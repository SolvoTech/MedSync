import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/medicine.dart';
import '../../../../domain/models/medicine_schedule.dart';
import '../schedule_controller.dart';
import 'medicine_forms.dart';
import 'medicine_schedule_bundle_card.dart';

class MedicineTab extends ConsumerWidget {
  const MedicineTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(scheduleControllerProvider.notifier).refresh(),
        child: state.when(
          data: (medicines) {
            if (medicines.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Belum ada data obat.')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final medicine = medicines[index];
                return _MedicineTile(
                  medicine: medicine,
                  onTap: () => _showMedicineSchedules(context, ref, medicine),
                  onLongPress: () =>
                      _showMedicineActions(context, ref, medicine),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemCount: medicines.length,
            );
          },
          loading: () => ListView(
            children: const [
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Gagal memuat jadwal obat: $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddMedicineSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Obat'),
      ),
    );
  }

  Future<void> _showMedicineActions(
    BuildContext context,
    WidgetRef ref,
    Medicine medicine,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: const Text('Nonaktifkan Obat'),
                onTap: () => Navigator.pop(context, 'deactivate'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Hapus Obat',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    try {
      if (result == 'deactivate') {
        await ref
            .read(scheduleControllerProvider.notifier)
            .deactivateMedicine(medicine.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${medicine.name} dinonaktifkan.')),
          );
        }
      } else if (result == 'delete') {
        await ref
            .read(scheduleControllerProvider.notifier)
            .deleteMedicine(medicine.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${medicine.name} dihapus.')));
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Aksi gagal: $error')));
      }
    }
  }

  Future<void> _showMedicineSchedules(
    BuildContext context,
    WidgetRef ref,
    Medicine medicine,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer(
              builder: (context, sheetRef, _) {
                final schedulesState = sheetRef.watch(
                  medicineSchedulesProvider(medicine.id),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (medicine.photoUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              medicine.photoUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadwal ${medicine.name}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (medicine.prescriptionUrl != null)
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Image.network(medicine.prescriptionUrl!),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Lihat Resep Dokter',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: schedulesState.when(
                        data: (bundles) {
                          if (bundles.isEmpty) {
                            return const Center(
                              child: Text('Belum ada jadwal untuk obat ini.'),
                            );
                          }

                          return ListView.separated(
                            itemBuilder: (context, index) {
                              final bundle = bundles[index];
                              return MedicineScheduleBundleCard(
                                bundle: bundle,
                                onEdit: () => showEditScheduleSheet(
                                  context,
                                  ref,
                                  medicine,
                                  bundle,
                                ),
                                onDelete: () => _deleteMedicineSchedule(
                                  context,
                                  ref,
                                  medicine,
                                  bundle,
                                ),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemCount: bundles.length,
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) =>
                            Center(child: Text('Gagal memuat jadwal: $error')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            showAddScheduleSheet(context, ref, medicine),
                        icon: const Icon(Icons.schedule),
                        label: const Text('Tambah Jadwal Minum'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteMedicineSchedule(
    BuildContext context,
    WidgetRef ref,
    Medicine medicine,
    MedicineScheduleBundle bundle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: const Text(
          'Jadwal obat akan dihapus permanen dan notifikasi terkait dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(scheduleControllerProvider.notifier)
          .deleteSchedule(medicineId: medicine.id, bundle: bundle);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Jadwal obat dihapus.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus jadwal: $error')),
        );
      }
    }
  }
}

class _MedicineTile extends StatelessWidget {
  const _MedicineTile({
    required this.medicine,
    required this.onTap,
    required this.onLongPress,
  });

  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: const CircleAvatar(child: Icon(Icons.medication_rounded)),
        title: Text(medicine.name),
        subtitle: Text(
          '${medicine.dosage ?? '-'} • Stok ${medicine.stockCurrent} ${medicine.stockUnit}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
