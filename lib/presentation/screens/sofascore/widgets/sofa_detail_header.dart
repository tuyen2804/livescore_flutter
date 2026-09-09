import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';

/// Header 74sdp dùng chung cho `activity_sofascore_team_detail.xml` và
/// `activity_unique_tournament.xml`: back 30sdp · logo · (tên 15ssp +
/// hạng mục 10ssp) · widget phụ bên phải.
class SofaDetailHeader extends StatelessWidget {
  const SofaDetailHeader({
    super.key,
    required this.logoUrl,
    required this.title,
    this.subtitle,
    this.logoSize = 32,
    this.trailing,
  });

  final String? logoUrl;
  final String title;
  final String? subtitle;
  final double logoSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        height: AppDimens.sdp(74),
        color: AppColors.itemBg,
        padding: EdgeInsets.only(
          left: AppDimens.sdp(14),
          right: AppDimens.sdp(14),
          top: AppDimens.sdp(16),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: AppDimens.sdp(30),
                height: AppDimens.sdp(30),
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.sdp(2)),
                  child: SvgPicture.asset('assets/icons/ic_arrow_back.svg'),
                ),
              ),
            ),
            SizedBox(width: AppDimens.sdp(8)),
            AppImage(
              source: logoUrl,
              width: AppDimens.sdp(logoSize),
              height: AppDimens.sdp(logoSize),
              placeholderAsset: 'assets/icons/ic_league.svg',
            ),
            SizedBox(width: AppDimens.sdp(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.medium(
                      size: AppDimens.ssp(15),
                      color: AppColors.text500,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.regular(
                        size: AppDimens.ssp(10),
                        color: AppColors.text100,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: AppDimens.sdp(8)),
              trailing!,
            ],
          ],
        ),
      );
}

/// `TabLayout` cao 36sdp, `tabMode=fixed`, không gạch chỉ báo —
/// dùng ở màn chi tiết đội Sofascore.
class SofaFixedTabs extends StatelessWidget {
  const SofaFixedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        height: AppDimens.sdp(36),
        color: AppColors.background,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.medium(
                        size: AppDimens.ssp(12),
                        color: i == selected
                            ? AppColors.brandAccent
                            : AppColors.text200,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// Nút chọn mùa giải: nền `bg_border_radius_16_dark`, 11ssp, kèm mũi tên ▾.
class SeasonPickerButton extends StatelessWidget {
  const SeasonPickerButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.sdp(10),
            vertical: AppDimens.sdp(5),
          ),
          decoration: BoxDecoration(
            color: AppColors.itemBg,
            borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
          ),
          child: Text(
            '$label ▾',
            style: AppTextStyles.regular(
              size: AppDimens.ssp(11),
              color: AppColors.text500,
            ),
          ),
        ),
      );
}
