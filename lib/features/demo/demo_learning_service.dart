import '../student/learning/services/learning_service.dart';

/// Local sample state exists only inside the debug demo's provider scope.
class DemoLearningService extends LearningService {
  DemoLearningService(super.account);
  final Set<String> enrolled = {};
  final Set<String> completed = {};
  final sample = <String, dynamic>{
    'id': 'demo-course',
    'title': 'Flutter foundations',
    'description':
        'Learn widgets, layouts and navigation through practical lessons.',
    'instructorId': {'firstName': 'Alex', 'lastName': 'Taylor'},
    'level': 'BEGINNER',
    'shortDescription': 'Build your first Flutter interface.',
  };
  @override
  Future<LearningPage> catalogue({
    int page = 1,
    String search = '',
    String category = '',
  }) async => LearningPage(
    page == 1 &&
            sample['title'].toString().toLowerCase().contains(
              search.toLowerCase(),
            )
        ? [sample]
        : [],
    false,
  );
  @override
  Future<List<Map<String, dynamic>>> categories() async => [
    {'id': 'demo-category', 'name': 'Mobile development'},
  ];
  @override
  Future<LearningPage> enrollments(int page, String status) async =>
      LearningPage(
        page == 1 &&
                enrolled.isNotEmpty &&
                status == (completed.length == 3 ? 'COMPLETED' : 'ACTIVE')
            ? [
                {
                  'id': 'demo-enrollment',
                  'courseId': sample,
                  'status': status,
                  'progressPercentage': completed.length / 3 * 100,
                },
              ]
            : [],
        false,
      );
  @override
  Future<Map<String, dynamic>> detail(String id) async => sample;
  @override
  Future<void> enroll(String id) async {
    enrolled.add(id);
  }

  @override
  Future<List<Map<String, dynamic>>> sections(String id) async => [
    {'id': 'demo-section', 'title': 'Getting started', 'lessonCount': 3},
  ];
  @override
  Future<List<Map<String, dynamic>>> lessons(String id) async => [
    for (final type in ['TEXT', 'VIDEO', 'DOCUMENT'])
      {
        'id': 'demo-$type',
        'title': 'Explore ${type.toLowerCase()} lessons',
        'lessonType': type,
      },
  ];
  @override
  Future<Map<String, dynamic>> lesson(String id) async => {
    'id': id,
    'title': 'Flutter foundations',
    'lessonType': id.split('-').last,
    'videoUrl':
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'documentUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    'textContent': 'Widgets describe your interface. Compose small widgets to build a complete screen. Try a Column containing a heading and a button.',
  };
  @override
  Future<Map<String, dynamic>> progress(String id) async => {
    'lessons': [
      for (final type in ['TEXT', 'VIDEO', 'DOCUMENT'])
        {
          'lessonId': 'demo-$type',
          'status': completed.contains('demo-$type')
              ? 'COMPLETED'
              : 'NOT_STARTED',
        },
    ],
    'enrollment': {
      'status': completed.length == 3 ? 'COMPLETED' : 'ACTIVE',
      'progressPercentage': completed.length / 3 * 100,
    },
  };
  @override
  Future<void> start(String id) async {}
  @override
  Future<void> complete(String id) async {
    completed.add(id);
  }
}
