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
        var dontAskAgain = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: colorScheme.surface,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 64,
                        height: 64,
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
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    if (allowDontAskAgain && dontAskAgainKey != null) ...[
                      const SizedBox(height: 20),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() => dontAskAgain = !dontAskAgain);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: dontAskAgain,
                                    onChanged: (value) {
                                      setState(
                                        () => dontAskAgain = value ?? false,
                                      );
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    effectiveDontAskAgainLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                              foregroundColor: colorScheme.onSurface,
                            ),
                            child: Text(
                              effectiveCancelLabel,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (allowDontAskAgain &&
                                  dontAskAgainKey != null &&
                                  dontAskAgain) {
                                try {
                                  await AppPreferences.setBool(
                                    dontAskAgainKey,
                                    true,
                                  );
                                } catch (_) {
                                  // Ignore preference write failure.
                                }
                              }
                              if (context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: isDestructive
                                  ? colorScheme.error
                                  : colorScheme.primary,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              effectiveConfirmLabel,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
