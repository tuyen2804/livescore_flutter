import 'package:equatable/equatable.dart';

import '../../core/error/either.dart';
import '../../core/error/failures.dart';

/// Hợp đồng chung cho mọi usecase.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Usecase đồng bộ (đọc cache, prefs...).
abstract class SyncUseCase<T, Params> {
  Either<Failure, T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => const [];
}
