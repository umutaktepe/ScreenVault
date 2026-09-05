/// Helper for calculating and formatting watch durations and digital LED statistics
class WatchTimeParts {
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int totalMinutes;

  const WatchTimeParts({
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.totalMinutes,
  });

  String get formattedMonths => months.toString().padLeft(2, '0');
  String get formattedDays => days.toString().padLeft(2, '0');
  String get formattedHours => hours.toString().padLeft(2, '0');
  String get formattedMinutes => minutes.toString().padLeft(2, '0');
}

class DurationFormatter {
  DurationFormatter._();

  /// Converts total minutes to Months, Days, Hours, and remaining Minutes
  /// Following standard TV Time calendar metric: 1 month = 30 days, 1 day = 24 hours.
  static WatchTimeParts formatLifetimeMinutes(int totalMinutes) {
    if (totalMinutes <= 0) {
      return const WatchTimeParts(
        months: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        totalMinutes: 0,
      );
    }

    const int minutesPerHour = 60;
    const int minutesPerDay = 24 * minutesPerHour; // 1440
    const int minutesPerMonth = 30 * minutesPerDay; // 43200

    final int months = totalMinutes ~/ minutesPerMonth;
    final int remAfterMonths = totalMinutes % minutesPerMonth;

    final int days = remAfterMonths ~/ minutesPerDay;
    final int remAfterDays = remAfterMonths % minutesPerDay;

    final int hours = remAfterDays ~/ minutesPerHour;
    final int minutes = remAfterDays % minutesPerHour;

    return WatchTimeParts(
      months: months,
      days: days,
      hours: hours,
      minutes: minutes,
      totalMinutes: totalMinutes,
    );
  }

  /// Converts TV Time runtime (in seconds) to minutes: runtimeSeconds ~/ 60
  static int secondsToMinutes(int runtimeSeconds) {
    if (runtimeSeconds <= 0) return 0;
    return runtimeSeconds ~/ 60;
  }

  /// Formats episode runtime (e.g. 52 -> "52m" or "1h 12m")
  static String formatRuntime(int minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
