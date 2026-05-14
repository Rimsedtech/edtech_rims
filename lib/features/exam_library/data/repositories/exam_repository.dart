import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

import 'package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart';

/// Firestore-backed implementation of [ExamRepository].
///
/// Handles CRUD for exams and their questions sub-collection.
/// Random-question retrieval (mock tests) is handled by [MockTestService]
/// and should be called from the BLoC layer — not via this repository.
class ExamRepositoryImpl with FirebaseGuardedExecution implements ExamRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ExamRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  CollectionReference<Map<String, dynamic>> get _examsCollection =>
      _firestore.collection('exams');

  // ── READ ──

  /// Fetch all published exams (for students).
  @override
  Future<Result<List<ExamModel>>> fetchPublishedExams() async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _examsCollection
              .where('status', isEqualTo: 'published')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map(_mapDocToExam).toList();
    }, taskName: 'fetchPublishedExams');
  }

  /// Watch all published exams (for students).
  @override
  Stream<Result<List<ExamModel>>> watchPublishedExams() {
    return guardedStream(
      () => _examsCollection
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map(_mapDocToExam).toList();
          }),
      taskName: 'watchPublishedExams',
    );
  }

  /// Fetch ALL exams regardless of status (for admins).
  @override
  Future<Result<List<ExamModel>>> fetchAllExams() async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _examsCollection.orderBy('updatedAt', descending: true).get();

      return snapshot.docs.map(_mapDocToExam).toList();
    }, taskName: 'fetchAllExams');
  }

  /// Fetch a single exam by ID.
  @override
  Future<Result<ExamModel>> fetchExamById(String examId) async {
    return guardedTask(() async {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _examsCollection
          .doc(examId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw NotFoundException(
          message: 'Exam not found: $examId',
          code: 'exam-not-found',
        );
      }
      return _mapDocToExam(doc);
    }, taskName: 'fetchExamById');
  }

  /// Fetch all questions for an exam.
  @override
  Future<Result<List<QuestionModel>>> fetchQuestions(String examId) async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _examsCollection
              .doc(examId)
              .collection('questions')
              .orderBy('order')
              .get();

      return snapshot.docs.map(_mapDocToQuestion).toList();
    }, taskName: 'fetchQuestions');
  }

  /// Create a new exam (admin only).
  ///
  /// If [attachmentFile] is provided, it will be uploaded to Firebase Storage
  /// and its download URL stored in the exam document as `attachmentUrl`.
  @override
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
  }) async {
    return guardedTask(() async {
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'subject': subject,
        'difficultyTier': difficultyTier.firestoreValue,
        'durationMinutes': durationMinutes,
        'createdBy': createdBy,
        'status': ExamStatus.draft.name,
        'xpReward': xpReward,
        'questionCount': 0,
        // Denormalised for collectionGroup queries
        'group': group,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final DocumentReference<Map<String, dynamic>> docRef =
          await _examsCollection.add(data);
      AppLogger.instance.i('Exam created: ${docRef.id}');

      // Upload attachment if provided
      if (attachmentFile != null) {
        final attachmentResult = await uploadExamFile(
          examId: docRef.id,
          file: attachmentFile,
        );
        switch (attachmentResult) {
          case Success(:final data):
            await docRef.update({'attachmentUrl': data});
          case Failure(:final errorMessage):
            AppLogger.instance.w(
              'Exam created but file upload failed: $errorMessage',
            );
        }
      }

      final DocumentSnapshot<Map<String, dynamic>> doc = await docRef.get();
      return _mapDocToExam(doc);
    }, taskName: 'createExam');
  }

  /// Uploads a file to Firebase Storage under `exam_assets/{examId}/`.
  ///
  /// Returns the download URL of the uploaded file on success.
  @override
  Future<Result<String>> uploadExamFile({
    required String examId,
    required File file,
  }) async {
    return guardedTask(() async {
      final fileName =
          'exam_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = _storage.ref().child('exam_assets/$examId/$fileName');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      AppLogger.instance.i('Exam file uploaded: $downloadUrl');
      return downloadUrl;
    }, taskName: 'uploadExamFile');
  }

  /// Add multiple questions to an exam in a single batch write (admin only).
  ///
  /// Handles the Firestore 500-operation limit by automatically splitting
  /// into multiple batches if necessary.
  @override
  Future<Result<void>> addQuestionsBatch({
    required String examId,
    required List<QuestionModel> questions,
  }) async {
    return guardedTask(() async {
      // Fetch the parent exam for denormalised metadata
      final DocumentSnapshot<Map<String, dynamic>> examDoc =
          await _examsCollection.doc(examId).get();

      if (!examDoc.exists) {
        throw NotFoundException(
          message: 'Exam $examId not found',
          code: 'exam-not-found',
        );
      }

      final examData = examDoc.data() ?? {};
      final subject = examData['subject'] as String? ?? '';
      final difficultyTier = examData['difficultyTier'] as String? ?? '';
      final group = examData['group'] as String? ?? '';

      final collection = _examsCollection.doc(examId).collection('questions');

      // Firestore batches have a limit of 500 operations.
      // We use chunks of 490 to be safe and leave room for the exam doc update.
      const int chunkSize = 490;
      for (var i = 0; i < questions.length; i += chunkSize) {
        final chunk = questions.sublist(
          i,
          i + chunkSize > questions.length ? questions.length : i + chunkSize,
        );

        final WriteBatch batch = _firestore.batch();

        for (final q in chunk) {
          final docRef = collection.doc();
          batch.set(docRef, {
            'questionText': q.questionText,
            'questionType': q.questionType.firestoreValue,
            'options': q.options,
            'correctAnswer': q.correctAnswer,
            'explanation': q.explanation,
            'points': q.points,
            'order': q.order,
            if (q.diagramUrl != null) 'diagramUrl': q.diagramUrl,
            // Denormalised for collectionGroup queries
            'subject': subject,
            'difficultyTier': difficultyTier,
            'group': group,
            'random': Random().nextDouble(),
          });
        }

        // Only the LAST batch (or the only batch) updates the exam metadata
        if (i + chunkSize >= questions.length) {
          batch.update(_examsCollection.doc(examId), {
            'questionCount': FieldValue.increment(questions.length),
            'updatedAt': FieldValue.serverTimestamp(),
            'status': ExamStatus.published.name, // Auto-publish on finish?
            // Note: The user might want it to stay in draft.
            // But usually, finishing means it's ready.
          });
        }

        await batch.commit();
      }

      AppLogger.instance.i(
        'Batch added ${questions.length} questions to exam $examId',
      );
    }, taskName: 'addQuestionsBatch');
  }

  // ── UPDATE ──

  /// Update exam metadata (admin only).
  @override
  Future<Result<void>> updateExam({
    required String examId,
    Map<String, dynamic>? updates,
  }) async {
    return guardedTask(() async {
      final Map<String, dynamic> data = {
        ...?updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _examsCollection.doc(examId).update(data);
      AppLogger.instance.i('Exam updated: $examId');
    }, taskName: 'updateExam');
  }

  /// Publish an exam (change status to published).
  @override
  Future<Result<void>> publishExam(String examId) async {
    return updateExam(
      examId: examId,
      updates: {'status': ExamStatus.published.name},
    );
  }

  /// Archive an exam.
  @override
  Future<Result<void>> archiveExam(String examId) async {
    return updateExam(
      examId: examId,
      updates: {'status': ExamStatus.archived.name},
    );
  }
  // ── DELETE ──

  /// Delete an exam and all its questions (admin only).
  @override
  Future<Result<void>> deleteExam(String examId) async {
    return guardedTask(() async {
      // Delete questions sub-collection first
      final QuerySnapshot<Map<String, dynamic>> questions =
          await _examsCollection.doc(examId).collection('questions').get();
      final WriteBatch batch = _firestore.batch();
      for (final DocumentSnapshot<Map<String, dynamic>> doc in questions.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_examsCollection.doc(examId));
      await batch.commit();

      AppLogger.instance.i('Exam deleted: $examId');
    }, taskName: 'deleteExam');
  }

  /// Delete a question from an exam (admin only).
  @override
  Future<Result<void>> deleteQuestion({
    required String examId,
    required String questionId,
  }) async {
    return guardedTask(() async {
      await _examsCollection
          .doc(examId)
          .collection('questions')
          .doc(questionId)
          .delete();

      // Update question count on the exam
      await _examsCollection.doc(examId).update({
        'questionCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.instance.i('Question deleted from exam $examId: $questionId');
    }, taskName: 'deleteQuestion');
  }

  // ── Mappers ──

  ExamModel _mapDocToExam(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ExamModel.fromFirestore(doc);
  }

  QuestionModel _mapDocToQuestion(DocumentSnapshot<Map<String, dynamic>> doc) {
    return QuestionModel.fromFirestore(doc);
  }
}
