import 'package:flutter/material.dart';

/// Warning banner for missing permissions or system issues.
/// Displayed at the top of HomeScreen per spec §6.4.
class WarningBanner extends StatelessWidget {
  const WarningBanner({
    super.key,
    required this.message,
    required this.onAction,
    this.actionLabel = 'Perbaiki',
    this.icon = Icons.warning_amber_rounded,
  });

  final String message;
  final VoidCallback onAction;
  final String actionLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 300;
          final action = TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              actionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );

          final leading = Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.onErrorContainer, size: 18),
          );

          final body = Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 10),
                    Expanded(child: body),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(child: body),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: action,
              ),
            ],
          );
        },
      ),
    );
  }
}
