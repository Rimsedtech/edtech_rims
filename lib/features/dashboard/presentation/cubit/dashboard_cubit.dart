import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/data/repositories/attempt_repository.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';
import 'package:bitwise_academy/shared/services/user_repository.dart';

// ── State ──

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  final UserEntity user;
  final int testsCompleted;
  final double averageScore;
  final List<AttemptModel> recentAttempts;

  const DashboardLoaded({
    required this.user,
    required this.testsCompleted,
    required this.averageScore,
    required this.recentAttempts,
  });

  @override
  List<Object?> get props => [
    user,
    testsCompleted,
    averageScore,
    recentAttempts,
  ];
}

final class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ── Cubit ──

/// Manages dashboard data: user profile stream + attempt stats.
///
/// Replaces the old pattern where `UserDashboardPage` read user data
/// from `AuthBloc` and created an ad-hoc `AttemptBloc` inline.
class DashboardCubit extends Cubit<DashboardState> {
  final UserRepository _userRepository;
  final AttemptRepository _attemptRepository;
  StreamSubscription<Result<UserEntity>>? _userSubscription;

  DashboardCubit({
    required UserRepository userRepository,
    required AttemptRepository attemptRepository,
  }) : _userRepository = userRepository,
       _attemptRepository = attemptRepository,
       super(const DashboardInitial());

  /// Starts listening to the user profile stream and loads attempt stats.
  void loadDashboard(String userId) {
    emit(const DashboardLoading());

    _userSubscription?.cancel();
    _userSubscription = _userRepository
        .watchUser(userId)
        .listen(
          (result) async {
            switch (result) {
              case Success(:final data):
                // Fetch attempt stats whenever user profile updates
                final statsResult = await _attemptRepository.fetchUserAttempts(
                  userId,
                );

                int testsCompleted = 0;
                double averageScore = 0;
                List<AttemptModel> recentAttempts = [];

                if (statsResult is Success<List<AttemptModel>>) {
                  final completed = statsResult.data
                      .where((a) => a.status == AttemptStatus.completed)
                      .toList();
                  testsCompleted = completed.length;
                  averageScore = completed.isNotEmpty
                      ? completed.fold<double>(
                              0,
                              (sum, a) => sum + a.scorePercentage,
                            ) /
                            completed.length
                      : 0.0;
                  recentAttempts = statsResult.data.take(5).toList();
                }

                emit(
                  DashboardLoaded(
                    user: data,
                    testsCompleted: testsCompleted,
                    averageScore: averageScore,
                    recentAttempts: recentAttempts,
                  ),
                );
              case Failure(:final exception):
                emit(DashboardError(message: exception.message));
            }
          },
          onError: (Object error) {
            emit(DashboardError(message: error.toString()));
          },
        );
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
