import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/ads/ads_config.dart';
import '../../../core/ads/ads_config_manager.dart';
import '../../../core/ads/ads_config_repository.dart';
import '../../../core/ads/ads_constants.dart';
import '../../../core/ads/app_open_ad_manager.dart';
import '../../../core/ads/consent_manager.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_placements.dart';
import '../../widgets/native/native_ad_view.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/local/app_prefs.dart';
import '../../../data/repositories/sofascore_repository_impl.dart';

/// Port `presentation/splash/SplashFragment.kt`.
///
/// Luồng quảng cáo giữ đúng bản gốc: tắt AOA và đánh dấu `isSplash`, mốc
/// `initAppStart` cho firstDelay, chờ kết quả consent rồi mới nạp cấu hình ads
/// và preload inter splash, cuối cùng chờ inter sẵn sàng để show trước khi đi
/// tiếp. Có hàng rào 30 giây: quá lâu mà chưa show được thì đi luôn.
/// Native splash đã bỏ theo yêu cầu.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Bản gốc chờ Remote Config + ads tối đa vài giây.
  static const Duration _minSplash = Duration(milliseconds: 1500);

  /// `launch { delay(30000); if (!isShowInter) goNext() }` của bản gốc.
  static const Duration _hardTimeout = Duration(seconds: 30);

  /// `launch { delay(20000); collectSplashInter() }`.
  static const Duration _interWait = Duration(seconds: 20);

  bool _isShowInter = false;
  bool _navigated = false;
  StreamSubscription<bool>? _consentSub;
  Timer? _hardTimeoutTimer;

  @override
  void initState() {
    super.initState();
    AppOpenAdManager.isSplash = true;
    AppOpenAdManager.disable('splash');
    InterstitialAdManager.initAppStart();
    _hardTimeoutTimer = Timer(_hardTimeout, () {
      if (!_isShowInter) _goNext();
    });
    _consentSub = ConsentState.stream.listen(_onConsent);
    // Nạp cấu hình native SONG SONG với consent, không nối tiếp — hạn 5 giây,
    // hết giờ thì rơi về cache/asset (xem NativePlacementRepository).
    unawaited(sl<NativeAdManager>().loadConfig());
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _consentSub?.cancel();
    _hardTimeoutTimer?.cancel();
    super.dispose();
  }

  /// `ConsentState.flow.collect { ... }` — từ chối consent thì bỏ qua ads.
  Future<void> _onConsent(bool canRequestAds) async {
    await _consentSub?.cancel();
    _consentSub = null;

    if (!canRequestAds) {
      dev.log('Consent denied → skip ads', name: 'Splash');
      _goNext();
      return;
    }

    await _initAdsConfigAndPreload();
    if (!mounted) return;

    AppOpenAdManager.preload();
    // Splash nạp trước cho chính nó và cho màn Language kế tiếp.
    unawaited(sl<NativeAdManager>().preloadAfterConfig([
      NativePlacements.splash,
      NativePlacements.language1,
      NativePlacements.language2,
    ]));
    unawaited(_collectSplashInter());
  }

  /// Port `initAdsConfigAndPreload()`.
  Future<void> _initAdsConfigAndPreload() async {
    InterstitialAdManager.preload(InterPlacement.splash);

    final prefs = sl<AppPrefs>();
    final playout = prefs.adsPlayout;
    final repo = sl<AdsConfigRepository>();

    var config = await repo.fetchAndCache().catchError((Object e) {
      dev.log('fetch ads config lỗi: $e', name: 'Splash');
      return repo.getCached() ?? AdsConfig.empty;
    });
    if (config.adsSet.isEmpty) {
      config = repo.getCached() ?? AdsConfig.empty;
    }
    if (config.adsSet.isEmpty) return;

    AdsConfigManager.init(config, playout);
    await prefs.setAdsPlayout(playout + 1);
  }

  /// Port `collectSplashInter()` — chờ inter sẵn sàng rồi show, xong mới đi.
  Future<void> _collectSplashInter() async {
    if (_isShowInter) return;
    final ready = await InterstitialAdManager.waitReady(
      InterPlacement.splash,
      timeout: _interWait,
    );
    if (!mounted) return;
    if (!ready) {
      _goNext();
      return;
    }
    _isShowInter = true;
    await InterstitialAdManager.showIfReady(
      InterPlacement.splash,
      enable: false,
      onDismiss: () {
        dev.log('Inter done -> go next', name: 'Splash');
        AppOpenAdManager.enable('splash inter dismissed');
        _goNext();
      },
    );
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    AppOpenAdManager.isSplash = false;
    _hardTimeoutTimer?.cancel();
    _navigateNext();
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    sl<AnalyticsService>().logEvent('splash_show');

    // Nạp trước danh sách giải ghim mặc định để màn Home hiện ngay.
    unawaited(sl<SofascoreRepositoryImpl>().ensureDefaultPinsInitialized());

    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minSplash) await Future<void>.delayed(_minSplash - elapsed);
    // Không tự đi tiếp ở đây: quyền quyết định thuộc về luồng consent → ads,
    // hoặc hàng rào 30 giây, đúng như bản gốc.
  }

  /// Port `MainActivity.navigateFromSplash`:
  /// `!passedLanguage || reopenLanguage` → Language,
  /// `!passedOnboard || reopenOnboard` → Onboarding, còn lại → Main.
  void _navigateNext() {
    final prefs = sl<AppPrefs>();
    final config = sl<RemoteConfigService>();

    if (!prefs.passedLanguage || config.languageReopen) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.language);
      return;
    }
    if (!prefs.passedOnboard || config.onboardReopen) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // `bgSplash` phủ kín màn, bản gốc nạp `bg_loading` bằng Glide.
          Image.asset(
            'assets/images/bg_loading.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: AppColors.bgApp),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: AppDimens.sdp(100)),
                Image.asset(
                  'assets/images/ic_launcher.png',
                  width: AppDimens.sdp(80),
                  height: AppDimens.sdp(80),
                  errorBuilder: (context, error, stack) => Container(
                    width: AppDimens.sdp(80),
                    height: AppDimens.sdp(80),
                    color: AppColors.itemBg,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.sports_soccer,
                      color: AppColors.brandAccent,
                      size: 40,
                    ),
                  ),
                ),
                SizedBox(height: AppDimens.sdp(12)),
                Shimmer.fromColors(
                  baseColor: AppColors.white.withValues(alpha: 0.5),
                  highlightColor: AppColors.white,
                  period: const Duration(milliseconds: 900),
                  child: Text(
                    s.appName,
                    style: AppTextStyles.semiBold(
                      size: AppDimens.ssp(20),
                      color: AppColors.white,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: AppDimens.sdp(40),
                  height: AppDimens.sdp(40),
                  child: CircularProgressIndicator(
                    strokeWidth: AppDimens.sdp(4),
                    strokeCap: StrokeCap.round,
                    color: AppColors.brandAccent,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SizedBox(height: AppDimens.sdp(16)),
                // `adsNative` — placement DUY NHẤT có shimmer, đúng như bản
                // gốc chỉ inflate layout_shimmer_native_* ở SplashFragment.
                NativeAdView(
                  placement: NativePlacements.splash,
                  showShimmer: true,
                ),
                SizedBox(height: AppDimens.sdp(16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
