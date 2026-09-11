import Flutter
import Foundation
import GoogleMobileAds
import google_mobile_ads
import UIKit

/// Dựng view cho native ad trên iOS. Mỗi layout trong `placement_config` ứng
/// với một factoryId đăng ký ở đây — factoryId phải khớp `NativeLayouts` bên
/// Dart (`lib/core/ads/native/native_layouts.dart`).
///
/// Bố cục dựng bằng code chứ không dùng xib: 5 layout đều là stack dọc/ngang
/// đơn giản, viết tay dễ đối chiếu với XML bên Android hơn là mở Interface
/// Builder.
///
/// Style đến từ Dart qua `customOptions`, đã gọt còn 5 khoá:
/// `bg_color`, `headline_color`, `body_color`, `headline_text_size_sp`,
/// `cta_shape`. Màu là Int ARGB.
/// SDK Google Mobile Ads bỏ tiền tố `GAD` cho Swift từ v12; dự án đang dùng
/// `Google-Mobile-Ads-SDK ~> 13.7` nên tên mới. **Nếu build trên Mac báo không
/// tìm thấy kiểu, chỉ cần đổi ba dòng typealias này về `GADNativeAd`,
/// `GADNativeAdView`, `GADMediaView`.**
typealias AdNativeAd = NativeAd
typealias AdNativeAdView = NativeAdView
typealias AdMediaView = MediaView

class LiveScoreNativeAdFactory: NSObject, FLTNativeAdFactory {

    enum Layout: CaseIterable {
        /// CTA trên → media → icon + tiêu đề + mô tả
        case ctaMediaInfo
        /// Thông tin trên → media → CTA dưới
        case infoMediaCta
        /// Media trên → thông tin → CTA dưới (bảng iOS: "Media - Info - CTA")
        case mediaInfoCta
        /// Icon + 2 dòng chữ, CTA bên phải (~80pt)
        case bannerInfoCta
        /// Icon → media nhỏ → chữ (~50pt)
        case bannerIconMediaInfo
        /// Media lớn → info → CTA, chiếm cả màn
        case fullscreenMediaInfoCta
    }

    private let layout: Layout

    /// Kênh báo chiều cao thật lên Dart (`NativeAdHeights`); nil trong test.
    private let heightChannel: FlutterMethodChannel?

    init(layout: Layout, heightChannel: FlutterMethodChannel? = nil) {
        self.layout = layout
        self.heightChannel = heightChannel
        super.init()
    }

    // MARK: - FLTNativeAdFactory

    func createNativeAd(
        _ nativeAd: AdNativeAd,
        customOptions: [AnyHashable: Any]?
    ) -> AdNativeAdView? {
        let adView = makeAdView(
            headline: nativeAd.headline,
            body: nativeAd.body,
            callToAction: nativeAd.callToAction,
            icon: nativeAd.icon?.image,
            customOptions: customOptions
        )
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        // Bắt buộc: asset view đã gán trong makeAdView, giờ mới gán nativeAd.
        adView.nativeAd = nativeAd
        reportHeight(of: adView, customOptions: customOptions)
        return adView
    }

    /// Đo chiều cao nội dung rồi báo lên Dart để ô Flutter co đúng bằng nó.
    ///
    /// Gọi ngay trong factory — plugin gọi factory **trước** khi báo
    /// `onAdLoaded`, nên Dart có chiều cao trước khi ad hiện, không bị nhảy.
    /// Ad luôn full chiều rộng nên đo theo chiều rộng màn hình; khung thật
    /// khác (xoay màn, iPad…) thì đo lại khi view đổi chiều rộng.
    private func reportHeight(
        of adView: AdNativeAdView,
        customOptions: [AnyHashable: Any]?
    ) {
        guard layout.wrapsContent,
              let channel = heightChannel,
              let slotId = customOptions?["slot_id"] as? String,
              let view = adView as? MeasuringNativeAdView
        else { return }

        let send: (CGFloat) -> Void = { [weak self, weak view] width in
            guard let self, let view else { return }
            let height = self.measuredHeight(of: view, width: width)
            channel.invokeMethod(
                "height", arguments: ["slot_id": slotId, "height": height])
        }
        let width = Self.screenWidth
        view.measuredWidth = width
        send(width)
        view.onWidthChange = { width in
            DispatchQueue.main.async { send(width) }
        }
    }

