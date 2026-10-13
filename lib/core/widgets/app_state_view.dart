import 'package:flutter/material.dart';

enum UiStatus { loading, empty, error, success }

/// Shared feedback for future asynchronous features. Retry belongs to the caller.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.status,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));
  final UiStatus status;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == UiStatus.loading)
            const CircularProgressIndicator()
          else
            Icon(
              switch (status) {
                UiStatus.empty => Icons.inbox_outlined,
                UiStatus.error => Icons.error_outline,
                _ => Icons.check_circle_outline,
              },
              size: 48,
              color: status == UiStatus.error
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, textAlign: TextAlign.center),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
