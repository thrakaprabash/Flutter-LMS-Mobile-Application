import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'instructor_management_test.dart' as fixtures;

void main() {
  for (final scenario in [
    ('section', 'Delete section', '/api/v1/sections/returned-id'),
    ('lesson', 'Delete lesson', '/api/v1/lessons/returned-id'),
    ('quiz', 'Delete quiz', '/api/v1/quizzes/returned-id'),
    ('assignment', 'Delete assignment', '/api/v1/assignments/returned-id'),
    ('quiz', 'Delete question 1', '/api/v1/quiz-questions/returned-question'),
    ('course', 'Remove thumbnail', '/api/v1/courses/returned-id/thumbnail'),
    ('lesson', 'Remove video', '/api/v1/lessons/returned-id/video'),
    ('lesson', 'Remove document', '/api/v1/lessons/returned-id/document'),
    (
      'assignment',
      'Remove attachment',
      '/api/v1/assignments/returned-id/attachment',
    ),
  ]) {
    testWidgets('${scenario.$2} requires confirmation and uses returned ID', (
      tester,
    ) async {
      final account = fixtures.InstructorAccount()
        ..entity = {
          'title': 'Practice',
          'isPublished': false,
          'thumbnailUrl': 'image',
          'videoUrl': 'video',
          'documentUrl': 'document',
          'attachmentUrl': 'file',
          'questions': [
            {
              '_id': 'returned-question',
              'questionText': 'Question',
              'options': [],
            },
          ],
        };
      await tester.pumpWidget(
        fixtures.workspace(account, scenario.$1, initial: account.entity),
      );
      await tester.pumpAndSettle();
      if (scenario.$1 == 'course') {
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
      }
      final control = find.text(scenario.$2);
      await tester.scrollUntilVisible(
        control,
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(account.calls.where((c) => c.$1 == 'DELETE'), isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(account.calls.where((c) => c.$1 == 'DELETE'), isEmpty);
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(
        account.calls.where((c) => c.$1 == 'DELETE').single.$2,
        scenario.$3,
      );
    });
  }
  testWidgets('published lessons hide media removal and allow unpublishing', (
    tester,
  ) async {
    final account = fixtures.InstructorAccount()
      ..entity = {
        'isPublished': true,
        'lessonType': 'VIDEO',
        'videoUrl': 'video',
      };
    await tester.pumpWidget(fixtures.workspace(account, 'lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Remove video'), findsNothing);
    expect(find.text('Unpublish lesson'), findsOneWidget);
  });
  testWidgets(
    'published quiz questions and quizzes with attempts are protected',
    (tester) async {
      final account = fixtures.InstructorAccount()
        ..entity = {
          'isPublished': true,
          'attemptCount': 1,
          'questions': [
            {'_id': 'q', 'options': []},
          ],
        };
      await tester.pumpWidget(fixtures.workspace(account, 'quiz'));
      await tester.pumpAndSettle();
      expect(find.text('Delete quiz'), findsNothing);
      expect(find.text('Delete question 1'), findsNothing);
    },
  );
  testWidgets('assignments with known submissions hide deletion', (
    tester,
  ) async {
    final account = fixtures.InstructorAccount()
      ..entity = {'submissionCount': 1};
    await tester.pumpWidget(
      fixtures.workspace(account, 'assignment', initial: account.entity),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete assignment'), findsNothing);
  });
}
