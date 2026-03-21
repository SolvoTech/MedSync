import '../../../domain/models/task_log.dart';
import '../supabase_client.dart';

class TaskLogRemoteDataSource {
  Future<List<TaskLog>> getTodayTasks() async {
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

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final rows = await client
        .from('task_logs')
        .select()
        .eq('owner_id', user.id)
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('scheduled_at', ascending: true);

    return (rows as List<dynamic>)
        .map((row) => TaskLog.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateTaskStatus({
    required String taskLogId,
    required String status,
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

    final payload = <String, dynamic>{'status': status};
    if (status == 'done' || status == 'skipped') {
      payload['completed_at'] = DateTime.now().toIso8601String();
    }

    await client
        .from('task_logs')
        .update(payload)
        .eq('id', taskLogId)
        .eq('owner_id', user.id);
  }

  Future<void> markReminderDoneByReference({
    required String taskType,
    required String referenceId,
    String? timeOfDay,
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

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final pendingRows = await client
        .from('task_logs')
        .select('id')
        .eq('owner_id', user.id)
        .eq('task_type', taskType)
        .eq('reference_id', referenceId)
        .eq('status', 'pending')
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('scheduled_at', ascending: true)
        .limit(1);

    if ((pendingRows as List<dynamic>).isNotEmpty) {
      final taskLogId = pendingRows.first['id'] as String;
      await updateTaskStatus(taskLogId: taskLogId, status: 'done');
      return;
    }

    final doneRows = await client
        .from('task_logs')
        .select('id')
        .eq('owner_id', user.id)
        .eq('task_type', taskType)
        .eq('reference_id', referenceId)
        .eq('status', 'done')
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .limit(1);

    if ((doneRows as List<dynamic>).isNotEmpty) {
      return;
    }

    final scheduledAt = _scheduledAtForToday(now: now, timeOfDay: timeOfDay);
    await client.from('task_logs').insert({
      'owner_id': user.id,
      'task_type': taskType,
      'reference_id': referenceId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': 'done',
      'completed_at': now.toIso8601String(),
    });
  }

  DateTime _scheduledAtForToday({required DateTime now, String? timeOfDay}) {
    if (timeOfDay == null || timeOfDay.isEmpty) {
      return now;
    }

    final parts = timeOfDay.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;

    if (hour == null || minute == null) {
      return now;
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
