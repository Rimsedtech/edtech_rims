import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Repository for user profile operations.
///
/// Handles XP updates, level progression, and streak tracking.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Fetch a user profile by UID.
  Future<Result<UserEntity>> fetchUser(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) {
        return Failure<UserEntity>(
          NotFoundException(
            message: 'User not found: $uid',
            code: 'user-not-found',
          ),
        );
      }
      return Success<UserEntity>(_mapDocToUser(doc));
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('fetchUser failed', error: e);
      return Failure<UserEntity>(
        FirestoreException(
          message: e.message ?? 'Failed to fetch user',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Real-time stream of a single user profile document.
  /// Retries up to [_maxRetries] times on transient permission-denied errors
  /// (caused by the Firebase Auth token not yet propagating to Firestore).
  Stream<Result<UserEntity>> watchUser(String uid) {
    return _watchUserWithRetry(uid, attempt: 0);
  }

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  Stream<Result<UserEntity>> _watchUserWithRetry(
    String uid, {
    required int attempt,
  }) async* {
    if (attempt > 0) {
      AppLogger.instance.w('watchUser retry $attempt/$_maxRetries for $uid');
      await Future<void>.delayed(_retryDelay);
    }

    try {
      await for (final event in _usersCollection.doc(uid).snapshots()) {
        try {
          if (!event.exists || event.data() == null) {
            yield Failure<UserEntity>(
              NotFoundException(
                message: 'User not found: $uid',
                code: 'user-not-found',
              ),
            );
          } else {
            yield Success<UserEntity>(_mapDocToUser(event));
          }
        } catch (e, stackTrace) {
          AppLogger.instance.e(
            'watchUser map failed for $uid',
            error: e,
            stackTrace: stackTrace,
          );
          yield Failure<UserEntity>(
            FirestoreException(
              message: 'Error parsing user data: $e',
              code: 'parse-error',
              stackTrace: stackTrace,
            ),
          );
        }
      }
    } on FirebaseException catch (e, stackTrace) {
      if (e.code == 'permission-denied' && attempt < _maxRetries) {
        // Transient token-propagation race — retry.
        AppLogger.instance.w(
          'watchUser permission-denied for $uid '
          '(attempt ${attempt + 1}/$_maxRetries) — will retry',
        );
        yield* _watchUserWithRetry(uid, attempt: attempt + 1);
      } else {
        // Exceeded retries or a different Firebase error — surface it.
        AppLogger.instance.e(
          'watchUser failed for $uid',
          error: e,
          stackTrace: stackTrace,
        );
        yield Failure<UserEntity>(
          FirestoreException(
            message: e.message ?? 'Failed to stream user',
            code: e.code,
            stackTrace: stackTrace,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'watchUser unexpected error for $uid',
        error: e,
        stackTrace: stackTrace,
      );
      yield Failure<UserEntity>(
        FirestoreException(
          message: 'Unexpected error: $e',
          code: 'unknown',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Award XP to a user and check for level-up.
  Future<Result<UserEntity>> awardXp({
    required String uid,
    required int xpAmount,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'xp': FieldValue.increment(xpAmount),
      });

      // Check for level-up (every 500 XP = 1 level)
      final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection
          .doc(uid)
          .get();
      final Map<String, dynamic> data = doc.data() ?? {};

      final int currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      final int currentLevel = (data['level'] as num?)?.toInt() ?? 1;
      final int newLevel = (currentXp ~/ 500) + 1;

      if (newLevel > currentLevel) {
        await _usersCollection.doc(uid).update({'level': newLevel});
        AppLogger.instance.i('User $uid leveled up: $currentLevel → $newLevel');
      }

      final DocumentSnapshot<Map<String, dynamic>> updatedDoc =
          await _usersCollection.doc(uid).get();
      return Success<UserEntity>(_mapDocToUser(updatedDoc));
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('awardXp failed', error: e);
      return Failure<UserEntity>(
        FirestoreException(
          message: e.message ?? 'Failed to award XP',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Update the daily streak counter.
  Future<Result<void>> updateStreak({
    required String uid,
    required int streakDays,
  }) async {
    try {
      await _usersCollection.doc(uid).update({'streakDays': streakDays});
      return const Success<void>(null);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('updateStreak failed', error: e);
      return Failure<void>(
        FirestoreException(
          message: e.message ?? 'Failed to update streak',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Update user profile fields.
  Future<Result<void>> updateProfile({
    required String uid,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (updates.isEmpty) return const Success<void>(null);

      await _usersCollection.doc(uid).update(updates);
      return const Success<void>(null);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('updateProfile failed', error: e);
      return Failure<void>(
        FirestoreException(
          message: e.message ?? 'Failed to update profile',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Admin: change a user's role.
  Future<Result<void>> setUserRole({
    required String uid,
    required UserRole role,
  }) async {
    try {
      await _usersCollection.doc(uid).update({'role': role.name});
      AppLogger.instance.i('User role changed: $uid → ${role.name}');
      return const Success<void>(null);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('setUserRole failed', error: e);
      return Failure<void>(
        FirestoreException(
          message: e.message ?? 'Failed to set user role',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Fetch leaderboard (Accuracy & Efficiency).
  ///
  /// Primary Sort: totalCorrectAnswers (Descending)
  /// Tie-Breaker 1: totalExamsTaken (Ascending)
  /// Tie-Breaker 2: lastExamCompletedAt (Ascending)
  ///
  /// Admin users are filtered out **client-side** after fetching [limit] rows.
  /// [limit] is intentionally generous (default 200).
  ///
  /// A 10-second hard timeout is applied.
  Future<Result<List<UserEntity>>> fetchLeaderboard({int limit = 200}) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection
              .orderBy('totalCorrectAnswers', descending: true)
              .orderBy('totalExamsTaken', descending: false)
              .orderBy('lastExamCompletedAt', descending: false)
              .limit(limit)
              .get()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw FirebaseException(
                  plugin: 'cloud_firestore',
                  code: 'timeout',
                  message: 'Leaderboard query timed out after 10 seconds.',
                ),
              );

      final List<UserEntity> users = snapshot.docs
          .map(_mapDocToUser)
          .where((user) => user.role == UserRole.student)
          .toList();

      if (users.isEmpty) {
        AppLogger.instance.w(
          'fetchLeaderboard returned 0 students '
          '(${snapshot.docs.length} total docs fetched). '
          'Check that user documents have valid "totalCorrectAnswers" and "totalExamsTaken" fields and role="student".',
        );
      }

      return Success<List<UserEntity>>(users);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('fetchLeaderboard failed', error: e);
      return Failure<List<UserEntity>>(
        FirestoreException(
          message: e.message ?? 'Failed to fetch leaderboard',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Fetch all users (admin).
  Future<Result<List<UserEntity>>> fetchAllUsers() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection.orderBy('createdAt', descending: true).get();
      final List<UserEntity> users = snapshot.docs.map(_mapDocToUser).toList();
      return Success<List<UserEntity>>(users);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('fetchAllUsers failed', error: e);
      return Failure<List<UserEntity>>(
        FirestoreException(
          message: e.message ?? 'Failed to fetch users',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Fetch total user count (admin).
  Future<Result<int>> fetchUserCount() async {
    try {
      final AggregateQuerySnapshot snapshot = await _usersCollection
          .count()
          .get();
      return Success<int>(snapshot.count ?? 0);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('fetchUserCount failed', error: e);
      return Failure<int>(
        FirestoreException(
          message: e.message ?? 'Failed to count users',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Award Coins to a user.
  Future<Result<UserEntity>> awardCoins({
    required String uid,
    required int coinsAmount,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'coins': FieldValue.increment(coinsAmount),
      });

      final DocumentSnapshot<Map<String, dynamic>> updatedDoc =
          await _usersCollection.doc(uid).get();
      return Success<UserEntity>(_mapDocToUser(updatedDoc));
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('awardCoins failed', error: e);
      return Failure<UserEntity>(
        FirestoreException(
          message: e.message ?? 'Failed to award coins',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Purchase/Unlock an avatar and deduct coins.
  Future<Result<UserEntity>> purchaseAvatar({
    required String uid,
    required String avatarId,
    required int price,
  }) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      final data = doc.data() ?? {};
      final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;

      if (currentCoins < price) {
        return const Failure<UserEntity>(
          ValidationException(
            message: 'Not enough coins to purchase this avatar.',
            code: 'insufficient-funds',
            fieldErrors: {},
          ),
        );
      }

      await _usersCollection.doc(uid).update({
        'coins': FieldValue.increment(-price),
        'unlockedAvatars': FieldValue.arrayUnion([avatarId]),
      });

      final updatedDoc = await _usersCollection.doc(uid).get();
      return Success<UserEntity>(_mapDocToUser(updatedDoc));
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('purchaseAvatar failed', error: e);
      return Failure<UserEntity>(
        FirestoreException(
          message: e.message ?? 'Failed to purchase avatar',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Update user leaderboard stats (totalCorrectAnswers and totalExamsTaken).
  Future<Result<void>> updateUserLeaderboardStats({
    required String uid,
    required int newCorrectAnswers,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'totalCorrectAnswers': FieldValue.increment(newCorrectAnswers),
        'totalExamsTaken': FieldValue.increment(1),
        'lastExamCompletedAt': FieldValue.serverTimestamp(),
      });
      return const Success<void>(null);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('updateUserLeaderboardStats failed', error: e);
      return Failure<void>(
        FirestoreException(
          message: e.message ?? 'Failed to update leaderboard stats',
          code: e.code,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  UserEntity _mapDocToUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? {};

    return UserEntity(
      uid: data['uid'] as String? ?? doc.id,
      email: data['email'] as String? ?? 'N/A',
      displayName: data['displayName'] as String? ?? 'Guest User',
      role: UserRole.fromString(data['role'] as String? ?? 'student'),
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      totalCorrectAnswers: (data['totalCorrectAnswers'] as num?)?.toInt() ?? 0,
      totalExamsTaken: (data['totalExamsTaken'] as num?)?.toInt() ?? 0,
      lastExamCompletedAt: (data['lastExamCompletedAt'] as Timestamp?)
          ?.toDate(),
      avatarUrl: data['avatarUrl'] as String? ?? '',
      unlockedAvatars: List<String>.from(
        (data['unlockedAvatars'] as List?)?.whereType<String>() ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
