import '../../core/error/either.dart';
import '../../core/error/failures.dart';
import '../../data/models/football/football_models.dart';
import '../entities/match_entities.dart';

/// Hợp đồng cho API bóng đá riêng của app.
abstract class FootballRepository {
  /// `league-live?date=` — toàn bộ trận trong ngày, đã gom theo giải.
  Future<Either<Failure, List<LeagueSection>>> getLeagueLive(DateTime date);

  /// `match-centre-live?fixture_id=` — chi tiết trận.
  Future<Either<Failure, MatchCentreDataDto>> getMatchCentre(int fixtureId);

  /// `standings?league_id=`
  Future<Either<Failure, List<StandingTeamDto>>> getStandings(int leagueId);

  /// `list-fixtures-upcoming?league_id=`
  Future<Either<Failure, List<UpcomingFixtureDto>>> getLeagueFixtures(int leagueId);

  /// `match-forecast-new?fixture_id=`
  Future<Either<Failure, ForecastData>> getMatchForecast(int fixtureId);
  Future<Either<Failure, List<SquadPlayerDto>>> getSquad(int teamId);

  /// `fixtures-by-date-for-team?team_id=`
  Future<Either<Failure, List<FavoriteFixtureDto>>> getTeamFixtures(int teamId);

  /// `match-centre-vote?fixture_id=`
  Future<Either<Failure, MatchVoteDto>> getVote(int fixtureId);

  /// `match-centre-vote-team-win` — 1 home, 2 draw, 3 away.
  Future<Either<Failure, void>> vote(int fixtureId, int choice);
}
