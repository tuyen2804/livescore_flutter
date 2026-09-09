// Port của `data/api/*.kt` — DTO cho API bóng đá riêng của app.

int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
String? _str(dynamic v) => v?.toString();
bool _boolOr(dynamic v, bool def) =>
    v is bool ? v : (v == null ? def : v == 1 || v == 'true');
bool? _bool(dynamic v) => v is bool ? v : (v == null ? null : v == 1 || v == 'true');

Map<String, dynamic>? _obj(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList(growable: false);
}

/// `MatchDto` — một trận trong `league-live`.
class MatchDto {
  const MatchDto({
    required this.id,
    required this.date,
    required this.countryId,
    required this.leagueId,
    required this.seasonId,
    this.nameVenue,
    required this.name,
    required this.kickoffUtc,
    required this.kickoffEpoch,
    required this.lengthMinutes,
    required this.state,
    this.groupName,
    this.roundName,
    this.score,
    required this.homeId,
    required this.awayId,
    required this.homeName,
    required this.awayName,
    this.homeShortName,
    this.awayShortName,
    this.homeTeamLogoUrl,
    this.awayTeamLogoUrl,
    this.leagueLogoUrl,
    required this.leagueName,
    required this.playingTime,
  });

  final int id;
  final String date;
  final int countryId;
  final int leagueId;
  final int seasonId;
  final String? nameVenue;
  final String name;
  final String kickoffUtc;
  final int kickoffEpoch;
  final int lengthMinutes;
  final int state;
  final String? groupName;
  final String? roundName;
  final String? score;
  final int homeId;
  final int awayId;
  final String homeName;
  final String awayName;
  final String? homeShortName;
  final String? awayShortName;
  final String? homeTeamLogoUrl;
  final String? awayTeamLogoUrl;
  final String? leagueLogoUrl;
  final String leagueName;
  final int playingTime;

  factory MatchDto.fromJson(Map<String, dynamic> j) => MatchDto(
        id: _int(j['id']) ?? 0,
        date: _str(j['date']) ?? '',
        countryId: _int(j['countryId']) ?? 0,
        leagueId: _int(j['leagueId']) ?? 0,
        seasonId: _int(j['seasonId']) ?? 0,
        nameVenue: _str(j['nameVenue']),
        name: _str(j['name']) ?? '',
        kickoffUtc: _str(j['kickoffUtc']) ?? '',
        kickoffEpoch: _int(j['kickoffEpoch']) ?? 0,
        lengthMinutes: _int(j['lengthMinutes']) ?? 0,
        state: _int(j['state']) ?? 0,
        groupName: _str(j['groupName']),
        roundName: _str(j['roundName']),
        score: _str(j['score']),
        homeId: _int(j['homeId']) ?? 0,
        awayId: _int(j['awayId']) ?? 0,
        homeName: _str(j['homeName']) ?? '',
        awayName: _str(j['awayName']) ?? '',
        homeShortName: _str(j['homeShortName']),
        awayShortName: _str(j['awayShortName']),
        homeTeamLogoUrl: _str(j['homeTeamLogoUrl']),
        awayTeamLogoUrl: _str(j['awayTeamLogoUrl']),
        leagueLogoUrl: _str(j['leagueLogoUrl']),
        leagueName: _str(j['leagueName']) ?? '',
        playingTime: _int(j['playingTime']) ?? 0,
      );

  static List<MatchDto> listFrom(Map<String, dynamic> j) =>
      _list(j['data'], MatchDto.fromJson);
}

// ---- Match centre ----

class MatchDetailDto {
  const MatchDetailDto({
    required this.id,
    required this.leagueId,
    required this.seasonId,
    this.nameVenue,
    this.name,
    this.kickoffUtc,
    this.kickoffEpoch,
    this.lengthMinutes,
    this.state,
    this.groupName,
    this.roundName,
    this.score,
    required this.homeId,
    required this.awayId,
    this.homeName,
    this.awayName,
    this.homeShortName,
    this.awayShortName,
    this.homeTeamLogoUrl,
    this.awayTeamLogoUrl,
    this.leagueLogoUrl,
    this.leagueName,
    this.playingTime,
  });

