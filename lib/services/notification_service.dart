import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/remote/datasources/task_log_remote_datasource.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  NotificationService();

  static const String markDoneActionId = 'mark_done';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final timeZoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    if (kDebugMode) {
      debugPrint('[NotificationService] Local timezone set to: $timeZoneName');
    }

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
    bool repeatDaily = false,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        channelDescription: _channelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        actions: _supportsTaskDoneAction(channelId)
            ? const <AndroidNotificationAction>[
                AndroidNotificationAction(
                  markDoneActionId,
                  'Selesai ✓',
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
    );

    final scheduleDate = tz.TZDateTime.from(scheduledAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (kDebugMode) {
      debugPrint('[Notification] Scheduling id=$id');
      debugPrint('[Notification]   input scheduledAt=$scheduledAt');
      debugPrint('[Notification]   tz.local=${tz.local.name}');
      debugPrint('[Notification]   tzScheduleDate=$scheduleDate');
      debugPrint('[Notification]   now=$now');
      debugPrint('[Notification]   repeatDaily=$repeatDaily');
    }

    if (scheduleDate.isBefore(now)) {
      if (kDebugMode) {
        debugPrint('[Notification]   ⚠️ SKIPPED — scheduleDate is in the past');
      }
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
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
    );

    if (kDebugMode) {
      debugPrint('[Notification]   ✅ Scheduled successfully');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> scheduleTaskNotification({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
    required String channelId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final basePayload = 'task|$taskType|$referenceId|$timeOfDay';

    // Schedule base notification
    await scheduleNotification(
      id: stableNotificationId(basePayload),
      channelId: channelId,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      payload: '$basePayload|0',
      repeatDaily: true,
    );

    // Schedule 6 snooze notifications (5 minutes apart, up to 30 mins)
    for (int i = 1; i <= 6; i++) {
      final snoozeTime = scheduledAt.add(Duration(minutes: 5 * i));
      await scheduleNotification(
        id: stableNotificationId('${basePayload}_snooze_$i'),
        channelId: channelId,
        title: title,
        body: body,
        scheduledAt: snoozeTime,
        payload: '$basePayload|$i',
        repeatDaily: true,
      );
    }
  }

  Future<void> advanceScheduleToTomorrow({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
  }) async {
    final targetPrefix = 'task|$taskType|$referenceId|$timeOfDay';

    String channelId = 'medicine_reminders';
    if (taskType == 'measurement') channelId = 'measurement_reminders';
    if (taskType == 'physical_activity') channelId = 'activity_reminders';

    final pendingList = await _plugin.pendingNotificationRequests();
    final now = tz.TZDateTime.now(tz.local);

    for (final pending in pendingList) {
      if (pending.payload != null &&
          pending.payload!.startsWith(targetPrefix)) {
        final parts = pending.payload!.split('|');
        final snoozeIndex = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;

        final timeParts = timeOfDay.split(':');
        final h = int.tryParse(timeParts[0]) ?? 0;
        final m = int.tryParse(timeParts[1]) ?? 0;

        var nextTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
        
        // If the base time for today hasn't passed, tomorrow is +1 day.
        // If it has passed, we add +1 day from now.
        if (!nextTime.isAfter(now)) {
          nextTime = nextTime.add(const Duration(days: 1));
        }

        // Add the snooze offset minutes
        nextTime = nextTime.add(Duration(minutes: 5 * snoozeIndex));

        // Re-schedule it to overwrite the current pending intent for today
        await scheduleNotification(
          id: pending.id,
          channelId: channelId,
          title: pending.title ?? 'Pengingat MedSync',
          body: pending.body ?? 'Saatnya tugas Anda.',
          scheduledAt: nextTime,
          payload: pending.payload,
          repeatDaily: true,
        );
      }
    }
  }

  Future<void> cancelTaskNotification({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
  }) async {
    final basePayload = 'task|$taskType|$referenceId|$timeOfDay';
    await cancelNotification(stableNotificationId(basePayload));
    for (int i = 1; i <= 6; i++) {
      await cancelNotification(stableNotificationId('${basePayload}_snooze_$i'));
    }
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

  bool _supportsTaskDoneAction(String channelId) {
    return channelId == 'medicine_reminders' ||
        channelId == 'measurement_reminders' ||
        channelId == 'activity_reminders';
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    await _handleNotificationResponse(response);
  }
}

int stableNotificationId(String seed) {
  return seed.hashCode.abs() % 2147483647;
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  await _handleNotificationResponse(response);

  if (kDebugMode) {
    debugPrint('Notification tapped: ${response.payload}');
  }
}

Future<void> _handleNotificationResponse(NotificationResponse response) async {
  if (response.actionId != NotificationService.markDoneActionId) {
    return;
  }

  final payload = response.payload;
  if (payload == null || payload.isEmpty) {
    return;
  }

  final parsed = _parseTaskPayload(payload);
  if (parsed == null) {
    return;
  }

  try {
    await TaskLogRemoteDataSource().markReminderDoneByReference(
      taskType: parsed.taskType,
      referenceId: parsed.referenceId,
      timeOfDay: parsed.timeOfDay,
    );
    
    final notificationService = NotificationService();
    await notificationService.advanceScheduleToTomorrow(
      taskType: parsed.taskType,
      referenceId: parsed.referenceId,
      timeOfDay: parsed.timeOfDay ?? '',
    );
    
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Failed to mark task from notification action: $error');
    }
  }
}

_TaskPayload? _parseTaskPayload(String payload) {
  // Payload format: task|taskType|referenceId|HH:mm:ss
  final parts = payload.split('|');
  if (parts.length < 3 || parts.first != 'task') {
    return null;
  }

  final taskType = parts[1].trim();
  final referenceId = parts[2].trim();
  final timeOfDay = parts.length > 3 ? parts[3].trim() : null;

  if (taskType.isEmpty || referenceId.isEmpty) {
    return null;
  }

  return _TaskPayload(
    taskType: taskType,
    referenceId: referenceId,
    timeOfDay: timeOfDay,
  );
}

class _TaskPayload {
  const _TaskPayload({
    required this.taskType,
    required this.referenceId,
    required this.timeOfDay,
  });

  final String taskType;
  final String referenceId;
  final String? timeOfDay;
}
