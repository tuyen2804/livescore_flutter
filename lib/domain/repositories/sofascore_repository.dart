import '../../core/error/either.dart';
import '../../core/error/failures.dart';
import '../../data/models/sofascore/sofascore_models.dart';
import '../entities/match_entities.dart';

/// Hợp đồng cho Sofascore — mọi môn trừ bóng đá.
abstract class SofascoreRepository {
  /// Feed trang chủ của một môn trong một ngày, gom theo giải.
  Future<Either<Failure, List<LeagueSection>>> getSportFeed(
    String sportSlug,
    DateTime date,
  );

  Future<Either<Failure, Map<String, SportEventCount>>> getSportEventCounts();

  Future<Either<Failure, List<SofascoreEvent>>> getSportEvents(
    String sportSlug,
    DateTime date,
  );

  Future<Either<Failure, List<CategoryItem>>> getCategoriesForDate(
    String sportSlug,
    DateTime date,
  );

  Future<Either<Failure, List<SofascoreEvent>>> getCategoryEvents(
    int categoryId,
    DateTime date,
  );

  Future<Either<Failure, List<UniqueTournament>>> getCategoryUniqueTournaments(
    int categoryId,
  );

  Future<Either<Failure, List<Category>>> getSportCategories(String sportSlug);

  Future<Either<Failure, SofascoreEvent>> getEventDetails(int eventId);

  /// JSON thô của `event/{id}` — bản gốc đọc thẳng nhiều field lồng nhau.
  Future<Either<Failure, Map<String, dynamic>>> getEventDetailsRaw(int eventId);

  Future<Either<Failure, Map<String, dynamic>>> getEventIncidents(int eventId);

  Future<Either<Failure, Map<String, dynamic>>> getEventStatistics(int eventId);

  Future<Either<Failure, Map<String, dynamic>>> getEventLineups(int eventId);

  Future<Either<Failure, Map<String, dynamic>>> getEventVotes(int eventId);

  Future<Either<Failure, Map<String, dynamic>>> getHeadToHead(String customId);

  Future<Either<Failure, Map<String, dynamic>>> getEventOdds(int eventId);

  Future<Either<Failure, Map<String, dynamic>>> getEventPointByPoint(int eventId);

  Future<Either<Failure, Map<String, dynamic>>> getEventCountryChannels(int eventId);

  Future<Either<Failure, Map<String, dynamic>>> getEventEsportsGames(int eventId);

  Future<Either<Failure, List<SeasonInfo>>> getTournamentSeasons(int tournamentId);

  Future<Either<Failure, Map<String, dynamic>>> getTournamentStandings(
    int uniqueTournamentId,
    int seasonId,
  );

  Future<Either<Failure, List<SofascoreEvent>>> getSeasonNextEvents(
    int tournamentId,
    int seasonId,
  );

  Future<Either<Failure, List<SofascoreEvent>>> getSeasonLastEvents(
    int tournamentId,
    int seasonId,
  );

  Future<Either<Failure, List<SofascoreEvent>>> getTournamentEvents(
    int tournamentId,
    DateTime date,
  );

  // ---- Stage: motorsport / cycling ----
  Future<Either<Failure, List<SofascoreStage>>> getScheduledStages(
    String sportSlug,
    DateTime date,
  );

  Future<Either<Failure, SofascoreStage>> getStageDetails(int stageId);

  Future<Either<Failure, Map<String, dynamic>>> getStageSubstages(int stageId);

  Future<Either<Failure, Map<String, dynamic>>> getStageStandings(int stageId);

  Future<Either<Failure, List<SofascoreStage>>> getUniqueStageSeasons(
    int uniqueStageId,
  );

  // ---- MMA ----
  Future<Either<Failure, List<SofascoreEvent>>> getMmaMainEvents(DateTime date);

  Future<Either<Failure, UniqueTournamentDetail>> getMmaTournamentDetail(int id);

  Future<Either<Failure, Tournament>> getTournament(int tournamentId);

  /// `unique-tournament/{ut}/tournament/{t}/mma-events/{fightType}`.
  Future<Either<Failure, List<SofascoreEvent>>> getMmaEvents(
    int uniqueTournamentId,
    int tournamentId,
    String fightType,
  );

  Future<Either<Failure, List<SofascoreEvent>>> getMmaFeaturedEvents(int id);

  Future<Either<Failure, List<SofascoreEvent>>> getMmaMainEventsPaged(
    int uniqueTournamentId, {
    required bool next,
    int page = 0,
  });

  // ---- Đội ----
  Future<Either<Failure, Map<String, dynamic>>> getTeamDetails(int teamId);

  Future<Either<Failure, List<SofascoreEvent>>> getTeamEvents(
    int teamId, {
    required bool last,
    int page = 0,
  });

  Future<Either<Failure, Map<String, dynamic>>> getTeamPlayers(int teamId);

  // ---- Tìm kiếm & gợi ý ----
  Future<Either<Failure, Map<String, dynamic>>> searchAll(String query);

  Future<Either<Failure, List<UniqueTournament>>> getSuggestedTournaments(
    String sportSlug, {
    String alpha2 = 'VN',
  });

  Future<Either<Failure, List<Team>>> getSuggestedTeams(
    String sportSlug, {
    String alpha2 = 'VN',
  });
}
