import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/remote/datasources/medicine_remote_datasource.dart';
import '../../../data/remote/supabase_client.dart';
import '../../../data/repositories/medicine_repository_impl.dart';
import '../../../domain/models/medicine.dart';
import '../../../domain/models/medicine_schedule.dart';
import '../../../domain/repositories/medicine_repository.dart';
import '../../../services/notification_service.dart';
import '../../../services/permission_service.dart';
import '../../home/home_controller.dart';
import '../../reports/report_screen.dart';

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
  static const int _maxMedicinePhotoBytes = 5 * 1024 * 1024;

  @override
  Future<List<Medicine>> build() async {
    return _fetch();
  }

  String _detectImageExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'png';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    return 'jpg';
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _medicinePhotoStorageErrorMessage(StorageException error) {
    final lower = error.message.toLowerCase();

    if (lower.contains('bucket') && lower.contains('not found')) {
      return 'Penyimpanan foto obat belum dikonfigurasi. Silakan hubungi admin.';
    }

    if (lower.contains('permission') || lower.contains('row-level security')) {
      return 'Anda tidak memiliki izin untuk mengunggah foto obat.';
    }

    if (lower.contains('mime') ||
        lower.contains('content type') ||
        (lower.contains('invalid') && lower.contains('image'))) {
      return 'Format foto obat tidak didukung. Gunakan JPG, PNG, atau WEBP.';
    }

    if (lower.contains('size') ||
        lower.contains('too large') ||
        lower.contains('payload') ||
        lower.contains('limit')) {
      final maxMb = (_maxMedicinePhotoBytes / (1024 * 1024)).round();
      return 'Ukuran foto obat terlalu besar. Maksimal $maxMb MB.';
    }

    return 'Gagal mengunggah foto obat. Silakan coba lagi.';
  }

  Future<String> _uploadMedicinePhoto({
    required SupabaseClient client,
    required String userId,
    required File photoFile,
    required int uniqueId,
  }) async {
    final bytes = await photoFile.readAsBytes();
    if (bytes.isEmpty) {
      throw const AppException(
        'File foto obat kosong. Silakan pilih ulang foto.',
      );
    }

    if (bytes.lengthInBytes > _maxMedicinePhotoBytes) {
      final maxMb = (_maxMedicinePhotoBytes / (1024 * 1024)).round();
      throw AppException('Ukuran foto obat terlalu besar. Maksimal $maxMb MB.');
    }

    final extension = _detectImageExtension(photoFile.path);
    final contentType = _contentTypeForExtension(extension);
    final path = '$userId/medicine_${uniqueId}_photo.$extension';

    try {
      await client.storage
          .from('medicine-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      return client.storage.from('medicine-photos').getPublicUrl(path);
    } on StorageException catch (error) {
      throw AppException(_medicinePhotoStorageErrorMessage(error));
    }
  }

  Future<List<Medicine>> _fetch() {
    return ref
        .read(medicineRepositoryProvider)
        .getMedicines(includeInactive: true);
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
  }) async {
    final previous = state.valueOrNull ?? const <Medicine>[];
    state = const AsyncLoading();

    try {
      final client = SupabaseClientRef.maybeClient;
      if (client == null) {
        throw StateError('Supabase client belum terinisialisasi');
      }
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw StateError('User belum login');
      }

      String? photoUrl;
      final userId = currentUser.id;
      final uniqueId = DateTime.now().millisecondsSinceEpoch;

      if (photoFile != null) {
        photoUrl = await _uploadMedicinePhoto(
          client: client,
          userId: userId,
          photoFile: photoFile,
          uniqueId: uniqueId,
        );
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
          );
      state = AsyncData(await _fetch());
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deactivateMedicine(String medicineId) async {
    final bundles = await ref
        .read(medicineRemoteDataSourceProvider)
        .getSchedulesForMedicine(medicineId);

    for (final bundle in bundles) {
      for (final slot in bundle.slots) {
        await ref
            .read(notificationServiceProvider)
            .cancelTaskNotification(
              taskType: 'medicine',
              referenceId: bundle.schedule.id,
              timeOfDay: slot.timeOfDay,
            );
      }
    }

    await ref.read(medicineRepositoryProvider).deactivateMedicine(medicineId);
    await refresh();
  }

  Future<void> activateMedicine(String medicineId) async {
    await ref.read(medicineRepositoryProvider).activateMedicine(medicineId);

    final bundles = await ref
        .read(medicineRemoteDataSourceProvider)
        .getSchedulesForMedicine(medicineId);

    for (final bundle in bundles) {
      await _scheduleMedicineBundleNotifications(
        medicineId: medicineId,
        bundle: bundle,
      );
    }

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
    ref.invalidate(todayTasksProvider);
    ref.invalidate(reportDataProvider);
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
      await ref
          .read(notificationServiceProvider)
          .cancelTaskNotification(
            taskType: 'medicine',
            referenceId: current.schedule.id,
            timeOfDay: slot.timeOfDay,
          );
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
    ref.invalidate(todayTasksProvider);
    ref.invalidate(reportDataProvider);
  }

  Future<void> deleteSchedule({
    required String medicineId,
    required MedicineScheduleBundle bundle,
  }) async {
    for (final slot in bundle.slots) {
      await ref
          .read(notificationServiceProvider)
          .cancelTaskNotification(
            taskType: 'medicine',
            referenceId: bundle.schedule.id,
            timeOfDay: slot.timeOfDay,
          );
    }

    await ref
        .read(medicineRemoteDataSourceProvider)
        .deleteScheduleWithSlots(bundle.schedule.id);

    ref.invalidate(medicineSchedulesProvider(medicineId));
    ref.invalidate(todayTasksProvider);
    ref.invalidate(reportDataProvider);
  }

  Future<void> _scheduleMedicineBundleNotifications({
    required String medicineId,
    required MedicineScheduleBundle bundle,
  }) async {
    final notificationService = ref.read(notificationServiceProvider);
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

      // Fast-forward to today if it's already in the past
      if (scheduledAt.isBefore(now)) {
        scheduledAt = DateTime(now.year, now.month, now.day, hour, minute);
        // If today's time block has also already passed, push it to tomorrow
        if (scheduledAt.isBefore(now)) {
          scheduledAt = scheduledAt.add(const Duration(days: 1));
        }
      }

      await notificationService.scheduleTaskNotification(
        taskType: 'medicine',
        referenceId: bundle.schedule.id,
        timeOfDay: slot.timeOfDay,
        channelId: NotificationService.medicineReminderChannelId,
        title: 'Pengingat Obat',
        body: 'Waktunya minum obat Anda.',
        scheduledAt: scheduledAt,
      );
    }
  }
}