  final int id;
  final int leagueId;
  final int seasonId;
  final String? nameVenue;
  final String? name;
  final String? kickoffUtc;
  final int? kickoffEpoch;
  final int? lengthMinutes;
  final int? state;
  final String? groupName;
  final String? roundName;
  final String? score;
  final int homeId;
  final int awayId;
  final String? homeName;
  final String? awayName;
  final String? homeShortName;
  final String? awayShortName;
  final String? homeTeamLogoUrl;
  final String? awayTeamLogoUrl;
  final String? leagueLogoUrl;
  final String? leagueName;
  final int? playingTime;

  factory MatchDetailDto.fromJson(Map<String, dynamic> j) => MatchDetailDto(
        id: _int(j['id']) ?? 0,
        leagueId: _int(j['leagueId']) ?? 0,
        seasonId: _int(j['seasonId']) ?? 0,
        nameVenue: _str(j['nameVenue']),
        name: _str(j['name']),
        kickoffUtc: _str(j['kickoffUtc']),
        kickoffEpoch: _int(j['kickoffEpoch']),
        lengthMinutes: _int(j['lengthMinutes']),
        state: _int(j['state']),
        groupName: _str(j['groupName']),
        roundName: _str(j['roundName']),
        score: _str(j['score']),
        homeId: _int(j['homeId']) ?? 0,
        awayId: _int(j['awayId']) ?? 0,
        homeName: _str(j['homeName']),
        awayName: _str(j['awayName']),
        homeShortName: _str(j['homeShortName']),
        awayShortName: _str(j['awayShortName']),
        homeTeamLogoUrl: _str(j['homeTeamLogoUrl']),
        awayTeamLogoUrl: _str(j['awayTeamLogoUrl']),
        leagueLogoUrl: _str(j['leagueLogoUrl']),
        leagueName: _str(j['leagueName']),
        playingTime: _int(j['playingTime']),
      );
}

class MatchEventDto {
  const MatchEventDto({
    required this.id,
    required this.fixtureId,
    required this.teamId,
    this.typeName,
    required this.minute,
    this.extraMinute,
    required this.playerId,
    this.playerName,
    this.relatedPlayerName,
  });

  final int id;
  final int fixtureId;
  final int teamId;
  final String? typeName;
  final int minute;
  final int? extraMinute;
  final int playerId;
  final String? playerName;
  final String? relatedPlayerName;

  factory MatchEventDto.fromJson(Map<String, dynamic> j) => MatchEventDto(
        id: _int(j['id']) ?? 0,
        fixtureId: _int(j['fixtureId']) ?? 0,
        teamId: _int(j['teamId']) ?? 0,
        typeName: _str(j['typeName']),
        minute: _int(j['minute']) ?? 0,
        extraMinute: _int(j['extraMinute']),
        playerId: _int(j['playerId']) ?? 0,
        playerName: _str(j['playerName']),
        relatedPlayerName: _str(j['relatedPlayerName']),
      );
}

class MatchLineupDto {
  const MatchLineupDto({
    required this.id,
    required this.fixtureId,
    required this.teamId,
    required this.playerId,
    this.playerName,
    this.playerImageUrl,
    this.jerseyNumber,
    this.formation,
    this.positionField,
    this.isCaptain,
  });

  final int id;
  final int fixtureId;
  final int teamId;
  final int playerId;
  final String? playerName;
  final String? playerImageUrl;
  final int? jerseyNumber;
  final String? formation;
  final String? positionField;
  final int? isCaptain;

  factory MatchLineupDto.fromJson(Map<String, dynamic> j) => MatchLineupDto(
        id: _int(j['id']) ?? 0,
        fixtureId: _int(j['fixtureId']) ?? 0,
        teamId: _int(j['teamId']) ?? 0,
        playerId: _int(j['playerId']) ?? 0,
        playerName: _str(j['playerName']),
        playerImageUrl: _str(j['playerImageUrl']),
        jerseyNumber: _int(j['jerseyNumber']),
        formation: _str(j['formation']),
        positionField: _str(j['positionField']),
        isCaptain: _int(j['isCaptain']),
      );

