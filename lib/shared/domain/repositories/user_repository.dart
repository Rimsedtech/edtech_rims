import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Abstract contract for user profile read operations.
///
/// BLoCs and Cubits depend only on this interface to stay decoupled
/// from the concrete Firebase implementation.
///
/// Progress mutations (XP, coins, streaks, avatar purchase) are in
/// [UserProgressRepository].
abstract class UserRepository {
  /// Fetch a single user profile by UID.
  Future<Result<UserEntity>> fetchUser(String uid);

  /// Watch a user profile in real time.
  Stream<Result<UserEntity>> watchUser(String uid);

  /// Update the user's display name and/or avatar URL.
  Future<Result<void>> updateProfile({
    required String uid,
    String? displayName,
    String? avatarUrl,
  });

  /// Admin: set a user's role.
  Future<Result<void>> setUserRole({
    required String uid,
    required UserRole role,
  });

  /// Fetch the leaderboard (accuracy + efficiency ranking).
  ///
  /// [limit] controls how many documents are fetched before client-side
  /// admin filtering. Defaults to 200.
  Future<Result<List<UserEntity>>> fetchLeaderboard({int limit = 200});

  /// Fetch all users (admin only).
  Future<Result<List<UserEntity>>> fetchAllUsers();

  /// Fetch total user count (admin only).
  Future<Result<int>> fetchUserCount();
}
