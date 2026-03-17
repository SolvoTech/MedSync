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
}
