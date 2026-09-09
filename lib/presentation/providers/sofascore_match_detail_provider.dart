import '../../core/error/either.dart';
import '../../core/error/failures.dart';
import '../../data/models/sofascore/sofascore_models.dart';
import '../../data/repositories/sofascore_repository_impl.dart';
import 'base_provider.dart';

/// Port `presentation/SofascoreMatchDetailActivity.kt`.
/// Bản gốc nạp 10 payload song song rồi tự dựng danh sách tab theo dữ liệu
/// nào thực sự có — provider này giữ nguyên cách đó.
class SofascoreMatchDetailProvider extends BaseProvider {
  SofascoreMatchDetailProvider(this._repo);

  final SofascoreRepositoryImpl _repo;

  SofascoreEvent? _event;
  Map<String, dynamic> _raw = const {};
  final Map<String, Map<String, dynamic>> _payloads = {};
  bool _isLoading = false;
  Failure? _failure;

  SofascoreEvent? get event => _event;
  Map<String, dynamic> get raw => _raw;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  Map<String, dynamic> payload(String key) => _payloads[key] ?? const {};

  // ---- Truy vấn dữ liệu đã phẳng hoá ----

  List<Map<String, dynamic>> get incidents => _list(payload('Incidents')['incidents']);

  List<Map<String, dynamic>> get h2hEvents => _list(payload('Matches')['events']);

  List<Map<String, dynamic>> get esportsGames {
    final p = payload('EsportsGames');
    final games = _list(p['games']);
    return games.isNotEmpty ? games : _list(p['events']);
  }

  List<Map<String, dynamic>> get tvChannels {
    final p = payload('TvChannels');
    final byCountry = p['countryChannels'];
    if (byCountry is! Map) return const [];
    final out = <Map<String, dynamic>>[];
    for (final entry in byCountry.entries) {
      for (final ch in _list(entry.value)) {
        out.add({...ch, 'country': entry.key});
      }
    }
    return out;
  }

  Map<String, dynamic> get votes {
    final v = payload('Votes')['vote'];
    return v is Map ? Map<String, dynamic>.from(v) : const {};
  }

  /// `{statistics:[{groups:[{groupName, statisticsItems:[...]}]}]}`.
  List<(String, String, String, String)> get statisticRows {
    final periods = payload('Statistics')['statistics'];
    if (periods is! List || periods.isEmpty) return const [];
    final all = periods.first;
    if (all is! Map) return const [];
    final rows = <(String, String, String, String)>[];
    for (final group in _list(all['groups'])) {
      final groupName = '${group['groupName'] ?? ''}';
      for (final item in _list(group['statisticsItems'])) {
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

  List<Map<String, dynamic>> lineupPlayers({required bool home}) {
    final side = payload('Lineups')[home ? 'home' : 'away'];
    if (side is! Map) return const [];
    return _list(side['players']);
  }

  String? lineupFormation({required bool home}) {
    final side = payload('Lineups')[home ? 'home' : 'away'];
    return side is Map ? side['formation']?.toString() : null;
  }

  /// `{standings:[{rows:[...]}]}` — lấy bảng đầu tiên có dữ liệu.
  List<Map<String, dynamic>> get standingRows {
    for (final table in _list(payload('Standings')['standings'])) {
      final rows = _list(table['rows']);
      if (rows.isNotEmpty) return rows;
    }
    return const [];
  }

  List<Map<String, dynamic>> get pointByPointSets =>
      _list(payload('PointByPoint')['pointByPoint']);

  /// Điểm từng hiệp/set lấy từ `homeScore`/`awayScore` của event.
  List<(String, String, String)> get periodScores {
    final home = _event?.homeScore;
    final away = _event?.awayScore;
    if (home == null || away == null) return const [];
    const keys = ['period1', 'period2', 'period3', 'period4', 'period5'];
    final rows = <(String, String, String)>[];
    for (var i = 0; i < keys.length; i++) {
      final h = home.periods.length > i ? home.periods[i] : null;
      final a = away.periods.length > i ? away.periods[i] : null;
      if (h == null && a == null) continue;
      rows.add(('${i + 1}', h?.toString() ?? '-', a?.toString() ?? '-'));
    }
    if (home.normaltime != null || away.normaltime != null) {
      rows.add((
        'FT',
        home.normaltime?.toString() ?? '-',
        away.normaltime?.toString() ?? '-',
      ));
    }
    return rows;
  }

  bool get isEsports {
    final slug = _event?.sportSlug.toLowerCase() ?? '';
    return slug == 'esports' || esportsGames.isNotEmpty;
  }

  /// Port `rebuildAvailableTabs()` — chỉ thêm tab khi có dữ liệu tương ứng.
  List<SofaTab> get availableTabs => [
        SofaTab.info,
        if (lineupPlayers(home: true).isNotEmpty ||
            lineupPlayers(home: false).isNotEmpty)
          SofaTab.lineup,
        if (statisticRows.isNotEmpty) SofaTab.stats,
        if (h2hEvents.isNotEmpty) SofaTab.h2h,
        if (standingRows.isNotEmpty) SofaTab.table,
      ];

  Future<void> load(int eventId) async {
    if (eventId <= 0) return;
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final detail = await _repo.getEventDetailsRaw(eventId);
    detail.fold(
      (f) => _failure = f,
      (json) {
        _raw = json;
        final ev = json['event'];
        if (ev is Map) {
          _event = SofascoreEvent.fromJson(Map<String, dynamic>.from(ev));
        }
      },
    );
    // Hiện header ngay, các thẻ còn lại nạp sau — giống `bindHeader()`.
    notifyListeners();

    final customId = '${_raw['event']?['customId'] ?? ''}';
    final tournamentId = _event?.tournament?.uniqueTournament?.id ?? 0;
    final seasonId = _seasonId;

    final results = await Future.wait([
      _repo.getEventIncidents(eventId),
      _repo.getEventStatistics(eventId),
      _repo.getEventLineups(eventId),
      _repo.getEventOdds(eventId),
      _repo.getEventVotes(eventId),
      customId.isEmpty
          ? Future.value(const Right<Failure, Map<String, dynamic>>({}))
          : _repo.getHeadToHead(customId),
      tournamentId > 0 && seasonId > 0
          ? _repo.getTournamentStandings(tournamentId, seasonId)
          : Future.value(const Right<Failure, Map<String, dynamic>>({})),
      _repo.getEventPointByPoint(eventId),
      _repo.getEventCountryChannels(eventId),
      _repo.getEventEsportsGames(eventId),
    ]);

    const keys = [
      'Incidents',
      'Statistics',
      'Lineups',
      'Odds',
      'Votes',
      'Matches',
      'Standings',
      'PointByPoint',
      'TvChannels',
      'EsportsGames',
    ];
    for (var i = 0; i < keys.length; i++) {
      results[i].fold((_) {}, (json) => _payloads[keys[i]] = json);
    }

    setState(() => _isLoading = false);
  }

  int get _seasonId {
    final season = _raw['event']?['season'];
    if (season is Map) {
      final id = season['id'];
      if (id is num) return id.toInt();
    }
    return 0;
  }

  static List<Map<String, dynamic>> _list(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }
}

enum SofaTab { info, lineup, stats, h2h, table }
