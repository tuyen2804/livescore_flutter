import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_analytics.dart';
import 'ads_config_manager.dart';
import 'ads_constants.dart';
import 'ads_cooldown_tracker.dart';
import 'ads_gate.dart';
import 'app_open_ad_manager.dart';

/// Port `ads/adinter/InterstitialAdManager.kt`.
///
/// Giữ nguyên mọi quy tắc của bản gốc:
/// - mỗi placement có hai ad unit: **high-floor** thử trước, fail thì mới rơi
///   xuống **normal**;
/// - chỉ `splash` và `inApp` được retry normal, và đúng **1 lần** mỗi lần gọi
///   `preload()`;
/// - quảng cáo nạp quá 10 phút coi như hết hạn, bỏ và nạp lại;
/// - `firstDelay` tính từ lúc app khởi động, **không áp cho splash**;
/// - `interval` lấy từ cấu hình của placement vừa show trước đó;
/// - `rewardInterDelay` chặn inter nếu vừa xem reward xong.
class InterstitialAdManager {
  const InterstitialAdManager._();

  static const int _adExpireMs = 10 * 60 * 1000;

  static final Map<String, InterstitialAd?> _adByUnitId = {};
  static final Map<String, bool> _loadingByUnitId = {};
  static final Map<String, ValueNotifier<bool>> _readyByUnitId = {};
  static final Map<String, int> _loadedTimeByUnitId = {};

  /// Placement được phép nạp lại normal khi fail.
  static const Set<String> _placementsWithNormalRetry = {
    InterPlacement.inApp,
    InterPlacement.splash,
  };

  /// Reset về true mỗi lần `preload()` để đảm bảo chỉ retry một lần.
  static final Map<String, bool> _isPreloadByPlacement = {};

  static int _appStartTime = 0;
  static bool _hasShownFirstInter = false;
  static int _lastInterDelaySeconds = 0;

  // ================== APP FIRST DELAY ==================

  static void initAppStart() {
    _appStartTime = AdsClock.elapsedMs;
    _hasShownFirstInter = false;
  }

  static bool _canPassFirstDelay() {
    if (_hasShownFirstInter) return true;
    final delaySec = AdsConfigManager.firstDelaySeconds;
    if (delaySec <= 0) return true;
    return AdsClock.elapsedMs - _appStartTime >= delaySec * 1000;
  }

  // ================== GLOBAL INTERVAL ==================

  static bool _canShow() {
    final lastClosed = AdsCooldownTracker.lastInterClosedAt;
    if (lastClosed == 0) return true;
    if (_lastInterDelaySeconds <= 0) return true;
    return AdsClock.elapsedMs - lastClosed >= _lastInterDelaySeconds * 1000;
  }

  // ================== PUBLIC API ==================

  static void preload(String placement) {
    if (AdsGate.isBlocked) return;

    final highId = AdsUnitIds.interHighFloor(placement);
    final normalId = AdsUnitIds.inter(placement);

    _isPreloadByPlacement[placement] = true;

    if (highId.isNotEmpty) {
      _preloadByUnitId(
        adUnitId: highId,
        placement: placement,
        tag: 'hf',
        onFail: () {
          dev.log('hf fail[$placement] → fallback to normal', name: 'InterAd');
          if (normalId.isNotEmpty) _preloadNormal(normalId, placement);
        },
      );
    } else if (normalId.isNotEmpty) {
      _preloadNormal(normalId, placement);
    }
  }

  /// `getReadyFlow(placement)` — true khi high-floor **hoặc** normal sẵn sàng.
  static ValueListenable<bool> readyOf(String placement) {
    final highId = AdsUnitIds.interHighFloor(placement);
    final normalId = AdsUnitIds.inter(placement);
    final high = highId.isEmpty ? null : _readyNotifier(highId);
    final normal = normalId.isEmpty ? null : _readyNotifier(normalId);

    if (high == null && normal == null) return ValueNotifier<bool>(false);
    if (normal == null) return high!;
    if (high == null) return normal;
    return _AnyOfNotifier(high, normal);
  }

  static bool isReady(String placement) => readyOf(placement).value;

