import 'package:intl/intl.dart';

/// Date formatting utilities
class DateFormatter {
  DateFormatter._();

  static final DateFormat _airDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEE');
  static final DateFormat _dayOfMonthFormat = DateFormat('d');

  static String formatAirDate(DateTime? date) {
    if (date == null) return 'TBA';
    return _airDateFormat.format(date);
  }

  static String formatIsoDate(DateTime date) {
    return _isoFormat.format(date);
  }

  static DateTime? parseIsoDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr.trim());
    } catch (_) {
      return null;
    }
  }

  static String getDayOfWeek(DateTime date) {
    return _dayOfWeekFormat.format(date);
  }

  static String getDayOfMonth(DateTime date) {
    return _dayOfMonthFormat.format(date);
  }

  /// Relative date label (e.g. "Today", "Tomorrow", "In 3 days", "3 days ago")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';
    if (diffDays > 1 && diffDays <= 7) return 'In $diffDays days';
    if (diffDays < -1 && diffDays >= -7) return '${diffDays.abs()} days ago';

    return _airDateFormat.format(date);
  }
}
