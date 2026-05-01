import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

class PermissionService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<bool> ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> canScheduleExactAlarms() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final pluginResult = await android?.canScheduleExactNotifications();
    if (pluginResult != null) {
      return pluginResult;
    }

    return Permission.scheduleExactAlarm.isGranted;
  }

  Future<bool> requestExactAlarmPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final pluginResult = await android?.requestExactAlarmsPermission();
    if (pluginResult != null) {
      return pluginResult;
    }

    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  Future<bool> requestFullScreenIntentPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final result = await android?.requestFullScreenIntentPermission();
    return result ?? true;
  }

  Future<bool> hasNotificationPolicyAccess() async {
    final status = await Permission.accessNotificationPolicy.status;
    return status.isGranted;
  }

  Future<bool> requestNotificationPolicyAccess() async {
    final status = await Permission.accessNotificationPolicy.request();
    return status.isGranted;
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  Future<void> ensureReminderReliabilityPermissions() async {
    await ensureNotificationPermission();

    if (!await canScheduleExactAlarms()) {
      await requestExactAlarmPermission();
    }

    await requestFullScreenIntentPermission();

    if (!await hasNotificationPolicyAccess()) {
      await requestNotificationPolicyAccess();
    }

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      await requestIgnoreBatteryOptimizations();
    }
  }
}
