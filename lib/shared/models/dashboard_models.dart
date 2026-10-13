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
}
