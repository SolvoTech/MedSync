import '../models/task_log.dart';

/// Abstract task log repository interface per spec §26.5.
abstract class TaskLogRepository {
  Future<List<TaskLog>> getTodayLogs();

  Future<List<TaskLog>> getLogsByDateRange(DateTime start, DateTime end);

  Future<List<TaskLog>> getLogsByReferenceId(String referenceId);

  Future<TaskLog> createLog(TaskLog log);

  Future<void> updateLogStatus(
    String logId, {
    required String status,
    DateTime? completedAt,
    String? mood,
    String? symptomNotes,
  });

  Future<void> markAsMissed(String logId);

  Future<int> getCompletedCount(DateTime start, DateTime end);

  Future<int> getTotalCount(DateTime start, DateTime end);
}
