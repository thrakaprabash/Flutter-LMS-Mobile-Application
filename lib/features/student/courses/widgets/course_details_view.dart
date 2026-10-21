import 'package:flutter/material.dart';

import '../../../../shared/models/learning_page.dart';
import '../../learning/widgets/learning_widgets.dart';
import 'course_detail_widgets.dart';
import 'course_section_tile.dart';

class CourseDetailsView extends StatelessWidget {
  const CourseDetailsView({
    super.key,
    required this.course,
    required this.progress,
    required this.sections,
    required this.busy,
    required this.enrolled,
    required this.error,
    required this.curriculumError,
    required this.progressError,
    required this.lessonStatuses,
    required this.load,
    required this.enroll,
    required this.continueLearning,
    required this.openActivity,
    required this.openLesson,
  });
  final Map<String, dynamic>? course, progress;
  final List<Map<String, dynamic>> sections;
  final bool busy, enrolled;
  final String? error, curriculumError, progressError;
  final Map<String, String> lessonStatuses;
  final VoidCallback load, enroll, continueLearning;
  final ValueChanged<String> openActivity, openLesson;
  @override
  Widget build(BuildContext context) {
    final c = course;
    final p = object(progress?['enrollment'] ?? progress);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course details'),
        actions: [
          IconButton(
            tooltip: 'Refresh course',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            DetailPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error!),
                  TextButton(
                    onPressed: busy ? null : load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (c != null) ...[
            CourseHero(course: c),
            const SizedBox(height: 16),
            DetailPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (enrolled) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Your progress',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer.withValues(
                                  alpha: .5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                friendlyStatus('${p['status'] ?? 'Enrolled'}'),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (progressError != null) Text(progressError!),
                    CourseProgress(
                      value: p['progressPercentage'],
                      onRetry: busy ? null : load,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: busy || sections.isEmpty
                          ? null
                          : continueLearning,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Continue learning'),
                    ),
                  ] else ...[
                    Text(
                      'Start your next chapter',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text('Join this course and learn at your own pace.'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: busy ? null : enroll,
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Enroll now'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Explore this course', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 460 ? 3 : 2;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (enrolled) ...[
                      SizedBox(
                        width: width,
                        child: CourseShortcut(
                          icon: Icons.quiz_outlined,
                          title: 'Quizzes',
                          subtitle: 'Check your knowledge',
                          onTap: busy ? null : () => openActivity('Quizzes'),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: CourseShortcut(
                          icon: Icons.assignment_outlined,
                          title: 'Assignments',
                          subtitle: 'Put learning into practice',
                          onTap: busy
                              ? null
                              : () => openActivity('Assignments'),
                        ),
                      ),
                    ],
                    SizedBox(
                      width: enrolled ? width : constraints.maxWidth,
                      child: CourseShortcut(
                        icon: Icons.star_outline_rounded,
                        title: 'Reviews',
                        subtitle: 'Hear from other learners',
                        onTap: busy ? null : () => openActivity('Reviews'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            DetailPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('${c['description'] ?? ''}'),
                  if (c['learningOutcomes'] is List &&
                      (c['learningOutcomes'] as List).isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'What you’ll learn',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (final outcome in c['learningOutcomes'] as List)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 20,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text('$outcome')),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Curriculum', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${sections.length} available ${sections.length == 1 ? 'section' : 'sections'} · Learn step by step',
            ),
            const SizedBox(height: 16),
            if (curriculumError != null)
              DetailPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(curriculumError!),
                    TextButton(
                      onPressed: busy ? null : load,
                      child: const Text('Retry curriculum'),
                    ),
                  ],
                ),
              ),
            if (sections.isEmpty && curriculumError == null && !busy)
              const DetailPanel(child: Text('No available sections.')),
            for (final section in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: CourseSectionTile(
                    section: section,
                    onLesson: openLesson,
                    statuses: lessonStatuses,
                    enrolled: enrolled,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
