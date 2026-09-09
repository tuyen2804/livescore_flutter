import '../../../core/constants/api_constants.dart';

/// Port 1:1 của `data/sofascore/SofascoreModels.kt`.
/// Mọi trường đều nullable-safe vì Sofascore hay bỏ field tuỳ môn.

int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
double? _dbl(dynamic v) =>
    v is double ? v : (v is num ? v.toDouble() : double.tryParse('$v'));
String? _str(dynamic v) => v?.toString();
bool? _bool(dynamic v) => v is bool ? v : (v == null ? null : v == 1 || v == 'true');

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList(growable: false);
}

Map<String, dynamic>? _obj(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

class Sport {
  const Sport({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;

  factory Sport.fromJson(Map<String, dynamic> j) => Sport(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']) ?? '',
        slug: _str(j['slug']) ?? '',
      );
}

class StageCountry {
  const StageCountry({this.alpha2, this.name});

  final String? alpha2;
  final String? name;

  factory StageCountry.fromJson(Map<String, dynamic> j) => StageCountry(
        alpha2: _str(j['alpha2']),
        name: _str(j['name']),
      );

  String? get flagUrl {
    final code = alpha2;
    return code == null ? null : ApiConstants.countryFlag(code.toLowerCase());
  }
}

class Category {
  const Category({
    required this.id,
    required this.name,
    this.slug,
    this.flag,
    this.alpha2,
    this.sport,
    this.priority = 0,
    this.sportVariant,
  });

  final int id;
  final String name;
  final String? slug;
  final String? flag;
  final String? alpha2;
  final Sport? sport;
  final int priority;
  final int? sportVariant;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']) ?? '',
        slug: _str(j['slug']),
        flag: _str(j['flag']),
        alpha2: _str(j['alpha2']),
        sport: _obj(j['sport']) == null ? null : Sport.fromJson(_obj(j['sport'])!),
        priority: _int(j['priority']) ?? 0,
        sportVariant: _int(j['sportVariant']),
      );

  String get imageUrl => ApiConstants.categoryLogo(id);
  String get sportSlug => sport?.slug ?? '';
}

class Team {
  const Team({
    required this.id,
    required this.name,
    this.slug,
    this.shortName,
    this.country,
    this.national = false,
    this.type = 0,
  });

  final int id;
  final String name;
  final String? slug;
  final String? shortName;
  final StageCountry? country;
  final bool? national;
  final int? type;

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']) ?? '',
        slug: _str(j['slug']),
        shortName: _str(j['shortName']),
        country: _obj(j['country']) == null
            ? null
            : StageCountry.fromJson(_obj(j['country'])!),
        national: _bool(j['national']) ?? false,
        type: _int(j['type']) ?? 0,
      );

  String get logoUrl => ApiConstants.teamLogo(id);
  String get displayName => shortName?.isNotEmpty == true ? shortName! : name;
}

class UniqueTournament {
  const UniqueTournament({
    required this.id,
    required this.name,
    this.slug,
    this.priority = 0,
    this.userCount = 0,
    this.category,
    this.primaryColorHex,
  });

  final int id;
  final String name;
  final String? slug;
  final int priority;
  final int userCount;
  final Category? category;
  final String? primaryColorHex;

  factory UniqueTournament.fromJson(Map<String, dynamic> j) => UniqueTournament(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']) ?? '',
        slug: _str(j['slug']),
        priority: _int(j['priority']) ?? 0,
        userCount: _int(j['userCount']) ?? 0,
        category:
            _obj(j['category']) == null ? null : Category.fromJson(_obj(j['category'])!),
        primaryColorHex: _str(j['primaryColorHex']),
      );

  String get logoUrl => ApiConstants.uniqueTournamentLogo(id);
}

class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    this.slug,
    this.priority = 0,
    this.order = 0,
    this.category,
    this.uniqueTournament,
    this.location,
    this.startTimestamp = 0,
    this.endTimestamp = 0,
  });

  final int id;
  final String name;
  final String? slug;
  final int priority;
  final int order;
  final Category? category;
  final UniqueTournament? uniqueTournament;
  final String? location;
  final int startTimestamp;
  final int endTimestamp;

  factory Tournament.fromJson(Map<String, dynamic> j) => Tournament(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']) ?? '',
        slug: _str(j['slug']),
        priority: _int(j['priority']) ?? 0,
        order: _int(j['order']) ?? 0,
        category:
            _obj(j['category']) == null ? null : Category.fromJson(_obj(j['category'])!),
        uniqueTournament: _obj(j['uniqueTournament']) == null
            ? null
            : UniqueTournament.fromJson(_obj(j['uniqueTournament'])!),
        location: _str(j['location']),
        startTimestamp: _int(j['startTimestamp']) ?? 0,
        endTimestamp: _int(j['endTimestamp']) ?? 0,
      );

  String get sportSlug => category?.sportSlug ?? '';

  /// Logo giải: ưu tiên uniqueTournament, fallback về category.
  String? get logoUrl => uniqueTournament?.logoUrl ?? category?.imageUrl;
}

