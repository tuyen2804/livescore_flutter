import 'package:flutter/material.dart';

/// Bảng màu port 1:1 từ `res/values/colors.xml` của bản Android.
class AppColors {
  const AppColors._();

  // ---- Nền & bề mặt ----
  static const Color bgApp = Color(0xFF000000);
  static const Color background = Color(0xFF000000);
  static const Color itemBg = Color(0xFF1F1E23);
  static const Color grayBg = Color(0xFF1F1E23);
  static const Color color0f = Color(0xFF0F0F0F);
  static const Color color010103 = Color(0xFF010103);
  static const Color color1e232e = Color(0xFF1E232E);

  static const Color surface0 = Color(0xFFF5F5F7);
  static const Color surface1 = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFEFEFF2);

  // ---- Thương hiệu ----
  static const Color brandAccent = Color(0xFFFFA600);
  static const Color brandAccent20 = Color(0x3375C948);
  static const Color colorPrimary = brandAccent;
  static const Color ff783e = brandAccent;
  static const Color settingsAccent = brandAccent;
  static const Color liveColor = brandAccent;
  static const Color colorBlue = Color(0xFF5C33F4);

  // ---- Chữ ----
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA5A7AB);
  static const Color text100 = Color(0xFFD2D3D5);
  static const Color text200 = Color(0xFFA5A7AB);
  static const Color text400 = Color(0xFF4B4F58);
  static const Color text500 = Color(0xFFFFFFFF);
  static const Color colorA5a7ab = Color(0xFFA5A7AB);
  static const Color colorD2d3d5 = Color(0xFFD2D3D5);

  // ---- Đường kẻ / viền ----
  static const Color divider = Color(0x1AFFFFFF);
  static const Color divider200 = Color(0x26FFFFFF);
  static const Color borderColor = Color(0x26CFCFFC);

  // ---- Trạng thái ----
  static const Color red = Color(0xFFFF453A);
  static const Color homeColor = Color(0xFF4CAF50);
  static const Color drawColor = Color(0xFFFF9800);
  static const Color awayColor = Color(0xFFF44336);
  static const Color color819c3e = Color(0xFF819C3E);
  static const Color colorFec93e = Color(0xFFFEC93E);
  static const Color textVenue = Color(0x60C8F558);

  // ---- Xám ----
  static const Color gray2 = Color(0xFF636366);
  static const Color gray5 = Color(0xFF2C2C2E);
  static const Color gray6 = Color(0xFFC6C6C6);
  static const Color gray7e = Color(0xFF7E7E7E);
  static const Color grayF5f5f5 = Color(0xFFF5F5F5);
  static const Color grayD1d3d4 = Color(0xFFD1D3D4);
  static const Color btnCancel = Color(0xFF3A3A3C);
  static const Color settingsBackground = Color(0xFFF8F8F8);

  // ---- Palette Sofascore (các môn ngoài bóng đá) ----
  static const Color sofaBlue = Color(0xFF374DF5);
  static const Color sofaBlueDark = Color(0xFF2C3EC4);
  static const Color sofaBlueLight = Color(0x1F374DF5);
  static const Color sofaBgLight = Color(0xFFF0F4F8);
  static const Color sofaCardBg = Color(0xFFFFFFFF);
  static const Color sofaDivider = Color(0xFFE2E8F0);
  static const Color sofaLiveRed = Color(0xFFFF364E);
  static const Color sofaLiveRedLight = Color(0x1AFF364E);
  static const Color sofaFinishedGrey = Color(0xFF70757A);
  static const Color sofaFinishedGreyLight = Color(0xFFF1F3F4);
  static const Color sofaTextPrimary = Color(0xFF1C1E21);
  static const Color sofaTextSecondary = Color(0xFF65676B);
  static const Color sofaTextMuted = Color(0xFF9A9C9E);

  // ---- Màu lấy thẳng từ drawable của bản gốc ----
  /// `color/tab_text_color.xml` — tab chưa chọn ở bottom nav.
  static const Color tabInactive = Color(0xFF64748B);

  /// `bg_radius_16_0f.xml` — nền badge phút thi đấu ở thẻ live.
  static const Color liveTimeBadge = Color(0xFF09CC3D);

  /// `ic_noti_select.xml` / `ic_noti_unselect.xml`.
  static const Color notiSelected = Color(0xFFFFD036);
  static const Color notiUnselected = Color(0xFF6B7280);

  /// `n_lv_1` / `n_lv_3` — chữ trên nền sáng của thẻ cricket.
  static const Color nLv1 = Color(0xFF222226);
  static const Color nLv3 = Color(0xFF8B8B94);

  /// Màu chữ/điểm thẻ cricket khi đang đánh (`#D71920`) và bình thường.
  static const Color cricketLive = Color(0xFFD71920);
  static const Color cricketNormal = Color(0xFF1C1E21);
  static const Color cricketDescription = Color(0xFF9B9FA5);

  /// `bg_sport_selector_pill.xml` — nền 10% của accent.
  static const Color sportPillFill = Color(0x1AFFA600);

  /// `ic_expand.xml`.
  static const Color expandArrow = Color(0xFF747474);

  // ---- Tiện ích ----
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
