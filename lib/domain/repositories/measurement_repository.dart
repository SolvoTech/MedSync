import '../models/measurement_log.dart';
import '../models/measurement_reminder.dart';

/// Abstract measurement repository interface per spec §26.5.
abstract class MeasurementRepository {
  Future<List<MeasurementReminder>> getReminders();

  Future<MeasurementReminder> createReminder(MeasurementReminder reminder);

  Future<void> updateReminder(MeasurementReminder reminder);

  Future<void> deleteReminder(String reminderId);

  Future<List<MeasurementLog>> getLogs(String reminderId);

  Future<MeasurementLog> createLog(MeasurementLog log);

  Future<void> deleteLog(String logId);
}
