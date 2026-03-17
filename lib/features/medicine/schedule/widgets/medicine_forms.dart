import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/image_helper.dart';

import '../../../../domain/models/medicine.dart';
import '../../../../domain/models/medicine_schedule.dart';
import '../schedule_controller.dart';

Future<void> showAddMedicineSheet(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final stockController = TextEditingController(text: '0');
  final formKey = GlobalKey<FormState>();

  File? photoFile;
  File? prescriptionFile;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tambah Obat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Obat'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama obat tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosis (opsional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok Saat Ini',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Stok harus diisi';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Stok harus berupa angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final file =
                                  await ImagePickerHelper.pickAndCompressImage(
                                    ImageSource.camera,
                                  );
                              if (file != null) {
                                setState(() {
                                  photoFile = file;
                                });
                              }
                            },
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: photoFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        photoFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Foto Kemasan\n(Opsional)',
                                          textAlign: TextAlign.center,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final file =
                                  await ImagePickerHelper.pickAndCompressImage(
                                    ImageSource.gallery,
                                  );
                              if (file != null) {
                                setState(() {
                                  prescriptionFile = file;
                                });
                              }
                            },
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: prescriptionFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        prescriptionFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.description_outlined,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Foto Resep\n(Opsional)',
                                          textAlign: TextAlign.center,
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
                      ],
                    ),
                    const SizedBox(height: 24),
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
                                  dosage: dosageController.text.trim().isEmpty
                                      ? null
                                      : dosageController.text.trim(),
                                  stockCurrent: int.parse(
                                    stockController.text.trim(),
                                  ),
                                  photoFile: photoFile,
                                  prescriptionFile: prescriptionFile,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Obat berhasil ditambahkan.'),
                                ),
                              );
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal menambahkan obat: $error',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
  dosageController.dispose();
  stockController.dispose();
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
    title: 'Tambah Jadwal ${medicine.name}',
    submitLabel: 'Simpan Jadwal',
    successMessage: 'Jadwal berhasil ditambahkan.',
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
    title: 'Edit Jadwal ${medicine.name}',
    submitLabel: 'Simpan Perubahan',
    successMessage: 'Jadwal berhasil diperbarui.',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Waktu tersebut sudah ada di jadwal.'),
                    ),
                  );
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

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Jadwal (Opsional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: repeatType,
                    decoration: const InputDecoration(
                      labelText: 'Pola Pengulangan',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Harian')),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Mingguan'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setLocalState(() {
                        repeatType = value;
                      });
                    },
                  ),
                  if (repeatType == 'weekly')
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Jadwal akan berulang setiap minggu di jam yang sama.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal Mulai'),
                    subtitle: Text(
                      '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: pickDate,
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
                          onDeleted: () {
                            setLocalState(() {
                              times.removeAt(i);
                            });
                          },
                        ),
                      ActionChip(
                        label: const Text('Tambah Waktu'),
                        avatar: const Icon(Icons.add_alarm, size: 18),
                        onPressed: pickTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        if (times.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tambahkan minimal 1 waktu minum obat.',
                              ),
                            ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(successMessage)),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menambah jadwal: $error'),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(submitLabel),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
}
