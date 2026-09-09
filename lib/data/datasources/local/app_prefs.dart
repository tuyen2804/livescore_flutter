import 'package:shared_preferences/shared_preferences.dart';

/// Port của `data/local/AppPrefs.kt` + `PinnedTournamentStore` +
/// `SelectedSportStore` + `FavoritesManager` gộp về một chỗ.
/// SharedPreferences của Flutter dùng chung một namespace nên các key giữ
/// nguyên tên, riêng key của từng store cũ được thêm tiền tố để khỏi đụng nhau.
class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> create() async =>
      AppPrefs(await SharedPreferences.getInstance());

  // ---- Key gốc ----
  static const String keyShowSketchGuide = 'show_sketch_guide';
  static const String keyShowAnimSketch = 'show_anim_sketch';
  static const String keyShowAnimTrace = 'show_anim_trace';
  static const String keyShowTraceGuide = 'show_trace_guide';
  static const String keyFirstTimeOpenApp = 'first_time_open_app';
  static const String keyLastSelectedTool = 'last_selected_tool';
  static const String keyPassedLanguage = 'passed_language';
  static const String keyPassedOnboard = 'passed_onboard';
  static const String keyPassedPickFav = 'passed_pick_fav';
  static const String keyThemeMode = 'theme_mode'; // 0: Light, 1: Dark
  static const String keyLanguageCode = 'language_code';
  static const String keyDisabledNotifications = 'disabled_notifications';
  static const String keySearchHistory = 'search_history';

  static const String _keySelectedSport = 'selected_sport_prefs.key_selected_sport';
  static const String _pinnedPrefix = 'pinned_tournaments.sport_';
  static const String _pinnedInitialized = 'pinned_tournaments.initialized_v1';
  static const String _favLeaguePrefix = 'favorites_prefs.league_';
  static const String _favTeamPrefix = 'favorites_prefs.team_';

  static const String defaultSport = 'football';

  // ---- Đọc / ghi cơ bản ----
  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String? getString(String key, {String? defaultValue}) =>
      _prefs.getString(key) ?? defaultValue;

  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  int getInt(String key, {int defaultValue = 1}) => _prefs.getInt(key) ?? defaultValue;

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  // ---- Cache JSON (AppPrefs.setCache/getCache) ----
  Future<void> setCache(String key, String value) =>
      _prefs.setString('cache_$key', value);

  String? getCache(String key) => _prefs.getString('cache_$key');

  // ---- Luồng khởi động ----
  bool get passedLanguage => getBool(keyPassedLanguage);
  Future<void> setPassedLanguage(bool v) => setBool(keyPassedLanguage, v);

  bool get passedOnboard => getBool(keyPassedOnboard);
  Future<void> setPassedOnboard(bool v) => setBool(keyPassedOnboard, v);

  bool get passedPickFav => getBool(keyPassedPickFav);
  Future<void> setPassedPickFav(bool v) => setBool(keyPassedPickFav, v);

  bool get firstTimeOpenApp => getBool(keyFirstTimeOpenApp, defaultValue: true);
  Future<void> setFirstTimeOpenApp(bool v) => setBool(keyFirstTimeOpenApp, v);

  /// 0: Light, 1: Dark — mặc định Dark như bản gốc.
  int get themeMode => getInt(keyThemeMode, defaultValue: 1);
  Future<void> setThemeMode(int v) => setInt(keyThemeMode, v);

  String? get languageCode => getString(keyLanguageCode);
  Future<void> setLanguageCode(String v) => setString(keyLanguageCode, v);

  // ---- Môn đang chọn (SelectedSportStore) ----
  String get selectedSport =>
      _prefs.getString(_keySelectedSport) ?? defaultSport;

  Future<void> setSelectedSport(String slug) =>
      _prefs.setString(_keySelectedSport, slug);

  // ---- Giải ghim (PinnedTournamentStore) ----
  bool get pinnedInitialized => _prefs.getBool(_pinnedInitialized) ?? false;

  /// Khởi tạo lần đầu từ danh sách gợi ý của Sofascore, gom theo môn.
  Future<void> initializePinned(Map<String, List<int>> bySport) async {
    if (pinnedInitialized) return;
    for (final entry in bySport.entries) {
      await _prefs.setString(
        '$_pinnedPrefix${entry.key}',
        entry.value.toSet().join(','),
      );
    }
    await _prefs.setBool(_pinnedInitialized, true);
  }

  List<int> getPinnedIds(String sportSlug) {
    final raw = _prefs.getString('$_pinnedPrefix$sportSlug');
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> replacePinnedIds(String sportSlug, List<int> orderedIds) async {
    await _prefs.setString(
      '$_pinnedPrefix$sportSlug',
      orderedIds.toSet().join(','),
    );
    await _prefs.setBool(_pinnedInitialized, true);
  }

  // ---- Yêu thích (FavoritesManager) ----
  bool isFavoriteLeague(String leagueId) =>
      _prefs.getBool('$_favLeaguePrefix$leagueId') ?? false;

  Future<void> toggleFavoriteLeague(String leagueId) =>
      _prefs.setBool('$_favLeaguePrefix$leagueId', !isFavoriteLeague(leagueId));

  Future<void> setFavoriteLeague(String leagueId, bool value) =>
      _prefs.setBool('$_favLeaguePrefix$leagueId', value);

  List<String> get favoriteLeagues => _prefs
      .getKeys()
      .where((k) => k.startsWith(_favLeaguePrefix) && (_prefs.getBool(k) ?? false))
      .map((k) => k.substring(_favLeaguePrefix.length))
      .toList(growable: false);

  bool isFavoriteTeam(String teamId) =>
      _prefs.getBool('$_favTeamPrefix$teamId') ?? false;

  Future<void> toggleFavoriteTeam(String teamId) =>
      _prefs.setBool('$_favTeamPrefix$teamId', !isFavoriteTeam(teamId));

  Future<void> setFavoriteTeam(String teamId, bool value) =>
      _prefs.setBool('$_favTeamPrefix$teamId', value);

  List<String> get favoriteTeams => _prefs
      .getKeys()
      .where((k) => k.startsWith(_favTeamPrefix) && (_prefs.getBool(k) ?? false))
      .map((k) => k.substring(_favTeamPrefix.length))
      .toList(growable: false);

  // ---- Thông báo trận đã tắt ----
  Set<String> get disabledNotifications =>
      (_prefs.getStringList(keyDisabledNotifications) ?? const []).toSet();

  Future<void> addDisabledNotification(int fixtureId) async {
    final current = disabledNotifications..add('$fixtureId');
    await _prefs.setStringList(keyDisabledNotifications, current.toList());
  }

  Future<void> removeDisabledNotification(int fixtureId) async {
    final current = disabledNotifications..remove('$fixtureId');
    await _prefs.setStringList(keyDisabledNotifications, current.toList());
  }

  bool isNotificationEnabled(int fixtureId) =>
      !disabledNotifications.contains('$fixtureId');

  // ---- Lịch sử tìm kiếm ----
  List<String> get searchHistory =>
      _prefs.getStringList(keySearchHistory) ?? const [];

  Future<void> addSearchHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = searchHistory.toList()
      ..removeWhere((e) => e.toLowerCase() == q.toLowerCase())
      ..insert(0, q);
    await _prefs.setStringList(
      keySearchHistory,
      list.take(20).toList(growable: false),
    );
  }

  Future<void> clearSearchHistory() => _prefs.remove(keySearchHistory);
}