  bool get captain => isCaptain == 1;
}

class MatchStatisticsDto {
  const MatchStatisticsDto({
    this.id,
    this.fixtureId,
    this.teamId,
    this.shotOnTarget,
    this.shotOffTarget,
    this.blockerShots,
    this.possession,
    this.cornerKicks,
    this.offsides,
    this.fouls,
    this.throwIn,
    this.yellowCards,
    this.redCards,
  });

  final int? id;
  final int? fixtureId;
  final int? teamId;
  final int? shotOnTarget;
  final int? shotOffTarget;
  final int? blockerShots;
  final int? possession;
  final int? cornerKicks;
  final int? offsides;
  final int? fouls;
  final int? throwIn;
  final int? yellowCards;
  final int? redCards;

  factory MatchStatisticsDto.fromJson(Map<String, dynamic> j) => MatchStatisticsDto(
        id: _int(j['id']),
        fixtureId: _int(j['fixtureId']),
        teamId: _int(j['teamId']),
        shotOnTarget: _int(j['shotOnTarget']),
        shotOffTarget: _int(j['shotOffTarget']),
        blockerShots: _int(j['blockerShots']),
        possession: _int(j['possession']),
        cornerKicks: _int(j['cornerKicks']),
        offsides: _int(j['offsides']),
        fouls: _int(j['fouls']),
        throwIn: _int(j['throwIn']),
        yellowCards: _int(j['yellowCards']),
        redCards: _int(j['redCards']),
      );
}

class MatchH2HDto {
  const MatchH2HDto({
    this.fixtureId,
    this.team1Id,
    this.team2Id,
    this.totalWin,
    this.totalDraws,
    this.totalLoss,
    this.winLastFive,
    this.drawsLastFive,
  });

  final int? fixtureId;
  final int? team1Id;
  final int? team2Id;
  final int? totalWin;
  final int? totalDraws;
  final int? totalLoss;
  final int? winLastFive;
  final int? drawsLastFive;

  factory MatchH2HDto.fromJson(Map<String, dynamic> j) => MatchH2HDto(
        fixtureId: _int(j['fixtureId']),
        team1Id: _int(j['team1Id']),
        team2Id: _int(j['team2Id']),
        totalWin: _int(j['totalWin']),
        totalDraws: _int(j['totalDraws']),
        totalLoss: _int(j['totalLoss']),
        winLastFive: _int(j['winLastFive']),
        drawsLastFive: _int(j['drawsLastFive']),
      );
}

class MatchCentreDataDto {
  const MatchCentreDataDto({
    this.match,
    this.events = const [],
    this.lineups = const [],
    this.statistics = const [],
    this.h2h = const [],
  });

  final MatchDetailDto? match;
  final List<MatchEventDto> events;
  final List<MatchLineupDto> lineups;
  final List<MatchStatisticsDto> statistics;
  final List<MatchH2HDto> h2h;

  factory MatchCentreDataDto.fromJson(Map<String, dynamic> j) => MatchCentreDataDto(
        match: _obj(j['match']) == null
            ? null
            : MatchDetailDto.fromJson(_obj(j['match'])!),
        events: _list(j['events'], MatchEventDto.fromJson),
        lineups: _list(j['lineups'], MatchLineupDto.fromJson),
        statistics: _list(j['statistics'], MatchStatisticsDto.fromJson),
        h2h: _list(j['h2h'], MatchH2HDto.fromJson),
      );

  /// Bọc ngoài `{success, data}`.
  static MatchCentreDataDto? unwrap(Map<String, dynamic> j) {
    final data = _obj(j['data']);
    return data == null ? null : MatchCentreDataDto.fromJson(data);
  }
}

// ---- Bảng xếp hạng ----