    /// Chiều cao nội dung khi view rộng [width]: dựng thử trong khung cao dư
    /// rồi đọc đáy nội dung (layout wrap có đáy `<=` nên không bị kéo giãn).
    func measuredHeight(of adView: AdNativeAdView, width: CGFloat) -> CGFloat {
        guard let content = adView.subviews.first(where: { $0 is UIStackView })
        else { return 0 }
        let measuring = adView as? MeasuringNativeAdView
        measuring?.isMeasuring = true
        let saved = adView.frame
        adView.frame = CGRect(
            x: saved.minX, y: saved.minY, width: width, height: 2000)
        adView.layoutIfNeeded()
        let height = ceil(content.frame.maxY + layout.padding)
        adView.frame = saved
        adView.setNeedsLayout()
        measuring?.isMeasuring = false
        return height
    }

    private static var screenWidth: CGFloat {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        return scene?.screen.bounds.width ?? UIScreen.main.bounds.width
    }

    /// Dựng cây view từ nội dung thô, chưa gắn `nativeAd` — tách riêng để
    /// RunnerTests đo được layout mà không cần quảng cáo thật.
    func makeAdView(
        headline headlineText: String?,
        body bodyText: String?,
        callToAction: String?,
        icon iconImage: UIImage?,
        customOptions: [AnyHashable: Any]?
    ) -> AdNativeAdView {
        // Không tắt translatesAutoresizingMaskIntoConstraints ở view gốc: plugin
        // trả thẳng view này làm platform view, Flutter đặt kích thước bằng
        // frame. Tắt đi thì frame bị bỏ qua, layout mơ hồ → ad lệch/tràn khung.
        let adView = MeasuringNativeAdView(frame: .zero)

        let style = AdStyle(options: customOptions)

        let headline = makeLabel(
            size: style.headlineSize ?? defaultHeadlineSize,
            weight: .bold,
            color: style.headlineColor ?? .white,
            lines: layout.headlineLines
        )
        headline.text = headlineText

        let body = makeLabel(
            size: layout.bodySize,
            weight: .regular,
            color: style.bodyColor ?? UIColor(white: 0.8, alpha: 1),
            lines: layout.bodyLines
        )
        body.text = bodyText
        body.isHidden = bodyText == nil

        let cta = makeCta(
            title: callToAction,
            shape: style.ctaShape,
            fontSize: layout.ctaFontSize
        )
        cta.isHidden = callToAction == nil

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.image = iconImage
        // Ẩn khi không có ảnh, kể cả khi ad khai icon mà ảnh chưa về — nếu
        // không sẽ còn một ô trống 40pt cạnh tiêu đề.
        icon.isHidden = iconImage == nil
        icon.translatesAutoresizingMaskIntoConstraints = false

        let media = AdMediaView()
        media.contentMode = .scaleAspectFill
        media.clipsToBounds = true
        media.translatesAutoresizingMaskIntoConstraints = false

        let adLabel = makeAdLabel()

        let content = buildContent(
            adLabel: adLabel,
            headline: headline,
            body: body,
            cta: cta,
            icon: icon,
            media: media
        )
        content.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(content)

        let pad = layout.padding
        // Layout inline: nội dung cao đúng tổng các phần (Dart co ô theo chiều
        // cao đo được). Fullscreen: kéo đủ khung.
        let bottom = layout.wrapsContent
            ? content.bottomAnchor.constraint(
                lessThanOrEqualTo: adView.bottomAnchor, constant: -pad)
            : content.bottomAnchor.constraint(
                equalTo: adView.bottomAnchor, constant: -pad)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            content.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            content.topAnchor.constraint(equalTo: adView.topAnchor, constant: pad),
            bottom,
        ])

        if let bg = style.bgColor {
            adView.backgroundColor = bg
        }

        adView.headlineView = headline
        adView.bodyView = body
        adView.callToActionView = cta
        adView.iconView = icon
        adView.mediaView = media

        // CTA phải cho SDK tự bắt sự kiện chạm.
        cta.isUserInteractionEnabled = false

        return adView
    }

    // MARK: - Dựng bố cục theo từng layout

    private func buildContent(
        adLabel: UIView,
        headline: UILabel,
        body: UILabel,
        cta: UIButton,
        icon: UIImageView,
        media: AdMediaView
    ) -> UIView {
        switch layout {
        case .ctaMediaInfo:
            // Media cao cố định, không phụ thuộc video/ảnh của từng ad.
            constrainMedia(media, height: layout.fixedMediaHeight ?? 0)
            constrainIcon(icon, size: 40)
            constrainCta(cta, height: 48)
            return vStack([
                cta,
                media,
                hStack([icon, vStack([headlineRow(adLabel, headline), body], spacing: 2)],
                       spacing: 8, alignment: .center),
            ], spacing: 8)

        case .infoMediaCta:
            constrainMedia(media, height: layout.fixedMediaHeight ?? 0)
            constrainIcon(icon, size: 40)
            constrainCta(cta, height: 48)
            return vStack([
                hStack([
                    icon,
                    vStack([headlineRow(adLabel, headline), body], spacing: 2),
                ], spacing: 8, alignment: .center),
                media,
                cta,
            ], spacing: 8)

        case .mediaInfoCta:
            constrainMedia(media, height: layout.fixedMediaHeight ?? 0)
            constrainIcon(icon, size: 40)
            constrainCta(cta, height: 48)
            return vStack([
                media,
                hStack([icon, vStack([headlineRow(adLabel, headline), body], spacing: 2)],
                       spacing: 8, alignment: .center),
                cta,
            ], spacing: 8)

        case .bannerInfoCta:
            constrainIcon(icon, size: 40)
            constrainCta(cta, height: 40, minWidth: 88)
            // Layout này không dùng ảnh nhưng MediaView vẫn phải nằm trong cây.
            constrainMedia(media, height: 0, width: 0)
            return hStack([
                icon,
                vStack([headlineRow(adLabel, headline), body], spacing: 2),
                cta,
                media,
            ], spacing: 8, alignment: .center)

        case .bannerIconMediaInfo:
            constrainIcon(icon, size: 34)
            constrainMedia(media, height: 34, width: 56)
            constrainCta(cta, height: 32)
            return hStack([
                icon,
                media,
                vStack([headlineRow(adLabel, headline), body], spacing: 1),
                cta,
            ], spacing: 6, alignment: .center)

        case .fullscreenMediaInfoCta:
            constrainIcon(icon, size: 48)
            constrainCta(cta, height: 52)
            // Khung fullscreen cao khác nhau theo máy và theo nửa/cả màn, nên
            // media lấp chỗ còn lại. Ưu tiên ôm thấp nhất để CHỈ media giãn,
            // không phải nhãn Ad hay hàng chữ.
            media.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
            media.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            return vStack([
                media,
                hStack([icon, vStack([headlineRow(adLabel, headline), body], spacing: 2)],
                       spacing: 8, alignment: .center),
                cta,
            ], spacing: 10)
        }
    }

    // MARK: - Tiện ích dựng view

    private var defaultHeadlineSize: CGFloat { layout.headlineSize }

    private func vStack(
        _ views: [UIView],
        spacing: CGFloat,
        alignment: UIStackView.Alignment = .fill
    ) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = alignment
        return stack
    }

    private func hStack(
        _ views: [UIView],
        spacing: CGFloat,
        alignment: UIStackView.Alignment = .fill
    ) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.alignment = alignment
        return stack
    }

    /// Nhãn "Ad" đứng ngay trước tiêu đề, thẳng hàng với dòng đầu của tiêu đề.
    private func headlineRow(_ adLabel: UIView, _ headline: UILabel) -> UIView {
        hStack([adLabel, headline], spacing: 4, alignment: .firstBaseline)
    }

    private func constrainMedia(
        _ media: AdMediaView,
        height: CGFloat,
        width: CGFloat? = nil
    ) {
        if height > 0 {
            media.heightAnchor.constraint(equalToConstant: height).isActive = true
        } else {
            media.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        if let width {
            media.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }

    private func constrainIcon(_ icon: UIImageView, size: CGFloat) {
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: size),
            icon.heightAnchor.constraint(equalToConstant: size),
        ])
    }

    private func constrainCta(
        _ cta: UIButton,
        height: CGFloat,
        minWidth: CGFloat? = nil
    ) {
        cta.heightAnchor.constraint(equalToConstant: height).isActive = true
        if let minWidth {
            cta.widthAnchor.constraint(
                greaterThanOrEqualToConstant: minWidth).isActive = true
        }
    }

    private func makeLabel(
        size: CGFloat,
        weight: UIFont.Weight,
        color: UIColor,
        lines: Int
    ) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = lines
        label.lineBreakMode = .byTruncatingTail
        // Chữ luôn cao đúng bằng nội dung: không bị kéo giãn, không bị ép.
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    /// Nhãn "Ad" — AdMob bắt buộc phải có.
    private func makeAdLabel() -> UILabel {
        let label = UILabel()
        label.text = " Ad "
        label.font = .systemFont(ofSize: 9, weight: .regular)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 2
        label.clipsToBounds = true
        // Không bao giờ bị ép/giãn — tiêu đề bên cạnh mới là phần co theo chỗ.
        for axis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
            label.setContentHuggingPriority(.required, for: axis)
            label.setContentCompressionResistancePriority(.required, for: axis)
        }
        return label
    }

    private func makeCta(
        title: String?,
        shape: String?,
        fontSize: CGFloat
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: .bold)
        // `cta_config.bg_color` trong config chỉ có đúng một giá trị.
        button.backgroundColor = UIColor(
            red: 1, green: 0.65, blue: 0, alpha: 1)  // #FFA600
        // Bo góc suy từ shape: PILL = 24, ROUNDED_RECT = 10.
        button.layer.cornerRadius =
            shape?.trimmingCharacters(in: .whitespaces).uppercased() == "PILL"
            ? 24 : 10
        button.clipsToBounds = true
        return button
    }
}

