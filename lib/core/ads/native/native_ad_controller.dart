import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_analytics.dart';
import '../ads_constants.dart';
import '../ads_gate.dart';
import 'native_layouts.dart';
import 'native_placement.dart';

enum NativeAdState { idle, loading, loaded, failed }

/// Một quảng cáo native đã nạp xong, kèm style để widget dựng lại.
class LoadedNativeAd {
  LoadedNativeAd({required this.ad, required this.layout, required this.style});

  final NativeAd ad;
  final String layout;
  final AdStyle style;

  /// **Mỗi `NativeAd` chỉ được bọc bằng đúng một `AdWidget`.** Dựng lại
  /// `AdWidget` ở mỗi lần rebuild sẽ tạo platform view mới trên cùng một ad
  /// và ô quảng cáo trắng bảng. Giữ sẵn ở đây để mọi lần rebuild đều dùng lại
  /// đúng một instance.
  ///
  /// `ValueKey` theo danh tính của ad là **bắt buộc**: khi nạp lại, widget cũ
  /// và mới cùng là `AdWidget` nên Flutter sẽ tái dùng Element và platform
  /// view vẫn trỏ vào ad đã bị huỷ — kết quả là một vùng đen chết. Có key thì
  /// Element cũ bị bỏ hẳn và view mới được dựng lại.
  late final Widget widget =
      AdWidget(key: ValueKey<int>(identityHashCode(ad)), ad: ad);
}

/// Quản lý vòng đời native của **một placement**.
///
/// Quy tắc (xem `docs/ADS_NATIVE_DESIGN.md`):
/// - **Số slot = số quảng cáo hiện cùng lúc**, các slot nạp song song.
/// - **Nhiều id trong một slot = chuỗi dự phòng cho MỘT quảng cáo**: thử
///   `ids[0]` (high-floor) trước, hạn 8 giây; hỏng mới sang `ids[1]`.
/// - Hỏng cả chuỗi id → backoff luỹ thừa 2 (2, 4, 8, 16, 32, trần 64 giây).
///   Nạp thành công một lần là reset bộ đếm.
/// - `AUTO_INTERVAL` chỉ đếm khi quảng cáo **đang hiển thị**; app vào nền thì
///   dừng, quay lại chạy tiếp.
class NativeAdController {
  NativeAdController(this.placement) {
    final policy = placement.loadPolicy;
    dev.log(
      '[${placement.name}] reload=${policy.reloadMode.name}'
      '${policy.reloadIntervalSec > 0 ? " mỗi ${policy.reloadIntervalSec}s" : ""}'
      ' (mặc định là manual — chỉ bật khi config khai reload_mode)',
      name: _tag,
    );
  }

  static const Duration _perIdTimeout = Duration(seconds: 8);
  static const int _maxBackoffSec = 64;
  static const Duration _staleAfter = Duration(minutes: 45);
  static const Duration _expireAfter = Duration(minutes: 55);
  static const String _tag = 'NativeAd';

  final NativePlacement placement;

  final ValueNotifier<NativeAdState> state =
      ValueNotifier<NativeAdState>(NativeAdState.idle);

  /// Theo đúng thứ tự slot; phần tử null = slot đó chưa/không nạp được.
  final ValueNotifier<List<LoadedNativeAd?>> ads =
      ValueNotifier<List<LoadedNativeAd?>>(const []);

  bool _loading = false;
  bool _disposed = false;

  /// Quảng cáo **đang** vẽ trên màn hình. Chỉ khi cờ này bật thì
  /// `AUTO_INTERVAL` mới đếm — đúng yêu cầu của tài liệu SDK v12.
  bool _shown = false;

  /// App vào nền lúc quảng cáo đang hiện. Dùng để biết có nên bật lại đồng hồ
  /// khi quay ra foreground hay không.
  bool _pausedWhileShown = false;
  int _failCount = 0;
  DateTime? _loadedAt;
  Timer? _intervalTimer;
  Timer? _backoffTimer;

  String get name => placement.name;

  bool get hasAd =>
      ads.value.any((e) => e != null) && state.value == NativeAdState.loaded;

