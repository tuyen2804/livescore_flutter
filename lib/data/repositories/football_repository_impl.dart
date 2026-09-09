import 'dart:developer' as dev;

import '../../core/error/either.dart';
import '../../core/error/exceptions.dart' as app;
import '../../core/error/failures.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/match_status.dart';
import '../../domain/entities/match_entities.dart';
import '../../domain/repositories/football_repository.dart';
import '../datasources/local/league_db_helper.dart';
import '../datasources/remote/football_remote_data_source.dart';
import '../models/football/football_models.dart';

class FootballRepositoryImpl implements FootballRepository {
  FootballRepositoryImpl(this._remote, this._db);

  final FootballRemoteDataSource _remote;
  final LeagueDbHelper _db;

  static const String _tag = 'FootballRepository';

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

  /// Port `HomeViewModel.fetchForDate` nhánh bóng đá: gọi 3 ngày
  /// (hôm trước / hôm nay / hôm sau) để bắt trọn trận lệch múi giờ.
  @override
  Future<Either<Failure, List<LeagueSection>>> getLeagueLive(
    DateTime date,
  ) async =>
      _run(() async {
        final dateStr = DateTimeUtils.apiDate(date);
        final prevStr = DateTimeUtils.apiDate(date.subtract(const Duration(days: 1)));
        final nextStr = DateTimeUtils.apiDate(date.add(const Duration(days: 1)));

        Future<List<MatchDto>> safeFetch(String d) async {
          try {
            return await _remote.getLeagueLive(d);
          } catch (e) {
            dev.log('getLeagueLive($d) failed: $e', name: _tag);
            return const [];
          }
        }

        final results = await Future.wait([
          safeFetch(dateStr),
          safeFetch(prevStr),
          safeFetch(nextStr),
        ]);

        return _processMatches(results.expand((e) => e).toList(), dateStr);
      });

  /// Port `HomeViewModel.processMatches`.
  Future<List<LeagueSection>> _processMatches(
    List<MatchDto> apiMatches,
    String dateStr,
  ) async {
    // distinctBy id + chỉ giữ trận rơi vào đúng ngày theo giờ máy.
    final seen = <int>{};
    final filtered = <MatchDto>[];
    for (final m in apiMatches) {
      if (!seen.add(m.id)) continue;
      if (DateTimeUtils.formatEpochToLocalDateFull(m.kickoffEpoch) == dateStr) {
        filtered.add(m);
      }
    }

    final favLeagues = (await _db.getFavouriteLeagues()).map((e) => e.id).toSet();
    final favTeams = (await _db.getFavouriteTeams()).map((e) => e.id).toSet();
    final allLeagues = await _db.getAllLeagues();
    final topLeagues = allLeagues
        .where((e) => e.priority != null)
        .map((e) => e.id)
        .toSet();
    final knownFootballLeagueIds = allLeagues.map((e) => e.id).toSet();
    final notifiedIds = await _db.getNotifiedFixtureIds();

    bool isWorldCup(String name) => name.trim().toLowerCase() == 'world cup';

    final sorted = filtered.toList()
      ..sort((m1, m2) {
        final wc1 = isWorldCup(m1.leagueName);
        final wc2 = isWorldCup(m2.leagueName);
        if (wc1 != wc2) return wc1 ? -1 : 1;

        final fl1 = favLeagues.contains(m1.leagueId);
        final fl2 = favLeagues.contains(m2.leagueId);
        if (fl1 != fl2) return fl1 ? -1 : 1;

        final ft1 = favTeams.contains(m1.homeId) || favTeams.contains(m1.awayId);
        final ft2 = favTeams.contains(m2.homeId) || favTeams.contains(m2.awayId);
        if (ft1 != ft2) return ft1 ? -1 : 1;

        final t1 = topLeagues.contains(m1.leagueId);
        final t2 = topLeagues.contains(m2.leagueId);
        if (t1 != t2) return t1 ? -1 : 1;

        return m1.kickoffEpoch.compareTo(m2.kickoffEpoch);
      });

    final grouped = <int, List<MatchDto>>{};
    for (final m in sorted) {
      grouped.putIfAbsent(m.leagueId, () => <MatchDto>[]).add(m);
    }

    final sections = <LeagueSection>[];
    for (final matches in grouped.values) {
      final first = matches.first;
      final rawLeagueName = first.leagueName;
      final groupName = first.groupName?.trim();

      final isOtherSport = _isOtherSportLeague(
        rawLeagueName,
        groupName,
        first.leagueId,
        knownFootballLeagueIds,
      );

      String? categoryName;
      if (isOtherSport) {
        final lower = rawLeagueName.toLowerCase();
        categoryName = switch (true) {
          _ when groupName != null && groupName.isNotEmpty => groupName,
          _ when lower.contains('atp') => 'ATP',
          _ when lower.contains('wta') => 'WTA',
          _ when lower.contains('itf') => 'ITF',
          _ when lower.contains('washington') => 'ATP',
          _ => 'ATP',
        };
      }

      var cleanLeagueName = rawLeagueName;
      if (isOtherSport && categoryName != null) {
        cleanLeagueName = cleanLeagueName
            .replaceAll(RegExp(', ${RegExp.escape(categoryName)}', caseSensitive: false), '')
            .replaceAll(RegExp(' ${RegExp.escape(categoryName)}', caseSensitive: false), '')
            .replaceAll(RegExp('${RegExp.escape(categoryName)} - ', caseSensitive: false), '')
            .trim();
      }

      final fixtures = matches.map((match) {
        final scores = match.score?.split('-');
        final scoreHome = scores == null || scores.isEmpty
            ? null
            : int.tryParse(scores[0].trim());
        final scoreAway = scores == null || scores.length < 2
            ? null
            : int.tryParse(scores[1].trim());

        return MatchFixture(
          id: '${match.id}',
          teamHome: match.homeName,
          teamAway: match.awayName,
          scoreHome: scoreHome,
          scoreAway: scoreAway,
          matchTime: DateTimeUtils.formatEpochToLocalTime(match.kickoffEpoch),
          status: MatchStatus.fromState(match.state),
          homeLogoUrl: match.homeTeamLogoUrl,
          awayLogoUrl: match.awayTeamLogoUrl,
          matchDate: DateTimeUtils.formatEpochToLocalDate(match.kickoffEpoch),
          leagueName: cleanLeagueName,
          isNotified: notifiedIds.contains(match.id),
          kickoffUtc: match.kickoffUtc,
          state: match.state,
          categoryName: categoryName,
          isFootball: !isOtherSport,
          playingTime: match.playingTime,
        );
      }).toList()
        ..sort((a, b) =>
            MatchStatus.sortRank(a.status).compareTo(MatchStatus.sortRank(b.status)));

      sections.add(LeagueSection(
        leagueName: cleanLeagueName,
        leagueLogoUrl: first.leagueLogoUrl,
        fixtures: fixtures,
        countryId: first.countryId,
        leagueId: first.leagueId,
        categoryName: categoryName,
        isFootball: !isOtherSport,
      ));
    }

    return sections;
  }

