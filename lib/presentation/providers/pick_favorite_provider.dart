import '../../core/services/remote_config_service.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/models/local/db_entities.dart';
import 'base_provider.dart';

/// Port `presentation/onboarding/pick/PickFavoriteViewModel.kt`.
class PickFavoriteProvider extends BaseProvider {
  PickFavoriteProvider(this._db, this._remoteConfig);

  final LeagueDbHelper _db;
  final RemoteConfigService _remoteConfig;

  /// Port `PickFavoriteAdapter.bind`: đường dẫn trong DB là dạng tương đối
  /// (`/leagues/8/8.png`) nên phải ghép `image_base_url` của Remote Config;
  /// chỉ giữ nguyên khi đã là URL đầy đủ.
  String? logoUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return imagePath;
    return '${_remoteConfig.imageBaseUrl}$imagePath';
  }

  List<LeagueDbEntity> _allLeagues = const [];
  List<TeamDbEntity> _allTeams = const [];
  List<LeagueDbEntity> _leagues = const [];
  List<TeamDbEntity> _teams = const [];
  String _query = '';
  bool _isLoading = false;

  List<LeagueDbEntity> get leagues => _leagues;
  List<TeamDbEntity> get teams => _teams;
  bool get isLoading => _isLoading;
  String get query => _query;

  int get favoriteLeagueCount =>
      _allLeagues.where((l) => l.isFavourite).length;
  int get favoriteTeamCount => _allTeams.where((t) => t.isFavourite).length;

  Future<void> loadData() async {
    setState(() => _isLoading = true);

    // Bản gốc: chỉ giải có priority, sắp theo priority; 200 đội phổ biến.
    final fetchedLeagues = (await _db.getAllLeagues())
        .where((l) => l.priority != null)
        .toList()
      ..sort((a, b) => a.priority!.compareTo(b.priority!));
    final fetchedTeams = await _db.getAllTeams(limit: 200);

    _allLeagues = fetchedLeagues;
    _allTeams = fetchedTeams;
    _filterData(_query);
    setState(() => _isLoading = false);
  }

  void search(String query) {
    _query = query;
    _filterData(query);
    notifyListeners();
  }

  void _filterData(String query) {
    if (query.isEmpty) {
      _leagues = _allLeagues;
      _teams = _allTeams;
      return;
    }
    final q = query.toLowerCase();
    _leagues =
        _allLeagues.where((l) => l.name.toLowerCase().contains(q)).toList();
    _teams = _allTeams.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  Future<void> toggleLeagueFavorite(LeagueDbEntity league) async {
    await _db.toggleFavourite(league.id);
    _allLeagues = _allLeagues
        .map((l) => l.id == league.id ? l.copyWith(isFavourite: !l.isFavourite) : l)
        .toList(growable: false);
    _filterData(_query);
    notifyListeners();
  }

  Future<void> toggleTeamFavorite(TeamDbEntity team) async {
    await _db.toggleTeamFavourite(team.id);
    _allTeams = _allTeams
        .map((t) => t.id == team.id ? t.copyWith(isFavourite: !t.isFavourite) : t)
        .toList(growable: false);
    _filterData(_query);
    notifyListeners();
  }
}
