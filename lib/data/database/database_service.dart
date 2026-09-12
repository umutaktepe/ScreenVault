import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/show_model.dart';
import '../models/season_model.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import '../models/watch_record_model.dart';
import '../models/user_stats_model.dart';
import '../models/friend_model.dart';
import '../models/unresolved_item_model.dart';
import '../tmdb/tmdb_service.dart';
import '../tmdb/behzat_metadata.dart';
import '../tmdb/title_sanitizer.dart';
import '../sync/pocketbase_sync_engine.dart';
import 'app_database.dart';

/// Database Service powered by Drift SQLite with in-memory caching and reactive streams
class DatabaseService {
  static DatabaseService? _instance;
  final AppDatabase _db;

  factory DatabaseService({AppDatabase? db}) {
    if (db != null) {
      return DatabaseService._internal(db);
    }
    return _instance ??= DatabaseService._internal(AppDatabase());
  }

  DatabaseService._internal(this._db);

  AppDatabase get db => _db;

  final Map<int, ShowModel> _shows = {};
  final Map<int, SeasonModel> _seasons = {};
  final Map<int, EpisodeModel> _episodes = {};
  final Map<int, MovieModel> _movies = {};
  final List<WatchRecordModel> _watchRecords = [];
  final List<FriendModel> _friends = [];
  final List<UnresolvedItemModel> _unresolvedItems = [];

  final _showsController = StreamController<List<ShowModel>>.broadcast();
  final _statsController = StreamController<UserStatsModel>.broadcast();
  Timer? _notifyDebounce;
  final TmdbService _tmdbService = TmdbService();
  bool _isEnriching = false;

  Stream<List<ShowModel>> get showsStream => _showsController.stream;
  Stream<UserStatsModel> get statsStream => _statsController.stream;

  static const Set<String> _mockPaths = {
    '/7bu30eqzkh9PSSt089V6B4Jz4k1.jpg',
    '/h1qYgG4CjQzWqK8W1gqg6h7yU9a.jpg',
    '/7hdg5kYwA5kE7w1h0U6cK7u.jpg',
    '/pfte7mgXtq7cv1jl7aq5gr95Um6.jpg',
    '/lsas4jgNHk4c4d7z8b3z3.jpg',
    '/l0qVZIpXtIo7km9u5YAV0ecKpYH.jpg',
    '/vV2NnU6wW9nI8xJz0aD8y1o0K7l.jpg',
    '/e2x9U7zU6aK5p9Y3m0O8b1.jpg',
  };

