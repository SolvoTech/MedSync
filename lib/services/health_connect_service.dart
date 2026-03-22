import 'package:flutter/material.dart';
import 'package:health/health.dart';

/// Health Connect integration service per spec §17.
class HealthConnectService {
  HealthConnectService._();

  static final Health _health = Health();

  /// Supported health data types.
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  /// Request authorization for health data.
  static Future<bool> requestAuthorization() async {
    try {
      final permissions = _types.map((_) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(
        _types,
        permissions: permissions,
      );
    } catch (e) {
      debugPrint('HealthConnect auth error: $e');
      return false;
    }
  }

  /// Check if Health Connect is available on this device.
  static Future<bool> isAvailable() async {
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  /// Fetch health data for a date range.
  static Future<List<HealthDataPoint>> fetchData({
    required DateTime start,
    required DateTime end,
    List<HealthDataType>? types,
  }) async {
    try {
      return await _health.getHealthDataFromTypes(
        types: types ?? _types,
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      debugPrint('HealthConnect fetch error: $e');
      return [];
    }
  }

  /// Fetch today's step count.
  static Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final data = await fetchData(
      start: midnight,
      end: now,
      types: [HealthDataType.STEPS],
    );
    return data.fold<int>(
      0,
      (sum, dp) =>
          sum +
          (dp.value is NumericHealthValue
              ? (dp.value as NumericHealthValue).numericValue.toInt()
              : 0),
    );
  }

  /// Fetch recent heart rate readings.
  static Future<List<HealthDataPoint>> getRecentHeartRate({
    int hours = 24,
  }) async {
    final now = DateTime.now();
    return fetchData(
      start: now.subtract(Duration(hours: hours)),
      end: now,
      types: [HealthDataType.HEART_RATE],
    );
  }
}
