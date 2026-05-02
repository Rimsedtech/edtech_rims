import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/data/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/services/user_repository.dart';

// ── State ──

class AdminStatsState extends Equatable {
  final bool isLoading;
  final int totalUsers;
  final int activeExams;
  final String? error;

  const AdminStatsState({
    this.isLoading = true,
    this.totalUsers = 0,
    this.activeExams = 0,
    this.error,
  });

  AdminStatsState copyWith({
    bool? isLoading,
    int? totalUsers,
    int? activeExams,
    String? error,
  }) {
    return AdminStatsState(
      isLoading: isLoading ?? this.isLoading,
      totalUsers: totalUsers ?? this.totalUsers,
      activeExams: activeExams ?? this.activeExams,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, totalUsers, activeExams, error];
}

// ── Cubit ──

/// Fetches aggregate admin statistics from Firestore.
class AdminStatsCubit extends Cubit<AdminStatsState> {
  final ExamRepository _examRepository;
  final UserRepository _userRepository;

  AdminStatsCubit({
    required ExamRepository examRepository,
    required UserRepository userRepository,
  }) : _examRepository = examRepository,
       _userRepository = userRepository,
       super(const AdminStatsState());

  /// Loads all admin stats in parallel.
  Future<void> loadStats() async {
    emit(state.copyWith(isLoading: true));

    // Fetch all exams (admin view) and user count in parallel
    final results = await Future.wait([
      _examRepository.fetchAllExams(),
      _userRepository.fetchUserCount(),
    ]);

    final examResult = results[0] as Result<List<ExamModel>>;
    final userCountResult = results[1] as Result<int>;

    int activeExams = 0;
    int totalUsers = 0;

    if (examResult is Success<List<ExamModel>>) {
      activeExams = examResult.data
          .where((e) => e.status == ExamStatus.published)
          .length;
    }

    if (userCountResult is Success<int>) {
      totalUsers = userCountResult.data;
    }

    emit(
      AdminStatsState(
        isLoading: false,
        totalUsers: totalUsers,
        activeExams: activeExams,
      ),
    );
  }
}
