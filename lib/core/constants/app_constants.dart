/// Application constants for Screen Vault
class AppConstants {
  AppConstants._();

  static const String appName = 'Screen Vault';
  static const String appTagline = 'Obsidian Cinema & TV Tracker';
  static const String stitchProjectId = '3622828564521745390';

  // TMDB API Configuration
  // Provide via: flutter run --dart-define=TMDB_API_KEY=your_key
  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: 'YOUR_TMDB_API_KEY_HERE',
  );
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/';
  static const String tmdbPosterW500 = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbBackdropW780 = 'https://image.tmdb.org/t/p/w780';
  static const String tmdbOriginal = 'https://image.tmdb.org/t/p/original';

  // TV Time Backup paths
  static const String defaultGdprPath = '/home/umutaktepe/Screen Vault/gdpr-data.zip';
  static const String exampleGdprPath = '/home/umutaktepe/Screen Vault/example backup data/gdpr-data.zip';

  // Rate Limiting
  static const int maxRequestsPerSecond = 40;
}
