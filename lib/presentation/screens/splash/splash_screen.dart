import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

/// Port `presentation/splash/SplashFragment.kt` — đã bỏ toàn bộ phần
/// nạp quảng cáo (native splash / interstitial) và consent.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Bản gốc chờ Remote Config + ads tối đa vài giây; ở đây chỉ còn
  /// Remote Config nên giữ một khoảng tối thiểu cho mượt.
  static const Duration _minSplash = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    sl<AnalyticsService>().logEvent('splash_show');

    // Nạp trước danh sách giải ghim mặc định để màn Home hiện ngay.
    unawaited(sl<SofascoreRepositoryImpl>().ensureDefaultPinsInitialized());

    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minSplash) await Future<void>.delayed(_minSplash - elapsed);
    if (!mounted) return;
    _navigateNext();
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
                SizedBox(height: AppDimens.sdp(32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
