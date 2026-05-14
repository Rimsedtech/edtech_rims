import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';

import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';

/// Firestore-backed implementation of [AttemptRepository].
///
/// Attempts are immutable once completed per security rules.
class AttemptRepositoryImpl
    with FirebaseGuardedExecution
    implements AttemptRepository {
  final FirebaseFirestore _firestore;

  AttemptRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _attemptsCollection =>
      _firestore.collection('attempts');

  /// Start a new exam attempt.
  @override
  Future<Result<AttemptModel>> startAttempt({
    required String userId,
    required String examId,
    required int totalPoints,
  }) async {
    return guardedTask(() async {
      final Map<String, dynamic> data = {
        'userId': userId,
        'examId': examId,
        'startedAt': FieldValue.serverTimestamp(),
        'completedAt': null,
        'score': 0,
        'totalPoints': totalPoints,
        'xpEarned': 0,
        'status': AttemptStatus.inProgress.firestoreValue,
        'answers': <String, dynamic>{},
      };

      final DocumentReference<Map<String, dynamic>> docRef =
          await _attemptsCollection.add(data);
      final DocumentSnapshot<Map<String, dynamic>> doc = await docRef.get();
      return _mapDocToAttempt(doc);
    }, taskName: 'startAttempt');
  }

  /// Submit an answer for a question during an attempt.
  @override
  Future<Result<void>> submitAnswer({
    required String attemptId,
    required String questionId,
    required dynamic answer,
  }) async {
    return guardedTask(() async {
      await _attemptsCollection.doc(attemptId).update({
        'answers.$questionId': answer,
      });
    }, taskName: 'submitAnswer');
  }

  /// Complete an attempt with final score.
  @override
  Future<Result<AttemptModel>> completeAttempt({
    required String attemptId,
    required int score,
    required int correctCount,
    required int xpEarned,
  }) async {
    return guardedTask(() async {
      await _attemptsCollection.doc(attemptId).update({
        'completedAt': FieldValue.serverTimestamp(),
        'score': score,
        'correctCount': correctCount,
        'xpEarned': xpEarned,
        'status': AttemptStatus.completed.firestoreValue,
      });

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _attemptsCollection.doc(attemptId).get();
      return _mapDocToAttempt(doc);
    }, taskName: 'completeAttempt');
  }

  /// Fetch all attempts for a specific user.
  @override
  Future<Result<List<AttemptModel>>> fetchUserAttempts(String userId) async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _attemptsCollection
              .where('userId', isEqualTo: userId)
              .orderBy('startedAt', descending: true)
              .get();

      return snapshot.docs.map(_mapDocToAttempt).toList();
    }, taskName: 'fetchUserAttempts');
  }

  /// Fetch all attempts for a specific exam (admin).
  @override
  Future<Result<List<AttemptModel>>> fetchExamAttempts(String examId) async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _attemptsCollection
              .where('examId', isEqualTo: examId)
              .orderBy('startedAt', descending: true)
              .get();

      return snapshot.docs.map(_mapDocToAttempt).toList();
    }, taskName: 'fetchExamAttempts');
  }

  /// Get stats for a user: total attempts, average score, etc.
  @override
  Future<Result<Map<String, dynamic>>> fetchUserStats(String userId) async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _attemptsCollection
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .get();

      final List<AttemptModel> completed = snapshot.docs
          .map(_mapDocToAttempt)
          .toList();

      final int totalCompleted = completed.length;
      final double averageScore = totalCompleted > 0
          ? completed.fold<double>(
                  0,
                  (double sum, AttemptModel a) => sum + a.scorePercentage,
                ) /
                totalCompleted
          : 0;
      final int totalXp = completed.fold<int>(
        0,
        (int sum, AttemptModel a) => sum + a.xpEarned,
      );

      return {
        'totalCompleted': totalCompleted,
        'averageScore': averageScore,
        'totalXpEarned': totalXp,
      };
    }, taskName: 'fetchUserStats');
  }

  AttemptModel _mapDocToAttempt(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;
    return AttemptModel(
      id: doc.id,
      userId: data['userId'] as String,
      examId: data['examId'] as String,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      score: (data['score'] as num).toInt(),
      correctCount: (data['correctCount'] as num?)?.toInt() ?? 0,
      totalPoints: (data['totalPoints'] as num).toInt(),
      xpEarned: (data['xpEarned'] as num).toInt(),
      status: AttemptStatus.fromString(data['status'] as String),
      answers: Map<String, dynamic>.from(data['answers'] as Map? ?? {}),
    );
  }
}
