import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

import 'package:bitwise_academy/shared/domain/repositories/user_progress_repository.dart';

/// Firestore-backed implementation of [UserProgressRepository].
///
/// Handles XP, coins, streaks, avatar purchases, and leaderboard stat updates.
/// Read-only profile operations (watch, fetch, update display name /
/// avatar URL, role management) live in [UserRepository].
class UserProgressRepositoryImpl implements UserProgressRepository {
  final FirebaseFirestore _firestore;

  UserProgressRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ── XP & Level ────────────────────────────────────────────────────────────

  /// Award XP to a user and check for level-up (every 500 XP = 1 level).
  @override
  Future<Result<UserEntity>> awardXp({
    required String uid,
    required int xpAmount,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'xp': FieldValue.increment(xpAmount),
      });

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

  // ── Streak ────────────────────────────────────────────────────────────────

  /// Update the daily streak counter.
  @override
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

  // ── Coins & Avatar Purchase ────────────────────────────────────────────────

  /// Award coins to a user.
  @override
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

  /// Purchase / unlock an avatar and deduct coins atomically.
  @override
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

  // ── Leaderboard Stats ─────────────────────────────────────────────────────

  /// Increment leaderboard counters after an exam is completed.
  @override
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

  // ── Internal Mapper ───────────────────────────────────────────────────────

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
