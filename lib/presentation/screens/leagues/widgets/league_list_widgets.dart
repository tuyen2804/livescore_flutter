import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';

/// Port `item_league_section_header.xml`: paddingV 6sdp, tên 12ssp regular
/// `#747474`, mũi tên `ic_expand` 24sdp padding 6sdp — xoay 180° khi đang mở.
class LeagueSectionHeader extends StatelessWidget {
  const LeagueSectionHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(6)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(12),
                    color: AppColors.expandArrow,
                  ),
                ),
              ),
              _CollapseArrow(expanded: expanded),
            ],
          ),
        ),
      );
}

/// Port `item_league_header.xml` + `SubHeaderVH.bind`: gạch 1dp `color_divider`
/// (ẩn ở mục đầu), `ic_league` 22sdp, tên 14sp **đậm** `text200` cách 10sdp,
/// mũi tên 24sdp; toàn khối cách dưới 10sdp.
class LeagueSubHeader extends StatelessWidget {
  const LeagueSubHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onTap,
    this.isFirst = false,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(bottom: AppDimens.sdp(10)),
          child: Column(
            children: [
              if (!isFirst) ...[
                Container(height: 1, color: AppColors.divider),
                SizedBox(height: AppDimens.sdp(10)),
              ],
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_league.svg',
                    width: AppDimens.sdp(22),
                    height: AppDimens.sdp(22),
                  ),
                  SizedBox(width: AppDimens.sdp(10)),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bold(
                        size: 14,
                        color: AppColors.text200,
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimens.sdp(10)),
                  _CollapseArrow(expanded: expanded),
                ],
              ),
            ],
          ),
        ),
      );
}

class _CollapseArrow extends StatelessWidget {
  const _CollapseArrow({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: AppDimens.sdp(24),
        height: AppDimens.sdp(24),
        child: Padding(
          padding: EdgeInsets.all(AppDimens.sdp(6)),
          child: AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: SvgPicture.asset('assets/icons/ic_expand.svg'),
          ),
        ),
      );
}

/// Port `item_no_favorite.xml`: chữ 10ssp `text200` căn giữa, paddingV 10sdp.
class NoFavoriteRow extends StatelessWidget {
  const NoFavoriteRow({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(10)),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.medium(
            size: AppDimens.ssp(10),
            color: AppColors.text200,
          ),
        ),
      );
}

/// Port `item_league_grid.xml` / `item_team_grid.xml`: ô lưới `bg_league_grid_item`
/// (nền `color_item_bg`, bo 12sdp), margin 6sdp, padding 8sdp — sao 13sdp góc
/// trên phải, logo 40sdp, tên 8ssp medium một dòng căn giữa.
class LeagueGridCell extends StatelessWidget {
  const LeagueGridCell({
    super.key,
    required this.name,
    required this.logoUrl,
    required this.isFavourite,
    required this.onTap,
    required this.onToggleFavourite,
    this.placeholderAsset = 'assets/icons/ic_league.svg',
  });

  final String name;
  final String? logoUrl;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavourite;
  final String placeholderAsset;

  @override
  Widget build(BuildContext context) {
    // Hai giải này dùng logo đơn sắc nên bản gốc tô trắng.
    final tintWhite = name.toLowerCase() == 'champions league' ||
        name.toLowerCase() == 'premier league';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.all(AppDimens.sdp(6)),
        padding: EdgeInsets.all(AppDimens.sdp(8)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onToggleFavourite,
                child: SvgPicture.asset(
                  isFavourite
                      ? 'assets/icons/ic_star_filled.svg'
                      : 'assets/icons/ic_star.svg',
                  width: AppDimens.sdp(13),
                  height: AppDimens.sdp(13),
                ),
              ),
            ),
            SizedBox(height: AppDimens.sdp(10)),
            AppImage(
              source: logoUrl,
              width: AppDimens.sdp(40),
              height: AppDimens.sdp(40),
              color: tintWhite ? AppColors.white : null,
              placeholderAsset: placeholderAsset,
            ),
            SizedBox(height: AppDimens.sdp(12)),
            Text(
              name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.medium(
                size: AppDimens.ssp(8),
                color: AppColors.text500,
              ),
            ),
            SizedBox(height: AppDimens.sdp(4)),
          ],
        ),
      ),
    );
  }
}
