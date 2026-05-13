/// A sealed Result type for handling fallible operations.
///
/// All repository and service methods that can fail MUST return
/// [Result<T>] instead of throwing exceptions. BLoCs/Cubits then
/// pattern-match on [Success] / [Failure] to emit the correct state.
sealed class Result<T> {
  const Result();
}

/// Represents a successful operation containing [data].
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed operation containing an [Exception].
///
/// Use [errorMessage] to obtain a safe, user-facing string without
/// needing to cast or import domain-specific exception types at call
/// sites. The actual message extraction logic lives in
/// [FailureMessageExtension] (see `app_exception.dart`).
final class Failure<T> extends Result<T> {
  final Exception exception;
  const Failure(this.exception);

  /// Returns a human-readable error message suitable for display in
  /// the UI. Falls back to [Exception.toString] for non-[AppException]
  /// exceptions so the getter is always safe to call.
  ///
  /// Note: the concrete mapping is provided by [FailureMessageExtension]
  /// in `package:bitwise_academy/core/errors/app_exception.dart`.
  String get errorMessage => _resolveMessage(exception);

  @override
  String toString() => 'Failure($exception)';
}

/// Internal helper — resolves a message from any [Exception] without
/// requiring a direct import of [AppException] here.
///
/// Mirrors the logic in [FailureMessageExtension] so the two are
/// always in sync.
String _resolveMessage(Exception e) {
  // Delegated: AppException carries a first-class `message` field.
  // We access it via the interface rather than importing the type.
  // If the exception has a `message` getter (all AppExceptions do),
  // we use it; otherwise we fall back to toString().
  try {
    // ignore: avoid_dynamic_calls
    return (e as dynamic).message as String;
  } catch (_) {
    return e.toString();
  }
}
