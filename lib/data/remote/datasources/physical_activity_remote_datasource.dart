import '../../../domain/models/physical_activity_reminder.dart';
import '../supabase_client.dart';

class PhysicalActivityRemoteDataSource {
  Future<List<PhysicalActivityReminder>> getReminders() async {
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

    final rows = await client
        .from('physical_activity_reminders')
        .select()
        .eq('owner_id', user.id)
        .eq('is_active', true)
        .order('time_of_day', ascending: true);

    return (rows as List<dynamic>)
        .map(
          (row) =>
              PhysicalActivityReminder.fromMap(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<PhysicalActivityReminder> createReminder({
    required String activityType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? targetUnit,
    num? targetValue,
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

    final inserted = await client
        .from('physical_activity_reminders')
        .insert({
          'owner_id': user.id,
          'activity_type': activityType,
          'custom_name': customName,
          'time_of_day': timeOfDay,
          'start_date': startDate.toIso8601String().split('T').first,
          'target_unit': targetUnit,
          'target_value': targetValue,
          'is_active': true,
          'notification_enabled': true,
          'repeat_type': 'daily',
        })
        .select()
        .single();

    return PhysicalActivityReminder.fromMap(inserted);
  }

  Future<void> updateReminder({
    required String reminderId,
    required String activityType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? targetUnit,
    num? targetValue,
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

    await client
        .from('physical_activity_reminders')
        .update({
          'activity_type': activityType,
          'custom_name': customName,
          'time_of_day': timeOfDay,
          'start_date': startDate.toIso8601String().split('T').first,
          'target_unit': targetUnit,
          'target_value': targetValue,
        })
        .eq('id', reminderId)
        .eq('owner_id', user.id);
  }

  Future<void> deactivateReminder(String reminderId) async {
    final client = SupabaseClientRef.maybeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    await client
        .from('physical_activity_reminders')
        .update({'is_active': false})
        .eq('id', reminderId)
        .eq('owner_id', user.id);
  }

  Future<void> deleteReminder(String reminderId) async {
    final client = SupabaseClientRef.maybeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    await client
        .from('physical_activity_reminders')
        .delete()
        .eq('id', reminderId)
        .eq('owner_id', user.id);
  }
}
