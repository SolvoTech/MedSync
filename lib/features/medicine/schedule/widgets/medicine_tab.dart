import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/widgets/app_dialog.dart';
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
                children: [
                  SizedBox(height: 120),
                  Center(child: Text(AppStrings.noMedicineData)),
                ],
              );
            }

            final activeMedicines = medicines
                .where((medicine) => medicine.isActive)
                .toList();
            final inactiveMedicines = medicines
                .where((medicine) => !medicine.isActive)
                .toList();

            final items = <Widget>[];

            if (activeMedicines.isNotEmpty) {
              items
                ..add(_SectionHeader(label: AppStrings.activeSchedules))
                ..add(const SizedBox(height: 8));

              for (var i = 0; i < activeMedicines.length; i++) {
                final medicine = activeMedicines[i];
                items.add(
                  _MedicineTile(
                    medicine: medicine,
                    onTap: () => _showMedicineSchedules(context, ref, medicine),
                    onLongPress: () =>
                        _showMedicineActions(context, ref, medicine),
                  ),
                );
                if (i != activeMedicines.length - 1) {
                  items.add(const SizedBox(height: 8));
                }
              }
            }

            if (inactiveMedicines.isNotEmpty) {
              if (items.isNotEmpty) {
                items.add(const SizedBox(height: 16));
              }
              items
                ..add(_SectionHeader(label: AppStrings.inactiveSchedules))
                ..add(const SizedBox(height: 8));

              for (var i = 0; i < inactiveMedicines.length; i++) {
                final medicine = inactiveMedicines[i];
                items.add(
                  _MedicineTile(
                    medicine: medicine,
                    onTap: () => _showMedicineSchedules(context, ref, medicine),
                    onLongPress: () =>
                        _showMedicineActions(context, ref, medicine),
                  ),
                );
                if (i != inactiveMedicines.length - 1) {
                  items.add(const SizedBox(height: 8));
                }
              }
            }

            return ListView(padding: const EdgeInsets.all(16), children: items);
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
                    toUserErrorMessage(
                      error,
                      fallback: AppStrings.scheduleLoadFailed,
                    ),
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
        label: Text(AppStrings.addMedicine),
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
              if (medicine.isActive)
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: Text(AppStrings.disableMedicineSchedule),
                  subtitle: Text(AppStrings.disableKeepsVisible),
                  onTap: () => Navigator.pop(context, 'deactivate'),
                )
              else
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(AppStrings.reactivate),
                  subtitle: Text(AppStrings.reactivateHint),
                  onTap: () => Navigator.pop(context, 'activate'),
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  AppStrings.deletePermanent,
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: Text(AppStrings.dataWillBeDeleted),
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
        final confirmed = await AppDialog.showConfirm(
          context,
          title: AppStrings.disableMedicineTitle,
          message: AppStrings.tr(
            'Schedule for ${medicine.name} will remain visible in the inactive list, but reminders will be paused.',
            'Jadwal ${medicine.name} akan tetap tersimpan dan tetap tampil di daftar Nonaktif, tetapi pengingatnya akan dihentikan.',
          ),
          confirmLabel: AppStrings.disableAction,
          icon: Icons.pause_circle_outline,
          allowDontAskAgain: true,
          dontAskAgainKey: 'confirm_skip_deactivate_medicine',
        );
        if (confirmed != true) {
          return;
        }

        await ref
            .read(scheduleControllerProvider.notifier)
            .deactivateMedicine(medicine.id);
        if (context.mounted) {
          context.showInfoSnackBar(
            AppStrings.tr(
              '${medicine.name} disabled. Schedule remains visible in Inactive section.',
              '${medicine.name} dinonaktifkan. Jadwal tetap terlihat di bagian Nonaktif.',
            ),
          );
        }
      } else if (result == 'activate') {
        await ref
            .read(scheduleControllerProvider.notifier)
            .activateMedicine(medicine.id);
        if (context.mounted) {
          context.showSuccessSnackBar(
            AppStrings.tr(
              '${medicine.name} reactivated successfully.',
              '${medicine.name} berhasil diaktifkan kembali.',
            ),
          );
        }
      } else if (result == 'delete') {
        final confirmed = await AppDialog.showConfirm(
          context,
          title: AppStrings.deleteMedicineTitle,
          message: AppStrings.tr(
            'Medicine ${medicine.name} and all related schedules/data will be permanently deleted and cannot be restored.',
            'Obat ${medicine.name} beserta semua jadwal dan data terkait akan dihapus permanen dan tidak dapat dipulihkan.',
          ),
          confirmLabel: AppStrings.delete,
          isDestructive: true,
          icon: Icons.delete_outline,
        );
        if (confirmed != true) {
          return;
        }

        await ref
            .read(scheduleControllerProvider.notifier)
            .deleteMedicine(medicine.id);
        if (context.mounted) {
          context.showSuccessSnackBar(
            AppStrings.tr(
              '${medicine.name} deleted.',
              '${medicine.name} dihapus.',
            ),
          );
        }
      }
    } catch (error) {
      if (context.mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(error, fallback: AppStrings.actionFailed),
        );
      }
    }
  }

  Future<void> _showMedicineSchedules(
    BuildContext context,
    WidgetRef ref,
    Medicine medicine,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: Consumer(
              builder: (context, sheetRef, _) {
                final schedulesState = sheetRef.watch(
                  medicineSchedulesProvider(medicine.id),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (medicine.photoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              medicine.photoUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.medication_rounded,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            medicine.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _MedicineStatsRow(medicine: medicine),
                    const SizedBox(height: 24),
                    if (!medicine.isActive)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(AppStrings.medicineStatusDisabledInfo),
                      ),
                    Expanded(
                      child: schedulesState.when(
                        data: (bundles) {
                          if (bundles.isEmpty) {
                            return Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.event_busy_rounded,
                                        size: 48,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppStrings.tr(
                                        'No Schedules Yet',
                                        'Belum Ada Jadwal',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppStrings.tr(
                                        'Add medication time to get started.',
                                        'Tambahkan waktu minum obat untuk memulai.',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemBuilder: (context, index) {
                              final bundle = bundles[index];
                              return MedicineScheduleBundleCard(
                                bundle: bundle,
                                isReadOnly: !medicine.isActive,
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
                                const SizedBox(height: 12),
                            itemCount: bundles.length,
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              toUserErrorMessage(
                                error,
                                fallback: AppStrings.scheduleLoadFailed,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: medicine.isActive
                          ? FilledButton.icon(
                              onPressed: () =>
                                  showAddScheduleSheet(context, ref, medicine),
                              icon: const Icon(Icons.add_task_rounded),
                              label: Text(AppStrings.addMedicineTimeSchedule),
                            )
                          : OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(scheduleControllerProvider.notifier)
                                      .activateMedicine(medicine.id);
                                  if (context.mounted) {
                                    context.showSuccessSnackBar(
                                      AppStrings.tr(
                                        '${medicine.name} reactivated successfully.',
                                        '${medicine.name} berhasil diaktifkan kembali.',
                                      ),
                                    );
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    context.showErrorSnackBar(
                                      toUserErrorMessage(
                                        error,
                                        fallback: AppStrings.activateFailed,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.play_circle_filled_rounded,
                              ),
                              label: Text(AppStrings.reactivate),
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
    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.deleteScheduleTitle,
      message: AppStrings.deleteScheduleMessage,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(scheduleControllerProvider.notifier)
          .deleteSchedule(medicineId: medicine.id, bundle: bundle);
      if (context.mounted) {
        context.showSuccessSnackBar(AppStrings.scheduleDeleted);
      }
    } catch (error) {
      if (context.mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(error, fallback: AppStrings.deleteScheduleFailed),
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
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = medicine.isActive ? Colors.green : Colors.orange;

    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: const CircleAvatar(child: Icon(Icons.medication_rounded)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                medicine.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                medicine.isActive
                    ? AppStrings.statusActive
                    : AppStrings.statusInactive,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${medicine.dosage ?? '-'} • Stok ${medicine.stockCurrent} ${medicine.stockUnit}',
          style: TextStyle(
            color: medicine.isActive
                ? null
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: onLongPress,
          icon: const Icon(Icons.more_vert),
          tooltip: AppStrings.tr('More options', 'Opsi lainnya'),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _MedicineStatsRow extends StatelessWidget {
  const _MedicineStatsRow({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(
            context,
            icon: Icons.medication_outlined,
            label: AppStrings.tr('Dosage', 'Dosis'),
            value: medicine.dosage ?? '-',
            colorScheme: colorScheme,
          ),
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildStatColumn(
            context,
            icon: Icons.inventory_2_outlined,
            label: AppStrings.tr('Stock', 'Stok'),
            value: '${medicine.stockCurrent} ${medicine.stockUnit}',
            colorScheme: colorScheme,
          ),
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildStatColumn(
            context,
            icon: medicine.isActive
                ? Icons.check_circle_outline
                : Icons.pause_circle_outline,
            label: AppStrings.tr('Status', 'Status'),
            value: medicine.isActive
                ? AppStrings.statusActiveLabel
                : AppStrings.statusInactiveLabel,
            colorScheme: colorScheme,
            valueColor: medicine.isActive ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