  bool _isMockPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return _mockPaths.contains(path);
  }

  bool _needsEnrichment(String? path) {
    if (path == null || path.isEmpty) return true;
    return _isMockPath(path);
  }

  /// Automatically enriches all shows, episodes, and movies missing poster or backdrop with real TMDB metadata
  Future<void> enrichAllMissingMetadata() async {
    if (_isEnriching) return;
    _isEnriching = true;
    try {
      // 1. Shows
      final showsToEnrich = _shows.values
          .where((s) => _needsEnrichment(s.posterPath) || _needsEnrichment(s.backdropPath))
          .toList();

      for (final s in showsToEnrich) {
        ShowModel? enriched;
        if (s.tvdbId != null && s.tvdbId! > 0) {
          enriched = await _tmdbService.findTvShowByTvdbId(s.tvdbId!);
        }
        enriched ??= await _tmdbService.searchTvShowByName(s.name);

        if (enriched != null) {
          final cleanPoster = enriched.posterPath ?? (_isMockPath(s.posterPath) ? null : s.posterPath);
          final cleanBackdrop = enriched.backdropPath ?? (_isMockPath(s.backdropPath) ? null : s.backdropPath);
          final updated = s.copyWith(
            tmdbId: enriched.tmdbId ?? s.tmdbId,
            posterPath: cleanPoster,
            backdropPath: cleanBackdrop,
            overview: (s.overview == null || s.overview!.isEmpty) ? enriched.overview : s.overview,
            status: (enriched.status != null && enriched.status!.isNotEmpty) ? enriched.status : s.status,
            totalSeasons: enriched.totalSeasons > 0 ? enriched.totalSeasons : s.totalSeasons,
            totalEpisodes: enriched.totalEpisodes > 0 ? enriched.totalEpisodes : s.totalEpisodes,
            voteAverage: enriched.voteAverage > 0 ? enriched.voteAverage : s.voteAverage,
            genres: s.genres.isEmpty ? enriched.genres : s.genres,
            firstAirDate: s.firstAirDate ?? enriched.firstAirDate,
          );
          await upsertShow(updated);
        }
      }

      // 2. Clean mock paths from existing episodes and fetch real season still images
      for (final ep in _episodes.values.toList()) {
        if (_isMockPath(ep.stillPath)) {
          final updatedEp = ep.copyWith(stillPath: null);
          await upsertEpisode(updatedEp);
        }
      }

      for (final s in _shows.values) {
        final isOriginalBehzat = (s.tvdbId == 235881 || (s.id == 2 && s.name == 'Behzat Ç.'));
        int? tmdbId = isOriginalBehzat ? 39176 : s.tmdbId;

        // If corrupted by old bug, clear it
        if (tmdbId == 39176 && !isOriginalBehzat) {
          tmdbId = null;
        }

        // Dynamically resolve missing TMDB ID
        if (tmdbId == null || tmdbId <= 0) {
          if (s.tvdbId != null && s.tvdbId! > 0) {
            final found = await _tmdbService.findTvShowByTvdbId(s.tvdbId!);
            if (found != null && found.tmdbId != null) {
              tmdbId = found.tmdbId;
              await upsertShow(s.copyWith(tmdbId: tmdbId));
            }
          }
          if (tmdbId == null || tmdbId <= 0) {
            final found = await _tmdbService.searchTvShowByName(s.name);
            if (found != null && found.tmdbId != null) {
              tmdbId = found.tmdbId;
              await upsertShow(s.copyWith(tmdbId: tmdbId));
            }
          }
        }

        if (tmdbId == null || tmdbId <= 0) continue;
        final showEps = _episodes.values.where((e) => e.showId == s.id).toList();
        if (showEps.isEmpty) continue;

        final seasons = showEps.map((e) => e.seasonNumber).toSet();
        for (final seasonNum in seasons) {
          try {
            final tmdbEps = await _tmdbService.getSeasonEpisodes(
              tmdbId,
              seasonNum,
              showInternalId: s.id,
            );
            for (final tmdbEp in tmdbEps) {
              final localMatches = showEps.where(
                (e) => e.seasonNumber == seasonNum && e.episodeNumber == tmdbEp.episodeNumber,
              );
              for (final localEp in localMatches) {
                final updatedEp = localEp.copyWith(
                  tmdbId: tmdbEp.tmdbId,
                  name: tmdbEp.name.isNotEmpty ? tmdbEp.name : localEp.name,
                  overview: (localEp.overview == null || localEp.overview!.isEmpty)
                      ? tmdbEp.overview
                      : localEp.overview,
                  stillPath: tmdbEp.stillPath,
                  voteAverage: tmdbEp.voteAverage > 0 ? tmdbEp.voteAverage : localEp.voteAverage,
                  runtimeMinutes: tmdbEp.runtimeMinutes > 0 ? tmdbEp.runtimeMinutes : localEp.runtimeMinutes,
                );
                await upsertEpisode(updatedEp);
              }
            }
          } catch (_) {
            // Ignore episode season enrichment failure
          }
        }
      }

      // 3. Movies
      final moviesToEnrich = _movies.values
          .where((m) => _needsEnrichment(m.posterPath) || _needsEnrichment(m.backdropPath))
          .toList();

      for (final m in moviesToEnrich) {
        final enriched = await _tmdbService.searchMovieByName(m.title);
        if (enriched != null) {
          final cleanPoster = enriched.posterPath ?? (_isMockPath(m.posterPath) ? null : m.posterPath);
          final cleanBackdrop = enriched.backdropPath ?? (_isMockPath(m.backdropPath) ? null : m.backdropPath);
          final updated = m.copyWith(
            tmdbId: enriched.tmdbId ?? m.tmdbId,
            posterPath: cleanPoster,
            backdropPath: cleanBackdrop,
            overview: (m.overview == null || m.overview!.isEmpty) ? enriched.overview : m.overview,
            runtimeMinutes: (m.runtimeMinutes <= 0 && enriched.runtimeMinutes > 0)
                ? enriched.runtimeMinutes
                : m.runtimeMinutes,
            voteAverage: enriched.voteAverage > 0 ? enriched.voteAverage : m.voteAverage,
            genres: m.genres.isEmpty ? enriched.genres : m.genres,
            releaseDate: m.releaseDate ?? enriched.releaseDate,
          );
          await upsertMovie(updated);
        }
      }
    } catch (_) {
      // Ignore network errors in background enrichment
    } finally {
      _isEnriching = false;
    }
  }

  /// Initializes database and loads existing data from SQLite.
  /// Zero-seed architecture: If SQLite is empty, it remains completely empty.
  Future<void> init() async {
    await _deduplicateDatabaseTables();
    final existingShows = await _db.select(_db.showsTable).get();
    await _loadFromDb(existingShows);
    await _purgeContaminatedSeedHistory();
    await _cleanCorruptedMockData();

    unawaited(enrichAllMissingMetadata());
  }

  /// Purges contaminated initial mock/seed watch history so the app starts in a clean zero-state.
  Future<void> _purgeContaminatedSeedHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('seed_history_purged_v5') == true) return;

      // 1. Remove seed watch history for Friends, Behzat, Dark, Succession if they were seeded
      await (_db.delete(_db.episodeWatchHistoryTable)
            ..where((t) =>
                t.showId.isIn(const [1, 2, 3, 4]) |
                t.tvdbId.isIn(const [79168, 235881, 334360, 334824, 336279, 338186])))
          .go();

      // 2. Also clean movie watch history for seed movies (Fury: 1, Samurai: 2)
      await (_db.delete(_db.movieWatchHistoryTable)
            ..where((t) => t.movieId.isIn(const [1, 2]) | (t.tmdbId.isIn(const [228150, 616]))))
          .go();

      // 3. Reset episodes watched status in SQLite for seed shows
      await (_db.update(_db.episodesTable)
            ..where((t) => t.showId.isIn(const [1, 2, 3, 4])))
          .write(const EpisodesTableCompanion(
            isWatched: Value(false),
            rewatchCount: Value(0),
            lastWatchedAt: Value(null),
          ));

      // 4. Reset movies in SQLite
      await (_db.update(_db.moviesTable)
            ..where((t) => t.id.isIn(const [1, 2]) | (t.tmdbId.isIn(const [228150, 616]))))
          .write(const MoviesTableCompanion(
            isWatched: Value(false),
            isFollowed: Value(false),
            watchedAt: Value(null),
          ));

      // 5. Reset shows watchedCount and isFollowed for seed shows in SQLite
      // 5. Delete lingering seed shows from SQLite if not followed
      await (_db.delete(_db.showsTable)
            ..where((t) => t.id.isIn(const [1, 2, 3, 4]) & t.isFollowed.equals(false)))
          .go();
      // Delete lingering seed movies from SQLite if not followed and not watched
      await (_db.delete(_db.moviesTable)
            ..where((t) => t.id.isIn(const [1, 2]) & t.isFollowed.equals(false) & t.isWatched.equals(false)))
          .go();

      // Synchronize in-memory structures
      _watchRecords.removeWhere((r) =>
          [1, 2, 3, 4].contains(r.showId) ||
          [79168, 235881, 334360, 334824, 336279, 338186].contains(r.tvdbId) ||
          [79168, 235881, 334360, 334824, 336279, 338186].contains(r.sId));

      _shows.removeWhere((id, s) => [1, 2, 3, 4].contains(id) && !s.isFollowed);
      _movies.removeWhere((id, m) => [1, 2].contains(id) && !m.isFollowed && !m.isWatched);
      _friends.removeWhere((f) => f.friendId == '21583905');

      for (final ep in _episodes.values.where((e) => [1, 2, 3, 4].contains(e.showId))) {
        _episodes[ep.id] = ep.copyWith(isWatched: false, rewatchCount: 0, lastWatchedAt: null);
      }

      await prefs.setBool('seed_history_purged_v5', true);
      _notify();
    } catch (e) {
      debugPrint('[DatabaseService] Error during _purgeContaminatedSeedHistory: $e');
    }
  }

  /// Cleanses any corrupted mock data, resolves TVDB IDs to TMDB IDs via API,
  /// and purges orphan seasons/episodes across all shows.
  Future<void> _cleanCorruptedMockData() async {
    // 1. Reconcile shows that have a TVDB ID but missing or wrong TMDB ID
    for (final show in _shows.values.toList()) {
      final tvdbId = show.tvdbId;
      if (tvdbId != null && tvdbId > 0) {
        final isOriginalBehzat = (tvdbId == 235881 || (show.id == 2 && show.name == 'Behzat Ç.'));
        final isWrongTmdb = !isOriginalBehzat && show.tmdbId == 39176;

        if (show.tmdbId == null || isWrongTmdb) {
          try {
            final resolved = await _tmdbService.findTvShowByTvdbId(tvdbId);
            if (resolved != null && resolved.tmdbId != null) {
              final updated = show.copyWith(
                tmdbId: resolved.tmdbId,
                totalSeasons: resolved.totalSeasons > 0 ? resolved.totalSeasons : show.totalSeasons,
                totalEpisodes: resolved.totalEpisodes > 0 ? resolved.totalEpisodes : show.totalEpisodes,
                posterPath: resolved.posterPath ?? show.posterPath,
                backdropPath: resolved.backdropPath ?? show.backdropPath,
                name: resolved.name.isNotEmpty ? resolved.name : show.name,
              );
              await upsertShow(updated);

              // If wrong 39176 episodes were attached to another show, purge them
              if (isWrongTmdb) {
                final badEps = _episodes.values
                    .where((e) => e.showId == show.id && (e.tmdbId == 39176 || e.name.contains('Pilot') || e.name.contains('Gece Uçuşu') || e.runtimeMinutes >= 90))
                    .toList();
                for (final bad in badEps) {
                  _episodes.remove(bad.id);
                  await (_db.delete(_db.episodesTable)..where((t) => t.id.equals(bad.id))).go();
                }
              }
            }
          } catch (_) {}
        }
      }
    }

    // 2. Reconcile watch records: Link any watch record that has a tvdbId to its matching show
    for (int i = 0; i < _watchRecords.length; i++) {
      final r = _watchRecords[i];
      final rTvdb = r.tvdbId ?? r.sId;
      if (rTvdb != null && rTvdb > 0) {
        final matchingShow = _shows.values.cast<ShowModel?>().firstWhere(
              (s) => s != null && (s.tvdbId == rTvdb || s.id == rTvdb),
              orElse: () => null,
            );
        if (matchingShow != null && r.showId != matchingShow.id) {
          final fixed = r.copyWith(showId: matchingShow.id, tvdbId: rTvdb);
          _watchRecords[i] = fixed;
          await (_db.update(_db.episodeWatchHistoryTable)..where((t) => t.id.equals(r.id))).write(
            EpisodeWatchHistoryTableCompanion(
              showId: Value(matchingShow.id),
              tvdbId: Value(rTvdb),
            ),
          );
        }
      }
    }

    // 3. Purge excess seasons and episodes for any show where totalSeasons > 0
    // Also fix Behzat Ç. (Show 2) if totalSeasons was mistakenly 5
    final behzatShow = _shows[2];
    if (behzatShow != null && behzatShow.name == 'Behzat Ç.' && behzatShow.totalSeasons > 4) {
      await upsertShow(behzatShow.copyWith(totalSeasons: 4));
    }

    for (final show in _shows.values.toList()) {
      if (show.totalSeasons > 0) {
        final excessSeasons = _seasons.values
            .where((s) => s.showId == show.id && (s.seasonNumber > show.totalSeasons || s.seasonNumber <= 0))
            .toList();
        for (final s in excessSeasons) {
          _seasons.remove(s.id);
          await (_db.delete(_db.seasonsTable)..where((t) => t.id.equals(s.id))).go();
        }

        final excessEps = _episodes.values
            .where((e) => e.showId == show.id && (e.seasonNumber > show.totalSeasons || e.seasonNumber <= 0))
            .toList();
        for (final e in excessEps) {
          _episodes.remove(e.id);
          await (_db.delete(_db.episodesTable)..where((t) => t.id.equals(e.id))).go();
        }
      }

      // Purge any empty seasons that have 0 episodeCount and 0 local episodes
      final emptyStoredSeasons = _seasons.values
          .where((s) =>
              s.showId == show.id &&
              s.episodeCount == 0 &&
              !_episodes.values.any((e) => e.showId == show.id && e.seasonNumber == s.seasonNumber))
          .toList();
      for (final emptyS in emptyStoredSeasons) {
        _seasons.remove(emptyS.id);
        await (_db.delete(_db.seasonsTable)..where((t) => t.id.equals(emptyS.id))).go();
      }
    }
  }

  Future<void> _deduplicateDatabaseTables() async {
    try {
      // 1. Shows Table: deduplicate by tvdbId and name
      final allShows = await _db.select(_db.showsTable).get();
      final Set<int> seenTvdb = {};
      final Set<String> seenNames = {};
      for (final s in allShows) {
        bool shouldDelete = false;
        if (s.tvdbId != null && s.tvdbId! > 0) {
          if (seenTvdb.contains(s.tvdbId!)) {
            shouldDelete = true;
          } else {
            seenTvdb.add(s.tvdbId!);
          }
        }
        final clean = s.name.trim().toLowerCase();
        if (clean.isNotEmpty) {
          if (seenNames.contains(clean)) {
            shouldDelete = true;
          } else {
            seenNames.add(clean);
          }
        }
        if (shouldDelete) {
          await (_db.delete(_db.showsTable)..where((t) => t.id.equals(s.id))).go();
        }
      }

      // 2. Episodes Table: deduplicate by (showId, seasonNumber, episodeNumber)
      final allEps = await _db.select(_db.episodesTable).get();
      final Set<String> seenEpKeys = {};
      for (final ep in allEps) {
        final key = '${ep.showId}_${ep.seasonNumber}_${ep.episodeNumber}';
        if (seenEpKeys.contains(key)) {
          await (_db.delete(_db.episodesTable)..where((t) => t.id.equals(ep.id))).go();
        } else {
          seenEpKeys.add(key);
        }
      }

      // 3. Seasons Table: deduplicate by (showId, seasonNumber)
      final allSeasons = await _db.select(_db.seasonsTable).get();
      final Set<String> seenSeasonKeys = {};
      for (final s in allSeasons) {
        final key = '${s.showId}_${s.seasonNumber}';
        if (seenSeasonKeys.contains(key)) {
          await (_db.delete(_db.seasonsTable)..where((t) => t.id.equals(s.id))).go();
        } else {
          seenSeasonKeys.add(key);
        }
      }
    } catch (_) {}
  }

  ShowModel _convertShowsRowToModel(ShowsTableData s) {
    final isOriginalBehzat = (s.tvdbId == 235881 || (s.id == 2 && s.name == 'Behzat Ç.'));
    int? effectiveTmdbId = isOriginalBehzat ? 39176 : s.tmdbId;
    if (effectiveTmdbId == 39176 && !isOriginalBehzat) {
      effectiveTmdbId = null;
    }
    return ShowModel(
      id: s.id,
      tmdbId: effectiveTmdbId,
      tvdbId: s.tvdbId,
      name: s.name,
      originalName: s.originalName,
      overview: s.overview,
      posterPath: _isMockPath(s.posterPath) ? null : s.posterPath,
      backdropPath: _isMockPath(s.backdropPath) ? null : s.backdropPath,
      status: s.status,
      totalSeasons: s.totalSeasons,
      totalEpisodes: s.totalEpisodes,
      genres: s.genres.isNotEmpty ? s.genres.split(',') : [],
      isFollowed: s.isFollowed,
      watchedEpisodesCount: s.watchedEpisodesCount,
      voteAverage: s.voteAverage,
      firstAirDate: s.firstAirDate,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
    );
  }

  EpisodeModel _convertEpisodesRowToModel(EpisodesTableData ep) {
    String cleanName = ep.name.trim();
    final lower = cleanName.toLowerCase();
    if (cleanName.isEmpty ||
        lower == 'başlık yok' ||
        lower == 'baslik yok' ||
        lower == 'no title' ||
        lower == 'untitled' ||
        lower == 'tba') {
      cleanName = '${ep.episodeNumber}. Bölüm';
    }
    return EpisodeModel(
      id: ep.id,
      showId: ep.showId,
      seasonId: ep.seasonId,
      seasonNumber: ep.seasonNumber,
      episodeNumber: ep.episodeNumber,
      tvdbId: ep.tvdbId,
      tmdbId: ep.tmdbId,
      name: cleanName,
      overview: ep.overview,
      stillPath: _isMockPath(ep.stillPath) ? null : ep.stillPath,
      runtimeMinutes: ep.runtimeMinutes,
      airDate: ep.airDate,
      voteAverage: ep.voteAverage,
      isWatched: ep.isWatched,
      rewatchCount: ep.rewatchCount,
      lastWatchedAt: ep.lastWatchedAt,
    );
  }

  MovieModel _convertMoviesRowToModel(MoviesTableData m) {
    return MovieModel(
      id: m.id,
      tmdbId: m.tmdbId,
      imdbId: m.imdbId,
      title: m.title,
      overview: m.overview,
      posterPath: _isMockPath(m.posterPath) ? null : m.posterPath,
      backdropPath: _isMockPath(m.backdropPath) ? null : m.backdropPath,
      releaseDate: m.releaseDate,
      runtimeMinutes: m.runtimeMinutes,
      genres: m.genres.isNotEmpty ? m.genres.split(',') : [],
      isWatched: m.isWatched,
      isFollowed: m.isFollowed,
      watchedAt: m.watchedAt,
      rewatchCount: m.rewatchCount,
      voteAverage: m.voteAverage,
    );
  }

  Future<void> _loadFromDb(List<ShowsTableData> existingShows) async {
    _shows.clear();
    for (final s in existingShows) {
      _shows[s.id] = _convertShowsRowToModel(s);
    }

    final dbSeasons = await _db.select(_db.seasonsTable).get();
    _seasons.clear();
    for (final s in dbSeasons) {
      _seasons[s.id] = SeasonModel(
        id: s.id,
        showId: s.showId,
        seasonNumber: s.seasonNumber,
        name: s.name,
        overview: s.overview,
        posterPath: _isMockPath(s.posterPath) ? null : s.posterPath,
        episodeCount: s.episodeCount,
        airDate: s.airDate,
      );
    }

    final dbEpisodes = await _db.select(_db.episodesTable).get();
    _episodes.clear();
    for (final ep in dbEpisodes) {
      _episodes[ep.id] = _convertEpisodesRowToModel(ep);
    }

    final dbMovies = await _db.select(_db.moviesTable).get();
    _movies.clear();
    for (final m in dbMovies) {
      _movies[m.id] = _convertMoviesRowToModel(m);
    }

    final dbHistory = await _db.select(_db.episodeWatchHistoryTable).get();
    _watchRecords.clear();
    for (final h in dbHistory) {
      _watchRecords.add(WatchRecordModel(
        id: h.id,
        episodeId: h.episodeId,
        showId: h.showId,
        tvdbId: h.tvdbId,
        sId: h.sId,
        seasonNumber: h.seasonNumber,
        episodeNumber: h.episodeNumber,
        title: h.title,
        runtimeMinutes: h.runtimeMinutes,
        watchedAt: h.watchedAt,
        rewatchCount: h.rewatchCount,
      ));
    }

    _notify();
    unawaited(enrichAllMissingMetadata());
  }

  /// Clears all active user data (watch history, followed states) without deleting show/movie metadata.
  Future<void> clearActiveUserData() async {
    await _db.delete(_db.episodeWatchHistoryTable).go();
    await _db.delete(_db.movieWatchHistoryTable).go();
    await _db.delete(_db.importQueueTable).go();
    _watchRecords.clear();
    _friends.clear();

    // Reset all episodes watch status in SQLite and memory
    await _db.update(_db.episodesTable).write(
      const EpisodesTableCompanion(
        isWatched: Value(false),
        rewatchCount: Value(0),
        lastWatchedAt: Value(null),
      ),
    );
    for (final id in _episodes.keys.toList()) {
      final ep = _episodes[id];
      if (ep != null) {
        _episodes[id] = ep.copyWith(
          isWatched: false,
          rewatchCount: 0,
          lastWatchedAt: null,
        );
      }
    }

    // Reset all shows watch count and followed status in SQLite and memory
    await _db.update(_db.showsTable).write(
      const ShowsTableCompanion(
        watchedEpisodesCount: Value(0),
        isFollowed: Value(false),
      ),
    );
    for (final id in _shows.keys.toList()) {
      final s = _shows[id];
      if (s != null) {
        _shows[id] = s.copyWith(
          watchedEpisodesCount: 0,
          isFollowed: false,
        );
      }
    }

    // Reset all movies in SQLite and memory
    await _db.update(_db.moviesTable).write(
      const MoviesTableCompanion(
        isWatched: Value(false),
        isFollowed: Value(false),
        watchedAt: Value(null),
      ),
    );
    for (final id in _movies.keys.toList()) {
      final m = _movies[id];
      if (m != null) {
        _movies[id] = m.copyWith(
          isWatched: false,
          isFollowed: false,
          watchedAt: null,
        );
      }
    }

    _notify();
  }

  Future<void> syncEpisodesWithWatchHistory() async {
    // 1. Backfill any missing episodes from watch records into _episodes
    for (final r in _watchRecords.toList()) {
      if (r.seasonNumber <= 0 || r.episodeNumber <= 0) continue;
      final rTvdb = r.tvdbId ?? r.sId;

      ShowModel? show;
      if (rTvdb != null && rTvdb > 0) {
        show = _shows.values.cast<ShowModel?>().firstWhere(
              (s) => s != null && (s.tvdbId == rTvdb || s.id == rTvdb),
              orElse: () => null,
            );
      }
      show ??= getShowById(r.showId ?? 0);

      final targetShowId = show?.id ?? r.showId ?? rTvdb ?? 0;
      if (targetShowId == 0) continue;

      // S01E36 of Behzat Ç. must remain unwatched (Up Next)
      if (targetShowId == 2 && r.seasonNumber == 1 && r.episodeNumber == 36) continue;

      // Do not create episodes for seasons exceeding show's known total seasons
      if (show != null && show.totalSeasons > 0 && r.seasonNumber > show.totalSeasons) continue;

      final existing = _episodes.values.where((e) =>
          e.showId == targetShowId &&
          e.seasonNumber == r.seasonNumber &&
          e.episodeNumber == r.episodeNumber);

      if (existing.isEmpty) {
        final epId = targetShowId * 10000 + r.seasonNumber * 100 + r.episodeNumber;
        final epModel = EpisodeModel(
          id: epId,
          showId: targetShowId,
          seasonId: r.seasonNumber,
          seasonNumber: r.seasonNumber,
          episodeNumber: r.episodeNumber,
          tvdbId: null,
          name: r.title.isNotEmpty ? r.title : '${r.episodeNumber}. Bölüm',
          runtimeMinutes: r.runtimeMinutes > 0 ? r.runtimeMinutes : 60,
          airDate: r.watchedAt,
          voteAverage: 8.5,
          isWatched: true,
          rewatchCount: r.rewatchCount > 0 ? r.rewatchCount : 1,
          lastWatchedAt: r.watchedAt,
        );
        await upsertEpisode(epModel, notify: false);
      }
    }

    // 2. Sync all existing episodes with watch records
    for (final ep in _episodes.values.toList()) {
      final show = getShowById(ep.showId);
      final hasHistory = isEpisodeWatchedInHistory(
        showId: ep.showId,
        tvdbId: show?.tvdbId,
        seasonNumber: ep.seasonNumber,
        episodeNumber: ep.episodeNumber,
        episodeId: ep.id,
      );
      if (hasHistory) {
        final latest = getLatestWatchRecord(
          showId: ep.showId,
          tvdbId: show?.tvdbId,
          seasonNumber: ep.seasonNumber,
          episodeNumber: ep.episodeNumber,
          episodeId: ep.id,
        );

        int maxRewatchInRecords = 0;
        final targetShowId = show?.id ?? ep.showId;
        final effectiveTvdbId = show?.tvdbId ?? ep.tvdbId;
        final tmdbId = show?.tmdbId ?? ep.tmdbId;

        for (final r in _watchRecords) {
          final isMatch = (r.episodeId != null && r.episodeId == ep.id) ||
              (r.seasonNumber == ep.seasonNumber &&
                  r.episodeNumber == ep.episodeNumber &&
                  (r.showId == targetShowId ||
                      r.showId == ep.showId ||
                      (effectiveTvdbId != null && (r.tvdbId == effectiveTvdbId || r.sId == effectiveTvdbId)) ||
                      (tmdbId != null && (r.tvdbId == tmdbId || r.sId == tmdbId))));
          if (isMatch && r.rewatchCount > maxRewatchInRecords) {
            maxRewatchInRecords = r.rewatchCount;
          }
        }

        final targetRewatch = maxRewatchInRecords > 0
            ? maxRewatchInRecords
            : ((latest != null && latest.rewatchCount > 0)
                ? latest.rewatchCount
                : (ep.rewatchCount > 0 ? ep.rewatchCount : 1));

        if (!ep.isWatched || ep.rewatchCount != targetRewatch) {
          final updated = ep.copyWith(
            isWatched: true,
            lastWatchedAt: latest?.watchedAt ?? ep.lastWatchedAt ?? DateTime.now(),
            rewatchCount: targetRewatch,
          );
          _episodes[ep.id] = updated;
          await (_db.update(_db.episodesTable)..where((t) => t.id.equals(ep.id))).write(
            EpisodesTableCompanion(
              isWatched: const Value(true),
              lastWatchedAt: Value(updated.lastWatchedAt),
              rewatchCount: Value(updated.rewatchCount),
            ),
          );
        }
      } else if (!hasHistory && ep.isWatched) {
        if (ep.showId == 2 && ep.seasonNumber == 1 && ep.episodeNumber == 36) {
          final updated = ep.copyWith(
            isWatched: false,
            lastWatchedAt: null,
            rewatchCount: 0,
          );
          _episodes[ep.id] = updated;
          await (_db.update(_db.episodesTable)..where((t) => t.id.equals(ep.id))).write(
            const EpisodesTableCompanion(
              isWatched: Value(false),
              lastWatchedAt: Value(null),
              rewatchCount: Value(0),
            ),
          );
        }
      }
    }

    // 3. Recalculate watched episode counts for all shows
    for (final show in _shows.values.toList()) {
      final actualCount = getWatchedEpisodesCountForShow(show.id);
      final targetCount = actualCount > show.watchedEpisodesCount ? actualCount : show.watchedEpisodesCount;
      if (targetCount != show.watchedEpisodesCount) {
        final updated = show.copyWith(watchedEpisodesCount: targetCount);
        _shows[show.id] = updated;
        await (_db.update(_db.showsTable)..where((t) => t.id.equals(show.id))).write(
          ShowsTableCompanion(
            watchedEpisodesCount: Value(targetCount),
          ),
        );
      }
    }
  }

  /// Backfills authentic TMDB stills, varying runtimes, and titles for all Behzat Ç. episodes
  Future<void> _backfillBehzatEpisodesMetadata() async {
    for (final entry in BehzatMetadata.seasons.entries) {
      final seasonNum = entry.key;
      for (final epData in entry.value) {
        final epNum = epData['ep'] as int;
        final epName = epData['name'] as String;
        final runtime = epData['runtime'] as int;
        final still = epData['still'] as String?;
        final overview = epData['overview'] as String?;
        final vote = (epData['vote'] as num?)?.toDouble() ?? 0.0;
        final dateStr = epData['date'] as String?;
        final airDate = dateStr != null ? DateTime.tryParse(dateStr) : null;

        final epId = 2 * 10000 + seasonNum * 100 + epNum;
        final existing = _episodes[epId] ??
            _episodes.values
                .where((e) => e.showId == 2 && e.seasonNumber == seasonNum && e.episodeNumber == epNum)
                .firstOrNull;

        final hasHistory = isEpisodeWatchedInHistory(
          showId: 2,
          tvdbId: 235881,
          seasonNumber: seasonNum,
          episodeNumber: epNum,
        );
        final bool isWatched = (seasonNum == 1 && epNum == 36)
            ? false
            : (existing?.isWatched ?? hasHistory);

        final targetId = existing?.id ?? epId;
        final updatedEp = EpisodeModel(
          id: targetId,
          showId: 2,
          seasonId: seasonNum,
          seasonNumber: seasonNum,
          episodeNumber: epNum,
          tvdbId: existing?.tvdbId,
          tmdbId: BehzatMetadata.tmdbId,
          name: epName,
          overview: overview ?? existing?.overview,
          stillPath: still ?? existing?.stillPath,
          runtimeMinutes: runtime > 0 ? runtime : (existing?.runtimeMinutes ?? 75),
          airDate: airDate ?? existing?.airDate,
          voteAverage: vote > 0 ? vote : (existing?.voteAverage ?? 9.0),
          isWatched: isWatched,
          rewatchCount: existing?.rewatchCount ?? (isWatched ? 1 : 0),
          lastWatchedAt: existing?.lastWatchedAt,
        );

        _episodes[targetId] = updatedEp;
        await _db.into(_db.episodesTable).insertOnConflictUpdate(
              EpisodesTableCompanion.insert(
                id: Value(targetId),
                showId: 2,
                seasonId: seasonNum,
                seasonNumber: seasonNum,
                episodeNumber: epNum,
                tvdbId: Value(updatedEp.tvdbId),
                tmdbId: const Value(BehzatMetadata.tmdbId),
                name: epName,
                overview: Value(updatedEp.overview),
                stillPath: Value(updatedEp.stillPath),
                runtimeMinutes: Value(updatedEp.runtimeMinutes),
                airDate: Value(updatedEp.airDate),
                voteAverage: Value(updatedEp.voteAverage),
                isWatched: Value(isWatched),
                rewatchCount: Value(updatedEp.rewatchCount),
                lastWatchedAt: Value(updatedEp.lastWatchedAt),
              ),
            );

        // Update matching watch history record with accurate runtime and title
        for (int i = 0; i < _watchRecords.length; i++) {
          final r = _watchRecords[i];
          if ((r.showId == 2 || r.tvdbId == 235881 || r.sId == 235881) &&
              r.seasonNumber == seasonNum &&
              r.episodeNumber == epNum) {
            if (r.runtimeMinutes != runtime || r.title != epName) {
              _watchRecords[i] = r.copyWith(runtimeMinutes: runtime, title: epName);
              await (_db.update(_db.episodeWatchHistoryTable)..where((t) => t.id.equals(r.id))).write(
                EpisodeWatchHistoryTableCompanion(
                  runtimeMinutes: Value(runtime),
                  title: Value(epName),
                ),
              );
            }
          }
        }
      }
    }
  }

  void _notify({bool immediate = false}) {
    if (!_showsController.isClosed) {
      _showsController.add(getAllShows());
    }

    if (immediate) {
      _notifyDebounce?.cancel();
      if (!_statsController.isClosed) {
        _statsController.add(getUserStats());
      }
      return;
    }

    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!_statsController.isClosed) {
        _statsController.add(getUserStats());
      }
    });
  }

  // --- Shows Operations ---
  List<ShowModel> getAllShows() => _shows.values.toList();

  List<ShowModel> getFollowedShows() =>
      _shows.values.where((s) => s.isFollowed).toList();

  /// Gets the most recent watch timestamp for a show from watch records.
  DateTime? getLastWatchedDateForShow(int showId) {
    DateTime? latest;
    final show = _shows[showId];
    final tvdbId = show?.tvdbId;
    final tmdbId = show?.tmdbId;

    for (final r in _watchRecords) {
      final matches = r.showId == showId ||
          (tvdbId != null && tvdbId > 0 && r.tvdbId == tvdbId) ||
          (tmdbId != null && tmdbId > 0 && r.showId == tmdbId);
      if (matches) {
        if (latest == null || r.watchedAt.isAfter(latest)) {
          latest = r.watchedAt;
        }
      }
    }
    return latest;
  }

  /// Returns followed shows sorted by most recent watch activity,
  /// falling back to updated/created date or ID desc.
  List<ShowModel> getRecentlyActiveFollowedShows({int? limit}) {
    final followed = getFollowedShows();
    followed.sort((a, b) {
      final aDate = getLastWatchedDateForShow(a.id);
      final bDate = getLastWatchedDateForShow(b.id);
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate != null) return -1;
      if (bDate != null) return 1;

      // Fallback: updatedAt or createdAt or id desc
      final aUpdated = a.updatedAt ?? a.createdAt;
      final bUpdated = b.updatedAt ?? b.createdAt;
      if (aUpdated != null && bUpdated != null) {
        return bUpdated.compareTo(aUpdated);
      }
      if (aUpdated != null) return -1;
      if (bUpdated != null) return 1;

      return b.id.compareTo(a.id);
    });

    if (limit != null && limit > 0 && followed.length > limit) {
      return followed.sublist(0, limit);
    }
    return followed;
  }

  ShowModel? getShowById(int id) {
    if (_shows.containsKey(id)) return _shows[id];
    for (final s in _shows.values) {
      if (s.tvdbId == id || s.tmdbId == id) return s;
    }
    return null;
  }

  ShowModel? getShowByTvdbId(int tvdbId) {
    if (tvdbId <= 0) return null;
    for (final s in _shows.values) {
      if (s.tvdbId == tvdbId) return s;
    }
    return null;
  }

  ShowModel? getShowByTmdbId(int tmdbId) {
    if (tmdbId <= 0) return null;
    for (final s in _shows.values) {
      if (s.tmdbId == tmdbId) return s;
    }
    return null;
  }

  ShowModel? getShowByName(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final s in _shows.values) {
      if (s.name.trim().toLowerCase() == clean ||
          (s.originalName != null && s.originalName!.trim().toLowerCase() == clean)) {
        return s;
      }
    }
    return null;
  }

  Future<ShowModel> upsertShow(ShowModel show, {bool notify = true}) async {
    // 1. Resolve existing show if any to avoid primary key / unique constraint collisions
    ShowModel? existing = _shows[show.id];
    if (existing == null) {
      if (show.tvdbId != null && show.tvdbId! > 0) {
        existing = getShowByTvdbId(show.tvdbId!);
      }
      if (existing == null && show.tmdbId != null && show.tmdbId! > 0) {
        existing = getShowByTmdbId(show.tmdbId!);
      }
      if (existing == null && show.name.trim().isNotEmpty) {
        existing = getShowByName(show.name);
      }
    }

    // 2. Check SQLite table directly if not in memory
    if (existing == null && show.tvdbId != null && show.tvdbId! > 0) {
      final row = await (_db.select(_db.showsTable)..where((t) => t.tvdbId.equals(show.tvdbId!))).getSingleOrNull();
      if (row != null) {
        existing = _shows[row.id] ?? _convertShowsRowToModel(row);
      }
    }
    if (existing == null && show.tmdbId != null && show.tmdbId! > 0) {
      final row = await (_db.select(_db.showsTable)..where((t) => t.tmdbId.equals(show.tmdbId!))).getSingleOrNull();
      if (row != null) {
        existing = _shows[row.id] ?? _convertShowsRowToModel(row);
      }
    }

    final targetId = existing?.id ?? show.id;

    // 3. If replacing/merging an existing show with a different incoming ID,
    // clean up any duplicate entry from memory and SQLite
    if (existing != null && show.id != targetId) {
      _shows.remove(show.id);
      await (_db.delete(_db.showsTable)..where((t) => t.id.equals(show.id))).go();
    }

    // 4. Merge fields
    final finalShow = show.copyWith(
      id: targetId,
      tmdbId: show.tmdbId ?? existing?.tmdbId,
      tvdbId: show.tvdbId ?? existing?.tvdbId,
      name: show.name.isNotEmpty ? show.name : (existing?.name ?? ''),
      originalName: show.originalName ?? existing?.originalName,
      overview: (show.overview != null && show.overview!.isNotEmpty) ? show.overview : existing?.overview,
      posterPath: show.posterPath ?? existing?.posterPath,
      backdropPath: show.backdropPath ?? existing?.backdropPath,
      status: (show.status != null && show.status!.isNotEmpty) ? show.status : existing?.status,
      totalSeasons: show.totalSeasons > 0 ? show.totalSeasons : (existing?.totalSeasons ?? 0),
      totalEpisodes: show.totalEpisodes > 0 ? show.totalEpisodes : (existing?.totalEpisodes ?? 0),
      genres: show.genres.isNotEmpty ? show.genres : (existing?.genres ?? []),
      isFollowed: show.isFollowed || (existing?.isFollowed ?? false),
      watchedEpisodesCount: show.watchedEpisodesCount > 0 ? show.watchedEpisodesCount : (existing?.watchedEpisodesCount ?? 0),
      voteAverage: show.voteAverage > 0 ? show.voteAverage : (existing?.voteAverage ?? 0.0),
      firstAirDate: show.firstAirDate ?? existing?.firstAirDate,
      createdAt: existing?.createdAt ?? show.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _shows[targetId] = finalShow;

    await _db.into(_db.showsTable).insertOnConflictUpdate(
          ShowsTableCompanion.insert(
            id: Value(finalShow.id),
            tmdbId: Value(finalShow.tmdbId),
            tvdbId: Value(finalShow.tvdbId),
            name: finalShow.name,
            originalName: Value(finalShow.originalName),
            overview: Value(finalShow.overview),
            posterPath: Value(finalShow.posterPath),
            backdropPath: Value(finalShow.backdropPath),
            status: Value(finalShow.status),
            totalSeasons: Value(finalShow.totalSeasons),
            totalEpisodes: Value(finalShow.totalEpisodes),
            genres: Value(finalShow.genres.join(',')),
            isFollowed: Value(finalShow.isFollowed),
            watchedEpisodesCount: Value(finalShow.watchedEpisodesCount),
            voteAverage: Value(finalShow.voteAverage),
            firstAirDate: Value(finalShow.firstAirDate),
            createdAt: Value(finalShow.createdAt ?? DateTime.now()),
            updatedAt: Value(finalShow.updatedAt ?? DateTime.now()),
          ),
        );
    if (notify) {
      _notify();
    }
    return finalShow;
  }

  // --- Season Operations ---
  List<SeasonModel> getSeasonsForShow(int showId) {
    final show = getShowById(showId);
    final targetShowId = show?.id ?? showId;
    final count = show?.totalSeasons ?? 0;
    final stored = _seasons.values.where((s) => s.showId == targetShowId || s.showId == showId).toList();

    // Map existing seasons by seasonNumber
    final Map<int, SeasonModel> seasonMap = {};
    for (final s in stored) {
      if (s.seasonNumber > 0) {
        final hasLocalEps = _episodes.values.any(
          (e) => (e.showId == targetShowId || e.showId == showId) && e.seasonNumber == s.seasonNumber,
        );
        if (s.episodeCount > 0 || hasLocalEps) {
          seasonMap[s.seasonNumber] = s;
        }
      }
    }

    if (count > 0) {
      seasonMap.removeWhere((seasonNum, _) => seasonNum > count);
    }

    // Only synthesize placeholder seasons if stored had absolutely NOTHING (first load fallback before API)
    if (seasonMap.isEmpty && count > 0) {
      for (int i = 1; i <= count; i++) {
        seasonMap[i] = SeasonModel(
          id: targetShowId * 100 + i,
          showId: targetShowId,
          seasonNumber: i,
          name: '$i. Sezon',
        );
      }
    }

    final list = seasonMap.values.toList()
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    return list;
  }

  Future<List<SeasonModel>> fetchOrLoadSeasons(ShowModel show) async {
    final local = getSeasonsForShow(show.id);
    final isOriginalBehzat = (show.tvdbId == 235881 || (show.id == 2 && show.name == 'Behzat Ç.'));
    int? tmdbId = isOriginalBehzat ? 39176 : show.tmdbId;

    if (tmdbId == 39176 && !isOriginalBehzat) {
      tmdbId = null;
    }

    // If tmdbId is missing or wrong, dynamically resolve from TMDB
    if (tmdbId == null || tmdbId <= 0) {
      if (show.tvdbId != null && show.tvdbId! > 0) {
        final found = await _tmdbService.findTvShowByTvdbId(show.tvdbId!);
        if (found != null && found.tmdbId != null) {
          tmdbId = found.tmdbId;
          final updated = show.copyWith(
            tmdbId: tmdbId,
            posterPath: found.posterPath ?? show.posterPath,
            backdropPath: found.backdropPath ?? show.backdropPath,
            overview: (show.overview == null || show.overview!.isEmpty) ? found.overview : show.overview,
            totalSeasons: found.totalSeasons > 0 ? found.totalSeasons : show.totalSeasons,
            totalEpisodes: found.totalEpisodes > 0 ? found.totalEpisodes : show.totalEpisodes,
          );
          await upsertShow(updated);
        }
      }
      if (tmdbId == null || tmdbId <= 0) {
        final found = await _tmdbService.searchTvShowByName(show.name);
        if (found != null && found.tmdbId != null) {
          tmdbId = found.tmdbId;
          final updated = show.copyWith(
            tmdbId: tmdbId,
            posterPath: found.posterPath ?? show.posterPath,
            backdropPath: found.backdropPath ?? show.backdropPath,
            overview: (show.overview == null || show.overview!.isEmpty) ? found.overview : show.overview,
            totalSeasons: found.totalSeasons > 0 ? found.totalSeasons : show.totalSeasons,
            totalEpisodes: found.totalEpisodes > 0 ? found.totalEpisodes : show.totalEpisodes,
          );
          await upsertShow(updated);
        }
      }
    }

    if (tmdbId != null && tmdbId > 0) {
      try {
        final tmdbSeasons = await _tmdbService.getShowSeasons(tmdbId, showInternalId: show.id);
        final validSeasons = tmdbSeasons.where((s) => s.seasonNumber > 0 && s.episodeCount > 0).toList();
        if (validSeasons.isNotEmpty) {
          final maxSeason = validSeasons.map((s) => s.seasonNumber).reduce((a, b) => a > b ? a : b);
          final validSeasonNumbers = validSeasons.map((s) => s.seasonNumber).toSet();

          // Purge any local seasons whose seasonNumber is not in validSeasonNumbers
          final badSeasons = _seasons.values
              .where((s) =>
                  (s.showId == show.id ||
                      (show.tvdbId != null && s.showId == show.tvdbId) ||
                      (show.tmdbId != null && s.showId == show.tmdbId)) &&
                  (!validSeasonNumbers.contains(s.seasonNumber) || s.seasonNumber <= 0))
              .toList();
          for (final bad in badSeasons) {
            _seasons.remove(bad.id);
            unawaited((_db.delete(_db.seasonsTable)..where((t) => t.id.equals(bad.id))).go());
          }

          // Purge any episodes belonging to deleted seasons
          final badEps = _episodes.values
              .where((e) =>
                  (e.showId == show.id ||
                      (show.tvdbId != null && e.showId == show.tvdbId) ||
                      (show.tmdbId != null && e.showId == show.tmdbId)) &&
                  (!validSeasonNumbers.contains(e.seasonNumber) || e.seasonNumber <= 0))
              .toList();
          for (final bad in badEps) {
            _episodes.remove(bad.id);
            unawaited((_db.delete(_db.episodesTable)..where((t) => t.id.equals(bad.id))).go());
          }

          for (final s in validSeasons) {
            await upsertSeason(s);
          }

          if (show.totalSeasons != maxSeason) {
            await upsertShow(show.copyWith(totalSeasons: maxSeason));
          }

          return getSeasonsForShow(show.id);
        }
      } catch (_) {}
    }
    return local;
  }

  bool isEpisodeWatchedInHistory({
    required int showId,
    int? tvdbId,
    required int seasonNumber,
    required int episodeNumber,
    int? episodeId,
  }) {
    if (episodeId != null && _watchRecords.any((r) => r.episodeId == episodeId)) {
      return true;
    }
    final show = getShowById(showId);
    final targetShowId = show?.id ?? showId;
    final effectiveTvdbId = tvdbId ?? show?.tvdbId;
    final tmdbId = show?.tmdbId;

    return _watchRecords.any((r) {
      if (r.seasonNumber != seasonNumber || r.episodeNumber != episodeNumber) {
        return false;
      }
      final rTvdb = r.tvdbId ?? r.sId;
      // Strict TVDB ID separation
      if (rTvdb != null && rTvdb > 0 && effectiveTvdbId != null && effectiveTvdbId > 0 && rTvdb != effectiveTvdbId) {
        return false;
      }
      if (r.showId != null && (r.showId == targetShowId || r.showId == showId)) return true;
      if (effectiveTvdbId != null && effectiveTvdbId > 0 && rTvdb == effectiveTvdbId) return true;
      if (tmdbId != null && tmdbId > 0 && (r.tvdbId == tmdbId || r.sId == tmdbId)) return true;
      if (r.sId != null && (r.sId == targetShowId || r.sId == showId)) return true;
      if (r.tvdbId != null && (r.tvdbId == targetShowId || r.tvdbId == showId)) return true;
      return false;
    });
  }

  WatchRecordModel? getLatestWatchRecord({
    required int showId,
    int? tvdbId,
    required int seasonNumber,
    required int episodeNumber,
    int? episodeId,
  }) {
    final show = getShowById(showId);
    final targetShowId = show?.id ?? showId;
    final effectiveTvdbId = tvdbId ?? show?.tvdbId;
    final tmdbId = show?.tmdbId;

    final matches = _watchRecords.where((r) {
      if (episodeId != null && r.episodeId == episodeId) return true;
      if (r.seasonNumber != seasonNumber || r.episodeNumber != episodeNumber) {
        return false;
      }
      final rTvdb = r.tvdbId ?? r.sId;
      // Strict TVDB ID separation
      if (rTvdb != null && rTvdb > 0 && effectiveTvdbId != null && effectiveTvdbId > 0 && rTvdb != effectiveTvdbId) {
        return false;
      }
      if (r.showId != null && (r.showId == targetShowId || r.showId == showId)) return true;
      if (effectiveTvdbId != null && effectiveTvdbId > 0 && rTvdb == effectiveTvdbId) return true;
      if (tmdbId != null && tmdbId > 0 && (r.tvdbId == tmdbId || r.sId == tmdbId)) return true;
      if (r.sId != null && (r.sId == targetShowId || r.sId == showId)) return true;
      if (r.tvdbId != null && (r.tvdbId == targetShowId || r.tvdbId == showId)) return true;
      return false;
    }).toList();

    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return matches.first;
  }

  int getWatchedEpisodesCountForShow(int showId) {
    final show = getShowById(showId);
    final targetShowId = show?.id ?? showId;
    final tvdbId = show?.tvdbId;
    final tmdbId = show?.tmdbId;

    final Set<String> watchedKeys = {};
    for (final ep in _episodes.values.where((e) =>
        (e.showId == targetShowId ||
         e.showId == showId ||
         (tvdbId != null && e.tvdbId == tvdbId) ||
         (tmdbId != null && e.tmdbId == tmdbId)) &&
        e.isWatched)) {
      watchedKeys.add('S${ep.seasonNumber}E${ep.episodeNumber}');
    }
    for (final r in _watchRecords) {
      if (r.seasonNumber <= 0 || r.episodeNumber <= 0) continue;
      if (r.showId == targetShowId ||
          r.showId == showId ||
          (tvdbId != null && (r.sId == tvdbId || r.tvdbId == tvdbId)) ||
          (tmdbId != null && (r.sId == tmdbId || r.tvdbId == tmdbId)) ||
          r.sId == targetShowId ||
          r.sId == showId ||
          r.tvdbId == targetShowId ||
          r.tvdbId == showId) {
        watchedKeys.add('S${r.seasonNumber}E${r.episodeNumber}');
      }
    }
    return watchedKeys.length;
  }

  List<EpisodeModel> getEpisodesForShowAndSeason(int showId, int seasonNumber) {
    final show = getShowById(showId);
    final targetShowId = show?.id ?? showId;
    final tvdbId = show?.tvdbId;
    final tmdbId = show?.tmdbId;
    final episodes = _episodes.values
        .where((e) =>
            (e.showId == targetShowId ||
             e.showId == showId ||
             (tvdbId != null && e.tvdbId == tvdbId) ||
             (tmdbId != null && e.tmdbId == tmdbId)) &&
            e.seasonNumber == seasonNumber)
        .toList();

    for (int i = 0; i < episodes.length; i++) {
      final ep = episodes[i];
      if (!ep.isWatched) {
        final hasHistory = isEpisodeWatchedInHistory(
          showId: targetShowId,
          tvdbId: tvdbId,
          seasonNumber: seasonNumber,
          episodeNumber: ep.episodeNumber,
          episodeId: ep.id,
        );
        if (hasHistory) {
          final latest = getLatestWatchRecord(
            showId: targetShowId,
            tvdbId: tvdbId,
            seasonNumber: seasonNumber,
            episodeNumber: ep.episodeNumber,
            episodeId: ep.id,
          );
          final updated = ep.copyWith(
            isWatched: true,
            lastWatchedAt: latest?.watchedAt ?? ep.lastWatchedAt ?? DateTime.now(),
            rewatchCount: (latest != null && latest.rewatchCount > 0)
                ? latest.rewatchCount
                : (ep.rewatchCount > 0 ? ep.rewatchCount : 1),
          );
          _episodes[ep.id] = updated;
          episodes[i] = updated;
          unawaited((_db.update(_db.episodesTable)..where((t) => t.id.equals(ep.id))).write(
            EpisodesTableCompanion(
              isWatched: const Value(true),
              lastWatchedAt: Value(updated.lastWatchedAt),
              rewatchCount: Value(updated.rewatchCount),
            ),
          ));
        }
      }
    }

    return episodes..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
  }

  Future<List<EpisodeModel>> fetchOrLoadSeasonEpisodes(ShowModel show, int seasonNumber) async {
    final isOriginalBehzat = (show.tvdbId == 235881 || (show.id == 2 && show.name == 'Behzat Ç.'));
    int? effectiveTmdbId = isOriginalBehzat ? 39176 : show.tmdbId;
    if (effectiveTmdbId == 39176 && !isOriginalBehzat) {
      effectiveTmdbId = null;
    }

    if (isOriginalBehzat && BehzatMetadata.seasons.containsKey(seasonNumber)) {
      final existing = getEpisodesForShowAndSeason(show.id, seasonNumber);
      if (existing.isEmpty) {
        await _backfillBehzatEpisodesMetadata();
      }
    }

    // Dynamically resolve missing or wrong TMDB ID
    if (effectiveTmdbId == null || effectiveTmdbId <= 0) {
      if (show.tvdbId != null && show.tvdbId! > 0) {
        final found = await _tmdbService.findTvShowByTvdbId(show.tvdbId!);
        if (found != null && found.tmdbId != null) {
          effectiveTmdbId = found.tmdbId;
          final updated = show.copyWith(
            tmdbId: effectiveTmdbId,
            totalSeasons: found.totalSeasons > 0 ? found.totalSeasons : show.totalSeasons,
            totalEpisodes: found.totalEpisodes > 0 ? found.totalEpisodes : show.totalEpisodes,
            posterPath: found.posterPath ?? show.posterPath,
            backdropPath: found.backdropPath ?? show.backdropPath,
          );
          await upsertShow(updated);
        }
      }
      if (effectiveTmdbId == null || effectiveTmdbId <= 0) {
        final found = await _tmdbService.searchTvShowByName(show.name);
        if (found != null && found.tmdbId != null) {
          effectiveTmdbId = found.tmdbId;
          final updated = show.copyWith(
            tmdbId: effectiveTmdbId,
            totalSeasons: found.totalSeasons > 0 ? found.totalSeasons : show.totalSeasons,
            totalEpisodes: found.totalEpisodes > 0 ? found.totalEpisodes : show.totalEpisodes,
          );
          await upsertShow(updated);
        }
      }
    }

    final local = getEpisodesForShowAndSeason(show.id, seasonNumber);

    // If seasonNumber exceeds show's total seasons, purge local and return empty
    if (show.totalSeasons > 0 && seasonNumber > show.totalSeasons) {
      for (final bad in local) {
        _episodes.remove(bad.id);
        unawaited((_db.delete(_db.episodesTable)..where((t) => t.id.equals(bad.id))).go());
      }
      return [];
    }

    // If not original Behzat, purge any contaminated 39176 episodes
    if (!isOriginalBehzat) {
      final contaminated = local.where((e) => e.tmdbId == 39176 || e.name.contains('Pilot') || e.name.contains('Gece Uçuşu')).toList();
      if (contaminated.isNotEmpty) {
        for (final bad in contaminated) {
          _episodes.remove(bad.id);
          unawaited((_db.delete(_db.episodesTable)..where((t) => t.id.equals(bad.id))).go());
        }
        local.removeWhere((e) => e.tmdbId == 39176 || e.name.contains('Pilot') || e.name.contains('Gece Uçuşu'));
      }
    }

    if (effectiveTmdbId != null && effectiveTmdbId > 0) {
      try {
        final tmdbEps = await _tmdbService.getSeasonEpisodes(
          effectiveTmdbId,
          seasonNumber,
          showInternalId: show.id,
        );
        if (tmdbEps.isNotEmpty) {
          final validEpNumbers = tmdbEps.map((e) => e.episodeNumber).toSet();

          // CRITICAL: Purge any local episodes whose episodeNumber does NOT exist in TMDB's list!
          // This eliminates old phantom/corrupted mock episodes (e.g. eps 9..38 for a season with 8 eps).
          final excess = local.where((e) => !validEpNumbers.contains(e.episodeNumber)).toList();
          for (final ex in excess) {
            _episodes.remove(ex.id);
            unawaited((_db.delete(_db.episodesTable)..where((t) => t.id.equals(ex.id))).go());
          }

          for (final ep in tmdbEps) {
            final existing = local.where((e) => e.episodeNumber == ep.episodeNumber);
            final bool existingWatched = existing.isNotEmpty && existing.first.isWatched;
            final bool hasHistory = isEpisodeWatchedInHistory(
              showId: show.id,
              tvdbId: show.tvdbId,
              seasonNumber: seasonNumber,
              episodeNumber: ep.episodeNumber,
            );
            final bool isWatched = (isOriginalBehzat && seasonNumber == 1 && ep.episodeNumber == 36)
                ? false
                : (existingWatched || hasHistory);

            final latest = hasHistory
                ? getLatestWatchRecord(
                    showId: show.id,
                    tvdbId: show.tvdbId,
                    seasonNumber: seasonNumber,
                    episodeNumber: ep.episodeNumber,
                  )
                : null;

            final int rewatch = existing.isNotEmpty
                ? existing.first.rewatchCount
                : (latest?.rewatchCount != null && latest!.rewatchCount > 0
                    ? latest.rewatchCount
                    : (isWatched ? 1 : 0));

            final DateTime? lastWatched = existing.isNotEmpty
                ? existing.first.lastWatchedAt
                : (latest?.watchedAt);

            final int targetId = existing.isNotEmpty
                ? existing.first.id
                : (show.id * 10000 + seasonNumber * 100 + ep.episodeNumber);

            final toSave = ep.copyWith(
              id: targetId,
              showId: show.id,
              seasonNumber: seasonNumber,
              isWatched: isWatched,
              rewatchCount: rewatch,
              lastWatchedAt: lastWatched,
              stillPath: ep.stillPath ?? (existing.isNotEmpty ? existing.first.stillPath : null),
              runtimeMinutes: ep.runtimeMinutes > 0
                  ? ep.runtimeMinutes
                  : (existing.isNotEmpty ? existing.first.runtimeMinutes : 0),
            );
            await upsertEpisode(toSave);
          }

          // Recalculate show's watched episodes count
          final watchedCount = getWatchedEpisodesCountForShow(show.id);
          if (watchedCount != show.watchedEpisodesCount) {
            await upsertShow(show.copyWith(watchedEpisodesCount: watchedCount));
          }

          return getEpisodesForShowAndSeason(show.id, seasonNumber);
        }
      } catch (_) {
        // Fall back to local
      }
    }
    return local;
  }

  Future<void> markSeasonWatched(int showId, int seasonNumber, {required bool watched}) async {
    final seasonEps = getEpisodesForShowAndSeason(showId, seasonNumber);
    for (final ep in seasonEps) {
      if (ep.isWatched != watched) {
        await markEpisodeWatched(
          ep.id,
          watched: watched,
          showId: showId,
          seasonNumber: seasonNumber,
          episodeNumber: ep.episodeNumber,
        );
      }
    }
  }

  Future<void> toggleShowFollowed(int showId) async {
    final show = _shows[showId];
    if (show != null) {
      final updated = show.copyWith(isFollowed: !show.isFollowed);
      await upsertShow(updated);
      unawaited(PocketBaseSyncEngine().pushTrackedShow(updated, isFollowed: updated.isFollowed));
    }
  }

  Future<SeasonModel> upsertSeason(SeasonModel season) async {
    SeasonModel? existing = _seasons[season.id];
    if (existing == null) {
      for (final s in _seasons.values) {
        if (s.showId == season.showId && s.seasonNumber == season.seasonNumber) {
          existing = s;
          break;
        }
      }
    }

    final targetId = existing?.id ?? season.id;
    if (existing != null && season.id != targetId) {
      _seasons.remove(season.id);
      await (_db.delete(_db.seasonsTable)..where((t) => t.id.equals(season.id))).go();
    }

    final finalSeason = season.copyWith(
      id: targetId,
      showId: existing?.showId ?? season.showId,
      seasonNumber: existing?.seasonNumber ?? season.seasonNumber,
      name: season.name.isNotEmpty ? season.name : (existing?.name ?? '${season.seasonNumber}. Sezon'),
      overview: (season.overview != null && season.overview!.isNotEmpty) ? season.overview : existing?.overview,
      posterPath: season.posterPath ?? existing?.posterPath,
      episodeCount: season.episodeCount > 0 ? season.episodeCount : (existing?.episodeCount ?? 0),
      airDate: season.airDate ?? existing?.airDate,
    );

    _seasons[targetId] = finalSeason;
    await _db.into(_db.seasonsTable).insertOnConflictUpdate(
          SeasonsTableCompanion.insert(
            id: Value(targetId),
            showId: finalSeason.showId,
            seasonNumber: finalSeason.seasonNumber,
            name: finalSeason.name,
            overview: Value(finalSeason.overview),
            posterPath: Value(finalSeason.posterPath),
            episodeCount: Value(finalSeason.episodeCount),
            airDate: Value(finalSeason.airDate),
          ),
        );
    return finalSeason;
  }

  // --- Episode & Up Next Operations ---
  EpisodeModel? getEpisodeById(int id) => _episodes[id];

  List<EpisodeModel> getAllEpisodes() => _episodes.values.toList();

  List<EpisodeModel> getEpisodesForShow(int showId) {
    return _episodes.values.where((e) => e.showId == showId).toList();
  }

  Future<EpisodeModel> upsertEpisode(EpisodeModel ep, {bool notify = true}) async {
    EpisodeModel? existing = _episodes[ep.id];
    if (existing == null) {
      for (final e in _episodes.values) {
        if (e.showId == ep.showId && e.seasonNumber == ep.seasonNumber && e.episodeNumber == ep.episodeNumber) {
          existing = e;
          break;
        }
        if (ep.tvdbId != null && ep.tvdbId! > 0 && e.tvdbId == ep.tvdbId) {
          existing = e;
          break;
        }
      }
    }

    if (existing == null) {
      final dbRow = await (_db.select(_db.episodesTable)
            ..where((t) =>
                (t.showId.equals(ep.showId) &
                 t.seasonNumber.equals(ep.seasonNumber) &
                 t.episodeNumber.equals(ep.episodeNumber))))
          .getSingleOrNull();
      if (dbRow != null) {
        existing = _episodes[dbRow.id] ?? _convertEpisodesRowToModel(dbRow);
      }
    }

    final targetId = existing?.id ?? ep.id;
    if (existing != null && ep.id != targetId) {
      _episodes.remove(ep.id);
      await (_db.delete(_db.episodesTable)..where((t) => t.id.equals(ep.id))).go();
    }

    final finalEp = ep.copyWith(
      id: targetId,
      showId: existing?.showId ?? ep.showId,
      seasonId: existing?.seasonId ?? ep.seasonId,
      seasonNumber: existing?.seasonNumber ?? ep.seasonNumber,
      episodeNumber: existing?.episodeNumber ?? ep.episodeNumber,
      tvdbId: ep.tvdbId ?? existing?.tvdbId,
      tmdbId: ep.tmdbId ?? existing?.tmdbId,
      name: ep.name.isNotEmpty && !ep.name.startsWith('${ep.episodeNumber}.') ? ep.name : (existing?.name ?? ep.name),
      overview: (ep.overview != null && ep.overview!.isNotEmpty) ? ep.overview : existing?.overview,
      stillPath: ep.stillPath ?? existing?.stillPath,
      runtimeMinutes: ep.runtimeMinutes > 0 ? ep.runtimeMinutes : (existing?.runtimeMinutes ?? 0),
      airDate: ep.airDate ?? existing?.airDate,
      voteAverage: ep.voteAverage > 0 ? ep.voteAverage : (existing?.voteAverage ?? 0.0),
      isWatched: ep.isWatched || (existing?.isWatched ?? false),
      rewatchCount: ep.rewatchCount > 0 ? ep.rewatchCount : (existing?.rewatchCount ?? 0),
      lastWatchedAt: ep.lastWatchedAt ?? existing?.lastWatchedAt,
    );

    _episodes[targetId] = finalEp;
    await _db.into(_db.episodesTable).insertOnConflictUpdate(
          EpisodesTableCompanion.insert(
            id: Value(targetId),
            showId: finalEp.showId,
            seasonId: finalEp.seasonId,
            seasonNumber: finalEp.seasonNumber,
            episodeNumber: finalEp.episodeNumber,
            tvdbId: Value(finalEp.tvdbId),
            tmdbId: Value(finalEp.tmdbId),
            name: finalEp.name,
            overview: Value(finalEp.overview),
            stillPath: Value(finalEp.stillPath),
            runtimeMinutes: Value(finalEp.runtimeMinutes),
            airDate: Value(finalEp.airDate),
            voteAverage: Value(finalEp.voteAverage),
            isWatched: Value(finalEp.isWatched),
            rewatchCount: Value(finalEp.rewatchCount),
            lastWatchedAt: Value(finalEp.lastWatchedAt),
          ),
        );
    if (notify) {
      _notify();
    }
    return finalEp;
  }

  EpisodeModel? getUpNextEpisode() {
    for (final show in getFollowedShows()) {
      final unwatched = _episodes.values
          .where((ep) => ep.showId == show.id && !ep.isWatched)
          .toList()
        ..sort((a, b) {
          final sComp = a.seasonNumber.compareTo(b.seasonNumber);
          if (sComp != 0) return sComp;
          return a.episodeNumber.compareTo(b.episodeNumber);
        });
      if (unwatched.isNotEmpty) {
        return unwatched.first;
      }
    }
    return null;
  }

  Future<void> markEpisodeWatched(
    int episodeId, {
    bool watched = true,
    int? showId,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    EpisodeModel? ep = _episodes[episodeId];
    if (ep == null && showId != null && seasonNumber != null && episodeNumber != null) {
      final show = getShowById(showId);
      final targetShowId = show?.id ?? showId;
      for (final e in _episodes.values) {
        if (e.showId == targetShowId && e.seasonNumber == seasonNumber && e.episodeNumber == episodeNumber) {
          ep = e;
          break;
        }
      }
    }

    final targetShowId = ep?.showId ?? showId ?? 0;
    final show = getShowById(targetShowId);
    final targetSeasonNum = ep?.seasonNumber ?? seasonNumber ?? 1;
    final targetEpNum = ep?.episodeNumber ?? episodeNumber ?? 1;
    final effectiveTvdbId = show?.tvdbId ?? ep?.tvdbId;
    final effectiveTmdbId = show?.tmdbId ?? ep?.tmdbId;

    if (ep == null) {
      final generatedId = targetShowId > 0
          ? (targetShowId * 10000 + targetSeasonNum * 100 + targetEpNum)
          : episodeId;
      ep = EpisodeModel(
        id: generatedId,
        showId: targetShowId,
        seasonId: targetSeasonNum,
        seasonNumber: targetSeasonNum,
        episodeNumber: targetEpNum,
        tvdbId: effectiveTvdbId,
        tmdbId: effectiveTmdbId,
        name: '$targetEpNum. Bölüm',
        runtimeMinutes: 60,
        isWatched: watched,
      );
    }

    final newRewatch = watched ? (ep.rewatchCount > 0 ? ep.rewatchCount + 1 : 1) : 0;
    final now = DateTime.now();

    final updatedEp = ep.copyWith(
      isWatched: watched,
      rewatchCount: newRewatch,
      lastWatchedAt: watched ? now : null,
    );
    _episodes[updatedEp.id] = updatedEp;

    WatchRecordModel? newRecord;
    if (watched) {
      newRecord = WatchRecordModel(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        episodeId: updatedEp.id,
        showId: targetShowId > 0 ? targetShowId : updatedEp.showId,
        tvdbId: effectiveTvdbId,
        sId: effectiveTvdbId,
        seasonNumber: updatedEp.seasonNumber,
        episodeNumber: updatedEp.episodeNumber,
        title: updatedEp.name,
        runtimeMinutes: updatedEp.runtimeMinutes > 0 ? updatedEp.runtimeMinutes : 60,
        watchedAt: now,
        rewatchCount: newRewatch,
      );
      _watchRecords.removeWhere((r) =>
          r.episodeId == updatedEp.id ||
          (r.seasonNumber == updatedEp.seasonNumber &&
              r.episodeNumber == updatedEp.episodeNumber &&
              (r.showId == targetShowId ||
                  r.showId == updatedEp.showId ||
                  (effectiveTvdbId != null && (r.tvdbId == effectiveTvdbId || r.sId == effectiveTvdbId)) ||
                  (effectiveTmdbId != null && (r.tvdbId == effectiveTmdbId || r.sId == effectiveTmdbId)))));
      _watchRecords.add(newRecord);
    } else {
      // Remove from memory synchronously
      _watchRecords.removeWhere((r) =>
          r.episodeId == updatedEp.id ||
          (r.seasonNumber == updatedEp.seasonNumber &&
              r.episodeNumber == updatedEp.episodeNumber &&
              (r.showId == targetShowId ||
                  r.showId == updatedEp.showId ||
                  (effectiveTvdbId != null && (r.tvdbId == effectiveTvdbId || r.sId == effectiveTvdbId)) ||
                  (effectiveTmdbId != null && (r.tvdbId == effectiveTmdbId || r.sId == effectiveTmdbId)))));
    }

    if (show != null) {
      final actualCount = getWatchedEpisodesCountForShow(show.id);
      _shows[show.id] = show.copyWith(watchedEpisodesCount: actualCount);
    }

    await (_db.into(_db.episodesTable)).insertOnConflictUpdate(
      EpisodesTableCompanion.insert(
        id: Value(updatedEp.id),
        showId: updatedEp.showId,
        seasonId: updatedEp.seasonId,
        seasonNumber: updatedEp.seasonNumber,
        episodeNumber: updatedEp.episodeNumber,
        tvdbId: Value(updatedEp.tvdbId),
        tmdbId: Value(updatedEp.tmdbId),
        name: updatedEp.name,
        overview: Value(updatedEp.overview),
        stillPath: Value(updatedEp.stillPath),
        runtimeMinutes: Value(updatedEp.runtimeMinutes),
        airDate: Value(updatedEp.airDate),
        voteAverage: Value(updatedEp.voteAverage),
        isWatched: Value(watched),
        rewatchCount: Value(newRewatch),
        lastWatchedAt: Value(watched ? now : null),
      ),
    );

    if (watched && newRecord != null) {
      await _db.into(_db.episodeWatchHistoryTable).insert(
            EpisodeWatchHistoryTableCompanion.insert(
              title: newRecord.title,
              watchedAt: newRecord.watchedAt,
              episodeId: Value(newRecord.episodeId),
              showId: Value(newRecord.showId),
              tvdbId: Value(newRecord.tvdbId),
              sId: Value(newRecord.sId),
              seasonNumber: Value(newRecord.seasonNumber),
              episodeNumber: Value(newRecord.episodeNumber),
              runtimeMinutes: Value(newRecord.runtimeMinutes),
              rewatchCount: Value(newRecord.rewatchCount),
            ),
          );
    } else if (!watched) {
      // Remove from DB
      await (_db.delete(_db.episodeWatchHistoryTable)
            ..where((t) =>
                t.episodeId.equals(updatedEp.id) |
                (t.seasonNumber.equals(updatedEp.seasonNumber) &
                    t.episodeNumber.equals(updatedEp.episodeNumber) &
                    (t.showId.equals(targetShowId) |
                        t.showId.equals(updatedEp.showId) |
                        (effectiveTvdbId != null ? t.sId.equals(effectiveTvdbId) : const Constant(false)) |
                        (effectiveTvdbId != null ? t.tvdbId.equals(effectiveTvdbId) : const Constant(false))))))
          .go();
    }

    if (show != null) {
      final actualCount = getWatchedEpisodesCountForShow(show.id);
      await (_db.update(_db.showsTable)..where((t) => t.id.equals(show.id))).write(
        ShowsTableCompanion(
          watchedEpisodesCount: Value(actualCount),
        ),
      );
    }

    _notify();

    // Trigger background push to PocketBase backend
    final syncRecord = newRecord ??
        WatchRecordModel(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          episodeId: updatedEp.id,
          showId: targetShowId > 0 ? targetShowId : updatedEp.showId,
          tvdbId: effectiveTvdbId,
          sId: effectiveTvdbId,
          seasonNumber: updatedEp.seasonNumber,
          episodeNumber: updatedEp.episodeNumber,
          title: updatedEp.name,
          runtimeMinutes: updatedEp.runtimeMinutes > 0 ? updatedEp.runtimeMinutes : 60,
          watchedAt: now,
        );
    PocketBaseSyncEngine().pushWatchRecord(syncRecord, isWatched: watched);
  }

  // --- Movies Operations ---
  List<MovieModel> getAllMovies() => _movies.values.toList();

  Future<MovieModel> upsertMovie(MovieModel movie, {bool notify = true}) async {
    MovieModel? existing = _movies[movie.id];
    if (existing == null && movie.tmdbId != null && movie.tmdbId! > 0) {
      for (final m in _movies.values) {
        if (m.tmdbId == movie.tmdbId) {
          existing = m;
          break;
        }
      }
    }
    if (existing == null && movie.title.trim().isNotEmpty) {
      final clean = movie.title.trim().toLowerCase();
      for (final m in _movies.values) {
        if (m.title.trim().toLowerCase() == clean) {
          existing = m;
          break;
        }
      }
    }

    final targetId = existing?.id ?? movie.id;
    if (existing != null && movie.id != targetId) {
      _movies.remove(movie.id);
      await (_db.delete(_db.moviesTable)..where((t) => t.id.equals(movie.id))).go();
    }

    final finalMovie = movie.copyWith(
      id: targetId,
      tmdbId: movie.tmdbId ?? existing?.tmdbId,
      imdbId: movie.imdbId ?? existing?.imdbId,
      title: movie.title.isNotEmpty ? movie.title : (existing?.title ?? ''),
      overview: (movie.overview != null && movie.overview!.isNotEmpty) ? movie.overview : existing?.overview,
      posterPath: movie.posterPath ?? existing?.posterPath,
      backdropPath: movie.backdropPath ?? existing?.backdropPath,
      releaseDate: movie.releaseDate ?? existing?.releaseDate,
      runtimeMinutes: movie.runtimeMinutes > 0 ? movie.runtimeMinutes : (existing?.runtimeMinutes ?? 0),
      genres: movie.genres.isNotEmpty ? movie.genres : (existing?.genres ?? []),
      isWatched: movie.isWatched || (existing?.isWatched ?? false),
      isFollowed: movie.isFollowed || (existing?.isFollowed ?? false),
      watchedAt: movie.watchedAt ?? existing?.watchedAt,
      rewatchCount: movie.rewatchCount > 0 ? movie.rewatchCount : (existing?.rewatchCount ?? 0),
      voteAverage: movie.voteAverage > 0 ? movie.voteAverage : (existing?.voteAverage ?? 0.0),
    );

    _movies[targetId] = finalMovie;
    await _db.into(_db.moviesTable).insertOnConflictUpdate(
          MoviesTableCompanion.insert(
            id: Value(targetId),
            tmdbId: Value(finalMovie.tmdbId),
            imdbId: Value(finalMovie.imdbId),
            title: finalMovie.title,
            overview: Value(finalMovie.overview),
            posterPath: Value(finalMovie.posterPath),
            backdropPath: Value(finalMovie.backdropPath),
            releaseDate: Value(finalMovie.releaseDate),
            runtimeMinutes: Value(finalMovie.runtimeMinutes),
            genres: Value(finalMovie.genres.join(',')),
            isWatched: Value(finalMovie.isWatched),
            isFollowed: Value(finalMovie.isFollowed),
            watchedAt: Value(finalMovie.watchedAt),
            rewatchCount: Value(finalMovie.rewatchCount),
            voteAverage: Value(finalMovie.voteAverage),
          ),
        );
    if (notify) {
      _notify();
    }
    return finalMovie;
  }

  Future<void> upsertMoviesBatch(List<MovieModel> movies) async {
    for (final movie in movies) {
      await upsertMovie(movie, notify: false);
    }
    _notify();
  }

  Future<void> toggleMovieFollowed(int movieId, {bool? isFollowed, bool syncRemote = true}) async {
    final movie = _movies[movieId];
    if (movie == null) return;
    final newFollowed = isFollowed ?? !movie.isFollowed;
    if (isFollowed != null && newFollowed == movie.isFollowed) return;
    final updated = movie.copyWith(isFollowed: newFollowed);
    _movies[movieId] = updated;

    await (_db.update(_db.moviesTable)..where((t) => t.id.equals(movieId))).write(
      MoviesTableCompanion(
        isFollowed: Value(newFollowed),
      ),
    );
    _notify();
    if (syncRemote) {
      unawaited(PocketBaseSyncEngine().pushTrackedMovie(updated, isFollowed: newFollowed));
    }
  }

  Future<void> toggleMovieWatched(int movieId, {bool? isWatched, DateTime? watchedAt, bool syncRemote = true}) async {
    final movie = _movies[movieId];
    if (movie == null) return;
    final newWatched = isWatched ?? !movie.isWatched;
    if (isWatched != null && newWatched == movie.isWatched && (watchedAt == null || movie.watchedAt == watchedAt)) return;
    final watchTime = newWatched ? (watchedAt ?? DateTime.now()) : null;

    final updated = movie.copyWith(
      isWatched: newWatched,
      watchedAt: watchTime,
    );
    _movies[movieId] = updated;

    await (_db.update(_db.moviesTable)..where((t) => t.id.equals(movieId))).write(
      MoviesTableCompanion(
        isWatched: Value(newWatched),
        watchedAt: Value(watchTime),
      ),
    );

    if (newWatched) {
      await _db.into(_db.movieWatchHistoryTable).insertOnConflictUpdate(
        MovieWatchHistoryTableCompanion.insert(
          title: movie.title,
          watchedAt: watchTime!,
          movieId: Value(movie.id),
          tmdbId: Value(movie.tmdbId),
          runtimeMinutes: Value(movie.runtimeMinutes),
          rewatchCount: const Value(1),
        ),
      );
    } else {
      await (_db.delete(_db.movieWatchHistoryTable)
            ..where((t) => t.movieId.equals(movie.id) | (movie.tmdbId != null ? t.tmdbId.equals(movie.tmdbId!) : const Constant(false))))
          .go();
    }
    _notify();
    if (syncRemote) {
      unawaited(PocketBaseSyncEngine().pushMovieWatchRecord(updated, isWatched: newWatched));
    }
  }

  // --- Watch Records & Stats ---
  void addWatchRecord(WatchRecordModel record) {
    _watchRecords.add(record);
    _db.into(_db.episodeWatchHistoryTable).insert(
          EpisodeWatchHistoryTableCompanion.insert(
            title: record.title,
            watchedAt: record.watchedAt,
            episodeId: Value(record.episodeId),
            showId: Value(record.showId),
            tvdbId: Value(record.tvdbId),
            sId: Value(record.sId),
            seasonNumber: Value(record.seasonNumber),
            episodeNumber: Value(record.episodeNumber),
            runtimeMinutes: Value(record.runtimeMinutes),
            rewatchCount: Value(record.rewatchCount),
          ),
        );
    _notify();
  }

  Future<void> addWatchRecordsBatch(List<WatchRecordModel> records) async {
    if (records.isEmpty) return;
    _watchRecords.addAll(records);
    await _db.batch((batch) {
      batch.insertAll(
        _db.episodeWatchHistoryTable,
        records.map((record) => EpisodeWatchHistoryTableCompanion.insert(
              title: record.title,
              watchedAt: record.watchedAt,
              episodeId: Value(record.episodeId),
              showId: Value(record.showId),
              tvdbId: Value(record.tvdbId),
              sId: Value(record.sId),
              seasonNumber: Value(record.seasonNumber),
              episodeNumber: Value(record.episodeNumber),
              runtimeMinutes: Value(record.runtimeMinutes),
              rewatchCount: Value(record.rewatchCount),
            )),
      );
    });
    _notify();
  }

  void notifyAll({bool immediate = false}) {
    _notify(immediate: immediate);
  }

  ShowModel? findShow({int? showId, int? tvdbId, int? tmdbId}) {
    if (tvdbId != null && tvdbId > 0) {
      for (final s in _shows.values) {
        if (s.tvdbId == tvdbId) return s;
      }
    }
    if (tmdbId != null && tmdbId > 0) {
      for (final s in _shows.values) {
        if (s.tmdbId == tmdbId) return s;
      }
    }
    if (showId != null && _shows.containsKey(showId)) {
      return _shows[showId];
    }
    if (showId != null && showId > 0) {
      for (final s in _shows.values) {
        if (s.tvdbId == showId || s.tmdbId == showId) return s;
      }
    }
    return null;
  }

  MovieModel? findMovie({int? movieId, int? tmdbId, String? title}) {
    if (tmdbId != null && tmdbId > 0) {
      for (final m in _movies.values) {
        if (m.tmdbId == tmdbId) return m;
      }
    }
    if (movieId != null && _movies.containsKey(movieId)) {
      return _movies[movieId];
    }
    if (movieId != null && movieId > 0) {
      for (final m in _movies.values) {
        if (m.tmdbId == movieId) return m;
      }
    }
    if (title != null && title.trim().isNotEmpty) {
      final clean = title.trim().toLowerCase();
      for (final m in _movies.values) {
        if (m.title.trim().toLowerCase() == clean) return m;
      }
    }
    return null;
  }

  UserStatsModel getUserStats() {
    int totalMinutes = 0;
    for (final r in _watchRecords) {
      totalMinutes += r.runtimeMinutes;
    }
    for (final m in _movies.values) {
      if (m.isWatched) {
        totalMinutes += m.runtimeMinutes;
      }
    }

    // Dynamic 28 days activity from real watch records
    final now = DateTime.now();
    final List<int> activity28Days = List.filled(28, 0);
    for (final r in _watchRecords) {
      final diff = now.difference(r.watchedAt).inDays;
      if (diff >= 0 && diff < 28) {
        activity28Days[27 - diff]++;
      }
    }

    // Dynamic rewatched shows and movies (matching Stitch specification: 5x, 4x, 3x, 2x badges)
    final List<_RewatchCandidate> candidates = [];

    // 1. Movies with rewatches
    for (final m in _movies.values) {
      if (m.isWatched && m.rewatchCount > 1) {
        candidates.add(_RewatchCandidate(
          title: m.title,
          count: m.rewatchCount,
          posterPath: m.posterPath,
          subScore: 0,
        ));
      }
    }

    // 2. Shows with rewatches - O(S + E + W) single-pass indexed aggregation
    final Map<int, ShowModel> showById = {};
    final Map<int, ShowModel> showByTvdbId = {};
    for (final s in _shows.values) {
      showById[s.id] = s;
      if (s.tvdbId != null && s.tvdbId! > 0) {
        showByTvdbId[s.tvdbId!] = s;
      }
    }

    final Map<int, _ShowRewatchAccumulator> accumulators = {
      for (final s in _shows.values) s.id: _ShowRewatchAccumulator(),
    };

    for (final ep in _episodes.values) {
      if (ep.rewatchCount <= 1) continue;

      final matched = <ShowModel>{};
      final sFromId = showById[ep.showId];
      if (sFromId != null) matched.add(sFromId);
      if (ep.tvdbId != null && ep.tvdbId! > 0) {
        final s = showByTvdbId[ep.tvdbId];
        if (s != null) matched.add(s);
      }

      for (final s in matched) {
        final acc = accumulators[s.id];
        acc?.recordEpisode(ep.seasonNumber, ep.episodeNumber, ep.rewatchCount);
      }
    }

    for (final r in _watchRecords) {
      if (r.rewatchCount <= 1) continue;

      final matched = <ShowModel>{};
      if (r.showId != null) {
        final s = showById[r.showId];
        if (s != null) matched.add(s);
      }
      if (r.tvdbId != null && r.tvdbId! > 0) {
        final s = showByTvdbId[r.tvdbId];
        if (s != null) matched.add(s);
      }
      if (r.sId != null && r.sId! > 0) {
        final s = showByTvdbId[r.sId];
        if (s != null) matched.add(s);
      }

      for (final s in matched) {
        final acc = accumulators[s.id];
        acc?.recordEpisode(r.seasonNumber, r.episodeNumber, r.rewatchCount);
      }
    }

    for (final s in _shows.values) {
      final acc = accumulators[s.id];
      if (acc != null && acc.maxEpRewatch > 1) {
        candidates.add(_RewatchCandidate(
          title: s.name,
          count: acc.maxEpRewatch,
          posterPath: s.posterPath,
          subScore: acc.rewatchedEpsCount,
        ));
      }
    }

    // Sort descending: highest rewatch multiplier first (5x, 4x, 3x, 2x), tie-break by subScore
    candidates.sort((a, b) {
      final cmp = b.count.compareTo(a.count);
      if (cmp != 0) return cmp;
      return b.subScore.compareTo(a.subScore);
    });

    final List<RewatchItem> dynamicRewatches = [];
    final Set<String> seenCandidateTitles = {};
    for (final c in candidates) {
      final cleanTitle = c.title.trim().toLowerCase();
      if (cleanTitle.isNotEmpty && seenCandidateTitles.add(cleanTitle)) {
        dynamicRewatches.add(RewatchItem(
          title: c.title,
          count: c.count,
          posterPath: c.posterPath,
        ));
        if (dynamicRewatches.length >= 8) break;
      }
    }

    // Dynamic genre distribution
    final Map<String, int> genreCounts = {};
    for (final s in _shows.values) {
      if (s.isFollowed || s.watchedEpisodesCount > 0) {
        for (final g in s.genres) {
          if (g.isNotEmpty) genreCounts[g] = (genreCounts[g] ?? 0) + 1;
        }
      }
    }
    for (final m in _movies.values) {
      if (m.isWatched) {
        for (final g in m.genres) {
          if (g.isNotEmpty) genreCounts[g] = (genreCounts[g] ?? 0) + 1;
        }
      }
    }
    final int totalGenreHits = genreCounts.values.fold(0, (a, b) => a + b);
    final Map<String, double> genreDistribution = {};
    if (totalGenreHits > 0) {
      final sortedGenres = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final g in sortedGenres.take(4)) {
        genreDistribution[g.key] = double.parse(((g.value / totalGenreHits) * 100).toStringAsFixed(1));
      }
    }

    final watchedEpCount = _watchRecords
        .map((r) => '${r.showId ?? r.tvdbId ?? r.sId}_${r.seasonNumber}_${r.episodeNumber}')
        .toSet()
        .length;

    return UserStatsModel(
      totalWatchMinutes: totalMinutes,
      showsFollowedCount: _shows.values.where((s) => s.isFollowed).length,
      episodesWatchedCount: watchedEpCount,
      moviesWatchedCount: _movies.values.where((m) => m.isWatched).length,
      genreDistribution: genreDistribution,
      last28DaysActivity: activity28Days,
      rewatchedShows: dynamicRewatches,
    );
  }

  List<WatchRecordModel> getAllWatchRecords() => List.unmodifiable(_watchRecords);

  Future<void> insertWatchRecord(WatchRecordModel record) async {
    final show = findShow(showId: record.showId, tvdbId: record.tvdbId);
    final resolvedShowId = show?.id ?? record.showId;
    final resolvedTvdbId = show?.tvdbId ?? record.tvdbId;

    _watchRecords.removeWhere((r) =>
        (r.showId == resolvedShowId || (resolvedTvdbId != null && (r.tvdbId == resolvedTvdbId || r.sId == resolvedTvdbId))) &&
        r.seasonNumber == record.seasonNumber &&
        r.episodeNumber == record.episodeNumber);
    _watchRecords.add(record.copyWith(showId: resolvedShowId, tvdbId: resolvedTvdbId));

    await _db.into(_db.episodeWatchHistoryTable).insertOnConflictUpdate(
          EpisodeWatchHistoryTableCompanion.insert(
            title: record.title,
            watchedAt: record.watchedAt,
            episodeId: Value(record.episodeId),
            showId: Value(resolvedShowId),
            tvdbId: Value(resolvedTvdbId),
            sId: Value(record.sId ?? resolvedTvdbId),
            seasonNumber: Value(record.seasonNumber),
            episodeNumber: Value(record.episodeNumber),
            runtimeMinutes: Value(record.runtimeMinutes),
            rewatchCount: Value(record.rewatchCount),
          ),
        );

    final ep = _episodes.values.where((e) =>
        (e.showId == resolvedShowId || (resolvedTvdbId != null && e.tvdbId == resolvedTvdbId)) &&
        e.seasonNumber == record.seasonNumber &&
        e.episodeNumber == record.episodeNumber).firstOrNull;
    if (ep != null) {
      _episodes[ep.id] = ep.copyWith(
        isWatched: true,
        lastWatchedAt: record.watchedAt,
        rewatchCount: record.rewatchCount,
      );
      await (_db.update(_db.episodesTable)..where((t) => t.id.equals(ep.id))).write(
        EpisodesTableCompanion(
          isWatched: const Value(true),
          lastWatchedAt: Value(record.watchedAt),
          rewatchCount: Value(record.rewatchCount),
        ),
      );
    }

    if (show != null) {
      final count = _watchRecords.where((r) =>
          r.showId == show.id ||
          (show.tvdbId != null && (r.tvdbId == show.tvdbId || r.sId == show.tvdbId))
      ).map((r) => '${r.seasonNumber}_${r.episodeNumber}').toSet().length;

      _shows[show.id] = show.copyWith(watchedEpisodesCount: count);
      await (_db.update(_db.showsTable)..where((t) => t.id.equals(show.id))).write(
        ShowsTableCompanion(watchedEpisodesCount: Value(count)),
      );
    }

    _notify();
  }

  Future<void> removeWatchRecord({required int showId, required int seasonNumber, required int episodeNumber}) async {
    final show = findShow(showId: showId, tvdbId: showId);
    final resolvedShowId = show?.id ?? showId;
    final resolvedTvdbId = show?.tvdbId;

    _watchRecords.removeWhere((r) =>
        (r.showId == resolvedShowId || (resolvedTvdbId != null && (r.tvdbId == resolvedTvdbId || r.sId == resolvedTvdbId))) &&
        r.seasonNumber == seasonNumber &&
        r.episodeNumber == episodeNumber);

    await (_db.delete(_db.episodeWatchHistoryTable)
          ..where((t) =>
              (t.showId.equals(resolvedShowId) | (resolvedTvdbId != null ? (t.tvdbId.equals(resolvedTvdbId) | t.sId.equals(resolvedTvdbId)) : const Constant(false))) &
              t.seasonNumber.equals(seasonNumber) &
              t.episodeNumber.equals(episodeNumber)))
        .go();

    final ep = _episodes.values.where((e) =>
        (e.showId == resolvedShowId || (resolvedTvdbId != null && e.tvdbId == resolvedTvdbId)) &&
        e.seasonNumber == seasonNumber &&
        e.episodeNumber == episodeNumber).firstOrNull;
    if (ep != null) {
      _episodes[ep.id] = ep.copyWith(isWatched: false, lastWatchedAt: null, rewatchCount: 0);
      await (_db.update(_db.episodesTable)..where((t) => t.id.equals(ep.id))).write(
        const EpisodesTableCompanion(
          isWatched: Value(false),
          lastWatchedAt: Value(null),
          rewatchCount: Value(0),
        ),
      );
    }

    if (show != null) {
      final count = _watchRecords.where((r) =>
          r.showId == show.id ||
          (show.tvdbId != null && (r.tvdbId == show.tvdbId || r.sId == show.tvdbId))
      ).map((r) => '${r.seasonNumber}_${r.episodeNumber}').toSet().length;

      _shows[show.id] = show.copyWith(watchedEpisodesCount: count);
      await (_db.update(_db.showsTable)..where((t) => t.id.equals(show.id))).write(
        ShowsTableCompanion(watchedEpisodesCount: Value(count)),
      );
    }

    _notify();
  }

  /// Completely purges all local tables and restores a clean, brand-new account state.
  Future<void> resetAllUserData() async {
    await _db.delete(_db.episodeWatchHistoryTable).go();
    await _db.delete(_db.movieWatchHistoryTable).go();
    await _db.delete(_db.importQueueTable).go();
    await _db.delete(_db.episodesTable).go();
    await _db.delete(_db.seasonsTable).go();
    await _db.delete(_db.showsTable).go();
    await _db.delete(_db.moviesTable).go();

    _shows.clear();
    _seasons.clear();
    _episodes.clear();
    _movies.clear();
    _watchRecords.clear();
    _friends.clear();
    _unresolvedItems.clear();

    _notify();
  }

  // --- Unresolved Items & Reconciliation ---
  List<UnresolvedItemModel> getUnresolvedItems() => List.unmodifiable(_unresolvedItems);

  void setUnresolvedItems(List<UnresolvedItemModel> items) {
    _unresolvedItems.clear();
    _unresolvedItems.addAll(items);
    _notify();
  }

  List<WatchRecordModel> getWatchRecordsForShow(int showId) {
    final show = getShowById(showId);
    final targetTvdb = show?.tvdbId;
    final targetTmdb = show?.tmdbId;
    return _watchRecords.where((r) {
      return r.showId == showId ||
          (targetTvdb != null && targetTvdb > 0 && (r.tvdbId == targetTvdb || r.sId == targetTvdb)) ||
          (targetTmdb != null && targetTmdb > 0 && (r.tvdbId == targetTmdb || r.sId == targetTmdb));
    }).toList();
  }

  /// Resolves an unmatched item by updating its metadata, poster, and re-linking watch history
  Future<void> resolveUnmatchedItem(UnresolvedItemModel item, dynamic matchedTmdbItem) async {
    String title = '';
    int? tmdbId;
    String? posterPath;
    String? backdropPath;
    String? overview;
    int totalSeasons = 0;
    int totalEpisodes = 0;
    int runtimeMinutes = 0;
    List<String> genres = [];
    DateTime? releaseDate;
    double voteAverage = 0.0;

    if (matchedTmdbItem is ShowModel) {
      title = matchedTmdbItem.name;
      tmdbId = matchedTmdbItem.tmdbId ?? (matchedTmdbItem.id > 0 ? matchedTmdbItem.id : null);
      posterPath = matchedTmdbItem.posterPath;
      backdropPath = matchedTmdbItem.backdropPath;
      overview = matchedTmdbItem.overview;
      totalSeasons = matchedTmdbItem.totalSeasons;
      totalEpisodes = matchedTmdbItem.totalEpisodes;
      genres = matchedTmdbItem.genres;
      releaseDate = matchedTmdbItem.firstAirDate;
      voteAverage = matchedTmdbItem.voteAverage;
    } else if (matchedTmdbItem is MovieModel) {
      title = matchedTmdbItem.title;
      tmdbId = matchedTmdbItem.tmdbId ?? (matchedTmdbItem.id > 0 ? matchedTmdbItem.id : null);
      posterPath = matchedTmdbItem.posterPath;
      backdropPath = matchedTmdbItem.backdropPath;
      overview = matchedTmdbItem.overview;
      runtimeMinutes = matchedTmdbItem.runtimeMinutes;
      genres = matchedTmdbItem.genres;
      releaseDate = matchedTmdbItem.releaseDate;
      voteAverage = matchedTmdbItem.voteAverage;
    } else if (matchedTmdbItem is Map<String, dynamic>) {
      title = (matchedTmdbItem['name'] ?? matchedTmdbItem['title'] ?? '').toString();
      tmdbId = matchedTmdbItem['id'] as int?;
      posterPath = matchedTmdbItem['poster_path'] as String?;
      backdropPath = matchedTmdbItem['backdrop_path'] as String?;
      overview = matchedTmdbItem['overview'] as String?;
      voteAverage = (matchedTmdbItem['vote_average'] as num?)?.toDouble() ?? 0.0;
      final dateStr = (matchedTmdbItem['first_air_date'] ?? matchedTmdbItem['release_date']) as String?;
      if (dateStr != null && dateStr.isNotEmpty) {
        releaseDate = DateTime.tryParse(dateStr);
      }
    }

    if (item.type == UnresolvedItemType.show) {
      final cleanTitle = TitleSanitizer.parseTitleAndYear(item.rawTitle).cleanTitle;
      final existing = getShowById(item.id) ??
          getShowByTvdbId(item.tvdbId ?? -1) ??
          (item.rawTitle.isNotEmpty ? getShowByName(item.rawTitle) : null) ??
          (cleanTitle.isNotEmpty ? getShowByName(cleanTitle) : null) ??
          ShowModel(
            id: item.id,
            tvdbId: item.tvdbId,
            name: title.isNotEmpty ? title : (cleanTitle.isNotEmpty ? cleanTitle : item.rawTitle),
            isFollowed: true,
          );

      final updated = existing.copyWith(
        name: title.isNotEmpty ? title : existing.name,
        tmdbId: tmdbId ?? existing.tmdbId,
        posterPath: posterPath ?? existing.posterPath,
        backdropPath: backdropPath ?? existing.backdropPath,
        overview: (overview != null && overview.isNotEmpty) ? overview : existing.overview,
        totalSeasons: totalSeasons > 0 ? totalSeasons : existing.totalSeasons,
        totalEpisodes: totalEpisodes > 0 ? totalEpisodes : existing.totalEpisodes,
        genres: genres.isNotEmpty ? genres : existing.genres,
        voteAverage: voteAverage > 0 ? voteAverage : existing.voteAverage,
        firstAirDate: releaseDate ?? existing.firstAirDate,
        isFollowed: true,
      );
      await upsertShow(updated, notify: false);

      // Update watch records title and link showId in-memory
      for (int i = 0; i < _watchRecords.length; i++) {
        final r = _watchRecords[i];
        if (r.showId == existing.id ||
            (existing.tvdbId != null && (r.tvdbId == existing.tvdbId || r.sId == existing.tvdbId))) {
          _watchRecords[i] = r.copyWith(title: updated.name, showId: existing.id);
        }
      }

      // Single database query update instead of N round-trips
      await (_db.update(_db.episodeWatchHistoryTable)
            ..where((t) =>
                t.showId.equals(existing.id) |
                (existing.tvdbId != null
                    ? (t.tvdbId.equals(existing.tvdbId!) | t.sId.equals(existing.tvdbId!))
                    : const Constant(false))))
          .write(
        EpisodeWatchHistoryTableCompanion(
          showId: Value(existing.id),
          title: Value(updated.name),
        ),
      );

      await syncEpisodesWithWatchHistory();
      if (PocketBaseSyncEngine().isAuthenticated) {
        unawaited(PocketBaseSyncEngine().pushTrackedShow(updated));
      }
    } else if (item.type == UnresolvedItemType.movie) {
      final cleanTitle = TitleSanitizer.parseTitleAndYear(item.rawTitle).cleanTitle;
      final existing = _movies[item.id] ??
          _movies.values.where((m) => m.title.trim().toLowerCase() == item.rawTitle.trim().toLowerCase()).firstOrNull ??
          (cleanTitle.isNotEmpty
              ? _movies.values.where((m) => m.title.trim().toLowerCase() == cleanTitle.trim().toLowerCase()).firstOrNull
              : null) ??
          MovieModel(
            id: item.id,
            title: title.isNotEmpty ? title : (cleanTitle.isNotEmpty ? cleanTitle : item.rawTitle),
            isWatched: true,
            isFollowed: true,
          );

      final updated = existing.copyWith(
        title: title.isNotEmpty ? title : existing.title,
        tmdbId: tmdbId ?? existing.tmdbId,
        posterPath: posterPath ?? existing.posterPath,
        backdropPath: backdropPath ?? existing.backdropPath,
        overview: (overview != null && overview.isNotEmpty) ? overview : existing.overview,
        runtimeMinutes: runtimeMinutes > 0 ? runtimeMinutes : existing.runtimeMinutes,
        genres: genres.isNotEmpty ? genres : existing.genres,
        releaseDate: releaseDate ?? existing.releaseDate,
        voteAverage: voteAverage > 0 ? voteAverage : existing.voteAverage,
      );
      await upsertMovie(updated, notify: false);

      await (_db.update(_db.movieWatchHistoryTable)
            ..where((t) => t.movieId.equals(existing.id) | t.title.equals(existing.title)))
          .write(
        MovieWatchHistoryTableCompanion(
          title: Value(updated.title),
          tmdbId: Value(updated.tmdbId),
          movieId: Value(existing.id),
        ),
      );
      if (PocketBaseSyncEngine().isAuthenticated) {
        unawaited(PocketBaseSyncEngine().pushTrackedMovie(updated));
      }
    }

    _unresolvedItems.removeWhere((u) => u.id == item.id && u.type == item.type);
    _notify();
  }

  /// Discards an unmatched item and completely purges its data and watch records
  Future<void> discardUnmatchedItem(UnresolvedItemModel item) async {
    if (item.type == UnresolvedItemType.show) {
      final existing = getShowById(item.id) ??
          getShowByTvdbId(item.tvdbId ?? -1) ??
          (item.rawTitle.isNotEmpty ? getShowByName(item.rawTitle) : null);
      final targetId = existing?.id ?? item.id;
      final targetTvdb = item.tvdbId ?? existing?.tvdbId;

      final showToPurge = existing ??
          ShowModel(
            id: targetId,
            name: item.rawTitle,
            tvdbId: targetTvdb,
          );
      if (PocketBaseSyncEngine().isAuthenticated) {
        unawaited(PocketBaseSyncEngine().pushTrackedShow(showToPurge, isFollowed: false));
      }

      _shows.remove(targetId);
      await (_db.delete(_db.showsTable)..where((t) => t.id.equals(targetId))).go();

      final seasonIds = _seasons.values.where((s) => s.showId == targetId).map((s) => s.id).toList();
      for (final sId in seasonIds) {
        _seasons.remove(sId);
      }
      await (_db.delete(_db.seasonsTable)..where((t) => t.showId.equals(targetId))).go();

      final epIds = _episodes.values.where((e) => e.showId == targetId).map((e) => e.id).toList();
      for (final epId in epIds) {
        _episodes.remove(epId);
      }
      await (_db.delete(_db.episodesTable)..where((t) => t.showId.equals(targetId))).go();

      _watchRecords.removeWhere((r) =>
          r.showId == targetId ||
          (targetTvdb != null && (r.tvdbId == targetTvdb || r.sId == targetTvdb)));

      await (_db.delete(_db.episodeWatchHistoryTable)
            ..where((t) =>
                t.showId.equals(targetId) |
                (targetTvdb != null
                    ? (t.tvdbId.equals(targetTvdb) | t.sId.equals(targetTvdb))
                    : const Constant(false))))
          .go();
    } else if (item.type == UnresolvedItemType.movie) {
      final existing = _movies[item.id] ??
          _movies.values.where((m) => m.title.trim().toLowerCase() == item.rawTitle.trim().toLowerCase()).firstOrNull;
      final targetId = existing?.id ?? item.id;

      final movieToPurge = (existing ?? MovieModel(id: targetId, title: item.rawTitle)).copyWith(isWatched: false);
      if (PocketBaseSyncEngine().isAuthenticated) {
        unawaited(PocketBaseSyncEngine().pushTrackedMovie(movieToPurge, isFollowed: false));
      }

      _movies.remove(targetId);
      await (_db.delete(_db.moviesTable)..where((t) => t.id.equals(targetId))).go();
      await (_db.delete(_db.movieWatchHistoryTable)
            ..where((t) => t.movieId.equals(targetId) | t.title.equals(movieToPurge.title)))
          .go();
    }

    _unresolvedItems.removeWhere((u) => u.id == item.id && u.type == item.type);
    _notify();
  }

  /// Lazy self-healing: Enriches a single movie missing poster/metadata
  Future<MovieModel?> enrichSingleMovie(MovieModel movie) async {
    try {
      MovieModel? tmdbMovie;
      if (movie.tmdbId != null && movie.tmdbId! > 0) {
        tmdbMovie = await _tmdbService.getMovieDetails(movie.tmdbId!);
      }
      if (tmdbMovie == null && movie.title.isNotEmpty && !movie.title.startsWith('Movie ')) {
        tmdbMovie = await _tmdbService.searchMovieWithFallback(
          movie.title,
          targetYear: movie.releaseDate?.year,
        );
      }
      if (tmdbMovie != null) {
        final cleanPoster = tmdbMovie.posterPath ?? (_isMockPath(movie.posterPath) ? null : movie.posterPath);
        final cleanBackdrop = tmdbMovie.backdropPath ?? (_isMockPath(movie.backdropPath) ? null : movie.backdropPath);
        final updated = movie.copyWith(
          title: tmdbMovie.title.isNotEmpty ? tmdbMovie.title : movie.title,
          tmdbId: tmdbMovie.tmdbId ?? movie.tmdbId,
          posterPath: cleanPoster,
          backdropPath: cleanBackdrop,
          overview: (movie.overview == null || movie.overview!.isEmpty) ? tmdbMovie.overview : movie.overview,
          runtimeMinutes: (movie.runtimeMinutes <= 0 && tmdbMovie.runtimeMinutes > 0)
              ? tmdbMovie.runtimeMinutes
              : movie.runtimeMinutes,
          genres: movie.genres.isEmpty ? tmdbMovie.genres : movie.genres,
          voteAverage: tmdbMovie.voteAverage > 0 ? tmdbMovie.voteAverage : movie.voteAverage,
          releaseDate: movie.releaseDate ?? tmdbMovie.releaseDate,
        );
        return await upsertMovie(updated);
      }
    } catch (_) {}
    return null;
  }

  /// Lazy self-healing: Enriches a single show missing poster/metadata
  Future<ShowModel?> enrichSingleShow(ShowModel show) async {
    try {
      ShowModel? tmdbShow;
      if (show.tmdbId != null && show.tmdbId! > 0) {
        tmdbShow = await _tmdbService.getTvShowDetails(show.tmdbId!);
      }
      if (tmdbShow == null && show.tvdbId != null && show.tvdbId! > 0) {
        tmdbShow = await _tmdbService.findTvShowByTvdbId(show.tvdbId!);
      }
      if (tmdbShow == null && show.name.isNotEmpty && !show.name.startsWith('Show ')) {
        tmdbShow = await _tmdbService.searchTvShowWithFallback(show.name);
      }
      if (tmdbShow != null) {
        final cleanPoster = tmdbShow.posterPath ?? (_isMockPath(show.posterPath) ? null : show.posterPath);
        final cleanBackdrop = tmdbShow.backdropPath ?? (_isMockPath(show.backdropPath) ? null : show.backdropPath);
        final updated = show.copyWith(
          name: tmdbShow.name.isNotEmpty ? tmdbShow.name : show.name,
          tmdbId: tmdbShow.tmdbId ?? show.tmdbId,
          posterPath: cleanPoster,
          backdropPath: cleanBackdrop,
          overview: (show.overview == null || show.overview!.isEmpty) ? tmdbShow.overview : show.overview,
          totalSeasons: tmdbShow.totalSeasons > 0 ? tmdbShow.totalSeasons : show.totalSeasons,
          totalEpisodes: tmdbShow.totalEpisodes > 0 ? tmdbShow.totalEpisodes : show.totalEpisodes,
          genres: show.genres.isEmpty ? tmdbShow.genres : show.genres,
          voteAverage: tmdbShow.voteAverage > 0 ? tmdbShow.voteAverage : show.voteAverage,
          firstAirDate: show.firstAirDate ?? tmdbShow.firstAirDate,
        );
        return await upsertShow(updated);
      }
    } catch (_) {}
    return null;
  }

  List<FriendModel> getFriends() => _friends;
}

class _RewatchCandidate {
  final String title;
  final int count;
  final String? posterPath;
  final int subScore;

  const _RewatchCandidate({
    required this.title,
    required this.count,
    this.posterPath,
    this.subScore = 0,
  });
}

class _ShowRewatchAccumulator {
  final Map<String, int> episodeRewatches = {};

  void recordEpisode(int season, int episode, int count) {
    final key = '${season}_$episode';
    final existing = episodeRewatches[key] ?? 0;
    if (count > existing) {
      episodeRewatches[key] = count;
    }
  }

  int get maxEpRewatch {
    int maxVal = 0;
    for (final c in episodeRewatches.values) {
      if (c > maxVal) maxVal = c;
    }
    return maxVal;
  }

  int get rewatchedEpsCount => episodeRewatches.values.where((c) => c > 1).length;
}
