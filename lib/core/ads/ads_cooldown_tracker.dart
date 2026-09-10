import 'dart:math' as math;

import 'ads_config_manager.dart';

/// Port `ads/AdsCooldownTracker.kt` — mốc thời gian đóng quảng cáo gần nhất,
/// dùng cho `interval`, `rewardDelay` và `rewardInterDelay`.
class AdsCooldownTracker {
  const AdsCooldownTracker._();

  static int _lastInterClosedAt = 0;
  static int _lastRewardClosedAt = 0;

  static void markInterClosed() => _lastInterClosedAt = AdsClock.elapsedMs;
  static void markRewardClosed() => _lastRewardClosedAt = AdsClock.elapsedMs;

  static int get lastInterClosedAt => _lastInterClosedAt;
  static int get lastRewardClosedAt => _lastRewardClosedAt;
  static int get lastAnyAdClosedAt =>
      math.max(_lastInterClosedAt, _lastRewardClosedAt);
}