// MARK: - Style từ customOptions

private struct AdStyle {
    let bgColor: UIColor?
    let headlineColor: UIColor?
    let bodyColor: UIColor?
    let headlineSize: CGFloat?
    let ctaShape: String?

    init(options: [AnyHashable: Any]?) {
        bgColor = AdStyle.color(options?["bg_color"])
        headlineColor = AdStyle.color(options?["headline_color"])
        bodyColor = AdStyle.color(options?["body_color"])
        if let size = options?["headline_text_size_sp"] as? NSNumber {
            headlineSize = CGFloat(size.doubleValue)
        } else {
            headlineSize = nil
        }
        ctaShape = options?["cta_shape"] as? String
    }

    /// Dart gửi Int ARGB.
    private static func color(_ raw: Any?) -> UIColor? {
        guard let number = raw as? NSNumber else { return nil }
        let argb = UInt32(truncatingIfNeeded: number.int64Value)
        return UIColor(
            red: CGFloat((argb >> 16) & 0xFF) / 255,
            green: CGFloat((argb >> 8) & 0xFF) / 255,
            blue: CGFloat(argb & 0xFF) / 255,
            alpha: CGFloat((argb >> 24) & 0xFF) / 255
        )
    }
}

// MARK: - Thông số riêng của từng layout

