import 'package:equatable/equatable.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

sealed class AuthFormState extends Equatable {
  const AuthFormState();

  @override
  List<Object?> get props => [];
}

final class AuthFormInitial extends AuthFormState {
  const AuthFormInitial();
}

final class AuthFormLoading extends AuthFormState {
  const AuthFormLoading();
}

final class AuthFormSuccess extends AuthFormState {
  final UserEntity user;
  final String? rawRecoveryKey;

  const AuthFormSuccess({required this.user, this.rawRecoveryKey});

  @override
  List<Object?> get props => [user, rawRecoveryKey];
}

final class AuthFormError extends AuthFormState {
  final String message;

  const AuthFormError(this.message);

  @override
  List<Object?> get props => [message];
}

final class AuthFormPasswordResetSent extends AuthFormState {
  const AuthFormPasswordResetSent();
}
