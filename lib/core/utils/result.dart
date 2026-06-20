import '../errors/failures.dart';

/// Lightweight success/failure wrapper returned by use cases, so callers
/// must explicitly handle both branches via a `switch` instead of relying
/// on try/catch leaking through the domain layer.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