class StandingTeamDto {
  const StandingTeamDto({
    required this.id,
    required this.position,
    required this.points,
    this.result,
    this.name,
    this.imagePath,
    this.won,
    this.draw,
    this.lost,
    this.goalsFor,
    this.goalsAgainst,
    this.overallMatches,
    this.goalDifference,
  });

  final int id;
  final int position;
  final int points;
  final String? result;
  final String? name;
  final String? imagePath;
  final int? won;
  final int? draw;
  final int? lost;
  final int? goalsFor;
  final int? goalsAgainst;
  final int? overallMatches;
  final int? goalDifference;

  factory StandingTeamDto.fromJson(Map<String, dynamic> j) => StandingTeamDto(
        id: _int(j['id']) ?? 0,
        position: _int(j['position']) ?? 0,
        points: _int(j['points']) ?? 0,
        result: _str(j['result']),
        name: _str(j['name']),
        imagePath: _str(j['image_path']),
        won: _int(j['won']),
        draw: _int(j['draw']),
        lost: _int(j['lost']),
        goalsFor: _int(j['goalsFor']),
        goalsAgainst: _int(j['goalsAgainst']),
        overallMatches: _int(j['overall_matches']),
        goalDifference: _int(j['goal_difference']),
      );

  static List<StandingTeamDto> listFrom(Map<String, dynamic> j) =>
      _list(j['data'], StandingTeamDto.fromJson);
}

class UpcomingFixtureDto {
  const UpcomingFixtureDto({
    this.id,
    this.homeName,
    this.awayName,
    this.homeImagePath,
    this.awayImagePath,
    this.leagueId,
    this.startingAt,
    this.score,
  });

  final int? id;
  final String? homeName;
  final String? awayName;
  final String? homeImagePath;
  final String? awayImagePath;
  final int? leagueId;
  final String? startingAt;
  final String? score;

  factory UpcomingFixtureDto.fromJson(Map<String, dynamic> j) => UpcomingFixtureDto(
        id: _int(j['id']),
        homeName: _str(j['home_name']),
        awayName: _str(j['away_name']),
        homeImagePath: _str(j['home_image_path']),
        awayImagePath: _str(j['away_image_path']),
        leagueId: _int(j['league_id']),
        startingAt: _str(j['starting_at']),
        score: _str(j['score']),
      );

  static List<UpcomingFixtureDto> listFrom(Map<String, dynamic> j) =>
      _list(j['data'], UpcomingFixtureDto.fromJson);
}

class FavoriteFixtureDto {
  const FavoriteFixtureDto({
    required this.id,
    required this.leagueId,
    required this.leagueName,
    this.leagueLogoUrl,
    required this.startingAt,
    required this.homeId,
    this.homeLogoUrl,
    required this.homeName,
    required this.awayId,
    this.awayLogoUrl,
    required this.awayName,
  });

  final int id;
  final int leagueId;
  final String leagueName;
  final String? leagueLogoUrl;
  final String startingAt;
  final int homeId;
  final String? homeLogoUrl;
  final String homeName;
  final int awayId;
  final String? awayLogoUrl;
  final String awayName;

  factory FavoriteFixtureDto.fromJson(Map<String, dynamic> j) => FavoriteFixtureDto(
        id: _int(j['id']) ?? 0,
        leagueId: _int(j['league_id']) ?? 0,
        leagueName: _str(j['league_name']) ?? '',
        leagueLogoUrl: _str(j['league_image_path']),
        startingAt: _str(j['starting_at']) ?? '',
        homeId: _int(j['home_team_id']) ?? 0,
        homeLogoUrl: _str(j['home_image_path']),
        homeName: _str(j['home_name']) ?? '',
        awayId: _int(j['away_team_id']) ?? 0,
        awayLogoUrl: _str(j['away_image_path']),
        awayName: _str(j['away_name']) ?? '',
      );

  static List<FavoriteFixtureDto> listFrom(Map<String, dynamic> j) =>
      _list(j['data'], FavoriteFixtureDto.fromJson);
}

