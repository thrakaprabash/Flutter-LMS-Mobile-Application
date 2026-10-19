import 'package:flutter/material.dart';

import '../learning/learning_screens.dart';
import '../learning/learning_service.dart';
import 'activity_widgets.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  int? count;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    try {
      final data = await activityService(context)
          .get('/api/v1/notifications/me/unread-count');
      if (mounted) {
        setState(() => count = (data['unreadCount'] as num?)?.toInt());
      }
    } catch (_) {
      if (mounted) setState(() => count = null);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: count == null
        ? 'Notifications · unread count unavailable'
        : '$count unread notifications',
    icon: Badge(
      isLabelVisible: count != null && count! > 0,
      label: Text('${count ?? ''}'),
      child: const Icon(Icons.notifications_outlined),
    ),
    onPressed: () async {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => learningScope(context, const NotificationsScreen()),
        ),
      );
      if (mounted) refresh();
    },
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> items = [];
  int? count;
  bool busy = false, unreadOnly = false, more = false;
  int page = 0;
  String? error;
  @override
  void initState() {
    super.initState();
    run(() => load());
  }

  Future<void> load({bool next = false}) async {
    final s = activityService(context);
    final p = next ? page + 1 : 1;
    final batch = await s.list(
      '/api/v1/notifications/me?unreadOnly=$unreadOnly',
      'notifications',
      p,
    );
    if (!next) items = [];
    items.addAll(batch.items);
    page = p;
    more = batch.hasNext;
    count = null;
    final data = await s.get('/api/v1/notifications/me/unread-count');
    count = (data['unreadCount'] as num?)?.toInt();
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

  Future<void> change(String method, String path) => run(() async {
    await activityService(context).mutate(method, path);
    await load();
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        IconButton(
          onPressed: busy ? null : () => run(() => load()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (busy) const LinearProgressIndicator(),
        Text(count == null ? 'Unread count unavailable' : '$count unread'),
        SwitchListTile(
          title: const Text('Unread only'),
          value: unreadOnly,
          onChanged: busy
              ? null
              : (v) {
                  setState(() => unreadOnly = v);
                  run(() => load());
                },
        ),
        TextButton(
          onPressed: busy
              ? null
              : () => change('PATCH', '/api/v1/notifications/me/read-all'),
          child: const Text('Mark all as read'),
        ),
        if (error != null) ...[
          Text(error!),
          TextButton(
            onPressed: busy ? null : () => run(() => load()),
            child: const Text('Retry'),
          ),
        ],
        if (!busy && error == null && items.isEmpty)
          const Text('You’re all caught up.'),
        for (final n in items)
          Card(
            child: ListTile(
              leading: Icon(
                n['isRead'] == true
                    ? Icons.drafts_outlined
                    : Icons.mark_email_unread_outlined,
              ),
              title: Text('${n['title'] ?? 'Notification'}'),
              subtitle: Text('${n['message'] ?? ''}'),
              onTap: busy || n['isRead'] == true
                  ? null
                  : () => change(
                      'PATCH',
                      '/api/v1/notifications/${recordId(n)}/read',
                    ),
              trailing: IconButton(
                tooltip: 'Delete notification',
                icon: const Icon(Icons.delete_outline),
                onPressed: busy
                    ? null
                    : () async {
                        if (await confirmActivity(
                              context,
                              'Delete notification?',
                              'This notification will be removed.',
                            ) &&
                            mounted) {
                          await change(
                            'DELETE',
                            '/api/v1/notifications/${recordId(n)}',
                          );
                        }
                      },
              ),
            ),
          ),
        if (more)
          TextButton(
            onPressed: busy ? null : () => run(() => load(next: true)),
            child: const Text('Load more'),
          ),
      ],
    ),
  );
}
