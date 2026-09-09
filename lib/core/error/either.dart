/// `Either` tối giản cho ranh giới domain — không kéo thêm dependency.
sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L? get leftOrNull => this is Left<L, R> ? (this as Left<L, R>).value : null;
  R? get rightOrNull => this is Right<L, R> ? (this as Right<L, R>).value : null;

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      switch (this) {
        Left<L, R>(:final value) => onLeft(value),
        Right<L, R>(:final value) => onRight(value),
      };

  Either<L, T> map<T>(T Function(R right) transform) => switch (this) {
        Left<L, R>(:final value) => Left<L, T>(value),
        Right<L, R>(:final value) => Right<L, T>(transform(value)),
      };

  Either<L, T> flatMap<T>(Either<L, T> Function(R right) transform) =>
      switch (this) {
        Left<L, R>(:final value) => Left<L, T>(value),
        Right<L, R>(:final value) => transform(value),
      };

  R getOrElse(R Function(L left) orElse) => fold(orElse, (r) => r);
}

final class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;

  @override
  bool operator ==(Object other) =>
      other is Left<L, R> && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'Left($value)';
}

final class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;

  @override
  bool operator ==(Object other) =>
      other is Right<L, R> && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'Right($value)';
}
