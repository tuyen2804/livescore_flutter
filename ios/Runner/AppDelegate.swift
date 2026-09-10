import Flutter
import UIKit
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerNativeAdFactories(engineBridge.pluginRegistry)
  }

  /// Đăng ký 5 NativeAdFactory. factoryId phải khớp `NativeLayouts` bên Dart
  /// (`lib/core/ads/native/native_layouts.dart`).
  private func registerNativeAdFactories(_ registry: FlutterPluginRegistry) {
    let factories: [String: LiveScoreNativeAdFactory.Layout] = [
      "ctaMediaInfo": .ctaMediaInfo,
      "infoMediaCta": .infoMediaCta,
      "mediaInfoCta": .mediaInfoCta,
      "bannerInfoCta": .bannerInfoCta,
      "bannerIconMediaInfo": .bannerIconMediaInfo,
      "fullscreenMediaInfoCta": .fullscreenMediaInfoCta,
    ]
    for (id, layout) in factories {
      FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
        registry,
        factoryId: id,
        nativeAdFactory: LiveScoreNativeAdFactory(layout: layout)
      )
    }
  }
}