  /// Port `HomeViewModel.isOtherSportLeague`.
  bool _isOtherSportLeague(
    String rawLeagueName,
    String? groupName,
    int leagueId,
    Set<int> knownFootballLeagueIds,
  ) {
    final name = rawLeagueName.trim().toLowerCase();
    final group = (groupName ?? '').trim().toLowerCase();

    const otherKeywords = [
      'atp', 'wta', 'itf', 'tennis', 'quần vợt',
      'nba', 'basketball', 'bóng rổ', 'mlb', 'baseball',
      'nhl', 'hockey', 'volleyball', 'washington', 'wimbledon',
      'roland garros', 'us open', 'australian open',
    ];
    for (final kw in otherKeywords) {
      if (name.contains(kw) || group.contains(kw)) return true;
    }

    const footballKeywords = [
      'premier league', 'champions league', 'la liga', 'serie a', 'bundesliga',
      'ligue 1', 'europa league', 'world cup', 'euro', 'v-league', 'mls',
      'fa cup', 'efl', 'league one', 'league two', 'eredivisie',
      'primeira liga', 'copa',
    ];
    for (final kw in footballKeywords) {
      if (name.contains(kw)) return false;
    }

    if (knownFootballLeagueIds.contains(leagueId)) return false;
    return true;
  }

  @override
  Future<Either<Failure, MatchCentreDataDto>> getMatchCentre(int fixtureId) =>
      _run(() async {
        final data = await _remote.getMatchCentreLive(fixtureId);
        if (data == null) throw app.ParseException('Empty match centre');
        return data;
      });

  @override
  Future<Either<Failure, List<StandingTeamDto>>> getStandings(int leagueId) =>
      _run(() => _remote.getStandings(leagueId));

  @override
  Future<Either<Failure, List<UpcomingFixtureDto>>> getLeagueFixtures(
    int leagueId,
  ) =>
      _run(() => _remote.getLeagueFixtures(leagueId));

  @override
  Future<Either<Failure, ForecastData>> getMatchForecast(int fixtureId) =>
      _run(() async {
        final data = await _remote.getMatchForecast(fixtureId);
        if (data == null) throw app.ParseException('Empty forecast');
        return data;
      });

  @override
  Future<Either<Failure, List<FavoriteFixtureDto>>> getTeamFixtures(int teamId) =>
      _run(() => _remote.getFixturesByDateForTeam(teamId));

  @override
  Future<Either<Failure, List<SquadPlayerDto>>> getSquad(int teamId) =>
      _run(() => _remote.getSquad(teamId));

  @override
  Future<Either<Failure, MatchVoteDto>> getVote(int fixtureId) =>
      _run(() => _remote.getVoteTeam(fixtureId));

  @override
  Future<Either<Failure, void>> vote(int fixtureId, int choice) =>
      _run(() => _remote.voteTeam(fixtureId, choice));
}
