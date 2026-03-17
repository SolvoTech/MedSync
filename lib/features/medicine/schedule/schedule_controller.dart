import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/supabase_client.dart';
import '../../../data/repositories/medicine_repository_impl.dart';
import '../../../domain/models/medicine.dart';
import '../../../domain/models/medicine_schedule.dart';
import '../../../domain/repositories/medicine_repository.dart';
import '../../../services/alarm_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/permission_service.dart';

final medicineRemoteDataSourceProvider = Provider<MedicineRemoteDataSource>((
  ref,
) {
  return MedicineRemoteDataSource();
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final remote = ref.watch(medicineRemoteDataSourceProvider);
  return MedicineRepositoryImpl(remote);
});

final scheduleControllerProvider =
    AutoDisposeAsyncNotifierProvider<ScheduleController, List<Medicine>>(
      ScheduleController.new,
    );

final medicineSchedulesProvider =
    FutureProvider.family<List<MedicineScheduleBundle>, String>((
      ref,
      medicineId,
    ) async {
      return ref
          .read(medicineRemoteDataSourceProvider)
          .getSchedulesForMedicine(medicineId);
    });

class ScheduleController extends AutoDisposeAsyncNotifier<List<Medicine>> {
  @override
  Future<List<Medicine>> build() async {
    return _fetch();
  }

  Future<List<Medicine>> _fetch() {
    return ref.read(medicineRepositoryProvider).getMedicines();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> addMedicine({
    required String name,
    String? dosage,
    required int stockCurrent,
    String stockUnit = 'tablet',
    String medicineType = 'tablet',
    File? photoFile,
    File? prescriptionFile,
  }) async {
    final previous = state.valueOrNull ?? const <Medicine>[];
    state = const AsyncLoading();

    try {
      String? photoUrl;
      String? prescriptionUrl;
      final userId = SupabaseClientRef.client.auth.currentUser!.id;
      final uniqueId = DateTime.now().millisecondsSinceEpoch;

      if (photoFile != null) {
        final path = '$userId/medicine_$uniqueId\_photo.jpg';
        await SupabaseClientRef.client.storage
            .from('medicine-photos')
            .upload(path, photoFile);
        photoUrl = SupabaseClientRef.client.storage
            .from('medicine-photos')
            .getPublicUrl(path);
      }

      if (prescriptionFile != null) {
        final path = '$userId/medicine_$uniqueId\_prescription.jpg';
        await SupabaseClientRef.client.storage
            .from('medicine-photos')
            .upload(path, prescriptionFile);
        prescriptionUrl = SupabaseClientRef.client.storage
            .from('medicine-photos')
            .getPublicUrl(path);
      }

      await ref
          .read(medicineRepositoryProvider)
          .createMedicine(
            name: name,
            dosage: dosage,
            stockCurrent: stockCurrent,
            stockUnit: stockUnit,
            medicineType: medicineType,
            photoUrl: photoUrl,
            prescriptionUrl: prescriptionUrl,
          );
      state = AsyncData(await _fetch());
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deactivateMedicine(String medicineId) async {
    await ref.read(medicineRepositoryProvider).deactivateMedicine(medicineId);
    await refresh();
  }

  Future<void> deleteMedicine(String medicineId) async {
    await ref.read(medicineRepositoryProvider).deleteMedicine(medicineId);
    await refresh();
  }

  Future<void> addScheduleForMedicine({
    required String medicineId,
    required DateTime startDate,
    required List<String> timeSlots,
    String repeatType = 'daily',
    String? scheduleName,
  }) async {
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.ensureNotificationPermission();
    final canScheduleExact = await permissionService.canScheduleExactAlarms();
    if (!canScheduleExact) {
      await permissionService.requestExactAlarmPermission();
    }

    final created = await ref
        .read(medicineRemoteDataSourceProvider)
        .createScheduleWithSlots(
          medicineId: medicineId,
          startDate: startDate,
          timeSlots: timeSlots,
          repeatType: repeatType,
          scheduleName: scheduleName,
        );

    await _scheduleMedicineBundleNotifications(
      medicineId: medicineId,
      bundle: created,
    );

    ref.invalidate(medicineSchedulesProvider(medicineId));
  }

  Future<void> editSchedule({
    required String medicineId,
    required MedicineScheduleBundle current,
    required DateTime startDate,
    required List<String> timeSlots,
    String repeatType = 'daily',
    String? scheduleName,
  }) async {
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.ensureNotificationPermission();
    final canScheduleExact = await permissionService.canScheduleExactAlarms();
    if (!canScheduleExact) {
      await permissionService.requestExactAlarmPermission();
    }

    for (final slot in current.slots) {
      final notificationId = stableNotificationId('medicine-slot:${slot.id}');
      await ref
          .read(notificationServiceProvider)
          .cancelNotification(notificationId);
      await ref.read(alarmServiceProvider).cancelAlarm(notificationId);
    }

    final updated = await ref
        .read(medicineRemoteDataSourceProvider)
        .replaceScheduleWithSlots(
          oldScheduleId: current.schedule.id,
          medicineId: medicineId,
          startDate: startDate,
          timeSlots: timeSlots,
          repeatType: repeatType,
          scheduleName: scheduleName,
        );

    await _scheduleMedicineBundleNotifications(
      medicineId: medicineId,
      bundle: updated,
    );

    ref.invalidate(medicineSchedulesProvider(medicineId));
  }

  Future<void> deleteSchedule({
    required String medicineId,
    required MedicineScheduleBundle bundle,
  }) async {
    for (final slot in bundle.slots) {
      final notificationId = stableNotificationId('medicine-slot:${slot.id}');
      await ref
          .read(notificationServiceProvider)
          .cancelNotification(notificationId);
      await ref.read(alarmServiceProvider).cancelAlarm(notificationId);
    }

    await ref
        .read(medicineRemoteDataSourceProvider)
        .deleteScheduleWithSlots(bundle.schedule.id);

    ref.invalidate(medicineSchedulesProvider(medicineId));
  }

  Future<void> _scheduleMedicineBundleNotifications({
    required String medicineId,
    required MedicineScheduleBundle bundle,
  }) async {
    final notificationService = ref.read(notificationServiceProvider);
    final alarmService = ref.read(alarmServiceProvider);
    final now = DateTime.now();

    for (final slot in bundle.slots) {
      final parts = slot.timeOfDay.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var scheduledAt = DateTime(
        bundle.schedule.startDate.year,
        bundle.schedule.startDate.month,
        bundle.schedule.startDate.day,
        hour,
        minute,
      );

      if (scheduledAt.isBefore(now)) {
        scheduledAt = scheduledAt.add(const Duration(days: 1));
      }

      final notificationId = stableNotificationId('medicine-slot:${slot.id}');

      await notificationService.scheduleNotification(
        id: notificationId,
        channelId: 'medicine_reminders',
        title: 'Pengingat Obat',
        body: 'Waktunya minum obat Anda.',
        scheduledAt: scheduledAt,
        payload: 'medicine:$medicineId',
      );

      await alarmService.scheduleExactAlarm(
        id: notificationId,
        dateTime: scheduledAt,
      );
    }
  }
}
