import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/admin/presentation/cubit/admin_stats_cubit.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/domain/repositories/user_repository.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';

class MockExamRepository extends Mock implements ExamRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockAttemptRepository extends Mock implements AttemptRepository {}

void main() {
  late MockExamRepository mockExamRepository;
  late MockUserRepository mockUserRepository;
  late MockAttemptRepository mockAttemptRepository;

  setUp(() {
    mockExamRepository = MockExamRepository();
    mockUserRepository = MockUserRepository();
    mockAttemptRepository = MockAttemptRepository();
  });

  test('does not throw exception when closed during async operation (emulating the bug)', () async {
    when(() => mockExamRepository.fetchPublishedExamCount()).thenAnswer(
      (_) async => Future.delayed(
        const Duration(milliseconds: 50),
        () => const Success(3),
      ),
    );
    when(() => mockUserRepository.fetchUserCount()).thenAnswer(
      (_) async => Future.delayed(
        const Duration(milliseconds: 50),
        () => const Success(0),
      ),
    );

    when(() => mockAttemptRepository.fetchTodayCompletedAttemptsCount()).thenAnswer(
      (_) async => Future.delayed(
        const Duration(milliseconds: 50),
        () => const Success(0),
      ),
    );

    final cubit = AdminStatsCubit(
      examRepository: mockExamRepository,
      userRepository: mockUserRepository,
      attemptRepository: mockAttemptRepository,
    );

    // Start loading stats
    final loadStatsFuture = cubit.loadStats();

    // Immediately close the cubit while the futures are pending
    await cubit.close();

    // Wait for the stats loading to complete and ensure no exceptions are thrown!
    await loadStatsFuture;

    // If it reaches here without throwing "Bad state: Cannot emit new states after calling close", the test passes.
    expect(cubit.isClosed, isTrue);
  });
}
