import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/alarm_ringtones.dart';
import '../data/local/preferences/app_preferences.dart';
import '../data/remote/datasources/task_log_remote_datasource.dart';
import '../data/remote/supabase_client.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  NotificationService();

  static const MethodChannel _systemSettingsChannel = MethodChannel(
    'med_syn/system_settings',
  );

  static const String markDoneActionId = 'mark_done';
  // v5 is intentionally new to recover from stale Android channels that may
  // persist silent sound settings from previous installs/updates.
  // Bumped from v4 → v5 to force recreation of channels after audio files
  // were extended to ≥ 1 second (fixes silent alarm bug).
  static const String medicineReminderChannelId = 'medicine_reminders_v5';
  static const String legacyMedicineReminderChannelId = 'medicine_reminders_v4';
  static const String legacyMedicineReminderChannelIdV2 =
      'medicine_reminders_v3';
  static const String legacyMedicineReminderChannelIdV1 =
      'medicine_reminders_v2';
  static const String legacyMedicineReminderChannelIdV0 = 'medicine_reminders';
  static const String measurementReminderChannelId = 'measurement_reminders_v5';
  static const String legacyMeasurementReminderChannelId =
      'measurement_reminders_v4';
  static const String legacyMeasurementReminderChannelIdV2 =
      'measurement_reminders_v3';
  static const String legacyMeasurementReminderChannelIdV1 =
      'measurement_reminders_v2';
  static const String legacyMeasurementReminderChannelIdV0 =
      'measurement_reminders';
  static const String activityReminderChannelId = 'activity_reminders_v5';
  static const String legacyActivityReminderChannelId = 'activity_reminders_v4';
  static const String legacyActivityReminderChannelIdV2 =
      'activity_reminders_v3';
  static const String legacyActivityReminderChannelIdV1 =
      'activity_reminders_v2';
  static const String legacyActivityReminderChannelIdV0 = 'activity_reminders';
  static const String stockWarningChannelId = 'stock_warnings';
  static const String streakChannelId = 'streak_notifications';
  static const String dailySummaryChannelId = 'daily_summary';
  static const String _legacyTaskPayloadPrefix = 'task';
  static const String _scopedTaskPayloadPrefix = 'taskv2';

  static final FlutterLocalNotificationsPlugin _plugin =
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

    await _ensureAndroidChannels();

    try {
      await _syncReminderNotificationsToCurrentChannelConfig();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Skip reminder channel sync: $error');
      }
    }
  }

  Future<void> applyRingtonePreferenceChanges() async {
    await _ensureAndroidChannels();
    await _syncReminderNotificationsToCurrentChannelConfig();
  }

  Future<void> syncTaskNotificationsWithCurrentPreferences() async {
    await cancelAllTaskNotifications();

    final client = SupabaseClientRef.maybeClient;
    final userId = _activeUserId();
    if (client == null || userId == null) {
      return;
    }

    if (AppPreferences.notifMedicine) {
      await _scheduleActiveMedicineTaskNotifications(
        client: client,
        userId: userId,
      );
    }

    if (AppPreferences.notifMeasurement) {
      await _scheduleActiveMeasurementTaskNotifications(
        client: client,
        userId: userId,
      );
    }

    if (AppPreferences.notifActivity) {
      await _scheduleActiveActivityTaskNotifications(
        client: client,
        userId: userId,
      );
    }
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

  Future<bool> openAndroidNotificationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final opened =
          await _systemSettingsChannel.invokeMethod<bool>(
            'openNotificationSettings',
          ) ??
          false;
      return opened;
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] Failed to open Android notification settings: ${error.code} ${error.message}',
        );
      }
      return false;
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    bool repeatDaily = false,
    int snoozeIndex = 0,
  }) async {
    final baseChannelId = _baseChannelId(channelId);
    final ringtoneId = _ringtoneIdForBaseChannel(baseChannelId);
    final resolvedChannelId = _resolvedChannelId(
      baseChannelId: baseChannelId,
      ringtoneId: ringtoneId,
    );

    await _ensureAndroidChannel(
      baseChannelId: baseChannelId,
      resolvedChannelId: resolvedChannelId,
      ringtoneId: ringtoneId,
    );

    NotificationDetails buildDetails({required bool allowCustomSound}) {
      final androidSound = allowCustomSound
          ? _androidSoundForChannel(baseChannelId, ringtoneId: ringtoneId)
          : null;

      return NotificationDetails(
        android: AndroidNotificationDetails(
          resolvedChannelId,
          _channelName(baseChannelId),
          channelDescription: _channelDescription(
            baseChannelId,
            ringtoneId: ringtoneId,
          ),
          importance: _channelImportance(baseChannelId),
          priority: Priority.high,
          playSound: true,
          sound: androidSound,
          audioAttributesUsage: _isReminderBaseChannel(baseChannelId)
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
          actions: _supportsTaskDoneAction(baseChannelId)
              ? const <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    markDoneActionId,
                    'Selesai',
                    showsUserInterface: false,
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
    }

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

    final modeCandidates = _androidScheduleModeCandidates(
      baseChannelId: baseChannelId,
      snoozeIndex: snoozeIndex,
    );

    PlatformException? lastPlatformError;
    var scheduled = false;

    for (final mode in modeCandidates) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduleDate,
          buildDetails(allowCustomSound: true),
          payload: payload,
          androidScheduleMode: mode,
          matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
        );
        scheduled = true;
        if (kDebugMode) {
          debugPrint('[Notification]   mode=$mode');
        }
        break;
      } on PlatformException catch (error) {
        if (_isInvalidSoundError(error)) {
          if (kDebugMode) {
            debugPrint(
              '[NotificationService] Fallback to default sound: ${error.message}',
            );
          }

          try {
            await _plugin.zonedSchedule(
              id,
              title,
              body,
              scheduleDate,
              buildDetails(allowCustomSound: false),
              payload: payload,
              androidScheduleMode: mode,
              matchDateTimeComponents: repeatDaily
                  ? DateTimeComponents.time
                  : null,
            );
            scheduled = true;
            if (kDebugMode) {
              debugPrint(
                '[Notification]   mode=$mode (default sound fallback)',
              );
            }
            break;
          } on PlatformException catch (fallbackError) {
            lastPlatformError = fallbackError;
            if (kDebugMode) {
              debugPrint(
                '[NotificationService] Scheduling retry failed with mode=$mode: ${fallbackError.code} ${fallbackError.message}',
              );
            }
            continue;
          }
        }

        lastPlatformError = error;
        if (kDebugMode) {
          debugPrint(
            '[NotificationService] Scheduling failed with mode=$mode: ${error.code} ${error.message}',
          );
        }
      }
    }

    if (!scheduled && lastPlatformError != null) {
      throw lastPlatformError;
    }

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
    final activeUserId = _activeUserId();
    final basePayload = activeUserId == null
        ? '$_legacyTaskPayloadPrefix|$taskType|$referenceId|$timeOfDay'
        : '$_scopedTaskPayloadPrefix|$taskType|$activeUserId|$referenceId|$timeOfDay';

    // Schedule base notification
    await scheduleNotification(
      id: stableNotificationId(basePayload),
      channelId: channelId,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      payload: '$basePayload|0',
      repeatDaily: true,
      snoozeIndex: 0,
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
        snoozeIndex: i,
      );
    }
  }

  Future<void> advanceScheduleToTomorrow({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
  }) async {
    final channelId =
        _channelIdForTaskType(taskType) ?? medicineReminderChannelId;

    final pendingList = await _plugin.pendingNotificationRequests();
    final now = tz.TZDateTime.now(tz.local);
    final activeUserId = _activeUserId();

    for (final pending in pendingList) {
      final payload = pending.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }

      final parsed = _parseTaskPayload(payload);
      if (parsed == null) {
        continue;
      }

      if (!_matchesTaskPayload(
        parsed,
        taskType: taskType,
        referenceId: referenceId,
        timeOfDay: timeOfDay,
      )) {
        continue;
      }

      if (!_isPayloadOwnedByUser(parsed, activeUserId)) {
        continue;
      }

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
      nextTime = nextTime.add(Duration(minutes: 5 * parsed.snoozeIndex));

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

  Future<void> cancelTaskNotification({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
  }) async {
    final pendingList = await _plugin.pendingNotificationRequests();
    final activeUserId = _activeUserId();

    for (final pending in pendingList) {
      final payload = pending.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }

      final parsed = _parseTaskPayload(payload);
      if (parsed == null) {
        continue;
      }

      if (!_matchesTaskPayload(
        parsed,
        taskType: taskType,
        referenceId: referenceId,
        timeOfDay: timeOfDay,
      )) {
        continue;
      }

      if (!_isPayloadOwnedByUser(parsed, activeUserId)) {
        continue;
      }

      await _plugin.cancel(pending.id);
    }
  }

  Future<void> cancelAllTaskNotifications() async {
    final pendingList = await _plugin.pendingNotificationRequests();

    for (final pending in pendingList) {
      final payload = pending.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }

      if (_parseTaskPayload(payload) == null) {
        continue;
      }

      await _plugin.cancel(pending.id);
    }
  }

  Future<void> cancelStaleTaskNotificationsForActiveSession() async {
    final pendingList = await _plugin.pendingNotificationRequests();
    final activeUserId = _activeUserId();

    for (final pending in pendingList) {
      final payload = pending.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }

      final parsed = _parseTaskPayload(payload);
      if (parsed == null) {
        continue;
      }

      if (_isPayloadOwnedByUser(parsed, activeUserId)) {
        continue;
      }

      await _plugin.cancel(pending.id);
    }
  }

  String _channelName(String baseChannelId) {
    switch (baseChannelId) {
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

  String _channelDescription(String baseChannelId, {String? ringtoneId}) {
    switch (baseChannelId) {
      case medicineReminderChannelId:
        final tone = AlarmRingtones.byId(ringtoneId).labelId;
        return 'Notifikasi jadwal minum obat (Dering: $tone)';
      case measurementReminderChannelId:
        final tone = AlarmRingtones.byId(ringtoneId).labelId;
        return 'Notifikasi pengukuran kesehatan (Dering: $tone)';
      case activityReminderChannelId:
        final tone = AlarmRingtones.byId(ringtoneId).labelId;
        return 'Notifikasi aktivitas fisik (Dering: $tone)';
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

  bool _supportsTaskDoneAction(String baseChannelId) {
    return _isReminderBaseChannel(baseChannelId);
  }

  Future<void> _syncReminderNotificationsToCurrentChannelConfig() async {
    final pendingList = await _plugin.pendingNotificationRequests();
    final activeUserId = _activeUserId();

    for (final pending in pendingList) {
      final payload = pending.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }

      final parsed = _parseTaskPayload(payload);
      if (parsed == null) {
        continue;
      }

      if (!_isPayloadOwnedByUser(parsed, activeUserId)) {
        await _plugin.cancel(pending.id);
        continue;
      }

      final channelId = _channelIdForTaskType(parsed.taskType);
      if (channelId == null) {
        continue;
      }

      final timeOfDay = parsed.timeOfDay;
      if (timeOfDay == null || timeOfDay.isEmpty) {
        continue;
      }

      final nextTime = _nextDailyTime(
        timeOfDay,
        snoozeIndex: parsed.snoozeIndex,
      );

      await _plugin.cancel(pending.id);

      await scheduleNotification(
        id: pending.id,
        channelId: channelId,
        title: pending.title ?? 'Pengingat Obat',
        body: pending.body ?? 'Waktunya minum obat Anda.',
        scheduledAt: nextTime,
        payload: payload,
        repeatDaily: true,
      );
    }
  }

  String? _activeUserId() {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
    } catch (_) {}
    return null;
  }

  bool _matchesTaskPayload(
    _TaskPayload parsed, {
    required String taskType,
    required String referenceId,
    required String timeOfDay,
  }) {
    return parsed.taskType == taskType &&
        parsed.referenceId == referenceId &&
        parsed.timeOfDay == timeOfDay;
  }

  bool _isPayloadOwnedByUser(_TaskPayload payload, String? activeUserId) {
    if (activeUserId == null || activeUserId.isEmpty) {
      return false;
    }

    final payloadUserId = payload.userId;
    if (payloadUserId == null || payloadUserId.isEmpty) {
      // Legacy payloads are treated as stale to prevent cross-account leakage.
      return false;
    }

    return payloadUserId == activeUserId;
  }

  Future<void> _scheduleActiveMedicineTaskNotifications({
    required SupabaseClient client,
    required String userId,
  }) async {
    final scheduleRows = await client
        .from('medicine_schedules')
        .select('id, start_date')
        .eq('owner_id', userId)
        .eq('is_active', true);

    for (final row in (scheduleRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final scheduleId = map['id']?.toString();
      final rawStartDate = map['start_date']?.toString();
      final startDate = rawStartDate == null
          ? null
          : DateTime.tryParse(rawStartDate);

      if (scheduleId == null || scheduleId.isEmpty || startDate == null) {
        continue;
      }

      final slotRows = await client
          .from('schedule_time_slots')
          .select('time_of_day, notification_enabled')
          .eq('schedule_id', scheduleId)
          .order('time_of_day', ascending: true);

      for (final slotRow in (slotRows as List<dynamic>)) {
        final slotMap = slotRow as Map<String, dynamic>;
        final notificationEnabled =
            (slotMap['notification_enabled'] as bool?) ?? true;
        if (!notificationEnabled) {
          continue;
        }

        final timeOfDay = slotMap['time_of_day']?.toString();
        if (timeOfDay == null || timeOfDay.isEmpty) {
          continue;
        }

        final scheduledAt = _nextScheduleTimeFromStartDate(
          startDate: startDate,
          timeOfDay: timeOfDay,
        );

        await scheduleTaskNotification(
          taskType: 'medicine',
          referenceId: scheduleId,
          timeOfDay: timeOfDay,
          channelId: medicineReminderChannelId,
          title: 'Pengingat Obat',
          body: 'Waktunya minum obat Anda.',
          scheduledAt: scheduledAt,
        );
      }
    }
  }

  Future<void> _scheduleActiveMeasurementTaskNotifications({
    required SupabaseClient client,
    required String userId,
  }) async {
    final rows = await client
        .from('measurement_reminders')
        .select('id, time_of_day, start_date')
        .eq('owner_id', userId)
        .eq('is_active', true)
        .order('time_of_day', ascending: true);

    for (final row in (rows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final reminderId = map['id']?.toString();
      final timeOfDay = map['time_of_day']?.toString();
      final rawStartDate = map['start_date']?.toString();
      final startDate = rawStartDate == null
          ? null
          : DateTime.tryParse(rawStartDate);

      if (reminderId == null ||
          reminderId.isEmpty ||
          timeOfDay == null ||
          timeOfDay.isEmpty ||
          startDate == null) {
        continue;
      }

      final scheduledAt = _nextScheduleTimeFromStartDate(
        startDate: startDate,
        timeOfDay: timeOfDay,
      );

      await scheduleTaskNotification(
        taskType: 'measurement',
        referenceId: reminderId,
        timeOfDay: timeOfDay,
        channelId: measurementReminderChannelId,
        title: 'Pengingat Pengukuran',
        body: 'Saatnya melakukan pengukuran kesehatan Anda.',
        scheduledAt: scheduledAt,
      );
    }
  }

  Future<void> _scheduleActiveActivityTaskNotifications({
    required SupabaseClient client,
    required String userId,
  }) async {
    final rows = await client
        .from('physical_activity_reminders')
        .select('id, time_of_day, start_date')
        .eq('owner_id', userId)
        .eq('is_active', true)
        .order('time_of_day', ascending: true);

    for (final row in (rows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final reminderId = map['id']?.toString();
      final timeOfDay = map['time_of_day']?.toString();
      final rawStartDate = map['start_date']?.toString();
      final startDate = rawStartDate == null
          ? null
          : DateTime.tryParse(rawStartDate);

      if (reminderId == null ||
          reminderId.isEmpty ||
          timeOfDay == null ||
          timeOfDay.isEmpty ||
          startDate == null) {
        continue;
      }

      final scheduledAt = _nextScheduleTimeFromStartDate(
        startDate: startDate,
        timeOfDay: timeOfDay,
      );

      await scheduleTaskNotification(
        taskType: 'physical_activity',
        referenceId: reminderId,
        timeOfDay: timeOfDay,
        channelId: activityReminderChannelId,
        title: 'Pengingat Aktivitas',
        body: 'Saatnya melakukan aktivitas fisik Anda.',
        scheduledAt: scheduledAt,
      );
    }
  }

  DateTime _nextScheduleTimeFromStartDate({
    required DateTime startDate,
    required String timeOfDay,
  }) {
    final parts = timeOfDay.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final now = DateTime.now();
    var scheduledAt = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      hour,
      minute,
    );

    if (scheduledAt.isBefore(now)) {
      scheduledAt = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledAt.isBefore(now)) {
        scheduledAt = scheduledAt.add(const Duration(days: 1));
      }
    }

    return scheduledAt;
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

  AndroidNotificationSound? _androidSoundForChannel(
    String baseChannelId, {
    String? ringtoneId,
  }) {
    if (!_isReminderBaseChannel(baseChannelId)) {
      return null;
    }

    final resourceName = AlarmRingtones.androidResourceNameById(ringtoneId);
    if (resourceName == null || resourceName.isEmpty) {
      return null;
    }

    return RawResourceAndroidNotificationSound(resourceName);
  }

  Future<void> _ensureAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }

    await _deleteLegacyReminderChannels(android);

    await _createAndroidChannel(
      android: android,
      baseChannelId: medicineReminderChannelId,
      resolvedChannelId: _resolvedChannelId(
        baseChannelId: medicineReminderChannelId,
        ringtoneId: AppPreferences.notifMedicineRingtoneId,
      ),
      ringtoneId: AppPreferences.notifMedicineRingtoneId,
    );

    await _createAndroidChannel(
      android: android,
      baseChannelId: measurementReminderChannelId,
      resolvedChannelId: _resolvedChannelId(
        baseChannelId: measurementReminderChannelId,
        ringtoneId: AppPreferences.notifMeasurementRingtoneId,
      ),
      ringtoneId: AppPreferences.notifMeasurementRingtoneId,
    );

    await _createAndroidChannel(
      android: android,
      baseChannelId: activityReminderChannelId,
      resolvedChannelId: _resolvedChannelId(
        baseChannelId: activityReminderChannelId,
        ringtoneId: AppPreferences.notifActivityRingtoneId,
      ),
      ringtoneId: AppPreferences.notifActivityRingtoneId,
    );

    await _createAndroidChannel(
      android: android,
      baseChannelId: stockWarningChannelId,
      resolvedChannelId: stockWarningChannelId,
    );
    await _createAndroidChannel(
      android: android,
      baseChannelId: streakChannelId,
      resolvedChannelId: streakChannelId,
    );
    await _createAndroidChannel(
      android: android,
      baseChannelId: dailySummaryChannelId,
      resolvedChannelId: dailySummaryChannelId,
    );
  }

  Future<void> _ensureAndroidChannel({
    required String baseChannelId,
    required String resolvedChannelId,
    String? ringtoneId,
  }) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }

    await _createAndroidChannel(
      android: android,
      baseChannelId: baseChannelId,
      resolvedChannelId: resolvedChannelId,
      ringtoneId: ringtoneId,
    );
  }

  Future<void> _createAndroidChannel({
    required AndroidFlutterLocalNotificationsPlugin android,
    required String baseChannelId,
    required String resolvedChannelId,
    String? ringtoneId,
  }) async {
    // Android does NOT allow updating the `sound` of an existing notification
    // channel. To guarantee the correct ringtone is always applied, we delete
    // the channel first and then recreate it fresh.
    try {
      await android.deleteNotificationChannel(resolvedChannelId);
    } catch (_) {
      // Best-effort: ignore if channel didn't exist.
    }

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        resolvedChannelId,
        _channelName(baseChannelId),
        description: _channelDescription(baseChannelId, ringtoneId: ringtoneId),
        importance: _channelImportance(baseChannelId),
        playSound: true,
        sound: _androidSoundForChannel(baseChannelId, ringtoneId: ringtoneId),
        audioAttributesUsage: _isReminderBaseChannel(baseChannelId)
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
      ),
    );
  }

  Future<void> _deleteLegacyReminderChannels(
    AndroidFlutterLocalNotificationsPlugin android,
  ) async {
    final legacyBaseChannelIds = <String>{
      legacyMedicineReminderChannelId,
      legacyMedicineReminderChannelIdV2,
      legacyMedicineReminderChannelIdV1,
      legacyMedicineReminderChannelIdV0,
      legacyMeasurementReminderChannelId,
      legacyMeasurementReminderChannelIdV2,
      legacyMeasurementReminderChannelIdV1,
      legacyMeasurementReminderChannelIdV0,
      legacyActivityReminderChannelId,
      legacyActivityReminderChannelIdV2,
      legacyActivityReminderChannelIdV1,
      legacyActivityReminderChannelIdV0,
    };

    final allLegacyChannelIds = <String>{...legacyBaseChannelIds};
    for (final baseChannelId in legacyBaseChannelIds) {
      for (final option in AlarmRingtones.options) {
        allLegacyChannelIds.add(
          '${baseChannelId}__${_safeChannelSuffix(option.id)}',
        );
      }
    }

    for (final channelId in allLegacyChannelIds) {
      try {
        await android.deleteNotificationChannel(channelId);
      } catch (_) {
        // Best-effort cleanup only.
      }
    }
  }

  Importance _channelImportance(String baseChannelId) {
    switch (baseChannelId) {
      case medicineReminderChannelId:
        return Importance.max;
      case measurementReminderChannelId:
        return Importance.max;
      case activityReminderChannelId:
        return Importance.max;
      case stockWarningChannelId:
        return Importance.high;
      case streakChannelId:
        return Importance.defaultImportance;
      case dailySummaryChannelId:
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  String _baseChannelId(String requestedChannelId) {
    if (_isMedicineRequestedChannel(requestedChannelId)) {
      return medicineReminderChannelId;
    }
    if (_isMeasurementRequestedChannel(requestedChannelId)) {
      return measurementReminderChannelId;
    }
    if (_isActivityRequestedChannel(requestedChannelId)) {
      return activityReminderChannelId;
    }
    return requestedChannelId;
  }

  String? _ringtoneIdForBaseChannel(String baseChannelId) {
    switch (baseChannelId) {
      case medicineReminderChannelId:
        return AppPreferences.notifMedicineRingtoneId;
      case measurementReminderChannelId:
        return AppPreferences.notifMeasurementRingtoneId;
      case activityReminderChannelId:
        return AppPreferences.notifActivityRingtoneId;
      default:
        return null;
    }
  }

  String _resolvedChannelId({
    required String baseChannelId,
    required String? ringtoneId,
  }) {
    if (!_isReminderBaseChannel(baseChannelId)) {
      return baseChannelId;
    }

    final normalizedToneId = AlarmRingtones.normalizeId(ringtoneId);
    return '${baseChannelId}__${_safeChannelSuffix(normalizedToneId)}';
  }

  String _safeChannelSuffix(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  }

  bool _isReminderBaseChannel(String baseChannelId) {
    return baseChannelId == medicineReminderChannelId ||
        baseChannelId == measurementReminderChannelId ||
        baseChannelId == activityReminderChannelId;
  }

  bool _isMedicineRequestedChannel(String channelId) {
    return channelId == medicineReminderChannelId ||
        channelId == legacyMedicineReminderChannelId ||
        channelId == legacyMedicineReminderChannelIdV2 ||
        channelId == legacyMedicineReminderChannelIdV1 ||
        channelId == legacyMedicineReminderChannelIdV0 ||
        channelId.startsWith('${medicineReminderChannelId}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelId}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelIdV2}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelIdV1}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelIdV0}__');
  }

  bool _isMeasurementRequestedChannel(String channelId) {
    return channelId == measurementReminderChannelId ||
        channelId == legacyMeasurementReminderChannelId ||
        channelId == legacyMeasurementReminderChannelIdV2 ||
        channelId == legacyMeasurementReminderChannelIdV1 ||
        channelId == legacyMeasurementReminderChannelIdV0 ||
        channelId.startsWith('${measurementReminderChannelId}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelId}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelIdV2}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelIdV1}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelIdV0}__');
  }

  bool _isActivityRequestedChannel(String channelId) {
    return channelId == activityReminderChannelId ||
        channelId == legacyActivityReminderChannelId ||
        channelId == legacyActivityReminderChannelIdV2 ||
        channelId == legacyActivityReminderChannelIdV1 ||
        channelId == legacyActivityReminderChannelIdV0 ||
        channelId.startsWith('${activityReminderChannelId}__') ||
        channelId.startsWith('${legacyActivityReminderChannelId}__') ||
        channelId.startsWith('${legacyActivityReminderChannelIdV2}__') ||
        channelId.startsWith('${legacyActivityReminderChannelIdV1}__') ||
        channelId.startsWith('${legacyActivityReminderChannelIdV0}__');
  }

  String? _channelIdForTaskType(String taskType) {
    switch (taskType) {
      case 'medicine':
        return medicineReminderChannelId;
      case 'measurement':
        return measurementReminderChannelId;
      case 'physical_activity':
        return activityReminderChannelId;
      default:
        return null;
    }
  }

  List<AndroidScheduleMode> _androidScheduleModeCandidates({
    required String baseChannelId,
    required int snoozeIndex,
  }) {
    final candidates = <AndroidScheduleMode>[];

    // Snooze notifications should stay reliable while the app is closed.
    if (_isReminderBaseChannel(baseChannelId) && snoozeIndex > 0) {
      candidates.add(AndroidScheduleMode.alarmClock);
    }

    candidates.add(AndroidScheduleMode.exactAllowWhileIdle);
    candidates.add(AndroidScheduleMode.inexactAllowWhileIdle);

    return candidates;
  }

  bool _isInvalidSoundError(Object error) {
    if (error is! PlatformException) {
      return false;
    }

    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('invalid_sound') ||
        message.contains('invalid_sound') ||
        (message.contains('resource') &&
            message.contains('could not be found'));
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

  await _ensureSessionReadyForPayload(parsed.userId);

  if (!_isPayloadAllowedForCurrentSession(parsed)) {
    if (kDebugMode) {
      debugPrint(
        'Skip notification action due to user mismatch: ${parsed.userId}',
      );
    }
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
  // Payload formats:
  // v1: task|taskType|referenceId|HH:mm:ss|snoozeIndex
  // v2: taskv2|taskType|userId|referenceId|HH:mm:ss|snoozeIndex
  final parts = payload.split('|');
  if (parts.isEmpty) {
    return null;
  }

  final prefix = parts.first;
  if (prefix == NotificationService._scopedTaskPayloadPrefix) {
    if (parts.length < 5) {
      return null;
    }

    final taskType = parts[1].trim();
    final userId = parts[2].trim();
    final referenceId = parts[3].trim();
    final rawTimeOfDay = parts[4].trim();
    final snoozeIndex = parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0;

    if (taskType.isEmpty || userId.isEmpty || referenceId.isEmpty) {
      return null;
    }

    return _TaskPayload(
      taskType: taskType,
      userId: userId,
      referenceId: referenceId,
      timeOfDay: rawTimeOfDay.isEmpty ? null : rawTimeOfDay,
      snoozeIndex: snoozeIndex,
    );
  }

  if (parts.length < 3 ||
      prefix != NotificationService._legacyTaskPayloadPrefix) {
    return null;
  }

  final taskType = parts[1].trim();
  final referenceId = parts[2].trim();
  final rawTimeOfDay = parts.length > 3 ? parts[3].trim() : null;
  final snoozeIndex = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;

  if (taskType.isEmpty || referenceId.isEmpty) {
    return null;
  }

  return _TaskPayload(
    taskType: taskType,
    userId: null,
    referenceId: referenceId,
    timeOfDay: rawTimeOfDay?.isEmpty == true ? null : rawTimeOfDay,
    snoozeIndex: snoozeIndex,
  );
}

bool _isPayloadAllowedForCurrentSession(_TaskPayload parsed) {
  final payloadUserId = parsed.userId;
  if (payloadUserId == null || payloadUserId.isEmpty) {
    return false;
  }

  try {
    final activeUserId = Supabase.instance.client.auth.currentUser?.id;
    return activeUserId != null && activeUserId == payloadUserId;
  } catch (_) {
    return false;
  }
}

Future<void> _ensureSessionReadyForPayload(String? payloadUserId) async {
  if (payloadUserId == null || payloadUserId.isEmpty) {
    return;
  }

  for (var i = 0; i < 8; i++) {
    try {
      final activeUserId = Supabase.instance.client.auth.currentUser?.id;
      if (activeUserId == payloadUserId) {
        return;
      }
    } catch (_) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

class _TaskPayload {
  const _TaskPayload({
    required this.taskType,
    required this.userId,
    required this.referenceId,
    required this.timeOfDay,
    required this.snoozeIndex,
  });

  final String taskType;
  final String? userId;
  final String referenceId;
  final String? timeOfDay;
  final int snoozeIndex;
}
