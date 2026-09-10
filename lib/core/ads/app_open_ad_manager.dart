import 'dart:developer' as dev;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../di/injection.dart';
import '../services/remote_config_service.dart';
import 'ads_analytics.dart';
import 'ads_config_manager.dart';
import 'ads_constants.dart';
import 'ads_gate.dart';

/// Port `ads/aoa/AppOpenAdManager.kt`.
///
/// Giữ nguyên: timeout 4 giờ, cờ `aoaEnabled` bật/tắt thủ công quanh lúc show
/// inter/reward, cờ `isSplash` cho phép preload ngay cả khi AOA đang tắt, và
/// điều kiện `LiveScore_appopen_resume` của Remote Config.
///
/// Phần AppsFlyer ad-revenue của bản gốc bị bỏ (app Flutter không nhúng
/// AppsFlyer); doanh thu vẫn được ghi qua [AdsAnalytics.logImpression].
class AppOpenAdManager {
  const AppOpenAdManager._();

  static const String _tag = 'AppOpenAdManager';
  static const int _timeoutMs = 4 * 60 * 60 * 1000;

  static AppOpenAd? _appOpenAd;
  static bool _isLoading = false;
  static bool _isShowing = false;
  static int _loadTime = 0;

  static bool _aoaEnabled = true;

  /// Bản gốc để `var isSplash` public — Splash bật lên để preload được ngay
  /// dù AOA đang bị tắt trong suốt màn splash.
  static bool isSplash = false;

  static void disable([String reason = '']) {
    _aoaEnabled = false;
    dev.log('AOA disabled: $reason', name: _tag);
  }

  static void enable([String reason = '']) {
    _aoaEnabled = true;
    dev.log('AOA enabled: $reason', name: _tag);
  }

  static bool get isEnabled => _aoaEnabled;

  static bool get _resumeEnabled {
    try {
      return sl<RemoteConfigService>().appOpenResumeEnabled;
    } catch (_) {
      return true;
    }
  }

  // ================= LOAD =================

  static void preload() {
    if (AdsGate.isBlocked) return;
    if (!isSplash && !_aoaEnabled) return;
    if (!_resumeEnabled) return;
    if (_isLoading || _isAdAvailable) return;

    _isLoading = true;
    AdsAnalytics.logRequest(AdsUnitIds.appOpen, AdFormat.appOpen);

    AppOpenAd.load(
      adUnitId: AdsUnitIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoading = false;
          _loadTime = AdsClock.elapsedMs;

          final adSource =
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                  'unknown';
          AdsAnalytics.logLoaded(
              AdsUnitIds.appOpen, AdFormat.appOpen, adSource);

          ad.onPaidEvent = (_, valueMicros, precision, currencyCode) {
            AdsAnalytics.logImpression(
              adUnit: AdsUnitIds.appOpen,
              adFormat: AdFormat.appOpen,
              adSource: adSource,
              valueMicros: valueMicros.round(),
              currencyCode: currencyCode,
            );
          };

          dev.log('AOA loaded', name: _tag);
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          dev.log('AOA load failed: ${error.message}', name: _tag);
        },
      ),
    );
  }

  // ================= SHOW =================

  static Future<void> showIfAvailable() async {
    if (AdsGate.isBlocked) return;
    if (!_aoaEnabled) {
      dev.log('AOA skipped (disabled)', name: _tag);
      return;
    }

    if (!_resumeEnabled) {
      AdsAnalytics.logShowRequest(
        adUnit: AdsUnitIds.appOpen,
        adFormat: AdFormat.appOpen,
        ready: false,
      );
      return;
    }
    if (_isShowing) return;

    if (!_isAdAvailable) {
      AdsAnalytics.logShowRequest(
        adUnit: AdsUnitIds.appOpen,
        adFormat: AdFormat.appOpen,
        ready: false,
      );
      preload();
      return;
    }

    AdsAnalytics.logShowRequest(
      adUnit: AdsUnitIds.appOpen,
      adFormat: AdFormat.appOpen,
      ready: true,
    );

    final ad = _appOpenAd;
    if (ad == null) return;

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdClicked: (shown) {
        AdsAnalytics.logClick(
          adUnit: AdsUnitIds.appOpen,
          adFormat: AdFormat.appOpen,
          adSource:
              shown.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                  'unknown',
        );
      },
      onAdShowedFullScreenContent: (_) => _isShowing = true,
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        _appOpenAd = null;
        _isShowing = false;
        preload();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        dev.log('AOA show failed: $error', name: _tag);
        shown.dispose();
        _appOpenAd = null;
        _isShowing = false;
        preload();
      },
    );

    await ad.show();
  }

  static bool get _isAdAvailable =>
      _appOpenAd != null && AdsClock.elapsedMs - _loadTime < _timeoutMs;
}
