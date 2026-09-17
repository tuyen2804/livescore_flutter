import 'package:flutter/material.dart';

import '../../presentation/screens/detail/league_detail_screen.dart';
import '../../presentation/screens/detail/match_detail_screen.dart';
import '../../presentation/screens/detail/match_forecast_screen.dart';
import '../../presentation/screens/detail/player_detail_screen.dart';
import '../../presentation/screens/detail/team_detail_screen.dart';
import '../../presentation/screens/highlight/highlight_detail_screen.dart';
import '../../presentation/screens/highlight/highlight_list_screen.dart';
import '../../presentation/screens/language/language_screen.dart';
import '../../presentation/screens/language/loading_screen.dart';
import '../../presentation/screens/live/live_matches_screen.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/notification/notification_screen.dart';
import '../../presentation/screens/notification/notification_settings_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/onboarding/pick_favorite_leagues_screen.dart';
import '../../presentation/screens/onboarding/pick_favorite_teams_screen.dart';
import '../../presentation/screens/search/search_league_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/premium/premium_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/sofascore/mma_tournament_screen.dart';
import '../../presentation/screens/sofascore/motorsport_series_screen.dart';
import '../../presentation/screens/sofascore/motorsport_stage_screen.dart';
import '../../presentation/screens/sofascore/sofascore_match_detail_screen.dart';
import '../../presentation/screens/sofascore/sofascore_team_detail_screen.dart';
import '../../presentation/screens/sofascore/unique_tournament_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

/// Thay cho `main_nav_graph.xml` + `nav_graph.xml`.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String language = '/language';
  static const String loading = '/loading';
  static const String onboarding = '/onboarding';
  static const String pickFavoriteLeagues = '/pick-favorite-leagues';
  static const String pickFavoriteTeams = '/pick-favorite-teams';
  static const String main = '/main';

  static const String settings = '/settings';
  static const String premium = '/premium';
  static const String notification = '/notification';
  static const String notificationSettings = '/notification-settings';
  static const String search = '/search';
  static const String searchLeague = '/search-league';
  static const String liveMatches = '/live-matches';

  static const String matchDetail = '/match-detail';
  static const String matchForecast = '/match-forecast';
  static const String leagueDetail = '/league-detail';
  static const String teamDetail = '/team-detail';
  static const String playerDetail = '/player-detail';

  static const String highlightDetail = '/highlight-detail';
  static const String highlightList = '/highlight-list';

  static const String sofascoreMatchDetail = '/sofascore-match-detail';
  static const String sofascoreTeamDetail = '/sofascore-team-detail';
  static const String uniqueTournament = '/unique-tournament';
  static const String mmaTournament = '/mma-tournament';
  static const String motorsportSeries = '/motorsport-series';
  static const String motorsportStage = '/motorsport-stage';
}

