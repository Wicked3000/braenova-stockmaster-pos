// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stockmaster_mobile/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We use StockMasterApp instead of MyApp
    // Note: StockMasterApp requires ProviderScope which is handled in main.dart
    // For a simple smoke test, we can just check if it builds.
    await tester.pumpWidget(
      const ProviderScope(
        child: StockMasterApp(),
      ),
    );

    // Verify that login screen is shown (it's the initial route)
    // The screen says "Sign In" not "Login"
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('StockMaster'), findsOneWidget);
  });
}