class EventStatus {
  const EventStatus({required this.code, this.description, this.type});

  final int code;
  final String? description;
  final String? type;

  factory EventStatus.fromJson(Map<String, dynamic> j) => EventStatus(
        code: _int(j['code']) ?? 0,
        description: _str(j['description']),
        type: _str(j['type']),
      );
}

class CricketInningScore {
  const CricketInningScore({
    this.id,
    this.run,
    this.score,
    this.wickets,
    this.overs,
    this.runRate,
    this.targetRunRate,
    this.inningDeclare,
    this.hits,
    this.errors,
  });

  final int? id;
  final int? run;
  final int? score;
  final int? wickets;
  final double? overs;
  final double? runRate;
  final double? targetRunRate;
  final bool? inningDeclare;
  final int? hits;
  final int? errors;

  factory CricketInningScore.fromJson(Map<String, dynamic> j) =>
      CricketInningScore(
        id: _int(j['id']),
        run: _int(j['run']),
        score: _int(j['score']),
        wickets: _int(j['wickets']),
        overs: _dbl(j['overs']),
        runRate: _dbl(j['runRate']),
        targetRunRate: _dbl(j['targetRunRate']),
        inningDeclare: _bool(j['inningDeclare']),
        hits: _int(j['hits']),
        errors: _int(j['errors']),
      );
}

class Score {
  const Score({
    this.current,
    this.display,
    this.period1,
    this.period2,
    this.period3,
    this.period4,
    this.period5,
    this.period6,
    this.period7,
    this.period8,
    this.period9,
    this.normaltime,
    this.innings,
    this.currentCricketDisplay,
  });

  final int? current;
  final int? display;
  final int? period1;
  final int? period2;
  final int? period3;
  final int? period4;
  final int? period5;
  final int? period6;
  final int? period7;
  final int? period8;
  final int? period9;
  final int? normaltime;
  final Map<String, CricketInningScore>? innings;
  final String? currentCricketDisplay;

  factory Score.fromJson(Map<String, dynamic> j) {
    Map<String, CricketInningScore>? innings;
    final rawInnings = j['innings'];
    if (rawInnings is Map) {
      innings = {
        for (final e in rawInnings.entries)
          if (e.value is Map)
            '${e.key}': CricketInningScore.fromJson(
                Map<String, dynamic>.from(e.value as Map)),
      };
    }
    return Score(
      current: _int(j['current']),
      display: _int(j['display']),
      period1: _int(j['period1']),
      period2: _int(j['period2']),
      period3: _int(j['period3']),
      period4: _int(j['period4']),
      period5: _int(j['period5']),
      period6: _int(j['period6']),
      period7: _int(j['period7']),
      period8: _int(j['period8']),
      period9: _int(j['period9']),
      normaltime: _int(j['normaltime']),
      innings: innings,
      currentCricketDisplay: _str(j['currentCricketDisplay']),
    );
  }

