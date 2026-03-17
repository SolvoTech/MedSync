import 'package:flutter/material.dart';

typedef ReminderSubmit =
    Future<void> Function({
      required String selectedType,
      String? customName,
      required String timeOfDay,
      required DateTime startDate,
    });

enum ReminderAction { edit, deactivate, delete }

ReminderAction? parseReminderAction(String value) {
  switch (value) {
    case 'edit':
      return ReminderAction.edit;
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
  required Future<void> Function() onDeactivate,
  required Future<void> Function() onDelete,
  required String deactivatedMessage,
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

    if (parsed == ReminderAction.deactivate) {
      await onDeactivate();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(deactivatedMessage)));
      }
      return;
    }

    final confirmed = await showDeleteReminderDialog(
      context: context,
      title: 'Hapus Reminder?',
      content: deleteDialogContent,
    );
    if (!confirmed) {
      return;
    }

    await onDelete();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(deletedMessage)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Aksi gagal: $error')));
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
    super.key,
  });

  final IconData icon;
  final String title;
  final String timeOfDay;
  final VoidCallback onTap;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('Jam ${timeOfDay.substring(0, 5)}'),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: onActionSelected,
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'deactivate', child: Text('Nonaktifkan')),
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}

Future<bool> showDeleteReminderDialog({
  required BuildContext context,
  required String title,
  required String content,
  String cancelText = 'Batal',
  String confirmText = 'Hapus',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );

  return confirmed == true;
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
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(labelText: typeFieldLabel),
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
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kustom (Opsional)',
                  ),
                ),
                ListTile(
                  title: const Text('Tanggal Mulai'),
                  subtitle: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setLocalState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text(timeFieldLabel),
                  subtitle: Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
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
                FilledButton(
                  onPressed: () async {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? updateSuccessMessage
                                  : createSuccessMessage,
                            ),
                          ),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Aksi gagal: $error')),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Simpan Perubahan' : 'Simpan'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
}
