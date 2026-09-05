import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/core/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter & Lifetime Watch Time Tests', () {
    test('Verifies 186,576 minutes matches TV Time 4 Months 9 Days 13 Hours exactly', () {
      final parts = DurationFormatter.formatLifetimeMinutes(186576);

      expect(parts.months, 4);
      expect(parts.days, 9);
      expect(parts.hours, 13);
      expect(parts.formattedMonths, '04');
      expect(parts.formattedDays, '09');
      expect(parts.formattedHours, '13');
      expect(parts.totalMinutes, 186576);
    });

    test('Handles zero and negative minutes gracefully', () {
      final zero = DurationFormatter.formatLifetimeMinutes(0);
      expect(zero.months, 0);
      expect(zero.days, 0);
      expect(zero.hours, 0);

      final negative = DurationFormatter.formatLifetimeMinutes(-100);
      expect(negative.months, 0);
      expect(negative.days, 0);
      expect(negative.hours, 0);
    });

    test('Exact 1 month boundary (43,200 minutes = 30 days * 24h * 60m)', () {
      final oneMonth = DurationFormatter.formatLifetimeMinutes(43200);
      expect(oneMonth.months, 1);
      expect(oneMonth.days, 0);
      expect(oneMonth.hours, 0);
    });

    test('Converts TV Time seconds to minutes using integer division (~/ 60)', () {
      expect(DurationFormatter.secondsToMinutes(5040), 84); // Behzat C runtime
      expect(DurationFormatter.secondsToMinutes(3600), 60);
      expect(DurationFormatter.secondsToMinutes(1500), 25);
      expect(DurationFormatter.secondsToMinutes(0), 0);
      expect(DurationFormatter.secondsToMinutes(-10), 0);
    });

    test('Formats runtime cleanly (e.g. 52m, 1h 12m)', () {
      expect(DurationFormatter.formatRuntime(45), '45m');
      expect(DurationFormatter.formatRuntime(60), '1h');
      expect(DurationFormatter.formatRuntime(72), '1h 12m');
      expect(DurationFormatter.formatRuntime(0), '0m');
    });
  });
}
