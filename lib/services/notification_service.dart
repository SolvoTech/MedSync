import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/remote/datasources/task_log_remote_datasource.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  NotificationService();

  static const String markDoneActionId = 'mark_done';
  static const String medicineReminderChannelId = 'medicine_reminders_v2';
  static const String legacyMedicineReminderChannelId = 'medicine_reminders';
  static const String medicineReminderRingtoneName = 'MedSync Obat Tenang';
  static const String medicineReminderSoundResource = 'medsync_obat_tenang';
  static const String measurementReminderChannelId = 'measurement_reminders';
  static const String activityReminderChannelId = 'activity_reminders';
  static const String stockWarningChannelId = 'stock_warnings';
  static const String streakChannelId = 'streak_notifications';
  static const String dailySummaryChannelId = 'daily_summary';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
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
        medicineReminderChannelId,
        'Pengingat Obat',
        description:
            'Notifikasi jadwal minum obat (Dering: $medicineReminderRingtoneName)',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          medicineReminderSoundResource,
        ),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      AndroidNotificationChannel(
        measurementReminderChannelId,
        'Pengingat Pengukuran',
        description: 'Notifikasi pengukuran kesehatan',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        activityReminderChannelId,
        'Pengingat Aktivitas',
        description: 'Notifikasi aktivitas fisik',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        stockWarningChannelId,
        'Peringatan Stok Obat',
        description: 'Notifikasi stok obat menipis',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        streakChannelId,
        'Notifikasi Streak',
        description: 'Notifikasi pencapaian streak',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        dailySummaryChannelId,
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

    await _migrateMedicineNotificationsToRingtoneChannel();
  }

  Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
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
    final androidSound = _androidSoundForChannel(channelId);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        channelDescription: _channelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: androidSound,
        audioAttributesUsage: channelId == medicineReminderChannelId
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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
        body: '$body (Peringatan ke-$i)',
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

    var channelId = medicineReminderChannelId;
    if (taskType == 'measurement') channelId = measurementReminderChannelId;
    if (taskType == 'physical_activity') channelId = activityReminderChannelId;

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

        var nextTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          h,
          m,
        );

        // Unconditionally add 1 day from today to permanently silence today's triggers
        nextTime = nextTime.add(const Duration(days: 1));

        // Add the snooze offset minutes
        nextTime = nextTime.add(Duration(minutes: 5 * snoozeIndex));

        // Cancel the old intent natively first to guarantee a clean overwrite
        await _plugin.cancel(pending.id);

        // Re-schedule it for tomorrow to silence the remaining trigger today
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
      await cancelNotification(
        stableNotificationId('${basePayload}_snooze_$i'),
      );
    }
  }

  String _channelName(String channelId) {
    switch (channelId) {
      case legacyMedicineReminderChannelId:
      case medicineReminderChannelId:
        return 'Pengingat Obat';
      case measurementReminderChannelId:
        return 'Pengingat Pengukuran';
      case activityReminderChannelId:
        return 'Pengingat Aktivitas';
      case stockWarningChannelId:
        return 'Peringatan Stok Obat';
      case streakChannelId:
        return 'Notifikasi Streak';
      case dailySummaryChannelId:
        return 'Ringkasan Harian';
      default:
        return 'MedSync';
    }
  }

  String _channelDescription(String channelId) {
    switch (channelId) {
      case legacyMedicineReminderChannelId:
      case medicineReminderChannelId:
        return 'Notifikasi jadwal minum obat (Dering: $medicineReminderRingtoneName)';
      case measurementReminderChannelId:
        return 'Notifikasi pengukuran kesehatan';
      case activityReminderChannelId:
        return 'Notifikasi aktivitas fisik';
      case stockWarningChannelId:
        return 'Notifikasi stok obat menipis';
      case streakChannelId:
        return 'Notifikasi pencapaian streak';
      case dailySummaryChannelId:
        return 'Notifikasi ringkasan aktivitas harian';
      default:
        return 'Notifikasi MedSync';
    }
  }

  bool _supportsTaskDoneAction(String channelId) {
    return channelId == medicineReminderChannelId ||
        channelId == legacyMedicineReminderChannelId ||
        channelId == measurementReminderChannelId ||
        channelId == activityReminderChannelId;
  }

  Future<void> _migrateMedicineNotificationsToRingtoneChannel() async {
    final pendingList = await _plugin.pendingNotificationRequests();

    for (final pending in pendingList) {
      final payload = pending.payload;
      if (payload == null || payload.isEmpty || !payload.startsWith('task|')) {
        continue;
      }

      final parsed = _parseTaskPayload(payload);
      if (parsed == null || parsed.taskType != 'medicine') {
        continue;
      }

      final timeOfDay = parsed.timeOfDay;
      if (timeOfDay == null || timeOfDay.isEmpty) {
        continue;
      }

      final parts = payload.split('|');
      final snoozeIndex = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
      final nextTime = _nextDailyTime(timeOfDay, snoozeIndex: snoozeIndex);

      await _plugin.cancel(pending.id);

      await scheduleNotification(
        id: pending.id,
        channelId: medicineReminderChannelId,
        title: pending.title ?? 'Pengingat Obat',
        body: pending.body ?? 'Waktunya minum obat Anda.',
        scheduledAt: nextTime,
        payload: payload,
        repeatDaily: true,
      );
    }
  }

  DateTime _nextDailyTime(String timeOfDay, {int snoozeIndex = 0}) {
    final now = DateTime.now();
    final parts = timeOfDay.split(':');

    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    var scheduledAt = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledAt.isBefore(now)) {
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }

    if (snoozeIndex > 0) {
      scheduledAt = scheduledAt.add(Duration(minutes: 5 * snoozeIndex));
    }

    return scheduledAt;
  }

  AndroidNotificationSound? _androidSoundForChannel(String channelId) {
    if (channelId == medicineReminderChannelId ||
        channelId == legacyMedicineReminderChannelId) {
      return const RawResourceAndroidNotificationSound(
        medicineReminderSoundResource,
      );
    }
    return null;
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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone for background isolate
  tz.initializeTimeZones();
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  } catch (_) {}

  // Initialize Supabase for background isolate
  try {
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (url.isNotEmpty && anonKey.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: anonKey);
    }
  } catch (_) {}

  await _handleNotificationResponse(response);

  if (kDebugMode) {
    debugPrint('Notification tapped background: ${response.payload}');
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
