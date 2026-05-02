/// Base exception hierarchy for all app-level errors.
///
/// All exceptions thrown by repositories and services must extend
/// [AppException]. Raw Firebase/network exceptions should be caught
/// and mapped to one of these subtypes.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException({required this.message, this.code, this.stackTrace});

  @override
  String toString() => 'AppException($code): $message';
}

/// Thrown when a network request fails (timeout, no connectivity, etc.)
final class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Thrown when Firebase Auth operations fail.
final class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.stackTrace});
}

/// Thrown when Firestore read/write operations fail.
final class FirestoreException extends AppException {
  const FirestoreException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Thrown when form or data validation fails.
final class ValidationException extends AppException {
  /// Map of field name → error message for per-field validation.
  final Map<String, String> fieldErrors;

  const ValidationException({
    required super.message,
    required this.fieldErrors,
    super.code,
    super.stackTrace,
  });
}

/// Thrown when Firebase Storage operations fail.
final class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Thrown when a requested resource is not found.
final class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Thrown when the user lacks permission for an action.
final class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}
