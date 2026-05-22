import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_form_container.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_time_field.dart';

typedef ReminderSubmit =
    Future<void> Function({
      required String selectedType,
      String? customName,
      required String timeOfDay,
      required DateTime startDate,
    });

enum ReminderAction { edit, markDone, deactivate, delete }

ReminderAction? parseReminderAction(String value) {
  switch (value) {
    case 'edit':
      return ReminderAction.edit;
    case 'mark_done':
      return ReminderAction.markDone;
    case 'deactivate':
      return ReminderAction.deactivate;
    case 'delete':
      return ReminderAction.delete;
    default:
      return null;
  }
}

EdgeInsets scheduleTabListPadding(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  final width = MediaQuery.sizeOf(context).width;
  final compactHeight = height < 760;
  final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
  final bottomInset =
      bottomSafeArea + kBottomNavigationBarHeight + (compactHeight ? 40 : 50);
  final horizontal = width < 340 ? 10.0 : 16.0;

  return EdgeInsets.fromLTRB(horizontal, 16, horizontal, bottomInset);
}

EdgeInsets scheduleTabFabPadding(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  final compactHeight = height < 760;
  final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

  return EdgeInsets.only(bottom: bottomSafeArea + (compactHeight ? 8 : 12));
}

Future<void> handleReminderAction({
  required BuildContext context,
  required String action,
  required Future<void> Function() onEdit,
  Future<bool> Function()? onMarkDone,
  required Future<void> Function() onDeactivate,
  required Future<void> Function() onDelete,
  String? doneMessage,
  required String deactivatedMessage,
  required String deactivateDialogContent,
  String? deactivateDontAskAgainKey,
  required String deletedMessage,
  required String deleteDialogContent,
}) async {
  final parsed = parseReminderAction(action);
  if (parsed == null) {
    return;
  }

  try {
    if (parsed == ReminderAction.edit) {
      await onEdit();
      return;
    }

    if (parsed == ReminderAction.markDone) {
      if (onMarkDone == null) {
        return;
      }

      final completed = await onMarkDone();
      if (!completed) {
        return;
      }
      if (context.mounted) {
        context.showSuccessSnackBar(
          doneMessage ?? AppStrings.tr('Marked as done.', 'Ditandai selesai.'),
        );
      }
      return;
    }

    if (parsed == ReminderAction.deactivate) {
      final confirmed = await AppDialog.showConfirm(
        context,
        title: AppStrings.disableReminderTitle,
        message: deactivateDialogContent,
        confirmLabel: AppStrings.disableAction,
        icon: Icons.pause_circle_outline,
        allowDontAskAgain: deactivateDontAskAgainKey != null,
        dontAskAgainKey: deactivateDontAskAgainKey,
      );
      if (confirmed != true) {
        return;
      }

      await onDeactivate();
      if (context.mounted) {
        context.showInfoSnackBar(deactivatedMessage);
      }
      return;
    }

    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.deleteReminderTitle,
      message: deleteDialogContent,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (confirmed != true) {
      return;
    }

    await onDelete();
    if (context.mounted) {
      context.showSuccessSnackBar(deletedMessage);
    }
  } catch (error) {
    if (context.mounted) {
      context.showErrorSnackBar(
        toUserErrorMessage(error, fallback: AppStrings.actionFailed),
      );
    }
  }
}

