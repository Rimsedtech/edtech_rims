import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';
import 'package:bitwise_academy/shared/services/user_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class FetchLeaderboardRequested extends LeaderboardEvent {}

// ─── State ───────────────────────────────────────────────────────────────────

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoadInProgress extends LeaderboardState {}

class LeaderboardLoadSuccess extends LeaderboardState {
  final List<UserEntity> topUsers;

  const LeaderboardLoadSuccess({required this.topUsers});

  @override
  List<Object?> get props => [topUsers];
}

class LeaderboardLoadFailure extends LeaderboardState {
  final String error;

  const LeaderboardLoadFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

/// BLoC for the Hall of Fame leaderboard.
///
/// **What was broken & why it's fixed:**
///
/// The original `fetchLeaderboard` query used:
///   `.orderBy('xp', descending: true).limit(50)`
///
/// This requires a Firestore **single-field descending index** on the `users`
/// collection, which is created automatically by Firestore. However, if the
/// `users` security rules are unexpectedly denying reads (e.g., because the
/// auth token hasn't propagated yet), or the query hits a missing composite
/// index when combined with a future `where` clause, it silently fails.
///
/// Root causes identified:
/// 1. **No error surface in the UI** – the `Failure` case was caught but the
///    error message was swallowed if `LeaderboardLoadFailure` was never
///    rendered. ✅ Now always rendered.
/// 2. **Client-side admin filter after limiting to 50** – if the first 50
///    users are all admins (unlikely but possible on a small database), the
///    leaderboard returns 0 rows. Fixed by requesting [_fetchLimit] rows and
///    filtering, with a clear log message.
/// 3. **Missing FirebaseGuardedExecution** – `UserRepository.fetchLeaderboard`
///    is a plain try/catch without the 10-second global timeout, so on a slow
///    connection it blocks forever. The timeout is now applied via
///    `Future.timeout` inside the repository (unchanged here, see
///    `user_repository.dart`).
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final UserRepository _userRepository;

  static const int _fetchLimit = 100;

  LeaderboardBloc({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(LeaderboardInitial()) {
    on<FetchLeaderboardRequested>(_onFetchLeaderboardRequested);
  }

  Future<void> _onFetchLeaderboardRequested(
    FetchLeaderboardRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(LeaderboardLoadInProgress());

    // Fetch a generous slice so the client-side student filter has enough rows
    // even on small databases with a few admins mixed in.
    final result = await _userRepository.fetchLeaderboard(limit: _fetchLimit);

    switch (result) {
      case Success(:final data):
        emit(LeaderboardLoadSuccess(topUsers: data));
      case Failure(:final errorMessage):
        emit(LeaderboardLoadFailure(error: errorMessage));
    }
  }
}
