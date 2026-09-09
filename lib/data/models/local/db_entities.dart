import 'package:equatable/equatable.dart';

int? _asInt(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));
String? _asStr(Object? v) => v?.toString();

/// Port `LeagueDbHelper.LeagueEntity`.
class LeagueDbEntity extends Equatable {
  const LeagueDbEntity({
    required this.id,
    this.countryId,
    required this.name,
    this.priority,
    this.imagePath,
    this.isFavourite = false,
    this.timeUse,
    this.subType,
  });

  final int id;
  final int? countryId;
  final String name;
  final int? priority;
  final String? imagePath;
  final bool isFavourite;
  final int? timeUse;
  final int? subType;

  factory LeagueDbEntity.fromDbMap(Map<String, Object?> m) => LeagueDbEntity(
        id: _asInt(m['id']) ?? 0,
        countryId: _asInt(m['country_id']),
        name: _asStr(m['name']) ?? '',
        priority: _asInt(m['priority']),
        imagePath: _asStr(m['image_path']),
        isFavourite: (_asInt(m['is_favourite']) ?? 0) == 1,
        timeUse: _asInt(m['time_use']),
        subType: _asInt(m['sub_type']),
      );

  LeagueDbEntity copyWith({bool? isFavourite}) => LeagueDbEntity(
        id: id,
        countryId: countryId,
        name: name,
        priority: priority,
        imagePath: imagePath,
        isFavourite: isFavourite ?? this.isFavourite,
        timeUse: timeUse,
        subType: subType,
      );

  bool get isInternational => subType == 1;

  @override
  List<Object?> get props => [id, isFavourite, timeUse];
}

/// Port `LeagueDbHelper.TeamEntity`.
class TeamDbEntity extends Equatable {
  const TeamDbEntity({
    required this.id,
    required this.name,
    this.imagePath,
    this.isFavourite = false,
    this.timeUse,
    this.priority,
    this.countryId,
  });

  final int id;
  final String name;
  final String? imagePath;
  final bool isFavourite;
  final int? timeUse;
  final int? priority;
  final int? countryId;

  factory TeamDbEntity.fromDbMap(Map<String, Object?> m) => TeamDbEntity(
        id: _asInt(m['id']) ?? 0,
        name: _asStr(m['name']) ?? '',
        imagePath: _asStr(m['image_path']),
        isFavourite: (_asInt(m['is_favourite']) ?? 0) == 1,
        timeUse: _asInt(m['time_use']),
        priority: _asInt(m['priority']),
        countryId: _asInt(m['country_id']),
      );

  TeamDbEntity copyWith({bool? isFavourite}) => TeamDbEntity(
        id: id,
        name: name,
        imagePath: imagePath,
        isFavourite: isFavourite ?? this.isFavourite,
        timeUse: timeUse,
        priority: priority,
        countryId: countryId,
      );

  @override
  List<Object?> get props => [id, isFavourite, timeUse];
}

/// Port `presentation/notification/NotificationItem.kt` + hàng trong bảng
/// `fixture_notifications`.
class NotificationDbItem extends Equatable {
  const NotificationDbItem({
    required this.id,
    required this.homeName,
    required this.awayName,
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.leagueName,
    this.leagueLogoUrl,
    this.timeStr,
    this.status,
    this.sportSlug = 'football',
    this.beforeMatchMinutes = 15,
    this.notifyMatchStart = true,
    this.notifyEndFirstHalf = true,
    this.notifyStartSecondHalf = false,
    this.notifyEndMatch = false,
    this.isNotified = false,
  });

  final int id;
  final String homeName;
  final String awayName;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final String? leagueName;
  final String? leagueLogoUrl;
  final String? timeStr;
  final String? status;
  final String? sportSlug;

  final int beforeMatchMinutes;
  final bool notifyMatchStart;
  final bool notifyEndFirstHalf;
  final bool notifyStartSecondHalf;
  final bool notifyEndMatch;
  final bool isNotified;

