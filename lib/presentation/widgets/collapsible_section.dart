import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_image.dart';

/// Tiêu đề nhóm gập được, dùng chung cho danh sách trận ở màn giải và màn đội.
///
/// Dựng theo đúng kiểu thẻ giải ở Home (`home_league_card.dart`): logo bên
/// trái, tên nhóm, số trận, mũi tên xoay 180° khi mở.
///
/// Trạng thái gập nằm ở widget cha — danh sách thường nằm trong `ListView` và
/// bị dựng lại khi cuộn, giữ trạng thái tại chỗ là mở xong cuộn đi cuộn lại nó
/// tự đóng.
class CollapsibleSectionHeader extends StatelessWidget {
  const CollapsibleSectionHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onTap,
    this.subtitle,
    this.logoUrl,
    this.logoAsset,
    this.count,
  });

  final String title;
  final String? subtitle;
  final String? logoUrl;

  /// Dùng khi nhóm không có logo riêng (ví dụ "Đã diễn ra" / "Sắp diễn ra").
  final String? logoAsset;

  /// Số trận trong nhóm; bỏ trống thì không hiện.
  final int? count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.sdp(12),
          vertical: AppDimens.sdp(10),
        ),
        child: Row(
          children: [
            if (logoUrl != null || logoAsset != null) ...[
              AppImage(
                source: logoUrl,
                width: AppDimens.sdp(20),
                height: AppDimens.sdp(20),
                placeholderAsset: logoAsset ?? 'assets/icons/ic_league.svg',
              ),
              SizedBox(width: AppDimens.sdp(8)),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.semiBold(
                      size: AppDimens.ssp(12),
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
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (count != null) ...[
              SizedBox(width: AppDimens.sdp(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.sdp(7),
                  vertical: AppDimens.sdp(2),
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppDimens.sdp(8)),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.medium(
                    size: AppDimens.ssp(10),
                    color: AppColors.brandAccent,
                  ),
                ),
              ),
            ],
            SizedBox(width: AppDimens.sdp(8)),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: AppDimens.sdp(20),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
