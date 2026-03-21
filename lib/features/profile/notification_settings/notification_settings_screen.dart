import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  // Default: all enabled
  bool _medicineEnabled = true;
  bool _measurementEnabled = true;
  bool _activityEnabled = true;
  bool _stockWarningEnabled = true;
  bool _streakEnabled = true;
  bool _dailySummaryEnabled = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.notificationSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.remindersSection,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.medication,
                    color: const Color(0xFF0077B6),
                  ),
                  title: Text(AppStrings.medicineReminderTitle),
                  subtitle: Text(AppStrings.medicineReminderSubtitle),
                  value: _medicineEnabled,
                  onChanged: (v) => setState(() => _medicineEnabled = v),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    Icons.monitor_heart,
                    color: const Color(0xFF16A34A),
                  ),
                  title: Text(AppStrings.measurementReminderTitle),
                  subtitle: Text(AppStrings.measurementReminderSubtitle),
                  value: _measurementEnabled,
                  onChanged: (v) => setState(() => _measurementEnabled = v),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    Icons.directions_run,
                    color: const Color(0xFFEA580C),
                  ),
                  title: Text(AppStrings.activityReminderTitle),
                  subtitle: Text(AppStrings.activityReminderSubtitle),
                  value: _activityEnabled,
                  onChanged: (v) => setState(() => _activityEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppStrings.alertsSection,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(AppStrings.lowStockAlertTitle),
                  subtitle: Text(AppStrings.lowStockAlertSubtitle),
                  value: _stockWarningEnabled,
                  onChanged: (v) => setState(() => _stockWarningEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppStrings.reportsSection,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.local_fire_department,
                    color: Colors.deepOrange,
                  ),
                  title: Text(AppStrings.streakNotificationTitle),
                  subtitle: Text(AppStrings.streakNotificationSubtitle),
                  value: _streakEnabled,
                  onChanged: (v) => setState(() => _streakEnabled = v),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    Icons.summarize_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(AppStrings.dailySummaryTitle),
                  subtitle: Text(AppStrings.dailySummarySubtitle),
                  value: _dailySummaryEnabled,
                  onChanged: (v) => setState(() => _dailySummaryEnabled = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
