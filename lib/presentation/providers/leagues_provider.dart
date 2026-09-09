import 'dart:async';

import '../../core/services/remote_config_service.dart';
import '../../data/datasources/local/app_prefs.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/models/local/db_entities.dart';
import '../../data/repositories/sofascore_repository_impl.dart';
import '../../domain/entities/match_entities.dart';
import 'base_provider.dart';

/// Port `presentation/leagues/LeaguesFragment.kt`:
/// bóng đá đọc từ DB nội bộ, môn khác lấy gợi ý + category từ Sofascore.
class LeaguesProvider extends BaseProvider {
  LeaguesProvider(this._db, this._sofascore, this._remoteConfig) {
    unawaited(loadData());
  }

  final LeagueDbHelper _db;
  final SofascoreRepositoryImpl _sofascore;

  final RemoteConfigService _remoteConfig;

  String _sportSlug = AppPrefs.defaultSport;
  bool _isLoading = false;
  String _query = '';

  List<League> _favourites = const [];
  List<League> _international = const [];
  List<League> _national = const [];

  bool _favouriteVisible = true;
  bool _internationalVisible = true;
  bool _nationalVisible = true;

  String get sportSlug => _sportSlug;
  bool get isLoading => _isLoading;
  bool get favouriteVisible => _favouriteVisible;
  bool get internationalVisible => _internationalVisible;
  bool get nationalVisible => _nationalVisible;
  bool get isFootball => _sportSlug.toLowerCase() == 'football';

  List<League> get favourites => _filter(_favourites);
  List<League> get international => _filter(_international);
  List<League> get national => _filter(_national);

  List<League> _filter(List<League> source) {
    if (_query.isEmpty) return source;
    final q = _query.toLowerCase();
    return source.where((l) => l.name.toLowerCase().contains(q)).toList();
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  void toggleFavouriteVisibility() =>
      setState(() => _favouriteVisible = !_favouriteVisible);

  void toggleInternationalVisibility() =>
      setState(() => _internationalVisible = !_internationalVisible);

  void toggleNationalVisibility() =>
      setState(() => _nationalVisible = !_nationalVisible);

  Future<void> selectSport(String slug) async {
    if (_sportSlug == slug) return;
    _sportSlug = slug;
    await loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);
    if (isFootball) {
      await _loadFootball();
    } else {
      await _loadSofascore();
    }
    setState(() => _isLoading = false);
  }

  String _logoUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    final base = _remoteConfig.imageBaseUrl;
    return '$base$imagePath';
  }

  League _fromDb(LeagueDbEntity e) => League(
        id: '${e.id}',
        name: e.name,
        logoUrl: _logoUrl(e.imagePath),
        isFavorite: e.isFavourite,
        countryId: e.countryId,
        leagueId: e.id,
      );

  Future<void> _loadFootball() async {
    final results = await Future.wait([
      _db.getFavouriteLeagues(),
      _db.getInternationalLeagues(),
      _db.getNationalLeagues(),
    ]);
    _favourites = results[0].map(_fromDb).toList(growable: false);
    _international = results[1].map(_fromDb).toList(growable: false);
    _national = results[2].map(_fromDb).toList(growable: false);
  }

  /// Bản gốc (nhánh môn Sofascore): tách theo `isFavourite`, 12 mục đầu của
  /// phần còn lại là "Featured Categories", phần đuôi là danh sách đầy đủ.
  void _splitSofascore(List<League> all) {
    _favourites = all.where((l) => l.isFavorite).toList(growable: false);
    final rest = all.where((l) => !l.isFavorite).toList();
    _international = rest.take(12).toList(growable: false);
    _national = rest.skip(12).toList(growable: false);
  }

  Future<void> _loadSofascore() async {
    final favIds = (await _db.getFavouriteLeagues()).map((e) => e.id).toSet();

    final suggested = await _sofascore.getSuggestedTournaments(_sportSlug);
    final categories = await _sofascore.getSportCategories(_sportSlug);

    final suggestedLeagues = suggested.fold(
      (_) => const <League>[],
      (list) => list
          .map((ut) => League(
                id: '${ut.id}',
                name: ut.name,
                logoUrl: ut.logoUrl,
                isFavorite: favIds.contains(ut.id),
                leagueId: ut.id,
                country: ut.category?.name,
                sportSlug: _sportSlug,
              ))
          .toList(growable: false),
    );

    final categoryLeagues = categories.fold(
      (_) => const <League>[],
      (list) => list
          .map((cat) => League(
                id: '${cat.id}',
                name: cat.name,
                logoUrl: cat.imageUrl,
                isFavorite: favIds.contains(cat.id),
                leagueId: cat.id,
                country: cat.name,
                sportSlug: _sportSlug,
              ))
          .toList(growable: false),
    );

    _splitSofascore([...suggestedLeagues, ...categoryLeagues]);
  }

  Future<void> toggleFavourite(League league) async {
    await _db.toggleFavourite(league.leagueId);
    await loadData();
  }
}