  /// Chờ tới khi có quảng cáo sẵn sàng, hoặc hết `timeout`.
  /// Thay cho `getReadyFlow(...).collect { ... }` của bản Kotlin.
  static Future<bool> waitReady(
    String placement, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final listenable = readyOf(placement);
    if (listenable.value) return true;

    final completer = _BoolCompleter();
    void listener() {
      if (listenable.value) completer.complete(true);
    }

    listenable.addListener(listener);
    try {
      return await completer.future.timeout(timeout, onTimeout: () => false);
    } finally {
      listenable.removeListener(listener);
    }
  }

  /// Port `showIfReady`. [enable] = có preload lại sau khi đóng hay không.
  static Future<void> showIfReady(
    String placement, {
    bool enable = true,
    VoidCallback? onDismiss,
  }) async {
    if (AdsGate.isBlocked) {
      onDismiss?.call();
      return;
    }

    final highId = AdsUnitIds.interHighFloor(placement);
    final normalId = AdsUnitIds.inter(placement);
    final logUnit = normalId.isEmpty ? highId : normalId;

    if (highId.isEmpty && normalId.isEmpty) {
      onDismiss?.call();
      return;
    }

    void bail() {
      onDismiss?.call();
      AdsAnalytics.logShowRequest(
        adUnit: logUnit,
        adFormat: AdFormat.interstitial,
        ready: false,
      );
    }

    // First delay không áp cho splash.
    if (placement != InterPlacement.splash && !_canPassFirstDelay()) {
      bail();
      return;
    }

    if (AdsConfigManager.intervalSeconds(placement) < 0) {
      bail();
      return;
    }
    if (!_canShow()) {
      bail();
      return;
    }

    final rewardInterDelaySec = AdsConfigManager.rewardInterDelaySeconds;
    if (rewardInterDelaySec > 0) {
      final lastRewardClosedAt = AdsCooldownTracker.lastRewardClosedAt;
      if (lastRewardClosedAt != 0 &&
          AdsClock.elapsedMs - lastRewardClosedAt <
              rewardInterDelaySec * 1000) {
        bail();
        return;
      }
    }

    final chosenUnitId = _pickBestUnitIdForShow(placement, highId, normalId);
    if (chosenUnitId.isEmpty) {
      bail();
      return;
    }

    final ad = _adByUnitId[chosenUnitId];
    if (ad == null || !_readyNotifier(chosenUnitId).value) {
      onDismiss?.call();
      AdsAnalytics.logShowRequest(
        adUnit: chosenUnitId,
        adFormat: AdFormat.interstitial,
        ready: false,
      );
      return;
    }

    AdsAnalytics.logShowRequest(
      adUnit: chosenUnitId,
      adFormat: AdFormat.interstitial,
      ready: true,
    );

    AppOpenAdManager.disable('inter show');
    dev.log('show[$placement] adUnitId=$chosenUnitId', name: 'InterAd');

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdClicked: (shown) {
        AdsAnalytics.logClick(
          adUnit: chosenUnitId,
          adFormat: AdFormat.interstitial,
          adSource: _adSourceOf(shown),
        );
      },
      onAdShowedFullScreenContent: (_) {
        if (placement != InterPlacement.splash) _hasShownFirstInter = true;
      },
      onAdDismissedFullScreenContent: (shown) {
        AdsCooldownTracker.markInterClosed();
        _lastInterDelaySeconds = AdsConfigManager.intervalSeconds(placement);
        shown.dispose();
        _clearByUnitId(chosenUnitId);
        AppOpenAdManager.enable('inter dismissed');
        if (enable) preload(placement);
        onDismiss?.call();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        dev.log('show fail[$placement]: $error', name: 'InterAd');
        shown.dispose();
        _clearByUnitId(chosenUnitId);
        AppOpenAdManager.enable('inter show failed');
        preload(placement);
        onDismiss?.call();
      },
    );

