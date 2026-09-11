import 'package:flutter/material.dart';

import '../../../core/ads/native/native_ad_controller.dart';
import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_layouts.dart';
import '../../../core/di/injection.dart';
import 'button_sequence.dart';

/// Quảng cáo native toàn màn — dùng cho `LiveScore_native_fullscreen` và
/// `LiveScore_native_fullscreen_2`.
///
/// Quy tắc slot (mục 5.1 của doc):
/// - **1 slot** → một quảng cáo chiếm cả màn;
/// - **2 slot** → hai quảng cáo chia đôi màn theo layout `_DUAL_`.
///
/// Chuỗi nút lấy từ `button_sequence` của union, chạy bằng
/// [ButtonSequenceRunner].
class NativeFullscreenOverlay extends StatefulWidget {
  const NativeFullscreenOverlay({super.key, required this.placement});

  final String placement;

  /// Mở dạng route toàn màn. Trả về khi user đóng.
  ///
  /// Không có quảng cáo sẵn thì trả về ngay, **không chặn luồng** — bên gọi cứ
  /// đi tiếp bình thường.
  static Future<void> show(BuildContext context, String placement) async {
    final controller = sl<NativeAdManager>().controllerOf(placement);
    if (controller == null || !controller.hasAd) return;
    if (!context.mounted) return;

    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) =>
            NativeFullscreenOverlay(placement: placement),
      ),
    );
  }

  @override
  State<NativeFullscreenOverlay> createState() =>
      _NativeFullscreenOverlayState();
}

class _NativeFullscreenOverlayState extends State<NativeFullscreenOverlay> {
  late final NativeAdController? _controller = sl<NativeAdManager>()
      .controllerOf(widget.placement);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller?.notifyShown();
    });
  }

  bool _closed = false;

  void _close() {
    // Chỉ đóng một lần: nhánh "quảng cáo biến mất" có thể gọi lại sau khi đã
    // đóng, pop thêm lần nữa sẽ đóng luôn màn bên dưới.
    if (_closed || !mounted) return;
    _closed = true;
    _controller?.notifyDismissed();
    // pop() chứ không phải maybePop(): route này tự chặn back bằng
    // PopScope(canPop: false), mà maybePop() tôn trọng PopScope nên không
    // bao giờ đóng được.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    final union = controller.placement.firstUnion;
    final steps = union?.buttonSequence ?? const [];

    return PopScope(
      // Chỉ đóng được qua nút CLOSE trong chuỗi, đúng như bản gốc.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ValueListenableBuilder<List<LoadedNativeAd?>>(
            valueListenable: controller.ads,
            builder: (context, ads, _) {
              final loaded = ads.whereType<LoadedNativeAd>().toList();
              if (loaded.isEmpty) {
                // Quảng cáo biến mất giữa chừng — đóng cho khỏi treo màn.
                WidgetsBinding.instance.addPostFrameCallback((_) => _close());
                return const SizedBox.shrink();
              }

              return Stack(
                children: [
                  Positioned.fill(child: _buildAds(loaded)),
                  if (steps.isNotEmpty)
                    Positioned.fill(
                      child: ButtonSequenceRunner(
                        steps: steps,
                        onClose: _close,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Một quảng cáo thì chiếm cả màn; hai quảng cáo thì chia đôi theo chiều
  /// dọc — `FULLSCREEN_PORT_DUAL_MIRROR` lật ngược nửa dưới cho đối xứng.
  Widget _buildAds(List<LoadedNativeAd> loaded) {
    if (loaded.length == 1) {
      return loaded.first.widget;
    }

    final mirrored =
        NativeLayouts.isDual(loaded.first.layout) &&
        loaded.first.layout.contains('MIRROR');

    return Column(
      children: [
        for (var i = 0; i < loaded.length; i++)
          Expanded(
            child: mirrored && i.isOdd
                ? Transform.flip(flipY: true, child: loaded[i].widget)
                : loaded[i].widget,
          ),
      ],
    );
  }
}
