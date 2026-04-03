import 'package:intl/intl.dart';

import '../constants/app_strings.dart';

extension DateTimeExt on DateTime {
  String get _activeLocale =>
      AppStrings.languageCode == 'id' ? 'id_ID' : 'en_US';

  /// "17 Maret 2025"
  String toIndonesianDate() {
    return DateFormat('d MMMM yyyy', _activeLocale).format(this);
  }

  /// "17 Mar"
  String toShortDate() {
    return DateFormat('d MMM', _activeLocale).format(this);
  }

  /// "08:00"
  String toTimeString() {
    return DateFormat('HH:mm').format(this);
  }

  /// "Senin, 17 Maret 2025"
  String toFullIndonesianDate() {
    return DateFormat('EEEE, d MMMM yyyy', _activeLocale).format(this);
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns "Pagi" | "Siang" | "Sore" | "Malam"
  String get greetingTime {
    if (hour >= 5 && hour < 11) return AppStrings.tr('Morning', 'Pagi');
    if (hour >= 11 && hour < 15) return AppStrings.tr('Noon', 'Siang');
    if (hour >= 15 && hour < 18) return AppStrings.tr('Afternoon', 'Sore');
    return AppStrings.tr('Night', 'Malam');
  }

  /// Label for grouping: "Hari ini", "Kemarin", or formatted date
  String get groupLabel {
    if (isToday) return AppStrings.tr('Today', 'Hari ini');
    if (isYesterday) return AppStrings.tr('Yesterday', 'Kemarin');
    return toIndonesianDate();
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}
