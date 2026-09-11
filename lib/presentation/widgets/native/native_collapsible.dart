import 'package:flutter/material.dart';

import '../../../core/ads/native/native_ad_controller.dart';
import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_layouts.dart';
import '../../../core/di/injection.dart';
import 'button_sequence.dart';

/// Hai nửa của `collap_home`. Chúng nằm ở **hai chỗ khác nhau** trong cây
/// widget nên phải là hai widget riêng, dùng chung trạng thái thu gọn lưu ở
/// [NativeAdController.collapsed].
enum CollapsibleSlot {
  /// `slots[0]` — bản mở, **đè lên nội dung và cả thanh điều hướng**.
  expanded,

  /// `slots[1]` — banner nhỏ, **nằm dưới thanh điều hướng**.
  small,
}

/// Chiều cao dải `frAds` trong `fragment_main.xml`: `android:layout_height="50dp"`.
///
/// Đây là dp thật, không phải sdp — XML ghi thẳng `50dp` chứ không dùng
/// `@dimen/_50sdp`, nên không co giãn theo kích thước màn.
const double kCollapSmallHeight = 50;

/// Native thu gọn được — port `collap_home`.
///
/// Bảng monetization: *"Ads native collap hiện ở dưới cùng các màn feature […]
/// 2 layer 2 ID ads: Layer Collap (Expand như một native to, có nút đóng
/// xuống) + Layer Small (native nhỏ bên dưới)"*.
///
/// Vị trí đúng ở màn Home:
/// - **small** nằm **dưới** thanh điều hướng, chiếm chỗ thật;
/// - **expanded** **đè lên** nội dung, kể cả thanh điều hướng.
///
/// Vì vậy không thể nhét cả hai vào một chỗ: [CollapsibleSlot.small] đặt trong
/// `bottomNavigationBar` (sau thanh nav), còn [CollapsibleSlot.expanded] đặt
/// trong một `Stack` bọc ngoài `Scaffold`.
class NativeCollapsible extends StatefulWidget {
  const NativeCollapsible({
    super.key,
    required this.placement,
    required this.slot,
  });

  final String placement;
  final CollapsibleSlot slot;

  @override
  State<NativeCollapsible> createState() => _NativeCollapsibleState();
}

class _NativeCollapsibleState extends State<NativeCollapsible> {
  late final NativeAdController? _controller = sl<NativeAdManager>()
      .controllerOf(widget.placement);

  @override
  void dispose() {
    // Chỉ nửa mở mới điều khiển đồng hồ; nửa nhỏ rời cây không nên dừng.
    if (widget.slot == CollapsibleSlot.expanded) _controller?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: controller.collapsed,
      builder: (context, collapsed, _) {
        // Nửa nào không đúng trạng thái thì biến mất hẳn, không giữ chỗ.
        final visible = widget.slot == CollapsibleSlot.small
            ? collapsed
            : !collapsed;
        if (!visible) return const SizedBox.shrink();

        return ValueListenableBuilder<NativeAdState>(
          valueListenable: controller.state,
          builder: (context, state, _) {
            if (state != NativeAdState.loaded) return const SizedBox.shrink();
            return _buildAd(controller);
          },
        );
      },
    );
  }

  Widget _buildAd(NativeAdController controller) {
    return ValueListenableBuilder<List<LoadedNativeAd?>>(
      valueListenable: controller.ads,
      builder: (context, ads, _) {
        final expanded = ads.isNotEmpty ? ads[0] : null;
        final small = ads.length > 1 ? ads[1] : null;
        // Thiếu slot nào thì dùng slot còn lại, đỡ mất luôn quảng cáo.
        final current = widget.slot == CollapsibleSlot.small
            ? (small ?? expanded)
            : (expanded ?? small);
        if (current == null) return const SizedBox.shrink();

        // Nửa nhỏ bị `frAds` khoá ở 50dp — bản gốc cắt luôn phần thừa. Nửa mở
        // thì cao bao nhiêu tuỳ layout.
        final height = widget.slot == CollapsibleSlot.small
            ? kCollapSmallHeight
            : NativeLayouts.preferredHeight(current.layout) ?? 90;
        final union = controller.placement.firstUnion;
        final steps = union?.buttonSequence ?? const [];
        final alpha = controller.placement.bgAlpha ?? 1.0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) controller.notifyShown();
        });

        final content = Stack(
          children: [
            Positioned.fill(child: current.widget),
            // Chuỗi nút (COUNTDOWN → COLLAPSE) chỉ ở bản mở, và chỉ khi thật
            // sự có bản nhỏ để thu về.
            if (widget.slot == CollapsibleSlot.expanded &&
                steps.isNotEmpty &&
                small != null)
              Positioned.fill(
                child: ButtonSequenceRunner(
                  steps: steps,
                  onClose: () => controller.collapsed.value = true,
                  onCollapse: () => controller.collapsed.value = true,
                ),
              ),
          ],
        );

        return Opacity(
          opacity: alpha,
          // Bản mở đè lên thanh điều hướng nên phải có nền đục, không thì
          // nhìn xuyên thấy nav bar bên dưới.
          child: Material(
            color: widget.slot == CollapsibleSlot.expanded
                ? Colors.black
                : Colors.transparent,
            child: SizedBox(
              height: height,
              child: widget.slot == CollapsibleSlot.small
                  ? ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        maxHeight:
                            NativeLayouts.preferredHeight(current.layout) ??
                            height,
                        child: content,
                      ),
                    )
                  : content,
            ),
          ),
        );
      },
    );
  }
}
