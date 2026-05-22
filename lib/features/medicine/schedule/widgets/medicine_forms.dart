import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../../core/widgets/app_form_container.dart';

import '../../../../domain/models/medicine.dart';
import '../../../../domain/models/medicine_schedule.dart';
import '../schedule_controller.dart';

Future<void> showAddMedicineSheet(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final stockController = TextEditingController(text: '0');
  final formKey = GlobalKey<FormState>();
  final compact = MediaQuery.sizeOf(context).width < 340;

  File? photoFile;

  Future<ImageSource?> chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  AppStrings.tr('Choose from Gallery', 'Pilih dari Galeri'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(
                  AppStrings.tr('Take a Photo', 'Ambil Foto'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                  title: AppStrings.addMedicineSheetTitle,
                  subtitle: AppStrings.addMedicineSheetSubtitle,
                  icon: Icons.medication_rounded,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: AppStrings.medicineName,
                          ),
                          validator: AppValidators.name,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: dosageController,
                          decoration: InputDecoration(
                            labelText: AppStrings.tr(
                              'Dosage (optional)',
                              'Dosis (opsional)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppStrings.medicineStock,
                          ),
                          validator: AppValidators.nonNegativeInt,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: InkWell(
                            onTap: () async {
                              final source = await chooseImageSource();
                              if (source == null) {
                                return;
                              }
                              final file =
                                  await ImagePickerHelper.pickAndCompressImage(
                                    source,
                                  );
                              if (file != null) {
                                setState(() {
                                  photoFile = file;
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: compact ? 92 : 110,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.24),
                              ),
                              child: photoFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        photoFile!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          AppStrings.medicinePhotoOptional,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              try {
                                await ref
                                    .read(scheduleControllerProvider.notifier)
                                    .addMedicine(
                                      name: nameController.text.trim(),
                                      dosage:
                                          dosageController.text.trim().isEmpty
                                          ? null
                                          : dosageController.text.trim(),
                                      stockCurrent: int.parse(
                                        stockController.text.trim(),
                                      ),
                                      photoFile: photoFile,
                                    );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  context.showSuccessSnackBar(
                                    AppStrings.medicineAdded,
                                  );
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  context.showErrorSnackBar(
                                    toUserErrorMessage(
                                      error,
                                      fallback: AppStrings.medicineAddFailed,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              AppStrings.save,
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
}

Future<void> showAddScheduleSheet(
  BuildContext context,
  WidgetRef ref,
  Medicine medicine,
) async {
  await _showScheduleSheet(
    context: context,
    ref: ref,
    medicine: medicine,
    title: '${AppStrings.tr('Add Schedule', 'Tambah Jadwal')} ${medicine.name}',
    submitLabel: AppStrings.tr('Save Schedule', 'Simpan Jadwal'),
    successMessage: AppStrings.scheduleAdded,
    onSubmit: (startDate, times, scheduleName, repeatType) async {
      await ref
          .read(scheduleControllerProvider.notifier)
          .addScheduleForMedicine(
            medicineId: medicine.id,
            scheduleName: scheduleName,
            startDate: startDate,
            timeSlots: times,
            repeatType: repeatType,
          );
    },
  );
}

Future<void> showEditScheduleSheet(
  BuildContext context,
  WidgetRef ref,
  Medicine medicine,
  MedicineScheduleBundle bundle,
) async {
  final initialTimes = bundle.slots.map((slot) {
    final parts = slot.timeOfDay.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }).toList();

  await _showScheduleSheet(
    context: context,
    ref: ref,
    medicine: medicine,
    title: '${AppStrings.tr('Edit Schedule', 'Edit Jadwal')} ${medicine.name}',
    submitLabel: AppStrings.saveChanges,
    successMessage: AppStrings.tr(
      'Schedule updated successfully.',
      'Jadwal berhasil diperbarui.',
    ),
    initialScheduleName: bundle.schedule.scheduleName,
    initialStartDate: bundle.schedule.startDate,
    initialTimes: initialTimes,
    onSubmit: (startDate, times, scheduleName, repeatType) async {
      await ref
          .read(scheduleControllerProvider.notifier)
          .editSchedule(
            medicineId: medicine.id,
            current: bundle,
            scheduleName: scheduleName,
            startDate: startDate,
            timeSlots: times,
            repeatType: repeatType,
          );
    },
    initialRepeatType: bundle.schedule.repeatType,
  );
}

Future<void> _showScheduleSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Medicine medicine,
  required String title,
  required String submitLabel,
  required String successMessage,
  required Future<void> Function(
    DateTime startDate,
    List<String> timeSlots,
    String? scheduleName,
    String repeatType,
  )
  onSubmit,
  String? initialScheduleName,
  DateTime? initialStartDate,
  List<TimeOfDay>? initialTimes,
  String? initialRepeatType,
}) async {
  final nameController = TextEditingController();
  nameController.text = initialScheduleName ?? '';
  final times = <TimeOfDay>[...(initialTimes ?? <TimeOfDay>[])];
  final formKey = GlobalKey<FormState>();
  DateTime startDate = initialStartDate ?? DateTime.now();
  var repeatType = initialRepeatType ?? 'daily';
  var isSubmitting = false;
  final compact = MediaQuery.sizeOf(context).width < 340;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          int toMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              final isDuplicate = times.any(
                (value) =>
                    value.hour == picked.hour && value.minute == picked.minute,
              );
              if (isDuplicate) {
                if (context.mounted) {
                  context.showWarningSnackBar(AppStrings.duplicateTimeWarning);
                }
                return;
              }

              setLocalState(() {
                times.add(picked);
                times.sort((a, b) => toMinutes(a).compareTo(toMinutes(b)));
              });
            }
          }

          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: startDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) {
              setLocalState(() {
                startDate = picked;
              });
            }
          }

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
                  title: title,
                  subtitle: AppStrings.scheduleSheetSubtitle,
                  icon: Icons.schedule_rounded,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: AppStrings.scheduleNameOptional,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: repeatType,
                          decoration: InputDecoration(
                            labelText: AppStrings.repeatPattern,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'daily',
                              child: Text(
                                AppStrings.daily,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text(
                                AppStrings.weekly,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (isSubmitting) {
                              return;
                            }
                            if (value == null) {
                              return;
                            }
                            setLocalState(() {
                              repeatType = value;
                            });
                          },
                        ),
                        if (repeatType == 'weekly')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              AppStrings.weeklyHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 8),
                        AppDateField(
                          label: AppStrings.startDate,
                          value: startDate,
                          onTap: isSubmitting ? () {} : pickDate,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < times.length; i++)
                              InputChip(
                                label: Text(
                                  '${times[i].hour.toString().padLeft(2, '0')}:${times[i].minute.toString().padLeft(2, '0')}',
                                ),
                                onDeleted: isSubmitting
                                    ? null
                                    : () {
                                        setLocalState(() {
                                          times.removeAt(i);
                                        });
                                      },
                              ),
                            ActionChip(
                              label: Text(
                                AppStrings.addTime,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              avatar: const Icon(Icons.add_alarm, size: 18),
                              onPressed: isSubmitting ? null : pickTime,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    if (times.isEmpty) {
                                      context.showWarningSnackBar(
                                        AppStrings.minimumOneTimeWarning,
                                      );
                                      return;
                                    }

                                    try {
                                      final formattedTimes = times
                                          .map(
                                            (t) =>
                                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00',
                                          )
                                          .toList();

                                      setLocalState(() {
                                        isSubmitting = true;
                                      });

                                      await onSubmit(
                                        startDate,
                                        formattedTimes,
                                        nameController.text.trim().isEmpty
                                            ? null
                                            : nameController.text.trim(),
                                        repeatType,
                                      );
                                      ref.invalidate(
                                        medicineSchedulesProvider(medicine.id),
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        context.showSuccessSnackBar(
                                          successMessage,
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
                                            fallback:
                                                AppStrings.saveScheduleFailed,
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
                                    submitLabel,
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
}
