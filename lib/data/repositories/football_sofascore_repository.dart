import 'dart:developer' as dev;

import '../../core/error/either.dart';
import '../../core/error/exceptions.dart' as app;
import '../../core/constants/api_constants.dart';
import '../../core/error/failures.dart';
import '../../core/utils/date_time_utils.dart';
import '../datasources/remote/sofascore_id_resolver.dart';
import '../datasources/remote/sofascore_remote_data_source.dart';
import '../mappers/sofascore_match_centre_mapper.dart';
import '../models/football/football_models.dart';
import '../models/sofascore/match_prediction.dart';
import '../models/sofascore/sofascore_models.dart';

/// Cầu nối: lấy dữ liệu **bóng đá** từ Sofascore rồi đổ vào đúng những DTO mà
/// màn hình đang dùng (`StandingTeamDto`, `UpcomingFixtureDto`,
/// `FavoriteFixtureDto`, `SquadPlayerDto`).
///
/// Giữ nguyên DTO là cố ý: màn BXH, lịch giải, đội hình không phải sửa một
/// dòng nào, chỉ provider đổi nguồn. Đổi lại phải chấp nhận vài trường của
/// Sofascore bị bỏ (ví dụ `weight` — Sofascore không có).
///
/// Mọi đầu vào là **tên** chứ không phải id, vì app đánh số theo Sportmonks
/// còn Sofascore có hệ riêng — [SofascoreIdResolver] lo phần dịch id.
class FootballSofascoreRepository {
  FootballSofascoreRepository(this._api, this._resolver);

  final SofascoreRemoteDataSource _api;
  final SofascoreIdResolver _resolver;

  static const String _tag = 'FootballSofa';

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

  /// Gọi được thì trả kết quả, lỗi thì trả `null` — dùng cho phần phụ, hỏng
  /// một mảnh không nên làm sập cả màn.
  Future<Map<String, dynamic>?> _tryJson(
    Future<Map<String, dynamic>> Function() body,
    String label,
  ) async {
    try {
      return await body();
    } catch (e) {
      dev.log('$label lỗi: $e', name: _tag);
      return null;
    }
  }

  // ------------------------------------------------------------- Dự đoán

  /// Thay `match-forecast-new` — endpoint cũ hỏng hoàn toàn.
  ///
  /// Ba nguồn chạy **song song** sau khi đã có `eventId`; trận chưa đá thì
  /// `ai-insights-postmatch` trả 404 và bị bỏ qua, hai nguồn kia vẫn có.
  Future<Either<Failure, MatchPrediction?>> getPrediction({
    required String homeName,
    required String awayName,
    required int kickoffEpochSeconds,
    String? country,
    String languageCode = 'en',
  }) =>
      _run(() async {
        final eventId = await _resolver.resolveEvent(
          homeName: homeName,
          awayName: awayName,
          kickoffEpochSeconds: kickoffEpochSeconds,
          country: country,
        );
        if (eventId == null) {
          dev.log('không dò được event cho $homeName vs $awayName', name: _tag);
          return null;
        }

        final lang = sofascoreInsightLanguage(languageCode);
        final results = await Future.wait(<Future<Map<String, dynamic>?>>[
          _tryJson(() => _api.getEventVotes(eventId), 'votes'),
          _tryJson(() => _api.getEventOdds(eventId), 'odds'),
          _tryJson(
            () => _api.getEventAiInsightsPostmatchLang(eventId, lang),
            'ai-insights',
          ),
        ]);

        final prediction = MatchPrediction.from(
          votes: results[0],
          odds: results[1],
          aiInsights: results[2],
        );
        return prediction.isEmpty ? null : prediction;
      });

