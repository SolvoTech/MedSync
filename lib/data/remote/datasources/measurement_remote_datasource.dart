import '../../../domain/models/measurement_reminder.dart';
import '../supabase_client.dart';

class MeasurementRemoteDataSource {
  Future<List<MeasurementReminder>> getReminders() async {
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
        .from('measurement_reminders')
        .select()
        .eq('owner_id', user.id)
        .eq('is_active', true)
        .order('time_of_day', ascending: true);

    return (rows as List<dynamic>)
        .map((row) => MeasurementReminder.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<MeasurementReminder> createReminder({
    required String measurementType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? unit,
    String? targetValue,
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
        .from('measurement_reminders')
        .insert({
          'owner_id': user.id,
          'measurement_type': measurementType,
          'custom_name': customName,
          'time_of_day': timeOfDay,
          'start_date': startDate.toIso8601String().split('T').first,
          'target_value': targetValue,
          'unit': unit,
          'is_active': true,
          'notification_enabled': true,
          'repeat_type': 'daily',
        })
        .select()
        .single();

    return MeasurementReminder.fromMap(inserted);
  }

  Future<void> updateReminder({
    required String reminderId,
    required String measurementType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? unit,
    String? targetValue,
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
        .from('measurement_reminders')
        .update({
          'measurement_type': measurementType,
          'custom_name': customName,
          'time_of_day': timeOfDay,
          'start_date': startDate.toIso8601String().split('T').first,
          'target_value': targetValue,
          'unit': unit,
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
        .from('measurement_reminders')
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
        .from('measurement_reminders')
        .delete()
        .eq('id', reminderId)
        .eq('owner_id', user.id);
  }
}
