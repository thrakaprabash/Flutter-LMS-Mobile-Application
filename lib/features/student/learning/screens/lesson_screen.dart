import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/utils/learning_error.dart';
import '../services/learning_service.dart';
import '../learning_scope.dart';
import '../widgets/lesson_video_player.dart';
import '../../widgets/student_ui.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.lessonId,
    required this.enrolled,
    this.initialStatus,
  });
  final String? initialStatus;
  final String lessonId;
  final bool enrolled;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Map<String, dynamic>? lesson;
  VideoPlayerController? video;
  bool busy = false, started = false, completed = false;
  String? error, mediaError;
  @override
  void initState() {
    super.initState();
    completed = widget.initialStatus == 'COMPLETED';
    load();
  }

  @override
  void dispose() {
    video?.dispose();
    super.dispose();
  }

  String? mediaUrl(Map<String, dynamic> l) =>
      (l['lessonType'] == 'VIDEO'
              ? l['videoUrl'] ?? object(l['video'])['url']
              : l['documentUrl'] ?? object(l['document'])['url'])
          ?.toString();
  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final s = context.read<LearningService>();
      final l = await s.lesson(widget.lessonId);
      if (widget.enrolled && !started && !completed) {
        await s.start(widget.lessonId);
        started = true;
      }
      if (!mounted) return;
      setState(() => lesson = l);
      final url = mediaUrl(l);
      if (l['lessonType'] == 'VIDEO' && url != null && video == null) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        video = controller;
        controller.addListener(() {
          if (mounted && controller.value.hasError && mediaError == null) {
            setState(
              () => mediaError =
                  'Video playback interrupted. Please retry the video.',
            );
          }
        });
        try {
          await controller.initialize();
        } catch (_) {
          mediaError =
              'Unable to play this video. Check your connection and retry.';
        }
      }
    } catch (e) {
      error = learningError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> complete() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<LearningService>().complete(widget.lessonId);
      if (mounted) {
        setState(() => completed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lesson completed. Return to the course to see updated progress.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!['http', 'https'].contains(uri.scheme) ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const FormatException();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => mediaError = 'Unable to open this document. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    final demo = context.watch<AuthProvider>().isDemo;
    return Scaffold(
      appBar: AppBar(title: Text('${l?['title'] ?? 'Lesson'}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: busy ? null : load,
              child: const Text('Retry'),
            ),
          ],
          if (l != null) ...[
            if (demo && l['lessonType'] != 'TEXT')
              const Text(
                'Demo media  -  Public sample  -  Internet connection required',
              ),
            Text(
              '${l['lessonType']} LESSON',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            StudentHeading(
              '${l['title'] ?? 'Your lesson'}',
              subtitle: '${l['description'] ?? ''}',
            ),
            if (l['lessonType'] == 'TEXT')
              StudentPanel(
                child: SelectableText(
                  '${l['textContent'] ?? 'No text available.'}',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: Color(0xFF304B40),
                  ),
                ),
              ),
            if (l['lessonType'] == 'VIDEO' &&
                video?.value.isInitialized == true) ...[
              LessonVideoPlayer(
                controller: video!,
                title: '${l['title'] ?? 'Lesson video'}',
                routeScope: (child) => learningScope(context, child),
              ),
            ],
            if (mediaError != null) ...[
              Text(mediaError!),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final old = video;
                        video = null;
                        mediaError = null;
                        await old?.dispose();
                        if (mounted) load();
                      },
                child: const Text('Retry media'),
              ),
            ],
            if (l['lessonType'] != 'TEXT' && mediaUrl(l) == null)
              Text(
                demo
                    ? 'Demo media lesson. Sign in to access uploaded course videos and documents.'
                    : 'The lesson media is unavailable.',
              ),
            if (l['lessonType'] == 'DOCUMENT' && mediaUrl(l) != null)
              FilledButton.icon(
                onPressed: () => openDocument(mediaUrl(l)!),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open document'),
              ),
            const SizedBox(height: 24),
            if (widget.enrolled)
              FilledButton(
                onPressed: busy || completed ? null : complete,
                child: Text(completed ? 'Lesson completed' : 'Mark complete'),
              )
            else
              const Text('Preview lesson. Enroll to record your progress.'),
          ],
        ],
      ),
    );
  }
}
