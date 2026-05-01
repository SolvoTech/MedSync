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
import '../core/utils/reminder_time.dart';
import '../data/local/preferences/app_preferences.dart';
import '../data/remote/datasources/task_log_remote_datasource.dart';
import '../data/remote/supabase_client.dart';
import 'task_completion_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService implements TaskReminderScheduler {
  NotificationService();

  static const MethodChannel _systemSettingsChannel = MethodChannel(
    'med_syn/system_settings',
  );

  static const String markDoneActionId = 'mark_done';
  // v7 is intentionally new to recover from stale Android channels that may
  // persist previous sound/vibration settings from older installs/updates.
  static const String medicineReminderChannelId = 'medicine_reminders_v7';
  static const String legacyMedicineReminderChannelId = 'medicine_reminders_v6';
  static const String legacyMedicineReminderChannelIdV4 =
      'medicine_reminders_v5';
  static const String legacyMedicineReminderChannelIdV3 =
      'medicine_reminders_v4';
  static const String legacyMedicineReminderChannelIdV2 =
      'medicine_reminders_v3';
  static const String legacyMedicineReminderChannelIdV1 =
      'medicine_reminders_v2';
  static const String legacyMedicineReminderChannelIdV0 = 'medicine_reminders';
  static const String measurementReminderChannelId = 'measurement_reminders_v7';
  static const String legacyMeasurementReminderChannelId =
      'measurement_reminders_v6';
  static const String legacyMeasurementReminderChannelIdV4 =
      'measurement_reminders_v5';
  static const String legacyMeasurementReminderChannelIdV3 =
      'measurement_reminders_v4';
  static const String legacyMeasurementReminderChannelIdV2 =
      'measurement_reminders_v3';
  static const String legacyMeasurementReminderChannelIdV1 =
      'measurement_reminders_v2';
  static const String legacyMeasurementReminderChannelIdV0 =
      'measurement_reminders';
  static const String activityReminderChannelId = 'activity_reminders_v7';
  static const String legacyActivityReminderChannelId = 'activity_reminders_v6';
  static const String legacyActivityReminderChannelIdV4 =
      'activity_reminders_v5';
  static const String legacyActivityReminderChannelIdV3 =
      'activity_reminders_v4';
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
  static const String _scopedTaskOccurrencePayloadPrefix = 'taskv3';
  static const int _scheduledReminderSnoozeCount = 6;
  static const int _taskNotificationHorizonDays = 30;
  static const Duration _missedReminderCatchUpGrace = Duration(minutes: 5);
  static const Duration _nearTermScheduleLeadTime = Duration(seconds: 5);
  static const int _notificationFlagInsistent = 4;
  static const String _fallbackReminderRingtoneId =
      AlarmRingtones.defaultReminderRingtoneId;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final Int64List _reminderVibrationPattern = Int64List.fromList(<int>[
    0,
    900,
    350,
    900,
    350,
    1300,
  ]);

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
  }

  Future<void> applyRingtonePreferenceChanges() async {
    await _ensureAndroidChannels();
    await _syncReminderNotificationsToCurrentChannelConfig();
  }

  Future<void> syncTaskNotificationsWithCurrentPreferences() async {
    final client = SupabaseClientRef.maybeClient;
    final userId = _activeUserId();
    if (client == null || userId == null) {
      return;
    }

    await cancelStaleTaskNotificationsForActiveSession();
    await _cancelTaskNotificationsForActiveUser(userId);

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
  }) async {
    final baseChannelId = _baseChannelId(channelId);
    final preferredRingtoneId = _ringtoneIdForBaseChannel(baseChannelId);
    final preferredResolvedChannelId = _resolvedChannelId(
      baseChannelId: baseChannelId,
      ringtoneId: preferredRingtoneId,
    );

    final activeChannelConfig = await _ensureAndroidChannelWithFallback(
      baseChannelId: baseChannelId,
      preferredResolvedChannelId: preferredResolvedChannelId,
      preferredRingtoneId: preferredRingtoneId,
    );

    NotificationDetails buildDetails({
      required String resolvedChannelId,
      required String? ringtoneId,
    }) {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          resolvedChannelId,
          _channelName(baseChannelId),
          channelDescription: _channelDescription(
            baseChannelId,
            ringtoneId: ringtoneId,
          ),
          importance: _channelImportance(baseChannelId),
          channelBypassDnd: _isReminderBaseChannel(baseChannelId),
          priority: Priority.high,
          playSound: true,
          sound: _androidSoundForChannel(baseChannelId, ringtoneId: ringtoneId),
          enableVibration: true,
          vibrationPattern: _androidVibrationPatternForChannel(baseChannelId),
          fullScreenIntent: _isReminderBaseChannel(baseChannelId),
          additionalFlags: _androidAdditionalFlagsForChannel(baseChannelId),
          audioAttributesUsage: _isReminderBaseChannel(baseChannelId)
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
          category: _isReminderBaseChannel(baseChannelId)
              ? AndroidNotificationCategory.alarm
              : null,
          visibility: NotificationVisibility.public,
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

    var scheduleDate = tz.TZDateTime.from(scheduledAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    final resolvedScheduleDate = resolveNotificationScheduleTime(
      scheduledAt: scheduleDate,
      now: now,
      repeatDaily: repeatDaily,
      isReminder: _isReminderBaseChannel(baseChannelId),
    );

    if (kDebugMode) {
      debugPrint('[Notification] Scheduling id=$id');
      debugPrint('[Notification]   input scheduledAt=$scheduledAt');
      debugPrint('[Notification]   tz.local=${tz.local.name}');
      debugPrint('[Notification]   tzScheduleDate=$scheduleDate');
      debugPrint('[Notification]   now=$now');
      debugPrint('[Notification]   repeatDaily=$repeatDaily');
      debugPrint(
        '[Notification]   channel=${activeChannelConfig.resolvedChannelId}',
      );
      debugPrint('[Notification]   ringtone=${activeChannelConfig.ringtoneId}');
    }

    if (resolvedScheduleDate == null) {
      if (kDebugMode) {
        debugPrint('[Notification]   ⚠️ SKIPPED — scheduleDate is in the past');
      }
      return;
    }
    scheduleDate = tz.TZDateTime.from(resolvedScheduleDate, tz.local);

    final modeCandidates = _androidScheduleModeCandidates(
      baseChannelId: baseChannelId,
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
          buildDetails(
            resolvedChannelId: activeChannelConfig.resolvedChannelId,
            ringtoneId: activeChannelConfig.ringtoneId,
          ),
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
          final fallbackRingtoneId = _fallbackRingtoneIdForBaseChannel(
            baseChannelId,
            preferredRingtoneId: activeChannelConfig.ringtoneId,
          );
          if (kDebugMode) {
            debugPrint(
              '[NotificationService] Fallback to reminder-safe sound: ${error.message}',
            );
          }

          if (fallbackRingtoneId != null) {
            final fallbackResolvedChannelId = _resolvedChannelId(
              baseChannelId: baseChannelId,
              ringtoneId: fallbackRingtoneId,
            );

            final fallbackChannelConfig =
                await _ensureAndroidChannelWithFallback(
                  baseChannelId: baseChannelId,
                  preferredResolvedChannelId: fallbackResolvedChannelId,
                  preferredRingtoneId: fallbackRingtoneId,
                );

            try {
              await _plugin.zonedSchedule(
                id,
                title,
                body,
                scheduleDate,
                buildDetails(
                  resolvedChannelId: fallbackChannelConfig.resolvedChannelId,
                  ringtoneId: fallbackChannelConfig.ringtoneId,
                ),
                payload: payload,
                androidScheduleMode: mode,
                matchDateTimeComponents: repeatDaily
                    ? DateTimeComponents.time
                    : null,
              );
              scheduled = true;
              if (kDebugMode) {
                debugPrint(
                  '[Notification]   mode=$mode (safe reminder sound fallback)',
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

  Future<bool> scheduleTaskNotification({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
    required String channelId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final activeUserId = _activeUserId();
    if (activeUserId == null || activeUserId.isEmpty) {
      return false;
    }

    final normalizedTimeOfDay =
        canonicalReminderTimeOfDay(timeOfDay) ?? timeOfDay.trim();
    if (normalizedTimeOfDay.isEmpty) {
      return false;
    }

    final baseChannelId = _baseChannelId(channelId);
    final baseScheduledAt = resolveTaskReminderOccurrenceScheduleTime(
      scheduledAt: scheduledAt,
      now: DateTime.now(),
      isReminder: _isReminderBaseChannel(baseChannelId),
    );
    if (baseScheduledAt == null) {
      return false;
    }

    final basePayload = _buildTaskPayload(
      taskType: taskType,
      userId: activeUserId,
      referenceId: referenceId,
      timeOfDay: normalizedTimeOfDay,
      scheduledAt: scheduledAt,
      snoozeIndex: 0,
    );

    // Task reminders are one-shot per pending occurrence. Daily repeating
    // notifications cannot safely skip a date after today's task is completed.
    await scheduleNotification(
      id: stableNotificationId(basePayload),
      channelId: channelId,
      title: title,
      body: body,
      scheduledAt: baseScheduledAt,
      payload: basePayload,
      repeatDaily: false,
    );

    // Schedule snooze notifications (5 minutes apart, up to 30 mins).
    for (int i = 1; i <= _scheduledReminderSnoozeCount; i++) {
      final snoozeTime = baseScheduledAt.add(Duration(minutes: 5 * i));
      final snoozePayload = _buildTaskPayload(
        taskType: taskType,
        userId: activeUserId,
        referenceId: referenceId,
        timeOfDay: normalizedTimeOfDay,
        scheduledAt: scheduledAt,
        snoozeIndex: i,
      );
      await scheduleNotification(
        id: stableNotificationId(snoozePayload),
        channelId: channelId,
        title: title,
        body: '$body (Peringatan ke-$i)',
        scheduledAt: snoozeTime,
        payload: snoozePayload,
        repeatDaily: false,
      );
    }

    return true;
  }

  @override
  Future<void> advanceScheduleToTomorrow({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
    DateTime? scheduledAt,
  }) async {
    final channelId =
        _channelIdForTaskType(taskType) ?? medicineReminderChannelId;
    final normalizedTimeOfDay =
        canonicalReminderTimeOfDay(timeOfDay) ?? timeOfDay.trim();
    if (normalizedTimeOfDay.isEmpty) {
      return;
    }

    final pendingList = await _plugin.pendingNotificationRequests();
    final now = tz.TZDateTime.now(tz.local);
    final activeUserId = _activeUserId();
    final occurrenceScheduledAt =
        scheduledAt ??
        reminderScheduledAtForDay(day: now, timeOfDay: normalizedTimeOfDay);
    final matchingPending = <PendingNotificationRequest>[];

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
        timeOfDay: normalizedTimeOfDay,
      )) {
        continue;
      }

      if (!_isPayloadCancelableByActiveSession(parsed, activeUserId)) {
        continue;
      }

      if (!_matchesOccurrenceDay(parsed, occurrenceScheduledAt)) {
        continue;
      }

      matchingPending.add(pending);
    }

    for (final pending in matchingPending) {
      await _plugin.cancel(pending.id);
    }

    await _cancelTaskNotificationsByStableIds(
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: normalizedTimeOfDay,
      scheduledAt: occurrenceScheduledAt,
      activeUserId: activeUserId,
    );

    if (!_notificationsEnabledForTaskType(taskType)) {
      return;
    }

    if (activeUserId == null || activeUserId.isEmpty) {
      return;
    }

    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      return;
    }

    final nextPending = await _nextPendingTaskForSlot(
      client: client,
      userId: activeUserId,
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: normalizedTimeOfDay,
      after: _startOfLocalDay(
        occurrenceScheduledAt ?? now,
      ).add(const Duration(days: 1)),
    );
    if (nextPending == null) {
      return;
    }

    final reminderText = _reminderTextForReschedule(
      taskType: taskType,
      matchingPending: matchingPending,
    );

    await scheduleTaskNotification(
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: normalizedTimeOfDay,
      channelId: channelId,
      title: reminderText.title,
      body: reminderText.body,
      scheduledAt: nextPending.scheduledAt,
    );
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

      if (!_isPayloadCancelableByActiveSession(parsed, activeUserId)) {
        continue;
      }

      await _plugin.cancel(pending.id);
    }

    await _cancelTaskNotificationsByStableIds(
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: timeOfDay,
      activeUserId: activeUserId,
    );
  }

  Future<void> _cancelTaskNotificationsByStableIds({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
    DateTime? scheduledAt,
    required String? activeUserId,
  }) async {
    final normalizedTimeOfDay =
        canonicalReminderTimeOfDay(timeOfDay) ?? timeOfDay.trim();
    if (normalizedTimeOfDay.isEmpty) {
      return;
    }

    final ids = taskNotificationIdsForSlot(
      taskType: taskType,
      activeUserId: activeUserId,
      referenceId: referenceId,
      timeOfDay: normalizedTimeOfDay,
      scheduledAt: scheduledAt,
      includeCurrentRuntimeHashIds: true,
    );

    for (final id in ids) {
      await _plugin.cancel(id);
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

  Future<void> _cancelTaskNotificationsForActiveUser(
    String activeUserId,
  ) async {
    final pendingList = await _plugin.pendingNotificationRequests();

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
        continue;
      }

      await _plugin.cancel(pending.id);
    }
  }

  Future<void> cancelStaleTaskNotificationsForActiveSession() async {
    final pendingList = await _plugin.pendingNotificationRequests();
    final activeUserId = _activeUserId();
    if (activeUserId == null || activeUserId.isEmpty) {
      return;
    }

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
    await syncTaskNotificationsWithCurrentPreferences();
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
    return _taskPayloadMatchesSlot(
      parsed,
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: timeOfDay,
    );
  }

  bool _isPayloadCancelableByActiveSession(
    _TaskPayload payload,
    String? activeUserId,
  ) {
    final payloadUserId = payload.userId;
    if (payloadUserId == null || payloadUserId.isEmpty) {
      return true;
    }

    return activeUserId != null &&
        activeUserId.isNotEmpty &&
        payloadUserId == activeUserId;
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

  _ReminderText _reminderTextForReschedule({
    required String taskType,
    required List<PendingNotificationRequest> matchingPending,
  }) {
    final defaultText = _defaultReminderTextForTaskType(taskType);
    PendingNotificationRequest? preferred;

    for (final pending in matchingPending) {
      final payload = pending.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }

      final parsed = _parseTaskPayload(payload);
      if (parsed == null) {
        continue;
      }

      preferred ??= pending;
      if (parsed.snoozeIndex == 0) {
        preferred = pending;
        break;
      }
    }

    final title = preferred?.title ?? defaultText.title;
    final body = _removeSnoozeSuffix(preferred?.body ?? defaultText.body);

    return _ReminderText(title: title, body: body);
  }

  _ReminderText _defaultReminderTextForTaskType(String taskType) {
    switch (taskType) {
      case 'medicine':
        return const _ReminderText(
          title: 'Pengingat Obat',
          body: 'Waktunya minum obat Anda.',
        );
      case 'measurement':
        return const _ReminderText(
          title: 'Pengingat Pengukuran',
          body: 'Saatnya melakukan pengukuran kesehatan Anda.',
        );
      case 'physical_activity':
        return const _ReminderText(
          title: 'Pengingat Aktivitas',
          body: 'Saatnya melakukan aktivitas fisik Anda.',
        );
      default:
        return const _ReminderText(
          title: 'Pengingat MedSync',
          body: 'Saatnya tugas Anda.',
        );
    }
  }

  String _removeSnoozeSuffix(String body) {
    return body.replaceFirst(RegExp(r'\s*\(Peringatan ke-\d+\)$'), '');
  }

  bool _notificationsEnabledForTaskType(String taskType) {
    switch (taskType) {
      case 'medicine':
        return AppPreferences.notifMedicine;
      case 'measurement':
        return AppPreferences.notifMeasurement;
      case 'physical_activity':
        return AppPreferences.notifActivity;
      default:
        return true;
    }
  }

  DateTime _startOfLocalDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool _matchesOccurrenceDay(
    _TaskPayload parsed,
    DateTime? occurrenceScheduledAt,
  ) {
    final parsedScheduledAt = parsed.scheduledAt;
    if (parsedScheduledAt == null || occurrenceScheduledAt == null) {
      return true;
    }

    return _startOfLocalDay(parsedScheduledAt) ==
        _startOfLocalDay(occurrenceScheduledAt);
  }

  Future<_PendingTaskOccurrence?> _nextPendingTaskForSlot({
    required SupabaseClient client,
    required String userId,
    required String taskType,
    required String referenceId,
    required String timeOfDay,
    required DateTime after,
  }) async {
    final end = after.add(const Duration(days: _taskNotificationHorizonDays));
    final rows = await client
        .from('task_logs')
        .select('scheduled_at')
        .eq('owner_id', userId)
        .eq('task_type', taskType)
        .eq('reference_id', referenceId)
        .eq('status', 'pending')
        .gte('scheduled_at', after.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('scheduled_at', ascending: true)
        .limit(_taskNotificationHorizonDays * 8);

    for (final row in (rows as List<dynamic>)) {
      final occurrence = _pendingOccurrenceFromRow(row, timeOfDay);
      if (occurrence != null) {
        return occurrence;
      }
    }

    return null;
  }

  Future<void> _schedulePendingTaskNotificationsForSlot({
    required SupabaseClient client,
    required String userId,
    required String taskType,
    required String referenceId,
    required String timeOfDay,
    required String channelId,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final start = _startOfLocalDay(now);
    final end = start.add(const Duration(days: _taskNotificationHorizonDays));

    final rows = await client
        .from('task_logs')
        .select('scheduled_at')
        .eq('owner_id', userId)
        .eq('task_type', taskType)
        .eq('reference_id', referenceId)
        .eq('status', 'pending')
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('scheduled_at', ascending: true)
        .limit(_taskNotificationHorizonDays * 8);

    for (final row in (rows as List<dynamic>)) {
      final occurrence = _pendingOccurrenceFromRow(row, timeOfDay);
      if (occurrence == null) {
        continue;
      }

      final scheduled = await scheduleTaskNotification(
        taskType: taskType,
        referenceId: referenceId,
        timeOfDay: timeOfDay,
        channelId: channelId,
        title: title,
        body: body,
        scheduledAt: occurrence.scheduledAt,
      );
      if (scheduled) {
        return;
      }
    }
  }

  _PendingTaskOccurrence? _pendingOccurrenceFromRow(
    Object? row,
    String timeOfDay,
  ) {
    if (row is! Map<String, dynamic>) {
      return null;
    }

    final rawScheduledAt = row['scheduled_at']?.toString();
    DateTime? scheduledAt;
    if (rawScheduledAt != null) {
      try {
        scheduledAt = parseReminderScheduledAt(rawScheduledAt);
      } catch (_) {
        scheduledAt = null;
      }
    }
    if (scheduledAt == null ||
        !reminderTimesMatch(
          reminderTimeOfDayFromDateTime(scheduledAt),
          timeOfDay,
        )) {
      return null;
    }

    return _PendingTaskOccurrence(scheduledAt: scheduledAt);
  }

  Future<void> _scheduleActiveMedicineTaskNotifications({
    required SupabaseClient client,
    required String userId,
  }) async {
    final scheduleRows = await client
        .from('medicine_schedules')
        .select('id')
        .eq('owner_id', userId)
        .eq('is_active', true);

    for (final row in (scheduleRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final scheduleId = map['id']?.toString();

      if (scheduleId == null || scheduleId.isEmpty) {
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

        await _schedulePendingTaskNotificationsForSlot(
          client: client,
          userId: userId,
          taskType: 'medicine',
          referenceId: scheduleId,
          timeOfDay: timeOfDay,
          channelId: medicineReminderChannelId,
          title: 'Pengingat Obat',
          body: 'Waktunya minum obat Anda.',
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
        .select('id, time_of_day')
        .eq('owner_id', userId)
        .eq('is_active', true)
        .eq('notification_enabled', true)
        .order('time_of_day', ascending: true);

    for (final row in (rows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final reminderId = map['id']?.toString();
      final timeOfDay = map['time_of_day']?.toString();

      if (reminderId == null ||
          reminderId.isEmpty ||
          timeOfDay == null ||
          timeOfDay.isEmpty) {
        continue;
      }

      await _schedulePendingTaskNotificationsForSlot(
        client: client,
        userId: userId,
        taskType: 'measurement',
        referenceId: reminderId,
        timeOfDay: timeOfDay,
        channelId: measurementReminderChannelId,
        title: 'Pengingat Pengukuran',
        body: 'Saatnya melakukan pengukuran kesehatan Anda.',
      );
    }
  }

  Future<void> _scheduleActiveActivityTaskNotifications({
    required SupabaseClient client,
    required String userId,
  }) async {
    final rows = await client
        .from('physical_activity_reminders')
        .select('id, time_of_day')
        .eq('owner_id', userId)
        .eq('is_active', true)
        .eq('notification_enabled', true)
        .order('time_of_day', ascending: true);

    for (final row in (rows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final reminderId = map['id']?.toString();
      final timeOfDay = map['time_of_day']?.toString();

      if (reminderId == null ||
          reminderId.isEmpty ||
          timeOfDay == null ||
          timeOfDay.isEmpty) {
        continue;
      }

      await _schedulePendingTaskNotificationsForSlot(
        client: client,
        userId: userId,
        taskType: 'physical_activity',
        referenceId: reminderId,
        timeOfDay: timeOfDay,
        channelId: activityReminderChannelId,
        title: 'Pengingat Aktivitas',
        body: 'Saatnya melakukan aktivitas fisik Anda.',
      );
    }
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

  Int64List? _androidVibrationPatternForChannel(String baseChannelId) {
    if (!_isReminderBaseChannel(baseChannelId)) {
      return null;
    }

    return _reminderVibrationPattern;
  }

  Int32List? _androidAdditionalFlagsForChannel(String baseChannelId) {
    if (!_isReminderBaseChannel(baseChannelId)) {
      return null;
    }

    return Int32List.fromList(<int>[_notificationFlagInsistent]);
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

    await _ensureAndroidChannelWithFallback(
      baseChannelId: medicineReminderChannelId,
      preferredResolvedChannelId: _resolvedChannelId(
        baseChannelId: medicineReminderChannelId,
        ringtoneId: AppPreferences.notifMedicineRingtoneId,
      ),
      preferredRingtoneId: AppPreferences.notifMedicineRingtoneId,
    );

    await _ensureAndroidChannelWithFallback(
      baseChannelId: measurementReminderChannelId,
      preferredResolvedChannelId: _resolvedChannelId(
        baseChannelId: measurementReminderChannelId,
        ringtoneId: AppPreferences.notifMeasurementRingtoneId,
      ),
      preferredRingtoneId: AppPreferences.notifMeasurementRingtoneId,
    );

    await _ensureAndroidChannelWithFallback(
      baseChannelId: activityReminderChannelId,
      preferredResolvedChannelId: _resolvedChannelId(
        baseChannelId: activityReminderChannelId,
        ringtoneId: AppPreferences.notifActivityRingtoneId,
      ),
      preferredRingtoneId: AppPreferences.notifActivityRingtoneId,
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

  Future<_AndroidChannelConfig> _ensureAndroidChannelWithFallback({
    required String baseChannelId,
    required String preferredResolvedChannelId,
    required String? preferredRingtoneId,
  }) async {
    if (!_isReminderBaseChannel(baseChannelId)) {
      await _ensureAndroidChannel(
        baseChannelId: baseChannelId,
        resolvedChannelId: preferredResolvedChannelId,
        ringtoneId: preferredRingtoneId,
      );
      return _AndroidChannelConfig(
        resolvedChannelId: preferredResolvedChannelId,
        ringtoneId: preferredRingtoneId,
      );
    }

    PlatformException? lastInvalidSoundError;
    for (final ringtoneId in _reminderRingtoneFallbackCandidates(
      preferredRingtoneId,
    )) {
      final resolvedChannelId = ringtoneId == preferredRingtoneId
          ? preferredResolvedChannelId
          : _resolvedChannelId(
              baseChannelId: baseChannelId,
              ringtoneId: ringtoneId,
            );

      try {
        await _ensureAndroidChannel(
          baseChannelId: baseChannelId,
          resolvedChannelId: resolvedChannelId,
          ringtoneId: ringtoneId,
        );

        if (kDebugMode && ringtoneId != preferredRingtoneId) {
          debugPrint(
            '[NotificationService] Android sound fallback applied: '
            '$preferredRingtoneId -> $ringtoneId',
          );
        }

        return _AndroidChannelConfig(
          resolvedChannelId: resolvedChannelId,
          ringtoneId: ringtoneId,
        );
      } on PlatformException catch (error) {
        if (!_isInvalidSoundError(error)) {
          rethrow;
        }

        lastInvalidSoundError = error;
        if (kDebugMode) {
          debugPrint(
            '[NotificationService] Invalid Android sound "$ringtoneId": '
            '${error.message}',
          );
        }
      }
    }

    throw lastInvalidSoundError ??
        PlatformException(
          code: 'invalid_sound',
          message: 'No valid Android reminder sound could be resolved.',
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
        bypassDnd: _isReminderBaseChannel(baseChannelId),
        playSound: true,
        sound: _androidSoundForChannel(baseChannelId, ringtoneId: ringtoneId),
        enableVibration: true,
        vibrationPattern: _androidVibrationPatternForChannel(baseChannelId),
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
      legacyMedicineReminderChannelIdV4,
      legacyMedicineReminderChannelIdV3,
      legacyMedicineReminderChannelIdV2,
      legacyMedicineReminderChannelIdV1,
      legacyMedicineReminderChannelIdV0,
      legacyMeasurementReminderChannelId,
      legacyMeasurementReminderChannelIdV4,
      legacyMeasurementReminderChannelIdV3,
      legacyMeasurementReminderChannelIdV2,
      legacyMeasurementReminderChannelIdV1,
      legacyMeasurementReminderChannelIdV0,
      legacyActivityReminderChannelId,
      legacyActivityReminderChannelIdV4,
      legacyActivityReminderChannelIdV3,
      legacyActivityReminderChannelIdV2,
      legacyActivityReminderChannelIdV1,
      legacyActivityReminderChannelIdV0,
    };

    final allLegacyChannelIds = <String>{...legacyBaseChannelIds};
    for (final baseChannelId in legacyBaseChannelIds) {
      for (final ringtoneId in AlarmRingtones.channelCleanupRingtoneIds) {
        allLegacyChannelIds.add(
          '${baseChannelId}__${_safeChannelSuffix(ringtoneId)}',
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

  String? _fallbackRingtoneIdForBaseChannel(
    String baseChannelId, {
    required String? preferredRingtoneId,
  }) {
    if (!_isReminderBaseChannel(baseChannelId)) {
      return null;
    }

    final normalizedPreferred = AlarmRingtones.normalizeId(preferredRingtoneId);
    if (normalizedPreferred == AlarmRingtones.systemDefault) {
      return null;
    }

    if (normalizedPreferred != _fallbackReminderRingtoneId) {
      return _fallbackReminderRingtoneId;
    }

    return AlarmRingtones.systemDefault;
  }

  List<String> _reminderRingtoneFallbackCandidates(
    String? preferredRingtoneId,
  ) {
    final candidates = <String>[];

    void add(String? ringtoneId) {
      final normalized = AlarmRingtones.normalizeId(ringtoneId);
      if (!candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    add(preferredRingtoneId);
    add(_fallbackReminderRingtoneId);
    add(AlarmRingtones.systemDefault);

    return candidates;
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
        channelId == legacyMedicineReminderChannelIdV4 ||
        channelId == legacyMedicineReminderChannelIdV3 ||
        channelId == legacyMedicineReminderChannelIdV2 ||
        channelId == legacyMedicineReminderChannelIdV1 ||
        channelId == legacyMedicineReminderChannelIdV0 ||
        channelId.startsWith('${medicineReminderChannelId}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelId}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelIdV4}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelIdV3}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelIdV2}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelIdV1}__') ||
        channelId.startsWith('${legacyMedicineReminderChannelIdV0}__');
  }

  bool _isMeasurementRequestedChannel(String channelId) {
    return channelId == measurementReminderChannelId ||
        channelId == legacyMeasurementReminderChannelId ||
        channelId == legacyMeasurementReminderChannelIdV4 ||
        channelId == legacyMeasurementReminderChannelIdV3 ||
        channelId == legacyMeasurementReminderChannelIdV2 ||
        channelId == legacyMeasurementReminderChannelIdV1 ||
        channelId == legacyMeasurementReminderChannelIdV0 ||
        channelId.startsWith('${measurementReminderChannelId}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelId}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelIdV4}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelIdV3}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelIdV2}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelIdV1}__') ||
        channelId.startsWith('${legacyMeasurementReminderChannelIdV0}__');
  }

  bool _isActivityRequestedChannel(String channelId) {
    return channelId == activityReminderChannelId ||
        channelId == legacyActivityReminderChannelId ||
        channelId == legacyActivityReminderChannelIdV4 ||
        channelId == legacyActivityReminderChannelIdV3 ||
        channelId == legacyActivityReminderChannelIdV2 ||
        channelId == legacyActivityReminderChannelIdV1 ||
        channelId == legacyActivityReminderChannelIdV0 ||
        channelId.startsWith('${activityReminderChannelId}__') ||
        channelId.startsWith('${legacyActivityReminderChannelId}__') ||
        channelId.startsWith('${legacyActivityReminderChannelIdV4}__') ||
        channelId.startsWith('${legacyActivityReminderChannelIdV3}__') ||
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
  }) {
    final candidates = <AndroidScheduleMode>[];

    // Reminder alarms should stay reliable while the app is closed/killed.
    if (_isReminderBaseChannel(baseChannelId)) {
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

class _AndroidChannelConfig {
  const _AndroidChannelConfig({
    required this.resolvedChannelId,
    required this.ringtoneId,
  });

  final String resolvedChannelId;
  final String? ringtoneId;
}

class _PendingTaskOccurrence {
  const _PendingTaskOccurrence({required this.scheduledAt});

  final DateTime scheduledAt;
}

class _ReminderText {
  const _ReminderText({required this.title, required this.body});

  final String title;
  final String body;
}

@visibleForTesting
Set<int> taskNotificationIdsForSlot({
  required String taskType,
  required String? activeUserId,
  required String referenceId,
  required String timeOfDay,
  DateTime? scheduledAt,
  bool includeCurrentRuntimeHashIds = false,
}) {
  final normalizedTimeOfDay =
      canonicalReminderTimeOfDay(timeOfDay) ?? timeOfDay.trim();
  if (normalizedTimeOfDay.isEmpty) {
    return const <int>{};
  }

  final ids = <int>{};

  void addIds(String? userId) {
    for (
      var snoozeIndex = 0;
      snoozeIndex <= NotificationService._scheduledReminderSnoozeCount;
      snoozeIndex++
    ) {
      final payload = _buildTaskPayload(
        taskType: taskType,
        userId: userId,
        referenceId: referenceId,
        timeOfDay: normalizedTimeOfDay,
        snoozeIndex: snoozeIndex,
      );
      ids.add(stableNotificationId(payload));
      if (includeCurrentRuntimeHashIds) {
        ids.add(_currentRuntimeNotificationId(payload));
      }

      if (userId == null || scheduledAt == null) {
        continue;
      }

      final occurrencePayload = _buildTaskPayload(
        taskType: taskType,
        userId: userId,
        referenceId: referenceId,
        timeOfDay: normalizedTimeOfDay,
        scheduledAt: scheduledAt,
        snoozeIndex: snoozeIndex,
      );
      ids.add(stableNotificationId(occurrencePayload));
      if (includeCurrentRuntimeHashIds) {
        ids.add(_currentRuntimeNotificationId(occurrencePayload));
      }
    }
  }

  addIds(activeUserId);
  addIds(null);

  return ids;
}

@visibleForTesting
bool taskNotificationPayloadMatchesSlot({
  required String payload,
  required String taskType,
  required String referenceId,
  required String timeOfDay,
}) {
  final parsed = _parseTaskPayload(payload);
  if (parsed == null) {
    return false;
  }

  return _taskPayloadMatchesSlot(
    parsed,
    taskType: taskType,
    referenceId: referenceId,
    timeOfDay: timeOfDay,
  );
}

bool _taskPayloadMatchesSlot(
  _TaskPayload parsed, {
  required String taskType,
  required String referenceId,
  required String timeOfDay,
}) {
  return parsed.taskType == taskType &&
      parsed.referenceId == referenceId &&
      reminderTimesMatch(parsed.timeOfDay, timeOfDay);
}

@visibleForTesting
DateTime? resolveNotificationScheduleTime({
  required DateTime scheduledAt,
  required DateTime now,
  required bool repeatDaily,
  required bool isReminder,
}) {
  if (!scheduledAt.isBefore(now)) {
    return scheduledAt;
  }

  if (!repeatDaily) {
    return null;
  }

  final missedBy = now.difference(scheduledAt);
  if (isReminder &&
      !missedBy.isNegative &&
      missedBy <= NotificationService._missedReminderCatchUpGrace) {
    return now.add(NotificationService._nearTermScheduleLeadTime);
  }

  // For recurring notifications, keep the original clock time. The native
  // scheduler will calculate the next matching daily occurrence.
  return scheduledAt;
}

@visibleForTesting
DateTime? resolveTaskReminderOccurrenceScheduleTime({
  required DateTime scheduledAt,
  required DateTime now,
  required bool isReminder,
}) {
  if (!scheduledAt.isBefore(now)) {
    return scheduledAt;
  }

  final missedBy = now.difference(scheduledAt);
  if (isReminder &&
      !missedBy.isNegative &&
      missedBy <= NotificationService._missedReminderCatchUpGrace) {
    return now.add(NotificationService._nearTermScheduleLeadTime);
  }

  return null;
}

int stableNotificationId(String seed) {
  const fnvOffsetBasis = 0x811c9dc5;
  const fnvPrime = 0x01000193;
  var hash = fnvOffsetBasis;

  for (final codeUnit in seed.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * fnvPrime) & 0xffffffff;
  }

  return hash & 0x7fffffff;
}

int _currentRuntimeNotificationId(String seed) {
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
    await TaskCompletionService(
      taskLogStore: TaskLogRemoteDataSource(),
      reminderScheduler: NotificationService(),
    ).markReminderDoneAndSilence(
      taskType: parsed.taskType,
      referenceId: parsed.referenceId,
      timeOfDay: parsed.timeOfDay,
      scheduledAt: parsed.scheduledAt,
    );
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Failed to mark task from notification action: $error');
    }
  }
}

String _buildTaskPayload({
  required String taskType,
  required String? userId,
  required String referenceId,
  required String timeOfDay,
  DateTime? scheduledAt,
  required int snoozeIndex,
}) {
  final normalizedTimeOfDay =
      canonicalReminderTimeOfDay(timeOfDay) ?? timeOfDay.trim();

  if (userId == null || userId.isEmpty) {
    return '${NotificationService._legacyTaskPayloadPrefix}|$taskType|$referenceId|$normalizedTimeOfDay|$snoozeIndex';
  }

  if (scheduledAt != null) {
    return '${NotificationService._scopedTaskOccurrencePayloadPrefix}|$taskType|$userId|$referenceId|$normalizedTimeOfDay|${scheduledAt.toIso8601String()}|$snoozeIndex';
  }

  return '${NotificationService._scopedTaskPayloadPrefix}|$taskType|$userId|$referenceId|$normalizedTimeOfDay|$snoozeIndex';
}

_TaskPayload? _parseTaskPayload(String payload) {
  // Payload formats:
  // v1: task|taskType|referenceId|HH:mm[:ss]|snoozeIndex
  // v2: taskv2|taskType|userId|referenceId|HH:mm[:ss]|snoozeIndex
  // v3: taskv3|taskType|userId|referenceId|HH:mm[:ss]|scheduledAtIso|snoozeIndex
  final parts = payload.split('|');
  if (parts.isEmpty) {
    return null;
  }

  final prefix = parts.first;
  if (prefix == NotificationService._scopedTaskOccurrencePayloadPrefix) {
    if (parts.length < 6) {
      return null;
    }

    final taskType = parts[1].trim();
    final userId = parts[2].trim();
    final referenceId = parts[3].trim();
    final rawTimeOfDay = parts[4].trim();
    final rawScheduledAt = parts[5].trim();
    DateTime? scheduledAt;
    if (rawScheduledAt.isNotEmpty) {
      try {
        scheduledAt = parseReminderScheduledAt(rawScheduledAt);
      } catch (_) {
        scheduledAt = null;
      }
    }
    final snoozeIndex = parts.length > 6 ? int.tryParse(parts[6]) ?? 0 : 0;
    final normalizedTimeOfDay = canonicalReminderTimeOfDay(rawTimeOfDay);

    if (taskType.isEmpty ||
        userId.isEmpty ||
        referenceId.isEmpty ||
        scheduledAt == null) {
      return null;
    }

    return _TaskPayload(
      taskType: taskType,
      userId: userId,
      referenceId: referenceId,
      timeOfDay: normalizedTimeOfDay,
      scheduledAt: scheduledAt,
      snoozeIndex: snoozeIndex,
    );
  }

  if (prefix == NotificationService._scopedTaskPayloadPrefix) {
    if (parts.length < 5) {
      return null;
    }

    final taskType = parts[1].trim();
    final userId = parts[2].trim();
    final referenceId = parts[3].trim();
    final rawTimeOfDay = parts[4].trim();
    final snoozeIndex = parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0;
    final normalizedTimeOfDay = canonicalReminderTimeOfDay(rawTimeOfDay);

    if (taskType.isEmpty || userId.isEmpty || referenceId.isEmpty) {
      return null;
    }

    return _TaskPayload(
      taskType: taskType,
      userId: userId,
      referenceId: referenceId,
      timeOfDay: normalizedTimeOfDay,
      scheduledAt: null,
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
  final normalizedTimeOfDay = canonicalReminderTimeOfDay(rawTimeOfDay);

  if (taskType.isEmpty || referenceId.isEmpty) {
    return null;
  }

  return _TaskPayload(
    taskType: taskType,
    userId: null,
    referenceId: referenceId,
    timeOfDay: normalizedTimeOfDay,
    scheduledAt: null,
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
    required this.scheduledAt,
    required this.snoozeIndex,
  });

  final String taskType;
  final String? userId;
  final String referenceId;
  final String? timeOfDay;
  final DateTime? scheduledAt;
  final int snoozeIndex;
}
