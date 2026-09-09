import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';

/// Bảng màu riêng của hai màn motorsport — bản gốc dùng nền SÁNG `#EEF2F6`
/// chứ không theo theme tối của phần còn lại.
class MotorsportPalette {
  const MotorsportPalette._();

  static const Color background = Color(0xFFEEF2F6);
  static const Color seriesHeaderFallback = Color(0xFF4B100B);
  static const Color stageHeaderFallback = Color(0xFF17240D);
  static const Color stageScrim = Color(0x990A1708);
  static const Color seriesTabInactive = Color(0xFFD8D0D0);
  static const Color stageTabInactive = Color(0xFFCDD0CF);
}

/// Port `seriesHeader` / `stageHeader`: khối 300dp có ảnh nền, nút back và
/// chuông 56dp (padding 14dp, marginTop 40dp), ô logo 72dp ở marginTop ~150dp,
/// tiêu đề nhỏ + tên lớn 28sp, và TabLayout 54dp gạch chỉ báo trắng.
class MotorsportHeroHeader extends StatelessWidget {
  const MotorsportHeroHeader({
    super.key,
    required this.backgroundColor,
    required this.title,
    required this.bigTitle,
    required this.tabs,
    required this.selectedTab,
    required this.onSelectTab,
    required this.tabInactiveColor,
    this.backgroundImageUrl,
    this.logo,
    this.showScrim = false,
  });

  final Color backgroundColor;
  final String title;
  final String bigTitle;
  final List<String> tabs;
  final int selectedTab;
  final ValueChanged<int> onSelectTab;
  final Color tabInactiveColor;
  final String? backgroundImageUrl;
  final Widget? logo;
  final bool showScrim;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 300,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: backgroundColor,
                child: backgroundImageUrl == null
                    ? null
                    : AppImage(source: backgroundImageUrl, fit: BoxFit.cover),
              ),
            ),
            if (showScrim)
              const Positioned.fill(
                child: ColoredBox(color: MotorsportPalette.stageScrim),
              ),
            Positioned(
              left: 10,
              top: 40,
              child: _IconButton(
                asset: 'assets/icons/ic_arrow_breadcrumb_16.svg',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              right: 18,
              top: 40,
              child: _IconButton(
                asset: 'assets/icons/ic_bell_outline.svg',
                onTap: () {},
              ),
            ),
            if (logo != null)
              Positioned(
                left: 22,
                top: 152,
                child: SizedBox(width: 72, height: 72, child: logo),
              ),
            Positioned(
              left: 122,
              right: 22,
              top: 150,
              height: 88,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.regular(size: 18, color: Colors.white),
                  ),
                  Text(
                    bigTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bold(size: 28, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 54,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onSelectTab(i),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  tabs[i].toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.medium(
                                    size: 13,
                                    color: i == selectedTab
                                        ? Colors.white
                                        : tabInactiveColor,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 2,
                              color: i == selectedTab
                                  ? Colors.white
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SvgPicture.asset(
              asset,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      );
}
