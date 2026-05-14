/// Marker interface for exceptions that carry a user-readable [message].
///
/// Implement this on any [Exception] subtype to ensure [Failure.errorMessage]
/// can extract a clean string without resorting to dynamic dispatch.
abstract interface class HasMessage {
  String get message;
}

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
/// Uses the [HasMessage] interface so all [AppException] subtypes are
/// handled without dynamic dispatch.
String _resolveMessage(Exception e) {
  if (e case final HasMessage h) return h.message;
  return e.toString();
}
