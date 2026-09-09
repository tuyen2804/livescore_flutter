import 'dart:developer' as dev;

import '../../core/error/either.dart';
import '../../core/error/exceptions.dart' as app;
import '../../core/error/failures.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/event_list_item.dart';
import '../../domain/entities/match_entities.dart';
import '../../domain/repositories/sofascore_repository.dart';
import '../datasources/remote/home_feed_loader.dart';
import '../datasources/remote/sofascore_remote_data_source.dart';
import '../mappers/sofascore_mapper.dart';
import '../models/sofascore/sofascore_models.dart';

class SofascoreRepositoryImpl implements SofascoreRepository {
  SofascoreRepositoryImpl(this._api, this._feedLoader);

  final SofascoreRemoteDataSource _api;
  final HomeFeedLoader _feedLoader;

  static const String _tag = 'SofascoreRepository';

  Future<Either<Failure, T>> _run<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on app.NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on app.TimeoutException catch (e) {
      return Left(TimeoutFailure(e.message));
    } on app.ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } on app.ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      dev.log('Unhandled: $e', name: _tag);
      return Left(UnknownFailure('$e'));
    }
  }

  /// Feed dạng danh sách phẳng (dùng cho màn Home các môn Sofascore).
  Future<Either<Failure, List<EventListItem>>> loadFeed({
    required String sportSlug,
    required DateTime date,
    bool liveOnly = false,
    int cyclingUniqueStageId = 9,
    String? cyclingYear,
  }) =>
      _run(() => _feedLoader.loadFeed(
            sportSlug: sportSlug,
            date: DateTimeUtils.apiDate(date),
            liveOnly: liveOnly,
            cyclingUniqueStageId: cyclingUniqueStageId,
            cyclingYear: cyclingYear,
          ));

  Future<void> ensureDefaultPinsInitialized() =>
      _feedLoader.ensureDefaultPinsInitialized();

  Future<Either<Failure, List<String>>> loadCyclingYears(int uniqueStageId) =>
      _run(() => _feedLoader.loadCyclingYears(uniqueStageId));

  /// Chuyển feed phẳng thành nhóm giải — dùng chung UI với bóng đá.
  @override
  Future<Either<Failure, List<LeagueSection>>> getSportFeed(
    String sportSlug,
    DateTime date,
  ) async {
    final result = await loadFeed(sportSlug: sportSlug, date: date);
    return result.map((items) => SofascoreMapper.toLeagueSections(items, sportSlug));
  }

  @override
  Future<Either<Failure, Map<String, SportEventCount>>> getSportEventCounts() =>
      _run(() => _feedLoader.loadSportEventCounts());

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getSportEvents(
    String sportSlug,
    DateTime date,
  ) =>
      _run(() => _api.getSportEvents(sportSlug, DateTimeUtils.apiDate(date)));

  @override
  Future<Either<Failure, List<CategoryItem>>> getCategoriesForDate(
    String sportSlug,
    DateTime date,
  ) =>
      _run(() =>
          _api.getCategoriesForDate(sportSlug, DateTimeUtils.apiDate(date)));

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getCategoryEvents(
    int categoryId,
    DateTime date,
  ) =>
      _run(() =>
          _api.getCategoryEventsForDate(categoryId, DateTimeUtils.apiDate(date)));

  @override
  Future<Either<Failure, List<UniqueTournament>>> getCategoryUniqueTournaments(
    int categoryId,
  ) =>
      _run(() => _api.getCategoryUniqueTournaments(categoryId));

  @override
  Future<Either<Failure, List<Category>>> getSportCategories(String sportSlug) =>
      _run(() => _api.getSportCategories(sportSlug));

  @override
  Future<Either<Failure, SofascoreEvent>> getEventDetails(int eventId) =>
      _run(() async {
        final event = await _api.getEventDetails(eventId);
        if (event == null) throw app.ParseException('Event $eventId not found');
        return event;
      });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventDetailsRaw(int eventId) =>
      _run(() => _api.getEventDetailsRaw(eventId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventPointByPoint(int eventId) =>
      _run(() => _api.getEventPointByPoint(eventId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventCountryChannels(int eventId) =>
      _run(() => _api.getEventCountryChannels(eventId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventEsportsGames(int eventId) =>
      _run(() => _api.getEventEsportsGames(eventId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventIncidents(int eventId) =>
      _run(() => _api.getEventIncidents(eventId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventStatistics(int eventId) =>
      _run(() => _api.getEventStatistics(eventId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventLineups(int eventId) =>
      _run(() => _api.getEventLineups(eventId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventVotes(int eventId) =>
      _run(() => _api.getEventVotes(eventId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getHeadToHead(String customId) =>
      _run(() => _api.getHeadToHeadEvents(customId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEventOdds(int eventId) =>
      _run(() => _api.getEventOdds(eventId));

  @override
  Future<Either<Failure, List<SeasonInfo>>> getTournamentSeasons(
    int tournamentId,
  ) =>
      _run(() => _api.getUniqueTournamentSeasons(tournamentId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTournamentStandings(
    int uniqueTournamentId,
    int seasonId,
  ) =>
      _run(() => _api.getUniqueTournamentStandings(uniqueTournamentId, seasonId));

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getSeasonNextEvents(
    int tournamentId,
    int seasonId,
  ) =>
      _run(() => _api.getSeasonNextEvents(tournamentId, seasonId));

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getSeasonLastEvents(
    int tournamentId,
    int seasonId,
  ) =>
      _run(() => _api.getSeasonLastEvents(tournamentId, seasonId));

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getTournamentEvents(
    int tournamentId,
    DateTime date,
  ) =>
      _run(() => _api.getUniqueTournamentEvents(
            tournamentId,
            DateTimeUtils.apiDate(date),
          ));

  // ---- Stage ----

  @override
  Future<Either<Failure, List<SofascoreStage>>> getScheduledStages(
    String sportSlug,
    DateTime date,
  ) =>
      _run(() => _api.getScheduledStages(sportSlug, DateTimeUtils.apiDate(date)));

  @override
  Future<Either<Failure, SofascoreStage>> getStageDetails(int stageId) =>
      _run(() async {
        final stage = await _api.getStageDetailsExtended(stageId);
        if (stage == null) throw app.ParseException('Stage $stageId not found');
        return stage;
      });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStageSubstages(int stageId) =>
      _run(() => _api.getStageSubstages(stageId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStageStandings(int stageId) =>
      _run(() => _api.getStageCompetitorStandings(stageId));

  @override
  Future<Either<Failure, List<SofascoreStage>>> getUniqueStageSeasons(
    int uniqueStageId,
  ) =>
      _run(() => _api.getUniqueStageSeasons(uniqueStageId));

  // ---- MMA ----

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getMmaMainEvents(DateTime date) =>
      _run(() => _api.getMmaMainEvents(DateTimeUtils.apiDate(date)));

  @override
  Future<Either<Failure, UniqueTournamentDetail>> getMmaTournamentDetail(int id) =>
      _run(() async {
        final detail = await _api.getMmaUniqueTournamentDetail(id);
        if (detail == null) throw app.ParseException('Tournament $id not found');
        return detail;
      });

  @override
  Future<Either<Failure, Tournament>> getTournament(int tournamentId) =>
      _run(() async {
        final t = await _api.getTournament(tournamentId);
        if (t == null) throw app.ParseException('Tournament $tournamentId');
        return t;
      });

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getMmaEvents(
    int uniqueTournamentId,
    int tournamentId,
    String fightType,
  ) =>
      _run(() => _api.getMmaEvents(uniqueTournamentId, tournamentId, fightType));

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getMmaFeaturedEvents(int id) =>
      _run(() => _api.getMmaFeaturedEvents(id));

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getMmaMainEventsPaged(
    int uniqueTournamentId, {
    required bool next,
    int page = 0,
  }) =>
      _run(() => next
          ? _api.getMmaMainEventsNext(uniqueTournamentId, page)
          : _api.getMmaMainEventsLast(uniqueTournamentId, page));

  // ---- Đội ----

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTeamDetails(int teamId) =>
      _run(() => _api.getTeamDetails(teamId));

  @override
  Future<Either<Failure, List<SofascoreEvent>>> getTeamEvents(
    int teamId, {
    required bool last,
    int page = 0,
  }) =>
      _run(() async {
        final json = last
            ? await _api.getTeamLastEvents(teamId, page)
            : await _api.getTeamNextEvents(teamId, page);
        return SofascoreResponses.events(json);
      });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTeamPlayers(int teamId) =>
      _run(() => _api.getTeamPlayers(teamId));

  // ---- Tìm kiếm ----

  @override
  Future<Either<Failure, Map<String, dynamic>>> searchAll(String query) =>
      _run(() => _api.searchAll(query));

  @override
  Future<Either<Failure, List<UniqueTournament>>> getSuggestedTournaments(
    String sportSlug, {
    String alpha2 = 'VN',
  }) =>
      _run(() => _api.getDefaultPinnedTournamentsForSport(sportSlug, alpha2));

  @override
  Future<Either<Failure, List<Team>>> getSuggestedTeams(
    String sportSlug, {
    String alpha2 = 'VN',
  }) =>
      _run(() => _api.getDefaultSuggestedTeamsForSport(sportSlug, alpha2));
}