    await ad.show();
  }

  // ================== INTERNAL ==================

  static void _preloadNormal(String normalId, String placement) {
    _preloadByUnitId(
      adUnitId: normalId,
      placement: placement,
      tag: 'normal',
      onFail: () {
        final allowedByConfig = _placementsWithNormalRetry.contains(placement);
        final allowedByFlag = _isPreloadByPlacement[placement] == true;
        if (allowedByConfig && allowedByFlag) {
          _isPreloadByPlacement[placement] = false;
          dev.log('normal fail[$placement] → retry once', name: 'InterAd');
          _preloadByUnitId(
            adUnitId: normalId,
            placement: placement,
            tag: 'normal_retry',
          );
        } else {
          dev.log(
            'normal fail[$placement] → no retry '
            '(allowedByConfig=$allowedByConfig, allowedByFlag=$allowedByFlag)',
            name: 'InterAd',
          );
        }
      },
    );
  }

  static void _preloadByUnitId({
    required String adUnitId,
    required String placement,
    required String tag,
    VoidCallback? onFail,
  }) {
    if (adUnitId.isEmpty) {
      onFail?.call();
      return;
    }
    if (_loadingByUnitId[adUnitId] == true) return;
    if (_adByUnitId[adUnitId] != null && _readyNotifier(adUnitId).value) return;

    _loadingByUnitId[adUnitId] = true;
    _setReady(adUnitId, false);

    AdsAnalytics.logRequest(adUnitId, AdFormat.interstitial);
    dev.log('request[$tag] adUnitId=$adUnitId (placement=$placement)',
        name: 'InterAd');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _adByUnitId[adUnitId] = ad;
          _loadedTimeByUnitId[adUnitId] = AdsClock.elapsedMs;
          _loadingByUnitId[adUnitId] = false;
          _setReady(adUnitId, true);

          final adSource = _adSourceOf(ad);
          AdsAnalytics.logLoaded(adUnitId, AdFormat.interstitial, adSource);

          ad.onPaidEvent = (paidAd, valueMicros, _, currencyCode) {
            AdsAnalytics.logImpression(
              adUnit: adUnitId,
              adFormat: AdFormat.interstitial,
              adSource: _adSourceOf(paidAd),
              valueMicros: valueMicros.round(),
              currencyCode: currencyCode,
            );
          };

          dev.log('loaded[$tag] adUnitId=$adUnitId (placement=$placement)',
              name: 'InterAd');
        },
        onAdFailedToLoad: (error) {
          _clearByUnitId(adUnitId);
          dev.log('load fail[$tag] adUnitId=$adUnitId: ${error.message}',
              name: 'InterAd');
          onFail?.call();
        },
      ),
    );
  }

  static String _pickBestUnitIdForShow(
    String placement,
    String highId,
    String normalId,
  ) {
    for (final id in [highId, normalId]) {
      if (id.isEmpty) continue;
      if (_adByUnitId[id] == null) continue;
      if (!_readyNotifier(id).value) continue;

      if (_isAdExpired(id)) {
        _clearByUnitId(id);
        _preloadByUnitId(
          adUnitId: id,
          placement: placement,
          tag: id == highId ? 'hf' : 'normal',
        );
        continue;
      }
      return id;
    }
    return '';
  }

  static ValueNotifier<bool> _readyNotifier(String adUnitId) =>
      _readyByUnitId.putIfAbsent(adUnitId, () => ValueNotifier<bool>(false));

  static void _setReady(String adUnitId, bool ready) =>
      _readyNotifier(adUnitId).value = ready;

  static void _clearByUnitId(String adUnitId) {
    _adByUnitId.remove(adUnitId);
    _loadedTimeByUnitId.remove(adUnitId);
    _loadingByUnitId[adUnitId] = false;
    _setReady(adUnitId, false);
  }

  static bool _isAdExpired(String adUnitId) {
    final loadedTime = _loadedTimeByUnitId[adUnitId];
    if (loadedTime == null) return true;
    return AdsClock.elapsedMs - loadedTime >= _adExpireMs;
  }

  static String _adSourceOf(Ad ad) {
    if (ad is AdWithoutView) {
      return ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
          'unknown';
    }
    return 'unknown';
  }
}

/// Gộp hai `ValueListenable<bool>` bằng phép OR — thay cho `combine()` +
/// `stateIn()` của Kotlin Flow.
class _AnyOfNotifier extends ValueNotifier<bool> {
  _AnyOfNotifier(this._a, this._b) : super(_a.value || _b.value) {
    _a.addListener(_sync);
    _b.addListener(_sync);
  }

  final ValueNotifier<bool> _a;
  final ValueNotifier<bool> _b;

  void _sync() => value = _a.value || _b.value;

  @override
  void dispose() {
    _a.removeListener(_sync);
    _b.removeListener(_sync);
    super.dispose();
  }
}

/// Completer chỉ hoàn thành một lần, tránh `Future already completed`.
class _BoolCompleter {
  final _completer = Completer<bool>();
  Future<bool> get future => _completer.future;
  void complete(bool value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }
}