  List<int?> get periods =>
      [period1, period2, period3, period4, period5, period6, period7, period8, period9];
}

class MmaFightTime {
  const MmaFightTime({
    this.period1,
    this.period2,
    this.period3,
    this.period4,
    this.period5,
    this.played,
    this.totalPeriodCount,
  });

  final int? period1;
  final int? period2;
  final int? period3;
  final int? period4;
  final int? period5;
  final int? played;
  final int? totalPeriodCount;

  factory MmaFightTime.fromJson(Map<String, dynamic> j) => MmaFightTime(
        period1: _int(j['period1']),
        period2: _int(j['period2']),
        period3: _int(j['period3']),
        period4: _int(j['period4']),
        period5: _int(j['period5']),
        played: _int(j['played']),
        totalPeriodCount: _int(j['totalPeriodCount']),
      );
}

class VenueCity {
  const VenueCity({this.id, this.name, this.country});
  final int? id;
  final String? name;
  final StageCountry? country;

  factory VenueCity.fromJson(Map<String, dynamic> j) => VenueCity(
        id: _int(j['id']),
        name: _str(j['name']),
        country: _obj(j['country']) == null
            ? null
            : StageCountry.fromJson(_obj(j['country'])!),
      );
}

class Venue {
  const Venue({this.id, this.name, this.slug, this.city, this.country});

  final int? id;
  final String? name;
  final String? slug;
  final VenueCity? city;
  final StageCountry? country;

  factory Venue.fromJson(Map<String, dynamic> j) => Venue(
        id: _int(j['id']),
        name: _str(j['name']),
        slug: _str(j['slug']),
        city: _obj(j['city']) == null ? null : VenueCity.fromJson(_obj(j['city'])!),
        country: _obj(j['country']) == null
            ? null
            : StageCountry.fromJson(_obj(j['country'])!),
      );
}

class SofascoreEvent {
  const SofascoreEvent({
    required this.id,
    this.name,
    this.slug,
    this.startTimestamp = 0,
    this.status,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.winnerCode,
    this.tournament,
    this.currentBattingTeamId,
    this.lastPeriod,
    this.venue,
    this.fightType,
    this.weightClass,
    this.winType,
    this.finalRound,
    this.order,
    this.time,
  });

  final int id;
  final String? name;
  final String? slug;
  final int startTimestamp;
  final EventStatus? status;
  final Team? homeTeam;
  final Team? awayTeam;
  final Score? homeScore;
  final Score? awayScore;
  final int? winnerCode;
  final Tournament? tournament;
  final int? currentBattingTeamId;
  final String? lastPeriod;
  final Venue? venue;
  final String? fightType;
  final String? weightClass;
  final String? winType;
  final int? finalRound;
  final int? order;
  final MmaFightTime? time;

  factory SofascoreEvent.fromJson(Map<String, dynamic> j) => SofascoreEvent(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']),
        slug: _str(j['slug']),
        startTimestamp: _int(j['startTimestamp']) ?? 0,
        status: _obj(j['status']) == null
            ? null
            : EventStatus.fromJson(_obj(j['status'])!),
        homeTeam:
            _obj(j['homeTeam']) == null ? null : Team.fromJson(_obj(j['homeTeam'])!),
        awayTeam:
            _obj(j['awayTeam']) == null ? null : Team.fromJson(_obj(j['awayTeam'])!),
        homeScore:
            _obj(j['homeScore']) == null ? null : Score.fromJson(_obj(j['homeScore'])!),
        awayScore:
            _obj(j['awayScore']) == null ? null : Score.fromJson(_obj(j['awayScore'])!),
        winnerCode: _int(j['winnerCode']),
        tournament: _obj(j['tournament']) == null
            ? null
            : Tournament.fromJson(_obj(j['tournament'])!),
        currentBattingTeamId: _int(j['currentBattingTeamId']),
        lastPeriod: _str(j['lastPeriod']),
        venue: _obj(j['venue']) == null ? null : Venue.fromJson(_obj(j['venue'])!),
        fightType: _str(j['fightType']),
        weightClass: _str(j['weightClass']),
        winType: _str(j['winType']),
        finalRound: _int(j['finalRound']),
        order: _int(j['order']),
        time: _obj(j['time']) == null ? null : MmaFightTime.fromJson(_obj(j['time'])!),
      );

