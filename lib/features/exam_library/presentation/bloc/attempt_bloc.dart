import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart';
import 'package:bitwise_academy/features/exam_library/data/services/mock_test_service.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';
import 'package:bitwise_academy/shared/domain/repositories/user_progress_repository.dart';

// ── Events ──

sealed class AttemptEvent extends Equatable {
  const AttemptEvent();

  @override
  List<Object?> get props => [];
}

/// Start a new exam attempt: loads exam + questions, creates attempt doc.
final class StartAttemptRequested extends AttemptEvent {
  final String examId;
  final String userId;

  const StartAttemptRequested({required this.examId, required this.userId});

  @override
  List<Object?> get props => [examId, userId];
}

/// Start a random mock test: fetches random questions from across all exams.
final class StartRandomMockTestRequested extends AttemptEvent {
  final String userId;
  final String subject;
  final String group;

  const StartRandomMockTestRequested({
    required this.userId,
    required this.subject,
    required this.group,
  });

  @override
  List<Object?> get props => [userId, subject, group];
}

/// User selects an answer for the current question.
final class AnswerSelected extends AttemptEvent {
  final int questionIndex;
  final String selectedOption;

  const AnswerSelected({
    required this.questionIndex,
    required this.selectedOption,
  });

  @override
  List<Object?> get props => [questionIndex, selectedOption];
}

/// User submits the entire exam (or timer expires).
final class SubmitAttemptRequested extends AttemptEvent {
  const SubmitAttemptRequested();
}

/// Resume an existing in-progress attempt.
final class ResumeAttemptRequested extends AttemptEvent {
  final AttemptModel attempt;
  final ExamModel exam;

  const ResumeAttemptRequested({
    required this.attempt,
    required this.exam,
  });

  @override
  List<Object?> get props => [attempt, exam];
}

/// Fetch user's past attempts for stats.
final class LoadUserAttemptsRequested extends AttemptEvent {
  final String userId;

  const LoadUserAttemptsRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// ── States ──

sealed class AttemptState extends Equatable {
  const AttemptState();

  @override
  List<Object?> get props => [];
}

final class AttemptInitial extends AttemptState {
  const AttemptInitial();
}

final class AttemptLoadInProgress extends AttemptState {
  const AttemptLoadInProgress();
}

/// Active exam session — questions loaded, user is answering.
final class AttemptInProgress extends AttemptState {
  final ExamModel exam;
  final List<QuestionModel> questions;
  final AttemptModel attempt;
  final Map<int, String> selectedAnswers; // questionIndex -> selectedOption

  const AttemptInProgress({
    required this.exam,
    required this.questions,
    required this.attempt,
    required this.selectedAnswers,
  });

  int get answeredCount => selectedAnswers.length;
  int get totalQuestions => questions.length;

  @override
  List<Object?> get props => [exam, questions, attempt, selectedAnswers];
}

/// Exam completed — results ready.
///
/// [questions] and [selectedAnswers] are carried forward so the review
/// page can display correct/incorrect answers + explanations without
/// an extra Firestore round-trip.
final class AttemptCompleted extends AttemptState {
  final ExamModel exam;
  final AttemptModel attempt;
  final int correctCount;
  final int totalQuestions;
  /// Full ordered list of questions shown during the exam.
  final List<QuestionModel> questions;
  /// Map of questionIndex → the option string the student selected.
  final Map<int, String> selectedAnswers;

  const AttemptCompleted({
    required this.exam,
    required this.attempt,
    required this.correctCount,
    required this.totalQuestions,
    required this.questions,
    required this.selectedAnswers,
  });

  double get scorePercentage =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0;

  @override
  List<Object?> get props =>
      [exam, attempt, correctCount, totalQuestions, questions, selectedAnswers];
}

/// User stats loaded.
final class UserAttemptsLoaded extends AttemptState {
  final List<AttemptModel> attempts;
  final int totalCompleted;
  final double averageScore;

  const UserAttemptsLoaded({
    required this.attempts,
    required this.totalCompleted,
    required this.averageScore,
  });

  @override
  List<Object?> get props => [attempts, totalCompleted, averageScore];
}

final class AttemptFailure extends AttemptState {
  final String message;

  const AttemptFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ── BLoC ──

/// Manages the full lifecycle of an exam attempt:
/// load exam → start attempt → answer questions → submit → score.
class AttemptBloc extends Bloc<AttemptEvent, AttemptState> {
  final AttemptRepository _attemptRepository;
  final ExamRepository _examRepository;
  final MockTestService _mockTestService;
  final UserProgressRepository _userProgressRepository;

