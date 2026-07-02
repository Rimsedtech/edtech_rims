import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/domain/repositories/user_progress_repository.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

// ── Events ──
sealed class SessionRecoveryEvent extends Equatable {
  const SessionRecoveryEvent();
  @override
  List<Object?> get props => [];
}

final class CheckRecoveryRequested extends SessionRecoveryEvent {
  final String userId;
  const CheckRecoveryRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

final class ResumeSessionRequested extends SessionRecoveryEvent {
  const ResumeSessionRequested();
}

final class SubmitSessionRequested extends SessionRecoveryEvent {
  final bool autoSubmitted;
  const SubmitSessionRequested({this.autoSubmitted = false});
  @override
  List<Object?> get props => [autoSubmitted];
}

final class ResetRecoveryState extends SessionRecoveryEvent {
  const ResetRecoveryState();
}

// ── States ──
sealed class SessionRecoveryState extends Equatable {
  const SessionRecoveryState();
  @override
  List<Object?> get props => [];
}

final class RecoveryInitial extends SessionRecoveryState {
  const RecoveryInitial();
}

final class RecoveryChecking extends SessionRecoveryState {
  const RecoveryChecking();
}

final class RecoveryNone extends SessionRecoveryState {
  const RecoveryNone();
}

final class RecoveryPrompt extends SessionRecoveryState {
  final AttemptModel attempt;
  final int remainingSeconds;

  const RecoveryPrompt({
    required this.attempt,
    required this.remainingSeconds,
  });

  @override
  List<Object?> get props => [attempt, remainingSeconds];
}

/// Emitted when an abandoned attempt is found and the app begins
/// auto-submitting it silently (Option C UX).
final class RecoveryAutoSubmitting extends SessionRecoveryState {
  const RecoveryAutoSubmitting();
}

/// Emitted when the auto-submit (or manual submit) finishes successfully.
final class RecoveryComplete extends SessionRecoveryState {
  final bool wasAutoSubmitted;
  const RecoveryComplete({required this.wasAutoSubmitted});

