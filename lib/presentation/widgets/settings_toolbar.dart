import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

/// Thanh tiêu đề 74sdp dùng chung cho Settings / Notification / LiveMatches:
/// nền `color_item_bg`, back 30sdp (marginStart 14sdp, marginTop 25sdp,
/// padding 2sdp), tiêu đề 18ssp bold căn giữa với `marginEnd 40sdp`,
/// và chỗ tuỳ chọn cho nút bên phải.
class SettingsToolbar extends StatelessWidget {
  const SettingsToolbar({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Container(
        height: AppDimens.sdp(74),
        width: double.infinity,
        color: AppColors.itemBg,
        padding: EdgeInsets.only(
          top: AppDimens.sdp(25),
          left: AppDimens.sdp(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: AppDimens.sdp(30),
                height: AppDimens.sdp(30),
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.sdp(2)),
                  child: SvgPicture.asset('assets/icons/ic_arrow_back.svg'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: AppDimens.sdp(3),
                  right: trailing == null ? AppDimens.sdp(40) : 0,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bold(
                    size: AppDimens.ssp(18),
                    color: AppColors.text500,
                  ),
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: EdgeInsets.only(
                  top: AppDimens.sdp(1),
                  right: AppDimens.sdp(12),
                ),
                child: trailing,
              ),
          ],
        ),
      );
}
