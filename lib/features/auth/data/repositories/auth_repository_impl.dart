import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:bitwise_academy/core/constants/app_constants.dart';
import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Concrete implementation of [AuthRepository].
///
/// Security model:
/// - Public document  /users/{uid}                 → display name, role, XP, etc.
/// - Private document /users/{uid}/private/secrets → email, SHA-256(recoveryKey)
/// - The raw recovery key is NEVER persisted; it is generated, returned once,
///   and then forgotten.
class AuthRepositoryImpl
    with FirebaseGuardedExecution
    implements AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    required AuthRemoteDataSource authDataSource,
    required FirebaseFirestore firestore,
  }) : _authDataSource = authDataSource,
       _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Cryptographically secure 12-character key using an unambiguous charset.
  String _generateRecoveryKey() {
    const charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(
      AppConstants.recoveryKeyLength,
      (_) => charset[rng.nextInt(charset.length)],
    ).join();
  }

  /// SHA-256 hash of [input] — used to store and compare recovery keys safely.
  String _hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  bool _isDomainAllowed(String email) {
    final domain = email.split('@').last.toLowerCase();
    return AppConstants.allowedDomains.contains(domain);
  }

  Future<bool> _isAdminWhitelisted(String email) async {
    try {
      final doc = await _firestore
          .collection('admin_whitelist')
          .doc(email)
          .get();
      return doc.exists;
    } catch (e, st) {
      AppLogger.instance.e(
        'Error checking admin whitelist for $email',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Writes the public profile and private secrets documents atomically (batch).
  Future<void> _dualWrite({
    required String uid,
    required Map<String, dynamic> publicData,
    required Map<String, dynamic> privateData,
  }) async {
    final batch = _firestore.batch();
    batch.set(_usersCollection.doc(uid), publicData);
    batch.set(
      _usersCollection.doc(uid).collection('private').doc('secrets'),
      privateData,
    );
    await batch.commit();
  }

  /// Reads the public profile only (email is not needed for most operations).
  Future<UserEntity?> _fetchPublicUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    // Fetch private doc for email
    final privateDoc = await _usersCollection
        .doc(uid)
        .collection('private')
        .doc('secrets')
        .get();
    return _mapDocToUser(doc, privateDoc.data()?['email'] as String?);
  }

  /// Maps Firestore documents → [UserEntity].
  UserEntity _mapDocToUser(
    DocumentSnapshot<Map<String, dynamic>> publicDoc, [
    String? email,
  ]) {
    final data = publicDoc.data()!;
    return UserEntity(
      // Safe casts: older accounts or Firestore schema migrations may be
      // missing fields. Fall back to safe sentinel values rather than crash.
      uid: data['uid'] as String? ?? publicDoc.id,
      email: email ?? '',
      displayName: data['displayName'] as String? ?? 'HERO',
      role: UserRole.fromString(data['role'] as String? ?? 'student'),
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      avatarUrl: data['avatarUrl'] as String?,
      unlockedAvatars: List<String>.from(
        data['unlockedAvatars'] as Iterable? ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── AuthRepository ─────────────────────────────────────────────────────────

  @override
  Stream<UserEntity?> get authStateChanges {
    late StreamController<UserEntity?> controller;
    StreamSubscription<fb.User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? firestoreSub;

    controller = StreamController<UserEntity?>.broadcast(
      onListen: () {
        authSub = _authDataSource.authStateChanges.listen((firebaseUser) {
          firestoreSub?.cancel();
          if (firebaseUser == null) {
            controller.add(null);
          } else {
            void listenToFirestore(int attempt) {
              firestoreSub = _usersCollection
                  .doc(firebaseUser.uid)
                  .snapshots()
                  .listen(
                    (doc) {
                      if (!doc.exists || doc.data() == null) {
                        controller.add(null);
                      } else {
                        try {
                          controller.add(_mapDocToUser(doc, firebaseUser.email));
                        } catch (e) {
                          AppLogger.instance.e(
                            'Error mapping auth state',
                            error: e,
                          );
                          controller.add(null);
                        }
                      }
                    },
                    onError: (Object e) {
                      AppLogger.instance.e(
                        'Error listening to user doc (attempt $attempt)',
                        error: e,
                      );
                      if (e is fb.FirebaseException &&
                          e.code == 'permission-denied' &&
                          attempt < 3) {
                        Future.delayed(const Duration(seconds: 1), () {
                          listenToFirestore(attempt + 1);
                        });
                      }
                    },
                  );
            }
            listenToFirestore(1);
          }
        });
      },
      onCancel: () {
        authSub?.cancel();
        firestoreSub?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    return guardedTask(() async {
      final firebaseUser = _authDataSource.currentUser;
      if (firebaseUser == null) return null;
      return _fetchPublicUser(firebaseUser.uid);
    }, taskName: 'getCurrentUser');
  }

  @override
  Future<Result<AuthResult>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return guardedTask(() async {
      if (!_isDomainAllowed(email)) {
        throw fb.FirebaseAuthException(
          code: 'invalid-email',
          message: 'This email domain is not authorized.',
        );
      }

      final credential = await _authDataSource.signInWithEmail(
        email: email,
        password: password,
      );

      final String uid = credential.user!.uid;
      await _usersCollection.doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      final user = await _fetchPublicUser(uid);
      return AuthResult(user: user!);
    }, taskName: 'signInWithEmail');
  }

  @override
  Future<Result<AuthResult>> createAccountWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return guardedTask(() async {
      if (!_isDomainAllowed(email)) {
        throw fb.FirebaseAuthException(
          code: 'invalid-email',
          message: 'This email domain is not authorized.',
        );
      }

      AppLogger.instance.d('🔵 [AUTH] Step 1: Creating Firebase Auth user...');
      final credential = await _authDataSource.createAccountWithEmail(
        email: email,
        password: password,
      );
      final String uid = credential.user!.uid;
      AppLogger.instance.d('🟢 [AUTH] Step 1 DONE: uid=$uid');

      await credential.user!.sendEmailVerification();
      AppLogger.instance.i('Verification email sent to $email');

      AppLogger.instance.d('🔵 [AUTH] Step 2: Checking admin whitelist...');
      final bool isAdmin = await _isAdminWhitelisted(email);
      AppLogger.instance.d('🟢 [AUTH] Step 2 DONE: isAdmin=$isAdmin');

      final String rawKey = _generateRecoveryKey();
      final String hashedKey = _hashString(rawKey);

      final Map<String, dynamic> publicData = {
        'uid': uid,
        'displayName': displayName,
        'role': isAdmin ? UserRole.admin.name : UserRole.student.name,
        'xp': 0,
        'level': 1,
        'coins': 0,
        'streakDays': 0,
        // Always write a non-null value so the app never crashes reading this
        // field. The real avatar is set via AvatarSelectionPage when
        // AppConstants.isAvatarSystemEnabled = true.
        'avatarUrl': AppConstants.defaultAvatarId,
        'unlockedAvatars': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      final Map<String, dynamic> privateData = {
        'email': email,
        'recoveryKey': hashedKey,
      };

      // Wait for auth to stabilise before writing
      AppLogger.instance.d('🔵 [AUTH] Step 3: Waiting for auth state...');
      final fb.User? current = _authDataSource.currentUser ?? credential.user;
      if (current?.uid != uid) {
        const timeout = Duration(seconds: 5);
        const interval = Duration(milliseconds: 250);
        var waited = Duration.zero;
        while ((_authDataSource.currentUser == null ||
                _authDataSource.currentUser!.uid != uid) &&
            waited < timeout) {
          await Future<void>.delayed(interval);
          waited += interval;
        }
      }

      AppLogger.instance.d('🔵 [AUTH] Step 4: Writing to Firestore...');
      await _dualWrite(
        uid: uid,
        publicData: publicData,
        privateData: privateData,
      );
      AppLogger.instance.d('🟢 [AUTH] Step 4 DONE: Firestore write succeeded!');

      final user = await _fetchPublicUser(uid);
      // rawKey is returned ONCE here and never stored in plain text again.
      return AuthResult(user: user!, rawRecoveryKey: rawKey);
    }, taskName: 'createAccountWithEmail');
  }

  @override
  Future<Result<AuthResult>> signInWithGoogle() async {
    return guardedTask(
      () async {
        final credential = await _authDataSource.signInWithGoogle();
        final String uid = credential.user!.uid;

        final DocumentSnapshot<Map<String, dynamic>> existingDoc =
            await _usersCollection.doc(uid).get();

        String? returnedRawKey;
        if (!existingDoc.exists) {
          final String rawKey = _generateRecoveryKey();
          returnedRawKey = rawKey;
          final String hashedKey = _hashString(rawKey);

          final Map<String, dynamic> publicData = {
            'uid': uid,
            'displayName': credential.user!.displayName ?? 'HERO',
            'role': await _isAdminWhitelisted(credential.user!.email ?? '')
                ? UserRole.admin.name
                : UserRole.student.name,
            'xp': 0,
            'level': 1,
            'coins': 0,
            'streakDays': 0,
            // Use Google profile photo when available; fall back to the default
            // avatar ID so the field is never null in Firestore.
            'avatarUrl':
                credential.user!.photoURL ?? AppConstants.defaultAvatarId,
            'unlockedAvatars': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          };

          final Map<String, dynamic> privateData = {
            'email': credential.user!.email ?? '',
            'recoveryKey': hashedKey,
          };

          await _dualWrite(
            uid: uid,
            publicData: publicData,
            privateData: privateData,
          );
          AppLogger.instance.i('New Google user profile created: $uid');
        } else {
          await _usersCollection.doc(uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }

        final user = await _fetchPublicUser(uid);
        return AuthResult(user: user!, rawRecoveryKey: returnedRawKey);
      },
      taskName: 'signInWithGoogle',
      timeout: const Duration(seconds: 500),
    );
  }

  @override
  Future<Result<AuthResult>> signInWithApple() async {
    return guardedTask(() async {
      final credential = await _authDataSource.signInWithApple();
      final String uid = credential.user!.uid;

      final DocumentSnapshot<Map<String, dynamic>> existingDoc =
          await _usersCollection.doc(uid).get();

      String? returnedRawKey;
      if (!existingDoc.exists) {
        final String rawKey = _generateRecoveryKey();
        returnedRawKey = rawKey;
        final String hashedKey = _hashString(rawKey);

        final Map<String, dynamic> publicData = {
          'uid': uid,
          'displayName': credential.user!.displayName ?? 'HERO',
          'role': await _isAdminWhitelisted(credential.user!.email ?? '')
              ? UserRole.admin.name
              : UserRole.student.name,
          'xp': 0,
          'level': 1,
          'coins': 0,
          'streakDays': 0,
          // Apple Sign-In doesn't provide a photo URL, so always use the
          // default avatar ID to keep the field non-null in Firestore.
          'avatarUrl': AppConstants.defaultAvatarId,
          'unlockedAvatars': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        };

        final Map<String, dynamic> privateData = {
          'email': credential.user!.email ?? '',
          'recoveryKey': hashedKey,
        };

        await _dualWrite(
          uid: uid,
          publicData: publicData,
          privateData: privateData,
        );
        AppLogger.instance.i('New Apple user profile created: $uid');
      } else {
        await _usersCollection.doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      final user = await _fetchPublicUser(uid);
      return AuthResult(user: user!, rawRecoveryKey: returnedRawKey);
    }, taskName: 'signInWithApple');
  }

  @override
  Future<Result<void>> recoverAccount({
    required String email,
    required String recoveryKey,
  }) async {
    try {
      // Strip any dashes the user typed (XXXX-XXXX-XXXX → XXXXXXXXXXXX)
      final String normalisedKey = recoveryKey
          .replaceAll('-', '')
          .trim()
          .toUpperCase();
      final String suppliedHash = _hashString(normalisedKey);

      // Look up the secrets doc via collectionGroup — unauthenticated call.
      // The Firestore rule allows list with limit ≤ 1.
      final QuerySnapshot<Map<String, dynamic>> secretsQuery = await _firestore
          .collectionGroup('secrets')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (secretsQuery.docs.isEmpty) {
        return const Failure<void>(
          AuthException(
            message:
                'Access Denied: No agent profile found for those subspace coordinates.',
            code: 'user-not-found',
          ),
        );
      }

      final Map<String, dynamic> secretsData = secretsQuery.docs.first.data();
      final String? storedHash = secretsData['recoveryKey'] as String?;

      if (storedHash == null || storedHash != suppliedHash) {
        return const Failure<void>(
          AuthException(
            message:
                'Access Denied: Invalid Subspace Coordinates. Key mismatch detected.',
            code: 'invalid-recovery-key',
          ),
        );
      }

      // Hashes match — dispatch password-reset email.
      await _authDataSource.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );

      AppLogger.instance.i(
        '[AUTH] Recovery key verified for $email. Password-reset email dispatched.',
      );
      return const Success<void>(null);
    } on fb.FirebaseAuthException catch (e, st) {
      AppLogger.instance.e(
        'FirebaseAuthException during recoverAccount',
        error: e,
        stackTrace: st,
      );
      return Failure<void>(
        AuthException(
          message: e.message ?? 'Signal lost. Unable to dispatch reset link.',
          code: e.code,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      AppLogger.instance.e(
        'Unexpected error during recoverAccount',
        error: e,
        stackTrace: st,
      );
      return Failure<void>(
        AuthException(
          message:
              'Subspace link disrupted. Please retry the recovery sequence.',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    return guardedTask(
      () => _authDataSource.sendPasswordResetEmail(email: email),
      taskName: 'sendPasswordResetEmail',
    );
  }

  @override
  Future<Result<void>> signOut() async {
    return guardedTask(() => _authDataSource.signOut(), taskName: 'signOut');
  }
}
