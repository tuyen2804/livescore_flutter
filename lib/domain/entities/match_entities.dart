import 'package:equatable/equatable.dart';

/// Port của `data/Models.kt` — entity mà tầng UI tiêu thụ.

class LiveMatch extends Equatable {
  const LiveMatch({
    required this.id,
    required this.teamHome,
    required this.teamAway,
    required this.scoreHome,
    required this.scoreAway,
    required this.matchTime,
    required this.leagueName,
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.leagueLogoUrl,
    this.venue,
    this.region,
  });

  final String id;
  final String teamHome;
  final String teamAway;
  final int scoreHome;
  final int scoreAway;
  final String matchTime;
  final String leagueName;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final String? leagueLogoUrl;
  final String? venue;
  final String? region;

  @override
  List<Object?> get props => [id, scoreHome, scoreAway, matchTime];
}

/// Một trận trong danh sách. `state` theo mã của API bóng đá riêng;
/// với môn Sofascore thì `isFootball = false`.
class MatchFixture extends Equatable {
  const MatchFixture({
    required this.id,
    required this.teamHome,
    required this.teamAway,
    this.scoreHome,
    this.scoreAway,
    required this.matchTime,
    required this.status,
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.matchDate,
    this.leagueName,
    this.isNotified = false,
    this.kickoffUtc,
    this.state = 0,
    this.subHeader,
    this.subHeaderLogoUrl,
    this.categoryName,
    this.isFootball = true,
    this.sportSlug = 'football',
    this.playingTime = 0,
    this.homeSubScore,
    this.awaySubScore,
    this.homePeriods = const [],
    this.awayPeriods = const [],
    this.winnerCode,
  });

  final String id;
  final String teamHome;
  final String teamAway;
  final int? scoreHome;
  final int? scoreAway;
  final String matchTime;
  final String status;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final String? matchDate;
  final String? leagueName;
  final bool isNotified;
  final String? kickoffUtc;
  final int state;
  final String? subHeader;
  final String? subHeaderLogoUrl;
  final String? categoryName;
  final bool isFootball;
  final String sportSlug;

  /// Phút thi đấu do API trả về (`MatchDto.playingTime`).
  final int playingTime;

  /// Điểm phụ (set/game) cho tennis, bóng chuyền...
  final String? homeSubScore;
  final String? awaySubScore;
  final List<int?> homePeriods;
  final List<int?> awayPeriods;
  final int? winnerCode;

  MatchFixture copyWith({
    bool? isNotified,
    String? leagueName,
    String? subHeader,
    String? subHeaderLogoUrl,
    String? categoryName,
  }) =>
      MatchFixture(
        id: id,
        teamHome: teamHome,
        teamAway: teamAway,
        scoreHome: scoreHome,
        scoreAway: scoreAway,
        matchTime: matchTime,
        status: status,
        homeLogoUrl: homeLogoUrl,
        awayLogoUrl: awayLogoUrl,
        matchDate: matchDate,
        leagueName: leagueName ?? this.leagueName,
        isNotified: isNotified ?? this.isNotified,
        kickoffUtc: kickoffUtc,
        state: state,
        subHeader: subHeader ?? this.subHeader,
        subHeaderLogoUrl: subHeaderLogoUrl ?? this.subHeaderLogoUrl,
        categoryName: categoryName ?? this.categoryName,
        isFootball: isFootball,
        sportSlug: sportSlug,
        playingTime: playingTime,
        homeSubScore: homeSubScore,
        awaySubScore: awaySubScore,
        homePeriods: homePeriods,
        awayPeriods: awayPeriods,
        winnerCode: winnerCode,
      );

  /// Trận chưa đá — đúng danh sách state mà `HomeMatchAdapter` dùng để
  /// ẩn tỉ số và hiện nút chuông.
  static const List<int> notStartedStates = [1, 26, 13, 19];

  bool get isNotStarted =>
      isFootball ? notStartedStates.contains(state) : status == 'NS';

  /// `HomeViewModel` coi các state này là đang/đã bắt đầu ở thẻ live.
  bool get isLive => isFootball
      ? const [2, 3, 4, 6, 7, 9, 21, 22, 23, 25].contains(state)
      : status.toLowerCase() == 'inprogress';

  bool get isFinished => isFootball
      ? const [5, 17, 8].contains(state)
      : const {'ft', 'ended', 'finished'}.contains(status.toLowerCase());

  @override
  List<Object?> get props => [id, scoreHome, scoreAway, state, status, isNotified];
}

