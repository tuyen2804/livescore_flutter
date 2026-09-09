import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// `Theme.LiveScoreTest` — nền tối, accent cam #FFA600.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgApp : AppColors.surface0;
    final surface = isDark ? AppColors.itemBg : AppColors.surface1;
    final onSurface = isDark ? AppColors.textPrimary : AppColors.sofaTextPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandAccent,
        brightness: brightness,
      ).copyWith(
        primary: AppColors.brandAccent,
        secondary: AppColors.colorBlue,
        surface: surface,
        onSurface: onSurface,
        error: AppColors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: AppTextStyles.semiBold(size: 18, color: onSurface),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.divider : AppColors.sofaDivider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandAccent,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brandAccent,
        selectionHandleColor: AppColors.brandAccent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brandAccent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.brandAccent,
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.semiBold(size: 14),
        unselectedLabelStyle: AppTextStyles.medium(size: 14),
      ),
    );
  }
}
