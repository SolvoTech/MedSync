import 'package:flutter/material.dart';

class AppDialog {
  const AppDialog._();

  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Hapus',
    String cancelLabel = 'Batal',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          // Icon header for visual emphasis
          icon: icon != null
              ? Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? colorScheme.error
                        : colorScheme.primary,
                    size: 28,
                  ),
                )
              : null,
          title: Text(title, textAlign: TextAlign.center),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: isDestructive
                    ? FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      )
                    : null,
                child: Text(confirmLabel),
              ),
            ),
          ],
        );
      },
    );
  }
}
