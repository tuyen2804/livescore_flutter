import 'dart:developer' as dev;

import 'package:firebase_analytics/firebase_analytics.dart';

/// Port của `data/firebase/Analytics.kt` (đã bỏ các event quảng cáo).
class AnalyticsService {
  FirebaseAnalytics? _analytics;

  FirebaseAnalytics? get instance {
    try {
      return _analytics ??= FirebaseAnalytics.instance;
    } catch (e) {
      dev.log('Analytics unavailable: $e', name: 'Analytics');
      return null;
    }
  }

  FirebaseAnalyticsObserver? get observer {
    final a = instance;
    return a == null ? null : FirebaseAnalyticsObserver(analytics: a);
  }

  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    try {
      await instance?.logEvent(name: name, parameters: params);
    } catch (e) {
      dev.log('logEvent($name) failed: $e', name: 'Analytics');
    }
  }

  Future<void> logScreen(String screenName) async {
    try {
      await instance?.logScreenView(screenName: screenName);
    } catch (e) {
      dev.log('logScreen($screenName) failed: $e', name: 'Analytics');
    }
  }
}
