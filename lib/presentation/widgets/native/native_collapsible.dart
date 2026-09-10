import 'package:flutter/material.dart';

import '../../../core/ads/native/native_ad_controller.dart';
import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_layouts.dart';
import '../../../core/di/injection.dart';
import 'button_sequence.dart';

/// Native thu gọn được ở đáy Main — port `collap_home`.
///
/// Placement này có **2 slot trong cùng một union**:
/// - `slots[0]` layout `FULLSIZE_INFO_MEDIA_CTA` — trạng thái **mở**;
/// - `slots[1]` layout `SMALL_BANNER_INFO2CTA` — trạng thái **thu gọn**.
///
/// `button_sequence` của nó là `COUNTDOWN 2s → COLLAPSE (chevron xuống)`:
/// đếm ngược xong mới hiện nút thu nhỏ.
class NativeCollapsible extends StatefulWidget {
  const NativeCollapsible({super.key, required this.placement});

  final String placement;

  @override
  State<NativeCollapsible> createState() => _NativeCollapsibleState();
}

class _NativeCollapsibleState extends State<NativeCollapsible> {
  late final NativeAdController? _controller =
      sl<NativeAdManager>().controllerOf(widget.placement);

  bool _collapsed = false;

  @override
  void dispose() {
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
        if (state != NativeAdState.loaded) return const SizedBox.shrink();
        return _buildAd(controller);
      },
    );
  }

  Widget _buildAd(NativeAdController controller) {
    return ValueListenableBuilder<List<LoadedNativeAd?>>(
      valueListenable: controller.ads,
      builder: (context, ads, _) {
        // Slot 0 = mở, slot 1 = thu gọn. Thiếu slot nào thì dùng slot còn lại.
        final expanded = ads.isNotEmpty ? ads[0] : null;
        final small = ads.length > 1 ? ads[1] : null;
        final current = _collapsed ? (small ?? expanded) : (expanded ?? small);
        if (current == null) return const SizedBox.shrink();

        final height = NativeLayouts.preferredHeight(current.layout) ?? 80;
        final union = controller.placement.firstUnion;
        final steps = union?.buttonSequence ?? const [];
        final alpha = controller.placement.bgAlpha ?? 1.0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) controller.notifyShown();
        });

        return Opacity(
          opacity: alpha,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: current.widget),
                // Chuỗi nút chỉ chạy ở trạng thái mở; thu gọn rồi thì thôi.
                if (steps.isNotEmpty && !_collapsed && small != null)
                  Positioned.fill(
                    child: ButtonSequenceRunner(
                      steps: steps,
                      onClose: () => setState(() => _collapsed = true),
                      onCollapse: () => setState(() => _collapsed = true),
                    ),
                  ),
                // Thu gọn rồi thì cho mở lại bằng một nút nhỏ.
                if (_collapsed && expanded != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => setState(() => _collapsed = false),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xB3000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
