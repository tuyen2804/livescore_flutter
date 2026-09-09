import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../models/football/football_models.dart';

/// Port của `data/api/ApiClient.kt` — API bóng đá riêng của app.
abstract class FootballRemoteDataSource {
  Future<List<MatchDto>> getLeagueLive(String date);
  Future<MatchCentreDataDto?> getMatchCentreLive(int fixtureId);
  Future<List<StandingTeamDto>> getStandings(int leagueId);
  Future<List<UpcomingFixtureDto>> getLeagueFixtures(int leagueId);
  Future<List<HighlightDto>> getHighlights(String date);
  Future<ForecastData?> getMatchForecast(int fixtureId, {String language = 'en'});
  Future<List<FavoriteFixtureDto>> getFixturesByDateForTeam(int teamId);
  Future<List<SquadPlayerDto>> getSquad(int teamId);
  Future<MatchVoteDto> getVoteTeam(int fixtureId);
  Future<void> voteTeam(int fixtureId, int choice);
}

class FootballRemoteDataSourceImpl implements FootballRemoteDataSource {
  FootballRemoteDataSourceImpl(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _client.get<dynamic>(path, query: query);
    if (res is Map) return Map<String, dynamic>.from(res);
    return const {};
  }

  @override
  Future<List<MatchDto>> getLeagueLive(String date) async =>
      MatchDto.listFrom(await _getJson(
        ApiConstants.leagueLive,
        query: {'date': date},
      ));

  @override
  Future<MatchCentreDataDto?> getMatchCentreLive(int fixtureId) async =>
      MatchCentreDataDto.unwrap(await _getJson(
        ApiConstants.matchCentreLive,
        query: {'fixture_id': fixtureId},
      ));

  @override
  Future<List<StandingTeamDto>> getStandings(int leagueId) async =>
      StandingTeamDto.listFrom(await _getJson(
        ApiConstants.standings,
        query: {'league_id': leagueId},
      ));

  @override
  Future<List<UpcomingFixtureDto>> getLeagueFixtures(int leagueId) async =>
      UpcomingFixtureDto.listFrom(await _getJson(
        ApiConstants.listFixturesUpcoming,
        query: {'league_id': leagueId},
      ));

  @override
  Future<List<HighlightDto>> getHighlights(String date) async =>
      HighlightDto.listFrom(await _getJson(
        ApiConstants.matchHighLight,
        query: {'date': date},
      ));

  @override
  Future<ForecastData?> getMatchForecast(
    int fixtureId, {
    String language = 'en',
  }) async =>
      ForecastData.unwrap(await _getJson(
        ApiConstants.matchForecast,
        query: {'fixture_id': fixtureId, 'language': language},
      ));

  @override
  Future<List<FavoriteFixtureDto>> getFixturesByDateForTeam(int teamId) async =>
      FavoriteFixtureDto.listFrom(await _getJson(
        ApiConstants.fixturesByDateForTeam,
        query: {'team_id': teamId},
      ));

  @override
  Future<List<SquadPlayerDto>> getSquad(int teamId) async =>
      SquadPlayerDto.listFrom(await _getJson(
        ApiConstants.listPlayer,
        query: {'team_id': teamId},
      ));

  @override
  Future<MatchVoteDto> getVoteTeam(int fixtureId) async => MatchVoteDto.fromJson(
        await _getJson(
          ApiConstants.matchCentreVote,
          query: {'fixture_id': fixtureId},
        ),
      );

  /// choice: 1 = home_win, 2 = draw, 3 = away_win — đúng như bản gốc.
  @override
  Future<void> voteTeam(int fixtureId, int choice) async {
    final param = switch (choice) {
      1 => 'home_win',
      2 => 'draw',
      3 => 'away_win',
      _ => 'home_win',
    };
    await _client.post<dynamic>(
      ApiConstants.matchCentreVoteTeamWin,
      query: {'fixture_id': fixtureId, param: 1},
    );
  }
}
