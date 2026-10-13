enum LmsRole { student, instructor, admin }

class DashboardData {
  const DashboardData({
    required this.title,
    required this.greeting,
    required this.subtitle,
    required this.metrics,
    required this.destinations,
    required this.activity,
  });
  final String title;
  final String greeting;
  final String subtitle;
  final List<(String, String)> metrics;
  final List<String> destinations;
  final List<String> activity;
}

/// Temporary fixtures isolated from presentation for later API mapping.
abstract final class DemoDashboards {
  static DashboardData forRole(LmsRole role) => switch (role) {
    LmsRole.student => const DashboardData(
      title: 'Student dashboard',
      greeting: 'Welcome back, learner',
      subtitle: 'A little progress today goes a long way.',
      metrics: [
        ('Enrolled courses', '4'),
        ('Completed lessons', '12'),
        ('Learning streak', '3 days'),
      ],
      destinations: ['Overview', 'My courses', 'Assignments', 'Profile'],
      activity: [
        'Completed: Introduction to Flutter',
        'Enrolled: UI Design Fundamentals',
      ],
    ),
    LmsRole.instructor => const DashboardData(
      title: 'Instructor dashboard',
      greeting: 'Ready to inspire?',
      subtitle: 'Help your students take their next step.',
      metrics: [
        ('Your courses', '3'),
        ('Active students', '84'),
        ('To grade', '7'),
      ],
      destinations: ['Overview', 'Courses', 'Submissions', 'Profile'],
      activity: [
        'New submission in Flutter Foundations',
        '5 students joined UI Design Fundamentals',
      ],
    ),
    LmsRole.admin => const DashboardData(
      title: 'Admin dashboard',
      greeting: 'Your platform at a glance',
      subtitle: 'Keep your learning community moving forward.',
      metrics: [
        ('Platform users', '248'),
        ('Published courses', '18'),
        ('Pending reviews', '6'),
      ],
      destinations: ['Overview', 'Users', 'Categories', 'Profile'],
      activity: [
        'New instructor account registered',
        'Course published: UI Design Fundamentals',
      ],
    ),
  };
}

class CoursePreview {
  const CoursePreview(
    this.code,
    this.title,
    this.lesson,
    this.progress,
    this.completed,
    this.duration,
  );
  final String code;
  final String title;
  final String lesson;
  final double progress;
  final String completed;
  final int duration;
}

class DeadlinePreview {
  const DeadlinePreview(this.title, this.course, this.due, {this.quiz = false});
  final String title;
  final String course;
  final String due;
  final bool quiz;
}

abstract final class StudentPreview {
  static const courses = [
    CoursePreview(
      'CS 204',
      'Flutter Foundations',
      'Up next: Building your first layout',
      0.4,
      '4 of 10',
      15,
    ),
    CoursePreview(
      'DES 201',
      'UI Design Fundamentals',
      'Up next: Layout and visual hierarchy',
      0.65,
      '13 of 20',
      12,
    ),
    CoursePreview(
      'CS 210',
      'Database Systems',
      'Up next: Understanding relationships',
      0.2,
      '2 of 10',
      20,
    ),
  ];
  static const deadlines = [
    DeadlinePreview(
      'Build a responsive layout',
      'CS 204 · Flutter Foundations',
      'Due tomorrow · 11:59 PM',
    ),
    DeadlinePreview(
      'Visual hierarchy quiz',
      'DES 201 · UI Design Fundamentals',
      'Due in 3 days · 5:00 PM',
      quiz: true,
    ),
  ];
}

class ManagementPreview {
  const ManagementPreview({
    required this.focusTitle,
    required this.focusMessage,
    required this.focusAction,
    required this.queueTitle,
    required this.queue,
    required this.shortcuts,
    required this.collectionTitle,
    required this.collection,
  });
  final String focusTitle;
  final String focusMessage;
  final String focusAction;
  final String queueTitle;
  final List<(String, String, String)> queue;
  final List<String> shortcuts;
  final String collectionTitle;
  final List<(String, String, String)> collection;

  static const instructor = ManagementPreview(
    focusTitle: '7 submissions ready for feedback',
    focusMessage: 'Help your students move forward. Start with the work waiting for your review.',
    focusAction: 'Review submissions',
    queueTitle: 'Needs your attention',
    queue: [
      (
        'Responsive layout assignment',
        'CS 204 · Flutter Foundations',
        '4 submissions to grade',
      ),
      (
        'Design principles assignment',
        'DES 201 · UI Design Fundamentals',
        '3 submissions to grade',
      ),
    ],
    shortcuts: [
      'Create a course',
      'Review submissions',
      'View enrollments',
      'Create an assignment',
    ],
    collectionTitle: 'Your teaching',
    collection: [
      ('Flutter Foundations', 'CS 204 · 36 students · 10 lessons', 'Published'),
      (
        'UI Design Fundamentals',
        'DES 201 · 48 students · 20 lessons',
        'Published',
      ),
      ('Advanced Flutter', 'CS 304 · 3 lessons prepared', 'Draft'),
    ],
  );

  static const admin = ManagementPreview(
    focusTitle: '6 reviews need moderation',
    focusMessage: 'Keep course feedback useful and respectful for your university community.',
    focusAction: 'Moderate reviews',
    queueTitle: 'Needs your attention',
    queue: [
      (
        'Course reviews',
        'Inspect feedback before taking action',
        '6 reviews awaiting moderation',
      ),
      (
        'User account requests',
        'Review account status and access',
        '3 requests to review',
      ),
    ],
    shortcuts: [
      'Manage users',
      'Manage categories',
      'Platform courses',
      'Moderate reviews',
    ],
    collectionTitle: 'Platform overview',
    collection: [
      (
        'Student community',
        '230 student accounts across the platform',
        'Users',
      ),
      ('Teaching team', '18 instructor accounts', 'Instructors'),
      ('Course catalog', '18 published courses across 6 categories', 'Courses'),
    ],
  );
}
