import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:native_dio_adapter/native_dio_adapter.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart' as app;

/// Bọc `Dio` với log + chuyển `DioException` thành exception của app.
/// Tương ứng `ApiClient.kt` (bóng đá) và `SofascoreApiService.create()`.
class DioClient {
  DioClient({
    required String baseUrl,
    required String tag,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Map<String, String> headers = const {},
    this.useNativeAdapter = true,
    // ignore: prefer_initializing_formals
  })  : _tag = tag,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            sendTimeout: receiveTimeout,
            responseType: ResponseType.json,
            headers: {
              'Accept': 'application/json',
              'Accept-Charset': 'UTF-8',
              ...headers,
            },
            validateStatus: (code) => code != null && code < 400,
          ),
        ) {
    // dart:io bị Sofascore chặn (403); Cronet/NSURLSession thì không.
    if (useNativeAdapter && _supportsNativeAdapter) {
      try {
        _dio.httpClientAdapter = NativeAdapter();
      } catch (e) {
        debugPrint('[$tag] native adapter unavailable, dùng mặc định: $e');
      }
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          dev.log('--> ${options.method} ${options.uri}', name: _tag);
          handler.next(options);
        },
        onResponse: (response, handler) {
          dev.log(
            '<-- ${response.statusCode} ${response.requestOptions.uri}',
            name: _tag,
          );
          handler.next(response);
        },
        onError: (e, handler) async {
          // Cronet hỏng ở tầng nạp thư viện thì MỌI request chết, kể cả host
          // không cần Cronet. Hạ xuống adapter mặc định rồi thử lại một lần —
          // Sofascore sẽ trả 403 vì dấu vân tay TLS, nhưng các host khác chạy
          // bình thường thay vì trắng sạch.
          if (_shouldFallBackToDefaultAdapter(e)) {
            _nativeAdapterBroken = true;
            _dio.httpClientAdapter = IOHttpClientAdapter();
            dev.log(
              'Cronet không nạp được (${e.error}); chuyển sang dart:io',
              name: _tag,
            );
            try {
              final retry = await _dio.fetch<dynamic>(e.requestOptions);
              return handler.resolve(retry);
            } catch (_) {
              // Thử lại cũng hỏng thì để lỗi gốc đi tiếp.
            }
          }
          debugPrint(
            '[$_tag] <-- FAILED ${e.response?.statusCode} '
            '${e.requestOptions.uri}: ${e.message} | ${e.error}',
          );
          handler.next(e);
        },
      ),
    );
  }

  /// Đặt một lần cho cả tiến trình: hỏng ở client này thì client kia cũng hỏng.
  static bool _nativeAdapterBroken = false;

  bool _shouldFallBackToDefaultAdapter(DioException e) {
    if (_nativeAdapterBroken) return false;
    if (!useNativeAdapter || !_supportsNativeAdapter) return false;
    final text = '${e.error}${e.message}';
    return text.contains('libdartjni') ||
        text.contains('Failed to load dynamic library');
  }

  /// Client cho API bóng đá riêng của app.
  factory DioClient.football({String? baseUrl}) => DioClient(
        baseUrl: baseUrl ?? ApiConstants.footballBaseUrl,
        tag: 'ApiClient',
      );

  /// Client cho Sofascore (cần User-Agent trình duyệt, timeout ngắn).
  factory DioClient.sofascore() => DioClient(
        baseUrl: ApiConstants.sofascoreBaseUrl,
        tag: 'SOFASCORE_HTTP',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'User-Agent': ApiConstants.userAgent,
          'Accept': '*/*',
        },
      );

  final Dio _dio;
  final String _tag;

  /// Bật adapter gốc của hệ điều hành (chỉ có trên Android/iOS).
  final bool useNativeAdapter;

  static bool get _supportsNativeAdapter =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Dio get raw => _dio;

  set baseUrl(String value) => _dio.options.baseUrl = value;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get<T>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
      );
      final data = res.data;
      if (data == null) throw app.ParseException('Empty body for $path');
      return data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.post<T>(
        path,
        queryParameters: query,
        data: body,
        cancelToken: cancelToken,
      );
      final data = res.data;
      if (data == null) throw app.ParseException('Empty body for $path');
      return data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          app.TimeoutException('Timed out: ${e.requestOptions.path}'),
        DioExceptionType.connectionError =>
          app.NetworkException(e.message ?? 'Connection error'),
        DioExceptionType.badResponse => app.ServerException(
            e.response?.statusMessage ?? 'Bad response',
            statusCode: e.response?.statusCode,
          ),
        DioExceptionType.cancel => app.NetworkException('Request cancelled'),
        _ => app.ServerException(e.message ?? 'Unknown network error'),
      };
}
