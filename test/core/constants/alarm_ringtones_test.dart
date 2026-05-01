import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/core/constants/alarm_ringtones.dart';

void main() {
  group('AlarmRingtones', () {
    test('shows three bundled alarm variants and system default', () {
      expect(AlarmRingtones.options.map((option) => option.id), [
        AlarmRingtones.medSyncAlarmPulse,
        AlarmRingtones.medSyncAlarmSiren,
        AlarmRingtones.medSyncAlarmBell,
        AlarmRingtones.systemDefault,
      ]);

      expect(
        AlarmRingtones.options.where(
          (option) => option.androidResourceName != null,
        ),
        hasLength(3),
      );
    });

    test('maps legacy bundled tone ids to the default wake pulse alarm', () {
      for (final legacyId in [
        AlarmRingtones.cc0ChimeNotification,
        AlarmRingtones.cc0PhoneChime,
        AlarmRingtones.cc0SoftBell,
        AlarmRingtones.medSyncClassic,
      ]) {
        final option = AlarmRingtones.byId(legacyId);

        expect(option.id, AlarmRingtones.defaultReminderRingtoneId);
        expect(option.labelEn, 'Wake Pulse');
        expect(option.androidResourceName, 'medsync_alarm_pulse_pcm');
      }
    });

    test('maps selectable alarm variants to Android raw resources', () {
      expect(
        AlarmRingtones.androidResourceNameById(
          AlarmRingtones.medSyncAlarmPulse,
        ),
        'medsync_alarm_pulse_pcm',
      );
      expect(
        AlarmRingtones.androidResourceNameById(
          AlarmRingtones.medSyncAlarmSiren,
        ),
        'medsync_alarm_siren_pcm',
      );
      expect(
        AlarmRingtones.androidResourceNameById(AlarmRingtones.medSyncAlarmBell),
        'medsync_alarm_bell_pcm',
      );
    });

    test('keeps legacy tone ids available for channel cleanup', () {
      expect(
        AlarmRingtones.channelCleanupRingtoneIds,
        containsAll([
          AlarmRingtones.cc0ChimeNotification,
          AlarmRingtones.cc0PhoneChime,
          AlarmRingtones.cc0SoftBell,
          AlarmRingtones.medSyncClassic,
          AlarmRingtones.medSyncAlarmPulse,
          AlarmRingtones.medSyncAlarmSiren,
          AlarmRingtones.medSyncAlarmBell,
          AlarmRingtones.systemDefault,
        ]),
      );
    });
  });
}
