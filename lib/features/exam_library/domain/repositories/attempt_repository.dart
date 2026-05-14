import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';

/// Abstract contract for exam attempt data operations.
///
/// BLoCs and Cubits depend only on this interface to stay decoupled
/// from the concrete Firebase implementation.
abstract class AttemptRepository {
  /// Start a new exam attempt.
  Future<Result<AttemptModel>> startAttempt({
    required String userId,
    required String examId,
    required int totalPoints,
  });

  /// Submit an answer for a question during an active attempt.
  Future<Result<void>> submitAnswer({
    required String attemptId,
    required String questionId,
    required dynamic answer,
  });

  /// Complete an attempt with the final score and XP earned.
  Future<Result<AttemptModel>> completeAttempt({
    required String attemptId,
    required int score,
    required int correctCount,
    required int xpEarned,
  });

  /// Fetch all completed attempts for a user (ordered most-recent first).
  Future<Result<List<AttemptModel>>> fetchUserAttempts(String userId);

  /// Fetch all attempts for an exam (admin view).
  Future<Result<List<AttemptModel>>> fetchExamAttempts(String examId);

  /// Aggregate stats (totalCompleted, averageScore, totalXpEarned) for a user.
  Future<Result<Map<String, dynamic>>> fetchUserStats(String userId);
}
