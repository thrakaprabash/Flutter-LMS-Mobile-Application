import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../instructor/services/instructor_service.dart';
import '../student/learning/services/learning_service.dart';

/// Disposable instructor fixtures. This class has no network client or storage.
class DemoInstructorData {
  DemoInstructorData() {
    courses.addAll([
      {
        'id': 'demo-studio',
        'categoryId': 'demo-mobile',
        'title': 'Build your first Flutter app',
        'shortDescription': 'A course ready for your finishing touches.',
        'description': 'Practice building a course, publishing lessons and supporting learners.',
        'status': 'DRAFT',
        'level': 'BEGINNER',
        'language': 'English',
        'requirements': ['A computer and curiosity'],
        'learningOutcomes': ['Build a Flutter screen'],
        'targetAudience': ['New developers'],
      },
      {
        'id': 'demo-live-course',
        'categoryId': 'demo-mobile',
        'title': 'Flutter foundations',
        'shortDescription': 'Published sample course with learner work.',
        'description': 'Explore quiz attempts and assignment feedback.',
        'status': 'PUBLISHED',
        'level': 'BEGINNER',
        'language': 'English',
        'requirements': ['No experience needed'],
        'learningOutcomes': ['Understand widgets'],
        'targetAudience': ['Beginners'],
      },
    ]);
    sections.addAll([
      {
        'id': 'demo-studio-section',
        'courseId': 'demo-studio',
        'title': 'Getting started',
        'description': 'Add content and publish when ready.',
        'order': 1,
        'isPublished': false,
      },
      {
        'id': 'demo-live-section',
        'courseId': 'demo-live-course',
        'title': 'Widget essentials',
        'description': 'Your published curriculum.',
        'order': 1,
        'isPublished': true,
      },
    ]);
    lessons.addAll([
      {
        'id': 'demo-studio-text',
        'sectionId': 'demo-studio-section',
        'title': 'Welcome to Flutter',
        'lessonType': 'TEXT',
        'textContent': 'Flutter builds interfaces from reusable widgets. Try editing this introduction.',
        'durationMinutes': 5,
        'order': 1,
        'isPublished': false,
        'isPreview': false,
      },
      {
        'id': 'demo-studio-video',
        'sectionId': 'demo-studio-section',
        'title': 'Your first screen',
        'lessonType': 'VIDEO',
        'durationMinutes': 10,
        'order': 2,
        'isPublished': false,
        'isPreview': false,
      },
      {
        'id': 'demo-studio-document',
        'sectionId': 'demo-studio-section',
        'title': 'Setup checklist',
        'lessonType': 'DOCUMENT',
        'durationMinutes': 5,
        'order': 3,
        'isPublished': false,
        'isPreview': false,
      },
      {
        'id': 'demo-live-text',
        'sectionId': 'demo-live-section',
        'title': 'Layout with widgets',
        'lessonType': 'TEXT',
        'textContent': 'Use Column and Row to arrange widgets.',
        'durationMinutes': 5,
        'order': 1,
        'isPublished': true,
        'isPreview': false,
      },
    ]);
    quizzes.addAll([
      {
        'id': 'demo-studio-quiz',
        'courseId': 'demo-studio',
        'title': 'Your first quiz',
        'description': 'Edit this sample before publishing.',
        'passingScore': 60,
        'timeLimitMinutes': 10,
        'maxAttempts': 3,
        'isPublished': false,
      },
      {
        'id': 'demo-live-quiz',
        'courseId': 'demo-live-course',
        'title': 'Widget knowledge check',
        'description': 'Published sample results.',
        'passingScore': 60,
        'timeLimitMinutes': 10,
        'maxAttempts': 3,
        'isPublished': true,
      },
    ]);
    for (final quiz in quizzes) {
      questions.add({
        'id': '${quiz['id']}-question',
        'quizId': quiz['id'],
        'questionText': 'Which widget arranges children vertically?',
        'questionType': 'SINGLE_CHOICE',
        'options': [
          {'id': 'A', 'text': 'Column'},
          {'id': 'B', 'text': 'Row'},
        ],
        'correctOptionIds': ['A'],
        'marks': 2,
      });
    }
    final due = DateTime.now()
        .add(const Duration(days: 14))
        .toUtc()
        .toIso8601String();
    assignments.addAll([
      {
        'id': 'demo-studio-assignment',
        'courseId': 'demo-studio',
        'title': 'Build a welcome screen',
        'description': 'A draft assignment to customize.',
        'instructions': 'Build a screen with a heading and button. Submit a brief explanation.',
        'dueDate': due,
        'maximumMarks': 100,
        'isPublished': false,
      },
      {
        'id': 'demo-live-assignment',
        'courseId': 'demo-live-course',
        'title': 'Design a profile card',
        'description': 'Review your learners’ sample submissions.',
        'instructions':
            'Create a profile card and explain your widget choices.',
        'dueDate': due,
        'maximumMarks': 100,
        'isPublished': true,
      },
    ]);
    final people = [
      {
        'id': 'demo-learner-one',
        'firstName': 'Sam',
        'lastName': 'Perera',
        'name': 'Sam Perera',
      },
      {
        'id': 'demo-learner-two',
        'firstName': 'Maya',
        'lastName': 'Silva',
        'name': 'Maya Silva',
      },
      {
        'id': 'demo-learner-three',
        'firstName': 'Lee',
        'lastName': 'Fernando',
        'name': 'Lee Fernando',
      },
    ];
    for (var i = 0; i < people.length; i++) {
      enrollments.add({
        'id': 'demo-enrollment-$i',
        'courseId': 'demo-live-course',
        'student': people[i],
        'status': i == 2 ? 'COMPLETED' : 'ACTIVE',
        'progressPercentage': i == 2 ? 100 : 50,
      });
      attempts.add({
        'id': 'demo-instructor-attempt-$i',
        'quizId': 'demo-live-quiz',
        'student': people[i],
        'attemptNumber': 1,
        'status': 'SUBMITTED',
        'score': i == 1 ? 0 : 2,
        'percentage': i == 1 ? 0 : 100,
        'passed': i != 1,
        'submittedAt': DateTime.now()
            .subtract(Duration(hours: i + 1))
            .toUtc()
            .toIso8601String(),
      });
      submissions.add({
        'id': 'demo-instructor-submission-$i',
        'assignmentId': 'demo-live-assignment',
        'student': people[i],
        'maximumMarks': 100,
        'textAnswer': 'I built my profile card using a Column, CircleAvatar and Text widgets.',
        'status': i == 2
            ? 'GRADED'
            : i == 1
            ? 'RESUBMISSION_REQUIRED'
            : 'SUBMITTED',
        if (i == 2) 'marksAwarded': 85,
        'feedback': i == 1
            ? 'Please explain how your layout adapts to small screens.'
            : i == 2
            ? 'Clear explanation. Good work.'
            : '',
      });
    }
  }
  final courses = <Map<String, dynamic>>[],
      sections = <Map<String, dynamic>>[],
      lessons = <Map<String, dynamic>>[];
  final quizzes = <Map<String, dynamic>>[],
      questions = <Map<String, dynamic>>[],
      assignments = <Map<String, dynamic>>[];
  final attempts = <Map<String, dynamic>>[],
      submissions = <Map<String, dynamic>>[],
      enrollments = <Map<String, dynamic>>[];
  int sequence = 0;
  Never fail(String message, [int status = 422]) =>
      throw ApiException(message: message, statusCode: status);
  Map<String, dynamic> find(List<Map<String, dynamic>> collection, String id) =>
      collection.firstWhere(
        (r) => recordId(r) == id,
        orElse: () => fail(
          'This sample record is unavailable in your demo session.',
          403,
        ),
      );
  Map<String, dynamic> result(Map<String, dynamic> data) => {
    'data': jsonDecode(jsonEncode(data)),
  };
  Map<String, dynamic> page(
    String key,
    Iterable<Map<String, dynamic>> source,
    Uri uri,
  ) {
    final status = uri.queryParameters['status'];
    final values = source
        .where((r) => status == null || status.isEmpty || r['status'] == status)
        .toList();
    final p = (int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1).clamp(
      1,
      100000,
    );
    final limit = (int.tryParse(uri.queryParameters['limit'] ?? '20') ?? 20)
        .clamp(1, 100);
    final start = ((p - 1) * limit).clamp(0, values.length);
    final end = (start + limit).clamp(0, values.length);
    return result({
      key: values.sublist(start, end),
      'pagination': {
        'page': p,
        'totalPages': (values.length / limit).ceil(),
        'hasNextPage': end < values.length,
      },
    });
  }