  /// Dự đoán + BXH cho màn chi tiết trận, chỉ **một lần dò** trận.
  ///
  /// Khác [getLeagueDetail] ở chỗ **không dò theo tên giải**: bản thân
  /// `event/{id}` đã mang sẵn `tournament.uniqueTournament.id` và `season.id`,
  /// nên BXH lấy chính xác tuyệt đối, không sợ nhầm giải trùng tên.
  /// Chi tiết trận theo **id Sofascore**, đổ vào đúng DTO của màn cũ.
  ///
  /// Khác [getMatchBundle] ở chỗ không phải dò tên: từ khi feed Home lấy thẳng
  /// từ Sofascore thì `matchId` mà màn hình nhận **chính là** `eventId`, nên đi
  /// thẳng, không qua [SofascoreIdResolver].
  ///
  /// Bốn khối phụ gọi song song và dùng [_tryJson]: thiếu đội hình hay thống kê
  /// thì tab đó rỗng, ba tab còn lại vẫn chạy.
  Future<Either<Failure, MatchCentreDataDto>> getMatchCentreById(
    int eventId,
  ) =>
      _run(() async {
        final event = await _api.getEventDetails(eventId);
        if (event == null) {
          throw app.ParseException('Không có trận $eventId');
        }

        final parts = await Future.wait(<Future<Map<String, dynamic>?>>[
          _tryJson(() => _api.getEventIncidents(eventId), 'incidents'),
          _tryJson(() => _api.getEventLineups(eventId), 'lineups'),
          _tryJson(() => _api.getEventStatistics(eventId), 'statistics'),
          _tryJson(() => _api.getEventH2H(eventId), 'h2h'),
        ]);

        return SofascoreMatchCentreMapper.build(
          event: event,
          incidents: parts[0],
          lineups: parts[1],
          statistics: parts[2],
          h2h: parts[3],
        );
      });

  /// Bình chọn của cộng đồng Sofascore, đổ vào DTO cũ.
  Future<Either<Failure, MatchVoteDto>> getVoteById(int eventId) =>
      _run(() async {
        final body = await _api.getEventVotes(eventId);
        final raw = body['vote'];
        final vote = raw is Map ? Map<String, dynamic>.from(raw) : null;
        return MatchVoteDto(
          fixtureId: eventId,
          countTeam1Win: _int(vote?['vote1']) ?? 0,
          countDraws: _int(vote?['voteX']) ?? 0,
          countTeam2Win: _int(vote?['vote2']) ?? 0,
        );
      });

  /// Như [getMatchBundle] nhưng đã biết sẵn `eventId`, bỏ bước dò tên.
  ///
  /// Dùng cho màn chi tiết trận bóng đá: `matchId` mà màn nhận được đã là id
  /// Sofascore, dò lại vừa thừa vừa có thể dò trượt.
  Future<Either<Failure, MatchBundle>> getMatchBundleByEvent(
    int eventId, {
    String languageCode = 'en',
    bool withStandings = true,
  }) =>
      _run(() async {
        final lang = sofascoreInsightLanguage(languageCode);
        final results = await Future.wait(<Future<Map<String, dynamic>?>>[
          _tryJson(() => _api.getEventVotes(eventId), 'votes'),
          _tryJson(() => _api.getEventOdds(eventId), 'odds'),
          _tryJson(
            () => _api.getEventAiInsightsPostmatchLang(eventId, lang),
            'ai-insights',
          ),
          if (withStandings)
            _tryJson(() => _api.getEventDetailsRaw(eventId), 'event'),
        ]);

        final prediction = MatchPrediction.from(
          votes: results[0],
          odds: results[1],
          aiInsights: results[2],
        );

        var standings = const <StandingTeamDto>[];
        if (withStandings && results.length > 3) {
          standings = await _standingsForEvent(results[3]);
        }

        return MatchBundle(
          eventId: eventId,
          prediction: prediction.isEmpty ? null : prediction,
          standings: standings,
        );
      });

  Future<Either<Failure, MatchBundle>> getMatchBundle({
    required String homeName,
    required String awayName,
    required int kickoffEpochSeconds,
    String? country,
    String languageCode = 'en',
    bool withStandings = true,
  }) =>
      _run(() async {
        final eventId = await _resolver.resolveEvent(
          homeName: homeName,
          awayName: awayName,
          kickoffEpochSeconds: kickoffEpochSeconds,
          country: country,
        );
        if (eventId == null) return const MatchBundle();

        final lang = sofascoreInsightLanguage(languageCode);
        final results = await Future.wait(<Future<Map<String, dynamic>?>>[
          _tryJson(() => _api.getEventVotes(eventId), 'votes'),
          _tryJson(() => _api.getEventOdds(eventId), 'odds'),
          _tryJson(
            () => _api.getEventAiInsightsPostmatchLang(eventId, lang),
            'ai-insights',
          ),
          if (withStandings)
            _tryJson(() => _api.getEventDetailsRaw(eventId), 'event'),
        ]);

        final prediction = MatchPrediction.from(
          votes: results[0],
          odds: results[1],
          aiInsights: results[2],
        );

        var standings = const <StandingTeamDto>[];
        if (withStandings && results.length > 3) {
          standings = await _standingsForEvent(results[3]);
        }

        return MatchBundle(
          eventId: eventId,
          prediction: prediction.isEmpty ? null : prediction,
          standings: standings,
        );
      });