// ---- Dự đoán trận (match-forecast-new) ----

class MatchResultForecast {
  const MatchResultForecast({this.home, this.draw, this.away, this.accuracy});
  final int? home;
  final int? draw;
  final int? away;
  final bool? accuracy;

  factory MatchResultForecast.fromJson(Map<String, dynamic> j) => MatchResultForecast(
        home: _int(j['home']),
        draw: _int(j['draw']),
        away: _int(j['away']),
        accuracy: _bool(j['accuracy']),
      );
}

class FirstGoalForecast {
  const FirstGoalForecast({this.home, this.noGoal, this.away, this.accuracy});
  final int? home;
  final int? noGoal;
  final int? away;
  final bool? accuracy;

  factory FirstGoalForecast.fromJson(Map<String, dynamic> j) => FirstGoalForecast(
        home: _int(j['home']),
        noGoal: _int(j['noGoal']),
        away: _int(j['away']),
        accuracy: _bool(j['accuracy']),
      );
}

class MatchScoreForecast {
  const MatchScoreForecast({this.home, this.away, this.accuracy});
  final int? home;
  final int? away;
  final bool? accuracy;

  factory MatchScoreForecast.fromJson(Map<String, dynamic> j) => MatchScoreForecast(
        home: _int(j['home']),
        away: _int(j['away']),
        accuracy: _bool(j['accuracy']),
      );
}

class TotalGoalsForecast {
  const TotalGoalsForecast({this.totalGoals, this.accuracy});
  final int? totalGoals;
  final bool? accuracy;

  factory TotalGoalsForecast.fromJson(Map<String, dynamic> j) => TotalGoalsForecast(
        totalGoals: _int(j['totalGoals']),
        accuracy: _bool(j['accuracy']),
      );
}

class BothTeamsToScoreForecast {
  const BothTeamsToScoreForecast({this.ft, this.h1, this.h2, this.accuracy});
  final bool? ft;
  final bool? h1;
  final bool? h2;
  final bool? accuracy;

  factory BothTeamsToScoreForecast.fromJson(Map<String, dynamic> j) =>
      BothTeamsToScoreForecast(
        ft: _bool(j['Ft']),
        h1: _bool(j['H1']),
        h2: _bool(j['H2']),
        accuracy: _bool(j['accuracy']),
      );
}

class CornerForecast {
  const CornerForecast({this.home, this.away, this.accuracy});
  final int? home;
  final int? away;
  final bool? accuracy;

  factory CornerForecast.fromJson(Map<String, dynamic> j) => CornerForecast(
        home: _int(j['home']),
        away: _int(j['away']),
        accuracy: _bool(j['accuracy']),
      );
}

class ConfidenceForecast {
  const ConfidenceForecast({this.percent, this.accuracy});
  final int? percent;
  final bool? accuracy;

  factory ConfidenceForecast.fromJson(Map<String, dynamic> j) => ConfidenceForecast(
        percent: _int(j['percent']),
        accuracy: _bool(j['accuracy']),
      );
}

class AnalysisForecast {
  const AnalysisForecast({this.text, this.accuracy});
  final String? text;
  final bool? accuracy;

  factory AnalysisForecast.fromJson(Map<String, dynamic> j) => AnalysisForecast(
        text: _str(j['text']),
        accuracy: _bool(j['accuracy']),
      );
}

class ForecastData {
  const ForecastData({
    this.matchResult,
    this.firstGoal,
    this.matchScore,
    this.totalGoals,
    this.bothTeamsToScore,
    this.corner,
    this.confidence,
    this.analysis,
  });

  final MatchResultForecast? matchResult;
  final FirstGoalForecast? firstGoal;
  final MatchScoreForecast? matchScore;
  final TotalGoalsForecast? totalGoals;
  final BothTeamsToScoreForecast? bothTeamsToScore;
  final CornerForecast? corner;
  final ConfidenceForecast? confidence;
  final AnalysisForecast? analysis;

