import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/utils/logger.dart';

/// Remote data source for all Firebase Authentication operations.
///
/// This class talks directly to [FirebaseAuth] and [GoogleSignIn].
/// It throws [AuthException] on failure — the repository layer
/// wraps these into [Result<T>].
class AuthRemoteDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource({
    required fb.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  /// Returns the currently signed-in user, or `null`.
  fb.User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes.
  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign in with email and password.
  Future<fb.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final fb.UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      AppLogger.instance.i('User signed in: ${credential.user?.uid}');
      return credential;
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      AppLogger.instance.e('Sign in failed', error: e, stackTrace: stackTrace);
      throw AuthException(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
        stackTrace: stackTrace,
      );
    }
  }

  /// Create a new account with email and password.
  Future<fb.UserCredential> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final fb.UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      AppLogger.instance.i('Account created: ${credential.user?.uid}');
      return credential;
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      AppLogger.instance.e(
        'Account creation failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sign in with Google.
  Future<fb.UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(
          message: 'Google sign-in was cancelled',
          code: 'google-sign-in-cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      AppLogger.instance.i(
        'Google sign-in successful: ${userCredential.user?.uid}',
      );
      return userCredential;
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      AppLogger.instance.e(
        'Google sign-in failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sign in with Apple.
  Future<fb.UserCredential> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final fb.OAuthCredential credential = fb.OAuthProvider('apple.com')
          .credential(
            idToken: appleCredential.identityToken ?? '',
            rawNonce: rawNonce,
          );

      final fb.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      AppLogger.instance.i(
        'Apple sign-in successful: ${userCredential.user?.uid}',
      );
      return userCredential;
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      AppLogger.instance.e(
        'Apple sign-in failed (Firebase)',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      // Check if it's a cancellation error from the package
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException(
          message: 'Apple sign-in was cancelled',
          code: 'apple-sign-in-cancelled',
        );
      }
      AppLogger.instance.e(
        'Apple sign-in failed (Native)',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException(
        message: 'Apple sign-in failed: ${e.toString()}',
        code: 'apple-sign-in-failed',
        stackTrace: stackTrace,
      );
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex format.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AppLogger.instance.i('Password reset email sent');
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      AppLogger.instance.e(
        'Password reset failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sign out from all providers.
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
      AppLogger.instance.i('User signed out');
    } on Exception catch (e, stackTrace) {
      AppLogger.instance.e('Sign out failed', error: e, stackTrace: stackTrace);
      throw AuthException(
        message: 'Failed to sign out',
        code: 'sign-out-failed',
        stackTrace: stackTrace,
      );
    }
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapAuthErrorMessage(String code) {
    return switch (code) {
      'user-not-found' => 'No player found with this email',
      'wrong-password' => 'Incorrect secret key',
      'email-already-in-use' => 'This email is already registered',
      'invalid-email' => 'Invalid email format',
      'weak-password' => 'Secret key is too weak',
      'user-disabled' => 'This account has been disabled',
      'too-many-requests' => 'Too many attempts. Try again later',
      'operation-not-allowed' => 'This sign-in method is not enabled',
      'network-request-failed' => 'Network connection failed',
      _ => 'Authentication error: $code',
    };
  }
}
