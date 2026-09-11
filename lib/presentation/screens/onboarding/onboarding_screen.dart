import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_placements.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/local/app_prefs.dart';
import '../../widgets/native/native_ad_view.dart';
import '../../widgets/native/native_fullscreen_overlay.dart';

/// Port `OnboardingLargeFragment.kt` + `fragment_on_boarding_1/2/3.xml`.
/// Ba trang đều là ảnh nền tràn viền, dưới cùng là chỉ báo 50x6sdp và nút
/// Next 44dp; trang 1 có tiêu đề + mô tả căn trái, trang 3 chỉ có tiêu đề
/// căn phải, trang 2 không có chữ. Đã bỏ native/interstitial ads.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    sl<AnalyticsService>().logEvent('onboarding_show');
    // Native fullscreen bật ngay khi rời trang 1 nên phải có sẵn từ đầu.
    unawaited(sl<NativeAdManager>().preload(NativePlacements.fullscreen));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next(int pageCount) async {
    sl<AnalyticsService>()
        .logEvent('onboarding_step_view', {'step_index': '${_page + 1}'});

    // `OnBoardingFragment1.btnNext`: rời trang 1 thì bật native fullscreen
    // (1 slot — một quảng cáo chiếm cả màn). Không có sẵn thì đi tiếp luôn.
    if (_page == 0) {
      await NativeFullscreenOverlay.show(
        context,
        NativePlacements.fullscreen,
      );
      if (!mounted) return;
    }

    if (_page < pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    await _finish();
  }

  static String _placementForPage(int page) => switch (page) {
        0 => NativePlacements.onboarding1,
        1 => NativePlacements.onboarding2,
        _ => NativePlacements.onboarding3,
      };

  /// Mỗi trang nạp trước cho trang kế; trang cuối nạp cho màn chọn giải và
  /// cho native fullscreen bật sau khi chọn xong đội.
  void _preloadForNextPage(int page, int total) {
    final manager = sl<NativeAdManager>();
    if (page + 1 < total) {
      unawaited(manager.preload(_placementForPage(page + 1)));
    } else {
      unawaited(manager.preloadAll([
        NativePlacements.choose1,
        NativePlacements.fullscreenInter,
      ]));
    }
  }

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    final prefs = sl<AppPrefs>();
    await prefs.setPassedOnboard(true);
    sl<AnalyticsService>().logEvent('onboarding_complete');

    // Bản gốc chỉ xét `!passedPickFav`; ở đây bước chọn giải/đội dùng chung
    // cờ `onboard_reopen` với onboarding nên mở lại mỗi lần vào app.
    final needPick =
        !prefs.passedPickFav || sl<RemoteConfigService>().onboardReopen;
    navigator.pushReplacementNamed(
      needPick ? AppRoutes.pickFavoriteLeagues : AppRoutes.main,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final pages = <_OnboardingPageData>[
      _OnboardingPageData(
        background: 'assets/images/bg_ob1.webp',
        title: s.ob1Title,
        description: s.ob1Des,
        alignment: Alignment.centerLeft,
        textAlign: TextAlign.start,
      ),
      const _OnboardingPageData(background: 'assets/images/bg_ob2.webp'),
      _OnboardingPageData(
        background: 'assets/images/bg_ob3.webp',
        title: s.ob3Title,
        alignment: Alignment.centerRight,
        textAlign: TextAlign.end,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _preloadForNextPage(i, pages.length);
            },
            itemBuilder: (_, i) => Image.asset(
              pages[i].background,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  const ColoredBox(color: AppColors.bgApp),
            ),
          ),
          // Chuỗi neo đáy: btnNext → icIndicator → txtDes → txtTitle.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pages[_page].title != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.sdp(12),
                      ),
                      child: Align(
                        alignment: pages[_page].alignment,
                        child: Text(
                          pages[_page].title!,
                          textAlign: pages[_page].textAlign,
                          style: AppTextStyles.semiBold(
                            size: AppDimens.ssp(20),
                            color: AppColors.colorPrimary,
                          ),
                        ),
                      ),
                    ),
                  if (pages[_page].description != null) ...[
                    SizedBox(height: AppDimens.sdp(10)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.sdp(12),
                      ),
                      child: Align(
                        alignment: pages[_page].alignment,
                        child: Text(
                          pages[_page].description!,
                          textAlign: pages[_page].textAlign,
                          style: AppTextStyles.regular(
                            size: AppDimens.ssp(15),
                            color: AppColors.text500,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: AppDimens.sdp(12)),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimens.sdp(6)),
                      child: _Indicator(count: pages.length, index: _page),
                    ),
                  ),
                  // Native riêng cho từng trang onboarding.
                  //
                  // Thứ tự đảo ở trang 3: `fragment_on_boarding_1/2.xml` cho
                  // `layoutNative` nằm **trên** `btnNext` (lề dưới 6sdp), còn
                  // `fragment_on_boarding_3.xml` thì `btnNext` mới ở trên,
                  // `layoutNative` ghim đáy parent và không có lề.
                  if (_page != 2)
                    NativeAdView(
                      placement: _placementForPage(_page),
                      margin: EdgeInsets.only(bottom: AppDimens.sdp(6)),
                    ),
                  // `btnNext`: 44dp, marginH 20sdp, marginV 6sdp,
                  // `bg_btn_12sdp_ff783e`, chữ 15ssp semi_bold trắng.
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.sdp(20),
                      vertical: AppDimens.sdp(6),
                    ),
                    child: GestureDetector(
                      onTap: () => _next(pages.length),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brandAccent,
                          borderRadius:
                              BorderRadius.circular(AppDimens.sdp(12)),
                        ),
                        child: Text(
                          s.next,
                          style: AppTextStyles.semiBold(
                            size: AppDimens.ssp(15),
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_page == 2)
                    NativeAdView(placement: _placementForPage(_page)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.background,
    this.title,
    this.description,
    this.alignment = Alignment.centerLeft,
    this.textAlign = TextAlign.start,
  });

  final String background;
  final String? title;
  final String? description;
  final Alignment alignment;
  final TextAlign textAlign;
}

/// Port `in_1/in_2/in_3.xml` — dải 56x8 gồm một viên 24x8 màu accent ở vị trí
/// đang chọn và hai chấm 8x8 màu #F3F4F6, hiển thị ở kích thước 50x6sdp.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scale = AppDimens.sdp(50) / 56;
    return SizedBox(
      height: AppDimens.sdp(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count * 2 - 1, (i) {
          if (i.isOdd) return SizedBox(width: 8 * scale);
          final position = i ~/ 2;
          final active = position == index;
          return Container(
            width: (active ? 24 : 8) * scale,
            height: 8 * scale,
            decoration: BoxDecoration(
              color: active ? AppColors.brandAccent : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4 * scale),
            ),
          );
        }),
      ),
    );
  }
}
