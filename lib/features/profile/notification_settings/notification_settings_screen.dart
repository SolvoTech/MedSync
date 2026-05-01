import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/alarm_ringtones.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/local/preferences/app_preferences.dart';
import '../../../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  // Default fallback values before SharedPreferences are loaded.
  bool _medicineEnabled = true;
  bool _measurementEnabled = true;
  bool _activityEnabled = true;
  bool _stockWarningEnabled = true;
  bool _streakEnabled = true;
  bool _dailySummaryEnabled = true;

  String _medicineRingtoneId = AlarmRingtones.defaultReminderRingtoneId;
  String _measurementRingtoneId = AlarmRingtones.defaultReminderRingtoneId;
  String _activityRingtoneId = AlarmRingtones.defaultReminderRingtoneId;

  bool _isApplyingTone = false;
  bool _isOpeningSystemSettings = false;

  @override
  void initState() {
    super.initState();
    _loadFromPreferences();
  }

  void _loadFromPreferences() {
    _medicineEnabled = AppPreferences.notifMedicine;
    _measurementEnabled = AppPreferences.notifMeasurement;
    _activityEnabled = AppPreferences.notifActivity;
    _stockWarningEnabled = AppPreferences.notifStock;
    _streakEnabled = AppPreferences.notifStreak;
    _dailySummaryEnabled = AppPreferences.notifDailySummary;

    _medicineRingtoneId = AppPreferences.notifMedicineRingtoneId;
    _measurementRingtoneId = AppPreferences.notifMeasurementRingtoneId;
    _activityRingtoneId = AppPreferences.notifActivityRingtoneId;
  }

  void _onMedicineToggleChanged(bool value) {
    setState(() => _medicineEnabled = value);
    unawaited(
      _persistReminderPreference(
        savePreference: () => AppPreferences.setNotifMedicine(value),
      ),
    );
  }

  void _onMeasurementToggleChanged(bool value) {
    setState(() => _measurementEnabled = value);
    unawaited(
      _persistReminderPreference(
        savePreference: () => AppPreferences.setNotifMeasurement(value),
      ),
    );
  }

  void _onActivityToggleChanged(bool value) {
    setState(() => _activityEnabled = value);
    unawaited(
      _persistReminderPreference(
        savePreference: () => AppPreferences.setNotifActivity(value),
      ),
    );
  }

  Future<void> _persistReminderPreference({
    required Future<void> Function() savePreference,
  }) async {
    try {
      await savePreference();
      await ref
          .read(notificationServiceProvider)
          .syncTaskNotificationsWithCurrentPreferences();
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(AppStrings.settingsSaveFailed);
      }
    }
  }

  void _onStockToggleChanged(bool value) {
    setState(() => _stockWarningEnabled = value);
    unawaited(AppPreferences.setNotifStock(value));
  }

  void _onStreakToggleChanged(bool value) {
    setState(() => _streakEnabled = value);
    unawaited(AppPreferences.setNotifStreak(value));
  }

  void _onDailySummaryToggleChanged(bool value) {
    setState(() => _dailySummaryEnabled = value);
    unawaited(AppPreferences.setNotifDailySummary(value));
  }

  Future<void> _onReminderToneChanged({
    required String reminderType,
    required String ringtoneId,
  }) async {
    if (_isApplyingTone) {
      return;
    }

    setState(() {
      if (reminderType == 'medicine') {
        _medicineRingtoneId = ringtoneId;
      } else if (reminderType == 'measurement') {
        _measurementRingtoneId = ringtoneId;
      } else if (reminderType == 'physical_activity') {
        _activityRingtoneId = ringtoneId;
      }
      _isApplyingTone = true;
    });

    try {
      if (reminderType == 'medicine') {
        await AppPreferences.setNotifMedicineRingtoneId(ringtoneId);
      } else if (reminderType == 'measurement') {
        await AppPreferences.setNotifMeasurementRingtoneId(ringtoneId);
      } else if (reminderType == 'physical_activity') {
        await AppPreferences.setNotifActivityRingtoneId(ringtoneId);
      }

      await ref
          .read(notificationServiceProvider)
          .applyRingtonePreferenceChanges();

      if (mounted) {
        context.showSuccessSnackBar(AppStrings.alarmToneUpdated);
      }
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(AppStrings.settingsSaveFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isApplyingTone = false);
      }
    }
  }

  Future<void> _openSystemNotificationSettings() async {
    if (_isOpeningSystemSettings) {
      return;
    }

    setState(() => _isOpeningSystemSettings = true);

    try {
      final opened = await ref
          .read(notificationServiceProvider)
          .openAndroidNotificationSettings();

      if (!opened && mounted) {
        context.showErrorSnackBar(
          AppStrings.tr(
            'Unable to open notification settings.',
            'Tidak dapat membuka pengaturan notifikasi.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(AppStrings.settingsSaveFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningSystemSettings = false);
      }
    }
  }

  String _ringtoneLabel(String ringtoneId) {
    final option = AlarmRingtones.byId(ringtoneId);
    return AppStrings.languageCode == 'id' ? option.labelId : option.labelEn;
  }

  Widget _buildRingtonePicker({
    required String selectedId,
    required ValueChanged<String> onChanged,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 340;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 56, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.alarmToneLabel,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.alarmToneSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(selectedId),
            initialValue: selectedId,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            items: AlarmRingtones.options.map((option) {
              return DropdownMenuItem<String>(
                value: option.id,
                child: Text(
                  _ringtoneLabel(option.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _isApplyingTone
                ? null
                : (value) {
                    if (value == null || value == selectedId) {
                      return;
                    }
                    onChanged(value);
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 340;
    final tilePadding = EdgeInsets.symmetric(
      horizontal: compact ? 10 : 16,
      vertical: compact ? 2 : 4,
    );
    final tileDensity = compact
        ? const VisualDensity(horizontal: -2, vertical: -1)
        : VisualDensity.standard;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.notificationSettings,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(compact ? 12 : 16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr(
                    'Still no ringtone? Check Android notification sound settings for this app.',
                    'Nada dering masih tidak muncul? Periksa pengaturan suara notifikasi Android untuk aplikasi ini.',
                  ),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isOpeningSystemSettings
                        ? null
                        : _openSystemNotificationSettings,
                    icon: const Icon(Icons.settings_suggest_outlined),
                    label: Text(
                      AppStrings.tr(
                        'Open Notification Settings',
                        'Buka Pengaturan Notifikasi',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppStrings.remindersSection,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: tilePadding,
                  dense: compact,
                  visualDensity: tileDensity,
                  secondary: Icon(
                    Icons.medication,
                    color: const Color(0xFF0077B6),
                  ),
                  title: Text(AppStrings.medicineReminderTitle),
                  subtitle: Text(AppStrings.medicineReminderSubtitle),
                  value: _medicineEnabled,
                  onChanged: _onMedicineToggleChanged,
                ),
                if (_medicineEnabled)
                  _buildRingtonePicker(
                    selectedId: _medicineRingtoneId,
                    onChanged: (value) => _onReminderToneChanged(
                      reminderType: 'medicine',
                      ringtoneId: value,
                    ),
                  ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  contentPadding: tilePadding,
                  dense: compact,
                  visualDensity: tileDensity,
                  secondary: Icon(
                    Icons.monitor_heart,
                    color: const Color(0xFF16A34A),
                  ),
                  title: Text(AppStrings.measurementReminderTitle),
                  subtitle: Text(AppStrings.measurementReminderSubtitle),
                  value: _measurementEnabled,
                  onChanged: _onMeasurementToggleChanged,
                ),
                if (_measurementEnabled)
                  _buildRingtonePicker(
                    selectedId: _measurementRingtoneId,
                    onChanged: (value) => _onReminderToneChanged(
                      reminderType: 'measurement',
                      ringtoneId: value,
                    ),
                  ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  contentPadding: tilePadding,
                  dense: compact,
                  visualDensity: tileDensity,
                  secondary: Icon(
                    Icons.directions_run,
                    color: const Color(0xFFEA580C),
                  ),
                  title: Text(AppStrings.activityReminderTitle),
                  subtitle: Text(AppStrings.activityReminderSubtitle),
                  value: _activityEnabled,
                  onChanged: _onActivityToggleChanged,
                ),
                if (_activityEnabled)
                  _buildRingtonePicker(
                    selectedId: _activityRingtoneId,
                    onChanged: (value) => _onReminderToneChanged(
                      reminderType: 'physical_activity',
                      ringtoneId: value,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppStrings.alertsSection,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: tilePadding,
                  dense: compact,
                  visualDensity: tileDensity,
                  secondary: Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(AppStrings.lowStockAlertTitle),
                  subtitle: Text(AppStrings.lowStockAlertSubtitle),
                  value: _stockWarningEnabled,
                  onChanged: _onStockToggleChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppStrings.reportsSection,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: tilePadding,
                  dense: compact,
                  visualDensity: tileDensity,
                  secondary: const Icon(
                    Icons.local_fire_department,
                    color: Colors.deepOrange,
                  ),
                  title: Text(AppStrings.streakNotificationTitle),
                  subtitle: Text(AppStrings.streakNotificationSubtitle),
                  value: _streakEnabled,
                  onChanged: _onStreakToggleChanged,
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  contentPadding: tilePadding,
                  dense: compact,
                  visualDensity: tileDensity,
                  secondary: Icon(
                    Icons.summarize_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(AppStrings.dailySummaryTitle),
                  subtitle: Text(AppStrings.dailySummarySubtitle),
                  value: _dailySummaryEnabled,
                  onChanged: _onDailySummaryToggleChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
