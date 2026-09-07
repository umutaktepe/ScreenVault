import '../models/show_model.dart';
import '../models/season_model.dart';
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

  /// Fetches seasons list for a TV show from TMDB
  Future<List<SeasonModel>> getShowSeasons(int tmdbShowId, {int showInternalId = 0}) async {
    final uri = TmdbEndpoints.tvShowDetails(tmdbShowId);
    final response = await _client.get(uri);
    final seasonsJson = response['seasons'] as List?;
    if (seasonsJson != null) {
      return seasonsJson
          .where((s) =>
              s is Map<String, dynamic> &&
              (s['season_number'] as int? ?? 0) > 0 &&
              (s['episode_count'] as int? ?? 0) > 0)
          .map((s) => SeasonModel.fromTmdbJson(s as Map<String, dynamic>, showInternalId))
          .toList();
    }
    return [];
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

  /// Searches for a TV show by name on TMDB
  Future<ShowModel?> searchTvShowByName(String query) async {
    if (query.trim().isEmpty) return null;
    final uri = TmdbEndpoints.searchTv(query);
    final response = await _client.get(uri);
    final results = response['results'] as List?;
    if (results != null && results.isNotEmpty) {
      final first = results.first as Map<String, dynamic>;
      final tmdbId = first['id'] as int?;
      if (tmdbId != null) {
        final details = await getTvShowDetails(tmdbId);
        if (details != null) return details;
      }
      return ShowModel.fromTmdbJson(first);
    }
    return null;
  }

  /// Searches for a Movie by name on TMDB
  Future<MovieModel?> searchMovieByName(String query) async {
    if (query.trim().isEmpty) return null;
    final uri = TmdbEndpoints.searchMovie(query);
    final response = await _client.get(uri);
    final results = response['results'] as List?;
    if (results != null && results.isNotEmpty) {
      final first = results.first as Map<String, dynamic>;
      final tmdbId = first['id'] as int?;
      if (tmdbId != null) {
        final details = await getMovieDetails(tmdbId);
        if (details != null) return details;
      }
      return MovieModel.fromTmdbJson(first);
    }
    return null;
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

  /// Live TMDB v3 search across movies, TV shows and cast with Turkish localization
  Future<List<dynamic>> searchMulti(String query, {int page = 1}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      // Execute multi, TV and movie searches concurrently
      final multiUri = TmdbEndpoints.searchMulti(cleanQuery, page: page);
      final tvUri = TmdbEndpoints.searchTv(cleanQuery, page: page);
      final movieUri = TmdbEndpoints.searchMovie(cleanQuery, page: page);

      final responses = await Future.wait([
        _client.get(multiUri),
        _client.get(tvUri),
        _client.get(movieUri),
      ]);

      final multiResults = (responses[0]['results'] as List?) ?? [];
      final tvResults = (responses[1]['results'] as List?) ?? [];
      final movieResults = (responses[2]['results'] as List?) ?? [];

      final List<dynamic> items = [];
      final Set<String> seen = {};

      // 1. Prioritize TV show matches (e.g. Behzat Ç., Çekiç ve Gül)
      for (final item in tvResults) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'] as int?;
        if (id == null || seen.contains('tv_$id')) continue;
        seen.add('tv_$id');
        items.add(ShowModel.fromTmdbJson(item));
      }

      // 2. Prioritize direct Movie matches
      for (final item in movieResults) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'] as int?;
        if (id == null || seen.contains('movie_$id')) continue;
        seen.add('movie_$id');
        items.add(MovieModel.fromTmdbJson(item));
      }

      // 3. Add items from multi search and extract known_for from actors
      for (final item in multiResults) {
        if (item is! Map<String, dynamic>) continue;
        final mediaType = item['media_type'] as String?;
        final id = item['id'] as int?;

        if (mediaType == 'tv' && id != null) {
          if (!seen.contains('tv_$id')) {
            seen.add('tv_$id');
            items.add(ShowModel.fromTmdbJson(item));
          }
        } else if (mediaType == 'movie' && id != null) {
          if (!seen.contains('movie_$id')) {
            seen.add('movie_$id');
            items.add(MovieModel.fromTmdbJson(item));
          }
        } else if (mediaType == 'person') {
          final knownFor = item['known_for'] as List?;
          if (knownFor != null) {
            for (final k in knownFor) {
              if (k is! Map<String, dynamic>) continue;
              final kType = k['media_type'] as String?;
              final kId = k['id'] as int?;
              if (kType == 'tv' && kId != null && !seen.contains('tv_$kId')) {
                seen.add('tv_$kId');
                items.add(ShowModel.fromTmdbJson(k));
              } else if (kType == 'movie' && kId != null && !seen.contains('movie_$kId')) {
                seen.add('movie_$kId');
                items.add(MovieModel.fromTmdbJson(k));
              }
            }
          }
        }
      }

      return items;
    } catch (_) {
      return [];
    }
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

  /// Regional watch provider discover query (e.g. Netflix 8, Prime 119, BluTV 341)
  Future<List<ShowModel>> getShowsByProvider(int providerId) async {
    final uri = TmdbEndpoints.discoverTvByProvider(providerId);
    final response = await _client.get(uri);
    final results = response['results'] as List?;
    if (results == null) return [];
    final List<ShowModel> shows = [];
    for (final item in results) {
      if (item is Map<String, dynamic>) {
        shows.add(ShowModel.fromTmdbJson(item));
      }
    }
    return shows;
  }

  void dispose() {
    _client.dispose();
  }
}
