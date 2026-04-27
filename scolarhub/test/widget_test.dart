// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:scolarhub/main.dart';

void main() {
  testWidgets('ScolarHub affiche l ecran d authentification', (WidgetTester tester) async {
    await tester.pumpWidget(const ScolarHubApp());

    expect(find.text('ScolarHub'), findsOneWidget);
    expect(find.text('S\'inscrire'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
