import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/datasources/local/app_prefs.dart';
import 'ads_config.dart';

/// Port `data/repository/AdsConfigRepositoryImpl.kt` +
/// `data/remote/service/RemoteConfigApi.kt` + `AdsConfigLocalDataSource.kt`.
///
/// Bản Kotlin dùng Retrofit với `BASE_URL = https://api.gamesontop.com/`,
/// endpoint `v4/games/services/remoteconfig`, và
/// `RemoteConfigHeaderInterceptor` gắn ba header: `Content-Type`, `pn`
/// (package name), `p` = 1. Kết quả cache vào SharedPreferences dưới khoá
/// `ads_config_cache`.
class AdsConfigRepository {
  AdsConfigRepository(this._prefs, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              responseType: ResponseType.json,
            ));

  static const String _baseUrl = 'https://api.gamesontop.com/';
  static const String _path = 'v4/games/services/remoteconfig';
  static const String _cacheKey = 'ads_config_cache';

  final AppPrefs _prefs;
  final Dio _dio;

  Future<AdsConfig> fetchAndCache() async {
    final packageName = (await PackageInfo.fromPlatform()).packageName;
    final response = await _dio.get<dynamic>(
      _path,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'pn': packageName,
        'p': '1',
      }),
    );

    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw StateError('AdsConfig data is null');
    }

    final json = Map<String, dynamic>.from(data);
    dev.log('$json', name: 'adsconfig');
    await _prefs.setString(_cacheKey, jsonEncode(json));
    return AdsConfig.fromJson(json);
  }

  AdsConfig? getCached() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AdsConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (e) {
      dev.log('cache parse failed: $e', name: 'adsconfig');
      return null;
    }
  }
}