  factory ForecastData.fromJson(Map<String, dynamic> j) => ForecastData(
        matchResult: _obj(j['match_result']) == null
            ? null
            : MatchResultForecast.fromJson(_obj(j['match_result'])!),
        firstGoal: _obj(j['first_goal']) == null
            ? null
            : FirstGoalForecast.fromJson(_obj(j['first_goal'])!),
        matchScore: _obj(j['match_score']) == null
            ? null
            : MatchScoreForecast.fromJson(_obj(j['match_score'])!),
        totalGoals: _obj(j['total_goals']) == null
            ? null
            : TotalGoalsForecast.fromJson(_obj(j['total_goals'])!),
        bothTeamsToScore: _obj(j['both_teams_to_score']) == null
            ? null
            : BothTeamsToScoreForecast.fromJson(_obj(j['both_teams_to_score'])!),
        corner: _obj(j['corner']) == null
            ? null
            : CornerForecast.fromJson(_obj(j['corner'])!),
        confidence: _obj(j['confidence']) == null
            ? null
            : ConfidenceForecast.fromJson(_obj(j['confidence'])!),
        analysis: _obj(j['analysis']) == null
            ? null
            : AnalysisForecast.fromJson(_obj(j['analysis'])!),
      );

  static ForecastData? unwrap(Map<String, dynamic> j) {
    if (!_boolOr(j['success'], true)) return null;
    final data = _obj(j['data']);
    if (data == null) return null;
    // API vẫn trả success=true nhưng bọc lỗi trong data:
    // `{"error":true,"message":"The system is busy, please try again later."}`
    if (_boolOr(data['error'], false)) return null;
    final forecast = ForecastData.fromJson(data);
    return forecast.isEmpty ? null : forecast;
  }

  /// Không có khối dự đoán nào — coi như chưa có dự đoán cho trận này.
  bool get isEmpty =>
      matchResult == null &&
      firstGoal == null &&
      matchScore == null &&
      totalGoals == null &&
      bothTeamsToScore == null &&
      corner == null &&
      confidence == null &&
      analysis == null;
}

// ---- Vote (match-centre-vote) ----

/// Response thật: `{success, data:{countTeam1Win, countTeam2Win, countDraws, fixtureId}}`.
class MatchVoteDto {
  const MatchVoteDto({
    this.countTeam1Win = 0,
    this.countTeam2Win = 0,
    this.countDraws = 0,
    this.fixtureId = 0,
  });

  final int countTeam1Win;
  final int countTeam2Win;
  final int countDraws;
  final int fixtureId;

  factory MatchVoteDto.fromJson(Map<String, dynamic> j) {
    final data = _obj(j['data']) ?? j;
    return MatchVoteDto(
      countTeam1Win: _int(data['countTeam1Win']) ?? 0,
      countTeam2Win: _int(data['countTeam2Win']) ?? 0,
      countDraws: _int(data['countDraws']) ?? 0,
      fixtureId: _int(data['fixtureId']) ?? 0,
    );
  }

  int get total => countTeam1Win + countDraws + countTeam2Win;
  double get homePercent => total == 0 ? 0 : countTeam1Win / total;
  double get drawPercent => total == 0 ? 0 : countDraws / total;
  double get awayPercent => total == 0 ? 0 : countTeam2Win / total;
}

// ---- Highlight ----

class HighlightDto {
  const HighlightDto({
    required this.id,
    required this.title,
    required this.url,
    required this.imgUrl,
    required this.source,
    required this.channel,
    required this.matchId,
    required this.matchDate,
    required this.matchRound,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamLogo,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.awayTeamLogo,
    required this.leagueId,
    required this.leagueName,
    required this.leagueLogo,
    required this.leagueSeason,
    required this.matchCountryCode,
    required this.matchCountryName,
    required this.matchCountryLogo,
  });

