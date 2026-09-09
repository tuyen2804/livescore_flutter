import 'dart:async';

import '../../core/services/remote_config_service.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/models/local/db_entities.dart';
import '../../data/repositories/sofascore_repository_impl.dart';
import '../../domain/entities/match_entities.dart';
import 'base_provider.dart';

/// Port `presentation/search/SearchViewModel.kt` + `SearchLeagueViewModel.kt`.
/// Bóng đá tra trong DB nội bộ; môn khác gọi `search/all` của Sofascore.
class SearchProvider extends BaseProvider {
  SearchProvider(this._db, this._sofascore, this._remoteConfig) {
    unawaited(loadTopTeams());
    unawaited(loadTopLeagues());
    unawaited(loadHistory());
  }

  final LeagueDbHelper _db;
  final SofascoreRepositoryImpl _sofascore;
  final RemoteConfigService _remoteConfig;

  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;

  List<TeamEntity> _teams = const [];
  List<TeamEntity> _topTeams = const [];
  List<League> _topLeagues = const [];
  List<League> _leagues = const [];
  List<TeamEntity> _historyTeams = const [];
  List<League> _historyLeagues = const [];

  String get query => _query;
  bool get isLoading => _isLoading;
  List<TeamEntity> get teams => _teams;

  /// Port `SearchViewModel.topTeams` — 20 đội đầu của bảng (đã sắp theo
  /// priority), hiện khi ô tìm kiếm còn trống.
  List<TeamEntity> get topTeams => _topTeams;

  /// Tương ứng cho màn tìm giải — 20 giải đầu của bảng.
  List<League> get topLeagues => _topLeagues;
  List<League> get leagues => _leagues;
  List<TeamEntity> get historyTeams => _historyTeams;
  List<League> get historyLeagues => _historyLeagues;
  bool get hasQuery => _query.trim().isNotEmpty;
  bool get isEmpty => _teams.isEmpty && _leagues.isEmpty;

  String _logo(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${_remoteConfig.imageBaseUrl}$path';
  }

  TeamEntity _teamFrom(TeamDbEntity e) => TeamEntity(
        id: '${e.id}',
        name: e.name,
        logoUrl: _logo(e.imagePath),
        isFavorite: e.isFavourite,
      );

  League _leagueFrom(LeagueDbEntity e) => League(
        id: '${e.id}',
        name: e.name,
        logoUrl: _logo(e.imagePath),
        isFavorite: e.isFavourite,
        countryId: e.countryId,
        leagueId: e.id,
      );

  /// Port `loadInitialData`: nạp toàn bộ đội (giới hạn 2000) rồi lấy 20 đội đầu.
  Future<void> loadTopTeams() async {
    final all = await _db.getAllTeams(limit: 2000);
    setState(() =>
        _topTeams = all.take(20).map(_teamFrom).toList(growable: false));
  }

  Future<void> loadTopLeagues() async {
    final all = await _db.getAllLeagues();
    setState(() =>
        _topLeagues = all.take(20).map(_leagueFrom).toList(growable: false));
  }

  Future<void> loadHistory() async {
    final teams = await _db.getSearchHistoryTeams();
    final leagues = await _db.getSearchHistoryLeagues();
    setState(() {
      _historyTeams = teams.map(_teamFrom).toList(growable: false);
      _historyLeagues = leagues.map(_leagueFrom).toList(growable: false);
    });
  }

  /// Gõ tới đâu tìm tới đó, hoãn 300ms để đỡ giật.
  void onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _teams = const [];
        _leagues = const [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => search(value));
  }

  Future<void> search(String value) async {
    final q = value.trim();
    if (q.isEmpty) return;
    setState(() => _isLoading = true);

    final teams = await _db.searchTeams(q);
    final leagues = await _db.searchLeagues(q);

    setState(() {
      _teams = teams.map(_teamFrom).toList(growable: false);
      _leagues = leagues.map(_leagueFrom).toList(growable: false);
      _isLoading = false;
    });
  }

  /// Tìm trên Sofascore cho các môn ngoài bóng đá.
  Future<Map<String, dynamic>?> searchSofascore(String value) async {
    final result = await _sofascore.searchAll(value);
    return result.fold((_) => null, (json) => json);
  }

  Future<void> rememberTeam(TeamEntity team) async {
    final id = int.tryParse(team.id);
    if (id == null) return;
    await _db.updateTeamTimeUse(id);
    await loadHistory();
  }

  Future<void> rememberLeague(League league) async {
    await _db.updateLeagueTimeUse(league.leagueId);
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await _db.clearSearchHistory();
    await _db.clearSearchLeagueHistory();
    await loadHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
