import 'package:permission_handler/permission_handler.dart';

/// Permission utility helpers per spec §26.4.
class PermissionUtils {
  PermissionUtils._();

  /// Request notification permission (Android 13+).
  static Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Request exact alarm permission (Android 12+).
  static Future<bool> requestExactAlarm() async {
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  /// Request camera permission (for medicine photo).
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage / photos permission.
  static Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Request Health Connect / activity recognition.
  static Future<bool> requestActivityRecognition() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  /// Check if notification permission is granted.
  static Future<bool> hasNotification() =>
      Permission.notification.isGranted;

  /// Check if exact alarm is granted.
  static Future<bool> hasExactAlarm() =>
      Permission.scheduleExactAlarm.isGranted;

  /// Open app settings if permission permanently denied.
  static Future<bool> openSettings() => openAppSettings();

  /// Request all critical permissions at once.
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    return await [
      Permission.notification,
      Permission.scheduleExactAlarm,
    ].request();
  }
}
