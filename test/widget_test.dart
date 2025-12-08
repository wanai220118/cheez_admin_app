// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:cheez_admin_app/main.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    // Note: For actual tests, you might want to use Firebase emulators
    // or mock Firebase services
  });

  testWidgets('App loads and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CheezAdminApp());

    // Wait for async initialization
    await tester.pumpAndSettle();

    // Verify that login screen is shown
    expect(find.text("Cheez n' Cream Co. Admin Login"), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
