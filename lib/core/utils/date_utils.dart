/// Date utility helpers per spec §26.4.
class AppDateUtils {
  AppDateUtils._();

  /// Start of current day (00:00:00).
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// End of current day (23:59:59.999).
  static DateTime endOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  /// Check if two dates are the same day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if date is today.
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// Check if date is yesterday.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Number of days between two dates (ignoring time).
  static int daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return (t.difference(f).inHours / 24).round();
  }

  /// Short month name in Indonesian.
  static String shortMonth(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month.clamp(1, 12)];
  }

  /// Full month name in Indonesian.
  static String fullMonth(int month) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month.clamp(1, 12)];
  }

  /// Short day name in Indonesian.
  static String shortDay(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  /// Format as "HH:mm".
  static String formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Format as "d MMM yyyy" e.g. "17 Mar 2026".
  static String formatDate(DateTime dt) {
    return '${dt.day} ${shortMonth(dt.month)} ${dt.year}';
  }

  /// Relative time description: "Baru saja", "5 menit lalu", etc.
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatDate(dt);
  }
}
