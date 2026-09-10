import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Port `layout_shimmer_native_language.xml`.
///
/// **Chỉ dùng ở Splash.** Rà toàn bộ mã Kotlin thì `layout_shimmer_native_*`
/// chỉ được inflate đúng một chỗ là `SplashFragment`; bốn file shimmer còn lại
/// (`_full`, `_medium`, `_ob`, `_small`) không nơi nào gọi. Các placement khác
/// lúc đang tải thì để trống, không chiếm chỗ.
class NativeAdShimmer extends StatelessWidget {
  const NativeAdShimmer({super.key, this.height = 250});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.itemBg,
      highlightColor: const Color(0xFF2A2A30),
      child: Container(
        height: height,
        padding: EdgeInsets.all(AppDimens.sdp(10)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ô CTA giả trên cùng, khớp bố cục FULLSIZE_CTA_MEDIA_INFO của
            // placement splash.
            _Block(height: AppDimens.sdp(40), radius: AppDimens.sdp(10)),
            SizedBox(height: AppDimens.sdp(8)),
            Expanded(child: _Block(radius: AppDimens.sdp(6))),
            SizedBox(height: AppDimens.sdp(8)),
            Row(
              children: [
                _Block(
                  width: AppDimens.sdp(40),
                  height: AppDimens.sdp(40),
                  radius: AppDimens.sdp(6),
                ),
                SizedBox(width: AppDimens.sdp(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Block(height: AppDimens.sdp(12), radius: 3),
                      SizedBox(height: AppDimens.sdp(6)),
                      _Block(
                        height: AppDimens.sdp(10),
                        radius: 3,
                        widthFactor: 0.6,
                      ),
                    ],
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

class _Block extends StatelessWidget {
  const _Block({
    this.width,
    this.height,
    this.radius = 4,
    this.widthFactor,
  });

  final double? width;
  final double? height;
  final double radius;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (widthFactor == null) return block;
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: block,
    );
  }
}
