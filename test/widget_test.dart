// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scolarhub/app/scolar_hub_app.dart';
import 'package:scolarhub/pages/checkin_screen.dart';

void main() {
  testWidgets('ScolarHub app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ScolarHubApp());

    // Verify that the splash screen is rendered.
    expect(find.text('Scholar'), findsOneWidget);
    expect(find.text('Hub'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('Checkin screen offers QR scanning for attendance', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CheckinScreen()));

    expect(find.text('Scanner le QR code'), findsOneWidget);
  });
}
