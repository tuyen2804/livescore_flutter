import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Chiều cao thật của từng quảng cáo native, do phía native đo rồi báo lên.
///
/// Platform view không tự báo kích thước cho Flutter, nên factory Android/iOS
/// đo nội dung theo chiều rộng màn hình (ad luôn full chiều rộng) ngay lúc
/// dựng view — plugin gọi factory **trước** khi báo `onAdLoaded`, nên chiều
/// cao về tới đây trước khi ad được hiện. Mỗi `NativeAd` mang một `slot_id`
/// trong `customOptions` để khớp cặp.
class NativeAdHeights {
  NativeAdHeights._();

  static const MethodChannel _channel = MethodChannel(
    'live_score/native_ad_height',
  );

  /// Khoá trong `customOptions` gửi xuống factory native.
  static const String slotIdKey = 'slot_id';

  static final Map<String, ValueNotifier<double?>> _heights = {};
  static final ValueNotifier<double?> _none = ValueNotifier<double?>(null);
  static int _nextId = 0;
  static bool _listening = false;

  /// Cấp id cho một `NativeAd` sắp nạp và bảo đảm đã nghe kênh.
  static String newSlotId() {
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler(handleCall);
    }
    final id = 'native_${_nextId++}';
    _heights[id] = ValueNotifier<double?>(null);
    return id;
  }

  /// null = native chưa báo, dùng chiều cao mặc định của layout.
  static ValueListenable<double?> listenable(String slotId) =>
      _heights[slotId] ?? _none;

  /// Gọi khi `NativeAd` bị huỷ.
  static void remove(String slotId) => _heights.remove(slotId)?.dispose();

  @visibleForTesting
  static Future<void> handleCall(MethodCall call) async {
    if (call.method != 'height') return;
    final args = Map<Object?, Object?>.from(call.arguments as Map);
    final id = args[slotIdKey] as String?;
    final height = (args['height'] as num?)?.toDouble();
    if (id == null || height == null || height <= 0) return;
    // Ad đã huỷ (hết giờ, nạp lại) thì bỏ qua.
    _heights[id]?.value = height;
  }
}
