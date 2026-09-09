import 'package:equatable/equatable.dart';

/// Lỗi ở tầng domain — mọi usecase trả về `Either<Failure, T>`.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final int? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => '$runtimeType($code): $message';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Malformed response']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
