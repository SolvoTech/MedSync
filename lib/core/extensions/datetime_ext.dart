import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  /// "17 Maret 2025"
  String toIndonesianDate() {
    return DateFormat('d MMMM yyyy', 'id_ID').format(this);
  }

  /// "17 Mar"
  String toShortDate() {
    return DateFormat('d MMM', 'id_ID').format(this);
  }

  /// "08:00"
  String toTimeString() {
    return DateFormat('HH:mm').format(this);
  }

  /// "Senin, 17 Maret 2025"
  String toFullIndonesianDate() {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(this);
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
    if (hour >= 5 && hour < 11) return 'Pagi';
    if (hour >= 11 && hour < 15) return 'Siang';
    if (hour >= 15 && hour < 18) return 'Sore';
    return 'Malam';
  }

  /// Label for grouping: "Hari ini", "Kemarin", or formatted date
  String get groupLabel {
    if (isToday) return 'Hari ini';
    if (isYesterday) return 'Kemarin';
    return toIndonesianDate();
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}
