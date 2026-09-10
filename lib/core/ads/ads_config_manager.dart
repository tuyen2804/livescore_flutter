import 'dart:developer' as dev;

import 'ads_config.dart';

/// Port `ads/AdsConfigManager.kt`.
///
/// Bản Kotlin dùng `SystemClock.elapsedRealtime()` (mốc từ lúc máy khởi động,
/// không bị lệch khi user chỉnh giờ). Dart không có API tương đương nên dùng
/// một `Stopwatch` chạy suốt vòng đời tiến trình — cùng tính chất đơn điệu.
class AdsClock {
  const AdsClock._();

  static final Stopwatch _sw = Stopwatch()..start();

  /// Số mili giây kể từ khi tiến trình khởi động.
  static int get elapsedMs => _sw.elapsedMilliseconds;
}

class AdsConfigManager {
  const AdsConfigManager._();

  static AdsSet? _currentSet;

  static void init(AdsConfig config, int playout) {
    _currentSet = _resolveAdsSet(config, playout);
    dev.log('Init | playout=$playout | using=$_currentSet', name: 'AdsConfig');
  }

  /// Chọn bộ cấu hình có ngưỡng lớn nhất mà `playout` vẫn vượt qua.
  static AdsSet? _resolveAdsSet(AdsConfig config, int playout) {
    final keys = config.adsSet.keys.toList()..sort();
    int? resultKey;
    for (final key in keys) {
      if (playout >= key) resultKey = key;
    }
    return resultKey == null ? null : config.adsSet[resultKey];
  }

  static int get firstDelaySeconds => _currentSet?.firstDelay ?? 0;
  static int get rewardDelaySeconds => _currentSet?.rewardDelay ?? 0;
  static int get rewardInterDelaySeconds => _currentSet?.rewardInterDelay ?? 0;
  static bool get isReady => _currentSet != null;

  /// `-1` = không cấu hình / tắt, `0` = luôn cho show.
  static int intervalSeconds(String placement) =>
      _currentSet?.inters[placement] ?? -1;

  static bool canShowInter(String placement, int lastShowTimeMs) {
    final set = _currentSet;
    if (set == null) return false;
    final value = set.inters[placement];
    if (value == null) return false;
    dev.log('$placement: ${AdsClock.elapsedMs - lastShowTimeMs}',
        name: 'Ads interval');
    if (value < 0) return false;
    if (value == 0) return true;
    return AdsClock.elapsedMs - lastShowTimeMs >= value * 1000;
  }

  /// Chỉ dùng cho kiểm thử — xoá cấu hình đã nạp.
  static void reset() => _currentSet = null;
}
