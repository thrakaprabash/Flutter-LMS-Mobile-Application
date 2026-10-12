import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/app.dart';

void main() {
  testWidgets('password visibility and preview submission work', (
    tester,
  ) async {
    await tester.pumpWidget(const LmsApp());
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('For students, instructors and admins'), findsOneWidget);
    final password = find.byType(TextField).last;
    await tester.enterText(password, 'preview-password');
    expect(tester.widget<TextField>(password).obscureText, isTrue);
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isFalse);
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(
      find.text(
        'This is a login preview. Account sign-in will be available later.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('login remains reachable with a small screen and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const LmsApp());
    final password = find.byType(TextField).last;
    await tester.ensureVisible(password);
    await tester.tap(password);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log in'));
    expect(tester.takeException(), isNull);
    expect(find.text('Log in').hitTestable(), findsOneWidget);
  });
}
