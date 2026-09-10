import 'native_placement.dart';

/// Năm layout mà `placement_config.json` thật sự trỏ tới, cộng một layout mặc
/// định cho placement fullscreen không khai `layout`.
///
/// Quy ước tên (mục 6.1 của doc):
/// - tên chứa `DUAL` → khung chứa **2 quảng cáo**, layout riêng của từng ad
///   lấy từ `slots[].layout`;
/// - `FULLSCREEN_PORT_...` không có `DUAL` → **1 quảng cáo** toàn màn.
class NativeLayouts {
  const NativeLayouts._();

  static const String fullsizeCtaMediaInfo = 'FULLSIZE_CTA_MEDIA_INFO';
  static const String fullsizeInfoMediaCta = 'FULLSIZE_INFO_MEDIA_CTA';
  static const String smallBannerInfo2Cta = 'SMALL_BANNER_INFO2CTA';
  static const String smallBannerIcon2Media2Info =
      'SMALL_BANNER_ICON2MEDIA2INFO';
  static const String fullscreenPortMediaInfoCta =
      'FULLSCREEN_PORT_MEDIA_INFO_CTA';
  static const String fullscreenPortDualMirror = 'FULLSCREEN_PORT_DUAL_MIRROR';

  /// Ánh xạ sang `factoryId` đăng ký bên Android/iOS. Layout `DUAL` chỉ là
  /// **khung chứa**, từng ad bên trong vẫn vẽ bằng factory một-ad.
  static const Map<String, String> _factoryIds = {
    fullsizeCtaMediaInfo: 'ctaMediaInfo',
    fullsizeInfoMediaCta: 'infoMediaCta',
    smallBannerInfo2Cta: 'bannerInfoCta',
    smallBannerIcon2Media2Info: 'bannerIconMediaInfo',
    fullscreenPortMediaInfoCta: 'fullscreenMediaInfoCta',
    // Mỗi nửa của DUAL vẽ như một fullscreen thường.
    fullscreenPortDualMirror: 'fullscreenMediaInfoCta',
  };

  /// Chuẩn hoá tên layout; thiếu thì chọn mặc định theo [type].
  static String resolve(String? raw, PlacementType type) {
    final name = raw?.trim().toUpperCase();
    if (name != null && _factoryIds.containsKey(name)) return name;
    return type == PlacementType.fullscreen
        ? fullscreenPortMediaInfoCta
        : fullsizeCtaMediaInfo;
  }

  static String factoryIdOf(String layout) =>
      _factoryIds[layout] ?? _factoryIds[fullsizeCtaMediaInfo]!;

  /// true = layout dựng cho **hai** quảng cáo cạnh nhau.
  static bool isDual(String layout) => layout.contains('DUAL');

  /// Chiều cao cấp cho khung chứa (dp).
  ///
  /// Platform view **không tự báo kích thước** về Flutter, nên không có
  /// "wrap content" thật. Layout bên native để `wrap_content` — bắt buộc, vì
  /// plugin gọi `LayoutInflater.inflate(layout, null)`, root mất LayoutParams
  /// nên `match_parent` không có tác dụng, và `match_parent` ở lớp trong sẽ
  /// cho ra chiều cao 0 (ô quảng cáo trắng bảng).
  ///
  /// Vậy nên số dưới đây phải **lớn hơn hoặc bằng** chiều cao thật của XML,
  /// tính tay từ chính file layout:
  ///
  /// - banner icon+media+info: padding 6×2 + hàng 34 ≈ 50
  /// - banner info+CTA: padding 10×2 + icon 40 + nhãn Ad ≈ 90
  /// - full: padding 10×2 + nhãn 16 + CTA 48 + ảnh 180 + hàng icon 40
  ///   + 3 khoảng cách 8 ≈ 330
  static double? preferredHeight(String layout) => switch (layout) {
        smallBannerIcon2Media2Info => 56,
        smallBannerInfo2Cta => 90,
        fullsizeCtaMediaInfo || fullsizeInfoMediaCta => 330,
        _ => null,
      };
}
