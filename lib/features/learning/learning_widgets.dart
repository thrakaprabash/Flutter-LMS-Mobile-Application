import 'package:flutter/material.dart';

import 'learning_service.dart';

num? progressValue(dynamic value) {
  final parsed = num.tryParse('$value');
  return parsed != null && parsed.isFinite && parsed >= 0 && parsed <= 100
      ? parsed
      : null;
}

String instructorName(Map<String, dynamic> course) {
  final instructor = object(course['instructorId'] ?? course['instructor']);
  final name =
      '${instructor['firstName'] ?? ''} ${instructor['lastName'] ?? ''}'.trim();
  return name.isEmpty ? 'Instructor information unavailable' : name;
}

String friendlyStatus(String status) => switch (status) {
  'ACTIVE' => 'In progress',
  'COMPLETED' => 'Completed',
  'CANCELLED' => 'Cancelled',
  'IN_PROGRESS' => 'In progress',
  'NOT_STARTED' => 'Not started',
  _ => status,
};
IconData lessonIcon(String type) => switch (type) {
  'VIDEO' => Icons.play_circle_outline,
  'DOCUMENT' => Icons.description_outlined,
  _ => Icons.article_outlined,
};

class CourseProgress extends StatelessWidget {
  const CourseProgress({super.key, required this.value, this.onRetry});
  final dynamic value;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final percentage = progressValue(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (percentage == null) ...[
          const Text('Progress unavailable'),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry progress')),
        ] else ...[
          Text('${percentage.toStringAsFixed(1)}% complete'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
            semanticsLabel: 'Course progress',
            semanticsValue: '${percentage.toStringAsFixed(1)}%',
          ),
        ],
      ],
    );
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.enrollment,
    required this.onOpen,
    this.onRetry,
  });
  final Map<String, dynamic> course;
  final Map<String, dynamic>? enrollment;
  final VoidCallback? onOpen, onRetry;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final thumbnail = course['thumbnailUrl']?.toString();
    final status = enrollment?['status']?.toString();
    final active = status == 'ACTIVE' || status == 'COMPLETED';
    final placeholder = Container(
      color: colors.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.menu_book_outlined, size: 40, color: colors.primary),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              height: 132,
              child: thumbnail == null || thumbnail.isEmpty
                  ? placeholder
                  : Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${course['title'] ?? 'Course unavailable'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(instructorName(course)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (course['level'] != null)
                      Chip(label: Text('${course['level']}')),
                    if (status != null)
                      Chip(label: Text(friendlyStatus(status))),
                  ],
                ),
                if (course['shortDescription'] != null) ...[
                  const SizedBox(height: 8),
                  Text('${course['shortDescription']}'),
                ],
                if (enrollment != null) ...[
                  const SizedBox(height: 16),
                  CourseProgress(
                    value: enrollment!['progressPercentage'],
                    onRetry: onRetry,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onOpen,
                  icon: Icon(active ? Icons.play_arrow : Icons.arrow_forward),
                  label: Text(active ? 'Continue learning' : 'View course'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