  @override
  List<Object?> get props => [wasAutoSubmitted];
}

/// Emitted when the auto-submit fails (e.g. network error, permission denied).
final class RecoveryError extends SessionRecoveryState {
  final String message;
  const RecoveryError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class SessionRecoveryBloc
    extends Bloc<SessionRecoveryEvent, SessionRecoveryState> {
  final AttemptRepository _attemptRepository;
  final ExamRepository _examRepository;
  final UserProgressRepository _userProgressRepository;

  SessionRecoveryBloc({
    required AttemptRepository attemptRepository,
    required ExamRepository examRepository,
    required UserProgressRepository userProgressRepository,
  })  : _attemptRepository = attemptRepository,
        _examRepository = examRepository,
        _userProgressRepository = userProgressRepository,
        super(const RecoveryInitial()) {
    on<CheckRecoveryRequested>(_onCheckRequested);
    on<SubmitSessionRequested>(_onSubmitRequested);
    on<ResumeSessionRequested>(_onResumeRequested);
    on<ResetRecoveryState>((event, emit) => emit(const RecoveryInitial()));
  }

  /// Checks for an abandoned in-progress attempt.
  ///
  /// Flow (Option C):
  /// 1. Query Firestore for an active attempt belonging to [userId].
  /// 2. If found → emit [RecoveryAutoSubmitting] (shows brief splash).
  /// 3. Recalculate score from persisted answers (Option A).
  /// 4. Persist the completed attempt + update leaderboard stats.
  /// 5. Emit [RecoveryComplete] — router sends the user to the dashboard
  ///    where a toast announces the auto-submission.
  Future<void> _onCheckRequested(
    CheckRecoveryRequested event,
    Emitter<SessionRecoveryState> emit,
  ) async {
    emit(const RecoveryChecking());

    final attemptResult =
        await _attemptRepository.fetchActiveAttempt(event.userId);

    if (attemptResult case Failure()) {
      // Can't determine whether there's an active attempt — fail safe by
      // letting the user through rather than blocking indefinitely.
      emit(const RecoveryNone());
      return;
    }

    final attempt = (attemptResult as Success<AttemptModel?>).data;

    if (attempt == null) {
      // No abandoned attempt — normal launch.
      emit(const RecoveryNone());
      return;
    }

    // ── Abandoned attempt found ──────────────────────────────────────────────
    // Option C: brief "submitting" splash before routing to dashboard.
    emit(const RecoveryAutoSubmitting());

    // Option A: re-fetch questions and recalculate score from saved answers.
    final (int recalcScore, int recalcCorrect, int recalcXp) =
        await _recalculateScore(attempt);

    // Persist the completed attempt.
    final completeResult = await _attemptRepository.completeAttempt(
      attemptId: attempt.id,
      score: recalcScore,
      correctCount: recalcCorrect,
      xpEarned: recalcXp,
    );

    if (completeResult case Failure(:final errorMessage)) {
      // Surface the error instead of silently swallowing it.
      // The attempt remains `in_progress` in Firestore and will be
      // detected again on the next launch.
      emit(RecoveryError(
        'Failed to auto-submit your previous session: $errorMessage',
      ));
      return;
    }

    // Update leaderboard stats (mirrors the normal submit flow in AttemptBloc).
    // This is fire-and-forget — a failure here doesn't block recovery.
    await _userProgressRepository.updateUserLeaderboardStats(
      uid: attempt.userId,
      newCorrectAnswers: recalcCorrect,
    );

    emit(const RecoveryComplete(wasAutoSubmitted: true));
  }

  /// Recalculates the score by fetching exam questions from Firestore and
  /// grading the answers that were persisted during the session.
  ///
  /// Returns (score, correctCount, xpEarned).
  /// Falls back to (0, 0, 0) if the exam/questions cannot be fetched
  /// (e.g. a random mock test whose virtual examId no longer resolves).
  Future<(int, int, int)> _recalculateScore(AttemptModel attempt) async {
    final questionsResult =
        await _examRepository.fetchQuestions(attempt.examId);

    if (questionsResult case Failure()) {
      // Can't grade — return zeros rather than crashing.
      return (0, 0, 0);
    }

    final questions =
        (questionsResult as Success<List<QuestionModel>>).data;

    if (questions.isEmpty) {
      return (0, 0, 0);
    }

    int score = 0;
    int correctCount = 0;
    int xpEarned = 0;

    for (final question in questions) {
      final savedAnswer = attempt.answers[question.id];
      if (savedAnswer != null && savedAnswer == question.correctAnswer) {
        correctCount++;
        score += question.points;
        xpEarned += question.xpReward;
      }
    }

    return (score, correctCount, xpEarned);
  }

  /// Manual submit from the [SessionRecoveryPage] dialog.
  /// Also recalculates score from answers and updates leaderboard.
  Future<void> _onSubmitRequested(
    SubmitSessionRequested event,
    Emitter<SessionRecoveryState> emit,
  ) async {
    if (state is! RecoveryPrompt) return;
    final promptState = state as RecoveryPrompt;

    emit(const RecoveryAutoSubmitting());

    final (int recalcScore, int recalcCorrect, int recalcXp) =
        await _recalculateScore(promptState.attempt);

    final completeResult = await _attemptRepository.completeAttempt(
      attemptId: promptState.attempt.id,
      score: recalcScore,
      correctCount: recalcCorrect,
      xpEarned: recalcXp,
    );

    if (completeResult case Failure(:final errorMessage)) {
      emit(RecoveryError(
        'Failed to submit session: $errorMessage',
      ));
      return;
    }

    await _userProgressRepository.updateUserLeaderboardStats(
      uid: promptState.attempt.userId,
      newCorrectAnswers: recalcCorrect,
    );

    emit(RecoveryComplete(wasAutoSubmitted: event.autoSubmitted));
  }

  void _onResumeRequested(
    ResumeSessionRequested event,
    Emitter<SessionRecoveryState> emit,
  ) {
    if (state is RecoveryPrompt) {
      // Emit RecoveryNone to unblock the router, then the page navigates
      // to the exam via context.pushReplacement().
      emit(const RecoveryNone());
    }
  }
}
