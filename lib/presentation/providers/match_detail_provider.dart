import '../../core/error/failures.dart';
import '../../core/services/notification_service.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/models/football/football_models.dart';
import '../../data/models/local/db_entities.dart';
import '../../data/repositories/football_sofascore_repository.dart';
import '../../domain/repositories/football_repository.dart';
import 'base_provider.dart';

/// Port `presentation/detail/MatchDetailViewModel.kt`.
class MatchDetailProvider extends BaseProvider {
  MatchDetailProvider(
    this._football,
    this._sofa,
    this._db,
    this._notifications,
  );

  final FootballRepository _football;
  final FootballSofascoreRepository _sofa;
  final LeagueDbHelper _db;
  final NotificationService _notifications;

  /// State cho phép hiện dự đoán — đúng danh sách của bản gốc.
  static const List<int> _predictionStates = [1, 2, 3, 4, 6, 7, 9, 21, 22, 23, 25];

  MatchCentreDataDto? _matchData;
  List<StandingTeamDto> _standings = const [];
  MatchVoteDto? _vote;
  int _matchState = 1;
  bool _isLoading = false;
  bool _isNotified = false;
  bool _isVoted = false;
  Failure? _failure;

  MatchCentreDataDto? get matchData => _matchData;
  MatchDetailDto? get match => _matchData?.match;
  List<MatchEventDto> get events => _matchData?.events ?? const [];
  List<MatchLineupDto> get lineups => _matchData?.lineups ?? const [];
  List<MatchStatisticsDto> get statistics => _matchData?.statistics ?? const [];
  List<MatchH2HDto> get h2h => _matchData?.h2h ?? const [];
  List<StandingTeamDto> get standings => _standings;
  MatchVoteDto? get vote => _vote;
  int get matchState => _matchState;
  bool get isLoading => _isLoading;
  bool get isNotified => _isNotified;
  bool get isVoted => _isVoted;
  Failure? get failure => _failure;

  bool get isPredictionAvailable => _predictionStates.contains(_matchState);

  int? get homeScore => _parseScore(0);
  int? get awayScore => _parseScore(1);

  int? _parseScore(int index) {
    final raw = match?.score;
    if (raw == null) return null;
    final parts = raw.split('-');
    if (parts.length <= index) return null;
    return int.tryParse(parts[index].trim());
  }

  /// Thống kê của đội nhà / đội khách trong danh sách `statistics`.
  MatchStatisticsDto? statsFor({required bool home}) {
    final teamId = home ? match?.homeId : match?.awayId;
    if (teamId == null) return null;
    for (final s in statistics) {
      if (s.teamId == teamId) return s;
    }
    return null;
  }

  List<MatchLineupDto> lineupFor({required bool home}) {
    final teamId = home ? match?.homeId : match?.awayId;
    if (teamId == null) return const [];
    return lineups.where((l) => l.teamId == teamId).toList(growable: false);
  }

  Future<void> loadMatchDetail(
    int matchId, {
    bool forceFetchForecast = false,
  }) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    _isNotified = await _db.isNotificationEnabled(matchId);
    await loadVote(matchId);

    // `matchId` giờ **chính là** eventId Sofascore vì feed Home đã đổi nguồn —
    // không cần dò theo tên nữa.
    final detail = await _sofa.getMatchCentreById(matchId);
    await detail.fold(
      (failure) async => setState(() => _failure = failure),
      (data) async {
        _matchData = data;
        _matchState = data.match?.state ?? 1;

        // BXH lấy từ Sofascore. Không dò theo tên giải mà đi qua chính trận
        // đó: `event/{id}` mang sẵn `uniqueTournament.id` + `season.id` nên
        // ghép đúng tuyệt đối, không sợ nhầm giải trùng tên.
        final bundle = await _sofa.getMatchBundleByEvent(matchId);
        bundle.fold((_) {}, (b) => _standings = b.standings);
      },
    );

    setState(() => _isLoading = false);
  }

  Future<void> loadVote(int fixtureId) async {
    final result = await _sofa.getVoteById(fixtureId);
    result.fold((_) {}, (data) => setState(() => _vote = data));
  }

  /// choice: 1 = home win, 2 = draw, 3 = away win.
  ///
  /// Sofascore **không cho ghi phiếu** (cần JWT tài khoản), nên chỉ ghi nhận
  /// lựa chọn tại máy rồi đọc lại số phiếu thật. Người dùng thấy lựa chọn của
  /// mình được giữ, con số hiển thị vẫn là số thật.
  Future<void> voteTeam(int fixtureId, int choice) async {
    final result = await _football.vote(fixtureId, choice);
    await result.fold(
      (_) async {
        setState(() => _isVoted = true);
        await loadVote(fixtureId);
      },
      (_) async {
        setState(() => _isVoted = true);
        await loadVote(fixtureId);
      },
    );
  }

  Future<void> toggleNotification({
    int beforeMatchMinutes = 15,
    bool notifyMatchStart = true,
    bool notifyEndFirstHalf = true,
    bool notifyStartSecondHalf = false,
    bool notifyEndMatch = false,
  }) async {
    final data = match;
    if (data == null) return;

    final item = NotificationDbItem(
      id: data.id,
      homeName: data.homeName ?? '',
      awayName: data.awayName ?? '',
      homeLogoUrl: data.homeTeamLogoUrl,
      awayLogoUrl: data.awayTeamLogoUrl,
      leagueName: data.leagueName,
      timeStr: data.kickoffUtc,
      status: data.score ?? 'NS',
      beforeMatchMinutes: beforeMatchMinutes,
      notifyMatchStart: notifyMatchStart,
      notifyEndFirstHalf: notifyEndFirstHalf,
      notifyStartSecondHalf: notifyStartSecondHalf,
      notifyEndMatch: notifyEndMatch,
    );

    final wasEnabled = await _db.isNotificationEnabled(item.id);
    await _db.toggleNotification(item);
    if (wasEnabled) {
      await _notifications.cancel(item.id);
    } else {
      await _notifications.schedule(item);
    }
    _isNotified = await _db.isNotificationEnabled(item.id);
    notifyListeners();
  }
}
