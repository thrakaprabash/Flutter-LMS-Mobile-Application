import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/providers/auth_provider.dart';
import '../learning/learning_screens.dart';
import '../learning/learning_service.dart';
import 'activity_widgets.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.courseId,
    required this.eligible,
  });
  final String courseId;
  final bool eligible;
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final comment = TextEditingController();
  List<Map<String, dynamic>> reviews = [];
  Map<String, dynamic>? mine;
  bool busy = false;
  String? error, message;
  int rating = 5;
  @override
  void initState() {
    super.initState();
    run(load);
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final s = activityService(context);
    final result = <Map<String, dynamic>>[];
    int page = 1;
    while (true) {
      final batch = await s.list(
        '/api/v1/courses/${widget.courseId}/reviews',
        'reviews',
        page++,
        public: true,
      );
      result.addAll(batch.items);
      if (!batch.hasNext) break;
    }
    if (!mounted) return;
    final uid = recordId(context.read<AuthProvider>().user ?? {});
    reviews = result;
    mine = null;
    for (final r in result) {
      final owner = r['studentId'] ?? r['userId'] ?? r['student'];
      if (uid.isNotEmpty &&
          (owner is Map ? recordId(object(owner)) : owner?.toString()) == uid) {
        mine = r;
      }
    }
    if (mine != null) {
      comment.text = '${mine!['comment'] ?? ''}';
      rating = (mine!['rating'] as num).toInt();
    }
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

  Future<void> save() => run(() async {
    final data = await activityService(context).mutate(
      mine == null ? 'POST' : 'PATCH',
      mine == null
          ? '/api/v1/courses/${widget.courseId}/reviews'
          : '/api/v1/reviews/${recordId(mine!)}',
      data: {'rating': rating, 'comment': comment.text.trim()},
    );
    mine = object(data['review'] ?? data);
    message = 'Review saved.';
    if (mounted) await load();
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course reviews')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (busy) const LinearProgressIndicator(),
        if (error != null) ...[
          Text(error!),
          TextButton(
            onPressed: busy ? null : () => run(load),
            child: const Text('Retry'),
          ),
        ],
        if (message != null) Text(message!),
        if (widget.eligible) ...[
          Text(
            mine == null ? 'Write a review' : 'Edit your review',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          DropdownButtonFormField<int>(
            initialValue: rating,
            key: ValueKey(rating),
            decoration: const InputDecoration(labelText: 'Rating'),
            items: [
              for (var i = 1; i <= 5; i++)
                DropdownMenuItem(value: i, child: Text('$i stars')),
            ],
            onChanged: busy ? null : (v) => setState(() => rating = v!),
          ),
          TextField(
            controller: comment,
            enabled: !busy,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Your review'),
          ),
          FilledButton(
            onPressed: busy || error != null ? null : save,
            child: Text(mine == null ? 'Submit review' : 'Update review'),
          ),
        ] else
          const Text('Enroll in this course to write a review.'),
        const SizedBox(height: 24),
        if (!busy && reviews.isEmpty) const Text('No visible reviews yet.'),
        for (final r in reviews)
          Card(
            child: ListTile(
              leading: const Icon(Icons.star),
              title: Text('${r['rating']} / 5'),
              subtitle: Text('${r['comment'] ?? ''}'),
            ),
          ),
      ],
    ),
  );
}
