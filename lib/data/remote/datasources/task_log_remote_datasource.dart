import '../../../core/utils/reminder_time.dart';
import '../../../domain/models/task_log.dart';
import '../../../services/task_completion_service.dart';
import 'task_log_completion_policy.dart';
import '../supabase_client.dart';

class TaskLogRemoteDataSource implements TaskLogCompletionStore {
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

  Future<TaskLog?> getTaskById(String taskLogId) async {
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
        .from('task_logs')
        .select()
        .eq('id', taskLogId)
        .eq('owner_id', user.id)
        .limit(1);

    if ((rows as List<dynamic>).isEmpty) {
      return null;
    }

    return TaskLog.fromMap(rows.first);
  }

  @override
  Future<void> updateTaskStatus({
    required String taskLogId,
    required String status,
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
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
    if (status == 'done' && completionProofPhotoPath != null) {
      payload['completion_proof_photo_path'] = completionProofPhotoPath;
      payload['completion_proof_captured_at'] = completionProofCapturedAt
          ?.toIso8601String();
      payload['completion_proof_uploaded_at'] =
          (completionProofUploadedAt ?? DateTime.now()).toIso8601String();
    }

    await client
        .from('task_logs')
        .update(payload)
        .eq('id', taskLogId)
        .eq('owner_id', user.id);
  }

  @override
  Future<void> markReminderDoneByReference({
    required String taskType,
    required String referenceId,
    String? timeOfDay,
    DateTime? scheduledAt,
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
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
    final exactScheduledAt =
        scheduledAt ?? _scheduledAtForToday(now: now, timeOfDay: timeOfDay);

    if (exactScheduledAt != null) {
      final exactRows = await client
          .from('task_logs')
          .select('id, status')
          .eq('owner_id', user.id)
          .eq('task_type', taskType)
          .eq('reference_id', referenceId)
          .eq('scheduled_at', exactScheduledAt.toIso8601String());

      final exactDecision = decideExactReminderCompletion(
        (exactRows as List<dynamic>)
            .map(
              (row) => ExactReminderTaskLogMatch.fromMap(
                row as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

      if (exactDecision.action == ExactReminderCompletionAction.noOp) {
        return;
      }

      if (exactDecision.action ==
          ExactReminderCompletionAction.updateExisting) {
        await updateTaskStatus(
          taskLogId: exactDecision.taskLogId!,
          status: 'done',
          completionProofPhotoPath: completionProofPhotoPath,
          completionProofCapturedAt: completionProofCapturedAt,
          completionProofUploadedAt: completionProofUploadedAt,
        );
        return;
      }

      await client.from('task_logs').insert({
        'owner_id': user.id,
        'task_type': taskType,
        'reference_id': referenceId,
        'scheduled_at': exactScheduledAt.toIso8601String(),
        'status': 'done',
        'completed_at': now.toIso8601String(),
        ..._completionProofPayload(
          completionProofPhotoPath: completionProofPhotoPath,
          completionProofCapturedAt: completionProofCapturedAt,
          completionProofUploadedAt: completionProofUploadedAt,
        ),
      });
      return;
    }

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
      await updateTaskStatus(
        taskLogId: taskLogId,
        status: 'done',
        completionProofPhotoPath: completionProofPhotoPath,
        completionProofCapturedAt: completionProofCapturedAt,
        completionProofUploadedAt: completionProofUploadedAt,
      );
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

    await client.from('task_logs').insert({
      'owner_id': user.id,
      'task_type': taskType,
      'reference_id': referenceId,
      'scheduled_at': (exactScheduledAt ?? now).toIso8601String(),
      'status': 'done',
      'completed_at': now.toIso8601String(),
      ..._completionProofPayload(
        completionProofPhotoPath: completionProofPhotoPath,
        completionProofCapturedAt: completionProofCapturedAt,
        completionProofUploadedAt: completionProofUploadedAt,
      ),
    });
  }

  Map<String, dynamic> _completionProofPayload({
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
  }) {
    if (completionProofPhotoPath == null) {
      return const <String, dynamic>{};
    }

    return <String, dynamic>{
      'completion_proof_photo_path': completionProofPhotoPath,
      'completion_proof_captured_at': completionProofCapturedAt
          ?.toIso8601String(),
      'completion_proof_uploaded_at':
          (completionProofUploadedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  DateTime? _scheduledAtForToday({required DateTime now, String? timeOfDay}) {
    return reminderScheduledAtForDay(day: now, timeOfDay: timeOfDay);
  }
}
