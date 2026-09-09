import 'package:flutter/material.dart';

import '../../core/services/remote_config_service.dart';
import '../../data/datasources/local/app_prefs.dart';
import 'base_provider.dart';

/// Giữ trạng thái toàn app: theme (0 Light / 1 Dark) và ngôn ngữ.
/// Thay cho `ThemeUtils.kt` + `LanguageUtils.kt`.
class AppProvider extends BaseProvider {
  AppProvider(this._prefs, this._remoteConfig) {
    final saved = _prefs.getString(AppPrefs.keyLanguageCode);
    _locale = saved == null ? null : _parseLocale(saved);
    // Bản gốc: theme lấy từ prefs, lần đầu lấy mặc định của Remote Config.
    _themeMode = _prefs.getInt(
      AppPrefs.keyThemeMode,
      defaultValue: _remoteConfig.themeMode,
    );
  }

  final AppPrefs _prefs;
  final RemoteConfigService _remoteConfig;

  /// 14 ngôn ngữ đúng như các thư mục `values-*` của bản Android.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('vi'),
    Locale('ar'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('zh'),
    Locale('zh', 'Hant'),
  ];

  Locale? _locale;
  int _themeMode = 1;

  Locale? get locale => _locale;
  int get themeModeValue => _themeMode;
  bool get isDark => _themeMode == 1;
  ThemeMode get themeMode => _themeMode == 0 ? ThemeMode.light : ThemeMode.dark;

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _prefs.setLanguageCode(_encodeLocale(locale));
    notifyListeners();
  }

  Future<void> setThemeMode(int mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> toggleTheme() => setThemeMode(_themeMode == 1 ? 0 : 1);

  static String _encodeLocale(Locale l) =>
      l.countryCode == null && l.scriptCode == null
          ? l.languageCode
          : '${l.languageCode}_${l.scriptCode ?? l.countryCode}';

  static Locale _parseLocale(String raw) {
    final parts = raw.split('_');
    if (parts.length == 1) return Locale(parts[0]);
    if (parts[1] == 'Hant' || parts[1] == 'Hans') {
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
    }
    return Locale(parts[0], parts[1]);
  }
}
