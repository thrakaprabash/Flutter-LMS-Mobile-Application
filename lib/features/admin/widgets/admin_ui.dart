import 'package:flutter/material.dart';

const adminInk = Color(0xFF173E32);
const adminMuted = Color(0xFF718078);
const adminLine = Color(0xFFE4EAE3);
const adminCanvas = Color(0xFFF6F7F2);

String adminLabel(Object? value) => (value ?? '')
    .toString()
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
    .replaceAll('_', ' ')
    .split(' ')
    .where((s) => s.isNotEmpty)
    .map((s) => '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}')
    .join(' ');

IconData adminIcon(String feature) => switch (feature) {
  'users' => Icons.people_outline_rounded,
  'categories' => Icons.grid_view_rounded,
  'courses' => Icons.auto_stories_outlined,
  'enrollments' => Icons.school_outlined,
  'reviews' => Icons.rate_review_outlined,
  _ => Icons.space_dashboard_outlined,
};

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: adminLine),
    ),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class AdminHeading extends StatelessWidget {
  const AdminHeading(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: adminInk,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: const TextStyle(
              color: adminMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ],
    ),
  );
}

class AdminBadge extends StatelessWidget {
  const AdminBadge(this.value, {super.key});
  final String value;
  @override
  Widget build(BuildContext context) {
    final color = switch (value) {
      'ACTIVE' ||
      'PUBLISHED' ||
      'COMPLETED' ||
      'VISIBLE' => const Color(0xFF227250),
      'SUSPENDED' || 'HIDDEN' => const Color(0xFFAF5746),
      'DRAFT' => const Color(0xFF9A671F),
      _ => adminMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        adminLabel(value),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AdminShortcut extends StatelessWidget {
  const AdminShortcut({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = adminInk,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: adminLine),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: adminInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: adminMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: adminMuted, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

class AdminNotice extends StatelessWidget {
  const AdminNotice(this.message, {super.key, this.error = false, this.action});
  final String message;
  final bool error;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFFF2EC) : const Color(0xFFEDF1E7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              size: 18,
              color: error ? const Color(0xFFAF5746) : adminInk,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: adminInk,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
        ?action,
      ],
    ),
  );
}

class AdminField extends StatelessWidget {
  const AdminField(this.label, this.value, {super.key});
  final String label;
  final Object? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: adminMuted, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(color: adminInk, fontSize: 14, height: 1.6),
        ),
      ],
    ),
  );
}
