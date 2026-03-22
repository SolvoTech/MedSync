import 'package:flutter/services.dart';

/// Service for Android home screen widget per spec §17.
/// Communicates with native Android widget via MethodChannel.
class HomeWidgetService {
  HomeWidgetService._();

  static const _channel = MethodChannel('com.medsync/home_widget');

  /// Update the home screen widget with latest data.
  static Future<void> updateWidget({
    required int todayTotal,
    required int todayDone,
    required int currentStreak,
    String? nextMedicineName,
    String? nextMedicineTime,
  }) async {
    try {
      await _channel.invokeMethod('updateWidget', {
        'today_total': todayTotal,
        'today_done': todayDone,
        'current_streak': currentStreak,
        'next_medicine_name': nextMedicineName ?? '',
        'next_medicine_time': nextMedicineTime ?? '',
        'progress_percent': todayTotal > 0
            ? (todayDone / todayTotal * 100).round()
            : 0,
      });
    } on PlatformException catch (_) {
      // Widget not available on this device, silently fail
    }
  }

  /// Request the OS to pin the widget to home screen.
  static Future<bool> requestPinWidget() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPinWidget');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if home screen widget feature is supported.
  static Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
