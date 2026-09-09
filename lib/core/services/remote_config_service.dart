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

  static const Duration _fetchTimeout = Duration(seconds: 10);

  static const Map<String, Object> defaults = {
    keyForceUpdate: false,
    keyMinAppVersion: 1,
    keyGuideEnabled: true,
    keyLanguageReopen: true,
    keyOnboardReopen: true,
    keyThemeMode: '1',
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

  /// 0 = Light, 1 = Dark.
  int get themeMode => int.tryParse(getString(keyThemeMode)) ?? 1;
}