  String get sportSlug => tournament?.sportSlug ?? '';
  String get statusType => status?.type ?? '';
  DateTime get startTime =>
      DateTime.fromMillisecondsSinceEpoch(startTimestamp * 1000);
}

// ---- Stage (motorsport / cycling) ----

class StageType {
  const StageType({this.id, this.name});
  final int? id;
  final String? name;

  factory StageType.fromJson(Map<String, dynamic> j) =>
      StageType(id: _int(j['id']), name: _str(j['name']));
}

class StageInfo {
  const StageInfo({this.discipline, this.version, this.stageRound});
  final String? discipline;
  final String? version;
  final int? stageRound;

  factory StageInfo.fromJson(Map<String, dynamic> j) => StageInfo(
        discipline: _str(j['discipline']),
        version: _str(j['version']),
        stageRound: _int(j['stageRound']),
      );
}

class StageParent {
  const StageParent({this.id, this.slug, this.description, this.startDateTimestamp});
  final int? id;
  final String? slug;
  final String? description;
  final int? startDateTimestamp;

  factory StageParent.fromJson(Map<String, dynamic> j) => StageParent(
        id: _int(j['id']),
        slug: _str(j['slug']),
        description: _str(j['description']),
        startDateTimestamp: _int(j['startDateTimestamp']),
      );
}

class UniqueStage {
  const UniqueStage({
    required this.id,
    this.name,
    this.slug,
    this.primaryColorHex,
    this.secondaryColorHex,
    this.category,
  });

  final int id;
  final String? name;
  final String? slug;
  final String? primaryColorHex;
  final String? secondaryColorHex;
  final Category? category;

  factory UniqueStage.fromJson(Map<String, dynamic> j) => UniqueStage(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']),
        slug: _str(j['slug']),
        primaryColorHex: _str(j['primaryColorHex']),
        secondaryColorHex: _str(j['secondaryColorHex']),
        category:
            _obj(j['category']) == null ? null : Category.fromJson(_obj(j['category'])!),
      );

  String get logoUrl => ApiConstants.uniqueStageLogo(id);
}

class Substage {
  const Substage({
    this.id,
    this.slug,
    this.name,
    this.description,
    this.type,
    this.status,
    this.startDateTimestamp,
  });

  final int? id;
  final String? slug;
  final String? name;
  final String? description;
  final StageType? type;
  final EventStatus? status;
  final int? startDateTimestamp;

  factory Substage.fromJson(Map<String, dynamic> j) => Substage(
        id: _int(j['id']),
        slug: _str(j['slug']),
        name: _str(j['name']),
        description: _str(j['description']),
        type: _obj(j['type']) == null ? null : StageType.fromJson(_obj(j['type'])!),
        status: _obj(j['status']) == null
            ? null
            : EventStatus.fromJson(_obj(j['status'])!),
        startDateTimestamp: _int(j['startDateTimestamp']),
      );
}

class SofascoreStage {
  const SofascoreStage({
    required this.id,
    this.slug,
    this.name,
    this.description,
    this.type,
    this.uniqueStage,
    this.country,
    this.substage,
    this.substageStartDateTimestamps,
    this.startDateTimestamp,
    this.endDateTimestamp,
    this.year,
    this.status,
    this.winner,
    this.substages,
    this.info,
    this.stageParent,
    this.sequence,
    this.flag,
    this.hasCompetitorResults,
  });