  /// Quá 55 phút kể từ lúc nạp thì quảng cáo hết hạn. **Chưa nạp lần nào thì
  /// không tính là hết hạn** — nếu không, mỗi lần app quay lại foreground sẽ
  /// ép nạp cho cả những placement chưa từng dùng.
  bool get _expired {
    final at = _loadedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) >= _expireAfter;
  }

  bool get _stale {
    final at = _loadedAt;
    return at != null && DateTime.now().difference(at) >= _staleAfter;
  }

  // ------------------------------------------------------------------ nạp

  /// App tự gọi ở màn trước đó. Gọi lại khi đã có quảng cáo thì bỏ qua, trừ
  /// khi quảng cáo đã cũ.
  ///
  /// [keepCurrent] = true khi nạp lại theo `AUTO_INTERVAL`: giữ quảng cáo đang
  /// hiện cho tới lúc bản mới sẵn sàng, tránh chớp một khoảng trống rồi mới
  /// hiện lại — đó là cái người dùng thấy như "reload liên tục".
  Future<void> preload({bool keepCurrent = false}) async {
    if (_disposed || _loading) return;
    if (AdsGate.isBlocked) return;
    if (hasAd && !_stale && !keepCurrent) return;

    final union = placement.firstUnion;
    if (union == null || union.slots.isEmpty) {
      _fail('placement rỗng');
      return;
    }

    final previous = keepCurrent ? List<LoadedNativeAd?>.of(ads.value) : null;

    _loading = true;
    _backoffTimer?.cancel();
    // Nạp nền thì giữ nguyên trạng thái `loaded` để UI khỏi nhấp nháy.
    if (!keepCurrent) state.value = NativeAdState.loading;

    // Các slot nạp SONG SONG; bên trong mỗi slot thì tuần tự theo thứ tự id.
    final results = await Future.wait([
      for (var i = 0; i < union.slots.length; i++)
        _loadSlot(union.slots[i], union.styleOf(i)),
    ]);

    if (_disposed) {
      for (final r in results) {
        r?.ad.dispose();
      }
      return;
    }

    _loading = false;
    final anyLoaded = results.any((e) => e != null);

    if (anyLoaded) {
      ads.value = results;
      // Huỷ bản cũ ở khung hình SAU, lúc view cũ đã rời khỏi cây widget.
      // Huỷ ngay tại đây thì platform view vẫn đang hiển thị một ad đã chết
      // và để lại một vùng đen.
      if (previous != null) {
        final stale = previous;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final old in stale) {
            old?.ad.dispose();
          }
        });
      }
      _failCount = 0;
      _loadedAt = DateTime.now();
      state.value = NativeAdState.loaded;
      dev.log('[$name] nạp xong ${results.where((e) => e != null).length}/'
          '${results.length} slot', name: _tag);
      _restartIntervalTimer();
    } else if (previous != null) {
      // Nạp lại hỏng: giữ nguyên quảng cáo cũ, chỉ giãn lịch thử lại.
      dev.log('[$name] nạp lại hỏng, giữ bản cũ', name: _tag);
      _scheduleBackoff();
    } else {
      _fail('cả ${union.slots.length} slot đều hỏng');
    }
  }

  /// Thử lần lượt từng id của slot. Trả null nếu hỏng hết.
  Future<LoadedNativeAd?> _loadSlot(AdSlot slot, AdStyle style) async {
    final layout = NativeLayouts.resolve(slot.layout, placement.type);
    for (final adUnitId in slot.ids) {
      final ad = await _loadOne(adUnitId, layout, style);
      if (ad != null) return LoadedNativeAd(ad: ad, layout: layout, style: style);
    }
    return null;
  }

  Future<NativeAd?> _loadOne(
    String adUnitId,
    String layout,
    AdStyle style,
  ) async {
    final completer = Completer<NativeAd?>();
    NativeAd? pending;

    void finish(NativeAd? result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    AdsAnalytics.logRequest(adUnitId, AdFormat.native);

    pending = NativeAd(
      adUnitId: adUnitId,
      factoryId: NativeLayouts.factoryIdOf(layout),
      customOptions: style.toCustomOptions(),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          final source =
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                  'unknown';
          AdsAnalytics.logLoaded(adUnitId, AdFormat.native, source);
          finish(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          dev.log('[$name] $adUnitId hỏng: ${error.message}', name: _tag);
          ad.dispose();
          finish(null);
        },
        onAdClicked: (ad) {
          AdsAnalytics.logClick(
            adUnit: adUnitId,
            adFormat: AdFormat.native,
            adSource: 'unknown',
          );
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          AdsAnalytics.logImpression(
            adUnit: adUnitId,
            adFormat: AdFormat.native,
            adSource: 'unknown',
            valueMicros: valueMicros.round(),
            currencyCode: currencyCode,
          );
        },
      ),
    );

    unawaited(pending.load());

    final result = await completer.future.timeout(
      _perIdTimeout,
      onTimeout: () {
        dev.log('[$name] $adUnitId quá ${_perIdTimeout.inSeconds}s', name: _tag);
        return null;
      },
    );

    // Hết giờ nhưng quảng cáo vẫn có thể về sau — huỷ để khỏi rò bộ nhớ.
    if (result == null) {
      pending.dispose();
    }
    return result;
  }

  void _fail(String reason) {
    _loading = false;
    state.value = NativeAdState.failed;
    ads.value = const [];
    dev.log('[$name] Failed: $reason', name: _tag);
    _scheduleBackoff();
  }

  // -------------------------------------------------------------- backoff

  /// 2 → 4 → 8 → 16 → 32 → 64 giây, dừng ở 64.
  int get _backoffSeconds {
    final exp = math.min(_failCount, 6);
    return math.min(1 << exp, _maxBackoffSec);
  }

  void _scheduleBackoff() {
    final policy = placement.loadPolicy;
    // MẶC ĐỊNH KHÔNG THỬ LẠI. Chỉ placement khai reload_mode mới có backoff;
    // `manual` thì nằm im chờ app gọi preload.
    if (policy.reloadMode == ReloadMode.manual) return;

    _failCount++;
    final wait = Duration(seconds: _backoffSeconds);
    dev.log('[$name] hỏng lần $_failCount → chờ ${wait.inSeconds}s', name: _tag);
    _backoffTimer?.cancel();
    _backoffTimer = Timer(wait, () {
      if (!_disposed) unawaited(preload());
    });
  }

  // ------------------------------------------------------------- interval

  void _restartIntervalTimer() {
    _intervalTimer?.cancel();
    final policy = placement.loadPolicy;
    // MẶC ĐỊNH KHÔNG NẠP LẠI. Chỉ chạy khi config khai `AUTO_INTERVAL`;
    // `ReloadMode.parse` trả `manual` cho mọi giá trị khác.
    if (!policy.reloadMode.onInterval) return;
    if (policy.reloadIntervalSec <= 0) return;
    // Theo tài liệu v12: chỉ đếm khi quảng cáo đang hiển thị trên màn hình.
    if (!_shown) return;

    _intervalTimer = Timer.periodic(
      Duration(seconds: policy.reloadIntervalSec),
      (_) {
        if (_disposed || !_shown) return;
        unawaited(_reload());
      },
    );
  }

  Future<void> _reload() async {
    _loadedAt = null;
    await preload(keepCurrent: true);
  }

  // ----------------------------------------------------------- sự kiện UI

  /// Widget gọi khi quảng cáo thật sự vẽ lên màn hình.
  void notifyShown() {
    if (_shown) return;
    _shown = true;
    _restartIntervalTimer();
  }

  /// App vào nền, hoặc widget rời cây → dừng đếm interval.
  void pause() {
    _pausedWhileShown = _shown;
    _shown = false;
    _intervalTimer?.cancel();
    _intervalTimer = null;
  }

  /// App quay lại foreground.
  ///
  /// **Không tự nạp lại gì cả** trừ khi trước đó quảng cáo đang hiện *và* đã
  /// quá 55 phút. Placement chưa từng nạp thì nằm im chờ app gọi `preload`.
  void resume() {
    if (!_pausedWhileShown) return;
    _pausedWhileShown = false;
    _shown = true;
    if (hasAd && _expired) {
      unawaited(_reload());
    } else {
      _restartIntervalTimer();
    }
  }

  /// User đóng quảng cáo (fullscreen / collapsible).
  void notifyDismissed() {
    pause();
    if (placement.loadPolicy.reloadMode.onClose) {
      unawaited(_reload());
    }
  }

  // ---------------------------------------------------------------- dọn

  void _disposeAds() {
    for (final e in ads.value) {
      e?.ad.dispose();
    }
    ads.value = const [];
    state.value = NativeAdState.idle;
  }

  void dispose() {
    _disposed = true;
    _intervalTimer?.cancel();
    _backoffTimer?.cancel();
    _disposeAds();
    state.dispose();
    ads.dispose();
  }
}
