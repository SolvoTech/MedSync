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

  static const String cc0ChimeNotification = 'cc0_chime_notification';
  static const String cc0PhoneChime = 'cc0_phone_chime';
  static const String cc0SoftBell = 'cc0_soft_bell';
  static const String medSyncClassic = 'medsync_classic';
  static const String systemDefault = 'system_default';

  // Default tone is bundled locally from a CC0 source.
  static const String defaultReminderRingtoneId = cc0ChimeNotification;

  static const AlarmRingtoneOption _defaultOption = AlarmRingtoneOption(
    id: cc0ChimeNotification,
    labelEn: 'CC0 Chime Notification',
    labelId: 'CC0 Chime Notification',
    androidResourceName: 'fs_cc0_chime_notification_pcm',
  );

  static const List<AlarmRingtoneOption> options = [
    _defaultOption,
    AlarmRingtoneOption(
      id: cc0PhoneChime,
      labelEn: 'CC0 Phone Chime',
      labelId: 'CC0 Phone Chime',
      androidResourceName: 'fs_cc0_phone_chime_pcm',
    ),
    AlarmRingtoneOption(
      id: cc0SoftBell,
      labelEn: 'CC0 Soft Bell',
      labelId: 'CC0 Soft Bell',
      androidResourceName: 'fs_cc0_soft_bell_pcm',
    ),
    AlarmRingtoneOption(
      id: medSyncClassic,
      labelEn: 'MedSync Classic',
      labelId: 'Klasik MedSync',
      androidResourceName: 'medsync_obat_tenang',
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
