import '../../core/error/failures.dart';
import '../../data/models/sofascore/sofascore_models.dart';
import '../../data/repositories/sofascore_repository_impl.dart';
import 'base_provider.dart';

/// Port `presentation/SofascoreMatchDetailActivity.kt` — chi tiết trận
/// của mọi môn ngoài bóng đá.
class SofascoreMatchDetailProvider extends BaseProvider {
  SofascoreMatchDetailProvider(this._repo);

  final SofascoreRepositoryImpl _repo;

  SofascoreEvent? _event;
  Map<String, dynamic> _incidents = const {};
  Map<String, dynamic> _statistics = const {};
  Map<String, dynamic> _lineups = const {};
  Map<String, dynamic> _votes = const {};
  Map<String, dynamic> _h2h = const {};
  bool _isLoading = false;
  Failure? _failure;

  SofascoreEvent? get event => _event;
  Map<String, dynamic> get incidents => _incidents;
  Map<String, dynamic> get statistics => _statistics;
  Map<String, dynamic> get lineups => _lineups;
  Map<String, dynamic> get votes => _votes;
  Map<String, dynamic> get h2h => _h2h;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  /// Danh sách nhóm thống kê đã phẳng hoá: (nhóm, tên, giá trị nhà, giá trị khách).
  List<(String, String, String, String)> get statisticRows {
    final periods = _statistics['statistics'];
    if (periods is! List || periods.isEmpty) return const [];
    final all = periods.first;
    if (all is! Map) return const [];
    final groups = all['groups'];
    if (groups is! List) return const [];

    final rows = <(String, String, String, String)>[];
    for (final group in groups) {
      if (group is! Map) continue;
      final groupName = '${group['groupName'] ?? ''}';
      final items = group['statisticsItems'];
      if (items is! List) continue;
      for (final item in items) {
        if (item is! Map) continue;
        rows.add((
          groupName,
          '${item['name'] ?? ''}',
          '${item['home'] ?? ''}',
          '${item['away'] ?? ''}',
        ));
      }
    }
    return rows;
  }

  /// Sự kiện trong trận (bàn thắng, thẻ...) — dùng cho tab Timeline.
  List<Map<String, dynamic>> get incidentList {
    final list = _incidents['incidents'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  Future<void> load(int eventId) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final detail = await _repo.getEventDetails(eventId);
    detail.fold((f) => _failure = f, (e) => _event = e);

    // Các lời gọi phụ chạy song song; thiếu cái nào thì bỏ qua cái đó.
    final results = await Future.wait([
      _repo.getEventIncidents(eventId),
      _repo.getEventStatistics(eventId),
      _repo.getEventLineups(eventId),
      _repo.getEventVotes(eventId),
    ]);

    results[0].fold((_) {}, (json) => _incidents = json);
    results[1].fold((_) {}, (json) => _statistics = json);
    results[2].fold((_) {}, (json) => _lineups = json);
    results[3].fold((_) {}, (json) => _votes = json);

    final customId = _event?.slug;
    if (customId != null && customId.isNotEmpty) {
      final h2h = await _repo.getHeadToHead(customId);
      h2h.fold((_) {}, (json) => _h2h = json);
    }

    setState(() => _isLoading = false);
  }
}

/// Port `presentation/SofascoreTeamDetailActivity.kt`.
class SofascoreTeamDetailProvider extends BaseProvider {
  SofascoreTeamDetailProvider(this._repo);

  final SofascoreRepositoryImpl _repo;

  Map<String, dynamic> _team = const {};
  var _lastEvents = const <SofascoreEvent>[];
  var _nextEvents = const <SofascoreEvent>[];
  Map<String, dynamic> _players = const {};
  bool _isLoading = false;

  Map<String, dynamic> get team => _team;
  List<SofascoreEvent> get lastEvents => _lastEvents;
  List<SofascoreEvent> get nextEvents => _nextEvents;
  bool get isLoading => _isLoading;

  /// Danh sách cầu thủ đã phẳng hoá từ `{players:[{player:{...}}]}`.
  List<Map<String, dynamic>> get squad {
    final list = _players['players'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e['player'] as Map? ?? e))
        .toList(growable: false);
  }

