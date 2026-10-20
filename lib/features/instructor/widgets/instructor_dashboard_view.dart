import 'package:flutter/material.dart';

import 'instructor_widgets.dart';
import '../../learning/learning_service.dart';

class InstructorDashboardView extends StatelessWidget {
  const InstructorDashboardView({
    super.key,
    required this.data,
    required this.name,
    required this.courses,
    required this.onCreate,
    required this.onCourses,
    required this.onLearners,
    required this.onOpenCourse,
    this.loading = false,
  });
  final Map<String, dynamic> data;
  final String name;
  final List<Map<String, dynamic>> courses;
  final VoidCallback? onCreate, onCourses, onLearners;
  final ValueChanged<Map<String, dynamic>> onOpenCourse;
  final bool loading;
  num? count(List<String> keys) {
    final values = {
      ...object(data['summary']),
      ...object(data['stats']),
      ...data,
    };
    for (final key in keys) {
      if (values[key] is num) return values[key] as num;
    }
    return null;
  }

  String metric(List<String> keys, {bool rating = false}) {
    final value = count(keys);
    if (value == null) return '—';
    return rating && value > 0 ? value.toStringAsFixed(1) : '$value';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        name.isEmpty ? 'Welcome to your studio' : 'Good to see you, $name',
        style: const TextStyle(fontSize: 13, color: studioMuted),
      ),
      const SizedBox(height: 6),
      const Text(
        'Your teaching, in focus.',
        style: TextStyle(
          fontSize: 26,
          color: studioInk,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -.7,
        ),
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF163F31), Color(0xFF326B4F)],
          ),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xFFD8E9BA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'COURSE BUILDER',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFD8E9BA),
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            const Text(
              'What will you teach next?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Create a course. Build it one lesson at a time.',
              style: TextStyle(
                color: Color(0xFFCDDDCF),
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE1EDCE),
                foregroundColor: studioInk,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text(
                'Create course',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'LmsRoboto',
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const StudioHeading(
        'Your impact',
        subtitle: 'A snapshot of your teaching',
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final single =
              constraints.maxWidth < 270 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.6;
          final width = single
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: StudioMetric(
                  label: 'Total courses',
                  value: metric(['totalCourses']),
                  icon: Icons.auto_stories_outlined,
                ),
              ),
              SizedBox(
                width: width,
                child: StudioMetric(
                  label: 'Learners',
                  value: metric(['totalEnrollments', 'activeEnrollments']),
                  icon: Icons.people_outline_rounded,
                  color: const Color(0xFF5276A6),
                ),
              ),
              SizedBox(
                width: width,
                child: StudioMetric(
                  label: 'To review',
                  value: metric([
                    'pendingSubmissions',
                    'pendingAssignmentSubmissions',
                  ]),
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFFA9783E),
                ),
              ),
              SizedBox(
                width: width,
                child: StudioMetric(
                  label: 'Course rating',
                  value: metric([
                    'averageCourseRating',
                    'averageRating',
                  ], rating: true),
                  icon: Icons.star_outline_rounded,
                  color: const Color(0xFFA9783E),
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2E9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _portfolio('Published', count(['publishedCourses'])),
            _portfolio('Drafts', count(['draftCourses'])),
            _portfolio('Archived', count(['archivedCourses'])),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const StudioHeading('Keep things moving'),
      StudioAction(
        title: 'My courses',
        subtitle: 'Build, refine and publish your curriculum.',
        icon: Icons.edit_note_rounded,
        onTap: onCourses,
      ),
      StudioAction(
        title: 'Learner reviews',
        subtitle: 'Review submissions, results and enrollment.',
        icon: Icons.grading_rounded,
        color: const Color(0xFF9A7149),
        onTap: onLearners,
      ),
      if (courses.isNotEmpty) ...[
        const SizedBox(height: 14),
        StudioHeading(
          'Your latest courses',
          trailing: TextButton(
            onPressed: onCourses,
            child: const Text('View all'),
          ),
        ),
        for (final course in courses.take(2))
          StudioCourseCard(course, onTap: () => onOpenCourse(course)),
      ],
    ],
  );
  Widget _portfolio(String label, num? value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value == null ? '—' : '$value',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          fontFamily: 'LmsRoboto',
          color: studioInk,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: studioMuted, fontSize: 11)),
    ],
  );
}
