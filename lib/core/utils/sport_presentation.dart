import 'package:flutter/material.dart';

enum HomeEventFamily {
  football,
  tennis,
  basketball,
  cricket,
  baseball,
  mmaFight,
  genericTwoCompetitor,
  stageSeries,
}

enum HomeFeedFamily { normalEvents, mmaFightNights, stageSeries, cyclingSeason }

enum HomeScoreProfile {
  footballScore,
  tennisGameAndSets,
  basketballPeriods,
  cricketInnings,
  baseballInnings,
  volleyballSets,
  racketSets,
  dartsLegsAndSets,
  snookerFrames,
  americanFootballPeriods,
  aussieRulesPeriods,
  iceHockeyPeriods,
  handballPeriods,
  rugbyPeriods,
  waterPoloPeriods,
  futsalPeriods,
  beachSoccerPeriods,
  bandyPeriods,
  floorballPeriods,
  pesapalloInnings,
  kabaddiPeriods,
  esportsMaps,
  mmaFight,
  boxingFight,
  genericCurrentScore,
  stage,
}

enum EventHeaderFamily {
  football,
  tennis,
  volleyball,
  baseball,
  cricket,
  mma,
  generic,
}

enum EventBoxScoreFamily {
  basketballPlayerTable,
  baseballPlayerTable,
  genericPlayerTable,
}

enum EventDetailsFamily {
  basketball,
  baseball,
  volleyball,
  americanFootball,
  tennis,
  tableTennis,
  iceHockey,
  darts,
  esports,
  cricket,
  mma,
  badminton,
  rugby,
  floorball,
  bandy,
  generic,
}

enum HomeCompetitorImage { teamImage, countryFlag }

enum EventPhase { prematch, live, finished, interrupted, canceled, unknown }

enum StageDiscipline {
  motorsportAuto,
  motorsportMoto,
  rally,
  cycling,
  genericStage,
}

/// Port 1:1 của `data/sofascore/SportPresentation.kt`.
class SportPresentation {
  const SportPresentation._();

  static const int motorsportAutoVariant = 4;
  static const int motorsportMotoVariant = 5;
  static const int wrcUniqueStageId = 36;
  static const int cyclingMenUniqueStageId = 9;
  static const int cyclingWomenUniqueStageId = 94;

  static const List<String> revertHomeSportOrder = [
    'football',
    'tennis',
    'basketball',
    'ice-hockey',
    'volleyball',
    'handball',
    'esports',
    'mma',
    'baseball',
    'cricket',
    'motorsport',
    'american-football',
    'rugby',
    'badminton',
    'snooker',
    'darts',
    'futsal',
    'minifootball',
    'table-tennis',
    'beach-volley',
    'waterpolo',
    'cycling',
    'aussie-rules',
    'floorball',
    'bandy',
  ];

  /// Danh sách môn trong bottom sheet chọn môn — port `SPORT_STRING_RES`
  /// của `BottomSheetSportPicker.kt`. Bản gốc luôn hiện đủ 24 môn, không
  /// lọc theo việc hôm nay có trận hay không.
  static const List<String> sportPickerOrder = [
    'football',
    'tennis',
    'basketball',
    'volleyball',
    'badminton',
    'table-tennis',
    'baseball',
    'mma',
    'motorsport',
    'cycling',
    'floorball',
    'bandy',
    'rugby',
    'american-football',
    'aussie-rules',
    'waterpolo',
    'cricket',
    'snooker',
    'darts',
    'esports',
    'ice-hockey',
    'futsal',
    'handball',
    'boxing',
  ];

  /// Bóng đá có API riêng của app; mọi môn khác lấy từ Sofascore.
  static bool usesSofascore(String slug) => slug.toLowerCase() != 'football';

  static HomeEventFamily homeEventFamily(String sportSlug) =>
      switch (sportSlug.toLowerCase()) {
        'football' => HomeEventFamily.football,
        'tennis' => HomeEventFamily.tennis,
        'basketball' => HomeEventFamily.basketball,
        'cricket' => HomeEventFamily.cricket,
        'baseball' => HomeEventFamily.baseball,
        'mma' => HomeEventFamily.mmaFight,
        'motorsport' || 'cycling' => HomeEventFamily.stageSeries,
        _ => HomeEventFamily.genericTwoCompetitor,
      };

  static HomeFeedFamily homeFeedFamily(String sportSlug) =>
      switch (sportSlug.toLowerCase()) {
        'mma' => HomeFeedFamily.mmaFightNights,
        'motorsport' => HomeFeedFamily.stageSeries,
        'cycling' => HomeFeedFamily.cyclingSeason,
        _ => HomeFeedFamily.normalEvents,
      };

