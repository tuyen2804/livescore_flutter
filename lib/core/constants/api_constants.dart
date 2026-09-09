/// Điểm cuối API — giữ đúng như bản Android.
class ApiConstants {
  const ApiConstants._();

  /// API bóng đá riêng của app (Remote Config key `base_url`).
  static const String footballBaseUrl = 'https://sp098-live-score.pandaglobal.top';

  /// Ảnh logo đội bóng của API riêng (Remote Config key `image_base_url`).
  static const String footballImageBaseUrl = 'https://cdn.sportmonks.com/images/soccer';

  /// API Sofascore cho các môn còn lại.
  static const String sofascoreBaseUrl = 'https://api.sofascore.com/api/v1/';
  static const String sofascoreImageBaseUrl = 'https://img.sofascore.com/api/v1';

  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  // ---- Đường dẫn API bóng đá ----
  static const String leagueLive = '/live-score/league-live';
  static const String matchCentreLive = '/live-score/match-centre-live';
  static const String standings = '/live-score/standings';
  static const String listFixturesUpcoming = '/live-score/list-fixtures-upcoming';
  static const String matchHighLight = '/live-score/match-high-light';
  static const String matchForecast = '/live-score/match-forecast-new';
  static const String fixturesByDateForTeam = '/live-score/fixtures-by-date-for-team';
  static const String matchCentreVote = '/live-score/match-centre-vote';
  static const String matchCentreVoteTeamWin = '/live-score/match-centre-vote-team-win';
  static const String listPlayer = '/live-score/list-player';

  // ---- Ảnh Sofascore ----
  static String teamLogo(int id) => '$sofascoreImageBaseUrl/team/$id/image';
  static String uniqueTournamentLogo(int id) =>
      '$sofascoreImageBaseUrl/unique-tournament/$id/image';
  static String uniqueStageLogo(int id) =>
      '$sofascoreImageBaseUrl/unique-stage/$id/image';
  static String categoryLogo(int id) => '$sofascoreImageBaseUrl/category/$id/image';
  static String countryFlag(String alpha2) =>
      '$sofascoreImageBaseUrl/country/$alpha2/flag';
  static String playerImage(int id) => '$sofascoreImageBaseUrl/player/$id/image';
  static String managerImage(int id) => '$sofascoreImageBaseUrl/manager/$id/image';

  // ---- YouTube ----
  static String youtubeThumb(String videoId) =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  static String youtubeWatch(String videoId) =>
      'https://www.youtube.com/watch?v=$videoId';
}
