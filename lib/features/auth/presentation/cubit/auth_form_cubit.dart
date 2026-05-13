import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';

class AuthFormCubit extends Cubit<AuthFormState> {
  final AuthRepository _authRepository;
  final AuthBloc _authBloc;

  AuthFormCubit({
    required AuthRepository authRepository,
    required AuthBloc authBloc,
  }) : _authRepository = authRepository,
       _authBloc = authBloc,
       super(const AuthFormInitial());

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _authBloc.add(const AuthFormOperationStarted());
    emit(const AuthFormLoading());
    final result = await _authRepository.signInWithEmail(
      email: email,
      password: password,
    );
    _handleAuthResult(result);
  }

  Future<void> createAccountWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _authBloc.add(const AuthFormOperationStarted());
    emit(const AuthFormLoading());
    final result = await _authRepository.createAccountWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    _handleAuthResult(result);
  }

  Future<void> signInWithGoogle() async {
    _authBloc.add(const AuthFormOperationStarted());
    emit(const AuthFormLoading());
    final result = await _authRepository.signInWithGoogle();
    _handleAuthResult(result);
  }

  Future<void> signInWithApple() async {
    _authBloc.add(const AuthFormOperationStarted());
    emit(const AuthFormLoading());
    final result = await _authRepository.signInWithApple();
    switch (result) {
      case Success(:final data):
        if (data.rawRecoveryKey != null) {
          _authBloc.add(
            AuthNeedsRecoveryKeyDisplayEvent(
              user: data.user,
              rawRecoveryKey: data.rawRecoveryKey!,
            ),
          );
        } else {
          _authBloc.add(const AuthFormOperationCompleted());
        }
        emit(
          AuthFormSuccess(user: data.user, rawRecoveryKey: data.rawRecoveryKey),
        );
      case Failure(:final errorMessage):
        _authBloc.add(const AuthFormOperationCompleted());
        if (errorMessage.toLowerCase().contains('cancelled')) {
          emit(const AuthFormInitial());
        } else {
          emit(AuthFormError(errorMessage));
        }
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    emit(const AuthFormLoading());
    final result = await _authRepository.sendPasswordResetEmail(email: email);
    switch (result) {
      case Success():
        emit(const AuthFormPasswordResetSent());
      case Failure(:final errorMessage):
        emit(AuthFormError(errorMessage));
    }
  }

  Future<void> recoverAccount({
    required String email,
    required String recoveryKey,
  }) async {
    _authBloc.add(const AuthFormOperationStarted());
    emit(const AuthFormLoading());
    final result = await _authRepository.recoverAccount(
      email: email,
      recoveryKey: recoveryKey,
    );
    switch (result) {
      case Success():
        _authBloc.add(const AuthFormOperationCompleted());
        emit(const AuthFormPasswordResetSent());
      case Failure(:final errorMessage):
        _authBloc.add(const AuthFormOperationCompleted());
        emit(AuthFormError(errorMessage));
    }
  }

  void _handleAuthResult(Result<AuthResult> result) {
    switch (result) {
      case Success(:final data):
        if (data.rawRecoveryKey != null) {
          _authBloc.add(
            AuthNeedsRecoveryKeyDisplayEvent(
              user: data.user,
              rawRecoveryKey: data.rawRecoveryKey!,
            ),
          );
        } else {
          _authBloc.add(const AuthFormOperationCompleted());
        }
        emit(
          AuthFormSuccess(user: data.user, rawRecoveryKey: data.rawRecoveryKey),
        );
      case Failure(:final errorMessage):
        _authBloc.add(const AuthFormOperationCompleted());
        emit(AuthFormError(errorMessage));
    }
  }
}