class ReminderSectionHeader extends StatelessWidget {
  const ReminderSectionHeader({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class ReminderListTile extends StatelessWidget {
  const ReminderListTile({
    required this.icon,
    required this.title,
    required this.timeOfDay,
    required this.onTap,
    required this.onActionSelected,
    this.showMarkDoneAction = false,
    this.accentColor,
    super.key,
  });

  final IconData icon;
  final String title;
  final String timeOfDay;
  final VoidCallback onTap;
  final ValueChanged<String> onActionSelected;
  final bool showMarkDoneAction;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final tight = width < 360;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tone = accentColor ?? _toneFromIcon(icon);
    final radius = compact ? 18.0 : 20.0;

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: radius,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, color: tone),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 12,
                compact ? 10 : 11,
                compact ? 10 : 12,
                compact ? 10 : 11,
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? 36 : 40,
                    height: compact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(compact ? 10 : 12),
                    ),
                    child: Icon(icon, color: tone, size: compact ? 18 : 20),
                  ),
                  SizedBox(width: compact ? 9 : 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: tight ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: compact ? 3 : 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 8 : 9,
                            vertical: compact ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: compact ? 12 : 13,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.66,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${AppStrings.reminderHourPrefix} ${timeOfDay.substring(0, 5)}',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  PopupMenuButton<String>(
                    onSelected: onActionSelected,
                    icon: Container(
                      width: compact ? 31 : 34,
                      height: compact ? 31 : 34,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(compact ? 9 : 10),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                        size: compact ? 16 : 18,
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(AppStrings.reminderEdit),
                      ),
                      if (showMarkDoneAction)
                        PopupMenuItem(
                          value: 'mark_done',
                          child: Text(
                            AppStrings.tr('Mark as Done', 'Tandai Selesai'),
                          ),
                        ),
                      PopupMenuItem(
                        value: 'deactivate',
                        child: Text(AppStrings.reminderDeactivate),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppStrings.reminderDelete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _toneFromIcon(IconData value) {
    if (value == Icons.monitor_heart_rounded) {
      return const Color(0xFF2F855A);
    }
    if (value == Icons.directions_walk_rounded) {
      return const Color(0xFFED8936);
    }
    if (value == Icons.medication_rounded) {
      return const Color(0xFF0077B6);
    }
    return const Color(0xFF4299E1);
  }
}

Future<void> showReminderEditorSheet({
  required BuildContext context,
  required List<String> availableTypes,
  required String Function(String) typeLabelBuilder,
  required String typeFieldLabel,
  required String timeFieldLabel,
  required String initialType,
  required String? initialCustomName,
  required String initialTimeOfDay,
  required DateTime initialDate,
  required bool isEditing,
  required String createSuccessMessage,
  required String updateSuccessMessage,
  required ReminderSubmit onSubmit,
}) async {
  var selectedType = availableTypes.contains(initialType)
      ? initialType
      : availableTypes.first;
  final nameController = TextEditingController(text: initialCustomName ?? '');
  final formKey = GlobalKey<FormState>();
  var hasAttemptedSubmit = false;
  var isSubmitting = false;
  final parts = initialTimeOfDay.split(':');
  TimeOfDay selectedTime = TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
  var selectedDate = initialDate;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          final compact = MediaQuery.sizeOf(context).width < 340;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 16,
                  16,
                  compact ? 12 : 16,
                  16,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: AppFormContainer(
                  title: isEditing
                      ? AppStrings.reminderFormEditTitle
                      : AppStrings.reminderFormAddTitle,
                  subtitle: AppStrings.reminderFormSubtitle,
                  icon: Icons.alarm_on_rounded,
                  child: Form(
                    key: formKey,
                    autovalidateMode: hasAttemptedSubmit
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: InputDecoration(
                            labelText: typeFieldLabel,
                          ),
                          items: availableTypes
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(
                                    typeLabelBuilder(type),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (isSubmitting) {
                              return;
                            }
                            if (value == null) {
                              return;
                            }
                            setLocalState(() {
                              selectedType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: AppStrings.customNameOptional,
                          ),
                          validator: (value) => AppValidators.maxLengthOptional(
                            value,
                            60,
                            label: AppStrings.tr('Custom name', 'Nama kustom'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AppDateField(
                          label: AppStrings.startDate,
                          value: selectedDate,
                          onTap: isSubmitting
                              ? () {}
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 3650),
                                    ),
                                  );
                                  if (picked != null) {
                                    setLocalState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 10),
                        AppTimeField(
                          label: timeFieldLabel,
                          value: selectedTime,
                          onTap: isSubmitting
                              ? () {}
                              : () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setLocalState(() => selectedTime = picked);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      setLocalState(
                                        () => hasAttemptedSubmit = true,
                                      );
                                      return;
                                    }

                                    final timeString =
                                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';

                                    try {
                                      setLocalState(() {
                                        isSubmitting = true;
                                      });

                                      await onSubmit(
                                        selectedType: selectedType,
                                        customName:
                                            nameController.text.trim().isEmpty
                                            ? null
                                            : nameController.text.trim(),
                                        timeOfDay: timeString,
                                        startDate: selectedDate,
                                      );

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        context.showSuccessSnackBar(
                                          isEditing
                                              ? updateSuccessMessage
                                              : createSuccessMessage,
                                        );
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        setLocalState(() {
                                          isSubmitting = false;
                                        });
                                      }
                                      if (context.mounted) {
                                        context.showErrorSnackBar(
                                          toUserErrorMessage(
                                            error,
                                            fallback: AppStrings.actionFailed,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEditing
                                        ? AppStrings.saveChanges
                                        : AppStrings.save,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
}