  final int id;
  final String title;
  final String url;
  final String imgUrl;
  final String source;
  final String channel;
  final int matchId;
  final int matchDate;
  final String matchRound;
  final int homeTeamId;
  final String homeTeamName;
  final String homeTeamLogo;
  final int awayTeamId;
  final String awayTeamName;
  final String awayTeamLogo;
  final int leagueId;
  final String leagueName;
  final String leagueLogo;
  final int leagueSeason;
  final String matchCountryCode;
  final String matchCountryName;
  final String matchCountryLogo;

  factory HighlightDto.fromJson(Map<String, dynamic> j) => HighlightDto(
        id: _int(j['id']) ?? 0,
        title: _str(j['title']) ?? '',
        url: _str(j['url']) ?? '',
        imgUrl: _str(j['imgUrl']) ?? '',
        source: _str(j['source']) ?? '',
        channel: _str(j['channel']) ?? '',
        matchId: _int(j['matchId']) ?? 0,
        matchDate: _int(j['matchDate']) ?? 0,
        matchRound: _str(j['matchRound']) ?? '',
        homeTeamId: _int(j['homeTeamId']) ?? 0,
        homeTeamName: _str(j['homeTeamName']) ?? '',
        homeTeamLogo: _str(j['homeTeamLogo']) ?? '',
        awayTeamId: _int(j['awayTeamId']) ?? 0,
        awayTeamName: _str(j['awayTeamName']) ?? '',
        awayTeamLogo: _str(j['awayTeamLogo']) ?? '',
        leagueId: _int(j['leagueId']) ?? 0,
        leagueName: _str(j['leagueName']) ?? '',
        leagueLogo: _str(j['leagueLogo']) ?? '',
        leagueSeason: _int(j['leagueSeason']) ?? 0,
        matchCountryCode: _str(j['matchCountryCode']) ?? '',
        matchCountryName: _str(j['matchCountryName']) ?? '',
        matchCountryLogo: _str(j['matchCountryLogo']) ?? '',
      );

  static List<HighlightDto> listFrom(Map<String, dynamic> j) =>
      _list(j['data'], HighlightDto.fromJson);
}

/// Response `/live-score/list-player?team_id=` — đội hình của một CLB.
class SquadPlayerDto {
  const SquadPlayerDto({
    required this.name,
    required this.position,
    this.imagePath,
    this.height,
    this.weight,
    this.dateOfBirth,
    this.jerseyNumber,
    this.nationality,
  });

  final String name;
  final String position;
  final String? imagePath;
  final int? height;
  final int? weight;
  final String? dateOfBirth;
  final int? jerseyNumber;
  final String? nationality;

  factory SquadPlayerDto.fromJson(Map<String, dynamic> j) => SquadPlayerDto(
        name: _str(j['name'])?.trim() ?? 'Unknown',
        position: _str(j['position_name']) ?? 'N/A',
        imagePath: _str(j['image_path']),
        height: _int(j['height']),
        weight: _int(j['weight']),
        dateOfBirth: _str(j['date_of_birth']),
        jerseyNumber: _int(j['jersey_number']),
        nationality: _str(j['nationality']),
      );

  static List<SquadPlayerDto> listFrom(Map<String, dynamic> j) {
    if (!_boolOr(j['success'], true)) return const [];
    final data = j['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => SquadPlayerDto.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  /// Bản gốc hiển thị "191cm" / "73kg" / "#51", thiếu thì "-".
  String get heightText => height == null || height == 0 ? '-' : '${height}cm';
  String get weightText => weight == null || weight == 0 ? '-' : '${weight}kg';
  String get numberText => jerseyNumber == null ? '-' : '#$jerseyNumber';

  /// Port `calculateAge(dateOfBirth)`.
  String get ageText {
    final dob = dateOfBirth;
    if (dob == null || dob.isEmpty) return '-';
    final parsed = DateTime.tryParse(dob);
    if (parsed == null) return '-';
    final now = DateTime.now();
    var age = now.year - parsed.year;
    if (now.month < parsed.month ||
        (now.month == parsed.month && now.day < parsed.day)) {
      age--;
    }
    return age <= 0 ? '-' : '$age';
  }
}
