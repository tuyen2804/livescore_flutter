import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age:'**
  String get age;

  /// No description provided for @aiMainPick.
  ///
  /// In en, this message translates to:
  /// **'AI Main Pick'**
  String get aiMainPick;

  /// No description provided for @allLeagues.
  ///
  /// In en, this message translates to:
  /// **'All leagues'**
  String get allLeagues;

  /// No description provided for @allTeams.
  ///
  /// In en, this message translates to:
  /// **'All Teams'**
  String get allTeams;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Football Track: Live Match'**
  String get appName;

  /// No description provided for @areYouSureYouWantToExitApp.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit app?'**
  String get areYouSureYouWantToExitApp;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @awayText.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get awayText;

  /// No description provided for @awayWin.
  ///
  /// In en, this message translates to:
  /// **'Away Win'**
  String get awayWin;

  /// No description provided for @bestPrice.
  ///
  /// In en, this message translates to:
  /// **'Best Price'**
  String get bestPrice;

  /// No description provided for @blockedShots.
  ///
  /// In en, this message translates to:
  /// **'Blocked Shots'**
  String get blockedShots;

  /// No description provided for @bothTeamsToScore.
  ///
  /// In en, this message translates to:
  /// **'Both Teams To score'**
  String get bothTeamsToScore;

  /// No description provided for @bottomsheetActionCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse the bottom sheet'**
  String get bottomsheetActionCollapse;

  /// No description provided for @bottomsheetActionExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand the bottom sheet'**
  String get bottomsheetActionExpand;

  /// No description provided for @bottomsheetActionExpandHalfway.
  ///
  /// In en, this message translates to:
  /// **'Expand halfway'**
  String get bottomsheetActionExpandHalfway;

  /// No description provided for @bottomsheetDragHandleContentDescription.
  ///
  /// In en, this message translates to:
  /// **'Drag handle'**
  String get bottomsheetDragHandleContentDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cheerForYourSideWillTheyConquerCrumbleOrHoldTheLine.
  ///
  /// In en, this message translates to:
  /// **'Cheer for your side — will they conquer, crumble, or hold the line?'**
  String get cheerForYourSideWillTheyConquerCrumbleOrHoldTheLine;

  /// No description provided for @chooseYourLeague.
  ///
  /// In en, this message translates to:
  /// **'Choose your league'**
  String get chooseYourLeague;

  /// No description provided for @chooseYourLeagues.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Leagues'**
  String get chooseYourLeagues;

  /// No description provided for @chooseYourPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Preferred Language'**
  String get chooseYourPreferredLanguage;

  /// No description provided for @chooseYourTeam.
  ///
  /// In en, this message translates to:
  /// **'Choose your team'**
  String get chooseYourTeam;

  /// No description provided for @chooseYourTeams.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Teams'**
  String get chooseYourTeams;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @closeDrawer.
  ///
  /// In en, this message translates to:
  /// **'Close navigation menu'**
  String get closeDrawer;

  /// No description provided for @closeSheet.
  ///
  /// In en, this message translates to:
  /// **'Close sheet'**
  String get closeSheet;

  /// No description provided for @club.
  ///
  /// In en, this message translates to:
  /// **'Club:'**
  String get club;

  /// No description provided for @confidenceFormat.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%% Confidence'**
  String confidenceFormat(int arg1);

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @cornerPredictions.
  ///
  /// In en, this message translates to:
  /// **'Corner Predictions'**
  String get cornerPredictions;

  /// No description provided for @dateFormatDay.
  ///
  /// In en, this message translates to:
  /// **'EEE'**
  String get dateFormatDay;

  /// No description provided for @dateFormatValue.
  ///
  /// In en, this message translates to:
  /// **'MMM d'**
  String get dateFormatValue;

  /// No description provided for @defaultAwayTeam.
  ///
  /// In en, this message translates to:
  /// **'Team Away'**
  String get defaultAwayTeam;

  /// No description provided for @defaultHomeTeam.
  ///
  /// In en, this message translates to:
  /// **'Team Home'**
  String get defaultHomeTeam;

  /// No description provided for @defaultLeague.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get defaultLeague;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @drawText.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get drawText;

  /// No description provided for @eliminateFullScreenInterstitialAds.
  ///
  /// In en, this message translates to:
  /// **'Eliminate full-screen interstitial ads'**
  String get eliminateFullScreenInterstitialAds;

  /// No description provided for @endOfFirstHalf.
  ///
  /// In en, this message translates to:
  /// **'End of first half'**
  String get endOfFirstHalf;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @favoriteLeagues.
  ///
  /// In en, this message translates to:
  /// **'Favorite Leagues'**
  String get favoriteLeagues;

  /// No description provided for @favoriteTeams.
  ///
  /// In en, this message translates to:
  /// **'Favorite Teams'**
  String get favoriteTeams;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @firstGoalPredictions.
  ///
  /// In en, this message translates to:
  /// **'First Goal Predictions'**
  String get firstGoalPredictions;

  /// No description provided for @fixture.
  ///
  /// In en, this message translates to:
  /// **'Fixture #{arg1} - {arg2}'**
  String fixture(int arg1, String arg2);

  /// No description provided for @fixtures.
  ///
  /// In en, this message translates to:
  /// **'Fixtures'**
  String get fixtures;

  /// No description provided for @followFavoriteTeams.
  ///
  /// In en, this message translates to:
  /// **'Follow Favorite Teams'**
  String get followFavoriteTeams;

  /// No description provided for @followersCount.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Người theo dõi'**
  String followersCount(String arg1);

  /// No description provided for @fouls.
  ///
  /// In en, this message translates to:
  /// **'Fouls'**
  String get fouls;

  /// No description provided for @fromTheBelowLanguagesPleaseChooseYourNativeLanguageLaterYouCanChangeLanguageFromSettings.
  ///
  /// In en, this message translates to:
  /// **'From the below languages, please choose your native language. Later you can change language from settings.'**
  String
  get fromTheBelowLanguagesPleaseChooseYourNativeLanguageLaterYouCanChangeLanguageFromSettings;

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full time'**
  String get fullTime;

  /// No description provided for @getReadyMatchStartsSoon.
  ///
  /// In en, this message translates to:
  /// **'�� Get Ready! Match starts soon'**
  String get getReadyMatchStartsSoon;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @goProVersion.
  ///
  /// In en, this message translates to:
  /// **'GO PRO VERSION'**
  String get goProVersion;

  /// No description provided for @goToSetting.
  ///
  /// In en, this message translates to:
  /// **'Go to setting'**
  String get goToSetting;

  /// No description provided for @goallessAtTheBreakSeeMatchStats.
  ///
  /// In en, this message translates to:
  /// **'Goalless at the break. See match stats.'**
  String get goallessAtTheBreakSeeMatchStats;

  /// No description provided for @goalsInTheFirstHalf.
  ///
  /// In en, this message translates to:
  /// **'Goals in the first half.'**
  String get goalsInTheFirstHalf;

  /// No description provided for @h2h.
  ///
  /// In en, this message translates to:
  /// **'H2H'**
  String get h2h;

  /// No description provided for @halftimeScore.
  ///
  /// In en, this message translates to:
  /// **'Halftime score'**
  String get halftimeScore;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height:'**
  String get height;

  /// No description provided for @highlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get highlight;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @homeText.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeText;

  /// No description provided for @homeWin.
  ///
  /// In en, this message translates to:
  /// **'Home Win'**
  String get homeWin;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'{arg1} hour{arg2}'**
  String hour(int arg1, String arg2);

  /// No description provided for @hourMins.
  ///
  /// In en, this message translates to:
  /// **'{arg1} hour{arg2} {arg3} mins'**
  String hourMins(int arg1, String arg2, int arg3);

  /// No description provided for @ht.
  ///
  /// In en, this message translates to:
  /// **'⏸️ HT: {arg1} {arg2} - {arg3} {arg4}'**
  String ht(String arg1, int arg2, int arg3, String arg4);

  /// No description provided for @inDepthAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'In-depth AI analysis'**
  String get inDepthAiAnalysis;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @indeterminate.
  ///
  /// In en, this message translates to:
  /// **'Partially checked'**
  String get indeterminate;

  /// No description provided for @infoAwayManager.
  ///
  /// In en, this message translates to:
  /// **'Away Manager'**
  String get infoAwayManager;

  /// No description provided for @infoChairman.
  ///
  /// In en, this message translates to:
  /// **'Chủ tịch hiện tại'**
  String get infoChairman;

  /// No description provided for @infoChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get infoChannel;

  /// No description provided for @infoCompetitorsCount.
  ///
  /// In en, this message translates to:
  /// **'Số lượng võ sĩ'**
  String get infoCompetitorsCount;

  /// No description provided for @infoCountry.
  ///
  /// In en, this message translates to:
  /// **'Quốc gia'**
  String get infoCountry;

  /// No description provided for @infoHomeManager.
  ///
  /// In en, this message translates to:
  /// **'Home Manager'**
  String get infoHomeManager;

  /// No description provided for @infoLeague.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get infoLeague;

  /// No description provided for @infoOwner.
  ///
  /// In en, this message translates to:
  /// **'Chủ sở hữu'**
  String get infoOwner;

  /// No description provided for @infoReferee.
  ///
  /// In en, this message translates to:
  /// **'Referee'**
  String get infoReferee;

  /// No description provided for @infoRound.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get infoRound;

  /// No description provided for @infoTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get infoTime;

  /// No description provided for @infoVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get infoVenue;

  /// No description provided for @infoWeightDivisions.
  ///
  /// In en, this message translates to:
  /// **'Hạng cân'**
  String get infoWeightDivisions;

  /// No description provided for @infoYearFoundation.
  ///
  /// In en, this message translates to:
  /// **'Thành lập'**
  String get infoYearFoundation;

  /// No description provided for @infor.
  ///
  /// In en, this message translates to:
  /// **'Infor'**
  String get infor;

  /// No description provided for @internationalTournaments.
  ///
  /// In en, this message translates to:
  /// **'International Tournaments'**
  String get internationalTournaments;

  /// No description provided for @introTitle1.
  ///
  /// In en, this message translates to:
  /// **'Live scores, video highlights, and breaking news.'**
  String get introTitle1;

  /// No description provided for @introTitle2.
  ///
  /// In en, this message translates to:
  /// **'Get live alerts for goals, cards, and kick-offs'**
  String get introTitle2;

  /// No description provided for @kickOff.
  ///
  /// In en, this message translates to:
  /// **'�� Kick-off!'**
  String get kickOff;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageScreenNotReachable.
  ///
  /// In en, this message translates to:
  /// **'Language screen not reachable from here'**
  String get languageScreenNotReachable;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @last5Games.
  ///
  /// In en, this message translates to:
  /// **'Last 5 games'**
  String get last5Games;

  /// No description provided for @league.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get league;

  /// No description provided for @leagues.
  ///
  /// In en, this message translates to:
  /// **'Leagues'**
  String get leagues;

  /// No description provided for @lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// No description provided for @lineup.
  ///
  /// In en, this message translates to:
  /// **'Lineup'**
  String get lineup;

  /// No description provided for @lineupsTitle.
  ///
  /// In en, this message translates to:
  /// **'MATCH LINEUPS'**
  String get lineupsTitle;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @liveMatches.
  ///
  /// In en, this message translates to:
  /// **'LIVE MATCHES'**
  String get liveMatches;

  /// No description provided for @liveS.
  ///
  /// In en, this message translates to:
  /// **'Lives'**
  String get liveS;

  /// No description provided for @liveScore.
  ///
  /// In en, this message translates to:
  /// **'LIVE SCORE'**
  String get liveScore;

  /// No description provided for @lives.
  ///
  /// In en, this message translates to:
  /// **'lives'**
  String get lives;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingRewardAd.
  ///
  /// In en, this message translates to:
  /// **'Loading reward ad'**
  String get loadingRewardAd;

  /// No description provided for @loadingRewardAdMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we prepare your reward.'**
  String get loadingRewardAdMessage;

  /// No description provided for @looksLikeYouHavenTAddedAnythingYet.
  ///
  /// In en, this message translates to:
  /// **'Looks like you haven’t added anything yet.'**
  String get looksLikeYouHavenTAddedAnythingYet;

  /// No description provided for @makeSureToTurnOnTheInternetToUseFeatures.
  ///
  /// In en, this message translates to:
  /// **'Make sure to turn on the internet to use features'**
  String get makeSureToTurnOnTheInternetToUseFeatures;

  /// No description provided for @matchAlarmBeforeMatch.
  ///
  /// In en, this message translates to:
  /// **'Match Alarm (Before Match)'**
  String get matchAlarmBeforeMatch;

  /// No description provided for @matchHighlights.
  ///
  /// In en, this message translates to:
  /// **'Match Highlights'**
  String get matchHighlights;

  /// No description provided for @matchInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'MATCH INFORMATION'**
  String get matchInfoTitle;

  /// No description provided for @matchPrediction.
  ///
  /// In en, this message translates to:
  /// **'Match Prediction'**
  String get matchPrediction;

  /// No description provided for @matchResultPredictions.
  ///
  /// In en, this message translates to:
  /// **'Match Result Predictions'**
  String get matchResultPredictions;

  /// No description provided for @matchScore.
  ///
  /// In en, this message translates to:
  /// **'Match score'**
  String get matchScore;

  /// No description provided for @matchScorePredictions.
  ///
  /// In en, this message translates to:
  /// **'Match Score Predictions'**
  String get matchScorePredictions;

  /// No description provided for @matchStart.
  ///
  /// In en, this message translates to:
  /// **'Match start'**
  String get matchStart;

  /// No description provided for @matchTimeline.
  ///
  /// In en, this message translates to:
  /// **'Match timeline'**
  String get matchTimeline;

  /// No description provided for @matchUpdate.
  ///
  /// In en, this message translates to:
  /// **'Match update'**
  String get matchUpdate;

  /// No description provided for @nationalLeagues.
  ///
  /// In en, this message translates to:
  /// **'National Leagues'**
  String get nationalLeagues;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality:'**
  String get nationality;

  /// No description provided for @nativeBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get nativeBody;

  /// No description provided for @nativeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Headline'**
  String get nativeHeadline;

  /// No description provided for @nativeMediaView.
  ///
  /// In en, this message translates to:
  /// **'Media View'**
  String get nativeMediaView;

  /// No description provided for @navRailCollapsedA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Collapsed'**
  String get navRailCollapsedA11yLabel;

  /// No description provided for @navRailExpandedA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Expanded'**
  String get navRailExpandedA11yLabel;

  /// No description provided for @navigationMenu.
  ///
  /// In en, this message translates to:
  /// **'Navigation menu'**
  String get navigationMenu;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noComparisonDataAvailableForThisMatchMakeYourPredictionBeforeTheMatchEndsToSeeResultsNextTime.
  ///
  /// In en, this message translates to:
  /// **'No comparison data available for this match. Make your prediction before the match ends to see results next time.'**
  String
  get noComparisonDataAvailableForThisMatchMakeYourPredictionBeforeTheMatchEndsToSeeResultsNextTime;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noFavoriteLeague.
  ///
  /// In en, this message translates to:
  /// **'No favorite League.'**
  String get noFavoriteLeague;

  /// No description provided for @noFavoriteTeam.
  ///
  /// In en, this message translates to:
  /// **'No favorite Team.'**
  String get noFavoriteTeam;

  /// No description provided for @noGoal.
  ///
  /// In en, this message translates to:
  /// **'No Goal'**
  String get noGoal;

  /// No description provided for @noGoalsScored.
  ///
  /// In en, this message translates to:
  /// **'No goals scored'**
  String get noGoalsScored;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet'**
  String get noInternet;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @noPredictionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Prediction Available'**
  String get noPredictionAvailable;

  /// No description provided for @noRecentMatches.
  ///
  /// In en, this message translates to:
  /// **'No recent matches'**
  String get noRecentMatches;

  /// No description provided for @noSubstitutionsYet.
  ///
  /// In en, this message translates to:
  /// **'No substitutions yet'**
  String get noSubstitutionsYet;

  /// No description provided for @noText.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noText;

  /// No description provided for @noUpcomingMatches.
  ///
  /// In en, this message translates to:
  /// **'No upcoming matches'**
  String get noUpcomingMatches;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @notificationChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications for upcoming football matches'**
  String get notificationChannelDesc;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Match Notifications'**
  String get notificationChannelName;

  /// No description provided for @notificationFailedMaybeTooManyPendingNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification FAILED (maybe too many pending notification)'**
  String get notificationFailedMaybeTooManyPendingNotification;

  /// No description provided for @notificationMatchReminder.
  ///
  /// In en, this message translates to:
  /// **'Match Reminder'**
  String get notificationMatchReminder;

  /// No description provided for @notificationMatchStarting.
  ///
  /// In en, this message translates to:
  /// **'{arg1} vs {arg2} is starting NOW in {arg3}!'**
  String notificationMatchStarting(String arg1, String arg2, String arg3);

  /// No description provided for @notificationMatchStartingIn.
  ///
  /// In en, this message translates to:
  /// **'{arg1} vs {arg2} starts in {arg3} minutes ({arg4})'**
  String notificationMatchStartingIn(
    String arg1,
    String arg2,
    int arg3,
    String arg4,
  );

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to set alerts.'**
  String get notificationPermissionDenied;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsAccess.
  ///
  /// In en, this message translates to:
  /// **'Notifications Access'**
  String get notificationsAccess;

  /// No description provided for @notificationsAreBeingSynchronized.
  ///
  /// In en, this message translates to:
  /// **'Notifications are being synchronized....'**
  String get notificationsAreBeingSynchronized;

  /// No description provided for @notificationsPermissionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get notificationsPermissionConfirm;

  /// No description provided for @notificationsPermissionDecline.
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow'**
  String get notificationsPermissionDecline;

  /// No description provided for @notificationsPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow app to send you notifications?'**
  String get notificationsPermissionTitle;

  /// No description provided for @ob1Des.
  ///
  /// In en, this message translates to:
  /// **'Get real-time updates from\nall major leagues\nand tournaments around the\nworld'**
  String get ob1Des;

  /// No description provided for @ob1Title.
  ///
  /// In en, this message translates to:
  /// **'Live Soccer'**
  String get ob1Title;

  /// No description provided for @ob3Title.
  ///
  /// In en, this message translates to:
  /// **'Never Miss a Moment'**
  String get ob3Title;

  /// No description provided for @offlineDialogImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get offlineDialogImageDescription;

  /// No description provided for @offlineDialogText.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your interest.\nWe will share more once you\'re back online.'**
  String get offlineDialogText;

  /// No description provided for @offlineOptInConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get offlineOptInConfirm;

  /// No description provided for @offlineOptInDecline.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get offlineOptInDecline;

  /// No description provided for @offlineOptInMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a notification with a link to the advertiser site.'**
  String get offlineOptInMessage;

  /// No description provided for @offlineOptInTitle.
  ///
  /// In en, this message translates to:
  /// **'Open ad when you\'re back online.'**
  String get offlineOptInTitle;

  /// No description provided for @offsides.
  ///
  /// In en, this message translates to:
  /// **'Offsides'**
  String get offsides;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @only.
  ///
  /// In en, this message translates to:
  /// **'Only'**
  String get only;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position:'**
  String get position;

  /// No description provided for @possession.
  ///
  /// In en, this message translates to:
  /// **'Possession (%)'**
  String get possession;

  /// No description provided for @prediction.
  ///
  /// In en, this message translates to:
  /// **'Prediction'**
  String get prediction;

  /// No description provided for @predictionWhoWillWin.
  ///
  /// In en, this message translates to:
  /// **'PREDICTION WINNER'**
  String get predictionWhoWillWin;

  /// No description provided for @preferFoot.
  ///
  /// In en, this message translates to:
  /// **'Prefer foot:'**
  String get preferFoot;

  /// No description provided for @premiumAdFreeUpgrade.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM AD-FREE UPGRADE'**
  String get premiumAdFreeUpgrade;

  /// No description provided for @premiumBannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock full feature, No ads & More'**
  String get premiumBannerDesc;

  /// No description provided for @premiumBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumBannerTitle;

  /// No description provided for @premiumBuy.
  ///
  /// In en, this message translates to:
  /// **'BUY NOW - {arg1}'**
  String premiumBuy(String arg1);

  /// No description provided for @premiumClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get premiumClose;

  /// No description provided for @premiumFeatureFaster.
  ///
  /// In en, this message translates to:
  /// **'Faster, lighter app'**
  String get premiumFeatureFaster;

  /// No description provided for @premiumFeatureLive.
  ///
  /// In en, this message translates to:
  /// **'Uninterrupted live match tracking'**
  String get premiumFeatureLive;

  /// No description provided for @premiumFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No banners, no interstitials'**
  String get premiumFeatureNoAds;

  /// No description provided for @premiumFeatureSupport.
  ///
  /// In en, this message translates to:
  /// **'Support future updates'**
  String get premiumFeatureSupport;

  /// No description provided for @premiumGo.
  ///
  /// In en, this message translates to:
  /// **'BUY NOW'**
  String get premiumGo;

  /// No description provided for @premiumNotReady.
  ///
  /// In en, this message translates to:
  /// **'Store is not ready yet. Please try again.'**
  String get premiumNotReady;

  /// No description provided for @premiumNoteOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time payment. No subscription.'**
  String get premiumNoteOneTime;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoy live scores without interruptions'**
  String get premiumSubtitle;

  /// No description provided for @premiumThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Ads are now removed.'**
  String get premiumThanks;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads'**
  String get premiumTitle;

  /// No description provided for @premiumVersion.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM VERSION'**
  String get premiumVersion;

  /// No description provided for @preparingYourMatchNotification.
  ///
  /// In en, this message translates to:
  /// **'Preparing your match notification'**
  String get preparingYourMatchNotification;

  /// No description provided for @priceLaterFormat.
  ///
  /// In en, this message translates to:
  /// **'Later {arg1}/{arg2}'**
  String priceLaterFormat(String arg1, String arg2);

  /// No description provided for @priceLaterLifetime.
  ///
  /// In en, this message translates to:
  /// **'Later {arg1}'**
  String priceLaterLifetime(String arg1);

  /// No description provided for @priceOnlyFormat.
  ///
  /// In en, this message translates to:
  /// **'Only {arg1}/{arg2}'**
  String priceOnlyFormat(String arg1, String arg2);

  /// No description provided for @priceOnlyLifetime.
  ///
  /// In en, this message translates to:
  /// **'Only {arg1}'**
  String priceOnlyLifetime(String arg1);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @rateAppTitleBad.
  ///
  /// In en, this message translates to:
  /// **'Oh no! We\'ll try to do better.'**
  String get rateAppTitleBad;

  /// No description provided for @rateAppTitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Rate our app'**
  String get rateAppTitleDefault;

  /// No description provided for @rateAppTitleGood.
  ///
  /// In en, this message translates to:
  /// **'We\'re glad you like it!'**
  String get rateAppTitleGood;

  /// No description provided for @rateAppTitleMid.
  ///
  /// In en, this message translates to:
  /// **'We\'re working hard to improve!'**
  String get rateAppTitleMid;

  /// No description provided for @rateOnGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Rate on Google Play'**
  String get rateOnGooglePlay;

  /// No description provided for @ratePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please rate us to enhance your experience. Thank you!'**
  String get ratePlaceholder;

  /// No description provided for @rateStars.
  ///
  /// In en, this message translates to:
  /// **'Rate stars:'**
  String get rateStars;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get rateUs;

  /// No description provided for @redCardInTheFirstHalf.
  ///
  /// In en, this message translates to:
  /// **'�� Red card in the first half.'**
  String get redCardInTheFirstHalf;

  /// No description provided for @redCards.
  ///
  /// In en, this message translates to:
  /// **'Red Cards'**
  String get redCards;

  /// No description provided for @removeAllAds.
  ///
  /// In en, this message translates to:
  /// **'Remove All Ads'**
  String get removeAllAds;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @rewardAdNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Reward ad not available'**
  String get rewardAdNotAvailable;

  /// No description provided for @rewardAdNotAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The reward ad could not be loaded. Please try again.'**
  String get rewardAdNotAvailableMessage;

  /// No description provided for @roundFormat.
  ///
  /// In en, this message translates to:
  /// **'Round {arg1}'**
  String roundFormat(int arg1);

  /// No description provided for @sConfidence.
  ///
  /// In en, this message translates to:
  /// **'{arg1} confidence'**
  String sConfidence(String arg1);

  /// No description provided for @sCorrectPredictions.
  ///
  /// In en, this message translates to:
  /// **'{arg1} correct predictions'**
  String sCorrectPredictions(String arg1);

  /// No description provided for @sGoal.
  ///
  /// In en, this message translates to:
  /// **'{arg1} goal'**
  String sGoal(String arg1);

  /// No description provided for @sSaleOff.
  ///
  /// In en, this message translates to:
  /// **'{arg1}\nOff'**
  String sSaleOff(String arg1);

  /// No description provided for @scoreS1S2.
  ///
  /// In en, this message translates to:
  /// **'Score ({arg1}1 - {arg2}2)'**
  String scoreS1S2(String arg1, String arg2);

  /// No description provided for @searchHintPick.
  ///
  /// In en, this message translates to:
  /// **'Search for leagues or teams...'**
  String get searchHintPick;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get searchHistory;

  /// No description provided for @searchLeague.
  ///
  /// In en, this message translates to:
  /// **'Search league'**
  String get searchLeague;

  /// No description provided for @searchTeam.
  ///
  /// In en, this message translates to:
  /// **'Search team'**
  String get searchTeam;

  /// No description provided for @searchTeamOrLeague.
  ///
  /// In en, this message translates to:
  /// **'Search team or league'**
  String get searchTeamOrLeague;

  /// No description provided for @searchbarScrollingViewBehavior.
  ///
  /// In en, this message translates to:
  /// **'com.google.android.material.search.SearchBar\$ScrollingViewBehavior'**
  String get searchbarScrollingViewBehavior;

  /// No description provided for @secondHalfIsUnderway.
  ///
  /// In en, this message translates to:
  /// **'Second half is underway. {arg1} {arg2} - {arg3} {arg4}.'**
  String secondHalfIsUnderway(String arg1, int arg2, int arg3, String arg4);

  /// No description provided for @secondHalfStarted.
  ///
  /// In en, this message translates to:
  /// **'▶️ Second Half Started'**
  String get secondHalfStarted;

  /// No description provided for @sectionFeatured.
  ///
  /// In en, this message translates to:
  /// **'Tiêu biểu'**
  String get sectionFeatured;

  /// No description provided for @sectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Thông tin'**
  String get sectionInfo;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @selectLeaguesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the leagues you want to follow closely.'**
  String get selectLeaguesSubtitle;

  /// No description provided for @selectTeamsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your favorite teams to get instant alerts.'**
  String get selectTeamsSubtitle;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @sentOff.
  ///
  /// In en, this message translates to:
  /// **'�� {arg1} sent off ({arg2}\')'**
  String sentOff(String arg1, int arg2);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareAppText.
  ///
  /// In en, this message translates to:
  /// **'Check out this amazing football app: https://play.google.com/store/apps/details?id={arg1}'**
  String shareAppText(String arg1);

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareVia;

  /// No description provided for @shirt.
  ///
  /// In en, this message translates to:
  /// **'Shirt:'**
  String get shirt;

  /// No description provided for @shotsOffTarget.
  ///
  /// In en, this message translates to:
  /// **'Shots off Target'**
  String get shotsOffTarget;

  /// No description provided for @shotsOnTarget.
  ///
  /// In en, this message translates to:
  /// **'Shots on Target'**
  String get shotsOnTarget;

  /// No description provided for @showAllPicks.
  ///
  /// In en, this message translates to:
  /// **'Show all picks'**
  String get showAllPicks;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @sportAmericanFootball.
  ///
  /// In en, this message translates to:
  /// **'American Football'**
  String get sportAmericanFootball;

  /// No description provided for @sportAussieRules.
  ///
  /// In en, this message translates to:
  /// **'Aussie Rules'**
  String get sportAussieRules;

  /// No description provided for @sportBadminton.
  ///
  /// In en, this message translates to:
  /// **'Badminton'**
  String get sportBadminton;

  /// No description provided for @sportBandy.
  ///
  /// In en, this message translates to:
  /// **'Bandy'**
  String get sportBandy;

  /// No description provided for @sportBaseball.
  ///
  /// In en, this message translates to:
  /// **'Baseball'**
  String get sportBaseball;

  /// No description provided for @sportBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get sportBasketball;

  /// No description provided for @sportBoxing.
  ///
  /// In en, this message translates to:
  /// **'Boxing'**
  String get sportBoxing;

  /// No description provided for @sportCricket.
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get sportCricket;

  /// No description provided for @sportCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get sportCycling;

  /// No description provided for @sportDarts.
  ///
  /// In en, this message translates to:
  /// **'Darts'**
  String get sportDarts;

  /// No description provided for @sportEsports.
  ///
  /// In en, this message translates to:
  /// **'eSports'**
  String get sportEsports;

  /// No description provided for @sportFloorball.
  ///
  /// In en, this message translates to:
  /// **'Floorball'**
  String get sportFloorball;

  /// No description provided for @sportFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get sportFootball;

  /// No description provided for @sportFutsal.
  ///
  /// In en, this message translates to:
  /// **'Futsal'**
  String get sportFutsal;

  /// No description provided for @sportHandball.
  ///
  /// In en, this message translates to:
  /// **'Handball'**
  String get sportHandball;

  /// No description provided for @sportIceHockey.
  ///
  /// In en, this message translates to:
  /// **'Ice Hockey'**
  String get sportIceHockey;

  /// No description provided for @sportMma.
  ///
  /// In en, this message translates to:
  /// **'MMA'**
  String get sportMma;

  /// No description provided for @sportMotorsport.
  ///
  /// In en, this message translates to:
  /// **'Motorsport'**
  String get sportMotorsport;

  /// No description provided for @sportPickerAll.
  ///
  /// In en, this message translates to:
  /// **'ALL SPORTS'**
  String get sportPickerAll;

  /// No description provided for @sportPickerRecent.
  ///
  /// In en, this message translates to:
  /// **'RECENT'**
  String get sportPickerRecent;

  /// No description provided for @sportPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find sports'**
  String get sportPickerSearchHint;

  /// No description provided for @sportRugby.
  ///
  /// In en, this message translates to:
  /// **'Rugby'**
  String get sportRugby;

  /// No description provided for @sportSnooker.
  ///
  /// In en, this message translates to:
  /// **'Snooker'**
  String get sportSnooker;

  /// No description provided for @sportTableTennis.
  ///
  /// In en, this message translates to:
  /// **'Table Tennis'**
  String get sportTableTennis;

  /// No description provided for @sportTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get sportTennis;

  /// No description provided for @sportVolleyball.
  ///
  /// In en, this message translates to:
  /// **'Volleyball'**
  String get sportVolleyball;

  /// No description provided for @sportWaterpolo.
  ///
  /// In en, this message translates to:
  /// **'Water Polo'**
  String get sportWaterpolo;

  /// No description provided for @squad.
  ///
  /// In en, this message translates to:
  /// **'Squad'**
  String get squad;

  /// No description provided for @startOfSecondHalf.
  ///
  /// In en, this message translates to:
  /// **'Start of second half'**
  String get startOfSecondHalf;

  /// No description provided for @stateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get stateEmpty;

  /// No description provided for @stateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get stateOff;

  /// No description provided for @stateOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get stateOn;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @statusAet.
  ///
  /// In en, this message translates to:
  /// **'AET'**
  String get statusAet;

  /// No description provided for @statusCancl.
  ///
  /// In en, this message translates to:
  /// **'CANCL'**
  String get statusCancl;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @statusFt.
  ///
  /// In en, this message translates to:
  /// **'FT'**
  String get statusFt;

  /// No description provided for @statusHt.
  ///
  /// In en, this message translates to:
  /// **'HT'**
  String get statusHt;

  /// No description provided for @statusLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get statusLive;

  /// No description provided for @statusMainCard.
  ///
  /// In en, this message translates to:
  /// **'Trận chính thức'**
  String get statusMainCard;

  /// No description provided for @statusNs.
  ///
  /// In en, this message translates to:
  /// **'NS'**
  String get statusNs;

  /// No description provided for @statusPen.
  ///
  /// In en, this message translates to:
  /// **'PEN'**
  String get statusPen;

  /// No description provided for @statusPostp.
  ///
  /// In en, this message translates to:
  /// **'POSTP'**
  String get statusPostp;

  /// No description provided for @statusTbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get statusTbd;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @substitutions.
  ///
  /// In en, this message translates to:
  /// **'Substitutions'**
  String get substitutions;

  /// No description provided for @subtabFinished.
  ///
  /// In en, this message translates to:
  /// **'Kết thúc'**
  String get subtabFinished;

  /// No description provided for @subtabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Sắp tới'**
  String get subtabUpcoming;

  /// No description provided for @svipMemberEnjoysManyPrivileges.
  ///
  /// In en, this message translates to:
  /// **'SVIP Member enjoys many privileges'**
  String get svipMemberEnjoysManyPrivileges;

  /// No description provided for @switchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchRole;

  /// No description provided for @tab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get tab;

  /// No description provided for @tabDetails.
  ///
  /// In en, this message translates to:
  /// **'Chi Tiết'**
  String get tabDetails;

  /// No description provided for @tabEvents.
  ///
  /// In en, this message translates to:
  /// **'Các sự kiện'**
  String get tabEvents;

  /// No description provided for @tabH2h.
  ///
  /// In en, this message translates to:
  /// **'H2H'**
  String get tabH2h;

  /// No description provided for @tabInfo.
  ///
  /// In en, this message translates to:
  /// **'INFO'**
  String get tabInfo;

  /// No description provided for @tabLineups.
  ///
  /// In en, this message translates to:
  /// **'LINEUPS'**
  String get tabLineups;

  /// No description provided for @tabOdds.
  ///
  /// In en, this message translates to:
  /// **'ODDS'**
  String get tabOdds;

  /// No description provided for @tabStandings.
  ///
  /// In en, this message translates to:
  /// **'STANDINGS'**
  String get tabStandings;

  /// No description provided for @tabStatistics.
  ///
  /// In en, this message translates to:
  /// **'STATISTICS'**
  String get tabStatistics;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @tableMatchesPlayed.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get tableMatchesPlayed;

  /// No description provided for @tablePoints.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get tablePoints;

  /// No description provided for @tableTeamHeader.
  ///
  /// In en, this message translates to:
  /// **'# Team'**
  String get tableTeamHeader;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @templatePercent.
  ///
  /// In en, this message translates to:
  /// **'{arg1} percent.'**
  String templatePercent(int arg1);

  /// No description provided for @termOfService.
  ///
  /// In en, this message translates to:
  /// **'Term of Service'**
  String get termOfService;

  /// No description provided for @textRate1.
  ///
  /// In en, this message translates to:
  /// **'Please rate us to enhance your experience. Thank you!'**
  String get textRate1;

  /// No description provided for @textRate2.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback.'**
  String get textRate2;

  /// No description provided for @textRate3.
  ///
  /// In en, this message translates to:
  /// **'We\'ll improve your experience'**
  String get textRate3;

  /// No description provided for @textRate4.
  ///
  /// In en, this message translates to:
  /// **'We\'re committed to making it even better.'**
  String get textRate4;

  /// No description provided for @textRate5.
  ///
  /// In en, this message translates to:
  /// **'We\'re delighted that you enjoy using our app'**
  String get textRate5;

  /// No description provided for @textRate6.
  ///
  /// In en, this message translates to:
  /// **'We are thrilled to hear that you love our app.'**
  String get textRate6;

  /// No description provided for @thanksForRating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thanksForRating;

  /// No description provided for @theAnalysesBelowAreForReferencePurposesOnly.
  ///
  /// In en, this message translates to:
  /// **'The analyses below are for reference purposes only.'**
  String get theAnalysesBelowAreForReferencePurposesOnly;

  /// No description provided for @theBest.
  ///
  /// In en, this message translates to:
  /// **'The best we can get :”>'**
  String get theBest;

  /// No description provided for @theBestWeCanGet.
  ///
  /// In en, this message translates to:
  /// **'The best we can get :)'**
  String get theBestWeCanGet;

  /// No description provided for @theFieldIsQuiet.
  ///
  /// In en, this message translates to:
  /// **'The field is quiet'**
  String get theFieldIsQuiet;

  /// No description provided for @theFieldIsQuiteEmpty.
  ///
  /// In en, this message translates to:
  /// **'The field is quite empty.'**
  String get theFieldIsQuiteEmpty;

  /// No description provided for @theMatchBetweenAndKicksOffIn.
  ///
  /// In en, this message translates to:
  /// **'The match between {arg1} and {arg2} kicks off in {arg3}.'**
  String theMatchBetweenAndKicksOffIn(String arg1, String arg2, String arg3);

  /// No description provided for @theMatchHasEndedPredictionsAreOnlyAvailableForUpcomingOrLiveMatches.
  ///
  /// In en, this message translates to:
  /// **'The match has ended. Predictions are only available for upcoming or live matches.'**
  String
  get theMatchHasEndedPredictionsAreOnlyAvailableForUpcomingOrLiveMatches;

  /// No description provided for @thereIsNoInternetConnectionPleaseCheckYourInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'There is no internet connection! Please check your internet connection!'**
  String get thereIsNoInternetConnectionPleaseCheckYourInternetConnection;

  /// No description provided for @thisActionMayContainAds.
  ///
  /// In en, this message translates to:
  /// **'This action may contain ads'**
  String get thisActionMayContainAds;

  /// No description provided for @thisActionMayContainAdvertising.
  ///
  /// In en, this message translates to:
  /// **'This action may contain advertising'**
  String get thisActionMayContainAdvertising;

  /// No description provided for @throwIns.
  ///
  /// In en, this message translates to:
  /// **'Throw-ins'**
  String get throwIns;

  /// No description provided for @timeLine.
  ///
  /// In en, this message translates to:
  /// **'Time line: {arg1}’'**
  String timeLine(int arg1);

  /// No description provided for @titleEsportsGames.
  ///
  /// In en, this message translates to:
  /// **'ESPORTS GAMES / MAPS'**
  String get titleEsportsGames;

  /// No description provided for @titleLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get titleLifetime;

  /// No description provided for @titleMatchIncidents.
  ///
  /// In en, this message translates to:
  /// **'MATCH EVENTS'**
  String get titleMatchIncidents;

  /// No description provided for @titleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get titleMonthly;

  /// No description provided for @titleMonthlyTrial.
  ///
  /// In en, this message translates to:
  /// **'Monthly - CTA = START FREE TRIAL'**
  String get titleMonthlyTrial;

  /// No description provided for @titlePeriodScores.
  ///
  /// In en, this message translates to:
  /// **'PERIOD / SET SCORES'**
  String get titlePeriodScores;

  /// No description provided for @titlePointByPoint.
  ///
  /// In en, this message translates to:
  /// **'POINT BY POINT'**
  String get titlePointByPoint;

  /// No description provided for @titleTvChannels.
  ///
  /// In en, this message translates to:
  /// **'BROADCAST CHANNELS'**
  String get titleTvChannels;

  /// No description provided for @titleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get titleWeekly;

  /// No description provided for @titleWeeklyTrial.
  ///
  /// In en, this message translates to:
  /// **'Weekly - CTA = START FREE TRIAL'**
  String get titleWeeklyTrial;

  /// No description provided for @titleYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get titleYearly;

  /// No description provided for @titleYearlyTrial.
  ///
  /// In en, this message translates to:
  /// **'Yearly - CTA = START FREE TRIAL'**
  String get titleYearlyTrial;

  /// No description provided for @toastNotificationOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get toastNotificationOff;

  /// No description provided for @toastNotificationOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get toastNotificationOn;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @tooltipDescription.
  ///
  /// In en, this message translates to:
  /// **'tooltip'**
  String get tooltipDescription;

  /// No description provided for @tooltipLabel.
  ///
  /// In en, this message translates to:
  /// **'show tooltip'**
  String get tooltipLabel;

  /// No description provided for @topLeague.
  ///
  /// In en, this message translates to:
  /// **'Top league'**
  String get topLeague;

  /// No description provided for @topTeam.
  ///
  /// In en, this message translates to:
  /// **'Top teams'**
  String get topTeam;

  /// No description provided for @totalGoals.
  ///
  /// In en, this message translates to:
  /// **'Total goals'**
  String get totalGoals;

  /// No description provided for @totalGoalsPredictions.
  ///
  /// In en, this message translates to:
  /// **'Total Goals Predictions'**
  String get totalGoalsPredictions;

  /// No description provided for @totalVotesFormat.
  ///
  /// In en, this message translates to:
  /// **'{arg1} total votes'**
  String totalVotesFormat(int arg1);

  /// No description provided for @turnOffNotifications.
  ///
  /// In en, this message translates to:
  /// **'Turn off notifications?'**
  String get turnOffNotifications;

  /// No description provided for @unitMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get unitMonth;

  /// No description provided for @unitWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get unitWeek;

  /// No description provided for @unitYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get unitYear;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unlimitedAccessToAllFeature.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access to all feature'**
  String get unlimitedAccessToAllFeature;

  /// No description provided for @unlockDrawPrediction.
  ///
  /// In en, this message translates to:
  /// **'Unlock Draw Prediction'**
  String get unlockDrawPrediction;

  /// No description provided for @unlockForecast.
  ///
  /// In en, this message translates to:
  /// **'Unlock Forecast'**
  String get unlockForecast;

  /// No description provided for @unlockMatchHighlights.
  ///
  /// In en, this message translates to:
  /// **'Unlock match highlights'**
  String get unlockMatchHighlights;

  /// No description provided for @unlocksAllFutureAdFreeFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlocks all future ad-free features'**
  String get unlocksAllFutureAdFreeFeatures;

  /// No description provided for @upComing.
  ///
  /// In en, this message translates to:
  /// **'Up coming'**
  String get upComing;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'The Match is updating...'**
  String get updating;

  /// No description provided for @updatingMatchInfo.
  ///
  /// In en, this message translates to:
  /// **'Updating match info…'**
  String get updatingMatchInfo;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @upgradeForUnlimitedAccessNoAds.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE FOR UNLIMITED ACCESS & NO ADS'**
  String get upgradeForUnlimitedAccessNoAds;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewDetailsMatch.
  ///
  /// In en, this message translates to:
  /// **'View details match.'**
  String get viewDetailsMatch;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @vsHasStartedFollowTheMatchLive.
  ///
  /// In en, this message translates to:
  /// **'{arg1} vs {arg2} has started. Follow the match live!'**
  String vsHasStartedFollowTheMatchLive(String arg1, String arg2);

  /// No description provided for @watchAShortAdToSubmitYourDrawPrediction.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to submit your draw prediction.'**
  String get watchAShortAdToSubmitYourDrawPrediction;

  /// No description provided for @watchNow.
  ///
  /// In en, this message translates to:
  /// **'Watch Now'**
  String get watchNow;

  /// No description provided for @watermarkLabelPrefix.
  ///
  /// In en, this message translates to:
  /// **'AdMob -'**
  String get watermarkLabelPrefix;

  /// No description provided for @weReDelightedThatYouEnjoyUsingOurApp.
  ///
  /// In en, this message translates to:
  /// **'We’re delighted that you enjoy using our app'**
  String get weReDelightedThatYouEnjoyUsingOurApp;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight:'**
  String get weight;

  /// No description provided for @whatAHalf.
  ///
  /// In en, this message translates to:
  /// **'�� What a half! {arg1} {arg2} - {arg3} {arg4}'**
  String whatAHalf(String arg1, int arg2, int arg3, String arg4);

  /// No description provided for @whoWillWins.
  ///
  /// In en, this message translates to:
  /// **'Who will wins?'**
  String get whoWillWins;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @yellowCards.
  ///
  /// In en, this message translates to:
  /// **'Yellow Cards'**
  String get yellowCards;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesText.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesText;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @youRePremiumUser.
  ///
  /// In en, this message translates to:
  /// **'You\'re Premium User'**
  String get youRePremiumUser;

  /// No description provided for @youWonTReceiveAnyAlertsOrUpdatesUntilYouTurnThemBackOn.
  ///
  /// In en, this message translates to:
  /// **'You won’t receive any alerts or updates until you turn them back on.'**
  String get youWonTReceiveAnyAlertsOrUpdatesUntilYouTurnThemBackOn;

  /// No description provided for @yourFilesIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your files is empty'**
  String get yourFilesIsEmpty;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @restorePurchasesSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your purchase has been restored.'**
  String get restorePurchasesSuccess;

  /// No description provided for @restorePurchasesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found for this account.'**
  String get restorePurchasesEmpty;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'ko',
    'pt',
    'ru',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return SZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return SAr();
    case 'de':
      return SDe();
    case 'en':
      return SEn();
    case 'es':
      return SEs();
    case 'fr':
      return SFr();
    case 'hi':
      return SHi();
    case 'ja':
      return SJa();
    case 'ko':
      return SKo();
    case 'pt':
      return SPt();
    case 'ru':
      return SRu();
    case 'th':
      return STh();
    case 'vi':
      return SVi();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
