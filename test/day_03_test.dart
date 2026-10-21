import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

import 'package:flutter_lms/core/widgets/app_state_view.dart';
import 'package:flutter_lms/core/widgets/app_loading.dart';
import 'package:flutter_lms/core/widgets/app_error_view.dart';
import 'package:flutter_lms/core/widgets/empty_state.dart';
import 'package:flutter_lms/core/widgets/app_success_view.dart';

void main() {
  testWidgets('splash, swipe, back, and completion clear entry routes', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    expect(find.text('Flutter LMS'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Your next chapter starts here'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Grow together'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Your next chapter starts here'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('skip clears onboarding and splash', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('shared states render and retry invokes caller', (tester) async {
    var retried = false;
    for (final status in UiStatus.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: switch (status) {
              UiStatus.loading => AppLoading(
                title: 'State ${status.name}',
                message: 'Details',
              ),
              UiStatus.empty => EmptyState(
                title: 'State ${status.name}',
                message: 'Details',
              ),
              UiStatus.error => AppErrorView(
                title: 'State ${status.name}',
                message: 'Details',
                actionLabel: 'Retry',
                onAction: () => retried = true,
              ),
              UiStatus.success => AppSuccessView(
                title: 'State ${status.name}',
                message: 'Details',
              ),
            },
          ),
        ),
      );
      expect(find.text('State ${status.name}'), findsOneWidget);
      if (status == UiStatus.loading) {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
      if (status == UiStatus.error) await tester.tap(find.text('Retry'));
    }
    expect(retried, isTrue);
  });
}
