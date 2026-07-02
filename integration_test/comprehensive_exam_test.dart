import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:bitwise_academy/features/exam_library/presentation/pages/exam_taking_page.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

// Mock declarations
class MockAttemptBloc extends MockBloc<AttemptEvent, AttemptState> implements AttemptBloc {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAttemptBloc mockAttemptBloc;
  late MockGoRouter mockGoRouter;

  // Set up common mock data models
  final testExam = ExamModel(
    id: 'test_exam_123',
    title: 'MATH OLYMPIAD MOCK',
    description: 'A highly comprehensive math evaluation.',
    subject: 'math',
    group: 'senior',
    durationMinutes: 45,
    createdBy: 'admin',
    status: ExamStatus.published,
    xpReward: 500,
    questionCount: 2,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testQuestions = [
    const QuestionModel(
      id: 'q1',
      questionText: 'What is 2 + 2?',
      questionType: QuestionType.mcq,
      options: ['3', '4', '5', '6'],
      correctAnswer: '4',
      explanation: 'Basic addition.',
      points: 5,
      order: 1,
    ),
    const QuestionModel(
      id: 'q2',
      questionText: 'What is 3 * 3?',
      questionType: QuestionType.mcq,
      options: ['6', '7', '8', '9'],
      correctAnswer: '9',
      explanation: 'Basic multiplication.',
      points: 5,
      order: 2,
    ),
  ];

  final testAttempt = AttemptModel(
    id: 'attempt_abc',
    userId: 'user_xyz',
    examId: 'test_exam_123',
    startedAt: DateTime.now(),
    score: 0,
    totalPoints: 10,
    xpEarned: 0,
    status: AttemptStatus.inProgress,
    answers: const {},
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAttemptRequested());
  });

  setUp(() {
    mockAttemptBloc = MockAttemptBloc();
    mockGoRouter = MockGoRouter();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: BlocProvider<AttemptBloc>.value(
          value: mockAttemptBloc,
          child: child,
        ),
      ),
    );
  }

  group('Comprehensive Mock Exam Integration & Edge Cases', () {
    
    testWidgets('Scenario 1: User navigates questions and selects answers', (tester) async {
      // 1. Arrange state
      when(() => mockAttemptBloc.state).thenReturn(AttemptInProgress(
        exam: testExam,
        questions: testQuestions,
        attempt: testAttempt,
        selectedAnswers: const {},
      ));

      // 2. Load the Exam Taking Page
      await tester.pumpWidget(buildTestableWidget(const ExamTakingPage(examId: 'test_exam_123')));
      await tester.pumpAndSettle();

      // 3. Verify page elements load correctly (Initial question text, Progress HP bar)
      expect(find.text('Q1'), findsOneWidget);
      expect(find.text('What is 2 + 2?'), findsOneWidget);
      expect(find.text('PROGRESS'), findsOneWidget);

      // 4. Select answer "4"
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // Verify that the answer selection event is triggered
      verify(() => mockAttemptBloc.add(const AnswerSelected(
        questionIndex: 0,
        selectedOption: '4',
      ))).called(1);

      // 5. Navigate to next question
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // We need to simulate the BLoC updating the state index
      // Since it's a mock state, we verify that pressing next correctly increments local question index
      expect(find.text('Q2'), findsOneWidget);
      expect(find.text('What is 3 * 3?'), findsOneWidget);
    });

    testWidgets('Scenario 2: Hardware back-button intercepts accidental exits', (tester) async {
      when(() => mockAttemptBloc.state).thenReturn(AttemptInProgress(
        exam: testExam,
        questions: testQuestions,
        attempt: testAttempt,
        selectedAnswers: const {},
      ));

      await tester.pumpWidget(buildTestableWidget(const ExamTakingPage(examId: 'test_exam_123')));
      await tester.pumpAndSettle();

      // Simulate a hardware back press by calling the now-public interceptor directly
      // This bypasses private method limitations and native platform channels completely
      final dynamic state = tester.state(find.byType(ExamTakingPage));
      state.backButtonInterceptor(true, RouteInfo());
      await tester.pumpAndSettle();

      // Verify that the submit confirmation dialog (MISSION ALERT) was shown
      expect(find.text('MISSION ALERT'), findsOneWidget);
      expect(find.text('Do you want to submit\nyour answers?'), findsOneWidget);

      // Verify tapping 'NO — CONTINUE' dismisses the dialog
      await tester.tap(find.text('NO — CONTINUE'));
      await tester.pumpAndSettle();

      expect(find.text('MISSION ALERT'), findsNothing);
    });

    testWidgets('Scenario 3: App interruption (Backgrounding / Resuming) alerts the user', (tester) async {
      when(() => mockAttemptBloc.state).thenReturn(AttemptInProgress(
        exam: testExam,
        questions: testQuestions,
        attempt: testAttempt,
        selectedAnswers: const {},
      ));

      await tester.pumpWidget(buildTestableWidget(const ExamTakingPage(examId: 'test_exam_123')));
      await tester.pumpAndSettle();

      // Get the page state directly to simulate lifecycle events
      // This avoids pausing the actual test runner's thread scheduler
      final state = tester.state(find.byType(ExamTakingPage)) as WidgetsBindingObserver;

      // Simulate going to background (home press / call interruption)
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();

      // Simulate returning to the foreground
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Verify that the app displays the submit confirmation warning automatically on restore
      expect(find.text('MISSION ALERT'), findsOneWidget);
    });

    testWidgets('Scenario 4: 45-Minute timer expiration auto-submits even in background', (tester) async {
      // Simulate that the exam started 45 minutes and 10 seconds ago
      final historicalAttempt = testAttempt.copyWith(
        startedAt: DateTime.now().subtract(const Duration(minutes: 45, seconds: 10)),
      );

      when(() => mockAttemptBloc.state).thenReturn(AttemptInProgress(
        exam: testExam,
        questions: testQuestions,
        attempt: historicalAttempt,
        selectedAnswers: const {},
      ));

      await tester.pumpWidget(buildTestableWidget(const ExamTakingPage(examId: 'test_exam_123')));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(ExamTakingPage)) as WidgetsBindingObserver;

      // Simulate the app was paused (in background)
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();

      // Simulate returning from background after the 45-minute timer has expired
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Verify that it automatically sent the SubmitAttemptRequested event due to expiry
      verify(() => mockAttemptBloc.add(const SubmitAttemptRequested())).called(greaterThanOrEqualTo(1));
    });
  });
}