class AppRouter {
  const AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    Widget page() => switch (settings.name) {
          AppRoutes.splash => const SplashScreen(),
          AppRoutes.language => LanguageScreen(
              fromSettings: (args as Map?)?['fromSettings'] as bool? ?? false,
            ),
          AppRoutes.loading => const LoadingScreen(),
          AppRoutes.onboarding => const OnboardingScreen(),
          AppRoutes.pickFavoriteLeagues => const PickFavoriteLeaguesScreen(),
          AppRoutes.pickFavoriteTeams => const PickFavoriteTeamsScreen(),
          AppRoutes.main => MainScreen(
              initialTab: (args as Map?)?['tab'] as int? ?? 0,
            ),
          AppRoutes.settings => const SettingsScreen(),
          AppRoutes.premium => PremiumScreen(
              fromOnboarding:
                  _arg<bool>(args, 'fromOnboarding') ?? false,
            ),
          AppRoutes.notification => const NotificationScreen(),
          AppRoutes.notificationSettings => const NotificationSettingsScreen(),
          AppRoutes.search => const SearchScreen(),
          AppRoutes.searchLeague => const SearchLeagueScreen(),
          AppRoutes.liveMatches => const LiveMatchesScreen(),
          AppRoutes.matchDetail => MatchDetailScreen(
              matchId: _arg<int>(args, 'matchId') ?? 0,
            ),
          AppRoutes.matchForecast => MatchForecastScreen(
              matchId: _arg<int>(args, 'matchId') ?? 0,
              homeTeamName: _arg<String>(args, 'homeTeamName') ?? '',
              awayTeamName: _arg<String>(args, 'awayTeamName') ?? '',
              homeTeamLogo: _arg<String>(args, 'homeTeamLogo'),
              awayTeamLogo: _arg<String>(args, 'awayTeamLogo'),
              kickoffEpoch: _arg<int>(args, 'kickoffEpoch') ?? 0,
              countryName: _arg<String>(args, 'countryName'),
            ),
          AppRoutes.leagueDetail => LeagueDetailScreen(
              leagueId: _arg<int>(args, 'leagueId') ?? 0,
              leagueName: _arg<String>(args, 'leagueName') ?? '',
              leagueLogo: _arg<String>(args, 'leagueLogo'),
              countryName: _arg<String>(args, 'countryName'),
            ),
          AppRoutes.teamDetail => TeamDetailScreen(
              teamId: _arg<int>(args, 'teamId') ?? 0,
            ),
          AppRoutes.playerDetail => PlayerDetailScreen(
              playerName: _arg<String>(args, 'playerName') ?? '',
              playerPos: _arg<String>(args, 'playerPos') ?? '',
              playerImg: _arg<String>(args, 'playerImg'),
              teamName: _arg<String>(args, 'teamName') ?? '',
              playerHeight: _arg<String>(args, 'playerHeight'),
              playerWeight: _arg<String>(args, 'playerWeight'),
              playerAge: _arg<String>(args, 'playerAge'),
              playerNumber: _arg<String>(args, 'playerNumber'),
              playerNationality: _arg<String>(args, 'playerNationality'),
              playerId: _arg<int>(args, 'playerId'),
            ),
          AppRoutes.highlightDetail => HighlightDetailScreen(
              url: _arg<String>(args, 'url') ?? '',
              title: _arg<String>(args, 'title') ?? '',
              homeTeam: _arg<String>(args, 'homeTeam') ?? '',
              awayTeam: _arg<String>(args, 'awayTeam') ?? '',
              leagueName: _arg<String>(args, 'leagueName') ?? '',
              thumb: _arg<String>(args, 'thumb'),
            ),
          AppRoutes.highlightList => HighlightListScreen(
              title: _arg<String>(args, 'title') ?? '',
              ids: (args is Map ? args['ids'] : null) is List
                  ? List<int>.from((args as Map)['ids'] as List)
                  : null,
            ),
          AppRoutes.sofascoreMatchDetail => SofascoreMatchDetailScreen(
              eventId: _arg<int>(args, 'eventId') ?? 0,
              sportSlug: _arg<String>(args, 'sportSlug') ?? '',
            ),
          AppRoutes.sofascoreTeamDetail => SofascoreTeamDetailScreen(
              teamId: _arg<int>(args, 'teamId') ?? 0,
              teamName: _arg<String>(args, 'teamName') ?? '',
              sportSlug: _arg<String>(args, 'sportSlug') ?? '',
            ),
          AppRoutes.uniqueTournament => UniqueTournamentScreen(
              uniqueTournamentId: _arg<int>(args, 'uniqueTournamentId') ?? 0,
              name: _arg<String>(args, 'name') ?? '',
              sportSlug: _arg<String>(args, 'sportSlug') ?? '',
            ),
          AppRoutes.mmaTournament => MmaTournamentScreen(
              uniqueTournamentId: _arg<int>(args, 'uniqueTournamentId') ?? 0,
              name: _arg<String>(args, 'name') ?? '',
              tournamentId: _arg<int>(args, 'tournamentId') ?? 0,
            ),
          AppRoutes.motorsportSeries => MotorsportSeriesScreen(
              uniqueStageId: _arg<int>(args, 'uniqueStageId') ?? 0,
              name: _arg<String>(args, 'name') ?? '',
              sportSlug: _arg<String>(args, 'sportSlug') ?? 'motorsport',
            ),
          AppRoutes.motorsportStage => MotorsportStageScreen(
              stageId: _arg<int>(args, 'stageId') ?? 0,
              name: _arg<String>(args, 'name') ?? '',
              sportSlug: _arg<String>(args, 'sportSlug') ?? 'motorsport',
            ),
          _ => const SplashScreen(),
        };

    return MaterialPageRoute(builder: (_) => page(), settings: settings);
  }

  static T? _arg<T>(Object? args, String key) {
    if (args is! Map) return null;
    final value = args[key];
    return value is T ? value : null;
  }
}
