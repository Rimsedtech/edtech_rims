import 'dart:io';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

/// Abstract contract for all exam-related data operations.
///
/// BLoCs and Cubits depend only on this interface — never on the
/// concrete [ExamRepositoryImpl] — to keep the presentation layer
/// decoupled from Firebase and allow easy test fakes.
abstract class ExamRepository {
  /// Fetch all published exams (for students).
  Future<Result<List<ExamModel>>> fetchPublishedExams();

  /// Watch all published exams as a real-time stream (for students).
  Stream<Result<List<ExamModel>>> watchPublishedExams();

  /// Fetch ALL exams regardless of status (for admins).
  Future<Result<List<ExamModel>>> fetchAllExams();

  /// Fetch a single exam by ID.
  Future<Result<ExamModel>> fetchExamById(String examId);

  /// Fetch all questions for an exam.
  Future<Result<List<QuestionModel>>> fetchQuestions(String examId);

  /// Create a new exam (admin only).
  Future<Result<ExamModel>> createExam({
    required String title,
    required String description,
    required String subject,
    required String group,
    required DifficultyTier difficultyTier,
    required int durationMinutes,
    required String createdBy,
    required int xpReward,
    File? attachmentFile,
  });

  /// Upload a file to Firebase Storage under `exam_assets/{examId}/`.
  Future<Result<String>> uploadExamFile({
    required String examId,
    required File file,
  });

  /// Add multiple questions to an exam in a single batch write (admin only).
  Future<Result<void>> addQuestionsBatch({
    required String examId,
    required List<QuestionModel> questions,
  });

  /// Update exam metadata (admin only).
  Future<Result<void>> updateExam({
    required String examId,
    Map<String, dynamic>? updates,
  });

  /// Publish an exam (change status to published).
  Future<Result<void>> publishExam(String examId);

  /// Archive an exam.
  Future<Result<void>> archiveExam(String examId);

  /// Delete an exam and all its questions (admin only).
  Future<Result<void>> deleteExam(String examId);

  /// Delete a single question from an exam (admin only).
  Future<Result<void>> deleteQuestion({
    required String examId,
    required String questionId,
  });
}
