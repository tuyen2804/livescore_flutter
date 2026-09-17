import '../../../core/network/dio_client.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../models/sofascore/sofascore_models.dart';

/// Port của `data/sofascore/SofascoreApiService.kt`.
/// Dùng cho MỌI môn trừ bóng đá (bóng đá có API riêng của app).
class SofascoreRemoteDataSource {
  SofascoreRemoteDataSource(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> _json(String path) async {
    final res = await _client.get<dynamic>(path);
    if (res is Map) return Map<String, dynamic>.from(res);
    return const {};
  }

  Future<Map<String, dynamic>> _jsonQ(
    String path,
    Map<String, dynamic> query,
  ) async {
    final res = await _client.get<dynamic>(path, query: query);
    if (res is Map) return Map<String, dynamic>.from(res);
    return const {};
  }

  String get _tz => DateTimeUtils.timezoneOffsetSeconds;

  // ---- Tìm kiếm ----
  Future<Map<String, dynamic>> searchAll(String query) =>
      _jsonQ('search/all', {'q': query});

  // ---- Feed theo môn / ngày ----
  Future<Map<String, SportEventCount>> getSportEventCounts([String? tzOffset]) async =>
      SofascoreResponses.sportEventCounts(
        await _json('sport/${tzOffset ?? _tz}/event-count'),
      );

  Future<List<SofascoreEvent>> getSportEvents(String sportSlug, String date) async =>
      SofascoreResponses.events(await _json('sport/$sportSlug/$date/events'));

  /// Số trang của feed một ngày.
  ///
  /// Sofascore cắt một ngày thành vài trang theo khung giờ. Bóng đá ngày
  /// 17/09/2026 có 4 trang × ~200 trận = 784 trận. Đây là cách **duy nhất** lấy
  /// trọn một ngày: `sport/{slug}/scheduled-events/{date}` trả 404 với bóng đá.
  Future<int> getSportDayPageCount(String sportSlug, String date) async {
    final body = await _json('sport/$sportSlug/$date/events/index');
    final total = body['totalPages'];
    if (total is int && total > 0) return total;
    final pages = body['pages'];
    return pages is List && pages.isNotEmpty ? pages.length : 1;
  }

  Future<List<SofascoreEvent>> getSportDayEventsPage(
    String sportSlug,
    String date,
    int page,
  ) async =>
      SofascoreResponses.events(
        await _json('sport/$sportSlug/$date/events/$page'),
      );

  /// Toàn bộ trận đang diễn ra của một môn, một lần gọi.
  ///
  /// Đo 16/09/2026: bóng đá trả 351 trận trong 1,5 MB.
  Future<List<SofascoreEvent>> getSportLiveEvents(String sportSlug) async =>
      SofascoreResponses.events(await _json('sport/$sportSlug/events/live'));

  Future<List<CategoryItem>> getCategoriesForDate(
    String sportSlug,
    String date, [
    String? tzOffset,
  ]) async =>
      SofascoreResponses.categoryItems(
        await _json('sport/$sportSlug/$date/${tzOffset ?? _tz}/categories'),
      );

  Future<List<SofascoreEvent>> getCategoryEventsForDate(
    int categoryId,
    String date,
  ) async =>
      SofascoreResponses.events(
        await _json('category/$categoryId/scheduled-events/$date'),
      );

  Future<List<SofascoreEvent>> getPopularEvents(String sportSlug) async =>
      SofascoreResponses.events(await _json('sport/$sportSlug/popular-events'));

  Future<List<SofascoreEvent>> getPopularEventsForDate(
    String sportSlug,
    String countryCode,
    String date,
  ) async =>
      SofascoreResponses.events(
        await _json('sport/$sportSlug/$countryCode/popular-events/$date'),
      );

  Future<List<DailyUniqueTournament>> getCalendar(
    String yearMonth,
    String sportSlug, [
    String tzOffset = '25200',
  ]) async =>
      SofascoreResponses.calendar(
        await _json('calendar/$yearMonth/$tzOffset/$sportSlug/unique-tournaments'),
      );

  // ---- Giải đấu ----
  Future<List<SofascoreEvent>> getUniqueTournamentEvents(
    int tournamentId,
    String date,
  ) async =>
      SofascoreResponses.events(
        await _json('unique-tournament/$tournamentId/scheduled-events/$date'),
      );

  Future<List<SeasonInfo>> getUniqueTournamentSeasons(int tournamentId) async =>
      SofascoreResponses.seasons(
        await _json('unique-tournament/$tournamentId/seasons'),
      );

  Future<List<SofascoreEvent>> getSeasonLastEvents(
    int tournamentId,
    int seasonId,
  ) async =>
      SofascoreResponses.events(
        await _json(
          'unique-tournament/$tournamentId/season/$seasonId/events/last/0',
        ),
      );

  Future<List<SofascoreEvent>> getSeasonNextEvents(
    int tournamentId,
    int seasonId,
  ) async =>
      SofascoreResponses.events(
        await _json(
          'unique-tournament/$tournamentId/season/$seasonId/events/next/0',
        ),
      );

  Future<List<Category>> getSportCategories(String sportSlug) async =>
      SofascoreResponses.categories(await _json('sport/$sportSlug/categories'));

  Future<List<StageCategory>> getSportStageCategories(String sportSlug) async =>
      SofascoreResponses.stageCategories(
        await _json('sport/$sportSlug/categories'),
      );

  Future<List<UniqueTournament>> getCategoryUniqueTournaments(int categoryId) async =>
      SofascoreResponses.groupedUniqueTournaments(
        await _json('category/$categoryId/unique-tournaments'),
      );

  Future<Tournament?> getTournament(int tournamentId) async =>
      SofascoreResponses.tournament(await _json('tournament/$tournamentId'));

  Future<Map<String, dynamic>> getUniqueTournamentDetails(int id) =>
      _json('unique-tournament/$id');

  Future<Map<String, dynamic>> getUniqueTournamentStandings(
    int uniqueTournamentId,
    int seasonId,
  ) =>
      _json('unique-tournament/$uniqueTournamentId/season/$seasonId/standings/total');

  Future<Map<String, dynamic>> getTournamentStandings(
    int tournamentId,
    int seasonId,
  ) =>
      _json('tournament/$tournamentId/season/$seasonId/standings/total');

  Future<Map<String, dynamic>> getTournamentTeamEvents(
    int tournamentId,
    int seasonId,
  ) =>
      _json('tournament/$tournamentId/season/$seasonId/team-events/total');

  Future<Map<String, dynamic>> getCupTrees(int tournamentId, int seasonId) =>
      _json('unique-tournament/$tournamentId/season/$seasonId/cuptrees');

  // ---- Stage (motorsport / cycling) ----
  Future<List<DailyStage>> getStageCalendar(
    String yearMonth,
    String sportSlug, [
    String? tzOffset,
  ]) async =>
      SofascoreResponses.stageCalendar(
        await _json('calendar/$yearMonth/${tzOffset ?? _tz}/$sportSlug/stages'),
      );

  Future<Map<String, dynamic>> getAvailableCategoryFilters(String sportSlug) =>
      _json('sport/$sportSlug/available-category-filters');

  Future<List<SofascoreStage>> getScheduledStages(
    String sportSlug,
    String date,
  ) async =>
      SofascoreResponses.stages(
        await _json('stage/sport/$sportSlug/scheduled/$date'),
      );

  Future<Map<String, dynamic>> getStageDetailsRaw(int stageId) =>
      _json('stage/$stageId');

  Future<Map<String, dynamic>> getStageDetailsExtendedRaw(int stageId) =>
      _json('stage/$stageId/extended');

  Future<SofascoreStage?> getStageDetailsExtended(int stageId) async =>
      SofascoreResponses.stage(await _json('stage/$stageId/extended'));

  Future<Map<String, dynamic>> getStageSubstages(int stageId) =>
      _json('stage/$stageId/v2/substages');

  Future<Map<String, dynamic>> getStageHighlights(int stageId) =>
      _json('stage/$stageId/highlights');

  Future<Map<String, dynamic>> getStageCompetitorStandings(int stageId) =>
      _json('stage/$stageId/standings/competitor');

  Future<Map<String, dynamic>> getStageTeamStandings(int stageId) =>
      _json('stage/$stageId/standings/team');

  Future<Map<String, dynamic>> getUniqueStageSeasonsRaw(int uniqueStageId) =>
      _json('unique-stage/$uniqueStageId/seasons');

  Future<List<SofascoreStage>> getUniqueStageSeasons(int uniqueStageId) async =>
      SofascoreResponses.stageSeasons(
        await _json('unique-stage/$uniqueStageId/seasons'),
      );

  Future<Map<String, dynamic>> getUniqueStageRecentStageIds(int uniqueStageId) =>
      _json('unique-stage/$uniqueStageId/recent-stage-ids');

  Future<Map<String, dynamic>> getStageSeasonRaces(
    int stageId, [
    String outrightTeamType = 'competitor',
  ]) =>
      _json('stage/$stageId/races/type/$outrightTeamType');

  Future<Map<String, dynamic>> getStageCountryChannels(int stageId) =>
      _json('tv/stage/$stageId/country-channels');

  // ---- Gợi ý theo dõi ----
  Future<List<UniqueTournament>> getDefaultPinnedTournaments([
    String alpha2 = 'VN',
  ]) async =>
      SofascoreResponses.uniqueTournaments(
        await _json('config/follow-suggestions/unique-tournaments/$alpha2'),
      );

  Future<List<UniqueTournament>> getDefaultPinnedTournamentsForSport(
    String sportSlug, [
    String alpha2 = 'VN',
  ]) async =>
      SofascoreResponses.uniqueTournaments(
        await _json(
          'config/follow-suggestions/unique-tournaments/$alpha2/sport/$sportSlug',
        ),
      );

  Future<List<UniqueTournament>> getDefaultUniqueTournaments([
    String countryCode = 'VN',
  ]) async =>
      SofascoreResponses.uniqueTournaments(
        await _json('config/default-unique-tournaments/$countryCode'),
      );

  Future<List<Team>> getDefaultSuggestedTeams([String alpha2 = 'VN']) async =>
      SofascoreResponses.teams(
        await _json('config/follow-suggestions/teams/$alpha2'),
      );

  Future<List<Team>> getDefaultSuggestedTeamsForSport(
    String sportSlug, [
    String alpha2 = 'VN',
  ]) async =>
      SofascoreResponses.teams(
        await _json('config/follow-suggestions/teams/$alpha2/sport/$sportSlug'),
      );

  Future<List<PlayerSuggestionItem>> getDefaultSuggestedPlayers([
    String alpha2 = 'VN',
  ]) async =>
      SofascoreResponses.players(
        await _json('config/follow-suggestions/players/$alpha2'),
      );

  // ---- Sự kiện ----
  Future<List<SofascoreEvent>> getNewlyAddedEvents() async =>
      SofascoreResponses.events(await _json('event/newly-added-events'));

  Future<SofascoreEvent?> getEventDetails(int eventId) async =>
      SofascoreResponses.event(await _json('event/$eventId'));

  Future<Map<String, dynamic>> getEventDetailsRaw(int eventId) =>
      _json('event/$eventId');

  Future<Map<String, dynamic>> getEventIncidents(int eventId) =>
      _json('event/$eventId/incidents');

  Future<Map<String, dynamic>> getEventBestPlayers(int eventId) =>
      _json('event/$eventId/best-players');

  Future<Map<String, dynamic>> getEventAtBats(int eventId) =>
      _json('event/$eventId/at-bats');

  Future<Map<String, dynamic>> getBaseballTopPerformers(int eventId) =>
      _json('event/baseball/$eventId/top-performers');

  Future<Map<String, dynamic>> getEventUmpires(int eventId) =>
      _json('event/$eventId/umpires');

  Future<Map<String, dynamic>> getEventWeather(int eventId) =>
      _json('event/$eventId/weather');

  Future<Map<String, dynamic>> getEventLineups(int eventId) =>
      _json('event/$eventId/lineups');

  Future<Map<String, dynamic>> getEventStatistics(int eventId) =>
      _json('event/$eventId/statistics');

  Future<Map<String, dynamic>> getEventInnings(int eventId) =>
      _json('event/$eventId/innings');

  Future<Map<String, dynamic>> getEventOdds(int eventId) =>
      _json('event/$eventId/odds/1/all');

  Future<Map<String, dynamic>> getEventVotes(int eventId) =>
      _json('event/$eventId/votes');

  /// Đối đầu tổng hợp (`teamDuel`), khác `event/{customId}/h2h/events` vốn trả
  /// danh sách trận.
  Future<Map<String, dynamic>> getEventH2H(int eventId) =>
      _json('event/$eventId/h2h');

  Future<Map<String, dynamic>> getEventPregameForm(int eventId) =>
      _json('event/$eventId/pregame-form');

  Future<Map<String, dynamic>> getEventComments(int eventId) =>
      _json('event/$eventId/comments/en');

  Future<Map<String, dynamic>> getHeadToHeadEvents(String customId) =>
      _json('event/$customId/h2h/events');

  Future<Map<String, dynamic>> getEventSuggests(int eventId) =>
      _json('event/$eventId/suggests');

  Future<Map<String, dynamic>> getEventGraph(int eventId) =>
      _json('event/$eventId/graph');

  Future<Map<String, dynamic>> getEventGraphSequence(int eventId) =>
      _json('event/$eventId/graph/sequence');

  Future<Map<String, dynamic>> getEventCricketGraph(int eventId) =>
      _json('event/$eventId/graph/cricket');

  Future<Map<String, dynamic>> getEventPointByPoint(int eventId) =>
      _json('event/$eventId/point-by-point');

  Future<Map<String, dynamic>> getEventTennisPower(int eventId) =>
      _json('event/$eventId/tennis-power');

  /// Phân tích AI **sau trận**, đa ngôn ngữ — trận chưa đá trả 404.
  ///
  /// Bản trước trận (`event/{id}/ai-insights/{lang}`) đòi JWT tài khoản
  /// Sofascore nên không dùng được; xem `docs/API_dang_su_dung.md`.
  Future<Map<String, dynamic>> getEventAiInsightsPostmatchLang(
    int eventId,
    String language,
  ) =>
      _json('event/$eventId/ai-insights-postmatch/$language');

  Future<Map<String, dynamic>> getPlayerDetails(int playerId) =>
      _json('player/$playerId');

  /// Danh sách giải/mùa mà cầu thủ có số liệu.
  /// Giải bóng đá Sofascore gợi ý cho **một quốc gia**.
  ///
  /// Đây là thứ mang tính khu vực: bản VN có V-League 1 và ASEAN Championship
  /// nằm cùng danh sách với Ngoại hạng Anh và Champions League, dù số người
  /// theo dõi chênh nhau vài trăm lần.
  Future<List<UniqueTournament>> getFollowSuggestedTournaments(
    String countryCode,
    String sportSlug,
  ) async {
    final body = await _json(
      'config/follow-suggestions/unique-tournaments/$countryCode/sport/$sportSlug',
    );
    final list = body['uniqueTournaments'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => UniqueTournament.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getPlayerSeasons(int playerId) =>
      _json('player/$playerId/statistics/seasons');

  Future<Map<String, dynamic>> getPlayerSeasonStatistics(
    int playerId,
    int tournamentId,
    int seasonId,
  ) =>
      _json(
        'player/$playerId/unique-tournament/$tournamentId/season/$seasonId/statistics/overall',
      );

  Future<Map<String, dynamic>> getPlayerLastEvents(int playerId, [int page = 0]) =>
      _json('player/$playerId/events/last/$page');

  Future<Map<String, dynamic>> getEventAiInsightsPostmatch(int eventId) =>
      _json('event/$eventId/ai-insights-postmatch/en');

  Future<Map<String, dynamic>> getEventMediaSummary(
    int eventId,
    String countryCode,
  ) =>
      _json('event/$eventId/media/summary/country/$countryCode');

  Future<Map<String, dynamic>> getEventCountryChannels(int eventId) =>
      _json('tv/event/$eventId/country-channels');

  // ---- Esports ----
  Future<Map<String, dynamic>> getEventEsportsGames(int eventId) =>
      _json('event/$eventId/esports-games');

  Future<Map<String, dynamic>> getEsportsGameStatistics(int gameId) =>
      _json('esports-game/$gameId/statistics');

  Future<Map<String, dynamic>> getEsportsGameLineups(int gameId) =>
      _json('esports-game/$gameId/lineups');

  Future<Map<String, dynamic>> getEsportsGameBans(int gameId) =>
      _json('esports-game/$gameId/bans');

  Future<Map<String, dynamic>> getEsportsGameRounds(int gameId) =>
      _json('esports-game/$gameId/rounds');

  // ---- MMA ----
  Future<List<SofascoreEvent>> getMmaMainEvents(String date) async =>
      SofascoreResponses.events(await _json('sport/mma/main-events/$date'));

  Future<List<SofascoreEvent>> getMmaEvents(
    int uniqueTournamentId,
    int tournamentId,
    String fightType,
  ) async =>
      SofascoreResponses.events(
        await _json(
          'unique-tournament/$uniqueTournamentId/tournament/$tournamentId/mma-events/$fightType',
        ),
      );

  Future<UniqueTournamentDetail?> getMmaUniqueTournamentDetail(int id) async =>
      SofascoreResponses.uniqueTournamentDetail(await _json('unique-tournament/$id'));

  Future<List<SofascoreEvent>> getMmaFeaturedEvents(int uniqueTournamentId) async =>
      SofascoreResponses.featuredEvents(
        await _json('unique-tournament/$uniqueTournamentId/featured-events'),
      );

  Future<List<SofascoreEvent>> getMmaMainEventsNext(
    int uniqueTournamentId, [
    int page = 0,
  ]) async =>
      SofascoreResponses.events(
        await _json('unique-tournament/$uniqueTournamentId/main-events/next/$page'),
      );

  Future<List<SofascoreEvent>> getMmaMainEventsLast(
    int uniqueTournamentId, [
    int page = 0,
  ]) async =>
      SofascoreResponses.events(
        await _json('unique-tournament/$uniqueTournamentId/main-events/last/$page'),
      );

  // ---- Đội & cầu thủ ----
  Future<Map<String, dynamic>> getTeamDetails(int teamId) => _json('team/$teamId');

  Future<Map<String, dynamic>> getTeamLastEvents(int teamId, [int page = 0]) =>
      _json('team/$teamId/events/last/$page');

  Future<Map<String, dynamic>> getTeamNextEvents(int teamId, [int page = 0]) =>
      _json('team/$teamId/events/next/$page');

  Future<Map<String, dynamic>> getTeamPlayers(int teamId) =>
      _json('team/$teamId/players');

  Future<Map<String, dynamic>> getTeamTournaments(int teamId) =>
      _json('team/$teamId/tournaments');

  Future<Map<String, dynamic>> getTeamTransfers(int teamId) =>
      _json('team/$teamId/transfers');

  Future<Map<String, dynamic>> getTeamRankings(int teamId) =>
      _json('rankings/team/$teamId');
}