  Future<void> load(int teamId) async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _repo.getTeamDetails(teamId),
      _repo.getTeamPlayers(teamId),
    ]);
    results[0].fold((_) {}, (json) => _team = json);
    results[1].fold((_) {}, (json) => _players = json);

    final last = await _repo.getTeamEvents(teamId, last: true);
    last.fold((_) {}, (list) => _lastEvents = list.reversed.toList());

    final next = await _repo.getTeamEvents(teamId, last: false);
    next.fold((_) {}, (list) => _nextEvents = list);

    setState(() => _isLoading = false);
  }
}

/// Port `presentation/UniqueTournamentActivity.kt`.
class UniqueTournamentProvider extends BaseProvider {
  UniqueTournamentProvider(this._repo);

  final SofascoreRepositoryImpl _repo;

  List<SeasonInfo> _seasons = const [];
  SeasonInfo? _selectedSeason;
  Map<String, dynamic> _standings = const {};
  List<SofascoreEvent> _nextEvents = const [];
  List<SofascoreEvent> _lastEvents = const [];
  bool _isLoading = false;

  List<SeasonInfo> get seasons => _seasons;
  SeasonInfo? get selectedSeason => _selectedSeason;
  List<SofascoreEvent> get nextEvents => _nextEvents;
  List<SofascoreEvent> get lastEvents => _lastEvents;
  bool get isLoading => _isLoading;

  /// Bảng xếp hạng đã phẳng hoá từ `{standings:[{rows:[...]}]}`.
  List<Map<String, dynamic>> get standingRows {
    final list = _standings['standings'];
    if (list is! List || list.isEmpty) return const [];
    final first = list.first;
    if (first is! Map) return const [];
    final rows = first['rows'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  Future<void> load(int tournamentId) async {
    setState(() => _isLoading = true);

    final seasons = await _repo.getTournamentSeasons(tournamentId);
    seasons.fold((_) {}, (list) {
      _seasons = list;
      _selectedSeason = list.isEmpty ? null : list.first;
    });

    final season = _selectedSeason;
    if (season != null) await _fetchSeason(tournamentId, season.id);

    setState(() => _isLoading = false);
  }

  Future<void> selectSeason(int tournamentId, SeasonInfo season) async {
    setState(() {
      _selectedSeason = season;
      _isLoading = true;
    });
    await _fetchSeason(tournamentId, season.id);
    setState(() => _isLoading = false);
  }

  /// Port `fetchSeasonDetails()`: trận sắp tới, trận đã đá và bảng xếp hạng.
  Future<void> _fetchSeason(int tournamentId, int seasonId) async {
    final results = await Future.wait([
      _repo.getSeasonNextEvents(tournamentId, seasonId),
      _repo.getSeasonLastEvents(tournamentId, seasonId),
    ]);
    results[0].fold((_) => _nextEvents = const [], (list) => _nextEvents = list);
    results[1].fold(
      (_) => _lastEvents = const [],
      (list) => _lastEvents = list.reversed.toList(growable: false),
    );

    final standings = await _repo.getTournamentStandings(tournamentId, seasonId);
    standings.fold((_) => _standings = const {}, (json) => _standings = json);
  }

  /// Đội tham dự lấy từ chính các hàng của bảng xếp hạng.
  List<Team> get participatingTeams {
    final teams = <Team>[];
    final seen = <int>{};
    for (final row in standingRows) {
      final team = row['team'];
      if (team is! Map) continue;
      final parsed = Team.fromJson(Map<String, dynamic>.from(team));
      if (seen.add(parsed.id)) teams.add(parsed);
    }
    return teams;
  }
}

/// Port `MmaTournamentActivity.kt`: hai tab `maincard` / `prelims`.
/// Có `tournamentId` thì gọi `mma-events/{fightType}`, không thì rơi về
/// `main-events/next` (maincard) và `main-events/last` (prelims).
class MmaTournamentProvider extends BaseProvider {
  MmaTournamentProvider(this._repo);

  final SofascoreRepositoryImpl _repo;

  UniqueTournamentDetail? _detail;
  Tournament? _tournament;
  List<SofascoreEvent> _fights = const [];
  String _tab = 'maincard';
  bool _isLoading = false;

  UniqueTournamentDetail? get detail => _detail;
  Tournament? get tournament => _tournament;
  List<SofascoreEvent> get fights => _fights;
  String get tab => _tab;
  bool get isLoading => _isLoading;

  int _uniqueTournamentId = 0;
  int _tournamentId = 0;

  /// Nhãn mục của bản gốc: trận đầu là Main Event, trận thứ hai Co-Main Event.
  String? sectionHeaderFor(int index) {
    if (_tab != 'maincard') return null;
    if (index == 0) return 'Main Event';
    if (index == 1) return 'Co-Main Event';
    return null;
  }

  Future<void> load(int uniqueTournamentId, {int tournamentId = 0}) async {
    _uniqueTournamentId = uniqueTournamentId;
    _tournamentId = tournamentId;
    setState(() => _isLoading = true);

    final detail = await _repo.getMmaTournamentDetail(uniqueTournamentId);
    detail.fold((_) {}, (d) => _detail = d);

    if (tournamentId > 0) {
      final t = await _repo.getTournament(tournamentId);
      t.fold((_) {}, (value) => _tournament = value);
    }

    await _loadFights();
    setState(() => _isLoading = false);
  }

  Future<void> selectTab(String tab) async {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _isLoading = true;
      _fights = const [];
    });
    await _loadFights();
    setState(() => _isLoading = false);
  }

