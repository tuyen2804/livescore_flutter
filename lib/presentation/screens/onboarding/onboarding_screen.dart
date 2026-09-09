import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/local/app_prefs.dart';

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int pageCount) {
    sl<AnalyticsService>()
        .logEvent('onboarding_step_view', {'step_index': '${_page + 1}'});
    if (_page < pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    _finish();
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
            onPageChanged: (i) => setState(() => _page = i),
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
