import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/domain/repositories/user_repository.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

// ── State ──────────────────────────────────────────────────────────────────

class AdminActivityState extends Equatable {
  final bool isLoading;
  final List<UserEntity> users;
  final int totalAttemptsCount;
  final int todayAttemptsCount;
  final List<ExamModel> exams;
  final String? error;

  const AdminActivityState({
    this.isLoading = true,
    this.users = const [],
    this.totalAttemptsCount = 0,
    this.todayAttemptsCount = 0,
    this.exams = const [],
    this.error,
  });

  AdminActivityState copyWith({
    bool? isLoading,
    List<UserEntity>? users,
    int? totalAttemptsCount,
    int? todayAttemptsCount,
    List<ExamModel>? exams,
    String? error,
  }) {
    return AdminActivityState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      totalAttemptsCount: totalAttemptsCount ?? this.totalAttemptsCount,
      todayAttemptsCount: todayAttemptsCount ?? this.todayAttemptsCount,
      exams: exams ?? this.exams,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        users,
        totalAttemptsCount,
        todayAttemptsCount,
        exams,
        error,
      ];
}

// ── Cubit ──────────────────────────────────────────────────────────────────

/// Loads all users, attempts, and exams for admin activity monitoring.
class AdminActivityCubit extends Cubit<AdminActivityState> {
  final AttemptRepository _attemptRepository;
  final ExamRepository _examRepository;
  final UserRepository _userRepository;

  AdminActivityCubit({
    required AttemptRepository attemptRepository,
    required ExamRepository examRepository,
    required UserRepository userRepository,
  }) : _attemptRepository = attemptRepository,
       _examRepository = examRepository,
       _userRepository = userRepository,
       super(const AdminActivityState());

  /// Fetch all data in parallel.
  Future<void> loadActivity() async {
    emit(state.copyWith(isLoading: true, error: null));

    final results = await Future.wait([
      _userRepository.fetchAllUsers(),
      _attemptRepository.fetchTotalCompletedAttemptsCount(),
      _attemptRepository.fetchTodayCompletedAttemptsCount(),
      _examRepository.fetchAllExams(),
    ]);

    final userResult = results[0] as Result<List<UserEntity>>;
    final totalAttemptsResult = results[1] as Result<int>;
    final todayAttemptsResult = results[2] as Result<int>;
    final examResult = results[3] as Result<List<ExamModel>>;

    List<UserEntity> users = [];
    int totalAttemptsCount = 0;
    int todayAttemptsCount = 0;
    List<ExamModel> exams = [];
    String? firstError;

    switch (userResult) {
      case Success(:final data):
        // Only students, admins don't need to appear in activity list
        users = data.where((u) => u.role == UserRole.student).toList();
      case Failure(:final errorMessage):
        firstError = errorMessage;
    }

    switch (totalAttemptsResult) {
      case Success(:final data):
        totalAttemptsCount = data;
      case Failure(:final errorMessage):
        firstError ??= errorMessage;
    }

    switch (todayAttemptsResult) {
      case Success(:final data):
        todayAttemptsCount = data;
      case Failure(:final errorMessage):
        firstError ??= errorMessage;
    }

    switch (examResult) {
      case Success(:final data):
        exams = data;
      case Failure(:final errorMessage):
        firstError ??= errorMessage;
    }

    if (isClosed) return;
    emit(
      AdminActivityState(
        isLoading: false,
        users: users,
        totalAttemptsCount: totalAttemptsCount,
        todayAttemptsCount: todayAttemptsCount,
        exams: exams,
        error: firstError,
      ),
    );
  }
}