/// Nhóm trận theo giải — item của danh sách Home.
class LeagueSection extends Equatable {
  const LeagueSection({
    required this.leagueName,
    this.leagueLogoUrl,
    required this.fixtures,
    this.countryId = 0,
    this.leagueId = 0,
    this.categoryName,
    this.isFootball = true,
    this.sportSlug = 'football',
  });

  final String leagueName;
  final String? leagueLogoUrl;
  final List<MatchFixture> fixtures;
  final int countryId;
  final int leagueId;
  final String? categoryName;
  final bool isFootball;
  final String sportSlug;

  int get matchCount => fixtures.length;

  LeagueSection copyWith({List<MatchFixture>? fixtures}) => LeagueSection(
        leagueName: leagueName,
        leagueLogoUrl: leagueLogoUrl,
        fixtures: fixtures ?? this.fixtures,
        countryId: countryId,
        leagueId: leagueId,
        categoryName: categoryName,
        isFootball: isFootball,
        sportSlug: sportSlug,
      );

  @override
  List<Object?> get props => [leagueId, leagueName, fixtures];
}

class League extends Equatable {
  const League({
    required this.id,
    required this.name,
    this.logoUrl,
    this.country,
    this.isFavorite = false,
    this.countryId,
    this.leagueId = 0,
    this.sportSlug = 'football',
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? country;
  final bool isFavorite;
  final int? countryId;
  final int leagueId;
  final String sportSlug;

  League copyWith({bool? isFavorite}) => League(
        id: id,
        name: name,
        logoUrl: logoUrl,
        country: country,
        isFavorite: isFavorite ?? this.isFavorite,
        countryId: countryId,
        leagueId: leagueId,
        sportSlug: sportSlug,
      );

  @override
  List<Object?> get props => [id, isFavorite];
}

class TeamEntity extends Equatable {
  const TeamEntity({
    required this.id,
    required this.name,
    this.logoUrl,
    this.isFavorite = false,
    this.country,
    this.sportSlug = 'football',
  });

  final String id;
  final String name;
  final String? logoUrl;
  final bool isFavorite;
  final String? country;
  final String sportSlug;

  TeamEntity copyWith({bool? isFavorite}) => TeamEntity(
        id: id,
        name: name,
        logoUrl: logoUrl,
        isFavorite: isFavorite ?? this.isFavorite,
        country: country,
        sportSlug: sportSlug,
      );

  @override
  List<Object?> get props => [id, isFavorite];
}

/// Port `data/model/DetailModels.kt` — `Fixture` dùng cho màn chi tiết đội.
class Fixture extends Equatable {
  const Fixture({
    required this.id,
    required this.homeTeamName,
    required this.homeTeamLogo,
    required this.awayTeamName,
    required this.awayTeamLogo,
    this.homeScore = '-',
    this.awayScore = '-',
    this.matchState = 'NS',
    required this.time,
    required this.date,
    this.leagueName,
    this.isNotified = false,
  });

  final String id;
  final String homeTeamName;
  final String homeTeamLogo;
  final String awayTeamName;
  final String awayTeamLogo;
  final String homeScore;
  final String awayScore;
  final String matchState;
  final String time;
  final String date;
  final String? leagueName;
  final bool isNotified;

  Fixture copyWith({bool? isNotified}) => Fixture(
        id: id,
        homeTeamName: homeTeamName,
        homeTeamLogo: homeTeamLogo,
        awayTeamName: awayTeamName,
        awayTeamLogo: awayTeamLogo,
        homeScore: homeScore,
        awayScore: awayScore,
        matchState: matchState,
        time: time,
        date: date,
        leagueName: leagueName,
        isNotified: isNotified ?? this.isNotified,
      );

  @override
  List<Object?> get props => [id, isNotified];
}

class PlayerEntity extends Equatable {
  const PlayerEntity({
    required this.id,
    required this.name,
    required this.position,
    required this.avatarUrl,
    this.height = '',
    this.weight = '',
    this.age = '',
    this.jerseyNumber = '',
    this.nationality = '',
  });

  final String id;
  final String name;
  final String position;
  final String avatarUrl;
  final String height;
  final String weight;
  final String age;
  final String jerseyNumber;
  final String nationality;

  @override
  List<Object?> get props => [id];
}

/// Item danh sách fixture có header giải — port `FixtureListItem`.
sealed class FixtureListItem extends Equatable {
  const FixtureListItem();
}

class FixtureHeaderItem extends FixtureListItem {
  const FixtureHeaderItem(this.leagueName, this.leagueLogo);
  final String leagueName;
  final String? leagueLogo;
  @override
  List<Object?> get props => [leagueName];
}

class FixtureRowItem extends FixtureListItem {
  const FixtureRowItem(this.fixture);
  final Fixture fixture;
  @override
  List<Object?> get props => [fixture];
}
