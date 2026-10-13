import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/app.dart';

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Log in'));
  await tester.tap(find.text('Log in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('invalid input stays on login with actionable errors', (
    tester,
  ) async {
    await tester.pumpWidget(const LmsApp(initialRoute: '/'));
    await submit(tester);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'invalid');
    await tester.enterText(find.byType(TextFormField).last, 'short');
    await submit(tester);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Use at least 8 characters for this preview.'),
      findsOneWidget,
    );
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('password checks each required character type', (tester) async {
    await tester.pumpWidget(const LmsApp(initialRoute: '/'));
    await tester.enterText(
      find.byType(TextFormField).first,
      'learner@example.com',
    );
    for (final entry in const {
      'preview123!': 'Add at least one uppercase letter.',
      'PREVIEW123!': 'Add at least one lowercase letter.',
      'Preview!!!': 'Add at least one number.',
      'Preview123': 'Add at least one special character.',
      'Preview123 ': 'Add at least one special character.',
    }.entries) {
      await tester.enterText(find.byType(TextFormField).last, entry.key);
      await submit(tester);
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    }
  });

  testWidgets('visibility, local login, all role dashboards and back work', (
    tester,
  ) async {
    await tester.pumpWidget(const LmsApp(initialRoute: '/'));
    await tester.enterText(
      find.byType(TextFormField).first,
      ' learner@example.com ',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Preview123!');
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    await submit(tester);
    expect(find.text('Home'), findsOneWidget);
    for (final title in [
      'Student dashboard',
      'Instructor dashboard',
      'Admin dashboard',
    ]) {
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text('Preview dashboard · Sample data'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    }
    await tester.ensureVisible(find.text('Back to login'));
    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screen, enlarged text, keyboard and asset remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const LmsApp(initialRoute: '/'));
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).textTheme.bodyMedium!.fontFamily, 'LmsRoboto');
    expect(find.byType(Image), findsOneWidget);
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.tap(find.byType(TextFormField).last);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await submit(tester);
    expect(find.text('Log in').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
