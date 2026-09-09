import '../../core/utils/date_time_utils.dart';
import '../../core/utils/sport_presentation.dart';
import '../../domain/entities/event_list_item.dart';
import '../../domain/entities/match_entities.dart';
import '../models/sofascore/sofascore_models.dart';

/// Đưa dữ liệu Sofascore về cùng entity mà UI bóng đá đang dùng,
/// nhờ vậy `HomeScreen` chỉ có một đường vẽ danh sách.
class SofascoreMapper {
  const SofascoreMapper._();

  static MatchFixture toFixture(SofascoreEvent event, {String? leagueName}) {
    final statusType = event.statusType;
    final phase = SportPresentation.eventPhase(statusType);
    final sportSlug = event.sportSlug;
    final started = SportPresentation.usesStartedEventPresentation(statusType);

    return MatchFixture(
      id: '${event.id}',
      teamHome: event.homeTeam?.name ?? '',
      teamAway: event.awayTeam?.name ?? '',
      scoreHome: started ? event.homeScore?.current : null,
      scoreAway: started ? event.awayScore?.current : null,
      matchTime: DateTimeUtils.formatEpochToLocalTime(event.startTimestamp),
      status: _statusLabel(phase, event),
      homeLogoUrl: _competitorImage(event.homeTeam, sportSlug),
      awayLogoUrl: _competitorImage(event.awayTeam, sportSlug),
      matchDate: DateTimeUtils.formatEpochToLocalDate(event.startTimestamp),
      leagueName: leagueName ?? event.tournament?.name,
      kickoffUtc: '${event.startTimestamp}',
      state: 0,
      categoryName: event.tournament?.category?.name,
      isFootball: false,
      sportSlug: sportSlug,
      homeSubScore: _subScore(event.homeScore, sportSlug),
      awaySubScore: _subScore(event.awayScore, sportSlug),
      homePeriods: event.homeScore?.periods ?? const [],
      awayPeriods: event.awayScore?.periods ?? const [],
      winnerCode: event.winnerCode,
    );
  }

  static String _statusLabel(EventPhase phase, SofascoreEvent event) =>
      switch (phase) {
        EventPhase.live =>
          event.status?.description?.isNotEmpty == true
              ? event.status!.description!
              : 'LIVE',
        EventPhase.finished => 'FT',
        EventPhase.prematch => 'NS',
        EventPhase.interrupted => 'INT',
        EventPhase.canceled => 'CANCL',
        EventPhase.unknown => event.status?.description ?? 'TBD',
      };

  /// Tennis hiển thị cờ quốc gia thay vì logo đội.
  static String? _competitorImage(Team? team, String sportSlug) {
    if (team == null) return null;
    if (SportPresentation.homeCompetitorImage(sportSlug) ==
        HomeCompetitorImage.countryFlag) {
      return team.country?.flagUrl ?? team.logoUrl;
    }
    return team.logoUrl;
  }

  /// Điểm phụ: tennis/bóng chuyền hiển thị số set thắng bên cạnh điểm game.
  static String? _subScore(Score? score, String sportSlug) {
    if (score == null) return null;
    if (!SportPresentation.usesSetPointSecondaryScore(sportSlug) &&
        SportPresentation.homeScoreProfile(sportSlug) !=
            HomeScoreProfile.tennisGameAndSets) {
      return null;
    }
    final display = score.display;
    return display == null ? null : '$display';
  }

  /// Gộp feed phẳng (`EventListItem`) thành nhóm giải cho UI dùng chung.
  static List<LeagueSection> toLeagueSections(
    List<EventListItem> items,
    String sportSlug,
  ) {
    final sections = <LeagueSection>[];
    TournamentSubHeaderItem? currentHeader;
    var buffer = <MatchFixture>[];

    void flush() {
      final header = currentHeader;
      if (header == null || buffer.isEmpty) return;
      sections.add(LeagueSection(
        leagueName: header.tournamentName,
        leagueLogoUrl: header.logoUrl,
        fixtures: List.unmodifiable(buffer),
        leagueId: header.uniqueTournamentId,
        categoryName: header.categoryName,
        isFootball: false,
        sportSlug: sportSlug,
      ));
      buffer = <MatchFixture>[];
    }

    for (final item in items) {
      switch (item) {
        case TournamentSubHeaderItem():
          flush();
          currentHeader = item;
        case MatchItem(:final event):
          final header = currentHeader;
          if (header != null) {
            buffer.add(toFixture(event, leagueName: header.tournamentName));
          }
        case SectionHeaderItem():
          flush();
          currentHeader = null;
        default:
          break;
      }
    }
    flush();
    return sections;
  }

  /// Trận đang đá — dùng cho carousel Live ở đầu màn Home.
  static List<LiveMatch> toLiveMatches(List<EventListItem> items) {
    final result = <LiveMatch>[];
    for (final item in items) {
      if (item is! MatchItem) continue;
      final event = item.event;
      if (event.status?.type?.toLowerCase() != 'inprogress') continue;
      result.add(LiveMatch(
        id: '${event.id}',
        teamHome: event.homeTeam?.name ?? '',
        teamAway: event.awayTeam?.name ?? '',
        scoreHome: event.homeScore?.current ?? 0,
        scoreAway: event.awayScore?.current ?? 0,
        matchTime: event.status?.description ?? 'LIVE',
        leagueName: event.tournament?.name ?? '',
        homeLogoUrl: event.homeTeam?.logoUrl,
        awayLogoUrl: event.awayTeam?.logoUrl,
        leagueLogoUrl: event.tournament?.uniqueTournament?.logoUrl,
        venue: '',
        region: event.tournament?.category?.name,
      ));
    }
    return result;
  }
}
