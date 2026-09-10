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
private typealias AdNativeAd = NativeAd
private typealias AdNativeAdView = NativeAdView
private typealias AdMediaView = MediaView

class LiveScoreNativeAdFactory: NSObject, FLTNativeAdFactory {

    enum Layout {
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

    init(layout: Layout) {
        self.layout = layout
        super.init()
    }

    // MARK: - FLTNativeAdFactory

    func createNativeAd(
        _ nativeAd: AdNativeAd,
        customOptions: [AnyHashable: Any]?
    ) -> AdNativeAdView? {
        let adView = AdNativeAdView(frame: .zero)
        adView.translatesAutoresizingMaskIntoConstraints = false

        let style = AdStyle(options: customOptions)

        let headline = makeLabel(
            size: style.headlineSize ?? defaultHeadlineSize,
            weight: .bold,
            color: style.headlineColor ?? .white,
            lines: layout.headlineLines
        )
        headline.text = nativeAd.headline

        let body = makeLabel(
            size: layout.bodySize,
            weight: .regular,
            color: style.bodyColor ?? UIColor(white: 0.8, alpha: 1),
            lines: layout.bodyLines
        )
        body.text = nativeAd.body
        body.isHidden = nativeAd.body == nil

        let cta = makeCta(
            title: nativeAd.callToAction,
            shape: style.ctaShape,
            fontSize: layout.ctaFontSize
        )
        cta.isHidden = nativeAd.callToAction == nil

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.image = nativeAd.icon?.image
        icon.isHidden = nativeAd.icon == nil
        icon.translatesAutoresizingMaskIntoConstraints = false

        let media = AdMediaView()
        media.contentMode = .scaleAspectFill
        media.clipsToBounds = true
        media.mediaContent = nativeAd.mediaContent
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
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            content.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            content.topAnchor.constraint(equalTo: adView.topAnchor, constant: pad),
            content.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -pad),
        ])

        if let bg = style.bgColor {
            adView.backgroundColor = bg
        }

        // Bắt buộc: gán từng asset view rồi mới gán nativeAd.
        adView.headlineView = headline
        adView.bodyView = body
        adView.callToActionView = cta
        adView.iconView = icon
        adView.mediaView = media
        adView.nativeAd = nativeAd

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
            // Không ghim chiều cao: media ăn theo chỗ còn lại giống
            // `layout_weight="1"` bên Android, nên không bị cắt.
            media.setContentHuggingPriority(.defaultLow, for: .vertical)
            media.setContentCompressionResistancePriority(
                .defaultLow, for: .vertical)
            constrainIcon(icon, size: 40)
            constrainCta(cta, height: 48)
            return vStack([
                leadingWrap(adLabel),
                cta,
                media,
                hStack([icon, vStack([headline, body], spacing: 2)], spacing: 8),
            ], spacing: 8)

        case .infoMediaCta:
            media.setContentHuggingPriority(.defaultLow, for: .vertical)
            media.setContentCompressionResistancePriority(
                .defaultLow, for: .vertical)
            constrainIcon(icon, size: 40)
            constrainCta(cta, height: 48)
            return vStack([
                hStack([
                    icon,
                    vStack([leadingWrap(adLabel), headline, body], spacing: 2),
                ], spacing: 8),
                media,
                cta,
            ], spacing: 8)

        case .mediaInfoCta:
            media.setContentHuggingPriority(.defaultLow, for: .vertical)
            media.setContentCompressionResistancePriority(
                .defaultLow, for: .vertical)
            constrainIcon(icon, size: 40)
            constrainCta(cta, height: 48)
            return vStack([
                leadingWrap(adLabel),
                media,
                hStack([icon, vStack([headline, body], spacing: 2)], spacing: 8),
                cta,
            ], spacing: 8)

        case .bannerInfoCta:
            constrainIcon(icon, size: 40)
            constrainCta(cta, height: 40, minWidth: 88)
            // Layout này không dùng ảnh nhưng MediaView vẫn phải nằm trong cây.
            constrainMedia(media, height: 0, width: 0)
            return hStack([
                icon,
                vStack([leadingWrap(adLabel), headline, body], spacing: 2),
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
                vStack([leadingWrap(adLabel), headline, body], spacing: 1),
                cta,
            ], spacing: 6, alignment: .center)

        case .fullscreenMediaInfoCta:
            constrainIcon(icon, size: 48)
            constrainCta(cta, height: 52)
            // Media chiếm hết chỗ trống còn lại.
            media.setContentHuggingPriority(.defaultLow, for: .vertical)
            media.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            return vStack([
                leadingWrap(adLabel),
                media,
                hStack([icon, vStack([headline, body], spacing: 2)], spacing: 8),
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

    /// Bọc để nhãn "Ad" không bị kéo giãn hết chiều ngang.
    private func leadingWrap(_ view: UIView) -> UIView {
        let container = UIView()
        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.trailingAnchor.constraint(
                lessThanOrEqualTo: container.trailingAnchor),
        ])
        return container
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
        return label
    }

    /// Nhãn "Ad" — AdMob bắt buộc phải có.
    private func makeAdLabel() -> UILabel {
        let label = UILabel()
        label.text = " Ad "
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .black
        label.backgroundColor = UIColor(
            red: 1, green: 0.65, blue: 0, alpha: 1)  // #FFA600
        label.layer.cornerRadius = 2
        label.clipsToBounds = true
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
