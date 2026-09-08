/// Helper utility for smart title parsing and year tolerance matching for TMDB queries.
class ParsedTitle {
  final String cleanTitle;
  final int? extractedYear;

  const ParsedTitle({
    required this.cleanTitle,
    this.extractedYear,
  });

  @override
  String toString() => 'ParsedTitle(cleanTitle: $cleanTitle, extractedYear: $extractedYear)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedTitle &&
          runtimeType == other.runtimeType &&
          cleanTitle == other.cleanTitle &&
          extractedYear == other.extractedYear;

  @override
  int get hashCode => cleanTitle.hashCode ^ extractedYear.hashCode;
}

class TitleSanitizer {
  TitleSanitizer._();

  static final RegExp _yearRegex = RegExp(r'^(.*?)\s*[\(\[]\s*(\d{4})\s*[\)\]]\s*$');

  /// Parses raw titles such as "Lost in Space (2018)" into clean title "Lost in Space"
  /// and extracted year 2018. If no year tag is present, cleanTitle is the trimmed title
  /// and extractedYear is null.
  static ParsedTitle parseTitleAndYear(String rawTitle) {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) {
      return const ParsedTitle(cleanTitle: '', extractedYear: null);
    }

    final match = _yearRegex.firstMatch(trimmed);
    if (match != null) {
      final title = match.group(1)?.trim() ?? '';
      final year = int.tryParse(match.group(2) ?? '');
      if (title.isNotEmpty && year != null) {
        return ParsedTitle(cleanTitle: title, extractedYear: year);
      }
    }

    return ParsedTitle(cleanTitle: trimmed, extractedYear: null);
  }

  /// Checks if [candidateYear] is within ±[tolerance] of [targetYear].
  static bool isWithinYearTolerance(int? candidateYear, int? targetYear, {int tolerance = 1}) {
    if (candidateYear == null || targetYear == null) return false;
    return (candidateYear - targetYear).abs() <= tolerance;
  }
}
