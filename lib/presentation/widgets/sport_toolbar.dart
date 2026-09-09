import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/sport_presentation.dart';
import 'sport_icon.dart';

/// Port khối `toolbar` của `fragment_leagues.xml` / `fragment_teams.xml`:
/// cao 64dp, nền `color_item_bg`, padding ngang 16dp — pill chọn môn bên trái,
/// tiêu đề căn giữa (18sp), nút tìm kiếm 32dp bên phải.
class SportToolbar extends StatelessWidget {
  const SportToolbar({
    super.key,
    required this.title,
    required this.sportSlug,
    required this.onSportTap,
    required this.onSearchTap,
  });

  final String title;
  final String sportSlug;
  final VoidCallback onSportTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    color: AppColors.itemBg,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        SportSelectorPill(slug: sportSlug, onTap: onSportTap),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bold(size: 18, color: AppColors.text500),
          ),
        ),
        GestureDetector(
          onTap: onSearchTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset('assets/icons/ic_search.svg'),
            ),
          ),
        ),
      ],
    ),
  );
}

/// `bg_sport_selector_pill.xml`: nền #1AFFA600, bo 9dp, viền 1.5dp #FFA600.
class SportSelectorPill extends StatelessWidget {
  const SportSelectorPill({super.key, required this.slug, required this.onTap});

  final String slug;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.sportPillFill,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.brandAccent, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 18, height: 18, child: SportIcon(slug: slug)),
          const SizedBox(width: 6),
          Text(
            SportPresentation.label(slug),
            style: AppTextStyles.bold(size: 14, color: AppColors.white),
          ),
          const SizedBox(width: 6),
          SvgPicture.asset('assets/icons/drop_home.svg', width: 10, height: 10),
        ],
      ),
    ),
  );
}
