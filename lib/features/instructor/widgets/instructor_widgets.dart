import 'package:flutter/material.dart';

import '../../../shared/models/learning_page.dart';

const studioInk = Color(0xFF173E32);
const studioMuted = Color(0xFF718078);
const studioLine = Color(0xFFE4EAE3);

String instructorLabel(Object? value) => (value ?? '')
    .toString()
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .where((s) => s.isNotEmpty)
    .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
    .join(' ');
String learnerName(Map<String, dynamic> data) {
  final person = object(data['student'] ?? data['studentId']);
  final name = [
    person['firstName'],
    person['lastName'],
  ].whereType<String>().join(' ');
  return '${person['fullName'] ?? person['name'] ?? (name.isNotEmpty ? name : person['email'] ?? 'Learner')}';
}

String studioDate(Object? raw) {
  final date = DateTime.tryParse('$raw')?.toLocal();
  if (date == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

IconData contentIcon(String type) => switch (type.toUpperCase()) {
  'COURSE' => Icons.auto_stories_outlined,
  'SECTION' => Icons.folder_outlined,
  'VIDEO' => Icons.play_circle_outline_rounded,
  'DOCUMENT' => Icons.description_outlined,
  'QUIZ' => Icons.quiz_outlined,
  'ASSIGNMENT' => Icons.assignment_outlined,
  _ => Icons.article_outlined,
};

class StudioStatus extends StatelessWidget {
  const StudioStatus(this.value, {super.key});
  final String value;
  @override
  Widget build(BuildContext context) {
    final good = [
      'PUBLISHED',
      'COMPLETED',
      'GRADED',
      'PASSED',
      'ACTIVE',
    ].contains(value);
    final warning = [
      'DRAFT',
      'SUBMITTED',
      'LATE',
      'RESUBMISSION_REQUIRED',
    ].contains(value);
    final color = good
        ? const Color(0xFF227250)
        : warning
        ? const Color(0xFF9A671F)
        : studioMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value == 'RESUBMISSION_REQUIRED'
            ? 'Correction requested'
            : instructorLabel(value),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StudioHeading extends StatelessWidget {
  const StudioHeading(this.title, {super.key, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: studioInk,
                  height: 1.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: const TextStyle(color: studioMuted, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class StudioAction extends StatelessWidget {
  const StudioAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = studioInk,
    this.badge,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final String? badge;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: studioLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: studioInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: studioMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (badge != null) StudioStatus(badge!),
              const Icon(
                Icons.chevron_right_rounded,
                color: studioMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class StudioMetric extends StatelessWidget {
  const StudioMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = studioInk,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 124),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: studioLine),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const Spacer(),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .4),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: studioInk,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: studioMuted, fontSize: 12)),
      ],
    ),
  );
}

class StudioCourseCard extends StatelessWidget {
  const StudioCourseCard(
    this.data, {
    super.key,
    required this.onTap,
    this.forLearners = false,
  });
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final bool forLearners;
  @override
  Widget build(BuildContext context) {
    final url = '${data['thumbnailUrl'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: studioLine),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: 112,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE4EFE5), Color(0xFFF1F3E6)],
                      ),
                    ),
                    child: url.startsWith('http')
                        ? Image.network(
                            url,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, st) => artwork(),
                          )
                        : artwork(),
                  ),
                  Positioned(
                    top: 12,
                    left: 14,
                    child: StudioStatus('${data['status'] ?? 'DRAFT'}'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['title'] ?? 'Untitled course'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: studioInk,
                      ),
                    ),
                    if ('${data['shortDescription'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        '${data['shortDescription']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: studioMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (data['level'] != null)
                          _meta(
                            Icons.signal_cellular_alt_rounded,
                            instructorLabel(data['level']),
                          ),
                        if (data['language'] != null)
                          _meta(Icons.language_rounded, '${data['language']}'),
                        if (data['totalEnrollments'] != null)
                          _meta(
                            Icons.people_outline_rounded,
                            '${data['totalEnrollments']} learners',
                          ),
                      ],
                    ),
                    const Divider(height: 28, color: studioLine),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            forLearners
                                ? 'View learner activity'
                                : 'Open course builder',
                            style: const TextStyle(
                              color: studioInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: studioInk,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget artwork() => const Center(
    child: Icon(
      Icons.auto_stories_outlined,
      color: Color(0xFF93AD96),
      size: 50,
    ),
  );
  Widget _meta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: studioMuted),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: studioMuted)),
    ],
  );
}

