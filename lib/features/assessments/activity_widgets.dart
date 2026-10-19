import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../shared/providers/auth_provider.dart';
import '../learning/learning_screens.dart';
import '../learning/learning_service.dart';
import 'student_activity_service.dart';

StudentActivityService activityService(BuildContext context) =>
    StudentActivityService(context.read<AuthProvider>().service);

Future<bool> confirmActivity(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ==
    true;

class ActivityStatus extends StatelessWidget {
  const ActivityStatus(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      status
          .toLowerCase()
          .split('_')
          .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
          .join(' '),
    ),
  );
}

class ActivityList extends StatefulWidget {
  const ActivityList({
    super.key,
    required this.title,
    required this.path,
    required this.listKey,
    required this.onOpen,
  });
  final String title, path, listKey;
  final Future<dynamic> Function(BuildContext, Map<String, dynamic>) onOpen;
  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  final items = <Map<String, dynamic>>[];
  bool busy = false, more = false;
  int page = 0;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool next = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final p = next ? page + 1 : 1;
      final service = activityService(context);
      final result = await service.list(widget.path, widget.listKey, p);
      if (widget.listKey == 'assignments') {
        await Future.wait(
          result.items.map((item) async {
            try {
              final submission = await service.get(
                '/api/v1/assignments/${recordId(item)}/submission/me',
                key: 'submission',
              );
              item['submissionStatus'] = submission['status'] ?? 'PENDING';
            } on DioException catch (e) {
              item['submissionStatus'] = e.response?.statusCode == 404
                  ? 'PENDING'
                  : 'STATUS_UNAVAILABLE';
            } catch (_) {
              item['submissionStatus'] = 'STATUS_UNAVAILABLE';
            }
          }),
        );
      }
      if (mounted) {
        setState(() {
          if (!next) items.clear();
          items.addAll(result.items);
          page = p;
          more = result.hasNext;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          onPressed: busy ? null : () => load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (busy) const LinearProgressIndicator(),
        if (error != null) ...[
          Text(error!),
          TextButton(onPressed: () => load(), child: const Text('Retry')),
        ],
        if (!busy && error == null && items.isEmpty)
          const Text('Nothing here yet.'),
        for (final item in items)
          Card(
            child: ListTile(
              title: Text(
                '${item['title'] ?? item['questionText'] ?? 'Assessment'}',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item['description'] ?? ''}'),
                  if (item['submissionStatus'] != null)
                    ActivityStatus('${item['submissionStatus']}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: busy
                  ? null
                  : () async {
                      await widget.onOpen(context, item);
                      if (mounted) await load();
                    },
            ),
          ),
        if (more)
          TextButton(
            onPressed: busy ? null : () => load(next: true),
            child: const Text('Load more'),
          ),
      ],
    ),
  );
}
