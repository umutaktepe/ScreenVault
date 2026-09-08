import '../models/show_model.dart';
import '../models/season_model.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import 'title_sanitizer.dart';
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

  /// Searches for a TV show with a 4-stage fallback mechanism:
  /// Stage 1: Raw title search
  /// Stage 2: cleanTitle + firstAirDateYear (if year is available)
  /// Stage 3: cleanTitle unfiltered search + ±1 year tolerance matching
  /// Stage 4: searchMulti cross-media search
  Future<ShowModel?> searchTvShowWithFallback(String rawTitle, {int? targetYear}) async {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) return null;

    final parsed = TitleSanitizer.parseTitleAndYear(trimmed);
    final cleanTitle = parsed.cleanTitle;
    final effectiveYear = targetYear ?? parsed.extractedYear;

    // Aşama 1: Raw title ile arama
    try {
      final candidate = await searchTvShowByName(trimmed);
      if (candidate != null) {
        if (effectiveYear == null) return candidate;
        final candYear = candidate.firstAirDate?.year;
        if (candYear != null && TitleSanitizer.isWithinYearTolerance(candYear, effectiveYear)) {
          return candidate;
        }
      }
    } catch (_) {}

    // Aşama 2: cleanTitle ve firstAirDateYear
    if (effectiveYear != null && effectiveYear > 1900) {
      try {
        final uri = TmdbEndpoints.searchTv(cleanTitle, firstAirDateYear: effectiveYear);
        final response = await _client.get(uri);
        final results = response['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final dateStr = first['first_air_date'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          final candYear = date?.year;
          if (candYear == null || TitleSanitizer.isWithinYearTolerance(candYear, effectiveYear)) {
            final tmdbId = first['id'] as int?;
            if (tmdbId != null) {
              final details = await getTvShowDetails(tmdbId);
              if (details != null) return details;
            }
            return ShowModel.fromTmdbJson(first);
          }
        }
      } catch (_) {}
    }

    // Aşama 3: cleanTitle filtresiz arama + ±1 yıl tolerans kuralı
    try {
      final uri = TmdbEndpoints.searchTv(cleanTitle);
      final response = await _client.get(uri);
      final results = response['results'] as List?;
      if (results != null && results.isNotEmpty) {
        if (effectiveYear != null) {
          for (final item in results) {
            if (item is! Map<String, dynamic>) continue;
            final dateStr = item['first_air_date'] as String?;
            final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
            final itemYear = date?.year;
            if (itemYear != null && TitleSanitizer.isWithinYearTolerance(itemYear, effectiveYear)) {
              final tmdbId = item['id'] as int?;
              if (tmdbId != null) {
                final details = await getTvShowDetails(tmdbId);
                if (details != null) return details;
              }
              return ShowModel.fromTmdbJson(item);
            }
          }
        } else {
          final first = results.first as Map<String, dynamic>;
          final tmdbId = first['id'] as int?;
          if (tmdbId != null) {
            final details = await getTvShowDetails(tmdbId);
            if (details != null) return details;
          }
          return ShowModel.fromTmdbJson(first);
        }
      }
    } catch (_) {}

    // Aşama 4: searchMulti çapraz arama
    try {
      final multiResults = await searchMulti(cleanTitle);
      final tvShows = multiResults.whereType<ShowModel>().toList();
      if (tvShows.isNotEmpty) {
        if (effectiveYear != null) {
          for (final s in tvShows) {
            final sYear = s.firstAirDate?.year;
            if (sYear != null && TitleSanitizer.isWithinYearTolerance(sYear, effectiveYear)) {
              return s;
            }
          }
        } else {
          return tvShows.first;
        }
      }
    } catch (_) {}

    return null;
  }

  TmdbClient get client => _client;

  /// Searches for a Movie by name on TMDB
  Future<MovieModel?> searchMovieByName(String query) async {
    return await searchMovieWithYear(query, null);
  }

  /// Searches for a Movie by name and optional release year on TMDB
  Future<MovieModel?> searchMovieWithYear(String title, int? year) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    // Try search with release year first if valid
    if (year != null && year > 1900) {
      final uriWithYear = TmdbEndpoints.searchMovie(cleanTitle, year: year);
      final responseWithYear = await _client.get(uriWithYear);
      final results = responseWithYear['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final first = results.first as Map<String, dynamic>;
        final tmdbId = first['id'] as int?;
        if (tmdbId != null) {
          final details = await getMovieDetails(tmdbId);
          if (details != null) return details;
        }
        return MovieModel.fromTmdbJson(first);
      }
    }

    // Fallback to query without year
    final uri = TmdbEndpoints.searchMovie(cleanTitle);
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

  /// Searches for a movie with a 4-stage fallback mechanism:
  /// Stage 1: Raw title search
  /// Stage 2: cleanTitle + primary_release_year (if year is available)
  /// Stage 3: cleanTitle unfiltered search + ±1 year tolerance matching
  /// Stage 4: searchMulti cross-media search
  Future<MovieModel?> searchMovieWithFallback(String rawTitle, {int? targetYear}) async {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) return null;

    final parsed = TitleSanitizer.parseTitleAndYear(trimmed);
    final cleanTitle = parsed.cleanTitle;
    final effectiveYear = targetYear ?? parsed.extractedYear;

    // Aşama 1: Raw title ile arama
    try {
      final candidate = await searchMovieByName(trimmed);
      if (candidate != null) {
        if (effectiveYear == null) return candidate;
        final candYear = candidate.releaseDate?.year;
        if (candYear != null && TitleSanitizer.isWithinYearTolerance(candYear, effectiveYear)) {
          return candidate;
        }
      }
    } catch (_) {}

    // Aşama 2: cleanTitle ve primary_release_year
    if (effectiveYear != null && effectiveYear > 1900) {
      try {
        final uri = TmdbEndpoints.searchMovie(cleanTitle, year: effectiveYear);
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
      } catch (_) {}
    }

    // Aşama 3: cleanTitle filtresiz arama + ±1 yıl tolerans kuralı
    try {
      final uri = TmdbEndpoints.searchMovie(cleanTitle);
      final response = await _client.get(uri);
      final results = response['results'] as List?;
      if (results != null && results.isNotEmpty) {
        if (effectiveYear != null) {
          for (final item in results) {
            if (item is! Map<String, dynamic>) continue;
            final dateStr = item['release_date'] as String?;
            final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
            final itemYear = date?.year;
            if (itemYear != null && TitleSanitizer.isWithinYearTolerance(itemYear, effectiveYear)) {
              final tmdbId = item['id'] as int?;
              if (tmdbId != null) {
                final details = await getMovieDetails(tmdbId);
                if (details != null) return details;
              }
              return MovieModel.fromTmdbJson(item);
            }
          }
        } else {
          final first = results.first as Map<String, dynamic>;
          final tmdbId = first['id'] as int?;
          if (tmdbId != null) {
            final details = await getMovieDetails(tmdbId);
            if (details != null) return details;
          }
          return MovieModel.fromTmdbJson(first);
        }
      }
    } catch (_) {}

    // Aşama 4: searchMulti çapraz arama
    try {
      final multiResults = await searchMulti(cleanTitle);
      final movies = multiResults.whereType<MovieModel>().toList();
      if (movies.isNotEmpty) {
        if (effectiveYear != null) {
          for (final m in movies) {
            final mYear = m.releaseDate?.year;
            if (mYear != null && TitleSanitizer.isWithinYearTolerance(mYear, effectiveYear)) {
              return m;
            }
          }
        } else {
          return movies.first;
        }
      }
    } catch (_) {}

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