  static HomeScoreProfile homeScoreProfile(String sportSlug) =>
      switch (sportSlug.toLowerCase()) {
        'football' || 'minifootball' => HomeScoreProfile.footballScore,
        'tennis' => HomeScoreProfile.tennisGameAndSets,
        'basketball' => HomeScoreProfile.basketballPeriods,
        'cricket' => HomeScoreProfile.cricketInnings,
        'baseball' => HomeScoreProfile.baseballInnings,
        'volleyball' || 'beach-volley' => HomeScoreProfile.volleyballSets,
        'badminton' || 'table-tennis' => HomeScoreProfile.racketSets,
        'darts' => HomeScoreProfile.dartsLegsAndSets,
        'snooker' => HomeScoreProfile.snookerFrames,
        'american-football' => HomeScoreProfile.americanFootballPeriods,
        'aussie-rules' => HomeScoreProfile.aussieRulesPeriods,
        'ice-hockey' => HomeScoreProfile.iceHockeyPeriods,
        'handball' => HomeScoreProfile.handballPeriods,
        'rugby' => HomeScoreProfile.rugbyPeriods,
        'waterpolo' => HomeScoreProfile.waterPoloPeriods,
        'futsal' => HomeScoreProfile.futsalPeriods,
        'beach-soccer' => HomeScoreProfile.beachSoccerPeriods,
        'bandy' => HomeScoreProfile.bandyPeriods,
        'floorball' => HomeScoreProfile.floorballPeriods,
        'pesapallo' => HomeScoreProfile.pesapalloInnings,
        'kabaddi' => HomeScoreProfile.kabaddiPeriods,
        'esports' => HomeScoreProfile.esportsMaps,
        'mma' => HomeScoreProfile.mmaFight,
        'boxing' => HomeScoreProfile.boxingFight,
        'motorsport' || 'cycling' => HomeScoreProfile.stage,
        _ => HomeScoreProfile.genericCurrentScore,
      };

  static EventHeaderFamily eventHeaderFamily(String sportSlug) =>
      switch (sportSlug.toLowerCase()) {
        'football' => EventHeaderFamily.football,
        'tennis' => EventHeaderFamily.tennis,
        'volleyball' || 'beach-volley' => EventHeaderFamily.volleyball,
        'baseball' => EventHeaderFamily.baseball,
        'cricket' => EventHeaderFamily.cricket,
        'mma' => EventHeaderFamily.mma,
        _ => EventHeaderFamily.generic,
      };

  static EventBoxScoreFamily eventBoxScoreFamily(String sportSlug) =>
      switch (sportSlug.toLowerCase()) {
        'basketball' => EventBoxScoreFamily.basketballPlayerTable,
        'baseball' => EventBoxScoreFamily.baseballPlayerTable,
        _ => EventBoxScoreFamily.genericPlayerTable,
      };

  static EventDetailsFamily eventDetailsFamily(String sportSlug) =>
      switch (sportSlug.toLowerCase()) {
        'basketball' => EventDetailsFamily.basketball,
        'baseball' => EventDetailsFamily.baseball,
        'volleyball' || 'beach-volley' => EventDetailsFamily.volleyball,
        'american-football' => EventDetailsFamily.americanFootball,
        'tennis' => EventDetailsFamily.tennis,
        'table-tennis' => EventDetailsFamily.tableTennis,
        'ice-hockey' || 'hockey' => EventDetailsFamily.iceHockey,
        'darts' => EventDetailsFamily.darts,
        'esports' => EventDetailsFamily.esports,
        'cricket' => EventDetailsFamily.cricket,
        'mma' => EventDetailsFamily.mma,
        'badminton' => EventDetailsFamily.badminton,
        'rugby' || 'aussie-rules' => EventDetailsFamily.rugby,
        'floorball' => EventDetailsFamily.floorball,
        'bandy' => EventDetailsFamily.bandy,
        _ => EventDetailsFamily.generic,
      };

  static HomeCompetitorImage homeCompetitorImage(String sportSlug) =>
      sportSlug.toLowerCase() == 'tennis'
          ? HomeCompetitorImage.countryFlag
          : HomeCompetitorImage.teamImage;

  static EventPhase eventPhase(String statusType) =>
      switch (statusType.toLowerCase()) {
        'notstarted' || 'not_started' || 'scheduled' => EventPhase.prematch,
        'inprogress' => EventPhase.live,
        'ended' || 'finished' => EventPhase.finished,
        'interrupted' => EventPhase.interrupted,
        'canceled' || 'cancelled' || 'postponed' => EventPhase.canceled,
        _ => EventPhase.unknown,
      };

