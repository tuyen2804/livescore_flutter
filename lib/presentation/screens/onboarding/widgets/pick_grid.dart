import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';

/// Port `rcvLeagues`/`rcvTeams`: lưới 2 cột, paddingH 13sdp,
/// paddingBottom 10sdp; mỗi ô tự chừa margin 7sdp bên trong.
class PickGrid extends StatelessWidget {
  const PickGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    // paddingV 16sp + logo 80sdp + marginTop 8sdp + 2 dòng chữ 12ssp.
    final extent = AppDimens.sdp(80) +
        AppDimens.sdp(8) +
        AppDimens.ssp(12) * 2 * 1.35 +
        32 +
        AppDimens.sdp(14);

    return GridView.builder(
      padding: EdgeInsets.only(
        left: AppDimens.sdp(13),
        right: AppDimens.sdp(13),
        bottom: AppDimens.sdp(10),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: extent,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Port `item_pick_league.xml` + `PickFavoriteAdapter.bind`: nền `bg_item_pick`
/// (chưa chọn `#1AFFFFFF`, đã chọn `#1A000000` + viền 1.5dp accent, bo 12sdp),
/// logo 80sdp căn giữa, tên 12ssp medium luôn chiếm 2 dòng.
class PickCard extends StatelessWidget {
  const PickCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
    this.isLeague = true,
  });

  final String name;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;
  final bool isLeague;

  @override
  Widget build(BuildContext context) {
    // Hai giải này dùng logo đơn sắc nên bản gốc tô trắng.
    final tintWhite = name.toLowerCase() == 'champions league' ||
        name.toLowerCase() == 'premier league';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.all(AppDimens.sdp(7)),
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: AppDimens.sdp(8),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1A000000) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
          border: selected
              ? Border.all(color: AppColors.settingsAccent, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage(
              source: imageUrl,
              width: AppDimens.sdp(80),
              height: AppDimens.sdp(80),
              color: tintWhite ? AppColors.white : null,
              placeholderAsset:
                  isLeague ? 'assets/icons/ic_league.svg' : 'assets/icons/ic_ball.svg',
            ),
            SizedBox(height: AppDimens.sdp(8)),
            SizedBox(
              width: double.infinity,
              child: Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(12),
                  color: AppColors.text500,
                ).copyWith(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề chung của hai màn chọn: 17ssp bold, marginStart 20sdp,
/// marginTop 25sdp.
class PickTitle extends StatelessWidget {
  const PickTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: AppDimens.sdp(20),
          top: AppDimens.sdp(25),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            style: AppTextStyles.bold(
              size: AppDimens.ssp(17),
              color: AppColors.text500,
            ),
          ),
        ),
      );
}

/// Nút dưới cùng: 44dp, marginH 20sdp, marginBottom 12sdp,
/// `bg_btn_12sdp_ff783e`, chữ 17ssp bold viết hoa.
class PickBottomButton extends StatelessWidget {
  const PickBottomButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: AppDimens.sdp(20),
          right: AppDimens.sdp(20),
          bottom: AppDimens.sdp(12),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandAccent,
              borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
            ),
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.bold(
                size: AppDimens.ssp(17),
                color: AppColors.white,
              ),
            ),
          ),
        ),
      );
}
