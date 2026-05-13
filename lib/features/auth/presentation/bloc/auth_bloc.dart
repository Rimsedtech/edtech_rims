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
      super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthUserUpdated>(_onUserUpdated);
    on<AuthRecoveryKeyDismissed>(_onRecoveryKeyDismissed);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthFormOperationStarted>(_onFormOperationStarted);
    on<AuthFormOperationCompleted>(_onFormOperationCompleted);
    on<AuthNeedsRecoveryKeyDisplayEvent>(_onNeedsRecoveryKeyDisplay);

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
    _isFormOperationInProgress = false;
    // Form finished, verify session state.
    final result = await _authRepository.getCurrentUser();
    if (result case Success(:final data) when data != null) {
      emit(AuthAuthenticated(user: data));
    } else if (state is AuthInitial ||
        state is AuthLoading ||
        state is AuthError) {
      emit(const AuthUnauthenticated());
    }
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
    // If a form operation is active, or we need to display the recovery key, ignore the stream.
    if (state is AuthNeedsRecoveryKeyDisplay || _isFormOperationInProgress) {
      return;
    }
    if (event.user != null) {
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

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<UserEntity?> result = await _authRepository.getCurrentUser();
    switch (result) {
      case Success(:final data):
        if (data != null) {
          emit(AuthAuthenticated(user: data));
        } else {
          emit(const AuthUnauthenticated());
        }
      case Failure(:final errorMessage):
        emit(AuthError(message: errorMessage));
    }
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
