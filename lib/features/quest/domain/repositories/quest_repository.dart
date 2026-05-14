import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/quest_model.dart';

/// Abstract contract for quest/achievement data operations.
///
/// BLoCs and Cubits depend only on this interface to stay decoupled
/// from the concrete Firebase implementation.
abstract class QuestRepository {
  /// Watch all active quests as a real-time stream (students).
  Stream<Result<List<QuestModel>>> watchActiveQuests();

  /// Fetch all quests regardless of status (admin).
  Future<Result<List<QuestModel>>> fetchAllQuests();

  /// Create a new quest (admin only).
  Future<Result<QuestModel>> createQuest({
    required String title,
    required String description,
    required QuestType type,
    required int targetValue,
    required int xpReward,
    required String iconName,
  });

  /// Update a quest (admin only).
  Future<Result<void>> updateQuest({
    required String questId,
    required Map<String, dynamic> updates,
  });

  /// Delete a quest (admin only).
  Future<Result<void>> deleteQuest(String questId);
}
