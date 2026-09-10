import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

import '../../../data/datasources/local/app_prefs.dart';
import '../../services/remote_config_service.dart';
import 'native_placement.dart';

/// Nạp `placement_config` theo ba tầng, **không bao giờ chờ vô hạn**:
///
/// 1. Firebase Remote Config — hạn [_timeout] (5 giây).
/// 2. Bản cache trong SharedPreferences của lần chạy trước.
/// 3. Asset đóng gói trong app, **tách riêng theo nền tảng**:
///    `native_placements.json` (Android) / `native_placements_ios.json` (iOS).
///
/// Đây là chỗ cố ý khác bản Kotlin: SDK native bản Android chờ vô hạn nên
/// splash treo mãi khi Firebase không trả lời. Ở đây quá 5 giây, hoặc fetch
/// lỗi, hoặc JSON hỏng — đều rơi xuống tầng dưới và **ads vẫn chạy**.
class NativePlacementRepository {
  NativePlacementRepository(this._prefs, this._remoteConfig);

  static const Duration _timeout = Duration(seconds: 5);
  static const String _cacheKey = 'native_placement_config_cache';
  static const String _tag = 'NativePlacement';

  /// Hai nền tảng có **bộ ad unit id hoàn toàn khác nhau** (app id Android
  /// `~4860453709`, iOS `~1935875064`), nên bản dự phòng cũng phải tách.
  /// Dùng nhầm file thì AdMob trả `No ad config` và không bao giờ có quảng cáo.
  static const String _assetAndroid = 'assets/config/native_placements.json';
  static const String _assetIos = 'assets/config/native_placements_ios.json';

  static String get _assetPath =>
      (!kIsWeb && Platform.isIOS) ? _assetIos : _assetAndroid;

  /// Cache cũng tách theo nền tảng cho chắc — cùng một máy chạy cả hai bản
  /// (ví dụ simulator + emulator dùng chung tài khoản) thì không lẫn.
  static String get _cacheKeyForPlatform =>
      (!kIsWeb && Platform.isIOS) ? '${_cacheKey}_ios' : _cacheKey;

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
    await _prefs.setString(_cacheKeyForPlatform, raw);
    return parsed;
  }

  NativePlacementConfig? _fromCache() {
    final raw = _prefs.getString(_cacheKeyForPlatform);
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
