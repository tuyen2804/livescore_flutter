/// Lỗi ở tầng data — repository bắt lại rồi đổi thành [Failure].
class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  TimeoutException([this.message = 'Request timed out']);
  final String message;
  @override
  String toString() => 'TimeoutException: $message';
}

class CacheException implements Exception {
  CacheException([this.message = 'Cache error']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}

class ParseException implements Exception {
  ParseException([this.message = 'Malformed response']);
  final String message;
  @override
  String toString() => 'ParseException: $message';
}
