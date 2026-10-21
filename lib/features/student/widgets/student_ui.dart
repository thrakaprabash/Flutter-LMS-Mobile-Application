import 'package:flutter/material.dart';

const studentInk = Color(0xFF173F35);
const studentMuted = Color(0xFF74857D);

class StudentHeading extends StatelessWidget {
  const StudentHeading(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: studentInk,
            letterSpacing: -.6,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(color: studentMuted, height: 1.5),
          ),
        ],
      ],
    ),
  );
}

class StudentPanel extends StatelessWidget {
  const StudentPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE0E7DF)),
    ),
    child: child,
  );
}

class StudentEmpty extends StatelessWidget {
  const StudentEmpty({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_stories_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => StudentPanel(
    child: Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFE8EFDF),
          child: Icon(icon, color: studentInk, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: studentInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class StudentHero extends StatelessWidget {
  const StudentHero({super.key, required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: [Color(0xFF123F33), Color(0xFF2E7055)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.school_outlined, size: 32, color: Color(0xFFDCEBC5)),
        const SizedBox(height: 18),
        const Text(
          'Small steps.\nReal progress.',
          style: TextStyle(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Make room for something new. Your next skill starts with one lesson.',
          style: TextStyle(color: Color(0xFFD3E5DA), height: 1.6),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onExplore,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE1EDCE),
            foregroundColor: studentInk,
          ),
          icon: const Icon(Icons.explore_outlined),
          label: const Text(
            'Explore courses',
            style: TextStyle(fontFamily: 'LmsRoboto'),
          ),
        ),
      ],
    ),
  );
}
