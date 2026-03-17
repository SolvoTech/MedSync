import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    tz.initializeTimeZones();

    const channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'medicine_reminders',
        'Pengingat Obat',
        description: 'Notifikasi jadwal minum obat',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'measurement_reminders',
        'Pengingat Pengukuran',
        description: 'Notifikasi pengukuran kesehatan',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'activity_reminders',
        'Pengingat Aktivitas',
        description: 'Notifikasi aktivitas fisik',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'stock_warnings',
        'Peringatan Stok Obat',
        description: 'Notifikasi stok obat menipis',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'streak_notifications',
        'Notifikasi Streak',
        description: 'Notifikasi pencapaian streak',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'daily_summary',
        'Ringkasan Harian',
        description: 'Notifikasi ringkasan aktivitas harian',
        importance: Importance.low,
      ),
    ];

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      for (final channel in channels) {
        await android.createNotificationChannel(channel);
      }
    }
  }

  Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  }

  Future<void> scheduleNotification({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        channelDescription: _channelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final scheduleDate = tz.TZDateTime.from(scheduledAt, tz.local);
    if (scheduleDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduleDate,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  String _channelName(String channelId) {
    switch (channelId) {
      case 'medicine_reminders':
        return 'Pengingat Obat';
      case 'measurement_reminders':
        return 'Pengingat Pengukuran';
      case 'activity_reminders':
        return 'Pengingat Aktivitas';
      case 'stock_warnings':
        return 'Peringatan Stok Obat';
      case 'streak_notifications':
        return 'Notifikasi Streak';
      case 'daily_summary':
        return 'Ringkasan Harian';
      default:
        return 'MedSync';
    }
  }

  String _channelDescription(String channelId) {
    switch (channelId) {
      case 'medicine_reminders':
        return 'Notifikasi jadwal minum obat';
      case 'measurement_reminders':
        return 'Notifikasi pengukuran kesehatan';
      case 'activity_reminders':
        return 'Notifikasi aktivitas fisik';
      case 'stock_warnings':
        return 'Notifikasi stok obat menipis';
      case 'streak_notifications':
        return 'Notifikasi pencapaian streak';
      case 'daily_summary':
        return 'Notifikasi ringkasan aktivitas harian';
      default:
        return 'Notifikasi MedSync';
    }
  }
}

int stableNotificationId(String seed) {
  return seed.hashCode.abs() % 2147483647;
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (kDebugMode) {
    debugPrint('Notification tapped: ${response.payload}');
  }
}