  Future<List<StandingTeamDto>> _standingsForEvent(
    Map<String, dynamic>? eventJson,
  ) async {
    final event = eventJson?['event'];
    if (event is! Map) return const [];

    final tournament = event['tournament'];
    final unique = tournament is Map ? tournament['uniqueTournament'] : null;
    final tournamentId = unique is Map ? _int(unique['id']) : null;
    final season = event['season'];
    final seasonId = season is Map ? _int(season['id']) : null;
    if (tournamentId == null || seasonId == null) return const [];

    final json = await _tryJson(
      () => _api.getUniqueTournamentStandings(tournamentId, seasonId),
      'standings',
    );
    return _standingsFrom(json);
  }

  // -------------------------------------------------------- Chi tiết giải

  /// BXH + lịch sắp tới + kết quả gần đây của một giải.
  ///
  /// Sofascore đòi `seasonId` cho cả ba, mà `seasonId` phải lấy từ một request
  /// riêng — nên tối thiểu là 2 vòng gọi, không gộp được.
  Future<Either<Failure, LeagueDetailBundle>> getLeagueDetail({
    required String leagueName,
    String? country,
  }) =>
      _run(() async {
        final tournamentId = await _resolver.resolveTournament(
          leagueName,
          country: country,
        );
        if (tournamentId == null) {
          throw app.ServerException('Không tìm thấy giải trên Sofascore');
        }

        final seasons = await _api.getUniqueTournamentSeasons(tournamentId);
        if (seasons.isEmpty) {
          throw app.ServerException('Giải chưa có mùa giải nào');
        }
        // `seasons[0]` là mùa mới nhất — Sofascore trả theo thứ tự giảm dần.
        final seasonId = seasons.first.id;

        final results = await Future.wait(<Future<Object?>>[
          _tryJson(
            () => _api.getUniqueTournamentStandings(tournamentId, seasonId),
            'standings',
          ),
          _safeEvents(() => _api.getSeasonNextEvents(tournamentId, seasonId)),
          _safeEvents(() => _api.getSeasonLastEvents(tournamentId, seasonId)),
        ]);

        final next = results[1] as List<SofascoreEvent>;
        final last = results[2] as List<SofascoreEvent>;

        return LeagueDetailBundle(
          tournamentId: tournamentId,
          seasonId: seasonId,
          standings: _standingsFrom(results[0] as Map<String, dynamic>?),
          // Lịch sắp tới xếp tăng dần, kết quả xếp giảm dần — ghép lại thành
          // một danh sách đọc xuôi theo thời gian như màn cũ.
          fixtures: <UpcomingFixtureDto>[
            for (final e in last.reversed) _upcomingFrom(e),
            for (final e in next) _upcomingFrom(e),
          ],
        );
      });

  Future<List<SofascoreEvent>> _safeEvents(
    Future<List<SofascoreEvent>> Function() body,
  ) async {
    try {
      return await body();
    } catch (e) {
      dev.log('lấy trận lỗi: $e', name: _tag);
      return const <SofascoreEvent>[];
    }
  }

  List<StandingTeamDto> _standingsFrom(Map<String, dynamic>? json) {
    final standings = json?['standings'];
    if (standings is! List || standings.isEmpty) return const [];

    final out = <StandingTeamDto>[];
    // Giải có nhiều bảng (World Cup, Champions League vòng bảng) trả nhiều
    // phần tử; nối hết lại, `position` của mỗi bảng tự đánh số lại từ 1.
    for (final group in standings) {
      if (group is! Map) continue;
      final rows = group['rows'];
      if (rows is! List) continue;
      for (final raw in rows) {
        if (raw is! Map) continue;
        final r = Map<String, dynamic>.from(raw);
        final team = r['team'];
        final teamId = team is Map ? _int(team['id']) : null;
        out.add(StandingTeamDto(
          // Màn cũ dùng `id` chỉ để làm khoá; Sofascore cho luôn id đội thật,
          // tốt hơn hẳn `id` dòng-bảng của backend cũ.
          id: teamId ?? 0,
          position: _int(r['position']) ?? 0,
          points: _int(r['points']) ?? 0,
          result: 'equal',
          name: team is Map ? _str(team['name']) : null,
          imagePath: teamId == null ? null : Team(id: teamId, name: '').logoUrl,
          won: _int(r['wins']),
          draw: _int(r['draws']),
          lost: _int(r['losses']),
          goalsFor: _int(r['scoresFor']),
          goalsAgainst: _int(r['scoresAgainst']),
          overallMatches: _int(r['matches']),
          goalDifference:
              (_int(r['scoresFor']) ?? 0) - (_int(r['scoresAgainst']) ?? 0),
          promotionText: r['promotion'] is Map
              ? _str((r['promotion'] as Map)['text'])
              : null,
        ));
      }
    }
    return out;
  }