extension LiveScoreNativeAdFactory.Layout {
    /// Ad inline cao đúng bằng nội dung (Dart co ô theo chiều cao đo được);
    /// fullscreen thì lấp cả khung.
    var wrapsContent: Bool { self != .fullscreenMediaInfoCta }

    /// Chiều cao cố định của media cho 3 layout lớn trong ô 330pt — chọn để
    /// vẫn vừa khi tiêu đề và mô tả đều 2 dòng (RunnerTests kiểm). nil = media
    /// lấp chỗ còn lại (fullscreen) hoặc đã có kích thước riêng (banner).
    var fixedMediaHeight: CGFloat? {
        switch self {
        case .ctaMediaInfo, .infoMediaCta, .mediaInfoCta: return 165
        default: return nil
        }
    }

    var padding: CGFloat {
        switch self {
        case .bannerIconMediaInfo: return 6
        case .fullscreenMediaInfoCta: return 12
        default: return 10
        }
    }

    var headlineSize: CGFloat {
        switch self {
        case .bannerInfoCta: return 14
        case .bannerIconMediaInfo: return 13
        case .fullscreenMediaInfoCta: return 19
        default: return 17
        }
    }

    var headlineLines: Int {
        switch self {
        case .bannerInfoCta, .bannerIconMediaInfo: return 1
        default: return 2
        }
    }

    var bodySize: CGFloat {
        switch self {
        case .bannerIconMediaInfo: return 11
        case .bannerInfoCta: return 13
        default: return 14
        }
    }

    var bodyLines: Int {
        switch self {
        case .bannerInfoCta, .bannerIconMediaInfo: return 1
        default: return 2
        }
    }

    var ctaFontSize: CGFloat {
        switch self {
        case .bannerIconMediaInfo: return 12
        case .bannerInfoCta: return 14
        case .fullscreenMediaInfoCta: return 17
        default: return 16
        }
    }
}

/// NativeAdView báo lại khi Flutter đặt chiều rộng khác lúc đo — để đo lại.
final class MeasuringNativeAdView: AdNativeAdView {
    var measuredWidth: CGFloat = 0
    var isMeasuring = false
    var onWidthChange: ((CGFloat) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !isMeasuring, bounds.width > 0,
              abs(bounds.width - measuredWidth) > 0.5
        else { return }
        measuredWidth = bounds.width
        onWidthChange?(bounds.width)
    }
}
