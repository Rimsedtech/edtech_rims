import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

// ── Events ──

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Check current auth state on app launch.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Sign out.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Instantaneously update the user's state (e.g. after purchasing an avatar).
final class AuthUserUpdated extends AuthEvent {
  final UserEntity user;
  const AuthUserUpdated({required this.user});
  @override
  List<Object?> get props => [user];
}

/// User has acknowledged the recovery key.
final class AuthRecoveryKeyDismissed extends AuthEvent {
  final UserEntity user;
  const AuthRecoveryKeyDismissed({required this.user});
  @override
  List<Object?> get props => [user];
}

/// Signals that a form operation started, to avoid race conditions with the auth stream.
final class AuthFormOperationStarted extends AuthEvent {
  const AuthFormOperationStarted();
}

/// Signals that a form operation finished.
final class AuthFormOperationCompleted extends AuthEvent {
  const AuthFormOperationCompleted();
}

/// Emitted by the form cubit when a recovery key is generated.
final class AuthNeedsRecoveryKeyDisplayEvent extends AuthEvent {
  final UserEntity user;
  final String rawRecoveryKey;
  const AuthNeedsRecoveryKeyDisplayEvent({
    required this.user,
    required this.rawRecoveryKey,
  });
  @override
  List<Object?> get props => [user, rawRecoveryKey];
}

/// Internal event to handle real-time auth state changes
final class _AuthUserChanged extends AuthEvent {
  final UserEntity? user;
  const _AuthUserChanged({required this.user});
  @override
  List<Object?> get props => [user];
}

// ── States ──

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Kept for API compatibility but the bloc no longer starts in this state.
/// The initial state is now [AuthLoading] so the splash screen is held
/// until the Firebase [authStateChanges] stream fires.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

final class AuthNeedsRecoveryKeyDisplay extends AuthState {
  final UserEntity user;

  /// The raw (unhashed) recovery key — shown exactly once and never stored.
  final String? rawRecoveryKey;
  const AuthNeedsRecoveryKeyDisplay({required this.user, this.rawRecoveryKey});
  @override
  List<Object?> get props => [user, rawRecoveryKey];
}

// ── BLoC ──

/// Manages the full authentication lifecycle.
///
/// Listens to [AuthRepository.authStateChanges] and handles
/// session management and routing state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserEntity?>? _authSubscription;
  bool _isFormOperationInProgress = false;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      // Start in AuthLoading so the router holds the splash screen.
      // The authStateChanges stream will emit the real state within
      // milliseconds, eliminating the cold-start race condition where
      // getCurrentUser() could return null before Firebase restores the
      // persisted token.
      super(const AuthLoading()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthUserUpdated>(_onUserUpdated);
    on<AuthRecoveryKeyDismissed>(_onRecoveryKeyDismissed);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthFormOperationStarted>(_onFormOperationStarted);
    on<AuthFormOperationCompleted>(_onFormOperationCompleted);
    on<AuthNeedsRecoveryKeyDisplayEvent>(_onNeedsRecoveryKeyDisplay);

    // Single source of truth for auth state. Fires immediately on subscription
    // with the current persisted state, making the one-shot getCurrentUser()
    // call unnecessary and avoiding cold-start race conditions.
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      add(_AuthUserChanged(user: user));
    });
  }

  void _onFormOperationStarted(
    AuthFormOperationStarted event,
    Emitter<AuthState> emit,
  ) {
    _isFormOperationInProgress = true;
  }

  Future<void> _onFormOperationCompleted(
    AuthFormOperationCompleted event,
    Emitter<AuthState> emit,
  ) async {
    // Clear the flag — the Firebase authStateChanges stream will have already
    // queued a _AuthUserChanged event with the signed-in user, which will now
    // be unblocked and emit AuthAuthenticated on its own.
    //
    // Safety fallback: if for some reason the Firebase stream's _AuthUserChanged
    // has already been processed and we're still in a non-authenticated state
    // (e.g. AuthInitial/AuthLoading), fetch the current user ourselves.
    _isFormOperationInProgress = false;

    // Allow the event queue to drain any pending _AuthUserChanged first.
    // If the state is still not AuthAuthenticated after that, fetch it now.
    await Future<void>.microtask(() async {
      if (state is! AuthAuthenticated && state is! AuthNeedsRecoveryKeyDisplay) {
        final result = await _authRepository.getCurrentUser();
        if (result case Success(:final data) when data != null) {
          emit(AuthAuthenticated(user: data));
        } else if (state is! AuthAuthenticated) {
          emit(const AuthUnauthenticated());
        }
      }
    });
  }

  void _onNeedsRecoveryKeyDisplay(
    AuthNeedsRecoveryKeyDisplayEvent event,
    Emitter<AuthState> emit,
  ) {
    _isFormOperationInProgress = false;
    emit(
      AuthNeedsRecoveryKeyDisplay(
        user: event.user,
        rawRecoveryKey: event.rawRecoveryKey,
      ),
    );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    // Ignore stream events while a form operation is in progress or while the
    // recovery key dialog is visible.
    if (state is AuthNeedsRecoveryKeyDisplay || _isFormOperationInProgress) {
      return;
    }
    if (event.user != null) {
      // Deduplicate: skip emission if we're already authenticated as the same user.
      // This prevents a second GoRouter refresh when the Firebase stream fires
      // right after AuthFormOperationCompleted already emitted AuthAuthenticated.
      final currentState = state;
      if (currentState is AuthAuthenticated &&
          currentState.user.uid == event.user!.uid) {
        return;
      }
      emit(AuthAuthenticated(user: event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  void _onUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(user: event.user));
  }

  void _onRecoveryKeyDismissed(
    AuthRecoveryKeyDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(user: event.user));
  }

  /// No-op: the [authStateChanges] stream subscription (started in the
  /// constructor) is now the sole mechanism for resolving auth state.
  /// Keeping this handler avoids breaking callers that still dispatch
  /// [AuthCheckRequested], but no separate Firestore/Firebase round-trip
  /// is performed — the stream already handles this correctly.
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Intentionally a no-op.
    // The authStateChanges stream handles auth resolution.
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<void> result = await _authRepository.signOut();
    switch (result) {
      case Success():
        emit(const AuthUnauthenticated());
      case Failure(:final errorMessage):
        emit(AuthError(message: errorMessage));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
