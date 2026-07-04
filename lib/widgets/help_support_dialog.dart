import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a simple Help & Support dialog.
/// Pass [isLecturer] = true for the lecturer profile, false for student.
Future<void> showHelpSupportDialog(
  BuildContext context, {
  required bool isLecturer,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final String supportEmail = 'salman@university.edu';
  final String supportPhone =
      isLecturer ? '+60 3-1234 5678' : '+60 3-1234 5679';
  final String officeHours = isLecturer
      ? 'Mon–Fri, 9:00 AM – 5:00 PM (Staff Help Desk)'
      : 'Mon–Fri, 8:30 AM – 4:30 PM (Student Help Desk)';
  final String description = isLecturer
      ? 'Need help with class sessions, attendance records, or your lecturer account? Reach out to the staff support team below.'
      : 'Having trouble marking attendance, viewing your sessions, or your account? Reach out to the student support team below.';

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  fontSize: 13.5,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _ContactRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: supportEmail,
                onCopy: () => _copyToClipboard(context, supportEmail, 'Email'),
              ),
              const SizedBox(height: 14),
              _ContactRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: supportPhone,
                onCopy: () =>
                    _copyToClipboard(context, supportPhone, 'Phone number'),
              ),
              const SizedBox(height: 14),
              _ContactRow(
                icon: Icons.schedule_outlined,
                label: 'Office Hours',
                value: officeHours,
                onCopy: null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

void _copyToClipboard(BuildContext context, String value, String label) {
  Clipboard.setData(ClipboardData(text: value));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label copied to clipboard'),
      duration: const Duration(seconds: 2),
    ),
  );
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: onCopy,
            tooltip: 'Copy',
            visualDensity: VisualDensity.compact,
            color: colorScheme.primary,
          ),
      ],
    );
  }
}
