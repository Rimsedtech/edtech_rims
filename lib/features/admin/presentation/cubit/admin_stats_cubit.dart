import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';

import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/domain/repositories/user_repository.dart';

// ── State ──

class AdminStatsState extends Equatable {
  final bool isLoading;
  final int totalUsers;
  final int activeExams;
  final int todayAttempts;
  final String? error;

  const AdminStatsState({
    this.isLoading = true,
    this.totalUsers = 0,
    this.activeExams = 0,
    this.todayAttempts = 0,
    this.error,
  });

  AdminStatsState copyWith({
    bool? isLoading,
    int? totalUsers,
    int? activeExams,
    int? todayAttempts,
    String? error,
  }) {
    return AdminStatsState(
      isLoading: isLoading ?? this.isLoading,
      totalUsers: totalUsers ?? this.totalUsers,
      activeExams: activeExams ?? this.activeExams,
      todayAttempts: todayAttempts ?? this.todayAttempts,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, totalUsers, activeExams, todayAttempts, error];
}

// ── Cubit ──

/// Fetches aggregate admin statistics from Firestore.
class AdminStatsCubit extends Cubit<AdminStatsState> {
  final ExamRepository _examRepository;
  final UserRepository _userRepository;
  final AttemptRepository _attemptRepository;

  AdminStatsCubit({
    required ExamRepository examRepository,
    required UserRepository userRepository,
    required AttemptRepository attemptRepository,
  }) : _examRepository = examRepository,
       _userRepository = userRepository,
       _attemptRepository = attemptRepository,
       super(const AdminStatsState());

  /// Loads all admin stats in parallel.
  Future<void> loadStats() async {
    emit(state.copyWith(isLoading: true));

    // Fetch exams count, user count, and today's attempt count in parallel
    final results = await Future.wait([
      _examRepository.fetchPublishedExamCount(),
      _userRepository.fetchUserCount(),
      _attemptRepository.fetchTodayCompletedAttemptsCount(),
    ]);

    final examCountResult = results[0] as Result<int>;
    final userCountResult = results[1] as Result<int>;
    final todayCountResult = results[2] as Result<int>;

    int activeExams = 0;
    int totalUsers = 0;
    int todayAttempts = 0;
    String? firstError;

    switch (examCountResult) {
      case Success(:final data):
        activeExams = data;
      case Failure(:final errorMessage):
        firstError = errorMessage;
    }

    switch (userCountResult) {
      case Success(:final data):
        totalUsers = data;
      case Failure(:final errorMessage):
        firstError ??= errorMessage;
    }

    switch (todayCountResult) {
      case Success(:final data):
        todayAttempts = data;
      case Failure():
        break; // non-fatal — today count stays 0
    }

    if (isClosed) return;
    emit(
      AdminStatsState(
        isLoading: false,
        totalUsers: totalUsers,
        activeExams: activeExams,
        todayAttempts: todayAttempts,
        error: firstError,
      ),
    );
  }
}
