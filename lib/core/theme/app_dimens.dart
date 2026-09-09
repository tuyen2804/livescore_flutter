import 'package:flutter/widgets.dart';

/// Thay cho `sdp`/`ssp` của bản Android: quy đổi kích thước theo bề rộng màn
/// hình, lấy 360dp làm mốc thiết kế (đúng bucket mà bản gốc dùng).
class AppDimens {
  const AppDimens._();

  static const double designWidth = 360.0;
  static double _scale = 1.0;
  static double _textScale = 1.0;

  static void init(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.width < size.height ? size.width : size.height;
    _scale = (shortest / designWidth).clamp(0.85, 1.35);
    _textScale = (shortest / designWidth).clamp(0.90, 1.20);
  }

  /// Tương đương `@dimen/_Nsdp`.
  static double sdp(double value) => value * _scale;

  /// Tương đương `@dimen/_Nssp`.
  static double ssp(double value) => value * _textScale;

  static double get scale => _scale;
}

extension AppDimensX on num {
  double get sdp => AppDimens.sdp(toDouble());
  double get ssp => AppDimens.ssp(toDouble());
}
