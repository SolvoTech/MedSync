import '../models/physical_activity_log.dart';
import '../models/physical_activity_reminder.dart';

/// Abstract physical activity repository interface per spec §26.5.
abstract class PhysicalActivityRepository {
  Future<List<PhysicalActivityReminder>> getReminders();

  Future<PhysicalActivityReminder> createReminder(
    PhysicalActivityReminder reminder,
  );

  Future<void> updateReminder(PhysicalActivityReminder reminder);

  Future<void> deleteReminder(String reminderId);

  Future<List<PhysicalActivityLog>> getLogs(String reminderId);

  Future<PhysicalActivityLog> createLog(PhysicalActivityLog log);

  Future<void> deleteLog(String logId);
}
