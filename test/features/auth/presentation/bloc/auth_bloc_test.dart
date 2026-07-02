import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late StreamController<UserEntity?> authStateController;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<UserEntity?>.broadcast();
    
    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);
    
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authStateController.close();
    authBloc.close();
  });

  final tUser = UserEntity(
    uid: '123',
    email: 'test@gmail.com',
    displayName: 'Test User',
    role: UserRole.student,
    xp: 0,
    level: 1,
    streakDays: 0,
    createdAt: DateTime(2026, 1, 1),
    lastLoginAt: DateTime(2026, 1, 1),
  );

  group('AuthBloc', () {
    test('initial state should be AuthLoading', () {
      expect(authBloc.state, const AuthLoading());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when authStateChanges emits a user',
      build: () => authBloc,
      act: (bloc) => authStateController.add(tUser),
      expect: () => [AuthAuthenticated(user: tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when authStateChanges emits null',
      build: () => authBloc,
      act: (bloc) => authStateController.add(null),
      expect: () => const [AuthUnauthenticated()],
    );
  });
}
