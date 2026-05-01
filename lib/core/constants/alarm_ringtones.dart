class AlarmRingtoneOption {
  const AlarmRingtoneOption({
    required this.id,
    required this.labelEn,
    required this.labelId,
    required this.androidResourceName,
  });

  final String id;
  final String labelEn;
  final String labelId;
  final String? androidResourceName;
}

class AlarmRingtones {
  const AlarmRingtones._();

  // Legacy IDs are retained so saved preferences from older builds resolve to
  // the default bundled tone instead of falling back to the platform default.
  static const String cc0ChimeNotification = 'cc0_chime_notification';
  static const String cc0PhoneChime = 'cc0_phone_chime';
  static const String cc0SoftBell = 'cc0_soft_bell';
  static const String medSyncClassic = 'medsync_classic';
  static const String medSyncAlarmPulse = 'medsync_alarm_pulse';
  static const String medSyncAlarmSiren = 'medsync_alarm_siren';
  static const String medSyncAlarmBell = 'medsync_alarm_bell';
  static const String systemDefault = 'system_default';

  static const Set<String> _legacyBundledToneIds = {
    cc0ChimeNotification,
    cc0PhoneChime,
    cc0SoftBell,
    medSyncClassic,
  };

  static const List<String> channelCleanupRingtoneIds = [
    cc0ChimeNotification,
    cc0PhoneChime,
    cc0SoftBell,
    medSyncClassic,
    medSyncAlarmPulse,
    medSyncAlarmSiren,
    medSyncAlarmBell,
    systemDefault,
  ];

  static const String defaultReminderRingtoneId = medSyncAlarmPulse;

  static const AlarmRingtoneOption _defaultOption = AlarmRingtoneOption(
    id: medSyncAlarmPulse,
    labelEn: 'Wake Pulse',
    labelId: 'Pulse Bangun',
    androidResourceName: 'medsync_alarm_pulse_pcm',
  );

  static const List<AlarmRingtoneOption> options = [
    _defaultOption,
    AlarmRingtoneOption(
      id: medSyncAlarmSiren,
      labelEn: 'Warning Beep',
      labelId: 'Beep Peringatan',
      androidResourceName: 'medsync_alarm_siren_pcm',
    ),
    AlarmRingtoneOption(
      id: medSyncAlarmBell,
      labelEn: 'Rapid Bell',
      labelId: 'Bel Cepat',
      androidResourceName: 'medsync_alarm_bell_pcm',
    ),
    AlarmRingtoneOption(
      id: systemDefault,
      labelEn: 'System Default',
      labelId: 'Default Sistem',
      androidResourceName: null,
    ),
  ];

  static AlarmRingtoneOption byId(String? id) {
    final normalized = id?.trim() ?? '';
    if (_legacyBundledToneIds.contains(normalized)) {
      return _defaultOption;
    }

    for (final option in options) {
      if (option.id == normalized) {
        return option;
      }
    }
    return _defaultOption;
  }

  static String normalizeId(String? id) {
    return byId(id).id;
  }

  static String? androidResourceNameById(String? id) {
    return byId(id).androidResourceName;
  }
}
