import 'package:equatable/equatable.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Represents the result of an authentication operation.
class AuthResult extends Equatable {
  final UserEntity user;

  /// Only present when a NEW account is created (one-time reveal).
  final String? rawRecoveryKey;

  const AuthResult({required this.user, this.rawRecoveryKey});

  @override
  List<Object?> get props => [user, rawRecoveryKey];
}

/// Abstract contract for authentication operations.
///
/// All methods return [Result<T>] — never throw.
abstract class AuthRepository {
  /// Stream of authentication state changes and live Firestore user profile updates.
  Stream<UserEntity?> get authStateChanges;

  /// Get the currently authenticated user, or `null`.
  Future<Result<UserEntity?>> getCurrentUser();

  /// Sign in with email and password.
  Future<Result<AuthResult>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email and password.
  Future<Result<AuthResult>> createAccountWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with Google.
  Future<Result<AuthResult>> signInWithGoogle();

  /// Sign in with Apple.
  Future<Result<AuthResult>> signInWithApple();

  /// Verify a 12-char recovery key for [email] and, if valid,
  /// dispatch a Firebase password-reset email.
  Future<Result<void>> recoverAccount({
    required String email,
    required String recoveryKey,
  });

  /// Send password reset email.
  Future<Result<void>> sendPasswordResetEmail({required String email});

  /// Sign out.
  Future<Result<void>> signOut();
}