  AttemptBloc({
    required AttemptRepository attemptRepository,
    required ExamRepository examRepository,
    required MockTestService mockTestService,
    required UserProgressRepository userProgressRepository,
  }) : _attemptRepository = attemptRepository,
       _examRepository = examRepository,
       _mockTestService = mockTestService,
       _userProgressRepository = userProgressRepository,
       super(const AttemptInitial()) {
    on<StartAttemptRequested>(_onStartAttempt);
    on<StartRandomMockTestRequested>(_onStartRandomMockTest);
    on<AnswerSelected>(_onAnswerSelected);
    on<SubmitAttemptRequested>(_onSubmitAttempt);
    on<ResumeAttemptRequested>(_onResumeAttempt);
    on<LoadUserAttemptsRequested>(_onLoadUserAttempts);
  }

  Future<void> _onStartAttempt(
    StartAttemptRequested event,
    Emitter<AttemptState> emit,
  ) async {
    emit(const AttemptLoadInProgress());

    try {
      await _startAttemptWorkflow(event, emit).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('MISSION DATA RETRIEVAL TIMED OUT');
        },
      );
    } on TimeoutException catch (e) {
      emit(AttemptFailure(message: e.message ?? 'TIMEOUT'));
    } catch (e) {
      emit(AttemptFailure(message: e.toString()));
    }
  }

  Future<void> _startAttemptWorkflow(
    StartAttemptRequested event,
    Emitter<AttemptState> emit,
  ) async {
    // 1. Fetch the exam
    final examResult = await _examRepository.fetchExamById(event.examId);
    if (examResult case Failure(:final errorMessage)) {
      emit(AttemptFailure(message: errorMessage));
      return;
    }
    final exam = (examResult as Success<ExamModel>).data;

    // 2. Fetch questions
    final questionsResult = await _examRepository.fetchQuestions(event.examId);
    if (questionsResult case Failure(:final errorMessage)) {
      emit(AttemptFailure(message: errorMessage));
      return;
    }
    final questions = (questionsResult as Success<List<QuestionModel>>).data;

    if (questions.isEmpty) {
      emit(const AttemptFailure(message: 'This exam has no questions yet.'));
      return;
    }

    // 3. Calculate total points
    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);

    // 4. Create attempt doc in Firestore
    final attemptResult = await _attemptRepository.startAttempt(
      userId: event.userId,
      examId: event.examId,
      totalPoints: totalPoints,
      examTitle: exam.title,
      questions: questions,
    );

