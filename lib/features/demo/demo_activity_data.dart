import 'package:dio/dio.dart';

/// Session-local fixtures for the explicitly selected debug demo. No transport.
class DemoActivityData {
  final notifications = <Map<String, dynamic>>[
    {
      'id': 'demo-notice',
      'title': 'Welcome to your learning space',
      'message': 'Demo notifications stay on this device.',
      'isRead': false,
    },
    {
      'id': 'demo-feedback',
      'title': 'Assignment feedback',
      'message':
          'Your instructor requested a correction in the sample assignment.',
      'isRead': false,
    },
  ];
  final submissions = <String, Map<String, dynamic>>{
    'demo-assignment': {
      'id': 'demo-submission',
      'status': 'RESUBMISSION_REQUIRED',
      'textAnswer': 'My first draft',
      'feedback': 'Add a clear explanation of your widget layout.',
    },
    'demo-graded': {
      'id': 'demo-graded-submission',
      'status': 'GRADED',
      'textAnswer': 'Completed work',
      'marksAwarded': 85,
      'feedback': 'Good work.',
    },
  };
  final reviews = <Map<String, dynamic>>[];
  final attempts = <Map<String, dynamic>>[];
  static const question = {
    'id': 'demo-question',
    'questionText': 'Which widget arranges children vertically?',
    'questionType': 'SINGLE_CHOICE',
    'options': [
      {'id': 'A', 'text': 'Column'},
      {'id': 'B', 'text': 'Row'},
    ],
  };
  static const quiz = {
    'id': 'demo-quiz',
    'title': 'Widget essentials',
    'description': 'Local sample quiz',
    'timeLimitMinutes': 10,
    'maxAttempts': 3,
    'passingScore': 60,
  };
  Map<String, dynamic> page(
    String key,
    List<Map<String, dynamic>> items,
    Uri uri,
  ) => {
    'data': {
      key:
          uri.queryParameters['page'] == null ||
              uri.queryParameters['page'] == '1'
          ? items
          : [],
      'pagination': {'hasNextPage': false},
    },
  };
  Map<String, dynamic>? handle(String method, String path, Object? body) {
    final uri = Uri.parse(path);
    final p = uri.path;
    final parts = p.split('/');
    if (p == '/api/v1/notifications/me/unread-count') {
      return {
        'data': {
          'unreadCount': notifications.where((n) => n['isRead'] != true).length,
        },
      };
    }
    if (p == '/api/v1/notifications/me/read-all' && method == 'PATCH') {
      for (final n in notifications) {
        n['isRead'] = true;
      }
      return {'data': {}};
    }
    if (p == '/api/v1/notifications/me' && method == 'GET') {
      return page(
        'notifications',
        notifications
            .where(
              (n) =>
                  uri.queryParameters['unreadOnly'] != 'true' ||
                  n['isRead'] != true,
            )
            .map((n) => Map<String, dynamic>.from(n))
            .toList(),
        uri,
      );
    }
    if (p.startsWith('/api/v1/notifications/')) {
      if (method == 'DELETE') {
        notifications.removeWhere((n) => n['id'] == parts[4]);
      }
      if (method == 'PATCH') {
        for (final n in notifications.where((n) => n['id'] == parts[4])) {
          n['isRead'] = true;
        }
      }
      return {'data': {}};
    }
    if (p.endsWith('/quizzes') && method == 'GET') {
      return page('quizzes', [Map<String, dynamic>.from(quiz)], uri);
    }
    if (p == '/api/v1/quizzes/demo-quiz') {
      return {
        'data': {
          'quiz': quiz,
          'questions': [question],
        },
      };
    }
    if (p.endsWith('/attempts/me')) return page('attempts', attempts, uri);
    if (p == '/api/v1/quizzes/demo-quiz/start') {
      if (attempts.where((a) => a['status'] == 'IN_PROGRESS').isNotEmpty ||
          attempts.length >= 3) {
        throw const FormatException('Demo attempt limit reached.');
      }
      final attempt = <String, dynamic>{
        'id': 'demo-attempt-${attempts.length + 1}',
        'attemptNumber': attempts.length + 1,
        'status': 'IN_PROGRESS',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 10))
            .toIso8601String(),
      };
      attempts.insert(0, attempt);
      return {
        'data': {
          'attempt': Map<String, dynamic>.from(attempt),
          'questions': [question],
        },
      };
    }
    if (p.startsWith('/api/v1/quiz-attempts/') && p.endsWith('/submit')) {
      final attempt = attempts.firstWhere((a) => a['id'] == parts[4]);
      // Fixed illustrative result; the production client never scores answers.
      attempt.addAll({
        'status': 'SUBMITTED',
        'score': 1,
        'totalMarks': 1,
        'percentage': 100,
        'passed': true,
      });
      return {'data': Map<String, dynamic>.from(attempt)};
    }
    if (p.endsWith('/assignments') && method == 'GET') {
      return page('assignments', [
        {
          'id': 'demo-assignment',
          'title': 'Build a learning card',
          'description': 'Explain your widget layout.',
        },
        {
          'id': 'demo-graded',
          'title': 'Completed layout exercise',
          'description': 'Inspect a graded submission.',
        },
      ], uri);
    }
    if (p.startsWith('/api/v1/assignments/')) {
      final id = parts[4];
      if (p.endsWith('/submission/me')) {
        return {
          'data': {
            'submission': Map<String, dynamic>.from(submissions[id] ?? {}),
          },
        };
      }
      if (p.endsWith('/submissions') && body is FormData) {
        if (submissions[id]?['status'] == 'GRADED') {
          throw const FormatException('Graded work cannot be edited.');
        }
        submissions[id] = {
          'id': 'demo-submission',
          'status': 'SUBMITTED',
          'textAnswer': body.fields
              .where((e) => e.key == 'textAnswer')
              .map((e) => e.value)
              .join(),
          'feedback': 'Demo submission received locally.',
        };
        return {
          'data': {'submission': submissions[id]},
        };
      }
      return {
        'data': {
          'id': id,
          'title': id == 'demo-graded'
              ? 'Completed layout exercise'
              : 'Build a learning card',
          'description': 'Explain the structure of a reusable Flutter card. You may attach a document.',
          'maxMarks': 100,
        },
      };
    }
    if (p.endsWith('/reviews') && method == 'GET') {
      return page('reviews', reviews, uri);
    }
    if (p.endsWith('/reviews') && body is Map && method == 'POST') {
      if (reviews.isNotEmpty) {
        throw const FormatException('A demo review already exists.');
      }
      reviews.add({
        'id': 'demo-review',
        'studentId': 'demo-user',
        ...Map<String, dynamic>.from(body),
      });
      return {
        'data': {'review': reviews.first},
      };
    }
    if (p == '/api/v1/reviews/demo-review' &&
        body is Map &&
        method == 'PATCH') {
      reviews.first.addAll(Map<String, dynamic>.from(body));
      return {
        'data': {'review': reviews.first},
      };
    }
    return null;
  }
}
