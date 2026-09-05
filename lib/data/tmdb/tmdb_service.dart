import '../models/show_model.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import 'tmdb_client.dart';
import 'tmdb_endpoints.dart';

/// High-level TMDB v3 API Service
class TmdbService {
  final TmdbClient _client;

  TmdbService({TmdbClient? client}) : _client = client ?? TmdbClient();

  /// Resolves a TVDB Series ID (from TV Time backup) to TMDB Show Model
  Future<ShowModel?> findTvShowByTvdbId(int tvdbId) async {
    final uri = TmdbEndpoints.findByTvdbId(tvdbId);
    final response = await _client.get(uri);

    final tvResults = response['tv_results'] as List?;
    if (tvResults != null && tvResults.isNotEmpty) {
      final firstResult = tvResults.first as Map<String, dynamic>;
      final tmdbId = firstResult['id'] as int?;
      if (tmdbId != null) {
        // Two-stage fetch: Get full show metadata including season list & external IDs
        return await getTvShowDetails(tmdbId);
      }
    }
    return null;
  }

  /// Fetches complete TV show metadata (stage 1 of two-stage rule)
  Future<ShowModel?> getTvShowDetails(int tmdbId) async {
    final uri = TmdbEndpoints.tvShowDetails(tmdbId);
    final response = await _client.get(uri);
    if (response.containsKey('id')) {
      return ShowModel.fromTmdbJson(response);
    }
    return null;
  }

  /// Fetches episodes and runtimes for a season (stage 2 of two-stage rule)
  Future<List<EpisodeModel>> getSeasonEpisodes(
    int tmdbShowId,
    int seasonNumber, {
    int showInternalId = 0,
    int seasonInternalId = 0,
  }) async {
    final uri = TmdbEndpoints.tvSeasonDetails(tmdbShowId, seasonNumber);
    final response = await _client.get(uri);

    final episodesJson = response['episodes'] as List?;
    if (episodesJson != null) {
      return episodesJson
          .map((ep) => EpisodeModel.fromTmdbJson(
                ep as Map<String, dynamic>,
                showInternalId,
                seasonInternalId,
              ))
          .toList();
    }
    return [];
  }

  /// Fetches full Movie details
  Future<MovieModel?> getMovieDetails(int tmdbId) async {
    final uri = TmdbEndpoints.movieDetails(tmdbId);
    final response = await _client.get(uri);
    if (response.containsKey('id')) {
      return MovieModel.fromTmdbJson(response);
    }
    return null;
  }

  /// Live TMDB v3 search across movies and TV shows
  Future<List<dynamic>> searchMulti(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    final uri = TmdbEndpoints.searchMulti(query, page: page);
    final response = await _client.get(uri);

    final results = response['results'] as List?;
    if (results == null) return [];

    final List<dynamic> items = [];
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final mediaType = item['media_type'] as String?;
      if (mediaType == 'tv') {
        items.add(ShowModel.fromTmdbJson(item));
      } else if (mediaType == 'movie') {
        items.add(MovieModel.fromTmdbJson(item));
      }
    }
    return items;
  }

  /// Top 5-10 Trending Hero items today
  Future<List<dynamic>> getTrendingAllDay() async {
    final uri = TmdbEndpoints.trendingAllDay();
    final response = await _client.get(uri);

    final results = response['results'] as List?;
    if (results == null) return [];

    final List<dynamic> trending = [];
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final mediaType = item['media_type'] as String?;
      if (mediaType == 'tv') {
        trending.add(ShowModel.fromTmdbJson(item));
      } else if (mediaType == 'movie') {
        trending.add(MovieModel.fromTmdbJson(item));
      }
    }
    return trending;
  }

  void dispose() {
    _client.dispose();
  }
}