    switch (attemptResult) {
      case Success(:final data):
        emit(
          AttemptInProgress(
            exam: exam,
            questions: questions,
            attempt: data,
            selectedAnswers: const {},
          ),
        );
      case Failure(:final errorMessage):
        emit(AttemptFailure(message: errorMessage));
    }
  }

  Future<void> _onStartRandomMockTest(
    StartRandomMockTestRequested event,
    Emitter<AttemptState> emit,
  ) async {
    emit(const AttemptLoadInProgress());

    // 1. Fetch the source exam metadata for the selected subject and group
    final examsResult = await _examRepository.fetchPublishedExams();
    int targetQuestionCount = 20;
    int targetDurationMinutes = 45;
    int targetXpReward = 400;

    if (examsResult is Success<List<ExamModel>>) {
      try {
        final sourceExam = examsResult.data.firstWhere(
          (e) => e.subject == event.subject && e.group == event.group,
        );
        targetQuestionCount = sourceExam.questionCount > 0 ? sourceExam.questionCount : 20;
        targetDurationMinutes = sourceExam.durationMinutes;
        targetXpReward = sourceExam.xpReward;
      } catch (_) {
        // Fallback to defaults if no specific exam is found
      }
    }

    // 2. Fetch random questions directly from MockTestService
    final questionsResult = await _mockTestService.fetchRandomQuestions(
      subject: event.subject,
      group: event.group,
      count: targetQuestionCount,
    );
    if (questionsResult case Failure(:final errorMessage)) {
      emit(AttemptFailure(message: errorMessage));
      return;
    }
    final questions = (questionsResult as Success<List<QuestionModel>>).data;

    if (questions.isEmpty) {
      emit(
        const AttemptFailure(
          message:
              'We could not find any questions matching your selected test series and topic. Try different settings!',
        ),
      );
      return;
    }

    // 3. Create a virtual exam model
    final virtualExam = ExamModel(
      id: 'random_mock_${DateTime.now().millisecondsSinceEpoch}',
      title: 'RANDOM MOCK TEST: ${event.subject.toUpperCase()}',
      description: 'Automatically generated mission based on your selection.',
      subject: event.subject,
      group: event.group,
      durationMinutes: targetDurationMinutes,
      createdBy: 'system',
      status: ExamStatus.published,
      xpReward: targetXpReward,
      questionCount: questions.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 3. Calculate total points
    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);

    // 4. Create attempt doc in Firestore
    final attemptResult = await _attemptRepository.startAttempt(
      userId: event.userId,
      examId: virtualExam.id,
      totalPoints: totalPoints,
      examTitle: virtualExam.title,
      questions: questions,
    );

    switch (attemptResult) {
      case Success(:final data):
        emit(
          AttemptInProgress(
            exam: virtualExam,
            questions: questions,
            attempt: data,
            selectedAnswers: const {},
          ),
        );
      case Failure(:final errorMessage):
        emit(AttemptFailure(message: errorMessage));
    }
  }

  Future<void> _onResumeAttempt(
    ResumeAttemptRequested event,
    Emitter<AttemptState> emit,
  ) async {
    emit(const AttemptLoadInProgress());

    final questionsResult = await _examRepository.fetchQuestions(event.exam.id);
    if (questionsResult case Failure(:final errorMessage)) {
      emit(AttemptFailure(message: errorMessage));
      return;
    }
    
    final questions = (questionsResult as Success<List<QuestionModel>>).data;
    
    // Map question IDs from Firestore answers back to their indexes
    final Map<int, String> mappedAnswers = {};
    for (int i = 0; i < questions.length; i++) {
      final qId = questions[i].id;
      if (event.attempt.answers.containsKey(qId)) {
        mappedAnswers[i] = event.attempt.answers[qId] as String;
      }
    }

    emit(
      AttemptInProgress(
        exam: event.exam,
        questions: questions,
        attempt: event.attempt,
        selectedAnswers: mappedAnswers,
      ),
    );
  }

  void _onAnswerSelected(AnswerSelected event, Emitter<AttemptState> emit) {
    final currentState = state;
    if (currentState is! AttemptInProgress) return;

    final updatedAnswers = Map<int, String>.from(currentState.selectedAnswers);
    updatedAnswers[event.questionIndex] = event.selectedOption;

    // Also persist to Firestore (fire-and-forget for speed)
    final question = currentState.questions[event.questionIndex];
    _attemptRepository.submitAnswer(
      attemptId: currentState.attempt.id,
      questionId: question.id,
      answer: event.selectedOption,
    );

    emit(
      AttemptInProgress(
        exam: currentState.exam,
        questions: currentState.questions,
        attempt: currentState.attempt,
        selectedAnswers: updatedAnswers,
      ),
    );
  }

  Future<void> _onSubmitAttempt(
    SubmitAttemptRequested event,
    Emitter<AttemptState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AttemptInProgress) return;

    emit(const AttemptLoadInProgress());

    // Calculate score
    int correctCount = 0;
    int totalScore = 0;

    for (int i = 0; i < currentState.questions.length; i++) {
      final question = currentState.questions[i];
      final selected = currentState.selectedAnswers[i];
      if (selected != null && selected == question.correctAnswer) {
        correctCount++;
        totalScore += question.points;
      }
    }

    // Calculate XP earned: sum of xpReward for each correctly answered question
    final xpEarned = currentState.questions
        .asMap()
        .entries
        .where((e) =>
            currentState.selectedAnswers[e.key] != null &&
            currentState.selectedAnswers[e.key] == e.value.correctAnswer)
        .fold<int>(0, (sum, e) => sum + e.value.xpReward);

    // Persist to Firestore
    final result = await _attemptRepository.completeAttempt(
      attemptId: currentState.attempt.id,
      score: totalScore,
      correctCount: correctCount,
      xpEarned: xpEarned,
    );

    // Update user leaderboard stats via UserProgressRepository
    await _userProgressRepository.updateUserLeaderboardStats(
      uid: currentState.attempt.userId,
      newCorrectAnswers: correctCount,
    );

    switch (result) {
      case Success(:final data):
        emit(
          AttemptCompleted(
            exam: currentState.exam,
            attempt: data,
            correctCount: correctCount,
            totalQuestions: currentState.questions.length,
            questions: currentState.questions,
            selectedAnswers: currentState.selectedAnswers,
          ),
        );
      case Failure(:final errorMessage):
        emit(AttemptFailure(message: errorMessage));
    }
  }

  Future<void> _onLoadUserAttempts(
    LoadUserAttemptsRequested event,
    Emitter<AttemptState> emit,
  ) async {
    emit(const AttemptLoadInProgress());

    final result = await _attemptRepository.fetchUserAttempts(event.userId);

    switch (result) {
      case Success(:final data):
        final completed = data
            .where((a) => a.status == AttemptStatus.completed)
            .toList();
        final averageScore = completed.isNotEmpty
            ? completed.fold<double>(0, (sum, a) => sum + a.scorePercentage) /
                  completed.length
            : 0.0;

        emit(
          UserAttemptsLoaded(
            attempts: data,
            totalCompleted: completed.length,
            averageScore: averageScore,
          ),
        );
      case Failure(:final errorMessage):
        emit(AttemptFailure(message: errorMessage));
    }
  }
}
