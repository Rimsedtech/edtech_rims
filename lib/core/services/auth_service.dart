import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart';

/// A high-level service to handle authentication tasks.
///
/// This service wraps the [AuthRepository] to provide a simplified
/// and robust interface for the UI.
class AuthService {
  final AuthRepository _authRepository;

  AuthService({required AuthRepository authRepository})
    : _authRepository = authRepository;

  /// Triggers the Google Sign-In flow and handles registration/login.
  ///
  /// Returns a [Result<AuthResult>] which represents the authenticated user
  /// (and an optional one-time recovery key for first-time sign-ins).
  Future<Result<AuthResult>> signInWithGoogle() async {
    AppLogger.instance.i('Starting Google Sign-In flow...');

    final result = await _authRepository.signInWithGoogle();

    switch (result) {
      case Success(:final data):
        AppLogger.instance.i(
          'Google Sign-In successful for user: ${data.user.email}',
        );
        return Success(data);
      case Failure(:final errorMessage, :final exception):
        // If it's a cancellation, log as info rather than error
        if (errorMessage.toLowerCase().contains('cancelled')) {
          AppLogger.instance.i('Google Sign-In was cancelled by the user.');
        } else {
          AppLogger.instance.e(
            'Google Sign-In failed',
            error: errorMessage,
          );
        }
        return Failure(exception);
    }
  }

  /// Sign out from the current session.
  Future<Result<void>> signOut() async {
    AppLogger.instance.i('Signing out...');
    return _authRepository.signOut();
  }
}
