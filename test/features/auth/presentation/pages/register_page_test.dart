import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bitwise_academy/features/auth/presentation/pages/register_page.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_state.dart';

class MockAuthFormCubit extends MockCubit<AuthFormState> implements AuthFormCubit {}
class MockAuthBloc extends MockCubit<AuthState> implements AuthBloc {}

void main() {
  late MockAuthFormCubit mockAuthFormCubit;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthFormCubit = MockAuthFormCubit();
    mockAuthBloc = MockAuthBloc();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthFormCubit>.value(value: mockAuthFormCubit),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: const RegisterPage(),
      ),
    );
  }

  testWidgets('register page form validation does not crash and shows errors when fields are empty', (WidgetTester tester) async {
    // Increase screen height in test so the button isn't off-screen
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockAuthFormCubit.state).thenReturn(const AuthFormInitial());
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Find the CREATE CHARACTER button
    final createButton = find.text('CREATE CHARACTER');
    expect(createButton, findsOneWidget);

    // Tap button to trigger form validation
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // Verify no exception was thrown and error messages are rendered on screen
    expect(tester.takeException(), isNull);
    expect(find.text('Hero name required'), findsOneWidget);
    expect(find.text('Email required'), findsOneWidget);
    expect(find.text('Secret key required'), findsOneWidget);
  });
}