  UpcomingFixtureDto _upcomingFrom(SofascoreEvent e) => UpcomingFixtureDto(
        id: e.id,
        homeName: e.homeTeam?.name,
        awayName: e.awayTeam?.name,
        homeImagePath: e.homeTeam?.logoUrl,
        awayImagePath: e.awayTeam?.logoUrl,
        leagueId: e.tournament?.uniqueTournament?.id,
        startingAt: DateTimeUtils.epochToUtcString(e.startTimestamp),
        score: _scoreOf(e),
      );

  /// `"2 - 1"` cho trận đã có tỷ số, null cho trận chưa đá.
  ///
  /// Màn `league_detail_screen` tách chuỗi này bằng `split('-')`, nên phải giữ
  /// đúng định dạng của backend cũ.
  String? _scoreOf(SofascoreEvent e) {
    final h = e.homeScore?.current;
    final a = e.awayScore?.current;
    if (h == null || a == null) return null;
    return '$h - $a';
  }

  // --------------------------------------------------------- Chi tiết đội

  Future<Either<Failure, TeamDetailBundle>> getTeamDetail({
    required String teamName,
    String? country,
  }) =>
      _run(() async {
        final teamId = await _resolver.resolveTeam(teamName, country: country);
        if (teamId == null) {
          throw app.ServerException('Không tìm thấy đội trên Sofascore');
        }

        final results = await Future.wait(<Future<Map<String, dynamic>?>>[
          _tryJson(() => _api.getTeamPlayers(teamId), 'squad'),
          _tryJson(() => _api.getTeamNextEvents(teamId), 'next'),
          _tryJson(() => _api.getTeamLastEvents(teamId), 'last'),
        ]);

        final next = SofascoreResponses.events(results[1] ?? const {});
        final last = SofascoreResponses.events(results[2] ?? const {});

        return TeamDetailBundle(
          teamId: teamId,
          logoUrl: Team(id: teamId, name: teamName).logoUrl,
          squad: _squadFrom(results[0]),
          fixtures: <FavoriteFixtureDto>[
            for (final e in last.reversed) _favoriteFrom(e),
            for (final e in next) _favoriteFrom(e),
          ],
        );
      });

  List<SquadPlayerDto> _squadFrom(Map<String, dynamic>? json) {
    final players = json?['players'];
    if (players is! List) return const [];

    final out = <SquadPlayerDto>[];
    for (final raw in players) {
      if (raw is! Map) continue;
      final p = raw['player'];
      if (p is! Map) continue;
      final player = Map<String, dynamic>.from(p);
      final id = _int(player['id']);

      out.add(SquadPlayerDto(
        name: (_str(player['name']) ?? '').trim().isEmpty
            ? 'Unknown'
            : _str(player['name'])!.trim(),
        position: _positionName(_str(player['position'])),
        imagePath: id == null ? null : ApiConstants.playerImage(id),
        height: _int(player['height']),
        // Sofascore không trả cân nặng; màn hình hiện "-" khi thiếu.
        weight: null,
        dateOfBirth: _dateOnly(_str(player['dateOfBirth'])),
        jerseyNumber: _int(player['jerseyNumber']),
        nationality: player['country'] is Map
            ? _str((player['country'] as Map)['name'])
            : null,
        playerId: id,
      ));
    }
    return out;
  }

  /// Sofascore trả một chữ cái; màn đội hình gom nhóm theo tên tiếng Anh đầy
  /// đủ giống backend cũ (`Goalkeeper` / `Defender` / …).
  String _positionName(String? code) => switch (code?.toUpperCase()) {
        'G' => 'Goalkeeper',
        'D' => 'Defender',
        'M' => 'Midfielder',
        'F' => 'Attacker',
        _ => 'N/A',
      };

