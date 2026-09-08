import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/tmdb/title_sanitizer.dart';

void main() {
  group('TitleSanitizer Tests', () {
    test('Parses title with year in parentheses: Lost in Space (2018)', () {
      final result = TitleSanitizer.parseTitleAndYear('Lost in Space (2018)');
      expect(result.cleanTitle, 'Lost in Space');
      expect(result.extractedYear, 2018);
    });

    test('Parses title with year in brackets: Dark [2017]', () {
      final result = TitleSanitizer.parseTitleAndYear('Dark [2017]');
      expect(result.cleanTitle, 'Dark');
      expect(result.extractedYear, 2017);
    });

    test('Parses plain title without year: Friends', () {
      final result = TitleSanitizer.parseTitleAndYear('Friends');
      expect(result.cleanTitle, 'Friends');
      expect(result.extractedYear, isNull);
    });

    test('Leaves title containing a number intact if not bracketed year', () {
      final result = TitleSanitizer.parseTitleAndYear('Blade Runner 2049');
      expect(result.cleanTitle, 'Blade Runner 2049');
      expect(result.extractedYear, isNull);
    });

    test('Extracts bracketed year even when title contains other numbers', () {
      final result = TitleSanitizer.parseTitleAndYear('Blade Runner 2049 (2017)');
      expect(result.cleanTitle, 'Blade Runner 2049');
      expect(result.extractedYear, 2017);
    });

    test('Leaves non-year parentheses intact: The Office (US)', () {
      final result = TitleSanitizer.parseTitleAndYear('The Office (US)');
      expect(result.cleanTitle, 'The Office (US)');
      expect(result.extractedYear, isNull);
    });

    test('Trims surrounding whitespace correctly', () {
      final result = TitleSanitizer.parseTitleAndYear('   Stranger Things (2016)   ');
      expect(result.cleanTitle, 'Stranger Things');
      expect(result.extractedYear, 2016);
    });

    test('Handles empty and whitespace-only strings safely', () {
      final empty = TitleSanitizer.parseTitleAndYear('');
      expect(empty.cleanTitle, '');
      expect(empty.extractedYear, isNull);

      final spaces = TitleSanitizer.parseTitleAndYear('   ');
      expect(spaces.cleanTitle, '');
      expect(spaces.extractedYear, isNull);
    });

    group('isWithinYearTolerance Tests', () {
      test('Exact match returns true', () {
        expect(TitleSanitizer.isWithinYearTolerance(2018, 2018), isTrue);
      });

      test('Within ±1 year returns true (tolerance = 1 default)', () {
        expect(TitleSanitizer.isWithinYearTolerance(2017, 2018), isTrue);
        expect(TitleSanitizer.isWithinYearTolerance(2019, 2018), isTrue);
      });

      test('Difference > 1 returns false for default tolerance', () {
        expect(TitleSanitizer.isWithinYearTolerance(2016, 2018), isFalse);
        expect(TitleSanitizer.isWithinYearTolerance(2020, 2018), isFalse);
      });

      test('Custom tolerance is respected', () {
        expect(TitleSanitizer.isWithinYearTolerance(2016, 2018, tolerance: 2), isTrue);
        expect(TitleSanitizer.isWithinYearTolerance(2015, 2018, tolerance: 2), isFalse);
      });

      test('Null candidate or target returns false safely', () {
        expect(TitleSanitizer.isWithinYearTolerance(null, 2018), isFalse);
        expect(TitleSanitizer.isWithinYearTolerance(2018, null), isFalse);
        expect(TitleSanitizer.isWithinYearTolerance(null, null), isFalse);
      });
    });
  });
}
