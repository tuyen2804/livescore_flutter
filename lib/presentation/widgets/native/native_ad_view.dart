import 'package:flutter/material.dart';

import '../../../core/ads/native/native_ad_controller.dart';
import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_layouts.dart';
import '../../../core/di/injection.dart';
import 'native_ad_shimmer.dart';

/// Chỗ đặt quảng cáo native dạng INLINE.
///
/// Quy tắc hiển thị (mục 8 của `docs/ADS_NATIVE_DESIGN.md`):
/// - **chỉ Splash mới có shimmer** khi đang tải — đặt [showShimmer] = true;
/// - các placement khác lúc đang tải thì **không chiếm chỗ** (`SizedBox.shrink`),
///   tải xong mới chèn vào, tránh giật layout.
///
/// Widget không tự nạp quảng cáo: [NativeAdManager.preload] phải được gọi
/// từ màn trước đó. Nếu chưa có sẵn thì nó gọi preload một lần cho chắc.
class NativeAdView extends StatefulWidget {
  const NativeAdView({
    super.key,
    required this.placement,
    this.showShimmer = false,
    this.height,
    this.margin,
  });

  final String placement;

  /// Chỉ bật ở Splash.
  final bool showShimmer;

  /// Bỏ trống thì lấy chiều cao gợi ý của layout.
  final double? height;
  final EdgeInsets? margin;

  @override
  State<NativeAdView> createState() => _NativeAdViewState();
}

class _NativeAdViewState extends State<NativeAdView> {
  NativeAdController? _controller;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant NativeAdView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) _attach();
  }

  void _attach() {
    final manager = sl<NativeAdManager>();
    final controller = manager.controllerOf(widget.placement);
    setState(() => _controller = controller);
    // Màn trước lẽ ra đã preload; đây chỉ là lưới an toàn.
    if (controller != null && !controller.hasAd) {
      manager.preload(widget.placement);
    }
  }

  @override
  void dispose() {
    // Không dispose controller: manager giữ nó để dùng lại ở màn khác.
    _controller?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return ValueListenableBuilder<NativeAdState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        switch (state) {
          case NativeAdState.idle:
          case NativeAdState.failed:
            return const SizedBox.shrink();
          case NativeAdState.loading:
            return widget.showShimmer
                ? Padding(
                    padding: widget.margin ?? EdgeInsets.zero,
                    child: NativeAdShimmer(height: widget.height ?? 330),
                  )
                : const SizedBox.shrink();
          case NativeAdState.loaded:
            return _buildAds(controller);
        }
      },
    );
  }

  Widget _buildAds(NativeAdController controller) {
    return ValueListenableBuilder<List<LoadedNativeAd?>>(
      valueListenable: controller.ads,
      builder: (context, ads, _) {
        final loaded = ads.whereType<LoadedNativeAd>().toList();
        if (loaded.isEmpty) return const SizedBox.shrink();

        // INLINE chỉ hiện quảng cáo đầu tiên; nhiều slot là chuyện của
        // fullscreen và collapsible.
        final first = loaded.first;
        final height = widget.height ??
            NativeLayouts.preferredHeight(first.layout) ??
            330;

        // Báo cho controller biết ad đã lên màn hình để bắt đầu đếm
        // AUTO_INTERVAL — tài liệu v12 yêu cầu chỉ đếm khi đang hiển thị.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) controller.notifyShown();
        });

        return Padding(
          padding: widget.margin ?? EdgeInsets.zero,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: first.widget,
          ),
        );
      },
    );
  }
}
