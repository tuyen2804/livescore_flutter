import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Port `ads/adnative/AdsKey.kt` — tên placement dùng chung cho cả hai nền
/// tảng; **ad unit id thì khác nhau hoàn toàn giữa Android và iOS**.
class InterPlacement {
  const InterPlacement._();

  static const String splash = 'LiveScore_inter_splash';
  static const String inApp = 'LiveScore_inter_Inapp';

  /// Show khi user đóng màn No-ads / Premium.
  static const String noAds = 'LiveScore_inter_Noads';
}

class RewardPlacement {
  const RewardPlacement._();

  static const String inApp = 'LiveScore_reward_Inapp';
}

/// Ad unit id theo nền tảng.
///
/// - **Android**: lấy từ `InterstitialAdManager` / `RewardAdManager` /
///   `AppOpenAdManager` của bản Kotlin.
/// - **iOS**: lấy từ bảng monetization do bên vận hành cấp (app id
///   `~1935875064`, khác app id Android `~4860453709`).
///
/// Hai bộ này **không được lẫn**: dùng nhầm id của nền tảng kia thì AdMob trả
/// `No ad config` và không bao giờ có quảng cáo.
class AdsUnitIds {
  const AdsUnitIds._();

  static bool get _ios => !kIsWeb && Platform.isIOS;

  /// Khai trong `AndroidManifest.xml` và `Info.plist`; để đây cho dễ tra.
  static const String appIdAndroid = 'ca-app-pub-6884037586522683~4860453709';
  static const String appIdIos = 'ca-app-pub-6884037586522683~1935875064';

  static String get appId => _ios ? appIdIos : appIdAndroid;

  // ---------------------------------------------------------- interstitial

  static const Map<String, String> _interAndroid = {
    InterPlacement.splash: 'ca-app-pub-6884037586522683/7120775219',
    InterPlacement.inApp: 'ca-app-pub-6884037586522683/8714872570',
    InterPlacement.noAds: 'ca-app-pub-6884037586522683/8193194050',
  };

  static const Map<String, String> _interHighFloorAndroid = {
    InterPlacement.splash: 'ca-app-pub-6884037586522683/6929203526',
    InterPlacement.inApp: 'ca-app-pub-6884037586522683/6319914573',
    InterPlacement.noAds: 'ca-app-pub-6884037586522683/5813377067',
  };

  static const Map<String, String> _interIos = {
    InterPlacement.splash: 'ca-app-pub-6884037586522683/6859180059',
    InterPlacement.inApp: 'ca-app-pub-6884037586522683/4141517375',
    InterPlacement.noAds: 'ca-app-pub-6884037586522683/5985433731',
  };

  static const Map<String, String> _interHighFloorIos = {
    InterPlacement.splash: 'ca-app-pub-6884037586522683/5055495442',
    InterPlacement.inApp: 'ca-app-pub-6884037586522683/3849873330',
    InterPlacement.noAds: 'ca-app-pub-6884037586522683/5322737104',
  };

  // --------------------------------------------------------------- reward

  static const Map<String, String> _rewardAndroid = {
    RewardPlacement.inApp: 'ca-app-pub-6884037586522683/5717279348',
  };

  static const Map<String, String> _rewardIos = {
    RewardPlacement.inApp: 'ca-app-pub-6884037586522683/1654954838',
  };

  // ------------------------------------------------------------- app open

  static const String _appOpenAndroid =
      'ca-app-pub-6884037586522683/5525707654';
  static const String _appOpenIos = 'ca-app-pub-6884037586522683/4869838782';

  // --------------------------------------------------------------- banner

  /// `MatchDetailFragment` có gọi banner nhưng đang bị comment; iOS chưa cấp id.
  static const String bannerHome = 'ca-app-pub-6884037586522683/6524671628';

  // ------------------------------------------------------------------ API

  static String inter(String placement) =>
      (_ios ? _interIos : _interAndroid)[placement] ?? '';

  static String interHighFloor(String placement) =>
      (_ios ? _interHighFloorIos : _interHighFloorAndroid)[placement] ?? '';

  static String reward(String placement) =>
      (_ios ? _rewardIos : _rewardAndroid)[placement] ?? '';

  static String get appOpen => _ios ? _appOpenIos : _appOpenAndroid;
}

/// Nhãn `ad_format` gửi kèm sự kiện Analytics — giữ đúng chuỗi của bản gốc.
class AdFormat {
  const AdFormat._();

  static const String interstitial = 'interstitial';
  static const String appOpen = 'app_open';
  static const String rewarded = 'rewarded';
  static const String banner = 'banner';
  static const String native = 'native';
}
