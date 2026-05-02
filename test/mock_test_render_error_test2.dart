import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';

void main() {
  testWidgets('Test PixelButton width double.infinity', (
    WidgetTester tester,
  ) async {
    bool isValid = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => isValid = true),
                    child: const Text('Click Me'),
                  ),
                  PixelButton(
                    label: 'START MISSION',
                    icon: Icons.play_arrow,
                    width: double.infinity,
                    onPressed: isValid ? () {} : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Tap to select
    await tester.tap(find.text('Click Me'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
