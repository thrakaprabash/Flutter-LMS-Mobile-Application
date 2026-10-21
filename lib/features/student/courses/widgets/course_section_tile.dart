import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/learning_error.dart';
import '../../learning/services/learning_service.dart';
import '../../learning/widgets/learning_widgets.dart';

class CourseSectionTile extends StatefulWidget {
  const CourseSectionTile({
    super.key,
    required this.section,
    required this.onLesson,
    required this.statuses,
    required this.enrolled,
  });
  final Map<String, String> statuses;
  final bool enrolled;
  final Map<String, dynamic> section;
  final void Function(String) onLesson;
  @override
  State<CourseSectionTile> createState() => _CourseSectionTileState();
}

class _CourseSectionTileState extends State<CourseSectionTile> {
  Future<List<Map<String, dynamic>>>? future;
  void loadLessons() {
    final request = context.read<LearningService>().lessons(
      recordId(widget.section),
    );
    setState(() {
      future = request;
    });
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    childrenPadding: const EdgeInsets.only(bottom: 12),
    shape: const Border(),
    collapsedShape: const Border(),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: .5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.folder_open_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    title: Text('${widget.section['title']}'),
    subtitle: Text(
      '${widget.section['lessonCount'] ?? widget.section['totalLessons'] ?? ''} lessons',
    ),
    onExpansionChanged: (open) {
      if (open && future == null) {
        loadLessons();
      }
    },
    children: [
      if (future != null)
        FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(learningError(snapshot.error!)),
                  TextButton(
                    onPressed: loadLessons,
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data!.isEmpty) {
              return const ListTile(title: Text('No available lessons.'));
            }
            return Column(
              children: [
                for (final lesson in snapshot.data!)
                  ListTile(
                    leading: Icon(lessonIcon('${lesson['lessonType']}')),
                    title: Text('${lesson['title']}'),
                    subtitle: Text(
                      '${lesson['lessonType']} · ${!widget.enrolled ? (lesson['isPreview'] == true ? 'Preview' : 'Enrollment required') : friendlyStatus(widget.statuses[recordId(lesson)] ?? 'Progress unavailable')}',
                    ),
                    trailing: Icon(
                      widget.statuses[recordId(lesson)] == 'COMPLETED'
                          ? Icons.check_circle
                          : !widget.enrolled && lesson['isPreview'] != true
                          ? Icons.lock_outline
                          : Icons.chevron_right,
                    ),
                    onTap: !widget.enrolled && lesson['isPreview'] != true
                        ? null
                        : () => widget.onLesson(recordId(lesson)),
                  ),
              ],
            );
          },
        ),
    ],
  );
}
