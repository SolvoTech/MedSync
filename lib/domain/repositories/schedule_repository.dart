import '../models/medicine_schedule.dart';

/// Abstract schedule repository interface per spec §26.5.
abstract class ScheduleRepository {
  Future<List<MedicineSchedule>> getSchedules(String medicineId);

  Future<MedicineSchedule> createSchedule(MedicineSchedule schedule);

  Future<void> updateSchedule(MedicineSchedule schedule);

  Future<void> deleteSchedule(String scheduleId);

  Future<List<ScheduleTimeSlot>> getTimeSlots(String scheduleId);

  Future<ScheduleTimeSlot> addTimeSlot(ScheduleTimeSlot slot);

  Future<void> updateTimeSlot(ScheduleTimeSlot slot);

  Future<void> deleteTimeSlot(String slotId);
}
