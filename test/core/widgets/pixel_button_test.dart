import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bitwise_academy/core/widgets/pixel_button.dart';

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('PixelButton Widget Tests', () {
    testWidgets('renders label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          PixelButton(label: 'START GAME', onPressed: () {}),
        ),
      );

      expect(find.text('START GAME'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          PixelButton(label: 'LOGIN', icon: Icons.login, onPressed: () {}),
        ),
      );

      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          PixelButton(label: 'SUBMIT', isLoading: true, onPressed: () {}),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SUBMIT'), findsNothing);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          PixelButton(
            label: 'TAP ME',
            onPressed: () {
              wasTapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(PixelButton));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });
  });
}
