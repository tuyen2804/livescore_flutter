package com.ind.score2new.stream

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    /**
     * Đăng ký 5 NativeAdFactory cho `google_mobile_ads`. factoryId phải khớp
     * `NativeLayouts` bên Dart.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LiveScoreNativeAdFactory.registerAll(flutterEngine, applicationContext)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        LiveScoreNativeAdFactory.unregisterAll(flutterEngine)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
