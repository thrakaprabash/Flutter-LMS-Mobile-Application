import 'package:flutter/material.dart';

import '../../learning/learning_service.dart';
import 'instructor_widgets.dart';

class InstructorDetailView extends StatelessWidget {
  const InstructorDetailView({
    super.key,
    required this.data,
    required this.kind,
    required this.onOpenLink,
    this.excluded = const [],
  });
  final Map<String, dynamic> data;
  final String kind;
  final List<String> excluded;
  final ValueChanged<String> onOpenLink;
  @override
  Widget build(BuildContext context) {
    final status =
        data['status'] ?? (data['isPublished'] == true ? 'PUBLISHED' : 'DRAFT');
    final meta = <(IconData, String)>[
      if (data['lessonType'] != null)
        (
          contentIcon('${data['lessonType']}'),
          instructorLabel(data['lessonType']),
        ),
      if (data['durationMinutes'] != null)
        (Icons.schedule_rounded, '${data['durationMinutes']} minutes'),
      if (data['level'] != null)
        (Icons.signal_cellular_alt_rounded, instructorLabel(data['level'])),
      if (data['language'] != null)
        (Icons.language_rounded, '${data['language']}'),
      if (data['passingScore'] != null)
        (Icons.flag_outlined, '${data['passingScore']}% to pass'),
      if (data['timeLimitMinutes'] != null)
        (Icons.timer_outlined, '${data['timeLimitMinutes']} minutes'),
      if (data['maxAttempts'] != null)
        (Icons.replay_rounded, '${data['maxAttempts']} attempts'),
      if (data['maximumMarks'] != null && kind != 'submission')
        (Icons.workspace_premium_outlined, '${data['maximumMarks']} marks'),
      if (data['dueDate'] != null)
        (Icons.event_outlined, 'Due ${studioDate(data['dueDate'])}'),
      if (data['marksAwarded'] != null)
        (
          Icons.workspace_premium_outlined,
          '${data['marksAwarded']} / ${data['maximumMarks'] ?? object(data['assignmentId'])['maximumMarks'] ?? '—'} marks',
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kind == 'submission') StudioLearnerCard(data),
        if (kind != 'course')
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StudioStatus('$status'),
            ),
          ),
        if (meta.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final entry in meta)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.$1, size: 16, color: studioInk),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          entry.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: studioInk,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        for (final field in const [
          ('description', 'Overview'),
          ('instructions', 'What learners need to do'),
          ('textContent', 'Lesson content'),
          ('textAnswer', 'Learner response'),
          ('feedback', 'Your feedback'),
        ])
          if ('${data[field.$1] ?? ''}'.trim().isNotEmpty)
            _section(
              field.$2,
              SelectableText(
                '${data[field.$1]}',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Color(0xFF52665B),
                ),
              ),
            ),
        for (final field in const [
          ('learningOutcomes', 'What learners will achieve'),
          ('requirements', 'Before getting started'),
          ('targetAudience', 'Who this course is for'),
        ])
          if (data[field.$1] is List && (data[field.$1] as List).isNotEmpty)
            _section(
              field.$2,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in data[field.$1] as List)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 17,
                            color: Color(0xFF64895D),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$item',
                              style: const TextStyle(fontSize: 13, height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        for (final field in const [
          ('videoUrl', 'Lesson video', Icons.play_circle_outline_rounded),
          ('documentUrl', 'Lesson document', Icons.description_outlined),
          ('attachmentUrl', 'Assignment resource', Icons.attach_file_rounded),
          ('fileUrl', 'Submitted file', Icons.file_present_outlined),
        ])
          if ('${data[field.$1] ?? ''}'.isNotEmpty)
            StudioAction(
              title: field.$2,
              subtitle: '${data[field.$1]}'.startsWith('demo://')
                  ? 'Media selected locally · Demo upload simulated'
                  : 'Open the attached resource',
              icon: field.$3,
              onTap: '${data[field.$1]}'.startsWith('demo://')
                  ? null
                  : () => onOpenLink('${data[field.$1]}'),
            ),
      ],
    );
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: studioInk,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );
}
