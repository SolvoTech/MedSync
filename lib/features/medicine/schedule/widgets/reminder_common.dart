import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_form_container.dart';
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

Future<void> handleReminderAction({
  required BuildContext context,
  required String action,
  required Future<void> Function() onEdit,
  Future<void> Function()? onMarkDone,
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

      await onMarkDone();
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

class ReminderListTile extends StatelessWidget {
  const ReminderListTile({
    required this.icon,
    required this.title,
    required this.timeOfDay,
    required this.onTap,
    required this.onActionSelected,
    this.showMarkDoneAction = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String timeOfDay;
  final VoidCallback onTap;
  final ValueChanged<String> onActionSelected;
  final bool showMarkDoneAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          '${AppStrings.reminderHourPrefix} ${timeOfDay.substring(0, 5)}',
        ),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: onActionSelected,
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(AppStrings.reminderEdit)),
            if (showMarkDoneAction)
              PopupMenuItem(
                value: 'mark_done',
                child: Text(AppStrings.tr('Mark as Done', 'Tandai Selesai')),
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
      ),
    );
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
          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                  child: Text(typeLabelBuilder(type)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
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
                          onTap: () async {
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
                          onTap: () async {
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
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                setLocalState(() => hasAttemptedSubmit = true);
                                return;
                              }

                              final timeString =
                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';

                              try {
                                await onSubmit(
                                  selectedType: selectedType,
                                  customName: nameController.text.trim().isEmpty
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
                                  context.showErrorSnackBar(
                                    toUserErrorMessage(
                                      error,
                                      fallback: AppStrings.actionFailed,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              isEditing
                                  ? AppStrings.saveChanges
                                  : AppStrings.save,
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
