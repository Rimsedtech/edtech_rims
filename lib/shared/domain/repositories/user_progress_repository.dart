import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Abstract contract for user progress mutations: XP, coins, streaks,
/// avatar purchases, and leaderboard stat updates.
///
/// BLoCs and Cubits depend only on this interface to stay decoupled
/// from the concrete Firebase implementation.
///
/// Read-only profile operations live in [UserRepository].
abstract class UserProgressRepository {
  /// Award XP to a user and trigger a level-up check.
  Future<Result<UserEntity>> awardXp({
    required String uid,
    required int xpAmount,
  });

  /// Update the user's daily streak counter.
  Future<Result<void>> updateStreak({
    required String uid,
    required int streakDays,
  });

  /// Award coins to a user.
  Future<Result<UserEntity>> awardCoins({
    required String uid,
    required int coinsAmount,
  });

  /// Purchase/unlock an avatar and atomically deduct coins.
  Future<Result<UserEntity>> purchaseAvatar({
    required String uid,
    required String avatarId,
    required int price,
  });

  /// Increment leaderboard counters after an exam attempt is completed.
  Future<Result<void>> updateUserLeaderboardStats({
    required String uid,
    required int newCorrectAnswers,
  });
}
