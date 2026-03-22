import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification utility helpers per spec §26.4.
class NotificationUtils {
  NotificationUtils._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Channel IDs per spec §7.
  static const medicineChannelId = 'medicine_reminder';
  static const measurementChannelId = 'measurement_reminder';
  static const activityChannelId = 'activity_reminder';
  static const stockChannelId = 'stock_warning';
  static const streakChannelId = 'streak_notification';
  static const dailySummaryChannelId = 'daily_summary';

  /// Initialize the notification plugin.
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Create notification channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          medicineChannelId,
          'Pengingat Obat',
          description: 'Notifikasi pengingat jadwal minum obat',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          measurementChannelId,
          'Pengingat Pengukuran',
          description: 'Notifikasi pengingat pengukuran kesehatan',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          activityChannelId,
          'Pengingat Aktivitas',
          description: 'Notifikasi pengingat aktivitas fisik',
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          stockChannelId,
          'Peringatan Stok',
          description: 'Notifikasi stok obat hampir habis',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          streakChannelId,
          'Notifikasi Streak',
          description: 'Pemberitahuan pencapaian streak',
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          dailySummaryChannelId,
          'Ringkasan Harian',
          description: 'Ringkasan progress harian',
          importance: Importance.low,
        ),
      );
    }
  }

  /// Show an immediate notification.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String channelId = medicineChannelId,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Cancel a notification by ID.
  static Future<void> cancel(int id) => _plugin.cancel(id);

  /// Cancel all notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  /// Generate a unique notification ID from a string hash.
  static int generateId(String source) => source.hashCode.abs() % 2147483647;
}
