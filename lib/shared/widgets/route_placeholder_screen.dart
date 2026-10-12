import 'package:flutter/material.dart';

import 'app_widgets.dart';

class RoutePlaceholderScreen extends StatelessWidget {
  const RoutePlaceholderScreen({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: title, subtitle: 'Route preview'),
              const SizedBox(height: 20),
              const AppMessage(
                message: 'This screen is a placeholder. Its features will be added in a later task.',
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Back to Home',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