  final int id;
  final String? slug;
  final String? name;
  final String? description;
  final StageType? type;
  final UniqueStage? uniqueStage;
  final StageCountry? country;
  final Substage? substage;
  final List<int>? substageStartDateTimestamps;
  final int? startDateTimestamp;
  final int? endDateTimestamp;
  final String? year;
  final EventStatus? status;
  final Team? winner;
  final List<SofascoreStage>? substages;
  final StageInfo? info;
  final StageParent? stageParent;
  final int? sequence;
  final String? flag;
  final bool? hasCompetitorResults;

  factory SofascoreStage.fromJson(Map<String, dynamic> j) => SofascoreStage(
        id: _int(j['id']) ?? 0,
        slug: _str(j['slug']),
        name: _str(j['name']),
        description: _str(j['description']),
        type: _obj(j['type']) == null ? null : StageType.fromJson(_obj(j['type'])!),
        uniqueStage: _obj(j['uniqueStage']) == null
            ? null
            : UniqueStage.fromJson(_obj(j['uniqueStage'])!),
        country: _obj(j['country']) == null
            ? null
            : StageCountry.fromJson(_obj(j['country'])!),
        substage: _obj(j['substage']) == null
            ? null
            : Substage.fromJson(_obj(j['substage'])!),
        substageStartDateTimestamps: (j['substageStartDateTimestamps'] as List?)
            ?.map((e) => _int(e) ?? 0)
            .toList(),
        startDateTimestamp: _int(j['startDateTimestamp']),
        endDateTimestamp: _int(j['endDateTimestamp']),
        year: _str(j['year']),
        status: _obj(j['status']) == null
            ? null
            : EventStatus.fromJson(_obj(j['status'])!),
        winner: _obj(j['winner']) == null ? null : Team.fromJson(_obj(j['winner'])!),
        substages: j['substages'] == null
            ? null
            : _list(j['substages'], SofascoreStage.fromJson),
        info: _obj(j['info']) == null ? null : StageInfo.fromJson(_obj(j['info'])!),
        stageParent: _obj(j['stageParent']) == null
            ? null
            : StageParent.fromJson(_obj(j['stageParent'])!),
        sequence: _int(j['sequence']),
        flag: _str(j['flag']),
        hasCompetitorResults: _bool(j['hasCompetitorResults']),
      );

  String get sportSlug => uniqueStage?.category?.sportSlug ?? '';
  DateTime? get startTime => startDateTimestamp == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(startDateTimestamp! * 1000);
}

// ---- Kiểu phụ ----

class SeasonInfo {
  const SeasonInfo({required this.id, required this.name, this.year});
  final int id;
  final String name;
  final String? year;

  factory SeasonInfo.fromJson(Map<String, dynamic> j) => SeasonInfo(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']) ?? '',
        year: _str(j['year']),
      );
}

class SportEventCount {
  const SportEventCount({this.live = 0, this.total = 0});
  final int live;
  final int total;

  factory SportEventCount.fromJson(Map<String, dynamic> j) => SportEventCount(
        live: _int(j['live']) ?? 0,
        total: _int(j['total']) ?? 0,
      );
}

class CategoryItem {
  const CategoryItem({this.category, this.totalEvents = 0, this.uniqueTournamentIds});
  final Category? category;
  final int totalEvents;
  final List<int>? uniqueTournamentIds;

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
        category:
            _obj(j['category']) == null ? null : Category.fromJson(_obj(j['category'])!),
        totalEvents: _int(j['totalEvents']) ?? 0,
        uniqueTournamentIds:
            (j['uniqueTournamentIds'] as List?)?.map((e) => _int(e) ?? 0).toList(),
      );
}

class DailyUniqueTournament {
  const DailyUniqueTournament({required this.date, this.uniqueTournamentIds});
  final String date;
  final List<int>? uniqueTournamentIds;

