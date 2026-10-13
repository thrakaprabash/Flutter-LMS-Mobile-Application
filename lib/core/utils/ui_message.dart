import 'package:flutter/material.dart';

class AppMessage extends StatelessWidget {
  const AppMessage({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
