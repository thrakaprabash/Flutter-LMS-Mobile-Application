import 'package:flutter_lms/shared/models/dashboard_models.dart';

/// Day 3 sample data only; no API or session is implemented.
abstract final class InstructorDashboardPreview {
  static const summary = DashboardData(
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
  );
  static const management = ManagementPreview(
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
}
