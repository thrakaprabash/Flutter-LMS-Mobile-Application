import 'package:flutter_lms/shared/models/dashboard_models.dart';

/// Day 3 sample data only; no API or session is implemented.
abstract final class StudentDashboardPreview {
  static const summary = DashboardData(
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
  );

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