  factory DailyUniqueTournament.fromJson(Map<String, dynamic> j) =>
      DailyUniqueTournament(
        date: _str(j['date']) ?? '',
        uniqueTournamentIds:
            (j['uniqueTournamentIds'] as List?)?.map((e) => _int(e) ?? 0).toList(),
      );
}

class DailyStage {
  const DailyStage({required this.date, this.stageIds});
  final String date;
  final List<int>? stageIds;

  factory DailyStage.fromJson(Map<String, dynamic> j) => DailyStage(
        date: _str(j['date']) ?? '',
        stageIds: (j['stageIds'] as List?)?.map((e) => _int(e) ?? 0).toList(),
      );
}

class StageCategory {
  const StageCategory({
    this.category,
    this.name,
    this.slug,
    this.sport,
    this.sportVariant,
    this.priority = 0,
    this.id = 0,
    this.flag,
    this.uniqueStages,
  });

  final Category? category;
  final String? name;
  final String? slug;
  final Sport? sport;
  final int? sportVariant;
  final int priority;
  final int id;
  final String? flag;
  final List<UniqueStage>? uniqueStages;

  factory StageCategory.fromJson(Map<String, dynamic> j) => StageCategory(
        category:
            _obj(j['category']) == null ? null : Category.fromJson(_obj(j['category'])!),
        name: _str(j['name']),
        slug: _str(j['slug']),
        sport: _obj(j['sport']) == null ? null : Sport.fromJson(_obj(j['sport'])!),
        sportVariant: _int(j['sportVariant']),
        priority: _int(j['priority']) ?? 0,
        id: _int(j['id']) ?? 0,
        flag: _str(j['flag']),
        uniqueStages: j['uniqueStages'] == null
            ? null
            : _list(j['uniqueStages'], UniqueStage.fromJson),
      );

  /// Bản gốc: `resolvedCategory` — dựng Category từ field phẳng khi thiếu.
  Category? get resolvedCategory {
    if (category != null) return category;
    if (id <= 0) return null;
    return Category(
      id: id,
      name: name ?? '',
      slug: slug,
      flag: flag,
      alpha2: null,
      sport: sport,
      priority: priority,
      sportVariant: sportVariant,
    );
  }
}

class PlayerSuggestionItem {
  const PlayerSuggestionItem({
    required this.id,
    required this.name,
    this.slug,
    this.shortName,
    this.position,
    this.jerseyNumber,
    this.team,
  });

  final int id;
  final String name;
  final String? slug;
  final String? shortName;
  final String? position;
  final String? jerseyNumber;
  final Team? team;

  factory PlayerSuggestionItem.fromJson(Map<String, dynamic> j) =>
      PlayerSuggestionItem(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']) ?? '',
        slug: _str(j['slug']),
        shortName: _str(j['shortName']),
        position: _str(j['position']),
        jerseyNumber: _str(j['jerseyNumber']),
        team: _obj(j['team']) == null ? null : Team.fromJson(_obj(j['team'])!),
      );

  String get imageUrl => ApiConstants.playerImage(id);
}

class UniqueTournamentDetail {
  const UniqueTournamentDetail({
    required this.id,
    required this.name,
    this.slug,
    this.userCount = 0,
    this.yearOfFoundation,
    this.chairman,
    this.owner,
    this.numberOfCompetitors,
    this.numberOfDivisions,
    this.country,
  });

  final int id;
  final String name;
  final String? slug;
  final int userCount;
  final int? yearOfFoundation;
  final String? chairman;
  final String? owner;
  final int? numberOfCompetitors;
  final int? numberOfDivisions;
  final StageCountry? country;