class StudioContentCard extends StatelessWidget {
  const StudioContentCard(
    this.data, {
    super.key,
    required this.type,
    required this.onTap,
  });
  final Map<String, dynamic> data;
  final String type;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final icon = contentIcon('${data['lessonType'] ?? type}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: studioLine),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF3EA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: studioInk, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['order'] != null)
                            Text(
                              '${type == 'section' ? 'SECTION' : 'LESSON'} ${data['order']}',
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                color: studioMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            '${data['title'] ?? 'Untitled'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: studioInk,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: studioMuted,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 10,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StudioStatus(
                      data['isPublished'] == true ? 'PUBLISHED' : 'DRAFT',
                    ),
                    if (data['lessonType'] != null)
                      Text(
                        instructorLabel(data['lessonType']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: studioMuted,
                        ),
                      ),
                    if (data['durationMinutes'] != null)
                      Text(
                        '${data['durationMinutes']} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: studioMuted,
                        ),
                      ),
                    if (data['questionCount'] != null)
                      Text(
                        '${data['questionCount']} questions',
                        style: const TextStyle(
                          fontSize: 11,
                          color: studioMuted,
                        ),
                      ),
                    if (data['dueDate'] != null)
                      Text(
                        'Due ${studioDate(data['dueDate'])}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: studioMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StudioLearnerCard extends StatelessWidget {
  const StudioLearnerCard(this.data, {super.key, this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final name = learnerName(data);
    final progress = data['progressPercentage'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: studioLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE9F0E6),
                      foregroundColor: studioInk,
                      child: Text(
                        name.isEmpty ? 'L' : name.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: studioInk,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: studioMuted,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (data['status'] != null)
                      StudioStatus('${data['status']}'),
                    if (data['percentage'] != null)
                      Text(
                        '${data['percentage']}% · ${data['passed'] == true ? 'Passed' : 'Not passed'}',
                        style: const TextStyle(
                          color: studioInk,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    if (data['marksAwarded'] != null)
                      Text(
                        '${data['marksAwarded']} marks',
                        style: const TextStyle(
                          color: studioInk,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    if (data['attemptNumber'] != null)
                      Text(
                        'Attempt ${data['attemptNumber']}',
                        style: const TextStyle(
                          color: studioMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                if (progress is num && progress >= 0 && progress <= 100) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress / 100,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 5,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$progress% complete',
                    style: const TextStyle(fontSize: 11, color: studioMuted),
                  ),
                ],
                if (data['submittedAt'] != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Submitted ${studioDate(data['submittedAt'])}',
                    style: const TextStyle(fontSize: 11, color: studioMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StudioQuestionCard extends StatelessWidget {
  const StudioQuestionCard(this.data, {super.key, this.onEdit});
  final Map<String, dynamic> data;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${instructorLabel(data['questionType'])} · ${data['marks'] ?? 0} marks',
                    style: const TextStyle(color: studioMuted, fontSize: 11),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit question',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
              ],
            ),
            Text(
              '${data['questionText'] ?? ''}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: studioInk,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            for (final option in records(data['options']))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      (data['correctOptionIds'] as List? ?? []).contains(
                            option['id'],
                          )
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 17,
                      color:
                          (data['correctOptionIds'] as List? ?? []).contains(
                            option['id'],
                          )
                          ? const Color(0xFF287453)
                          : studioMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${option['text']}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class StudioEmpty extends StatelessWidget {
  const StudioEmpty({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_stories_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    alignment: Alignment.center,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFE9F0E6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: studioInk),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: studioInk,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: studioMuted),
        ),
      ],
    ),
  );
}
