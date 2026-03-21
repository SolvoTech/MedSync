import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/warning_banner.dart';

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
  bool _needsBatteryOpt = false;
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
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    if (mounted) {
      setState(() {
        _needsNotification = !notifStatus.isGranted;
        _needsAlarm = !alarmStatus.isGranted;
        _needsBatteryOpt = !batteryStatus.isGranted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (_needsNotification) await Permission.notification.request();
    if (_needsAlarm) await Permission.scheduleExactAlarm.request();
    if (_needsBatteryOpt) await Permission.ignoreBatteryOptimizations.request();
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
    if (_needsBatteryOpt) {
      missingPermissions.add(
        AppStrings.tr('Battery Optimization Exemption', 'Pengecualian Baterai'),
      );
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
