import Flutter
import UIKit
import XCTest

@testable import Runner

/// Kiểm layout native iOS trong đúng khung Flutter cấp, không cần ad thật.
class RunnerTests: XCTestCase {

  private typealias Layout = LiveScoreNativeAdFactory.Layout

  private let longHeadline = String(
    repeating: "Tiêu đề quảng cáo rất dài để chiếm đủ hai dòng ", count: 3)
  private let longBody = String(
    repeating: "Mô tả quảng cáo dài để chiếm đủ hai dòng chữ ", count: 3)

  private lazy var iconImage: UIImage = UIGraphicsImageRenderer(
    size: CGSize(width: 40, height: 40)
  ).image { ctx in
    UIColor.red.setFill()
    ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
  }

  /// Chiều cao mặc định Dart cấp khi native chưa báo số đo:
  /// `NativeLayouts.preferredHeight`, fullscreen là nửa màn (DUAL) và cả màn.
  private func slotHeights(for layout: Layout) -> [CGFloat] {
    switch layout {
    case .bannerIconMediaInfo: return [56]
    case .bannerInfoCta: return [90]
    case .fullscreenMediaInfoCta: return [380, 760]
    default: return [330]
    }
  }

  private func makeAd(
    _ layout: Layout, headline: String, body: String
  ) -> (LiveScoreNativeAdFactory, AdNativeAdView) {
    let factory = LiveScoreNativeAdFactory(layout: layout)
    let adView = factory.makeAdView(
      headline: headline,
      body: body,
      callToAction: "Tìm hiểu thêm",
      icon: iconImage,
      customOptions: nil
    )
    return (factory, adView)
  }

  /// Giống Flutter: platform view được đặt bằng frame + autoresizing.
  private func place(_ adView: UIView, width: CGFloat, height: CGFloat) {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
    adView.frame = host.bounds
    adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(adView)
    host.layoutIfNeeded()
  }

  /// Mọi view con, không đi vào bên trong MediaView (view nội bộ của SDK).
  private func descendants(of view: UIView) -> [UIView] {
    view.subviews.flatMap { sub -> [UIView] in
      sub is AdMediaView ? [sub] : [sub] + descendants(of: sub)
    }
  }

  private func isEffectivelyHidden(_ view: UIView, in root: UIView) -> Bool {
    var v: UIView? = view
    while let cur = v, cur !== root {
      if cur.isHidden { return true }
      v = cur.superview
    }
    return false
  }

  /// Yêu cầu chung cho mọi layout ở mọi khung.
  private func assertLayout(_ adView: AdNativeAdView, _ ctx: String, headline: String) {
    let views = descendants(of: adView).filter { !isEffectivelyHidden($0, in: adView) }

    // 1. Không view nào có layout mơ hồ.
    for v in views {
      XCTAssertFalse(v.hasAmbiguousLayout, "\(ctx): \(type(of: v)) mơ hồ")
    }

    // 2. Không view nào tràn khỏi khung Flutter cấp.
    for v in views where v.bounds.width > 0 && v.bounds.height > 0 {
      let f = v.convert(v.bounds, to: adView)
      XCTAssertTrue(
        adView.bounds.insetBy(dx: -0.5, dy: -0.5).contains(f),
        "\(ctx): \(type(of: v)) tràn khung \(f)")
    }

    // 3. Chữ cao vừa nội dung (wrap content), không bị kéo giãn hay ép.
    let labels = views.compactMap { $0 as? UILabel }.filter { !($0.superview is UIButton) }
    for label in labels {
      let fit = label.textRect(
        forBounds: CGRect(
          x: 0, y: 0, width: label.bounds.width, height: .greatestFiniteMagnitude),
        limitedToNumberOfLines: label.numberOfLines
      ).height
      XCTAssertEqual(
        label.bounds.height, ceil(fit), accuracy: 1,
        "\(ctx): label \"\(label.text?.prefix(12) ?? "")\" cao "
          + "\(label.bounds.height), nội dung chỉ \(ceil(fit))")
    }

    // 4. Nhãn "Ad" đứng ngay trước tiêu đề, trên dòng đầu của tiêu đề.
    if let ad = labels.first(where: { $0.text == " Ad " }),
      let title = labels.first(where: { $0.text == headline })
    {
      let adF = ad.convert(ad.bounds, to: adView)
      let titleF = title.convert(title.bounds, to: adView)
      XCTAssertLessThanOrEqual(
        adF.maxX, titleF.minX + 0.5, "\(ctx): Ad không đứng trước tiêu đề")
      XCTAssertTrue(
        adF.midY >= titleF.minY && adF.midY <= titleF.minY + title.font.lineHeight,
        "\(ctx): Ad không cùng dòng đầu tiêu đề — Ad \(adF), tiêu đề \(titleF)")
    } else {
      XCTFail("\(ctx): thiếu nhãn Ad hoặc tiêu đề")
    }
  }

  /// Khung mặc định (trước khi native báo số đo) vẫn chứa đủ nội dung.
  func testNativeLayoutsFitSlotAndTextsWrapContent() {
    for layout in Layout.allCases {
      for width in [CGFloat(320), 390] {
        for height in slotHeights(for: layout) {
          var mediaHeights: [CGFloat] = []

          for (headline, body) in [(longHeadline, longBody), ("Ngắn", "Ngắn")] {
            let (_, adView) = makeAd(layout, headline: headline, body: body)
            place(adView, width: width, height: height)
            assertLayout(
              adView, "\(layout) \(Int(width))x\(Int(height)) chữ=\(headline.count)",
              headline: headline)
            if let media = adView.mediaView {
              mediaHeights.append(media.bounds.height)
            }
          }

          // 5. Media cố định, không đổi theo độ dài chữ (fullscreen thì media
          //    lấp chỗ còn lại nên được phép đổi).
          if let fixed = layout.fixedMediaHeight {
            for h in mediaHeights {
              XCTAssertEqual(
                h, fixed, accuracy: 0.5,
                "\(layout) \(Int(width))x\(Int(height)): media \(h), phải cố định \(fixed)")
            }
          }
        }
      }
    }
  }

  /// Dart đặt ô đúng bằng chiều cao factory đo được: không còn khoảng trống
  /// ở đáy và không gì bị cắt.
  func testMeasuredHeightWrapsContent() {
    for layout in Layout.allCases where layout.wrapsContent {
      for width in [CGFloat(320), 390] {
        for (headline, body) in [(longHeadline, longBody), ("Ngắn", "Ngắn")] {
          let (factory, adView) = makeAd(layout, headline: headline, body: body)
          let height = factory.measuredHeight(of: adView, width: width)
          let ctx = "\(layout) \(Int(width)) đo=\(height) chữ=\(headline.count)"
          XCTAssertGreaterThan(height, 0, ctx)

          place(adView, width: width, height: height)
          assertLayout(adView, ctx, headline: headline)

          guard let content = adView.subviews.first(where: { $0 is UIStackView }) else {
            XCTFail("\(ctx): không thấy nội dung")
            continue
          }
          let blank = height - (content.frame.maxY + layout.padding)
          XCTAssertLessThanOrEqual(blank, 1, "\(ctx): còn trống \(blank)pt ở đáy")
        }
      }
    }
  }
}
