import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_analytics.dart';
import 'ads_config_manager.dart';
import 'ads_constants.dart';
import 'ads_cooldown_tracker.dart';
import 'ads_gate.dart';
import 'app_open_ad_manager.dart';

/// Port `ads/reward/RewardAdManager.kt`.
///
/// Ba lối vào giống bản gốc:
/// - [preload] nạp trước;
/// - [showIfReady] chỉ show nếu đã có sẵn;
/// - [loadAndShow] nạp rồi show ngay, dùng cho nút "Watch now" ở Prediction và
///   ở thẻ bình chọn trong chi tiết trận.
///
/// `rewardDelay` tính từ lần **bất kỳ** quảng cáo nào đóng gần nhất (cả inter
/// lẫn reward), đúng như `AdsCooldownTracker.getLastAnyAdClosedAt()`.
class RewardAdManager {
  const RewardAdManager._();

  static const int _adExpireMs = 10 * 60 * 1000;

  static final Map<String, RewardedAd?> _adByUnitId = {};
  static final Map<String, bool> _loadingByUnitId = {};
  static final Map<String, ValueNotifier<bool>> _readyByUnitId = {};
  static final Map<String, int> _loadedTimeByUnitId = {};

  static void preload(String placement) {
    if (AdsGate.isBlocked) return;
    if (!AdsGate.showAds) return;

    final adUnitId = AdsUnitIds.reward(placement);
    if (adUnitId.isEmpty) return;
    if (_loadingByUnitId[adUnitId] == true) return;
    if (_adByUnitId[adUnitId] != null && _readyNotifier(adUnitId).value) return;

    _loadingByUnitId[adUnitId] = true;
    _setReady(adUnitId, false);

    AdsAnalytics.logRequest(adUnitId, AdFormat.rewarded);
    dev.log('request adUnitId=$adUnitId (placement=$placement)',
        name: 'RewardAd');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _onLoaded(adUnitId, placement, ad),
        onAdFailedToLoad: (error) {
          _clearByUnitId(adUnitId);
          dev.log('load fail adUnitId=$adUnitId: ${error.message}',
              name: 'RewardAd');
        },
      ),
    );
  }

  static ValueListenable<bool> readyOf(String placement) {
    final adUnitId = AdsUnitIds.reward(placement);
    if (adUnitId.isEmpty) return ValueNotifier<bool>(false);
    return _readyNotifier(adUnitId);
  }

  /// Port `showIfReady`. [onUnavailable] không có ở bản gốc — bản gốc bắn
  /// `Toast(reward_ad_not_available)` rồi gọi `onDismiss`; ở đây trả về false
  /// để tầng UI tự quyết định hiện thông báo gì.
  static Future<bool> showIfReady(
    String placement, {
    bool enable = true,
    VoidCallback? onUserEarned,
    VoidCallback? onDismiss,
  }) async {
    if (!AdsGate.showAds) {
      onDismiss?.call();
      return false;
    }

    final adUnitId = AdsUnitIds.reward(placement);
    if (adUnitId.isEmpty) {
      onDismiss?.call();
      return false;
    }

    if (!_canPassRewardDelay()) {
      onDismiss?.call();
      AdsAnalytics.logShowRequest(
          adUnit: adUnitId, adFormat: AdFormat.rewarded, ready: false);
      return false;
    }

    final ad = _adByUnitId[adUnitId];
    if (ad == null || !_readyNotifier(adUnitId).value) {
      preload(placement);
      onDismiss?.call();
      AdsAnalytics.logShowRequest(
          adUnit: adUnitId, adFormat: AdFormat.rewarded, ready: false);
      return false;
    }

    if (_isAdExpired(adUnitId)) {
      _clearByUnitId(adUnitId);
      preload(placement);
      onDismiss?.call();
      AdsAnalytics.logShowRequest(
          adUnit: adUnitId, adFormat: AdFormat.rewarded, ready: false);
      return false;
    }

    await _showLoadedReward(
      placement: placement,
      adUnitId: adUnitId,
      ad: ad,
      enable: enable,
      onUserEarned: onUserEarned,
      onDismiss: onDismiss,
      onUnavailable: null,
    );
    return true;
  }

  /// Port `loadAndShow` — dùng cho nút bấm, có dialog loading ở tầng UI.
  static Future<void> loadAndShow(
    String placement, {
    VoidCallback? onUserEarned,
    VoidCallback? onDismiss,
    VoidCallback? onUnavailable,
  }) async {
    if (!AdsGate.showAds) {
      onDismiss?.call();
      return;
    }

    final adUnitId = AdsUnitIds.reward(placement);
    if (adUnitId.isEmpty) {
      onDismiss?.call();
      return;
    }

    if (!_canPassRewardDelay()) {
      AdsAnalytics.logShowRequest(
          adUnit: adUnitId, adFormat: AdFormat.rewarded, ready: false);
      onUnavailable?.call();
      return;
    }

    final readyAd = _adByUnitId[adUnitId];
    if (readyAd != null &&
        _readyNotifier(adUnitId).value &&
        !_isAdExpired(adUnitId)) {
      await _showLoadedReward(
        placement: placement,
        adUnitId: adUnitId,
        ad: readyAd,
        enable: false,
        onUserEarned: onUserEarned,
        onDismiss: onDismiss,
        onUnavailable: onUnavailable,
      );
      return;
    }

    _clearByUnitId(adUnitId);
    _loadingByUnitId[adUnitId] = true;
    _setReady(adUnitId, false);

    AdsAnalytics.logRequest(adUnitId, AdFormat.rewarded);
    dev.log('loadAndShow request adUnitId=$adUnitId (placement=$placement)',
        name: 'RewardAd');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _onLoaded(adUnitId, placement, ad);
          _showLoadedReward(
            placement: placement,
            adUnitId: adUnitId,
            ad: ad,
            enable: false,
            onUserEarned: onUserEarned,
            onDismiss: onDismiss,
            onUnavailable: onUnavailable,
          );
        },
        onAdFailedToLoad: (error) {
          _clearByUnitId(adUnitId);
          AdsAnalytics.logShowRequest(
              adUnit: adUnitId, adFormat: AdFormat.rewarded, ready: false);
          dev.log('loadAndShow fail adUnitId=$adUnitId: ${error.message}',
              name: 'RewardAd');
          onUnavailable?.call();
        },
      ),
    );
  }

  // ================= INTERNAL =================

  static void _onLoaded(String adUnitId, String placement, RewardedAd ad) {
    _adByUnitId[adUnitId] = ad;
    _loadedTimeByUnitId[adUnitId] = AdsClock.elapsedMs;
    _loadingByUnitId[adUnitId] = false;
    _setReady(adUnitId, true);

    final adSource =
        ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? 'unknown';
    AdsAnalytics.logLoaded(adUnitId, AdFormat.rewarded, adSource);

    ad.onPaidEvent = (paidAd, valueMicros, _, currencyCode) {
      final paidSource = paidAd is AdWithoutView
          ? paidAd.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
              'unknown'
          : 'unknown';
      AdsAnalytics.logImpression(
        adUnit: adUnitId,
        adFormat: AdFormat.rewarded,
        adSource: paidSource,
        valueMicros: valueMicros.round(),
        currencyCode: currencyCode,
      );
    };

    dev.log('loaded adUnitId=$adUnitId (placement=$placement)',
        name: 'RewardAd');
  }

  static Future<void> _showLoadedReward({
    required String placement,
    required String adUnitId,
    required RewardedAd ad,
    required bool enable,
    VoidCallback? onUserEarned,
    VoidCallback? onDismiss,
    VoidCallback? onUnavailable,
  }) async {
    AdsAnalytics.logShowRequest(
        adUnit: adUnitId, adFormat: AdFormat.rewarded, ready: true);

    AppOpenAdManager.disable('reward show');
    dev.log('show[$placement] adUnitId=$adUnitId', name: 'RewardAd');

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (shown) {
        // Mốc này phục vụ cả rewardDelay (reward sau) lẫn rewardInterDelay
        // (inter sau reward).
        AdsCooldownTracker.markRewardClosed();
        shown.dispose();
        _clearByUnitId(adUnitId);
        AppOpenAdManager.enable('reward dismissed');
        if (enable) preload(placement);
        onDismiss?.call();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        dev.log('show fail[$placement]: $error', name: 'RewardAd');
        shown.dispose();
        _clearByUnitId(adUnitId);
        AppOpenAdManager.enable('reward show failed');
        AdsAnalytics.logShowRequest(
            adUnit: adUnitId, adFormat: AdFormat.rewarded, ready: false);
        if (onUnavailable != null) {
          onUnavailable();
        } else {
          onDismiss?.call();
        }
      },
    );

    await ad.show(onUserEarnedReward: (_, reward) => onUserEarned?.call());
  }

  static bool _canPassRewardDelay() {
    final delaySec = AdsConfigManager.rewardDelaySeconds;
    if (delaySec <= 0) return true;
    final lastAnyClosedAt = AdsCooldownTracker.lastAnyAdClosedAt;
    if (lastAnyClosedAt == 0) return true;
    return AdsClock.elapsedMs - lastAnyClosedAt >= delaySec * 1000;
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
}
