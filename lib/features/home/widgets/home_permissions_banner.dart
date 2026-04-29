import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/warning_banner.dart';
import '../../../services/notification_service.dart';

class HomePermissionsBanner extends ConsumerStatefulWidget {
  const HomePermissionsBanner({super.key});

  @override
  ConsumerState<HomePermissionsBanner> createState() =>
      _HomePermissionsBannerState();
}

class _HomePermissionsBannerState extends ConsumerState<HomePermissionsBanner>
    with WidgetsBindingObserver {
  bool _needsNotification = false;
  bool _needsAlarm = false;
  bool _needsDndAccess = false;
  bool _needsBatteryOpt = false;
  bool _needsActivityRecognition = false;
  bool _needsBodySensors = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    final notifStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    final dndStatus = await Permission.accessNotificationPolicy.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final activityRecognitionStatus =
        await Permission.activityRecognition.status;
    final sensorsStatus = await Permission.sensors.status;

    if (mounted) {
      setState(() {
        _needsNotification = !notifStatus.isGranted;
        _needsAlarm = !alarmStatus.isGranted;
        _needsDndAccess = !dndStatus.isGranted;
        _needsBatteryOpt = !batteryStatus.isGranted;
        _needsActivityRecognition = !activityRecognitionStatus.isGranted;
        _needsBodySensors = !sensorsStatus.isGranted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (_needsNotification) await Permission.notification.request();
    if (_needsAlarm) await Permission.scheduleExactAlarm.request();
    final requestedDndAccess = _needsDndAccess;
    if (_needsDndAccess) await Permission.accessNotificationPolicy.request();
    if (_needsBatteryOpt) await Permission.ignoreBatteryOptimizations.request();
    if (_needsActivityRecognition) {
      await Permission.activityRecognition.request();
    }
    if (_needsBodySensors) await Permission.sensors.request();
    if (requestedDndAccess) {
      try {
        await ref
            .read(notificationServiceProvider)
            .applyRingtonePreferenceChanges();
      } catch (_) {}
    }
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final missingPermissions = <String>[];
    if (_needsNotification) {
      missingPermissions.add(AppStrings.tr('Notifications', 'Notifikasi'));
    }
    if (_needsAlarm) {
      missingPermissions.add(AppStrings.tr('Exact Alarm', 'Alarm Tepat Waktu'));
    }
    if (_needsDndAccess) {
      missingPermissions.add(
        AppStrings.tr('Do Not Disturb Access', 'Akses Jangan Ganggu'),
      );
    }
    if (_needsBatteryOpt) {
      missingPermissions.add(
        AppStrings.tr('Battery Optimization Exemption', 'Pengecualian Baterai'),
      );
    }
    if (_needsActivityRecognition) {
      missingPermissions.add(
        AppStrings.tr('Physical Activity', 'Aktivitas fisik'),
      );
    }
    if (_needsBodySensors) {
      missingPermissions.add(AppStrings.tr('Body Sensors', 'Sensor tubuh'));
    }

    if (missingPermissions.isEmpty) return const SizedBox.shrink();

    return WarningBanner(
      message: AppStrings.tr(
        'Incomplete permissions: ${missingPermissions.join(', ')}',
        'Perizinan belum lengkap: ${missingPermissions.join(', ')}',
      ),
      actionLabel: AppStrings.tr('Allow', 'Izinkan'),
      onAction: _requestPermissions,
    );
  }
}
