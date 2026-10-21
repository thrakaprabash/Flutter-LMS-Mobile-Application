import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/features/student/learning/widgets/learning_widgets.dart';

void main() {
  testWidgets('missing or invalid progress never shows a false zero', (
    tester,
  ) async {
    for (final value in [null, 'invalid', -1, 101]) {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseProgress(
              value: value,
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );
      expect(find.text('Progress unavailable'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.tap(find.text('Retry progress'));
      expect(retried, isTrue);
    }
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CourseProgress(value: 0))),
    );
    expect(find.text('0.0% complete'), findsOneWidget);
  });
  testWidgets('shared card shows instructor, status and appropriate action', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CourseCard(
              course: const {
                'title': 'Learning Flutter',
                'level': 'BEGINNER',
                'instructorId': {'firstName': 'Alex', 'lastName': 'Taylor'},
              },
              enrollment: const {'status': 'ACTIVE', 'progressPercentage': 42},
              onOpen: () {
                opened = true;
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('Alex Taylor'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('42.0% complete'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue learning'));
    await tester.tap(find.text('Continue learning'));
    expect(opened, isTrue);
  });
}
