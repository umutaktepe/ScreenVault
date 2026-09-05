import '../../core/constants/app_constants.dart';

/// Centralized endpoint builder for TMDB API v3
class TmdbEndpoints {
  TmdbEndpoints._();

  static const String baseUrl = AppConstants.tmdbBaseUrl;
  static const String apiKey = AppConstants.tmdbApiKey;

  static Uri findByTvdbId(int tvdbId) {
    return Uri.parse('$baseUrl/find/$tvdbId?api_key=$apiKey&external_source=tvdb_id');
  }

  static Uri tvShowDetails(int tmdbShowId) {
    return Uri.parse('$baseUrl/tv/$tmdbShowId?api_key=$apiKey&append_to_response=external_ids,content_ratings');
  }

  static Uri tvSeasonDetails(int tmdbShowId, int seasonNumber) {
    return Uri.parse('$baseUrl/tv/$tmdbShowId/season/$seasonNumber?api_key=$apiKey');
  }

  static Uri movieDetails(int tmdbMovieId) {
    return Uri.parse('$baseUrl/movie/$tmdbMovieId?api_key=$apiKey&append_to_response=external_ids');
  }

  static Uri searchMulti(String query, {int page = 1}) {
    final encoded = Uri.encodeComponent(query);
    return Uri.parse('$baseUrl/search/multi?api_key=$apiKey&query=$encoded&page=$page&include_adult=false');
  }

  static Uri searchTv(String query, {int page = 1}) {
    final encoded = Uri.encodeComponent(query);
    return Uri.parse('$baseUrl/search/tv?api_key=$apiKey&query=$encoded&page=$page&include_adult=false');
  }

  static Uri searchMovie(String query, {int page = 1}) {
    final encoded = Uri.encodeComponent(query);
    return Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$encoded&page=$page&include_adult=false');
  }

  static Uri trendingAllDay() {
    return Uri.parse('$baseUrl/trending/all/day?api_key=$apiKey');
  }

  static Uri discoverTvByProvider(int providerId) {
    return Uri.parse('$baseUrl/discover/tv?api_key=$apiKey&with_watch_providers=$providerId&watch_region=TR&sort_by=popularity.desc');
  }

  static String imageUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConstants.tmdbImageBaseUrl}$size$path';
  }
}
