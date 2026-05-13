import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

/// Standalone service for handling random mock test retrieval.
///
/// Uses [collectionGroup] queries with wrap-around logic to ensure
/// truly random question selection across all exams.
class MockTestService with FirebaseGuardedExecution {
  final FirebaseFirestore _firestore;

  MockTestService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Fetches a random set of [count] questions matching the criteria.
  ///
  /// This method uses a two-query "forward and backward slice" strategy:
  /// 1. Query for questions where `random >= seed`.
  /// 2. If [count] isn't reached, query for questions where `random < seed`.
  ///
  /// This ensures wrap-around logic is implemented correctly and we don't
  /// get empty results unless no questions match the filters at all.
  Future<Result<List<QuestionModel>>> fetchRandomQuestions({
    required String subject,
    required String difficultyTier,
    required String group,
    int count = 10,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;

    while (attempts < maxAttempts) {
      attempts++;
      // Tiered timeouts: 5s for the first "wake-up" attempt, 10s for the retry.
      final currentTimeout = attempts == 1
          ? const Duration(seconds: 5)
          : const Duration(seconds: 10);

      final result = await guardedTask(
        () async {
          final double seed = Random().nextDouble();

          // 1. Forward Slice: [seed, 1.0]
          final forwardSnap = await _firestore
              .collectionGroup('questions')
              .where('subject', isEqualTo: subject)
              .where('difficultyTier', isEqualTo: difficultyTier)
              .where('group', isEqualTo: group)
              .where('random', isGreaterThanOrEqualTo: seed)
              .orderBy('random')
              .limit(count)
              .get();

          final List<QuestionModel> pool = forwardSnap.docs
              .map((doc) => _mapDocToQuestion(doc))
              .toList();

          // 2. Backward Slice: [0.0, seed) - SKIPPED if we already have enough questions
          if (pool.length < count) {
            final remainingCount = count - pool.length;
            final backwardSnap = await _firestore
                .collectionGroup('questions')
                .where('subject', isEqualTo: subject)
                .where('difficultyTier', isEqualTo: difficultyTier)
                .where('group', isEqualTo: group)
                .where('random', isLessThan: seed)
                .orderBy('random', descending: true)
                .limit(remainingCount)
                .get();

            final backwardQuestions = backwardSnap.docs
                .map((doc) => _mapDocToQuestion(doc))
                .toList();

            pool.addAll(backwardQuestions);
          }

          if (pool.isEmpty) {
            throw const NotFoundException(
              message: 'No questions found for the given criteria.',
              code: 'questions-not-found',
            );
          }

          // Shuffle the final pool for extra randomness
          pool.shuffle(Random());
          return pool;
        },
        taskName: 'fetchRandomQuestions (Attempt $attempts)',
        timeout: currentTimeout,
      );

      // Return immediately on success
      if (result is Success<List<QuestionModel>>) return result;

      // Only retry if it was a timeout and we have attempts left
      final failure = result as Failure<List<QuestionModel>>;
      final exception = failure.exception;
      if (attempts < maxAttempts &&
          exception is AppException &&
          exception.code == 'timeout') {
        continue;
      }

      // Otherwise, return the final failure
      return result;
    }

    return const Failure(
      FirestoreException(
        message: 'Max retries reached while fetching questions.',
        code: 'retry-exhausted',
      ),
    );
  }

  /// Maps a Firestore document to a [QuestionModel].
  QuestionModel _mapDocToQuestion(DocumentSnapshot<Map<String, dynamic>> doc) {
    return QuestionModel.fromFirestore(doc);
  }
}
