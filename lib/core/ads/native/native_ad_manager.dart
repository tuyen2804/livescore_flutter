import 'dart:async';
import 'dart:developer' as dev;

import '../../services/remote_config_service.dart';
import '../ads_gate.dart';
import 'native_ad_controller.dart';
import 'native_placement.dart';
import 'native_placement_repository.dart';

/// Sổ đăng ký controller theo placement.
///
/// **Preload do app gọi tay**, không phải hễ Firebase trả config về là nạp
/// sạch 15 placement — xem mục 3 của `docs/ADS_NATIVE_DESIGN.md`. Mỗi màn nạp
/// trước cho màn kế tiếp, đúng cách bản Kotlin dùng `prepareController`.
class NativeAdManager {
  NativeAdManager(this._repository, this._remoteConfig);

  static const String _tag = 'NativeAdManager';

  final NativePlacementRepository _repository;
  final RemoteConfigService _remoteConfig;

  final Map<String, NativeAdController> _controllers = {};

  /// Nạp cấu hình (Remote Config → cache → asset). Gọi ở Splash, song song
  /// với consent.
  Future<NativePlacementConfig> loadConfig() => _repository.load();

  bool get isConfigReady => _repository.current != null;

  /// null nếu chưa nạp config, hoặc placement không có trong config, hoặc
  /// khoá Remote Config của placement đang tắt.
  NativeAdController? controllerOf(String placement) {
    final existing = _controllers[placement];
    if (existing != null) return existing;

    if (AdsGate.isBlocked) return null;
    if (!_remoteConfig.isNativeEnabled(placement)) {
      dev.log('[$placement] tắt trên Remote Config', name: _tag);
      return null;
    }

    final config = _repository.current;
    if (config == null) {
      dev.log('[$placement] chưa nạp config', name: _tag);
      return null;
    }

    final model = config[placement];
    if (model == null || model.isEmpty) {
      dev.log('[$placement] không có trong config', name: _tag);
      return null;
    }

    final controller = NativeAdController(model);
    _controllers[placement] = controller;
    return controller;
  }

  /// App gọi ở màn TRƯỚC màn cần hiện quảng cáo.
  Future<void> preload(String placement) async {
    final controller = controllerOf(placement);
    if (controller == null) return;
    await controller.preload();
  }

  /// Nạp trước nhiều placement một lượt, chạy song song.
  Future<void> preloadAll(List<String> placements) =>
      Future.wait(placements.map(preload));

  /// Đảm bảo có config rồi mới preload — dùng ở Splash khi config có thể
  /// chưa về kịp.
  Future<void> preloadAfterConfig(List<String> placements) async {
    await loadConfig();
    await preloadAll(placements);
  }

  bool isReady(String placement) =>
      _controllers[placement]?.hasAd ?? false;

  /// App vào nền — dừng đếm interval của mọi placement.
  void pauseAll() {
    for (final c in _controllers.values) {
      c.pause();
    }
  }

  /// App quay lại foreground.
  void resumeAll() {
    for (final c in _controllers.values) {
      c.resume();
    }
  }

  void disposePlacement(String placement) {
    _controllers.remove(placement)?.dispose();
  }

  void disposeAll() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }
}
