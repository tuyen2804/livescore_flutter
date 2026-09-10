import '../di/injection.dart';
import '../services/analytics_service.dart';

/// Port `ads/AdsAnalytics.kt`.
///
/// Bản Kotlin bắn song song sang Firebase Analytics và AppsFlyer
/// (`AppsFlyerAdRevenue.logAdRevenue`). Bản Flutter không tích hợp AppsFlyer
/// nên chỉ giữ nhánh Firebase — tên event và tên tham số giữ nguyên để báo
/// cáo bên Firebase khớp với bản Android.
class AdsAnalytics {
  const AdsAnalytics._();

  static AnalyticsService get _analytics => sl<AnalyticsService>();

  static void logRequest(String adUnit, String adFormat) {
    _analytics.logEvent('ads_request', {
      'ad_unit': adUnit,
      'ad_format': adFormat,
    });
  }

  static void logLoaded(String adUnit, String adFormat, String adSource) {
    _analytics.logEvent('ads_loaded', {
      'ad_unit': adUnit,
      'ad_format': adFormat,
      'ad_source': adSource,
    });
  }

  static void logShowRequest({
    required String adUnit,
    required String adFormat,
    required bool ready,
  }) {
    _analytics.logEvent('ads_show_request', {
      'ad_unit': adUnit,
      'ad_format': adFormat,
      'ad_ready': ready.toString(),
    });
  }

  /// `valueMicros` là doanh thu × 1.000.000 do AdMob trả về; bản gốc chia
  /// 1e6 trước khi gửi Firebase.
  static void logImpression({
    required String adUnit,
    required String adFormat,
    required String adSource,
    required int valueMicros,
    required String currencyCode,
  }) {
    _analytics.logEvent('ads_impression', {
      'ad_unit': adUnit,
      'ad_format': adFormat,
      'ad_source': adSource,
      'value': valueMicros / 1000000.0,
      'currency': currencyCode,
    });
  }

  static void logClick({
    required String adUnit,
    required String adFormat,
    required String adSource,
  }) {
    _analytics.logEvent('ads_click', {
      'ad_unit': adUnit,
      'ad_format': adFormat,
      'ad_source': adSource,
    });
  }
}
