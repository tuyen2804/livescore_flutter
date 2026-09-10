import 'package:flutter/widgets.dart';

import '../di/injection.dart';
import 'app_open_ad_manager.dart';
import 'native/native_ad_manager.dart';

/// Port phần `Application.ActivityLifecycleCallbacks` của `MyApplication.kt`:
///
/// ```kotlin
/// override fun onActivityStarted(activity: Activity) {
///     if (++startedActivityCount == 1 && !isChangingConfig) {
///         AppOpenAdManager.showIfAvailable(activity)
///     }
/// }
/// ```
///
/// Flutter chỉ có một Activity nên đếm activity không còn ý nghĩa; điều kiện
/// tương đương là app chuyển từ nền về `resumed`. Lần `resumed` đầu tiên ngay
/// sau khi khởi động bị bỏ qua — bản gốc lúc đó vẫn đang ở splash và AOA đang
/// bị `disable()`.
class AdsLifecycleObserver with WidgetsBindingObserver {
  bool _wasBackgrounded = false;

  NativeAdManager? get _native =>
      sl.isRegistered<NativeAdManager>() ? sl<NativeAdManager>() : null;

  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _wasBackgrounded = true;
        // `AUTO_INTERVAL` chỉ đếm khi ad đang hiện — vào nền thì dừng.
        _native?.pauseAll();
      case AppLifecycleState.resumed:
        _native?.resumeAll();
        if (_wasBackgrounded) {
          _wasBackgrounded = false;
          AppOpenAdManager.showIfAvailable();
        }
      case AppLifecycleState.inactive:
        break;
    }
  }
}
