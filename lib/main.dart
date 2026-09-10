import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'core/ads/ads_lifecycle_observer.dart';
import 'core/ads/ads_test_devices.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase là tuỳ chọn: thiếu cấu hình thì app vẫn chạy bình thường.
  try {
    await Firebase.initializeApp();
    if (!kDebugMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    dev.log('Firebase not initialized: $e', name: 'main');
  }

  await initDependencies();

  // Port `MyApplication.onCreate`: khai test device → MobileAds.initialize →
  // đăng ký quan sát vòng đời để show App Open Ad khi app về foreground.
  unawaited(
    AdsTestDevices.apply().then((_) => MobileAds.instance.initialize()),
  );
  AdsLifecycleObserver().attach();

  runApp(const LiveScoreApp());
}
