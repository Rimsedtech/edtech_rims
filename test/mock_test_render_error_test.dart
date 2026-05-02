import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test wrap chip animation', (WidgetTester tester) async {
    bool isSelected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['medium'].map((d) {
                  const color = Colors.blue;
                  return GestureDetector(
                    onTap: () => setState(() => isSelected = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withAlpha(38) : Colors.grey,
                        border: Border.all(
                          color: isSelected ? color : Colors.black,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected ? color : Colors.transparent,
                              border: Border.all(color: color, width: 2),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(d),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );

    // Tap to select
    await tester.tap(find.text('medium'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // halfway
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
