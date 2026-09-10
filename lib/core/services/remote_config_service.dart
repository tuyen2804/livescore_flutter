import 'dart:developer' as dev;

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../constants/api_constants.dart';

/// Port của `data/firebase/RemoteConfigManager.kt`, đã bỏ toàn bộ key quảng cáo.
/// Nếu Firebase chưa khởi tạo được thì rơi về giá trị mặc định — app vẫn chạy.
class RemoteConfigService {
  static const String keyForceUpdate = 'force_update';
  static const String keyMinAppVersion = 'min_app_version';
  static const String keyGuideEnabled = 'guide_enabled';
  static const String keyLanguageReopen = 'language_reopen';
  static const String keyOnboardReopen = 'onboard_reopen';
  static const String keyThemeMode = 'theme_mode';
  static const String keyBaseUrl = 'base_url';
  static const String keyImageBaseUrl = 'image_base_url';

  // ---- Khoá quảng cáo (port RemoteConfigManager.kt, bỏ toàn bộ key native) ----
  static const String keyShowAds = 'show_ads';
  static const String keyInterSplash = 'LiveScore_inter_splash';
  static const String keyInterInApp = 'LiveScore_inter_Inapp';
  static const String keyInterNoAds = 'LiveScore_inter_Noads';
  static const String keyRewardInApp = 'LiveScore_reward_Inapp';
  static const String keyAppOpenResume = 'LiveScore_appopen_resume';

  /// JSON cấu hình placement native — xem `docs/ADS_NATIVE_DESIGN.md`.
  static const String keyPlacementConfig = 'placement_config';

  static const Duration _fetchTimeout = Duration(seconds: 10);

  static const Map<String, Object> defaults = {
    keyForceUpdate: false,
    keyMinAppVersion: 1,
    keyGuideEnabled: true,
    keyLanguageReopen: true,
    keyOnboardReopen: true,
    keyThemeMode: '1',
    keyShowAds: true,
    keyInterSplash: true,
    keyInterInApp: true,
    keyInterNoAds: true,
    keyRewardInApp: true,
    keyAppOpenResume: true,
    // Để rỗng: thiếu Remote Config thì repository rơi về asset đóng gói.
    keyPlacementConfig: '',
    keyBaseUrl: ApiConstants.footballBaseUrl,
    keyImageBaseUrl: ApiConstants.footballImageBaseUrl,
  };

  FirebaseRemoteConfig? _config;
  bool get isReady => _config != null;

  Future<void> init() async {
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: _fetchTimeout,
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await config.setDefaults(defaults);
      _config = config;
      await config.fetchAndActivate().timeout(_fetchTimeout);
      dev.log('Remote config activated', name: 'RemoteConfigManager');
    } catch (e) {
      dev.log('Remote config unavailable, using defaults: $e',
          name: 'RemoteConfigManager');
    }
  }

  String getString(String key) {
    final value = _config?.getString(key);
    if (value != null && value.isNotEmpty) return value;
    return '${defaults[key] ?? ''}';
  }

  bool getBool(String key) =>
      _config?.getBool(key) ?? (defaults[key] as bool? ?? false);

  int getInt(String key) => _config?.getInt(key) ?? (defaults[key] as int? ?? 0);

  String get baseUrl => getString(keyBaseUrl);
  String get imageBaseUrl => getString(keyImageBaseUrl);
  bool get forceUpdate => getBool(keyForceUpdate);
  int get minAppVersion => getInt(keyMinAppVersion);
  bool get guideEnabled => getBool(keyGuideEnabled);

  /// Bản gốc: mở lại màn chọn ngôn ngữ / onboarding ở lần vào sau.
  bool get languageReopen => getBool(keyLanguageReopen);
  bool get onboardReopen => getBool(keyOnboardReopen);

  /// `show_ads` — công tắc tổng, bản gốc kiểm trong RewardAdManager và BannerAds.
  bool get showAds => getBool(keyShowAds);

  /// `isInterSplashEnabled()` / `isAOAResumeEnabled()` của bản gốc.
  bool get interSplashEnabled => getBool(keyInterSplash);
  bool get interInAppEnabled => getBool(keyInterInApp);
  bool get interNoAdsEnabled => getBool(keyInterNoAds);
  bool get rewardInAppEnabled => getBool(keyRewardInApp);
  bool get appOpenResumeEnabled => getBool(keyAppOpenResume);

  /// Chuỗi JSON thô của `placement_config`; rỗng nghĩa là chưa có.
  String get placementConfig => getString(keyPlacementConfig);

  /// Khoá bật/tắt riêng của từng placement native (`LiveScore_native_splash`…).
  /// Bản gốc: `isAdEnabled()` trả true khi không khai khoá.
  bool isNativeEnabled(String placement) {
    final config = _config;
    if (config == null) return true;
    final value = config.getValue(placement);
    // Khoá không tồn tại ở cả defaults lẫn server → coi như bật, đúng như
    // `isAdEnabled()` của bản gốc (`return if (key != null) ... else true`).
    return value.source == ValueSource.valueStatic ? true : value.asBool();
  }

  /// 0 = Light, 1 = Dark.
  int get themeMode => int.tryParse(getString(keyThemeMode)) ?? 1;
}
