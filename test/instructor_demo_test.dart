import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/network/api_exception.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/features/demo/demo_screen.dart';
import 'package:flutter_lms/features/instructor/screens/instructor_home_screen.dart';
import 'package:flutter_lms/features/instructor/services/instructor_service.dart';
import 'package:flutter_lms/features/student/learning/services/learning_service.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

import 'core_api_test.dart' show FakeAdapter;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = TokenStorage(FlutterSecureStorage());
  late DemoAccountService account;
  late ApiClient client;
  late InstructorService service;
  var networkCalls = 0;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await storage.saveSession(
      accessToken: 'real-session',
      refreshToken: 'real-refresh',
      role: 'STUDENT',
    );
    networkCalls = 0;
    final dio = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((_) {
        networkCalls++;
        throw StateError('Demo must never reach the network.');
      });
    client = ApiClient(storage, client: dio);
    account = DemoAccountService(client, 'INSTRUCTOR');
    service = InstructorService(account);
  });
  tearDown(() => expect(networkCalls, 0));

  test('demo builds and publishes a draft course, archives it and resets per session', () async {
    final categories = await LearningService(account).categories();
    final created = await service.save('POST', '/api/v1/courses', {
      'categoryId': recordId(categories.first),
      'title': 'My local course',
      'shortDescription': 'A demo',
      'description': 'Local only',
      'level': 'BEGINNER',
      'language': 'English',
      'requirements': ['Curiosity'],
      'learningOutcomes': ['Build a screen'],
      'targetAudience': ['Beginners'],
    });
    final id = recordId(object(created['course']));
    expect(created['course']['status'], 'DRAFT');
    final section = await service.save('POST', '/api/v1/courses/$id/sections', {
      'title': 'Introduction',
    });
    final sid = recordId(object(section['section']));
    final lesson = await service.save('POST', '/api/v1/sections/$sid/lessons', {
      'title': 'Welcome',
      'lessonType': 'TEXT',
      'textContent': 'Hello!',
      'durationMinutes': 5,
    });
    final lid = recordId(object(lesson['lesson']));
    await expectLater(
      service.save('PATCH', '/api/v1/courses/$id/publish'),
      throwsA(isA<ApiException>()),
    );
    await service.save('PATCH', '/api/v1/lessons/$lid', {'isPublished': true});
    await service.save('PATCH', '/api/v1/sections/$sid', {'isPublished': true});
    await service.save('PATCH', '/api/v1/courses/$id/publish');
    expect(
      (await service.get(
        '/api/v1/courses/instructor/me/$id',
        'course',
      ))['status'],
      'PUBLISHED',
    );
    await service.save('PATCH', '/api/v1/courses/$id/archive');
    await expectLater(
      service.save('PATCH', '/api/v1/courses/$id', {'title': 'Blocked'}),
      throwsA(isA<ApiException>()),
    );
    final fresh = InstructorService(DemoAccountService(client, 'INSTRUCTOR'));
    expect(
      (await fresh.list(
        '/api/v1/courses/instructor/me',
        'courses',
        1,
      )).items.length,
      2,
    );
    expect(await storage.readAccessToken(), 'real-session');
  });
  test(
    'demo media requires an upload simulation and reports local progress',
    () async {
      await expectLater(
        service.save('PATCH', '/api/v1/lessons/demo-studio-video', {
          'isPublished': true,
        }),
        throwsA(isA<ApiException>()),
      );
      var completed = false;
      await service.upload(
        '/api/v1/lessons/demo-studio-video/video',
        'video',
        MultipartFile.fromBytes([1, 2], filename: 'lesson.mp4'),
        (sent, total) => completed = sent == total,
      );
      await service.save('PATCH', '/api/v1/lessons/demo-studio-video', {
        'isPublished': true,
      });
      final lesson = await service.get(
        '/api/v1/lessons/demo-studio-video',
        'lesson',
      );
      expect(lesson['videoUrl'], startsWith('demo://'));
      expect(completed, true);
      expect(lesson['isPublished'], true);
    },
  );
  test(
    'demo quiz questions publish once and instructor attempts are visible',
    () async {
      final result = await service.save(
        'POST',
        '/api/v1/courses/demo-studio/quizzes',
        {
          'title': 'A new quiz',
          'passingScore': 60,
          'timeLimitMinutes': 10,
          'maxAttempts': 3,
        },
      );
      final id = recordId(object(result['quiz']));
      await expectLater(
        service.save('PATCH', '/api/v1/quizzes/$id/publish'),
        throwsA(isA<ApiException>()),
      );
      await service.save('POST', '/api/v1/quizzes/$id/questions', {
        'questionText': 'True?',
        'questionType': 'TRUE_FALSE',
        'options': [
          {'id': 'A', 'text': 'True'},
          {'id': 'B', 'text': 'False'},
        ],
        'correctOptionIds': ['A'],
        'marks': 1,
      });
      await service.save('PATCH', '/api/v1/quizzes/$id/publish');
      await expectLater(
        service.save('PATCH', '/api/v1/quizzes/$id', {'title': 'Blocked'}),
        throwsA(isA<ApiException>()),
      );
      expect(
        (await service.get(
          '/api/v1/quizzes/$id/instructor',
          'quiz',
        ))['questions'],
        hasLength(1),
      );
      expect(
        (await service.list(
          '/api/v1/quizzes/demo-live-quiz/attempts/instructor',
          'attempts',
          1,
        )).items.length,
        3,
      );
    },
  );
  test('demo grading and correction update stored submissions and dashboard counts', () async {
    final rows = await service.list(
      '/api/v1/assignments/demo-live-assignment/submissions',
      'submissions',
      1,
    );
    expect(rows.items.length, 3);
    final id = recordId(rows.items.first);
    await expectLater(
      service.save('PATCH', '/api/v1/submissions/$id/grade', {
        'status': 'GRADED',
        'marksAwarded': 101,
      }),
      throwsArgumentError,
    );
    await service.save('PATCH', '/api/v1/submissions/$id/grade', {
      'status': 'GRADED',
      'marksAwarded': 80,
      'feedback': 'Clear explanation',
    });
    expect(
      (await service.get(
        '/api/v1/dashboard/instructor',
        'dashboard',
      ))['pendingSubmissions'],
      0,
    );
    await service.save('PATCH', '/api/v1/submissions/$id/grade', {
      'status': 'RESUBMISSION_REQUIRED',
      'feedback': 'Add a screenshot',
    });
    final corrected = (await service.list(
      '/api/v1/assignments/demo-live-assignment/submissions?status=RESUBMISSION_REQUIRED',
      'submissions',
      1,
    )).items;
    expect(corrected.first['feedback'], 'Add a screenshot');
    expect(corrected.first.containsKey('marksAwarded'), false);
    expect(
      (await service.list(
        '/api/v1/courses/demo-live-course/enrollments',
        'enrollments',
        1,
      )).items.length,
      3,
    );
  });
  testWidgets('instructor demo retains its own account across pushed screens', (
    tester,
  ) async {
    final real = AuthProvider(AccountService(client), storage)
      ..user = {'role': 'STUDENT'};
    final demo = DemoAuthProvider(account, storage);
    addTearDown(real.dispose);
    addTearDown(demo.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: real,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Launch demo'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider<AuthProvider>.value(
                      value: demo,
                      child: const InstructorHomeScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Launch demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    expect(find.text('Create course'), findsOneWidget);
    await tester.tap(find.text('Build your first Flutter app'));
    await tester.pumpAndSettle();
    expect(find.text('Add section'), findsOneWidget);
    expect(find.textContaining('Uploads simulated'), findsOneWidget);
    expect(real.role, 'STUDENT');
    expect(await storage.readAccessToken(), 'real-session');
  });
}
