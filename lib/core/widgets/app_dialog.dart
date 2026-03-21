import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../../data/local/preferences/app_preferences.dart';

class AppDialog {
  const AppDialog._();

  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
    IconData? icon,
    bool allowDontAskAgain = false,
    String? dontAskAgainKey,
    String? dontAskAgainLabel,
  }) async {
    final effectiveConfirmLabel = confirmLabel ?? AppStrings.delete;
    final effectiveCancelLabel = cancelLabel ?? AppStrings.cancel;
    final effectiveDontAskAgainLabel =
        dontAskAgainLabel ??
        AppStrings.tr('Don\'t ask again', 'Jangan tanya lagi');

    if (allowDontAskAgain && dontAskAgainKey != null) {
      try {
        final skipped = AppPreferences.getBool(dontAskAgainKey);
        if (skipped) {
          return true;
        }
      } catch (_) {
        // Ignore preference access issues and continue showing dialog.
      }
    }

    return showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final dialogContentWidth = (screenWidth - 64).clamp(260.0, 420.0);
        final actionButtonWidth = ((dialogContentWidth - 12) / 2).clamp(
          108.0,
          180.0,
        );
        var dontAskAgain = false;

        return StatefulBuilder(
          builder: (context, setState) {
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  if (allowDontAskAgain && dontAskAgainKey != null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() => dontAskAgain = !dontAskAgain);
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: dontAskAgain,
                            onChanged: (value) {
                              setState(() => dontAskAgain = value ?? false);
                            },
                          ),
                          Expanded(
                            child: Text(
                              effectiveDontAskAgainLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsOverflowAlignment: OverflowBarAlignment.center,
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowButtonSpacing: 8,
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                SizedBox(
                  width: actionButtonWidth,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      effectiveCancelLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: actionButtonWidth,
                  child: FilledButton(
                    onPressed: () async {
                      if (allowDontAskAgain &&
                          dontAskAgainKey != null &&
                          dontAskAgain) {
                        try {
                          await AppPreferences.setBool(dontAskAgainKey, true);
                        } catch (_) {
                          // Ignore preference write failure.
                        }
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: isDestructive
                        ? FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            minimumSize: const Size(0, 48),
                          )
                        : FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                    child: Text(
                      effectiveConfirmLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> clearDontAskAgain(String key) async {
    try {
      await AppPreferences.setBool(key, false);
    } catch (_) {
      // Ignore preference write failure.
    }
  }
}
