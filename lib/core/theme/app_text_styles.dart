import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Port của `styles.xml`: 4 nhóm chữ Bold / SemiBold / Medium / Regular.
class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Gilroy';

  static TextStyle _base(FontWeight weight, double size, Color color) =>
      TextStyle(
        fontFamily: fontFamily,
        fontWeight: weight,
        fontSize: size,
        color: color,
        height: 1.2,
      );

  static TextStyle bold({double size = 14, Color color = AppColors.textPrimary}) =>
      _base(FontWeight.w700, size, color);

  static TextStyle semiBold({double size = 14, Color color = AppColors.textPrimary}) =>
      _base(FontWeight.w600, size, color);

  static TextStyle medium({double size = 14, Color color = AppColors.textPrimary}) =>
      _base(FontWeight.w500, size, color);

  static TextStyle regular({double size = 14, Color color = AppColors.textPrimary}) =>
      _base(FontWeight.w400, size, color);
}
