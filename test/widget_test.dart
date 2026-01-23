import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart'; // Note: Package name might be default still

void main() {
  testWidgets('FarmAI UI Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our title is present.
    expect(find.text('FarmAI'), findsOneWidget);
    expect(find.text('Diagnose'), findsOneWidget); // In nav bar
    expect(find.text('History'), findsOneWidget); // In nav bar
    expect(find.text('Market'), findsOneWidget); // In nav bar

    // Verify Big Buttons
    expect(find.text('New Diagnosis'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });
}
