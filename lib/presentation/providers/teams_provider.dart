import 'dart:async';

import '../../core/services/remote_config_service.dart';
import '../../data/datasources/local/app_prefs.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/models/local/db_entities.dart';
import '../../data/repositories/sofascore_repository_impl.dart';
import '../../domain/entities/match_entities.dart';
import 'base_provider.dart';

/// Port `presentation/teams/TeamsViewModel.kt`.
class TeamsProvider extends BaseProvider {
  TeamsProvider(this._db, this._sofascore, this._remoteConfig) {
    unawaited(loadData());
  }

  final LeagueDbHelper _db;
  final SofascoreRepositoryImpl _sofascore;

  final RemoteConfigService _remoteConfig;

  String _sportSlug = AppPrefs.defaultSport;
  bool _isLoading = false;
  bool _favouriteVisible = true;
  bool _allVisible = true;

  List<TeamEntity> _fullTeamList = const [];
  List<TeamEntity> _allTeams = const [];
  List<TeamEntity> _favouriteTeams = const [];

  String get sportSlug => _sportSlug;
  bool get isLoading => _isLoading;
  bool get favouriteVisible => _favouriteVisible;
  bool get allVisible => _allVisible;
  List<TeamEntity> get allTeams => _allTeams;
  List<TeamEntity> get favouriteTeams => _favouriteTeams;
  bool get isFootball => _sportSlug.toLowerCase() == 'football';

  String _buildLogoUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    final base = _remoteConfig.imageBaseUrl;
    return '$base$imagePath';
  }

  TeamEntity _fromDb(TeamDbEntity e) => TeamEntity(
        id: '${e.id}',
        name: e.name,
        logoUrl: _buildLogoUrl(e.imagePath),
        isFavorite: e.isFavourite,
      );

  Future<void> selectSport(String slug) async {
    if (_sportSlug == slug) return;
    _sportSlug = slug;
    await loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);

    final favsFromDb =
        (await _db.getFavouriteTeams()).map(_fromDb).toList(growable: false);
    _favouriteTeams = favsFromDb;

    if (isFootball) {
      // Giữ nguyên logic bóng đá: đọc toàn bộ đội từ DB nội bộ.
      final teams = (await _db.getAllTeams()).map(_fromDb).toList(growable: false);
      _fullTeamList = teams;
      _allTeams = teams;
    } else {
      final favIds = favsFromDb.map((t) => t.id).toSet();
      final result = await _sofascore.getSuggestedTeams(_sportSlug);
      final teams = result.fold(
        (_) => const <TeamEntity>[],
        (list) => list
            .where((t) => t.national != true)
            .map((t) => TeamEntity(
                  id: '${t.id}',
                  name: t.name,
                  logoUrl: t.logoUrl,
                  isFavorite: favIds.contains('${t.id}'),
                  sportSlug: _sportSlug,
                ))
            .toList(growable: false),
      );
      _fullTeamList = teams;
      _allTeams = teams;
    }

    setState(() => _isLoading = false);
  }

  void searchTeams(String query) {
    if (query.isEmpty) {
      setState(() => _allTeams = _fullTeamList);
      return;
    }
    final q = query.toLowerCase();
    setState(() => _allTeams =
        _fullTeamList.where((t) => t.name.toLowerCase().contains(q)).toList());
  }

  void toggleFavouriteVisibility() =>
      setState(() => _favouriteVisible = !_favouriteVisible);

  void toggleAllVisibility() => setState(() => _allVisible = !_allVisible);

  Future<void> toggleFavourite(TeamEntity team) async {
    final id = int.tryParse(team.id);
    if (id == null) return;
    await _db.toggleTeamFavourite(id);
    await loadData();
  }
}
