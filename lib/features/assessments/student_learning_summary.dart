import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../learning/learning_service.dart';
import '../learning/learning_screens.dart';

class StudentLearningSummary extends StatefulWidget {
  const StudentLearningSummary({super.key});
  @override
  State<StudentLearningSummary> createState() => _StudentLearningSummaryState();
}

class _StudentLearningSummaryState extends State<StudentLearningSummary> {
  List<Map<String, dynamic>> completed = [];
  int active = 0;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (busy) return;
    final service = context.read<LearningService?>();
    if (service == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final courses = <Map<String, dynamic>>[];
      var activeCount = 0;
      for (final status in ['ACTIVE', 'COMPLETED']) {
        var page = 1;
        while (true) {
          final result = await service.enrollments(page++, status);
          if (status == 'COMPLETED') {
            courses.addAll(result.items);
          } else {
            activeCount += result.items.length;
          }
          if (!result.hasNext) break;
        }
      }
      if (mounted) {
        setState(() {
          active = activeCount;
          completed = courses;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My learning', style: Theme.of(context).textTheme.titleLarge),
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: busy ? null : load,
              child: const Text('Retry learning summary'),
            ),
          ] else if (!busy) ...[
            Text('$active in progress · ${completed.length} completed'),
            const SizedBox(height: 12),
            Text(
              'Completed courses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (completed.isEmpty)
              const Text('Your completed courses will appear here.'),
            for (final enrollment in completed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.verified_outlined),
                title: Text(
                  '${object(enrollment['courseId'] ?? enrollment['course'])['title'] ?? 'Completed course'}',
                ),
                subtitle: Text('Completed ${enrollment['completedAt'] ?? ''}'),
              ),
          ],
        ],
      ),
    ),
  );
}
