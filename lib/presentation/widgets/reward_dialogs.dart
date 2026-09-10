import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

/// Nền `bg_btn_cancel.xml` — `#3A3A3C`, bo 24dp.
const Color _btnCancel = Color(0xFF3A3A3C);

/// Nền `bg_btn_watch.xml` — `#2B7FFF`, bo 24dp.
const Color _btnWatch = Color(0xFF2B7FFF);

/// Port `presentation/dialog/RewardDialog.kt` + `dialog_reward.xml`:
/// nền `bg_dialog_reward` (color_item_bg, bo 24dp), padding 24dp, ảnh 120dp,
/// tiêu đề 20sp bold, mô tả 14sp, hai nút cao 48dp chia tỉ lệ 1 : 1.3.
class RewardDialog extends StatelessWidget {
  const RewardDialog({super.key, required this.onWatchNow});

  final VoidCallback onWatchNow;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onWatchNow,
  }) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => RewardDialog(onWatchNow: onWatchNow),
      );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/ic_dialog_reward.webp',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stack) => const SizedBox(
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.unlockDrawPrediction,
              textAlign: TextAlign.center,
              style: AppTextStyles.bold(size: 20, color: AppColors.text500),
            ),
            const SizedBox(height: 8),
            Text(
              s.watchAShortAdToSubmitYourDrawPrediction,
              textAlign: TextAlign.center,
              style: AppTextStyles.regular(size: 14, color: AppColors.text200),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: s.cancel,
                    background: _btnCancel,
                    textColor: AppColors.text500,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 13,
                  child: _DialogButton(
                    label: s.watchNow,
                    background: _btnWatch,
                    textColor: AppColors.white,
                    leading: SvgPicture.asset(
                      'assets/icons/ic_button_reward.svg',
                      width: 20,
                      height: 20,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onWatchNow();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cột phải có `layout_weight="1.3"` nên `Expanded` bên trái phải là 10.
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
    this.leading,
  });

  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bold(size: 16, color: textColor),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Port `RewardLoadingDialog.kt` + `dialog_reward_loading.xml`:
/// nền `bg_league_grid_item` (color_item_bg, bo 12sdp), paddingV 18sdp,
/// vòng quay 36sdp, tiêu đề 14ssp bold, mô tả 12ssp. Không cho bấm ra ngoài.
class RewardLoadingDialog extends StatelessWidget {
  const RewardLoadingDialog({super.key});

  /// Trả về hàm đóng dialog — gọi trong `onUserEarned` / `onDismiss` /
  /// `onUnavailable` giống `loadingDialog.dismiss()` của bản gốc.
  static VoidCallback show(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    var closed = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: RewardLoadingDialog(),
      ),
    );
    return () {
      if (closed) return;
      closed = true;
      if (navigator.canPop()) navigator.pop();
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(AppDimens.sdp(22)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(18)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: AppDimens.sdp(36),
              height: AppDimens.sdp(36),
              child: const CircularProgressIndicator(
                color: AppColors.brandAccent,
              ),
            ),
            SizedBox(height: AppDimens.sdp(12)),
            Text(
              s.loadingRewardAd,
              textAlign: TextAlign.center,
              style: AppTextStyles.bold(
                size: AppDimens.ssp(14),
                color: AppColors.text500,
              ),
            ),
            SizedBox(height: AppDimens.sdp(8)),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppDimens.sdp(16)),
              child: Text(
                s.loadingRewardAdMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(12),
                  color: AppColors.text100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Port `RewardNotAvailableDialog.kt` + `dialog_reward_not_available.xml`:
/// tiêu đề 20ssp bold, mô tả 13ssp, nút Retry `bg_btn_12sdp_ff783e` 20ssp,
/// nút Cancel `bg_btn_cancel` 18ssp.
class RewardNotAvailableDialog extends StatelessWidget {
  const RewardNotAvailableDialog({
    super.key,
    required this.onRetry,
    this.onCancel,
  });

  final VoidCallback onRetry;
  final VoidCallback? onCancel;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRetry,
    VoidCallback? onCancel,
  }) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) =>
            RewardNotAvailableDialog(onRetry: onRetry, onCancel: onCancel),
      );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(AppDimens.sdp(14)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: AppDimens.sdp(12),
                right: AppDimens.sdp(12),
                top: AppDimens.sdp(14),
              ),
              child: Text(
                s.rewardAdNotAvailable,
                textAlign: TextAlign.center,
                style: AppTextStyles.bold(
                  size: AppDimens.ssp(20),
                  color: AppColors.text500,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: AppDimens.sdp(12),
                right: AppDimens.sdp(12),
                top: AppDimens.sdp(8),
              ),
              child: Text(
                s.rewardAdNotAvailableMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(13),
                  color: AppColors.text500,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppDimens.sdp(16)),
              child: _WideButton(
                label: s.retry,
                background: AppColors.brandAccent,
                textColor: AppColors.white,
                fontSize: AppDimens.ssp(20),
                radius: AppDimens.sdp(12),
                onTap: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: AppDimens.sdp(16),
                right: AppDimens.sdp(16),
                bottom: AppDimens.sdp(16),
              ),
              child: _WideButton(
                label: s.cancel,
                background: _btnCancel,
                textColor: AppColors.text500,
                fontSize: AppDimens.ssp(18),
                radius: 24,
                onTap: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.fontSize,
    required this.radius,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color textColor;
  final double fontSize;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(8)),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Text(
            label,
            style: AppTextStyles.regular(size: fontSize, color: textColor),
          ),
        ),
      );
}
