import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bitwise_academy/main.dart' as app;

void main() {
  // Initialize the standard Flutter integration testing binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'app launches and shows the initial screen',
    (WidgetTester tester) async {
      // Launch the app
      await app.main();
      
      // Wait for the app to settle and render
      await tester.pumpAndSettle();

      // Ensure the app has loaded by finding a MaterialApp or Scaffold widget
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}
