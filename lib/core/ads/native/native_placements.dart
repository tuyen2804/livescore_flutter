/// Tên placement native — phải khớp 1-1 với khoá trong `placement_config`
/// và với `AdsUnitId` của bản Kotlin.
class NativePlacements {
  const NativePlacements._();

  static const String splash = 'LiveScore_native_splash';
  static const String language1 = 'LiveScore_native_LGF_1';
  static const String language2 = 'LiveScore_native_LGF_2';
  static const String loading = 'LiveScore_native_Loading';

  static const String onboarding1 = 'LiveScore_native_OB';
  static const String onboarding2 = 'LiveScore_native_OB2';
  static const String onboarding3 = 'LiveScore_native_OB3';

  /// Fullscreen một quảng cáo (1 slot, 2 id là high-floor + thường).
  static const String fullscreen = 'LiveScore_native_fullscreen';

  /// Fullscreen hai quảng cáo cùng lúc (2 slot) + chuỗi nút giả.
  static const String fullscreenInter = 'LiveScore_native_fullscreen_2';

  static const String choose1 = 'LiveScore_native_Choose1';
  static const String choose2 = 'LiveScore_native_Choose2';
  static const String noAds = 'LiveScore_native_noads';

  static const String inApp = 'LiveScore_native_Inapp';
  static const String inAppNew = 'LiveScore_native_Inapp_New';

  /// Native thu gọn ở đáy Main.
  static const String collapHome = 'collap_home';
}
