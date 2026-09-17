import '../models/football/football_models.dart';
import '../models/sofascore/sofascore_models.dart';

/// Dựng [MatchCentreDataDto] — thứ màn chi tiết trận bóng đá vẫn đang đọc — từ
/// các endpoint Sofascore.
///
/// Làm vậy để **giao diện không đổi**: `MatchDetailScreen` và 4 tab con giữ
/// nguyên, chỉ thay nguồn bên dưới. Nếu đổi sang màn Sofascore đa môn thì người
/// dùng thấy một màn hoàn toàn khác.
///
/// | Khối | Nguồn |
/// |---|---|
/// | `match` | `event/{id}` |
/// | `events` | `event/{id}/incidents` |
/// | `lineups` | `event/{id}/lineups` |
/// | `statistics` | `event/{id}/statistics` (chỉ period `ALL`) |
/// | `h2h` | `event/{id}/h2h` |
class SofascoreMatchCentreMapper {
  const SofascoreMatchCentreMapper._();

  static MatchCentreDataDto build({
    required SofascoreEvent event,
    Map<String, dynamic>? incidents,
    Map<String, dynamic>? lineups,
    Map<String, dynamic>? statistics,
    Map<String, dynamic>? h2h,
  }) {
    final homeId = event.homeTeam?.id ?? 0;
    final awayId = event.awayTeam?.id ?? 0;
    return MatchCentreDataDto(
      match: _match(event),
      events: _incidents(incidents, event.id, homeId, awayId),
      lineups: _lineups(lineups, event.id, homeId, awayId),
      statistics: _statistics(statistics, event.id, homeId, awayId),
      h2h: _h2h(h2h, event.id, homeId, awayId),
    );
  }

  // ------------------------------------------------------------------- match

  static MatchDetailDto _match(SofascoreEvent e) {
    final home = e.homeScore?.current;
    final away = e.awayScore?.current;
    return MatchDetailDto(
      id: e.id,
      leagueId: e.tournament?.uniqueTournament?.id ?? 0,
      seasonId: 0,
      name: '${e.homeTeam?.name ?? ''} vs ${e.awayTeam?.name ?? ''}',
      kickoffEpoch: e.startTimestamp,
      lengthMinutes: 90,
      state: _state(e),
      roundName: e.tournament?.name,
      // Màn chi tiết tách chuỗi này bằng dấu `-`, giữ đúng định dạng cũ.
      score: home == null || away == null ? null : '$home - $away',
      homeId: e.homeTeam?.id ?? 0,
      awayId: e.awayTeam?.id ?? 0,
      homeName: e.homeTeam?.name,
      awayName: e.awayTeam?.name,
      homeShortName: e.homeTeam?.shortName,
      awayShortName: e.awayTeam?.shortName,
      homeTeamLogoUrl: e.homeTeam?.logoUrl,
      awayTeamLogoUrl: e.awayTeam?.logoUrl,
      leagueLogoUrl: e.tournament?.uniqueTournament?.logoUrl,
      leagueName: e.tournament?.name,
      playingTime: 0,
    );
  }

  static int _state(SofascoreEvent e) => switch (e.statusType) {
        'notstarted' => 1,
        'inprogress' => 2,
        'finished' => 5,
        'postponed' => 10,
        'canceled' => 12,
        _ => 13,
      };

  // --------------------------------------------------------------- diễn biến

