import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import '../error/failures.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Khối shimmer thay cho `com.facebook.shimmer.ShimmerFrameLayout`.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.itemBg,
        highlightColor: AppColors.gray5,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.itemBg,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      );
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.brandAccent,
          ),
        ),
      );
}

/// Port `layoutNoData`: `ic_empty` 120sdp + dòng chữ 14ssp `text_secondary`
/// cách 10sdp, tất cả căn giữa.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.message,
    this.icon,
    this.action,
  });

  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, size: 48, color: AppColors.textSecondary)
              else
                SvgPicture.asset(
                  'assets/icons/ic_empty.svg',
                  width: AppDimens.sdp(120),
                  height: AppDimens.sdp(120),
                ),
              SizedBox(height: AppDimens.sdp(10)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.semiBold(
                  size: AppDimens.ssp(14),
                  color: AppColors.textSecondary,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      );
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isNetwork = failure is NetworkFailure || failure is TimeoutFailure;
    return AppEmptyView(
      icon: isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      message: failure.message,
      action: onRetry == null
          ? null
          : TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandAccent,
                side: const BorderSide(color: AppColors.brandAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Retry', style: AppTextStyles.semiBold(size: 14)),
            ),
    );
  }
}

/// Nút chính màu accent — port `bg_btn_12sdp_ff783e`.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 44,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: Material(
          color: enabled ? AppColors.brandAccent : AppColors.btnCancel,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.semiBold(size: 15, color: AppColors.white),
              ),
            ),
          ),
        ),
      );
}