  Future<void> _loadFights() async {
    if (_tournamentId > 0) {
      final result = await _repo.getMmaEvents(
        _uniqueTournamentId,
        _tournamentId,
        _tab,
      );
      result.fold((_) => _fights = const [], (list) => _fights = list);
      return;
    }
    final result = await _repo.getMmaMainEventsPaged(
      _uniqueTournamentId,
      next: _tab == 'maincard',
    );
    result.fold((_) => _fights = const [], (list) => _fights = list);
  }
}

/// Port `MotorsportSeriesActivity.kt`.
class MotorsportSeriesProvider extends BaseProvider {
  MotorsportSeriesProvider(this._repo);

  final SofascoreRepositoryImpl _repo;

  List<SofascoreStage> _seasons = const [];
  SofascoreStage? _selectedSeason;
  List<SofascoreStage> _races = const [];
  bool _isLoading = false;

  List<SofascoreStage> get seasons => _seasons;
  SofascoreStage? get selectedSeason => _selectedSeason;
  List<SofascoreStage> get races => _races;
  bool get isLoading => _isLoading;

  Future<void> load(int uniqueStageId) async {
    setState(() => _isLoading = true);

    final seasons = await _repo.getUniqueStageSeasons(uniqueStageId);
    seasons.fold((_) {}, (list) {
      _seasons = list;
      _selectedSeason = list.isEmpty ? null : list.first;
    });

    final season = _selectedSeason;
    if (season != null) await _loadRaces(season);

    setState(() => _isLoading = false);
  }

  Future<void> selectSeason(SofascoreStage season) async {
    setState(() {
      _selectedSeason = season;
      _isLoading = true;
    });
    await _loadRaces(season);
    setState(() => _isLoading = false);
  }

  Future<void> _loadRaces(SofascoreStage season) async {
    final detail = await _repo.getStageDetails(season.id);
    detail.fold(
      (_) => _races = const [],
      (stage) => _races = stage.substages ?? const [],
    );
  }
}

/// Port `MotorsportStageActivity.kt` — một chặng đua cụ thể.
class MotorsportStageProvider extends BaseProvider {
  MotorsportStageProvider(this._repo);

  final SofascoreRepositoryImpl _repo;

  SofascoreStage? _stage;
  Map<String, dynamic> _standings = const {};
  Map<String, dynamic> _substages = const {};
  bool _isLoading = false;

  SofascoreStage? get stage => _stage;
  bool get isLoading => _isLoading;

  /// Kết quả chặng — `{standings:[{...}]}`.
  List<Map<String, dynamic>> get standingRows {
    final list = _standings['standings'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  /// Các phiên trong chặng (practice / qualifying / race).
  List<Map<String, dynamic>> get sessions {
    final list = _substages['substages'] ?? _substages['stages'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  Future<void> load(int stageId) async {
    setState(() => _isLoading = true);

    final detail = await _repo.getStageDetails(stageId);
    detail.fold((_) {}, (s) => _stage = s);

    final results = await Future.wait([
      _repo.getStageStandings(stageId),
      _repo.getStageSubstages(stageId),
    ]);
    results[0].fold((_) {}, (json) => _standings = json);
    results[1].fold((_) {}, (json) => _substages = json);

    setState(() => _isLoading = false);
  }
}