  /// `incidents` là mảng **trộn nhiều loại**, phân biệt bằng `incidentType`.
  /// Chỉ lấy loại nào màn timeline vẽ được; `period`, `injuryTime`,
  /// `varDecision`… bỏ qua.
  static List<MatchEventDto> _incidents(
    Map<String, dynamic>? body,
    int eventId,
    int homeId,
    int awayId,
  ) {
    final list = body?['incidents'];
    if (list is! List) return const [];

    final out = <MatchEventDto>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final i = Map<String, dynamic>.from(raw);

      final type = _typeName(i);
      if (type == null) continue;

      // `isHome` là bool, phải quy về teamId vì UI so với `match.homeId`.
      final isHome = i['isHome'];
      final teamId = isHome is bool ? (isHome ? homeId : awayId) : 0;
      if (teamId == 0) continue;

      final player = _obj(i['player']) ?? _obj(i['playerIn']);
      final related = _obj(i['assist1']) ?? _obj(i['playerOut']);

      out.add(MatchEventDto(
        id: _int(i['id']) ?? 0,
        fixtureId: eventId,
        teamId: teamId,
        typeName: type,
        minute: _int(i['time']) ?? 0,
        extraMinute: _int(i['addedTime']),
        playerId: _int(player?['id']) ?? 0,
        playerName: _str(player?['name']),
        relatedPlayerName: _str(related?['name']),
      ));
    }
    // Sofascore trả từ mới nhất về cũ nhất; timeline của app đọc xuôi.
    out.sort((a, b) => a.minute.compareTo(b.minute));
    return out;
  }

  /// Quy về đúng chuỗi mà `match_info_tab` và `match_lineup_tab` so khớp:
  /// `Goal` · `Penalty` · `Yellowcard` · `Redcard` · `Yellowred` ·
  /// `Substitution`.
  static String? _typeName(Map<String, dynamic> i) {
    final type = _str(i['incidentType'])?.toLowerCase();
    final klass = _str(i['incidentClass'])?.toLowerCase() ?? '';
    return switch (type) {
      'goal' => klass == 'penalty' ? 'Penalty' : 'Goal',
      'card' => switch (klass) {
          'yellow' => 'Yellowcard',
          'yellowred' => 'Yellowred',
          'red' => 'Redcard',
          _ => 'Yellowcard',
        },
      'substitution' => 'Substitution',
      _ => null,
    };
  }

  // ---------------------------------------------------------------- đội hình

  static List<MatchLineupDto> _lineups(
    Map<String, dynamic>? body,
    int eventId,
    int homeId,
    int awayId,
  ) {
    if (body == null) return const [];
    final out = <MatchLineupDto>[];
    for (final side in const ['home', 'away']) {
      final block = _obj(body[side]);
      if (block == null) continue;
      final teamId = side == 'home' ? homeId : awayId;
      final formation = _str(block['formation']);
      final players = block['players'];
      if (players is! List) continue;

      final slots = _pitchSlots(formation);
      var starterIndex = 0;

      for (final raw in players) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final player = _obj(row['player']);
        if (player == null) continue;

        final isSub = row['substitute'] == true;
        String? positionField;
        if (!isSub) {
          positionField = starterIndex < slots.length
              ? slots[starterIndex]
              : null;
          starterIndex++;
        }

        out.add(MatchLineupDto(
          id: _int(player['id']) ?? 0,
          fixtureId: eventId,
          teamId: teamId,
          playerId: _int(player['id']) ?? 0,
          playerName: _str(player['name']),
          playerImageUrl: _playerImage(_int(player['id'])),
          jerseyNumber: _int(row['shirtNumber']) ?? _int(player['jerseyNumber']),
          // Dự bị không có vị trí trên sân — để trống đúng như bản cũ.
          formation: isSub ? null : formation,
          positionField: positionField,
          isCaptain: row['captain'] == true ? 1 : 0,
        ));
      }
    }
    return out;
  }

  /// Dựng chuỗi `"hàng:cột"` cho từng cầu thủ đá chính.
  ///
  /// Sofascore **không trả toạ độ sân**, chỉ có `formation` (`"3-4-2-1"`) và
  /// mảng `players` xếp đúng thứ tự sơ đồ: thủ môn trước, rồi lần lượt từng
  /// tuyến. Bên Sportmonks thì có sẵn `positionField`, mà màn đội hình lọc
  /// thẳng `positionField.isNotEmpty` — thiếu nó là **cả sân trống trơn**.
  ///
  /// Hàng 1 luôn là thủ môn; mỗi số trong sơ đồ là một hàng tiếp theo. Bộ vẽ
  /// sân chỉ xử lý tối đa 5 hàng nên sơ đồ nhiều tuyến hơn (`4-1-2-1-2`) bị dồn
  /// hàng cuối lại — thà chen chúc còn hơn mất cầu thủ.
  static List<String> _pitchSlots(String? formation) {
    final lines = <int>[];
    for (final part in (formation ?? '').split('-')) {
      final n = int.tryParse(part.trim());
      if (n != null && n > 0) lines.add(n);
    }
    if (lines.isEmpty) lines.addAll(const [4, 4, 2]);

    final slots = <String>['1:1']; // thủ môn
    var row = 2;
    for (final count in lines) {
      final clamped = row > 5 ? 5 : row;
      for (var col = 1; col <= count; col++) {
        slots.add('$clamped:$col');
      }
      row++;
    }
    return slots;
  }

  static String? _playerImage(int? id) =>
      id == null || id == 0 ? null : 'https://img.sofascore.com/api/v1/player/$id/image';

  // -------------------------------------------------------------- thống kê

  /// Sofascore trả 3 period (`ALL` / `1ST` / `2ND`) × 7 nhóm chỉ số, còn màn cũ
  /// chỉ hiện 11 con số cho cả trận. Lấy period `ALL` rồi tra theo `key`.
  static List<MatchStatisticsDto> _statistics(
    Map<String, dynamic>? body,
    int eventId,
    int homeId,
    int awayId,
  ) {
    final periods = body?['statistics'];
    if (periods is! List) return const [];

    Map<String, dynamic>? all;
    for (final raw in periods) {
      if (raw is! Map) continue;
      final p = Map<String, dynamic>.from(raw);
      if (_str(p['period'])?.toUpperCase() == 'ALL') {
        all = p;
        break;
      }
    }
    all ??= periods.isEmpty ? null : Map<String, dynamic>.from(periods.first as Map);
    if (all == null) return const [];

    final home = <String, String>{};
    final away = <String, String>{};
    final groups = all['groups'];
    if (groups is List) {
      for (final g in groups) {
        if (g is! Map) continue;
        final items = g['statisticsItems'];
        if (items is! List) continue;
        for (final it in items) {
          if (it is! Map) continue;
          final key = _str(it['key']);
          if (key == null) continue;
          final h = _str(it['home']);
          final a = _str(it['away']);
          if (h != null) home[key] = h;
          if (a != null) away[key] = a;
        }
      }
    }
    if (home.isEmpty && away.isEmpty) return const [];

    return [
      _statsFor(eventId, homeId, home),
      _statsFor(eventId, awayId, away),
    ];
  }

  static MatchStatisticsDto _statsFor(
    int eventId,
    int teamId,
    Map<String, String> v,
  ) =>
      MatchStatisticsDto(
        fixtureId: eventId,
        teamId: teamId,
        // `"64%"` → 64; các giá trị khác là số trần.
        possession: _num(v['ballPossession']),
        shotOnTarget: _num(v['shotsOnGoal']),
        shotOffTarget: _num(v['shotsOffGoal']),
        blockerShots: _num(v['blockedScoringAttempt']),
        cornerKicks: _num(v['cornerKicks']),
        offsides: _num(v['offsides']),
        fouls: _num(v['fouls']),
        throwIn: _num(v['throwIns']),
        yellowCards: _num(v['yellowCards']),
        redCards: _num(v['redCards']),
      );

  // --------------------------------------------------------------- đối đầu

  /// `h2h` của Sofascore tính theo **đội 1 / đội 2 của chính nó**, mà thứ tự đó
  /// không chắc trùng nhà/khách của trận — nên phải đọc `teamDuel`.
  static List<MatchH2HDto> _h2h(
    Map<String, dynamic>? body,
    int eventId,
    int homeId,
    int awayId,
  ) {
    final duel = _obj(body?['teamDuel']);
    if (duel == null) return const [];
    return [
      MatchH2HDto(
        fixtureId: eventId,
        team1Id: homeId,
        team2Id: awayId,
        totalWin: _int(duel['homeWins']),
        totalDraws: _int(duel['draws']),
        totalLoss: _int(duel['awayWins']),
      ),
    ];
  }

  // ------------------------------------------------------------------ tiện ích

  static Map<String, dynamic>? _obj(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  static int? _int(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));

  static String? _str(Object? v) => v?.toString();

  /// Bỏ hậu tố `%` rồi mới parse — `"64%"` là dạng Sofascore hay dùng.
  static int? _num(String? v) {
    if (v == null || v.isEmpty) return null;
    final clean = v.replaceAll('%', '').trim();
    return int.tryParse(clean) ?? double.tryParse(clean)?.round();
  }
}