  /// `"2004-01-08T00:00:00+00:00"` → `"2004-01-08"`, đúng dạng backend cũ để
  /// hàm tính tuổi sẵn có đọc được.
  String? _dateOnly(String? iso) {
    if (iso == null || iso.length < 10) return null;
    return iso.substring(0, 10);
  }

  FavoriteFixtureDto _favoriteFrom(SofascoreEvent e) => FavoriteFixtureDto(
        id: e.id,
        leagueId: e.tournament?.uniqueTournament?.id ?? 0,
        leagueName: e.tournament?.uniqueTournament?.name ??
            e.tournament?.name ??
            '',
        leagueLogoUrl: e.tournament?.uniqueTournament?.logoUrl,
        startingAt: DateTimeUtils.epochToUtcString(e.startTimestamp),
        homeId: e.homeTeam?.id ?? 0,
        homeLogoUrl: e.homeTeam?.logoUrl,
        homeName: e.homeTeam?.name ?? '',
        awayId: e.awayTeam?.id ?? 0,
        awayLogoUrl: e.awayTeam?.logoUrl,
        awayName: e.awayTeam?.name ?? '',
      );

  // ------------------------------------------------------- Chi tiết cầu thủ

  Future<Either<Failure, PlayerProfile?>> getPlayerProfile(int playerId) =>
      _run(() async {
        final json = await _tryJson(
          () => _api.getPlayerDetails(playerId),
          'player',
        );
        final profile = PlayerProfile.fromJson(json);
        if (profile == null) return null;
        return profile.withStats(await _playerSeasonStats(playerId));
      });

  /// Thống kê mùa hiện tại.
  ///
  /// Hai bước vì Sofascore không có endpoint "mùa này" chung: `statistics/
  /// seasons` liệt kê những giải cầu thủ có số liệu, rồi mới lấy chi tiết theo
  /// (giải, mùa). Chọn giải **nhiều trận nhất** — cầu thủ thường đá vài giải
  /// cùng lúc (quốc nội, cúp, châu lục), lấy giải đầu danh sách dễ ra cúp chỉ
  /// đá 2 trận, nhìn như cầu thủ chẳng ra sân bao giờ.
  Future<PlayerSeasonStats?> _playerSeasonStats(int playerId) async {
    final seasons = await _tryJson(
      () => _api.getPlayerSeasons(playerId),
      'player-seasons',
    );
    final list = seasons?['uniqueTournamentSeasons'];
    if (list is! List || list.isEmpty) return null;

    PlayerSeasonStats? best;
    for (final raw in list.take(4)) {
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      final tournament = _obj2(entry['uniqueTournament']);
      final seasonList = entry['seasons'];
      if (tournament == null || seasonList is! List || seasonList.isEmpty) {
        continue;
      }
      final tournamentId = _int(tournament['id']);
      final season = _obj2(seasonList.first);
      final seasonId = _int(season?['id']);
      if (tournamentId == null || seasonId == null) continue;

      final body = await _tryJson(
        () => _api.getPlayerSeasonStatistics(playerId, tournamentId, seasonId),
        'player-stats',
      );
      final stats = PlayerSeasonStats.fromJson(
        _obj2(body?['statistics']),
        tournamentName: _str(tournament['name']),
      );
      if (stats == null) continue;
      if (best == null || stats.appearances > best.appearances) best = stats;
    }
    return best;
  }
}

// ----------------------------------------------------------------- gói dữ liệu

/// Gói dữ liệu cho màn chi tiết trận.
class MatchBundle {
  const MatchBundle({
    this.eventId,
    this.prediction,
    this.standings = const [],
  });

  final int? eventId;
  final MatchPrediction? prediction;
  final List<StandingTeamDto> standings;
}

class LeagueDetailBundle {
  const LeagueDetailBundle({
    required this.tournamentId,
    required this.seasonId,
    required this.standings,
    required this.fixtures,
  });

  final int tournamentId;
  final int seasonId;
  final List<StandingTeamDto> standings;
  final List<UpcomingFixtureDto> fixtures;
}

class TeamDetailBundle {
  const TeamDetailBundle({
    required this.teamId,
    required this.logoUrl,
    required this.squad,
    required this.fixtures,
  });

  final int teamId;
  final String logoUrl;
  final List<SquadPlayerDto> squad;
  final List<FavoriteFixtureDto> fixtures;
}

