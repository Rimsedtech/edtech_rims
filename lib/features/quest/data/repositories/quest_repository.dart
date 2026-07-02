import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/shared/models/quest_model.dart';

import 'package:bitwise_academy/features/quest/domain/repositories/quest_repository.dart';

/// Firestore-backed implementation of [QuestRepository].
class QuestRepositoryImpl
    with FirebaseGuardedExecution
    implements QuestRepository {
  final FirebaseFirestore _firestore;

  QuestRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _questsCollection =>
      _firestore.collection('quests');

  /// Watch all active quests.
  @override
  Stream<Result<List<QuestModel>>> watchActiveQuests() {
    return guardedStream(
      () => _questsCollection
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map(_mapDocToQuest).toList();
          }),
      taskName: 'watchActiveQuests',
    );
  }

  /// Fetch all quests (admin).
  @override
  Future<Result<List<QuestModel>>> fetchAllQuests() async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _questsCollection.get();

      return snapshot.docs.map(_mapDocToQuest).toList();
    }, taskName: 'fetchAllQuests');
  }

  /// Create a new quest (admin only).
  @override
  Future<Result<QuestModel>> createQuest({
    required String title,
    required String description,
    required QuestType type,
    required int targetValue,
    required int xpReward,
    required String iconName,
  }) async {
    return guardedTask(() async {
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'type': type.name,
        'targetValue': targetValue,
        'xpReward': xpReward,
        'iconName': iconName,
        'isActive': true,
      };

      final DocumentReference<Map<String, dynamic>> docRef =
          await _questsCollection.add(data);
      AppLogger.instance.i('Quest created: ${docRef.id}');

      final DocumentSnapshot<Map<String, dynamic>> doc = await docRef.get();
      return _mapDocToQuest(doc);
    }, taskName: 'createQuest');
  }

  /// Update a quest (admin only).
  @override
  Future<Result<void>> updateQuest({
    required String questId,
    required Map<String, dynamic> updates,
  }) async {
    return guardedTask(() async {
      await _questsCollection.doc(questId).update(updates);
      AppLogger.instance.i('Quest updated: $questId');
    }, taskName: 'updateQuest');
  }

  /// Delete a quest (admin only).
  @override
  Future<Result<void>> deleteQuest(String questId) async {
    return guardedTask(() async {
      await _questsCollection.doc(questId).delete();
      AppLogger.instance.i('Quest deleted: $questId');
    }, taskName: 'deleteQuest');
  }

  QuestModel _mapDocToQuest(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? {};
    return QuestModel(
      id: doc.id,
      // Safe casts: Firestore documents can have missing fields if they were
      // partially written (e.g., network drop during admin save).
      title: data['title'] as String? ?? 'Unnamed Quest',
      description: data['description'] as String? ?? '',
      type: QuestType.fromString(data['type'] as String? ?? 'daily'),
      targetValue: (data['targetValue'] as num?)?.toInt() ?? 1,
      xpReward: (data['xpReward'] as num?)?.toInt() ?? 0,
      iconName: data['iconName'] as String? ?? 'bolt',
      isActive: data['isActive'] as bool? ?? false,
    );
  }
}
