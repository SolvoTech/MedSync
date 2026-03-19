import '../../../domain/models/medicine.dart';
import '../../../domain/models/medicine_schedule.dart';
import '../supabase_client.dart';

class MedicineRemoteDataSource {
  Future<List<Medicine>> getMedicines({String? carePersonId}) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    var query = client
        .from('medicines')
        .select()
        .eq('owner_id', user.id)
        .eq('is_active', true);

    query = carePersonId == null
        ? query.filter('care_person_id', 'is', 'null')
        : query.eq('care_person_id', carePersonId);

    final rows = await query.order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => Medicine.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Medicine> createMedicine({
    required String name,
    String? dosage,
    required int stockCurrent,
    String stockUnit = 'tablet',
    String medicineType = 'tablet',
    String? carePersonId,
    String? photoUrl,
    String? prescriptionUrl,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    final inserted = await client.from('medicines').insert({
      'owner_id': user.id,
      'care_person_id': carePersonId,
      'name': name,
      'dosage': dosage,
      'medicine_type': medicineType,
      'stock_current': stockCurrent,
      'stock_unit': stockUnit,
      'photo_url': photoUrl,
      'prescription_url': prescriptionUrl,
      'is_active': true,
    }).select().single();
    
    return Medicine.fromMap(inserted);
  }

  Future<void> deactivateMedicine(String medicineId) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    await client
        .from('medicines')
        .update({'is_active': false})
        .eq('id', medicineId)
        .eq('owner_id', user.id);
  }

  Future<void> deleteMedicine(String medicineId) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    await client
        .from('medicines')
        .delete()
        .eq('id', medicineId)
        .eq('owner_id', user.id);
  }

  Future<List<MedicineScheduleBundle>> getSchedulesForMedicine(
    String medicineId,
  ) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    final scheduleRows = await client
        .from('medicine_schedules')
        .select()
        .eq('owner_id', user.id)
        .eq('medicine_id', medicineId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final schedules = (scheduleRows as List<dynamic>)
        .map((row) => MedicineSchedule.fromMap(row as Map<String, dynamic>))
        .toList();

    final bundles = <MedicineScheduleBundle>[];

    for (final schedule in schedules) {
      final slotRows = await client
          .from('schedule_time_slots')
          .select()
          .eq('schedule_id', schedule.id)
          .order('time_of_day', ascending: true);

      final slots = (slotRows as List<dynamic>)
          .map((row) => ScheduleTimeSlot.fromMap(row as Map<String, dynamic>))
          .toList();

      bundles.add(MedicineScheduleBundle(schedule: schedule, slots: slots));
    }

    return bundles;
  }

  Future<MedicineScheduleBundle> createScheduleWithSlots({
    required String medicineId,
    required DateTime startDate,
    required List<String> timeSlots,
    String repeatType = 'daily',
    String? scheduleName,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    if (timeSlots.isEmpty) {
      throw Exception('Minimal satu waktu minum harus diisi.');
    }

    final scheduleMap = await client
        .from('medicine_schedules')
        .insert({
          'medicine_id': medicineId,
          'owner_id': user.id,
          'schedule_name': scheduleName,
          'repeat_type': repeatType,
          'start_date': startDate.toIso8601String().split('T').first,
          'is_active': true,
        })
        .select()
        .single();

    final schedule = MedicineSchedule.fromMap(scheduleMap);
    final scheduleId = schedule.id;

    final insertedSlots = await client
        .from('schedule_time_slots')
        .insert(
          timeSlots
              .map(
                (time) => {
                  'schedule_id': scheduleId,
                  'time_of_day': time,
                  'dosage_amount': 1,
                  'dosage_unit': 'tablet',
                  'notification_enabled': true,
                  'notification_before_minutes': 0,
                },
              )
              .toList(),
        )
        .select();

    final slots = (insertedSlots as List<dynamic>)
        .map((row) => ScheduleTimeSlot.fromMap(row as Map<String, dynamic>))
        .toList();

    final now = DateTime.now();
    final scheduleDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    if (!scheduleDate.isAfter(DateTime(now.year, now.month, now.day))) {
      final taskRows = timeSlots.map((time) {
        final parts = time.split(':');
        final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
        final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        
        final scheduledAt = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        return {
          'owner_id': user.id,
          'task_type': 'medicine',
          'reference_id': scheduleId,
          'scheduled_at': scheduledAt.toIso8601String(),
          'status': 'pending',
        };
      }).toList();

      await client.from('task_logs').insert(taskRows);
    }

    return MedicineScheduleBundle(schedule: schedule, slots: slots);
  }

  Future<void> deleteScheduleWithSlots(String scheduleId) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    await client
        .from('schedule_time_slots')
        .delete()
        .eq('schedule_id', scheduleId);

    await client
        .from('task_logs')
        .delete()
        .eq('owner_id', user.id)
        .eq('task_type', 'medicine')
        .eq('reference_id', scheduleId);

    await client
        .from('medicine_schedules')
        .delete()
        .eq('id', scheduleId)
        .eq('owner_id', user.id);
  }

  Future<MedicineScheduleBundle> replaceScheduleWithSlots({
    required String oldScheduleId,
    required String medicineId,
    required DateTime startDate,
    required List<String> timeSlots,
    String repeatType = 'daily',
    String? scheduleName,
  }) async {
    await deleteScheduleWithSlots(oldScheduleId);

    return createScheduleWithSlots(
      medicineId: medicineId,
      startDate: startDate,
      timeSlots: timeSlots,
      repeatType: repeatType,
      scheduleName: scheduleName,
    );
  }
}