  Map<String, dynamic> courseFor(String resource, Map<String, dynamic> record) {
    if (resource == 'courses') return record;
    if (resource == 'lessons') {
      return courseFor('sections', find(sections, '${record['sectionId']}'));
    }
    if (resource == 'quiz-questions') {
      return courseFor('quizzes', find(quizzes, '${record['quizId']}'));
    }
    if (resource == 'submissions') {
      return courseFor(
        'assignments',
        find(assignments, '${record['assignmentId']}'),
      );
    }
    return find(courses, '${record['courseId']}');
  }

  void editable(Map<String, dynamic> course) {
    if (course['status'] == 'ARCHIVED') {
      fail('Archived courses cannot be edited.');
    }
  }

  Map<String, dynamic>? handle(
    String method,
    String path,
    Object? body, {
    ProgressCallback? progress,
  }) {
    final uri = Uri.parse(path);
    final parts = uri.path.split('/').skip(3).toList();
    if (parts.isEmpty) return null;
    final data = object(body);
    if (uri.path == '/api/v1/categories' && method == 'GET') {
      return page('categories', [
        {'id': 'demo-mobile', 'name': 'Mobile development', 'isActive': true},
        {'id': 'demo-design', 'name': 'Design', 'isActive': true},
      ], uri);
    }
    if (uri.path == '/api/v1/dashboard/instructor' && method == 'GET') {
      return result({
        'totalCourses': courses.length,
        'draftCourses': courses.where((c) => c['status'] == 'DRAFT').length,
        'publishedCourses': courses
            .where((c) => c['status'] == 'PUBLISHED')
            .length,
        'archivedCourses': courses
            .where((c) => c['status'] == 'ARCHIVED')
            .length,
        'activeEnrollments': enrollments
            .where((e) => e['status'] == 'ACTIVE')
            .length,
        'pendingSubmissions': submissions
            .where((s) => ['SUBMITTED', 'LATE'].contains(s['status']))
            .length,
        'averageCourseRating': 4.6,
      });
    }
    final resource = parts.first;
    if (resource == 'courses' &&
        parts.length >= 3 &&
        parts[1] == 'instructor' &&
        parts[2] == 'me') {
      if (parts.length == 3) return page('courses', courses, uri);
      return result({'course': find(courses, parts[3])});
    }
    if (resource == 'courses' && parts.length == 1 && method == 'POST') {
      if (!['demo-mobile', 'demo-design'].contains(data['categoryId'])) {
        fail('Choose an active demo category.');
      }
      final course = {
        ...data,
        'id': 'demo-course-${++sequence}',
        'status': 'DRAFT',
        'price': 0,
      };
      courses.add(course);
      return result({'course': course});
    }
    if (parts.length < 2) return null;
    final id = parts[1];
    final op = parts.length > 2 ? parts[2] : '';
    final collection = switch (resource) {
      'courses' => courses,
      'sections' => sections,
      'lessons' => lessons,
      'quizzes' => quizzes,
      'quiz-questions' => questions,
      'assignments' => assignments,
      'submissions' => submissions,
      _ => null,
    };
    if (collection == null) return null;
    final record = find(collection, id);
    final course = courseFor(resource, record);
    if (method != 'GET') editable(course);
    if (resource == 'courses') {
      if (op == 'sections') {
        return child(
          method,
          uri,
          sections,
          'sections',
          'courseId',
          id,
          data,
          defaults: {'isPublished': false},
        );
      }
      if (op == 'quizzes') {
        if (method == 'GET') {
          return page(
            'quizzes',
            quizzes.where((q) => q['courseId'] == id),
            uri,
          );
        }
        return child(
          method,
          uri,
          quizzes,
          'quizzes',
          'courseId',
          id,
          data,
          defaults: {'isPublished': false},
        );
      }
      if (op == 'assignments') {
        if (method == 'GET') {
          return page(
            'assignments',
            assignments.where((q) => q['courseId'] == id),
            uri,
          );
        }
        return child(
          method,
          uri,
          assignments,
          'assignments',
          'courseId',
          id,
          data,
          defaults: {'isPublished': false},
        );
      }
      if (op == 'enrollments' && method == 'GET') {
        return page(
          'enrollments',
          enrollments.where((e) => e['courseId'] == id),
          uri,
        );
      }
      if (op == 'archive' && method == 'PATCH') {
        record['status'] = 'ARCHIVED';
        return result({'course': record});
      }
      if (op == 'publish' && method == 'PATCH') {
        final sectionIds = sections
            .where((s) => s['courseId'] == id && s['isPublished'] == true)
            .map(recordId)
            .toSet();
        if (!lessons.any(
          (l) =>
              sectionIds.contains(l['sectionId']) && l['isPublished'] == true,
        )) {
          fail(
            'Publish a section with at least one valid published lesson first.',
          );
        }
        record['status'] = 'PUBLISHED';
        return result({'course': record});
      }
    }
    if (resource == 'sections') {
      if (op == 'lessons') {
        return child(
          method,
          uri,
          lessons,
          'lessons',
          'sectionId',
          id,
          data,
          defaults: {'isPublished': false, 'isPreview': false},
        );
      }
      if (op == 'reorder' && method == 'PATCH') {
        final siblings =
            sections.where((s) => s['courseId'] == record['courseId']).toList()
              ..sort(
                (a, b) => (a['order'] as num).compareTo(b['order'] as num),
              );
        final order = data['order'];
        if (order is! int || order < 1 || order > siblings.length) {
          fail('Choose a position between 1 and ${siblings.length}.');
        }
        siblings.remove(record);
        siblings.insert(order - 1, record);
        for (var i = 0; i < siblings.length; i++) {
          siblings[i]['order'] = i + 1;
        }
        return result({'section': record});
      }
    }
    if (resource == 'lessons' &&
        method == 'PATCH' &&
        data['isPublished'] == true) {
      final merged = {...record, ...data};
      final field = switch (merged['lessonType']) {
        'TEXT' => 'textContent',
        'VIDEO' => 'videoUrl',
        _ => 'documentUrl',
      };
      if ('${merged[field] ?? ''}'.trim().isEmpty) {
        fail(
          'Add the lesson content or simulate its media upload before publishing.',
        );
      }
    }
    if (resource == 'quizzes') {
      if (op == 'attempts' && method == 'GET') {
        return page('attempts', attempts.where((a) => a['quizId'] == id), uri);
      }
      if (op == 'instructor' && method == 'GET') {
        return result({
          'quiz': {
            ...record,
            'questions': questions.where((q) => q['quizId'] == id).toList(),
          },
        });
      }
      if (method != 'GET' && record['isPublished'] == true) {
        fail('Published quizzes cannot be edited.');
      }
      if (op == 'questions') {
        return child(method, uri, questions, 'questions', 'quizId', id, data);
      }
      if (op == 'publish' && method == 'PATCH') {
        if (!questions.any((q) => q['quizId'] == id)) {
          fail('Add a valid question before publishing.');
        }
        record['isPublished'] = true;
        return result({'quiz': record});
      }
    }
    if (resource == 'quiz-questions' &&
        find(quizzes, '${record['quizId']}')['isPublished'] == true &&
        method != 'GET') {
      fail('Published quiz questions cannot be edited.');
    }
    if (resource == 'assignments') {
      if (op == 'submissions' && method == 'GET') {
        return page(
          'submissions',
          submissions.where((s) => s['assignmentId'] == id),
          uri,
        );
      }
      if (op == 'publish' && method == 'PATCH') {
        record['isPublished'] = true;
        return result({'assignment': record});
      }
      if (method == 'PATCH' &&
          data['maximumMarks'] is num &&
          submissions.any(
            (s) =>
                s['assignmentId'] == id &&
                (s['marksAwarded'] as num? ?? 0) >
                    (data['maximumMarks'] as num),
          )) {
        fail('Maximum marks cannot be lower than marks already awarded.');
      }
    }
    if (resource == 'submissions' && op == 'grade' && method == 'PATCH') {
      final assignment = find(assignments, '${record['assignmentId']}');
      InstructorService.validateGrade(
        '${data['status']}',
        data['marksAwarded'] as num?,
        assignment['maximumMarks'] as num,
        '${data['feedback'] ?? ''}',
      );
      record.addAll(data);
      if (data['status'] == 'RESUBMISSION_REQUIRED') {
        record.remove('marksAwarded');
      }
      return result({'submission': record});
    }
    if (method == 'POST' &&
        body is FormData &&
        ['thumbnail', 'video', 'document', 'attachment'].contains(op)) {
      final files = body.files.where((f) => f.key == op).toList();
      if (files.length != 1) fail('Choose one $op file.');
      progress?.call(1, 2);
      progress?.call(2, 2);
      record['${op}Url'] =
          'demo://selected/${Uri.encodeComponent(files.single.value.filename ?? op)}';
      record['${op}Name'] = files.single.value.filename;
      return result({singular(resource): record});
    }
    if (method == 'PATCH' && op.isEmpty) {
      record.addAll(data);
      return result({singular(resource): record});
    }
    if (method == 'GET' && op.isEmpty) {
      return result({singular(resource): record});
    }
    return null;
  }

  String singular(String key) => switch (key) {
    'courses' => 'course',
    'sections' => 'section',
    'lessons' => 'lesson',
    'quizzes' => 'quiz',
    'questions' || 'quiz-questions' => 'question',
    'assignments' => 'assignment',
    _ => 'submission',
  };
  Map<String, dynamic> child(
    String method,
    Uri uri,
    List<Map<String, dynamic>> list,
    String key,
    String parent,
    String id,
    Map<String, dynamic> data, {
    Map<String, dynamic> defaults = const {},
  }) {
    if (method == 'GET') {
      return page(key, list.where((r) => r[parent] == id), uri);
    }
    if (method != 'POST') fail('This demo action is unavailable.');
    final record = {
      ...defaults,
      ...data,
      'id': 'demo-$key-${++sequence}',
      parent: id,
      'order': list.where((r) => r[parent] == id).length + 1,
    };
    list.add(record);
    return result({singular(key): record});
  }
}