  factory NotificationDbItem.fromDbMap(Map<String, Object?> m) =>
      NotificationDbItem(
        id: _asInt(m['fixture_id']) ?? 0,
        homeName: _asStr(m['home_name']) ?? '',
        awayName: _asStr(m['away_name']) ?? '',
        homeLogoUrl: _asStr(m['home_logo']),
        awayLogoUrl: _asStr(m['away_logo']),
        leagueName: _asStr(m['league_name']),
        leagueLogoUrl: _asStr(m['league_logo']),
        timeStr: _asStr(m['kickoff_time']),
        status: _asStr(m['status']),
        sportSlug: _asStr(m['sport_slug']) ?? 'football',
        beforeMatchMinutes: _asInt(m['before_match_minutes']) ?? 15,
        notifyMatchStart: (_asInt(m['notify_match_start']) ?? 1) == 1,
        notifyEndFirstHalf: (_asInt(m['notify_end_first_half']) ?? 1) == 1,
        notifyStartSecondHalf: (_asInt(m['notify_start_second_half']) ?? 0) == 1,
        notifyEndMatch: (_asInt(m['notify_end_match']) ?? 0) == 1,
        isNotified: true,
      );

  Map<String, Object?> toDbMap() => {
        'fixture_id': id,
        'league_name': leagueName ?? 'Unknown',
        'league_logo': leagueLogoUrl ?? '',
        'home_name': homeName,
        'home_logo': homeLogoUrl ?? '',
        'away_name': awayName,
        'away_logo': awayLogoUrl ?? '',
        'kickoff_time': timeStr ?? '',
        'status': status ?? 'NS',
        'before_match_minutes': beforeMatchMinutes,
        'notify_match_start': notifyMatchStart ? 1 : 0,
        'notify_end_first_half': notifyEndFirstHalf ? 1 : 0,
        'notify_start_second_half': notifyStartSecondHalf ? 1 : 0,
        'notify_end_match': notifyEndMatch ? 1 : 0,
        'sport_slug': sportSlug ?? 'football',
      };

  NotificationDbItem copyWith({
    int? beforeMatchMinutes,
    bool? notifyMatchStart,
    bool? notifyEndFirstHalf,
    bool? notifyStartSecondHalf,
    bool? notifyEndMatch,
    bool? isNotified,
  }) =>
      NotificationDbItem(
        id: id,
        homeName: homeName,
        awayName: awayName,
        homeLogoUrl: homeLogoUrl,
        awayLogoUrl: awayLogoUrl,
        leagueName: leagueName,
        leagueLogoUrl: leagueLogoUrl,
        timeStr: timeStr,
        status: status,
        sportSlug: sportSlug,
        beforeMatchMinutes: beforeMatchMinutes ?? this.beforeMatchMinutes,
        notifyMatchStart: notifyMatchStart ?? this.notifyMatchStart,
        notifyEndFirstHalf: notifyEndFirstHalf ?? this.notifyEndFirstHalf,
        notifyStartSecondHalf:
            notifyStartSecondHalf ?? this.notifyStartSecondHalf,
        notifyEndMatch: notifyEndMatch ?? this.notifyEndMatch,
        isNotified: isNotified ?? this.isNotified,
      );

  /// Thời điểm bóng lăn — `timeStr` có thể là epoch giây hoặc "yyyy-MM-dd HH:mm:ss" UTC.
  DateTime? get kickoffTime {
    final raw = timeStr;
    if (raw == null || raw.isEmpty) return null;
    final epoch = int.tryParse(raw);
    if (epoch != null && epoch > 0) {
      return DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    }
    return DateTime.tryParse('${raw.replaceFirst(' ', 'T')}Z')?.toLocal();
  }

  @override
  List<Object?> get props => [id, beforeMatchMinutes, notifyMatchStart];
}