  static bool usesStartedEventPresentation(String statusType) => const {
        EventPhase.live,
        EventPhase.finished,
        EventPhase.interrupted,
      }.contains(eventPhase(statusType));

  static List<String> orderSports(Iterable<String> sportSlugs) {
    final distinct = <String>[];
    for (final s in sportSlugs.map((e) => e.toLowerCase())) {
      if (s.isNotEmpty && !distinct.contains(s)) distinct.add(s);
    }
    final known = distinct.toSet();
    return [
      ...revertHomeSportOrder.where(known.contains),
      ...distinct.where((s) => !revertHomeSportOrder.contains(s)),
    ];
  }

  static bool usesSetPointSecondaryScore(String sportSlug) => const {
        HomeScoreProfile.volleyballSets,
        HomeScoreProfile.racketSets,
      }.contains(homeScoreProfile(sportSlug));

  static bool usesStageFeed(String sportSlug) =>
      sportSlug == 'motorsport' || sportSlug == 'cycling';

  static bool usesWeekCalendar(String sportSlug) =>
      sportSlug.toLowerCase() == 'motorsport';

  static bool supportsDedicatedGraphTab(String sportSlug) =>
      sportSlug.toLowerCase() == 'cricket';

  static StageDiscipline stageDiscipline({
    required String sportSlug,
    String? categorySlug,
    int? categorySportVariant,
    int? uniqueStageId,
  }) {
    if (sportSlug.toLowerCase() == 'cycling') return StageDiscipline.cycling;
    if (uniqueStageId == wrcUniqueStageId) return StageDiscipline.rally;

    final slug = (categorySlug ?? '').toLowerCase();
    if (slug == 'rally' || slug.contains('wrc')) return StageDiscipline.rally;
    if (categorySportVariant == motorsportMotoVariant ||
        slug == 'bikes' ||
        slug.startsWith('moto')) {
      return StageDiscipline.motorsportMoto;
    }
    if (sportSlug.toLowerCase() == 'motorsport' ||
        categorySportVariant == motorsportAutoVariant) {
      return StageDiscipline.motorsportAuto;
    }
    return StageDiscipline.genericStage;
  }

  static String relatedEventsTabTitle(String sportSlug) =>
      switch (sportSlug.toLowerCase()) {
        'baseball' || 'basketball' || 'american-football' => 'Games',
        'mma' => 'Events',
        'motorsport' => 'Series',
        'cycling' => 'Cycling',
        _ => 'Matches',
      };

  // ---- Nhãn + icon cho thanh chọn môn ----

  static const Map<String, String> _labels = {
    'football': 'Football',
    'tennis': 'Tennis',
    'basketball': 'Basketball',
    'ice-hockey': 'Ice Hockey',
    'volleyball': 'Volleyball',
    'handball': 'Handball',
    'esports': 'Esports',
    'mma': 'MMA',
    'baseball': 'Baseball',
    'cricket': 'Cricket',
    'motorsport': 'Motorsport',
    'american-football': 'Am. Football',
    'rugby': 'Rugby',
    'badminton': 'Badminton',
    'snooker': 'Snooker',
    'darts': 'Darts',
    'futsal': 'Futsal',
    'minifootball': 'Minifootball',
    'table-tennis': 'Table Tennis',
    'beach-volley': 'Beach Volley',
    'waterpolo': 'Waterpolo',
    'cycling': 'Cycling',
    'aussie-rules': 'Aussie Rules',
    'floorball': 'Floorball',
    'bandy': 'Bandy',
  };

  static String label(String slug) =>
      _labels[slug.toLowerCase()] ??
      slug
          .split('-')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

  static IconData icon(String slug) => switch (slug.toLowerCase()) {
        'football' || 'minifootball' || 'futsal' => Icons.sports_soccer,
        'basketball' => Icons.sports_basketball,
        'tennis' || 'table-tennis' || 'badminton' => Icons.sports_tennis,
        'ice-hockey' || 'bandy' || 'floorball' => Icons.sports_hockey,
        'volleyball' || 'beach-volley' => Icons.sports_volleyball,
        'baseball' || 'pesapallo' => Icons.sports_baseball,
        'american-football' => Icons.sports_football,
        'handball' => Icons.sports_handball,
        'cricket' => Icons.sports_cricket,
        'rugby' || 'aussie-rules' => Icons.sports_rugby,
        'mma' || 'boxing' => Icons.sports_mma,
        'motorsport' => Icons.sports_motorsports,
        'esports' => Icons.sports_esports,
        'darts' => Icons.gps_fixed,
        'snooker' => Icons.circle_outlined,
        'waterpolo' => Icons.pool,
        'cycling' => Icons.directions_bike,
        _ => Icons.sports,
      };
}
