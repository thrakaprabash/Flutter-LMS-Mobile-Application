import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/models/learning_page.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../profile/screens/profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic> summary = {};
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.authenticated || auth.role != 'ADMIN') return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await auth.service.request(
        'GET',
        '/api/v1/dashboard/admin',
      );
      final data = object(response['data']);
      final dashboard = object(data['dashboard'] ?? data);
      if (mounted) {
        setState(
          () => summary = object(
            dashboard['summary'] ?? dashboard['stats'] ?? dashboard,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = AuthProvider.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated || auth.role != 'ADMIN') {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    final totals = summary.entries
        .where((entry) => entry.value is num)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'My profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ChangeNotifierProvider<AuthProvider>.value(
                  value: auth,
                  child: const Scaffold(body: SafeArea(child: ProfileScreen())),
                ),
              ),
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: totals.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  if (busy) const LinearProgressIndicator(),
                  if (error != null) ...[
                    Text(error!),
                    TextButton(onPressed: load, child: const Text('Retry')),
                  ],
                  if (!busy && error == null && totals.isEmpty)
                    const Text('No dashboard totals available.'),
                ],
              );
            }
            final entry = totals[index - 1];
            final label = entry.key
                .replaceAllMapped(
                  RegExp(r'([a-z])([A-Z])'),
                  (match) => '${match[1]} ${match[2]}',
                )
                .replaceAll('_', ' ');
            return Card(
              margin: const EdgeInsets.only(top: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                title: Text(label),
                trailing: Text(
                  '${entry.value}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
