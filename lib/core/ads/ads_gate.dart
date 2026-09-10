import '../billing/premium_manager.dart';
import '../di/injection.dart';
import '../services/remote_config_service.dart';

/// Port `ads/AdsGate.kt`.
///
/// Chặn toàn bộ quảng cáo khi user đã mua gói No-ads, đúng như bản Kotlin
/// (`isBlocked = PremiumManager.isPremium`). Inter / AOA / Reward tự kiểm cờ
/// này ngay trong manager của chúng.
class AdsGate {
  const AdsGate._();

  /// true = đã mua gói No-ads, không load/show bất kỳ quảng cáo nào.
  static bool get isBlocked {
    try {
      return sl<PremiumManager>().isPremium;
    } catch (_) {
      return false;
    }
  }

  /// `show_ads` của Firebase Remote Config. Bản gốc kiểm khoá này trong
  /// `RewardAdManager` và `BannerAds` (interstitial và AOA thì không).
  static bool get showAds {
    try {
      return sl<RemoteConfigService>().showAds;
    } catch (_) {
      return true;
    }
  }
}
