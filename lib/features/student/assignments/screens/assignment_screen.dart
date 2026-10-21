import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../widgets/student_ui.dart';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../learning/services/learning_service.dart';
import '../../../../shared/utils/learning_error.dart';
import '../../widgets/activity_widgets.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key, required this.id});
  final String id;
  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final text = TextEditingController();
  Map<String, dynamic> assignment = {}, submission = {};
  PlatformFile? file;
  bool busy = false, loaded = false;
  String? error, message;
  bool get graded => submission['status'] == 'GRADED';
  @override
  void initState() {
    super.initState();
    run(load);
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final s = activityService(context);
    assignment = await s.get(
      '/api/v1/assignments/${widget.id}',
      key: 'assignment',
    );
    try {
      submission = await s.get(
        '/api/v1/assignments/${widget.id}/submission/me',
        key: 'submission',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      submission = {};
    }
    text.text = '${submission['textAnswer'] ?? ''}';
    loaded = true;
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> choose() => run(() async {
    final selected = await FilePicker.pickFile();
    if (selected != null) file = selected;
  });
  Future<void> send() async {
    if (graded || !loaded || busy) return;
    if (text.text.trim().isEmpty && file == null) {
      setState(() => error = 'Add an answer or choose a file.');
      return;
    }
    if (!await confirmActivity(
      context,
      'Submit assignment?',
      'Send this answer and selected attachment to your instructor?',
    )) {
      return;
    }
    if (!mounted) return;
    await run(() async {
      final service = activityService(context);
      final f = file;
      final bytes = await f?.readAsBytes();
      if (f != null && bytes == null) {
        throw StateError('Could not read file. Select it again.');
      }
      final data = await service.submitAssignment(
        widget.id,
        text: text.text,
        file: f == null
            ? null
            : MultipartFile.fromBytes(
                bytes!,
                filename: f.name,
                contentType: MediaType.parse(
                  lookupMimeType(f.name, headerBytes: bytes) ??
                      'application/octet-stream',
                ),
              ),
      );
      submission = object(data['submission'] ?? data);
      file = null;
      message = 'Assignment submitted.';
      // A successful mutation remains visible even if a later refresh fails.
      if (mounted) await load();
    });
  }

  Future<void> openFile(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) setState(() => error = 'Unable to open attachment.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${assignment['title'] ?? 'Assignment'}')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (busy) const LinearProgressIndicator(),
        if (error != null) ...[
          Text(error!),
          TextButton(
            onPressed: busy ? null : () => run(load),
            child: const Text('Retry loading'),
          ),
        ],
        if (message != null) Text(message!),
        StudentHeading(
          'Put your skills into practice',
          subtitle: '${assignment['description'] ?? ''}',
        ),
        StudentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: studentInk,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                'Due: ${assignment['dueDate'] == null ? '—' : DateTime.tryParse('${assignment['dueDate']}')?.toLocal().toString().replaceFirst(RegExp(r':\d{2}\.\d+$'), '') ?? assignment['dueDate']}',
              ),
              const SizedBox(height: 8),
              Text(
                'Maximum marks: ${assignment['maximumMarks'] ?? assignment['maxMarks'] ?? '—'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: studentInk,
                ),
              ),
              if ('${assignment['instructions'] ?? ''}'.trim().isNotEmpty) ...[
                const Divider(height: 28),
                const Text(
                  'Your brief',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: studentInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${assignment['instructions']}'),
              ],
            ],
          ),
        ),
        if (assignment['attachmentUrl'] is String)
          TextButton(
            onPressed: () => openFile(assignment['attachmentUrl']),
            child: const Text('Open assignment attachment'),
          ),
        const SizedBox(height: 16),
        if (loaded) ActivityStatus('${submission['status'] ?? 'PENDING'}'),
        if (submission['feedback'] != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Instructor feedback: ${submission['feedback']}'),
            ),
          ),
        if (submission['marks'] != null || submission['marksAwarded'] != null)
          Text('Marks: ${submission['marksAwarded'] ?? submission['marks']}'),
        if (submission['fileUrl'] is String)
          TextButton(
            onPressed: () => openFile(submission['fileUrl']),
            child: const Text('Open submitted file'),
          ),
        if (graded)
          const Text('This submission has been graded. Editing is closed.'),
        const SizedBox(height: 16),
        const StudentHeading(
          'Your submission',
          subtitle:
              'Check the brief, add your work, and submit when you are ready.',
        ),
        TextField(
          controller: text,
          enabled: loaded && !graded && !busy,
          minLines: 4,
          maxLines: 12,
          decoration: const InputDecoration(labelText: 'Your answer'),
        ),
        if (file != null)
          ListTile(
            title: Text(file!.name),
            trailing: IconButton(
              onPressed: busy ? null : () => setState(() => file = null),
              icon: const Icon(Icons.close),
            ),
          ),
        OutlinedButton.icon(
          onPressed: !loaded || graded || busy ? null : choose,
          icon: const Icon(Icons.attach_file),
          label: const Text('Choose file'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: !loaded || graded || busy ? null : send,
          child: Text(
            submission['status'] == 'RESUBMISSION_REQUIRED'
                ? 'Submit correction'
                : 'Submit assignment',
          ),
        ),
      ],
    ),
  );
}
