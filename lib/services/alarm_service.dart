import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});

class AlarmService {
  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  Future<void> scheduleExactAlarm({
    required int id,
    required DateTime dateTime,
  }) async {
    if (dateTime.isBefore(DateTime.now())) {
      return;
    }

    await AndroidAlarmManager.oneShotAt(
      dateTime,
      id,
      medSyncAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
  }
}

@pragma('vm:entry-point')
void medSyncAlarmCallback() {
  if (kDebugMode) {
    debugPrint('MedSync alarm callback triggered');
  }
}
