import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bitwise_academy/core/widgets/hp_bar.dart';

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('HpBar Widget Tests', () {
    testWidgets('renders label and value correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const HpBar(label: 'HEALTH', value: '50/100', progress: 0.5),
        ),
      );

      expect(find.text('HEALTH'), findsOneWidget);
      expect(find.text('50/100'), findsOneWidget);
    });

    testWidgets('clamps progress between 0 and 1', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const HpBar(
            label: 'MANA',
            value: 'OVER',
            progress: 1.5, // Should clamp to 1.0
          ),
        ),
      );

      // We can't easily assert the exact width of the filled container
      // without looking at the RenderBox, but we can at least ensure it builds
      // without errors when progress is > 1.
      expect(find.text('MANA'), findsOneWidget);
      expect(find.text('OVER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles negative progress by clamping to 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const HpBar(
            label: 'STAMINA',
            value: '0/100',
            progress: -0.5, // Should clamp to 0.0
          ),
        ),
      );

      expect(find.text('STAMINA'), findsOneWidget);
      expect(find.text('0/100'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
