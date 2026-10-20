import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/features/instructor/services/instructor_service.dart';
import 'package:flutter_lms/features/instructor/screens/instructor_editor.dart';
import 'package:flutter_lms/features/instructor/screens/instructor_workspace.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

const storage = TokenStorage(FlutterSecureStorage());

class InstructorAccount extends AccountService {
  InstructorAccount() : super(ApiClient(storage));
  final calls = <(String, String, Object?)>[];
  Map<String, dynamic> entity = {};
  List<Map<String, dynamic>> items = [];
  bool forbidden = false;
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    bool public = false,
    ProgressCallback? progress,
  }) async {
    expect(public, false);
    calls.add((method, path, data));
    if (forbidden) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 403,
          data: {'message': 'You do not own this course.'},
        ),
      );
    }
    if (method != 'GET') {
      if (data is Map<String, dynamic>) entity.addAll(data);
      if (data is FormData) {
        progress?.call(100, 100);
      }
      return {'data': entity};
    }
    if (path.contains('page=')) {
      return {
        'data': {
          'courses': items,
          'sections': items,
          'lessons': items,
          'submissions': items,
          'pagination': {'page': 1, 'totalPages': 2},
        },
      };
    }
    return {'data': entity};
  }
}

Widget workspace(
  InstructorAccount account,
  String kind, {
  Map<String, dynamic> initial = const {},
  String role = 'INSTRUCTOR',
}) {
  final auth = AuthProvider(account, storage)..user = {'role': role};
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      home: InstructorWorkspace(
        kind: kind,
        id: 'returned-id',
        initial: initial,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'course form blocks short descriptions before sending a request',
    (tester) async {
      var saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: InstructorEditor(
            title: 'Create course',
            fields: courseDetailsFields.take(3).toList(),
            initial: const {
              'title': 'qqqqqqqqqq demo',
              'shortDescription': 'demo',
              'description': 'demo',
            },
            onSave: (_) async {
              saves++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saves, 0);
      expect(find.text('Enter at least 10 characters.'), findsOneWidget);
      expect(find.text('Enter at least 20 characters.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('shortDescription')),
        'A valid course introduction.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('description')),
        'This course introduces Flutter widgets and helps beginners build their first screen.',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saves, 1);
    },
  );
  test(
    'course list fields allow empty lists and enforce individual item limits',
    () {
      final field = courseDetailsFields.firstWhere(
        (f) => f.key == 'requirements',
      );
      expect(editorLengthError(field, ''), isNull);
      expect(editorLengthError(field, 'x'), contains('at least 2'));
      expect(
        editorLengthError(field, List.filled(21, 'Valid item').join('\n')),
        contains('at most 20 items'),
      );
      expect(editorLengthError(field, 'Basic skills\nA computer'), isNull);
    },
  );
  test('grading rejects excess marks and correction without feedback', () {
    expect(
      () => InstructorService.validateGrade('GRADED', 101, 100, ''),
      throwsArgumentError,
    );
    expect(
      () => InstructorService.validateGrade('GRADED', -1, 100, ''),
      throwsArgumentError,
    );
    expect(
      () => InstructorService.validateGrade(
        'RESUBMISSION_REQUIRED',
        null,
        100,
        ' ',
      ),
      throwsArgumentError,
    );
    InstructorService.validateGrade('GRADED', 85, 100, 'Good work');
    InstructorService.validateGrade(
      'RESUBMISSION_REQUIRED',
      null,
      100,
      'Add your report',
    );
  });
  test('uploads use exact multipart field and report progress', () async {
    final account = InstructorAccount();
    var sent = 0;
    for (final field in ['thumbnail', 'video', 'document', 'attachment']) {
      await InstructorService(account).upload(
        '/api/v1/upload/$field',
        field,
        MultipartFile.fromBytes([1, 2], filename: 'fixture.bin'),
        (s, t) => sent = s,
      );
      final call = account.calls.last;
      expect(call.$1, 'POST');
      expect((call.$3 as FormData).files.single.key, field);
    }
    expect(sent, 100);
  });
  testWidgets(
    'video publication stays unavailable until uploaded media exists',
    (tester) async {
      final account = InstructorAccount()
        ..entity = {
          'title': 'Video lesson',
          'lessonType': 'VIDEO',
          'isPublished': false,
        };
      await tester.pumpWidget(workspace(account, 'lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Publish lesson'), findsNothing);
      expect(find.text('Upload video'), findsOneWidget);
      account.entity['videoUrl'] = 'https://example.com/lesson.mp4';
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(find.text('Publish lesson'), findsOneWidget);
      await tester.ensureVisible(find.text('Publish lesson'));
      await tester.tap(find.text('Publish lesson'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(
        account.calls.any(
          (c) =>
              c.$1 == 'PATCH' &&
              c.$2 == '/api/v1/lessons/returned-id' &&
              (c.$3 as Map)['isPublished'] == true,
        ),
        true,
      );
      expect(find.text('Publish lesson'), findsNothing);
    },
  );
  testWidgets('published quiz hides editing and correct-answer form', (
    tester,
  ) async {
    final account = InstructorAccount()
      ..entity = {
        'title': 'Published quiz',
        'isPublished': true,
        'questions': [
          {
            'id': 'q',
            'questionText': 'Example question',
            'marks': 2,
            'correctOptionIds': ['B'],
          },
        ],
      };
    await tester.pumpWidget(workspace(account, 'quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Add question'), findsNothing);
    expect(find.text('Edit settings'), findsNothing);
    expect(find.text('Student attempts'), findsOneWidget);
    await tester.tap(find.text('Example question'));
    await tester.pumpAndSettle();
    expect(find.text('Edit question'), findsNothing);
  });
  testWidgets(
    'archived course permits inspection and hides edit and publish actions',
    (tester) async {
      final account = InstructorAccount()
        ..entity = {'title': 'Archived course', 'status': 'ARCHIVED'};
      await tester.pumpWidget(workspace(account, 'course'));
      await tester.pumpAndSettle();
      expect(find.text('Edit course'), findsNothing);
      expect(find.text('Add section'), findsNothing);
      expect(find.text('Publish course'), findsNothing);
      await tester.tap(find.text('Assessments'));
      await tester.pumpAndSettle();
      expect(find.text('Enrollments'), findsOneWidget);
      expect(
        account.calls.first.$2,
        '/api/v1/courses/instructor/me/returned-id',
      );
    },
  );
  testWidgets('403 shows ownership error and no mutation controls', (
    tester,
  ) async {
    final account = InstructorAccount()..forbidden = true;
    await tester.pumpWidget(workspace(account, 'course'));
    await tester.pumpAndSettle();
    expect(find.text('You do not own this course.'), findsOneWidget);
    expect(find.text('Add section'), findsNothing);
    expect(account.calls.length, 1);
  });
  testWidgets('student cannot load instructor data', (tester) async {
    final account = InstructorAccount();
    await tester.pumpWidget(workspace(account, 'courses', role: 'STUDENT'));
    await tester.pumpAndSettle();
    expect(find.text('Instructor access required.'), findsOneWidget);
    expect(account.calls, isEmpty);
  });
  testWidgets('instructor dashboard fits narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final account = InstructorAccount()
      ..entity = {
        'totalCourses': 12,
        'activeEnrollments': 22,
        'pendingSubmissions': 3,
      };
    await tester.pumpWidget(workspace(account, 'home'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('My courses'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My courses'));
    await tester.pumpAndSettle();
    expect(find.text('Create course'), findsOneWidget);
  });
  testWidgets(
    'question editor selects correct answers and preserves backend option IDs',
    (tester) async {
      Map<String, dynamic>? payload;
      await tester.pumpWidget(
        MaterialApp(
          home: InstructorEditor(
            title: 'Add question',
            fields: questionFields,
            initial: const {
              'questionText': 'Which language?',
              'questionType': 'SINGLE_CHOICE',
              'options': [
                {'id': 'A', 'text': 'Java'},
                {'id': 'B', 'text': 'Dart'},
              ],
              'correctOptionIds': [],
              'marks': 2,
            },
            onSave: (data) async => payload = data,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(payload, isNull);
      expect(
        find.text('Choose the correct answer before saving.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byTooltip('Mark answer 2 correct'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mark answer 2 correct'));
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(payload?['correctOptionIds'], ['B']);
      expect(payload?['options'], [
        {'id': 'A', 'text': 'Java'},
        {'id': 'B', 'text': 'Dart'},
      ]);
    },
  );
  testWidgets('course list preserves pagination and uses owned courses route', (
    tester,
  ) async {
    final account = InstructorAccount()
      ..items = [
        {'id': 'owned', 'title': 'Owned course', 'status': 'DRAFT'},
      ];
    await tester.pumpWidget(workspace(account, 'courses'));
    await tester.pumpAndSettle();
    expect(find.text('Owned course'), findsOneWidget);
    await tester.ensureVisible(find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(
      account.calls.last.$2,
      '/api/v1/courses/instructor/me?page=2&limit=20',
    );
  });
  testWidgets('correction requires feedback and sends no final marks', (
    tester,
  ) async {
    final account = InstructorAccount();
    await tester.pumpWidget(
      workspace(
        account,
        'submission',
        initial: {'maximumMarks': 100, 'textAnswer': 'My answer'},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grade or request correction'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request correction').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Explain what the student needs to correct.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'Please include a screenshot.',
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final call = account.calls.last;
    expect(call.$2, '/api/v1/submissions/returned-id/grade');
    expect(call.$3, {
      'status': 'RESUBMISSION_REQUIRED',
      'feedback': 'Please include a screenshot.',
    });
  });
}
