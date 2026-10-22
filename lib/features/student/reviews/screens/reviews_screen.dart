import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/utils/learning_error.dart';
import '../../learning/services/learning_service.dart';
import '../../widgets/activity_widgets.dart';

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
  Future<void> deleteReview() async {
    if (busy || mine == null) return;
    final id = recordId(mine!);
    if (!await confirmActivity(
      context,
      'Delete your review?',
      'Permanently delete your rating and comment? Course ratings will be recalculated.',
    )) {
      return;
    }
    if (!mounted) return;
    await run(() async {
      await activityService(context).mutate('DELETE', '/api/v1/reviews/$id');
      mine = null;
      comment.clear();
      rating = 5;
      message = 'Review deleted.';
      await load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const descriptions = ['Poor', 'Fair', 'Good', 'Very good', 'Excellent'];
    return Scaffold(
      appBar: AppBar(title: const Text('Course reviews')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: busy ? null : () => run(load),
              child: const Text('Retry'),
            ),
          ],
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message!)),
                ],
              ),
            ),
          if (widget.eligible)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.rate_review_outlined,
                          color: colors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mine == null ? 'Write a review' : 'Edit your review',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'How was your learning experience? Your feedback helps other learners.',
                    ),
                    const SizedBox(height: 24),
                    Text('Your rating', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    StarRating(
                      rating: rating,
                      onChanged: busy
                          ? null
                          : (value) => setState(() => rating = value),
                      interactive: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${descriptions[rating.clamp(1, 5) - 1]} · $rating out of 5',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: comment,
                      enabled: !busy,
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Your review',
                        alignLabelWithHint: true,
                        hintText: 'What worked well? What could be better?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: busy || error != null ? null : save,
                      icon: Icon(
                        mine == null ? Icons.send_rounded : Icons.check_rounded,
                        size: 18,
                      ),
                      label: Text(
                        mine == null ? 'Submit review' : 'Update review',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, color: colors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Enroll in this course to share your experience.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (mine != null)
            TextButton.icon(
              onPressed: busy ? null : deleteReview,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete my review'),
            ),
          const SizedBox(height: 28),
          Text('Learner reviews', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${reviews.length} visible ${reviews.length == 1 ? 'review' : 'reviews'}',
          ),
          const SizedBox(height: 16),
          if (!busy && error == null && reviews.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 36,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Be the first to share',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No visible reviews yet.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          for (final review in reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReviewCard(
                review: review,
                isMine: mine != null && recordId(review) == recordId(mine!),
              ),
            ),
        ],
      ),
    );
  }
}

/// Uses native icons so stars stay sharp at every screen size.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.interactive = false,
    this.onChanged,
  });
  final int rating;
  final bool interactive;
  final ValueChanged<int>? onChanged;
  static const gold = Color(0xFFBC7900);
  @override
  Widget build(BuildContext context) {
    if (!interactive) {
      return Semantics(
        label: '$rating out of 5 stars',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i <= rating
                      ? gold
                      : Theme.of(context).colorScheme.outlineVariant,
                  size: 20,
                ),
            ],
          ),
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            selected: i == rating,
            child: IconButton(
              tooltip: 'Rate $i ${i == 1 ? 'star' : 'stars'}',
              onPressed: onChanged == null ? null : () => onChanged!(i),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.all(5),
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  key: ValueKey('$i/${i <= rating}'),
                  color: i <= rating
                      ? gold
                      : Theme.of(context).colorScheme.outline,
                  size: 36,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, required this.isMine});
  final Map<String, dynamic> review;
  final bool isMine;
  @override
  Widget build(BuildContext context) {
    final owner = object(
      review['studentId'] ?? review['userId'] ?? review['student'],
    );
    final name = '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'
        .trim();
    final label = isMine
        ? 'Your review'
        : name.isEmpty
        ? 'Learner'
        : name;
    final value = (review['rating'] as num?)?.toInt() ?? 0;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: isMine || name.isEmpty
                      ? const Icon(Icons.person_outline)
                      : Text(name.characters.first.toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      StarRating(rating: value),
                    ],
                  ),
                ),
              ],
            ),
            if ('${review['comment'] ?? ''}'.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${review['comment']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