  factory UniqueTournamentDetail.fromJson(Map<String, dynamic> j) =>
      UniqueTournamentDetail(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']) ?? '',
        slug: _str(j['slug']),
        userCount: _int(j['userCount']) ?? 0,
        yearOfFoundation: _int(j['yearOfFoundation']),
        chairman: _str(j['chairman']),
        owner: _str(j['owner']),
        numberOfCompetitors: _int(j['numberOfCompetitors']),
        numberOfDivisions: _int(j['numberOfDivisions']),
        country: _obj(j['country']) == null
            ? null
            : StageCountry.fromJson(_obj(j['country'])!),
      );

  String get logoUrl => ApiConstants.uniqueTournamentLogo(id);
}

// ---- Bao ngoài response ----

class SofascoreResponses {
  const SofascoreResponses._();

  static List<SofascoreEvent> events(Map<String, dynamic> j) =>
      _list(j['events'], SofascoreEvent.fromJson);

  static List<SofascoreEvent> featuredEvents(Map<String, dynamic> j) =>
      _list(j['featuredEvents'], SofascoreEvent.fromJson);

  static List<CategoryItem> categoryItems(Map<String, dynamic> j) =>
      _list(j['categories'], CategoryItem.fromJson);

  static List<Category> categories(Map<String, dynamic> j) =>
      _list(j['categories'], Category.fromJson);

  static List<StageCategory> stageCategories(Map<String, dynamic> j) =>
      _list(j['categories'], StageCategory.fromJson);

  static List<DailyUniqueTournament> calendar(Map<String, dynamic> j) =>
      _list(j['dailyUniqueTournaments'], DailyUniqueTournament.fromJson);

  static List<DailyStage> stageCalendar(Map<String, dynamic> j) =>
      _list(j['dailyStages'], DailyStage.fromJson);

  static List<SofascoreStage> stages(Map<String, dynamic> j) =>
      _list(j['stages'], SofascoreStage.fromJson);

  static List<SofascoreStage> stageSeasons(Map<String, dynamic> j) =>
      _list(j['seasons'], SofascoreStage.fromJson);

  static SofascoreStage? stage(Map<String, dynamic> j) =>
      _obj(j['stage']) == null ? null : SofascoreStage.fromJson(_obj(j['stage'])!);

  static SofascoreEvent? event(Map<String, dynamic> j) =>
      _obj(j['event']) == null ? null : SofascoreEvent.fromJson(_obj(j['event'])!);

  static List<UniqueTournament> uniqueTournaments(Map<String, dynamic> j) =>
      _list(j['uniqueTournaments'], UniqueTournament.fromJson);

  /// `category/{id}/unique-tournaments` trả về mảng `groups`.
  static List<UniqueTournament> groupedUniqueTournaments(Map<String, dynamic> j) {
    final groups = j['groups'];
    if (groups is! List) return const [];
    return groups
        .whereType<Map>()
        .expand((g) => uniqueTournaments(Map<String, dynamic>.from(g)))
        .toList(growable: false);
  }

  static List<Team> teams(Map<String, dynamic> j) => _list(j['teams'], Team.fromJson);

  static List<PlayerSuggestionItem> players(Map<String, dynamic> j) =>
      _list(j['players'], PlayerSuggestionItem.fromJson);

  static List<SeasonInfo> seasons(Map<String, dynamic> j) =>
      _list(j['seasons'], SeasonInfo.fromJson);

  static Tournament? tournament(Map<String, dynamic> j) => _obj(j['tournament']) == null
      ? null
      : Tournament.fromJson(_obj(j['tournament'])!);

  static UniqueTournamentDetail? uniqueTournamentDetail(Map<String, dynamic> j) =>
      _obj(j['uniqueTournament']) == null
          ? null
          : UniqueTournamentDetail.fromJson(_obj(j['uniqueTournament'])!);

  static Map<String, SportEventCount> sportEventCounts(Map<String, dynamic> j) => {
        for (final e in j.entries)
          if (e.value is Map)
            e.key: SportEventCount.fromJson(Map<String, dynamic>.from(e.value as Map)),
      };
}
