import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

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
    String? examTitle,
    List<QuestionModel>? questions,
  }) async {
    return guardedTask(() async {
      final docRef = _attemptsCollection.doc();
      final Map<String, dynamic> data = {
        'id': docRef.id,
        'userId': userId,
        'examId': examId,
        'examTitle': examTitle,
        'startedAt': Timestamp.now(),
        'completedAt': null,
        'score': 0,
        'correctCount': 0,
        'totalPoints': totalPoints,
        'xpEarned': 0,
        'status': AttemptStatus.inProgress.firestoreValue,
        'answers': <String, dynamic>{},
        if (questions != null)
          'questions': questions.map((q) => q.toJson()).toList(),
      };

      await docRef.set(data);
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

  /// Fetch the most recent active attempt for a user.
  @override
  Future<Result<AttemptModel?>> fetchActiveAttempt(String userId) async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _attemptsCollection
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: AttemptStatus.inProgress.firestoreValue)
              .orderBy('startedAt', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;
      return _mapDocToAttempt(snapshot.docs.first);
    }, taskName: 'fetchActiveAttempt');
  }

  /// Admin: fetch the total count of all completed attempts across the entire platform.
  @override
  Future<Result<int>> fetchTotalCompletedAttemptsCount() async {
    return guardedTask(() async {
      final AggregateQuerySnapshot snapshot = await _attemptsCollection
          .where('status', isEqualTo: AttemptStatus.completed.firestoreValue)
          .count()
          .get();
      return snapshot.count ?? 0;
    }, taskName: 'fetchTotalCompletedAttemptsCount');
  }

  /// Admin: fetch the total count of completed attempts today across the entire platform.
  @override
  Future<Result<int>> fetchTodayCompletedAttemptsCount() async {
    return guardedTask(() async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final AggregateQuerySnapshot snapshot = await _attemptsCollection
          .where('status', isEqualTo: AttemptStatus.completed.firestoreValue)
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .count()
          .get();
      return snapshot.count ?? 0;
    }, taskName: 'fetchTodayCompletedAttemptsCount');
  }

  AttemptModel _mapDocToAttempt(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? {};
    
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return AttemptModel(
      id: data['id'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? 'unknown',
      examId: data['examId'] as String? ?? 'unknown',
      examTitle: data['examTitle'] as String?,
      startedAt: data['startedAt'] != null ? parseDate(data['startedAt']) : DateTime.now(),
      completedAt: data['completedAt'] != null ? parseDate(data['completedAt']) : null,
      score: (data['score'] as num?)?.toInt() ?? 0,
      correctCount: (data['correctCount'] as num?)?.toInt() ?? 0,
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
      status: AttemptStatus.fromString(data['status'] as String? ?? 'inProgress'),
      // Safely cast the answers map: values are always strings (option text),
      // but defensive toString() guards against legacy int-typed values.
      answers: (data['answers'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ),
      questions: data['questions'] != null
          ? (data['questions'] as List<dynamic>)
              .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q as Map)))
              .toList()
          : null,
    );
  }
}
