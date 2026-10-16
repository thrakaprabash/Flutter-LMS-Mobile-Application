import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('empty credentials show inline errors without navigating', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(initialRoute: '/'));
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
  testWidgets('password visibility and recovery navigation work', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(initialRoute: '/'));
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Recover password'), findsOneWidget);
  });
  testWidgets('registration allows Student and Instructor only', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(initialRoute: '/'));
    await tester.ensureVisible(find.text('Create an account'));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    expect(dropdown.initialValue, 'student');
    expect(find.text('Admin'), findsNothing);
  });
}
