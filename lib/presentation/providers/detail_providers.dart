import '../../core/error/failures.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/models/football/football_models.dart';
import '../../domain/entities/match_entities.dart';
import '../../domain/repositories/football_repository.dart';
import 'base_provider.dart';

/// Port `presentation/leagues/LeagueDetailFragment.kt` — BXH + lịch thi đấu.
class LeagueDetailProvider extends BaseProvider {
  LeagueDetailProvider(this._football);

  final FootballRepository _football;

  List<StandingTeamDto> _standings = const [];
  List<UpcomingFixtureDto> _fixtures = const [];
  bool _isLoading = false;
  Failure? _failure;

  List<StandingTeamDto> get standings => _standings;
  List<UpcomingFixtureDto> get fixtures => _fixtures;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  Future<void> load(int leagueId) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final standings = await _football.getStandings(leagueId);
    standings.fold((f) => _failure = f, (list) => _standings = list);

    final fixtures = await _football.getLeagueFixtures(leagueId);
    fixtures.fold((f) => _failure ??= f, (list) => _fixtures = list);

    setState(() => _isLoading = false);
  }
}

/// Port `presentation/detail/DetailTeamViewModel.kt` — lịch thi đấu của đội.
class TeamDetailProvider extends BaseProvider {
  TeamDetailProvider(this._football, this._db);

  final FootballRepository _football;
  final LeagueDbHelper _db;

  List<FixtureListItem> _items = const [];
  List<SquadPlayerDto> _squad = const [];
  bool _isLoading = false;
  bool _isFavorite = false;
  String _teamName = '';
  String? _teamLogo;
  Failure? _failure;

  List<FixtureListItem> get items => _items;
  List<SquadPlayerDto> get squad => _squad;
  bool get isLoading => _isLoading;
  bool get isFavorite => _isFavorite;
  String get teamName => _teamName;
  String? get teamLogo => _teamLogo;
  Failure? get failure => _failure;

  Future<void> load(int teamId) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final team = await _db.getTeamById(teamId);
    if (team != null) {
      _teamName = team.name;
      _teamLogo = team.imagePath;
      _isFavorite = team.isFavourite;
    }

    // Bản gốc gọi song song lịch thi đấu và đội hình.
    final fixturesFuture = _football.getTeamFixtures(teamId);
    final squadFuture = _football.getSquad(teamId);

    (await fixturesFuture).fold(
      (f) => _failure = f,
      (list) => _items = _group(list),
    );
    (await squadFuture).fold(
      (_) {},
      (list) => _squad = list,
    );

    setState(() => _isLoading = false);
  }

  /// Gom theo giải, chèn header — port `FixtureListItem` của bản gốc.
  List<FixtureListItem> _group(List<FavoriteFixtureDto> list) {
    final byLeague = <String, List<FavoriteFixtureDto>>{};
    final logos = <String, String?>{};
    for (final f in list) {
      byLeague.putIfAbsent(f.leagueName, () => <FavoriteFixtureDto>[]).add(f);
      logos[f.leagueName] ??= f.leagueLogoUrl;
    }

    final items = <FixtureListItem>[];
    for (final entry in byLeague.entries) {
      items.add(FixtureHeaderItem(entry.key, logos[entry.key]));
      for (final f in entry.value) {
        items.add(FixtureRowItem(Fixture(
          id: '${f.id}',
          homeTeamName: f.homeName,
          homeTeamLogo: f.homeLogoUrl ?? '',
          awayTeamName: f.awayName,
          awayTeamLogo: f.awayLogoUrl ?? '',
          time: DateTimeUtils.convertUtcToLocalTime(f.startingAt),
          date: DateTimeUtils.convertUtcToLocalDate(f.startingAt),
          leagueName: f.leagueName,
        )));
      }
    }
    return items;
  }

  Future<void> toggleFavorite(int teamId) async {
    await _db.toggleTeamFavourite(teamId);
    final team = await _db.getTeamById(teamId);
    setState(() => _isFavorite = team?.isFavourite ?? false);
  }
}

/// Port `presentation/detail/MatchForecastFragment.kt`.
class MatchForecastProvider extends BaseProvider {
  MatchForecastProvider(this._football);

  final FootballRepository _football;

  ForecastData? _forecast;
  bool _isLoading = false;
  Failure? _failure;

  ForecastData? get forecast => _forecast;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  Future<void> load(int matchId) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });
    final result = await _football.getMatchForecast(matchId);
    result.fold(
      (f) => setState(() => _failure = f),
      (data) => setState(() => _forecast = data),
    );
    setState(() => _isLoading = false);
  }
}
