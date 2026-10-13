import 'package:flutter_lms/shared/models/dashboard_models.dart';

/// Day 3 sample data only; no API or session is implemented.
abstract final class AdminDashboardPreview {
  static const summary = DashboardData(
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
  );
  static const management = ManagementPreview(
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
