import '../../core/constants/app_constants.dart';

/// Centralized endpoint builder for TMDB API v3
class TmdbEndpoints {
  TmdbEndpoints._();

  static const String baseUrl = AppConstants.tmdbBaseUrl;
  static String _dynamicApiKey = AppConstants.tmdbApiKey;

  static String get apiKey => _dynamicApiKey;

  static void setApiKey(String key) {
    _dynamicApiKey = key.trim();
  }

  static Uri _buildUri(String unencodedPath, [Map<String, String>? queryParams]) {
    final params = <String, String>{
      'api_key': apiKey,
      'language': 'tr-TR',
      ...?queryParams,
    };
    return Uri.https('api.themoviedb.org', '/3$unencodedPath', params);
  }

  static Uri findByTvdbId(int tvdbId) {
    return _buildUri('/find/$tvdbId', {'external_source': 'tvdb_id'});
  }

  static Uri tvShowDetails(int tmdbShowId) {
    return _buildUri('/tv/$tmdbShowId', {'append_to_response': 'external_ids,content_ratings'});
  }

  static Uri tvSeasonDetails(int tmdbShowId, int seasonNumber) {
    return _buildUri('/tv/$tmdbShowId/season/$seasonNumber');
  }

  static Uri movieDetails(int tmdbMovieId) {
    return _buildUri('/movie/$tmdbMovieId', {'append_to_response': 'external_ids'});
  }

  static Uri searchMulti(String query, {int page = 1}) {
    return _buildUri('/search/multi', {
      'query': query,
      'page': page.toString(),
      'include_adult': 'false',
    });
  }

  static Uri searchTv(String query, {int page = 1}) {
    return _buildUri('/search/tv', {
      'query': query,
      'page': page.toString(),
      'include_adult': 'false',
    });
  }

  static Uri searchMovie(String query, {int page = 1}) {
    return _buildUri('/search/movie', {
      'query': query,
      'page': page.toString(),
      'include_adult': 'false',
    });
  }

  static Uri trendingAllDay() {
    return _buildUri('/trending/all/day');
  }

  static Uri discoverTvByProvider(int providerId) {
    return _buildUri('/discover/tv', {
      'with_watch_providers': providerId.toString(),
      'watch_region': 'TR',
      'sort_by': 'popularity.desc',
    });
  }

  static String imageUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '${AppConstants.tmdbImageBaseUrl}$size$normalizedPath';
  }
}
