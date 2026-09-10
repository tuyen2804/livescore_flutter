import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/services.dart' show rootBundle;

import '../../../data/datasources/local/app_prefs.dart';
import '../../services/remote_config_service.dart';
import 'native_placement.dart';

/// Nạp `placement_config` theo ba tầng, **không bao giờ chờ vô hạn**:
///
/// 1. Firebase Remote Config — hạn [_timeout] (5 giây).
/// 2. Bản cache trong SharedPreferences của lần chạy trước.
/// 3. `assets/config/native_placements.json` đóng gói trong app.
///
/// Đây là chỗ cố ý khác bản Kotlin: SDK native bản Android chờ vô hạn nên
/// splash treo mãi khi Firebase không trả lời.
class NativePlacementRepository {
  NativePlacementRepository(this._prefs, this._remoteConfig);

  static const Duration _timeout = Duration(seconds: 5);
  static const String _cacheKey = 'native_placement_config_cache';
  static const String _assetPath = 'assets/config/native_placements.json';
  static const String _tag = 'NativePlacement';

  final AppPrefs _prefs;
  final RemoteConfigService _remoteConfig;

  NativePlacementConfig? _cached;
  Future<NativePlacementConfig>? _inFlight;

  /// Cấu hình đã nạp; null nếu chưa gọi [load].
  NativePlacementConfig? get current => _cached;

  /// Gọi nhiều lần cũng chỉ nạp một lần.
  Future<NativePlacementConfig> load() {
    final done = _cached;
    if (done != null) return Future.value(done);
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<NativePlacementConfig> _load() async {
    final config = await _fromRemote()
            .timeout(_timeout, onTimeout: () {
              dev.log(
                'Remote Config quá ${_timeout.inSeconds}s → dùng cache/asset',
                name: _tag,
              );
              return null;
            })
            .catchError((Object e) {
              dev.log('Remote Config lỗi: $e', name: _tag);
              return null;
            }) ??
        _fromCache() ??
        await _fromAsset();

    _cached = config;
    dev.log('Đã nạp ${config.placements.length} placement', name: _tag);
    return config;
  }

  Future<NativePlacementConfig?> _fromRemote() async {
    final raw = _remoteConfig.placementConfig;
    if (raw.isEmpty) return null;
    final parsed = _parse(raw, 'remote');
    if (parsed == null || parsed.isEmpty) return null;
    // Chỉ cache khi parse được, tránh ghi đè bản tốt bằng bản hỏng.
    await _prefs.setString(_cacheKey, raw);
    return parsed;
  }

  NativePlacementConfig? _fromCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    final parsed = _parse(raw, 'cache');
    return (parsed == null || parsed.isEmpty) ? null : parsed;
  }

  Future<NativePlacementConfig> _fromAsset() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      return _parse(raw, 'asset') ?? NativePlacementConfig.empty;
    } catch (e) {
      dev.log('Không đọc được $_assetPath: $e', name: _tag);
      return NativePlacementConfig.empty;
    }
  }

  NativePlacementConfig? _parse(String raw, String source) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final config = NativePlacementConfig.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      dev.log('Nguồn: $source (${config.placements.length} placement)',
          name: _tag);
      return config;
    } catch (e) {
      dev.log('Parse hỏng từ $source: $e', name: _tag);
      return null;
    }
  }
}
