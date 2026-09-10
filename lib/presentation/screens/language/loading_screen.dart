import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/ads/native/native_placements.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/local/app_prefs.dart';
import '../../widgets/native/native_ad_view.dart';

/// Port `presentation/language/LoadingFragment.kt` — màn chờ giữa
/// Language và Onboarding/Main (bản gốc dùng để nạp native ads).
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  static const Duration _duration = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    unawaited(_next());
  }

  Future<void> _next() async {
    await Future<void>.delayed(_duration);
    if (!mounted) return;
    final prefs = sl<AppPrefs>();
    // `LoadingFragment.navigateNext`: `!passedOnboard || reopenOnboard`.
    final needOnboard =
        !prefs.passedOnboard || sl<RemoteConfigService>().onboardReopen;
    Navigator.of(context).pushReplacementNamed(
      needOnboard ? AppRoutes.onboarding : AppRoutes.main,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_loading.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: AppColors.bgApp),
          ),
          // Khối `layoutanim` 180sdp lệch trái 30sdp, lên 70sdp so với tâm.
          Center(
            child: Transform.translate(
              offset: Offset(AppDimens.sdp(30) / 2, -AppDimens.sdp(70) / 2),
              child: SizedBox(
                width: AppDimens.sdp(180),
                height: AppDimens.sdp(180),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SvgPicture.asset(
                        'assets/icons/bg_gif_fb.svg',
                        width: AppDimens.sdp(130),
                        height: AppDimens.sdp(130),
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/ic_fb.svg',
                      width: AppDimens.sdp(94),
                      height: AppDimens.sdp(94),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Chữ "Loading" 22ssp bold có shimmer, ngay dưới khối anim (-40dp).
          Center(
            child: Transform.translate(
              offset: Offset(
                AppDimens.sdp(12) / 2,
                AppDimens.sdp(180) / 2 - AppDimens.sdp(70) / 2 - 40,
              ),
              child: Shimmer.fromColors(
                baseColor: AppColors.white.withValues(alpha: 0.3),
                highlightColor: AppColors.white,
                period: const Duration(milliseconds: 800),
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppDimens.sdp(2)),
                  child: Text(
                    s.loading,
                    style: AppTextStyles.bold(
                      size: AppDimens.ssp(22),
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // `LiveScore_native_Loading` neo ở đáy màn.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: NativeAdView(
                placement: NativePlacements.loading,
                margin: EdgeInsets.all(AppDimens.sdp(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
