/// Port `ads/adnative/AdsKey.kt` — chỉ giữ phần interstitial / reward, bỏ
/// toàn bộ placement native.
///
/// Tên placement phải khớp 1-1 với key trong `adsIntersConfig` mà API
/// `api.gamesontop.com` trả về; ad unit id thì nằm ngay trong app đúng như
/// bản Kotlin (xem `InterstitialAdManager.getAdUnitId`).
class InterPlacement {
  const InterPlacement._();

  static const String splash = 'LiveScore_inter_splash';
  static const String inApp = 'LiveScore_inter_Inapp';

  /// Bản gốc show khi đóng màn No-ads / Premium. App này đã bỏ Premium nên
  /// placement giữ lại cho đủ, không có nơi gọi.
  static const String noAds = 'LiveScore_inter_Noads';
}

class RewardPlacement {
  const RewardPlacement._();

  static const String inApp = 'LiveScore_reward_Inapp';
}

/// Ad unit id lấy nguyên từ `InterstitialAdManager`, `RewardAdManager`,
/// `AppOpenAdManager` và `MatchDetailFragment` của bản Kotlin.
class AdsUnitIds {
  const AdsUnitIds._();

  static const String appId = 'ca-app-pub-6884037586522683~4860453709';

  static const Map<String, String> _interNormal = {
    InterPlacement.splash: 'ca-app-pub-6884037586522683/7120775219',
    InterPlacement.inApp: 'ca-app-pub-6884037586522683/8714872570',
    InterPlacement.noAds: 'ca-app-pub-6884037586522683/8193194050',
  };

  static const Map<String, String> _interHighFloor = {
    InterPlacement.splash: 'ca-app-pub-6884037586522683/6929203526',
    InterPlacement.inApp: 'ca-app-pub-6884037586522683/6319914573',
    InterPlacement.noAds: 'ca-app-pub-6884037586522683/5813377067',
  };

  static const Map<String, String> _reward = {
    RewardPlacement.inApp: 'ca-app-pub-6884037586522683/5717279348',
  };

  static const String appOpen = 'ca-app-pub-6884037586522683/5525707654';

  /// `MatchDetailFragment` có gọi banner nhưng đang bị comment, giữ id để
  /// bật lại khi cần.
  static const String bannerHome = 'ca-app-pub-6884037586522683/6524671628';

  static String inter(String placement) => _interNormal[placement] ?? '';
  static String interHighFloor(String placement) =>
      _interHighFloor[placement] ?? '';
  static String reward(String placement) => _reward[placement] ?? '';
}

/// Nhãn `ad_format` gửi kèm sự kiện Analytics — giữ đúng chuỗi của bản gốc.
class AdFormat {
  const AdFormat._();

  static const String interstitial = 'interstitial';
  static const String appOpen = 'app_open';
  static const String rewarded = 'rewarded';
  static const String banner = 'banner';
  static const String native = 'native';
}