/// Hồ sơ cầu thủ — thứ backend cũ **không làm được** vì `list-player` không trả
/// id cầu thủ.
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    this.position,
    this.jerseyNumber,
    this.height,
    this.dateOfBirth,
    this.nationality,
    this.preferredFoot,
    this.marketValue,
    this.marketValueCurrency,
    this.teamName,
    this.teamId,
    this.contractUntil,
    this.stats,
  });

  final int id;
  final String name;
  final String? position;
  final int? jerseyNumber;
  final int? height;
  final String? dateOfBirth;
  final String? nationality;
  final String? preferredFoot;
  final int? marketValue;
  final String? marketValueCurrency;
  final String? teamName;
  final int? teamId;
  final String? contractUntil;

  /// Thống kê mùa hiện tại; `null` khi cầu thủ chưa ra sân giải nào.
  final PlayerSeasonStats? stats;

  PlayerProfile withStats(PlayerSeasonStats? value) => PlayerProfile(
        id: id,
        name: name,
        position: position,
        jerseyNumber: jerseyNumber,
        height: height,
        dateOfBirth: dateOfBirth,
        nationality: nationality,
        preferredFoot: preferredFoot,
        marketValue: marketValue,
        marketValueCurrency: marketValueCurrency,
        teamName: teamName,
        teamId: teamId,
        contractUntil: contractUntil,
        stats: value,
      );

  String get imageUrl => ApiConstants.playerImage(id);
  String? get teamLogoUrl =>
      teamId == null ? null : ApiConstants.teamLogo(teamId!);

  static PlayerProfile? fromJson(Map<String, dynamic>? json) {
    final p = json?['player'];
    if (p is! Map) return null;
    final player = Map<String, dynamic>.from(p);
    final id = _int(player['id']);
    if (id == null) return null;

    final team = player['team'];
    final value = player['proposedMarketValue'];

    return PlayerProfile(
      id: id,
      name: _str(player['name']) ?? '',
      position: switch (_str(player['position'])?.toUpperCase()) {
        'G' => 'Goalkeeper',
        'D' => 'Defender',
        'M' => 'Midfielder',
        'F' => 'Attacker',
        _ => null,
      },
      jerseyNumber: _int(player['jerseyNumber']),
      height: _int(player['height']),
      dateOfBirth: _str(player['dateOfBirth'])?.substring(0, 10),
      nationality: player['country'] is Map
          ? _str((player['country'] as Map)['name'])
          : null,
      preferredFoot: _str(player['preferredFoot']),
      marketValue: _int(value),
      marketValueCurrency:
          _str(player['proposedMarketValueRaw'] is Map
              ? (player['proposedMarketValueRaw'] as Map)['currency']
              : null) ??
              'EUR',
      teamName: team is Map ? _str(team['name']) : null,
      teamId: team is Map ? _int(team['id']) : null,
      contractUntil: _epochToDate(_int(player['contractUntilTimestamp'])),
    );
  }

  static String? _epochToDate(int? epochSeconds) {
    if (epochSeconds == null || epochSeconds <= 0) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(
      epochSeconds * 1000,
      isUtc: true,
    );
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

Map<String, dynamic>? _obj2(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

int? _int(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));

String? _str(Object? v) => v?.toString();

/// Thống kê một mùa của cầu thủ, đã chọn giải nhiều trận nhất.
class PlayerSeasonStats {
  const PlayerSeasonStats({
    required this.appearances,
    required this.goals,
    required this.assists,
    this.rating,
    this.minutesPlayed,
    this.yellowCards,
    this.redCards,
    this.tournamentName,
  });

  final int appearances;
  final int goals;
  final int assists;
  final double? rating;
  final int? minutesPlayed;
  final int? yellowCards;
  final int? redCards;
  final String? tournamentName;

  static PlayerSeasonStats? fromJson(
    Map<String, dynamic>? j, {
    String? tournamentName,
  }) {
    if (j == null) return null;
    final appearances = _int(j['appearances']) ?? 0;
    if (appearances == 0) return null;
    final rating = j['rating'];
    return PlayerSeasonStats(
      appearances: appearances,
      goals: _int(j['goals']) ?? 0,
      assists: _int(j['assists']) ?? 0,
      rating: rating is num ? rating.toDouble() : null,
      minutesPlayed: _int(j['minutesPlayed']),
      yellowCards: _int(j['yellowCards']),
      redCards: _int(j['redCards']),
      tournamentName: tournamentName,
    );
  }

  /// Sofascore chấm thang 10; dưới 6.5 là kém, trên 7.0 là tốt.
  String get ratingText => rating == null ? '-' : rating!.toStringAsFixed(2);
}
