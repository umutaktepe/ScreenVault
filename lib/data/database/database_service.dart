import 'dart:async';
import 'package:drift/drift.dart';
import '../models/show_model.dart';
import '../models/season_model.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import '../models/watch_record_model.dart';
import '../models/user_stats_model.dart';
import '../models/friend_model.dart';
import '../tmdb/tmdb_service.dart';
import '../tmdb/behzat_metadata.dart';
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

  final _showsController = StreamController<List<ShowModel>>.broadcast();
  final _statsController = StreamController<UserStatsModel>.broadcast();
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

  /// Initializes database and seeds initial sample data if SQLite is empty
  Future<void> init() async {
    final existingShows = await _db.select(_db.showsTable).get();
    if (existingShows.isEmpty) {
      await _seedInitialData();
    } else {
      await _loadFromDb(existingShows);
    }
    await _cleanCorruptedMockData();
    unawaited(enrichAllMissingMetadata());
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

  Future<void> _loadFromDb(List<ShowsTableData> existingShows) async {
    _shows.clear();
    for (final s in existingShows) {
      final isOriginalBehzat = (s.tvdbId == 235881 || (s.id == 2 && s.name == 'Behzat Ç.'));
      int? effectiveTmdbId = isOriginalBehzat ? 39176 : s.tmdbId;
      if (effectiveTmdbId == 39176 && !isOriginalBehzat) {
        effectiveTmdbId = null;
      }
      _shows[s.id] = ShowModel(
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
      _episodes[ep.id] = EpisodeModel(
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

    final dbMovies = await _db.select(_db.moviesTable).get();
    _movies.clear();
    for (final m in dbMovies) {
      _movies[m.id] = MovieModel(
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

    if (_friends.isEmpty) {
      _friends.add(
        FriendModel(
          friendId: '21583905',
          name: 'Kerem Yılmaz',
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
          affinity: 0.88,
          addedAt: DateTime(2024, 6, 13),
        ),
      );
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

    // Ensure all seed shows have full watch history records and synced episodes
    await _ensureSeedShowsHistoryBackfilled();

    _notify();
    unawaited(enrichAllMissingMetadata());
  }

  Future<void> _seedInitialData() async {
    // Top followed shows from TV Time archive
    final friends = ShowModel(
      id: 1,
      tmdbId: 1668,
      tvdbId: 79168,
      name: 'Friends',
      overview: 'Rachel Green, Ross Geller, Monica Geller, Joey Tribbiani, Chandler Bing and Phoebe Buffay are six twenty-somethings living in New York City.',
      posterPath: null,
      backdropPath: null,
      status: 'Ended',
      totalSeasons: 10,
      totalEpisodes: 236,
      genres: ['Comedy', 'Romance'],
      isFollowed: true,
      watchedEpisodesCount: 236,
      voteAverage: 8.5,
      firstAirDate: DateTime(1994, 9, 22),
    );

    final behzat = ShowModel(
      id: 2,
      tmdbId: 39176,
      tvdbId: 235881,
      name: 'Behzat Ç.',
      originalName: 'Behzat Ç. Bir Ankara Polisiyesi',
      overview: 'Behzat Ç. is a rough, violent, and morally ambiguous police commissioner in Ankara.',
      posterPath: null,
      backdropPath: null,
      status: 'Returning Series',
      totalSeasons: 4,
      totalEpisodes: 105,
      genres: ['Crime', 'Drama', 'Mystery'],
      isFollowed: true,
      watchedEpisodesCount: 96,
      voteAverage: 8.8,
      firstAirDate: DateTime(2010, 9, 19),
    );

    final dark = ShowModel(
      id: 3,
      tmdbId: 70523,
      tvdbId: 334824,
      name: 'Dark',
      overview: 'A missing child sets four families on a frantic hunt for answers as they unearth a mind-bending mystery that spans three generations.',
      posterPath: '/apbrbWs8M9lyOpJYU5WXrpFbk1Z.jpg',
      backdropPath: '/3lBDg3i6nn5R2NKICJ79f94aAvm.jpg',
      status: 'Ended',
      totalSeasons: 3,
      totalEpisodes: 26,
      genres: ['Sci-Fi', 'Mystery', 'Drama'],
      isFollowed: true,
      watchedEpisodesCount: 26,
      voteAverage: 8.4,
      firstAirDate: DateTime(2017, 12, 1),
    );

    final succession = ShowModel(
      id: 4,
      tmdbId: 76331,
      tvdbId: 338186,
      name: 'Succession',
      overview: 'The Roy family is known for controlling the biggest media and entertainment company in the world.',
      posterPath: null,
      backdropPath: null,
      status: 'Ended',
      totalSeasons: 4,
      totalEpisodes: 39,
      genres: ['Drama'],
      isFollowed: true,
      watchedEpisodesCount: 36,
      voteAverage: 8.9,
      firstAirDate: DateTime(2018, 6, 3),
    );

    await upsertShow(friends);
    await upsertShow(behzat);
    await upsertShow(dark);
    await upsertShow(succession);

    // Seasons for Behzat Ç.
    for (int s = 1; s <= behzat.totalSeasons; s++) {
      await upsertSeason(SeasonModel(
        id: behzat.id * 100 + s,
        showId: behzat.id,
        seasonNumber: s,
        name: '$s. Sezon',
      ));
    }

    // Up next episode for Behzat Ç. (S01E36 - Gece Uçuşu)
    final upNextEp = EpisodeModel(
      id: 201,
      showId: behzat.id,
      seasonId: 1,
      seasonNumber: 1,
      episodeNumber: 36,
      tvdbId: 4115317,
      tmdbId: 39176,
      name: 'Gece Uçuşu',
      overview: 'Cinayet masası ekibi, meslektaşının işten atılmasından ve bir yolcunun uçaktan çıkarılmasından sorumlu olan kabin amirinin öldürülmesini araştırır.',
      stillPath: '/1kBczkdnbW2VXu4QM6erkrNawJ8.jpg',
      runtimeMinutes: 102,
      airDate: DateTime(2011, 6, 5),
      voteAverage: 9.1,
      isWatched: false,
    );
    _episodes[upNextEp.id] = upNextEp;
    await _db.into(_db.episodesTable).insertOnConflictUpdate(
          EpisodesTableCompanion.insert(
            id: Value(upNextEp.id),
            showId: upNextEp.showId,
            seasonId: upNextEp.seasonId,
            seasonNumber: upNextEp.seasonNumber,
            episodeNumber: upNextEp.episodeNumber,
            tvdbId: Value(upNextEp.tvdbId),
            tmdbId: Value(upNextEp.tmdbId),
            name: upNextEp.name,
            overview: Value(upNextEp.overview),
            stillPath: Value(upNextEp.stillPath),
            runtimeMinutes: Value(upNextEp.runtimeMinutes),
            airDate: Value(upNextEp.airDate),
            voteAverage: Value(upNextEp.voteAverage),
            isWatched: Value(upNextEp.isWatched),
          ),
        );

    // Sample Movies
    final fury = MovieModel(
      id: 1,
      tmdbId: 228150,
      title: 'Fury',
      overview: 'In April 1945, the Allies make their final push in the European Theatre.',
      posterPath: null,
      runtimeMinutes: 134,
      genres: ['War', 'Action', 'Drama'],
      isWatched: true,
      isFollowed: true,
      watchedAt: DateTime(2024, 6, 26),
      voteAverage: 7.5,
    );

    final lastSamurai = MovieModel(
      id: 2,
      tmdbId: 616,
      title: 'The Last Samurai',
      overview: 'Nathan Algren is an American captain who is hired by the Emperor of Japan to train the country\'s first modern infantry army.',
      posterPath: null,
      runtimeMinutes: 154,
      genres: ['Action', 'Adventure', 'Drama'],
      isWatched: true,
      isFollowed: true,
      watchedAt: DateTime(2024, 6, 18),
      voteAverage: 7.6,
    );

    await upsertMovie(fury);
    await upsertMovie(lastSamurai);

    // Friends from friend.csv
    _friends.add(
      FriendModel(
        friendId: '21583905',
        name: 'Kerem Yılmaz',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
        affinity: 0.88,
        addedAt: DateTime(2024, 6, 13),
      ),
    );

    // Seed watch history records and sync episodes for all initial shows
    await _ensureSeedShowsHistoryBackfilled();

    _notify();
  }

  Future<void> _ensureSeedShowsHistoryBackfilled() async {
    // Clean up any accidentally assigned show-level tvdbId from episodesTable
    await (_db.update(_db.episodesTable)
          ..where((t) => t.tvdbId.isIn(const [235881, 334360, 336279, 79168])))
        .write(const EpisodesTableCompanion(tvdbId: Value(null)));
    for (final ep in _episodes.values) {
      if (ep.tvdbId == 235881 || ep.tvdbId == 334360 || ep.tvdbId == 336279 || ep.tvdbId == 79168) {
        _episodes[ep.id] = ep.copyWith(tvdbId: null);
      }
    }

    // 1. Behzat Ç. (id: 2, tvdbId: 235881, tmdbId: 39176)
    final behzatShow = _shows.values.where((s) => s.tvdbId == 235881 || (s.id == 2 && s.name == 'Behzat Ç.')).firstOrNull;
    if (behzatShow != null && behzatShow.tmdbId != 39176) {
      final updatedShow = behzatShow.copyWith(tmdbId: 39176);
      _shows[updatedShow.id] = updatedShow;
      await (_db.update(_db.showsTable)..where((t) => t.id.equals(updatedShow.id))).write(
        const ShowsTableCompanion(tmdbId: Value(39176)),
      );
    }

    // S1E36 must be unwatched (Up Next). Remove any erroneous S1E36 watch records.
    _watchRecords.removeWhere((r) =>
        (r.showId == 2 || r.tvdbId == 235881 || r.sId == 235881) &&
        r.seasonNumber == 1 &&
        r.episodeNumber == 36);
    await (_db.delete(_db.episodeWatchHistoryTable)
          ..where((t) =>
              (t.showId.equals(2) | t.tvdbId.equals(235881) | t.sId.equals(235881)) &
              t.seasonNumber.equals(1) &
              t.episodeNumber.equals(36)))
        .go();

    final behzatCount = _watchRecords.where((r) =>
        (r.showId == 2 || r.tvdbId == 235881 || r.sId == 235881) &&
        !(r.seasonNumber == 1 && r.episodeNumber == 36)).length;
    if (behzatCount < 96) {
      await _seedBehzatWatchHistory(2);
    }

    // 2. Dark (id: 3, tvdbId: 334360, tmdbId: 70523, 26 eps)
    final darkCount = _watchRecords.where((r) =>
        r.showId == 3 || r.tvdbId == 334360 || r.sId == 334360).length;
    if (darkCount < 26) {
      await _seedDarkWatchHistory(3);
    }

    // 3. Succession (id: 4, tvdbId: 336279, tmdbId: 76331, 36 eps)
    final succCount = _watchRecords.where((r) =>
        r.showId == 4 || r.tvdbId == 336279 || r.sId == 336279).length;
    if (succCount < 36) {
      await _seedSuccessionWatchHistory(4);
    }

    // 4. Friends (id: 1, tvdbId: 79168, tmdbId: 1668, 207 eps)
    final friendsCount = _watchRecords.where((r) =>
        r.showId == 1 || r.tvdbId == 79168 || r.sId == 79168).length;
    if (friendsCount < 207) {
      await _seedFriendsWatchHistory(1);
    }

    // Sync all in-memory and database episodes with watch records
    await syncEpisodesWithWatchHistory();

    // Backfill authentic TMDB metadata (stills, runtimes, titles) for Behzat Ç.
    await _backfillBehzatEpisodesMetadata();
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
        _episodes[epModel.id] = epModel;
        await _db.into(_db.episodesTable).insertOnConflictUpdate(
              EpisodesTableCompanion.insert(
                id: Value(epModel.id),
                showId: targetShowId,
                seasonId: r.seasonNumber,
                seasonNumber: r.seasonNumber,
                episodeNumber: r.episodeNumber,
                tvdbId: const Value(null),
                name: epModel.name,
                runtimeMinutes: Value(epModel.runtimeMinutes),
                airDate: Value(epModel.airDate),
                voteAverage: const Value(8.5),
                isWatched: const Value(true),
                rewatchCount: Value(epModel.rewatchCount),
                lastWatchedAt: Value(epModel.lastWatchedAt),
              ),
            );
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
      if (hasHistory && !ep.isWatched) {
        final latest = getLatestWatchRecord(
          showId: ep.showId,
          tvdbId: show?.tvdbId,
          seasonNumber: ep.seasonNumber,
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
        await (_db.update(_db.episodesTable)..where((t) => t.id.equals(ep.id))).write(
          EpisodesTableCompanion(
            isWatched: const Value(true),
            lastWatchedAt: Value(updated.lastWatchedAt),
            rewatchCount: Value(updated.rewatchCount),
          ),
        );
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

  Future<void> _seedBehzatWatchHistory(int showId) async {
    const int tvdbId = 235881;
    final List<Map<String, dynamic>> recordsToSeed = [];

    // Season 1: 35 episodes watched (S01E36 unwatched for Up Next)
    for (int ep = 1; ep <= 35; ep++) {
      final epMeta = BehzatMetadata.seasons[1]?.where((m) => m['ep'] == ep).firstOrNull;
      final epTitle = epMeta?['name'] as String? ?? '$ep. Bölüm';
      final epDate = epMeta?['date'] != null ? DateTime.tryParse(epMeta!['date'] as String) : null;
      final epRuntime = epMeta?['runtime'] as int? ?? 75;
      recordsToSeed.add({
        'season': 1,
        'ep': ep,
        'title': epTitle,
        'runtime': epRuntime,
        'date': epDate ?? DateTime(2010, 9, 19).add(Duration(days: ep * 7)),
      });
    }
    // Season 2: 31 episodes watched (complete season)
    for (int ep = 1; ep <= 31; ep++) {
      final epMeta = BehzatMetadata.seasons[2]?.where((m) => m['ep'] == ep).firstOrNull;
      final epTitle = epMeta?['name'] as String? ?? '$ep. Bölüm';
      final epDate = epMeta?['date'] != null ? DateTime.tryParse(epMeta!['date'] as String) : null;
      final epRuntime = epMeta?['runtime'] as int? ?? 75;
      recordsToSeed.add({
        'season': 2,
        'ep': ep,
        'title': epTitle,
        'runtime': epRuntime,
        'date': epDate ?? DateTime(2011, 11, 13).add(Duration(days: ep * 7)),
      });
    }
    // Season 3: 27 episodes watched (complete season)
    for (int ep = 1; ep <= 27; ep++) {
      final epMeta = BehzatMetadata.seasons[3]?.where((m) => m['ep'] == ep).firstOrNull;
      final epTitle = epMeta?['name'] as String? ?? '$ep. Bölüm';
      final epDate = epMeta?['date'] != null ? DateTime.tryParse(epMeta!['date'] as String) : null;
      final epRuntime = epMeta?['runtime'] as int? ?? 75;
      recordsToSeed.add({
        'season': 3,
        'ep': ep,
        'title': epTitle,
        'runtime': epRuntime,
        'date': epDate ?? DateTime(2012, 9, 21).add(Duration(days: ep * 7)),
      });
    }
    // Season 4: 3 episodes watched
    for (int ep = 1; ep <= 3; ep++) {
      final epMeta = BehzatMetadata.seasons[4]?.where((m) => m['ep'] == ep).firstOrNull;
      final epTitle = epMeta?['name'] as String? ?? '$ep. Bölüm';
      final epDate = epMeta?['date'] != null ? DateTime.tryParse(epMeta!['date'] as String) : null;
      final epRuntime = epMeta?['runtime'] as int? ?? 75;
      recordsToSeed.add({
        'season': 4,
        'ep': ep,
        'title': epTitle,
        'runtime': epRuntime,
        'date': epDate ?? DateTime(2019, 7, 25).add(Duration(days: ep * 7)),
      });
    }

    for (final r in recordsToSeed) {
      final seasonNum = r['season'] as int;
      final epNum = r['ep'] as int;
      final title = r['title'] as String;
      final runtime = r['runtime'] as int;
      final date = r['date'] as DateTime;

      final epMeta = BehzatMetadata.seasons[seasonNum]?.where((m) => m['ep'] == epNum).firstOrNull;
      final epStill = epMeta?['still'] as String?;
      final epOverview = epMeta?['overview'] as String?;
      final epVote = (epMeta?['vote'] as num?)?.toDouble() ?? 9.0;

      final alreadyHas = _watchRecords.any((rec) =>
          (rec.showId == showId || rec.tvdbId == tvdbId || rec.sId == tvdbId) &&
          rec.seasonNumber == seasonNum &&
          rec.episodeNumber == epNum);
      if (!alreadyHas) {
        final insertedId = await _db.into(_db.episodeWatchHistoryTable).insert(
              EpisodeWatchHistoryTableCompanion.insert(
                title: title,
                watchedAt: date,
                showId: Value(showId),
                tvdbId: const Value(tvdbId),
                sId: const Value(tvdbId),
                seasonNumber: Value(seasonNum),
                episodeNumber: Value(epNum),
                runtimeMinutes: Value(runtime),
                rewatchCount: const Value(1),
              ),
            );

        final rec = WatchRecordModel(
          id: insertedId,
          showId: showId,
          tvdbId: tvdbId,
          sId: tvdbId,
          seasonNumber: seasonNum,
          episodeNumber: epNum,
          title: title,
          runtimeMinutes: runtime,
          watchedAt: date,
          rewatchCount: 1,
        );
        _watchRecords.add(rec);
      }

      // Also ensure episode exists in _episodes and episodesTable
      final epId = showId * 10000 + seasonNum * 100 + epNum;
      final existingEp = _episodes[epId];
      final epModel = EpisodeModel(
        id: existingEp?.id ?? epId,
        showId: showId,
        seasonId: seasonNum,
        seasonNumber: seasonNum,
        episodeNumber: epNum,
        tvdbId: (existingEp?.tvdbId != tvdbId) ? existingEp?.tvdbId : null,
        tmdbId: BehzatMetadata.tmdbId,
        name: title,
        overview: epOverview ?? existingEp?.overview,
        stillPath: epStill ?? existingEp?.stillPath,
        runtimeMinutes: runtime,
        airDate: existingEp?.airDate ?? date,
        voteAverage: epVote > 0 ? epVote : (existingEp?.voteAverage ?? 9.0),
        isWatched: true,
        rewatchCount: (existingEp != null && existingEp.rewatchCount > 0) ? existingEp.rewatchCount : 1,
        lastWatchedAt: existingEp?.lastWatchedAt ?? date,
      );
      _episodes[epModel.id] = epModel;
      await _db.into(_db.episodesTable).insertOnConflictUpdate(
            EpisodesTableCompanion.insert(
              id: Value(epModel.id),
              showId: showId,
              seasonId: seasonNum,
              seasonNumber: seasonNum,
              episodeNumber: epNum,
              tvdbId: Value(epModel.tvdbId),
              tmdbId: const Value(BehzatMetadata.tmdbId),
              name: epModel.name,
              overview: Value(epModel.overview),
              stillPath: Value(epModel.stillPath),
              runtimeMinutes: Value(runtime),
              airDate: Value(epModel.airDate),
              voteAverage: Value(epModel.voteAverage),
              isWatched: const Value(true),
              rewatchCount: const Value(1),
              lastWatchedAt: Value(epModel.lastWatchedAt),
            ),
          );
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

  Future<void> _seedDarkWatchHistory(int showId) async {
    const int tvdbId = 334360;
    final List<Map<String, dynamic>> recordsToSeed = [];

    // S1: 10 eps (2017-12-01)
    for (int ep = 1; ep <= 10; ep++) {
      recordsToSeed.add({
        'season': 1,
        'ep': ep,
        'title': '$ep. Bölüm',
        'date': DateTime(2017, 12, 1).add(Duration(days: ep)),
      });
    }
    // S2: 8 eps (2019-06-21)
    for (int ep = 1; ep <= 8; ep++) {
      recordsToSeed.add({
        'season': 2,
        'ep': ep,
        'title': '$ep. Bölüm',
        'date': DateTime(2019, 6, 21).add(Duration(days: ep)),
      });
    }
    // S3: 8 eps (2020-06-27)
    for (int ep = 1; ep <= 8; ep++) {
      recordsToSeed.add({
        'season': 3,
        'ep': ep,
        'title': '$ep. Bölüm',
        'date': DateTime(2020, 6, 27).add(Duration(days: ep)),
      });
    }

    for (final r in recordsToSeed) {
      final seasonNum = r['season'] as int;
      final epNum = r['ep'] as int;
      final title = r['title'] as String;
      final date = r['date'] as DateTime;

      final alreadyHas = _watchRecords.any((rec) =>
          (rec.showId == showId || rec.tvdbId == tvdbId || rec.sId == tvdbId) &&
          rec.seasonNumber == seasonNum &&
          rec.episodeNumber == epNum);
      if (!alreadyHas) {
        final insertedId = await _db.into(_db.episodeWatchHistoryTable).insert(
              EpisodeWatchHistoryTableCompanion.insert(
                title: title,
                watchedAt: date,
                showId: Value(showId),
                tvdbId: const Value(tvdbId),
                sId: const Value(tvdbId),
                seasonNumber: Value(seasonNum),
                episodeNumber: Value(epNum),
                runtimeMinutes: const Value(60),
                rewatchCount: const Value(1),
              ),
            );

        _watchRecords.add(WatchRecordModel(
          id: insertedId,
          showId: showId,
          tvdbId: tvdbId,
          sId: tvdbId,
          seasonNumber: seasonNum,
          episodeNumber: epNum,
          title: title,
          runtimeMinutes: 60,
          watchedAt: date,
          rewatchCount: 1,
        ));
      }

      final epId = showId * 10000 + seasonNum * 100 + epNum;
      final existingEp = _episodes[epId];
      final epModel = EpisodeModel(
        id: existingEp?.id ?? epId,
        showId: showId,
        seasonId: seasonNum,
        seasonNumber: seasonNum,
        episodeNumber: epNum,
        tvdbId: (existingEp?.tvdbId != tvdbId) ? existingEp?.tvdbId : null,
        tmdbId: existingEp?.tmdbId,
        name: existingEp?.name.isNotEmpty == true ? existingEp!.name : title,
        stillPath: existingEp?.stillPath,
        runtimeMinutes: 60,
        airDate: date,
        voteAverage: 8.8,
        isWatched: true,
        rewatchCount: 1,
        lastWatchedAt: date,
      );
      _episodes[epModel.id] = epModel;
      await _db.into(_db.episodesTable).insertOnConflictUpdate(
            EpisodesTableCompanion.insert(
              id: Value(epModel.id),
              showId: showId,
              seasonId: seasonNum,
              seasonNumber: seasonNum,
              episodeNumber: epNum,
              tvdbId: Value(epModel.tvdbId),
              tmdbId: Value(epModel.tmdbId),
              name: epModel.name,
              runtimeMinutes: const Value(60),
              airDate: Value(date),
              voteAverage: const Value(8.8),
              isWatched: const Value(true),
              rewatchCount: const Value(1),
              lastWatchedAt: Value(date),
            ),
          );
    }
  }

  Future<void> _seedSuccessionWatchHistory(int showId) async {
    const int tvdbId = 336279;
    final List<Map<String, dynamic>> recordsToSeed = [];

    // S1: 10 eps
    for (int ep = 1; ep <= 10; ep++) {
      recordsToSeed.add({
        'season': 1,
        'ep': ep,
        'title': '$ep. Bölüm',
        'date': DateTime(2018, 6, 3).add(Duration(days: ep * 7)),
      });
    }
    // S2: 10 eps
    for (int ep = 1; ep <= 10; ep++) {
      recordsToSeed.add({
        'season': 2,
        'ep': ep,
        'title': '$ep. Bölüm',
        'date': DateTime(2019, 8, 11).add(Duration(days: ep * 7)),
      });
    }
    // S3: 9 eps
    for (int ep = 1; ep <= 9; ep++) {
      recordsToSeed.add({
        'season': 3,
        'ep': ep,
        'title': '$ep. Bölüm',
        'date': DateTime(2021, 10, 17).add(Duration(days: ep * 7)),
      });
    }
    // S4: 7 eps
    for (int ep = 1; ep <= 7; ep++) {
      recordsToSeed.add({
        'season': 4,
        'ep': ep,
        'title': '$ep. Bölüm',
        'date': DateTime(2023, 3, 26).add(Duration(days: ep * 7)),
      });
    }

    for (final r in recordsToSeed) {
      final seasonNum = r['season'] as int;
      final epNum = r['ep'] as int;
      final title = r['title'] as String;
      final date = r['date'] as DateTime;

      final alreadyHas = _watchRecords.any((rec) =>
          (rec.showId == showId || rec.tvdbId == tvdbId || rec.sId == tvdbId) &&
          rec.seasonNumber == seasonNum &&
          rec.episodeNumber == epNum);
      if (!alreadyHas) {
        final insertedId = await _db.into(_db.episodeWatchHistoryTable).insert(
              EpisodeWatchHistoryTableCompanion.insert(
                title: title,
                watchedAt: date,
                showId: Value(showId),
                tvdbId: const Value(tvdbId),
                sId: const Value(tvdbId),
                seasonNumber: Value(seasonNum),
                episodeNumber: Value(epNum),
                runtimeMinutes: const Value(60),
                rewatchCount: const Value(1),
              ),
            );

        _watchRecords.add(WatchRecordModel(
          id: insertedId,
          showId: showId,
          tvdbId: tvdbId,
          sId: tvdbId,
          seasonNumber: seasonNum,
          episodeNumber: epNum,
          title: title,
          runtimeMinutes: 60,
          watchedAt: date,
          rewatchCount: 1,
        ));
      }

      final epId = showId * 10000 + seasonNum * 100 + epNum;
      final existingEp = _episodes[epId];
      final epModel = EpisodeModel(
        id: existingEp?.id ?? epId,
        showId: showId,
        seasonId: seasonNum,
        seasonNumber: seasonNum,
        episodeNumber: epNum,
        tvdbId: (existingEp?.tvdbId != tvdbId) ? existingEp?.tvdbId : null,
        tmdbId: existingEp?.tmdbId,
        name: existingEp?.name.isNotEmpty == true ? existingEp!.name : title,
        stillPath: existingEp?.stillPath,
        runtimeMinutes: 60,
        airDate: date,
        voteAverage: 8.9,
        isWatched: true,
        rewatchCount: 1,
        lastWatchedAt: date,
      );
      _episodes[epModel.id] = epModel;
      await _db.into(_db.episodesTable).insertOnConflictUpdate(
            EpisodesTableCompanion.insert(
              id: Value(epModel.id),
              showId: showId,
              seasonId: seasonNum,
              seasonNumber: seasonNum,
              episodeNumber: epNum,
              tvdbId: Value(epModel.tvdbId),
              tmdbId: Value(epModel.tmdbId),
              name: epModel.name,
              runtimeMinutes: const Value(60),
              airDate: Value(date),
              voteAverage: const Value(8.9),
              isWatched: const Value(true),
              rewatchCount: const Value(1),
              lastWatchedAt: Value(date),
            ),
          );
    }
  }

  Future<void> _seedFriendsWatchHistory(int showId) async {
    const int tvdbId = 79168;
    final List<Map<String, dynamic>> recordsToSeed = [];

    // Seasons 1-8: 24 episodes each = 192 episodes
    for (int s = 1; s <= 8; s++) {
      for (int ep = 1; ep <= 24; ep++) {
        recordsToSeed.add({
          'season': s,
          'ep': ep,
          'title': 'The One with $ep',
          'date': DateTime(1994 + s - 1, 9, 22).add(Duration(days: ep * 7)),
        });
      }
    }
    // Season 9: 15 episodes (192 + 15 = 207)
    for (int ep = 1; ep <= 15; ep++) {
      recordsToSeed.add({
        'season': 9,
        'ep': ep,
        'title': 'The One with $ep',
        'date': DateTime(2002, 9, 26).add(Duration(days: ep * 7)),
      });
    }

    for (final r in recordsToSeed) {
      final seasonNum = r['season'] as int;
      final epNum = r['ep'] as int;
      final title = r['title'] as String;
      final date = r['date'] as DateTime;

      final alreadyHas = _watchRecords.any((rec) =>
          (rec.showId == showId || rec.tvdbId == tvdbId || rec.sId == tvdbId) &&
          rec.seasonNumber == seasonNum &&
          rec.episodeNumber == epNum);
      if (!alreadyHas) {
        final insertedId = await _db.into(_db.episodeWatchHistoryTable).insert(
              EpisodeWatchHistoryTableCompanion.insert(
                title: title,
                watchedAt: date,
                showId: Value(showId),
                tvdbId: const Value(tvdbId),
                sId: const Value(tvdbId),
                seasonNumber: Value(seasonNum),
                episodeNumber: Value(epNum),
                runtimeMinutes: const Value(22),
                rewatchCount: const Value(1),
              ),
            );

        _watchRecords.add(WatchRecordModel(
          id: insertedId,
          showId: showId,
          tvdbId: tvdbId,
          sId: tvdbId,
          seasonNumber: seasonNum,
          episodeNumber: epNum,
          title: title,
          runtimeMinutes: 22,
          watchedAt: date,
          rewatchCount: 1,
        ));
      }
    }
  }

  void _notify() {
    _showsController.add(getAllShows());
    _statsController.add(getUserStats());
  }

  // --- Shows Operations ---
  List<ShowModel> getAllShows() => _shows.values.toList();

  List<ShowModel> getFollowedShows() =>
      _shows.values.where((s) => s.isFollowed).toList();

  ShowModel? getShowById(int id) {
    if (_shows.containsKey(id)) return _shows[id];
    for (final s in _shows.values) {
      if (s.tvdbId == id || s.tmdbId == id) return s;
    }
    return null;
  }

  ShowModel? getShowByTvdbId(int tvdbId) {
    for (final s in _shows.values) {
      if (s.tvdbId == tvdbId) return s;
    }
    return null;
  }

  Future<void> upsertShow(ShowModel show) async {
    _shows[show.id] = show;
    await _db.into(_db.showsTable).insertOnConflictUpdate(
          ShowsTableCompanion.insert(
            id: Value(show.id),
            tmdbId: Value(show.tmdbId),
            tvdbId: Value(show.tvdbId),
            name: show.name,
            originalName: Value(show.originalName),
            overview: Value(show.overview),
            posterPath: Value(show.posterPath),
            backdropPath: Value(show.backdropPath),
            status: Value(show.status),
            totalSeasons: Value(show.totalSeasons),
            totalEpisodes: Value(show.totalEpisodes),
            genres: Value(show.genres.join(',')),
            isFollowed: Value(show.isFollowed),
            watchedEpisodesCount: Value(show.watchedEpisodesCount),
            voteAverage: Value(show.voteAverage),
            firstAirDate: Value(show.firstAirDate),
            createdAt: Value(show.createdAt ?? DateTime.now()),
            updatedAt: Value(show.updatedAt ?? DateTime.now()),
          ),
        );
    _notify();
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
      await upsertShow(show.copyWith(isFollowed: !show.isFollowed));
    }
  }

  Future<void> upsertSeason(SeasonModel season) async {
    _seasons[season.id] = season;
    await _db.into(_db.seasonsTable).insertOnConflictUpdate(
          SeasonsTableCompanion.insert(
            id: Value(season.id),
            showId: season.showId,
            seasonNumber: season.seasonNumber,
            name: season.name,
            overview: Value(season.overview),
            posterPath: Value(season.posterPath),
            episodeCount: Value(season.episodeCount),
            airDate: Value(season.airDate),
          ),
        );
  }

  // --- Episode & Up Next Operations ---
  EpisodeModel? getEpisodeById(int id) => _episodes[id];

  List<EpisodeModel> getAllEpisodes() => _episodes.values.toList();

  List<EpisodeModel> getEpisodesForShow(int showId) {
    return _episodes.values.where((e) => e.showId == showId).toList();
  }

  Future<void> upsertEpisode(EpisodeModel ep) async {
    _episodes[ep.id] = ep;
    await _db.into(_db.episodesTable).insertOnConflictUpdate(
          EpisodesTableCompanion.insert(
            id: Value(ep.id),
            showId: ep.showId,
            seasonId: ep.seasonId,
            seasonNumber: ep.seasonNumber,
            episodeNumber: ep.episodeNumber,
            tvdbId: Value(ep.tvdbId),
            tmdbId: Value(ep.tmdbId),
            name: ep.name,
            overview: Value(ep.overview),
            stillPath: Value(ep.stillPath),
            runtimeMinutes: Value(ep.runtimeMinutes),
            airDate: Value(ep.airDate),
            voteAverage: Value(ep.voteAverage),
            isWatched: Value(ep.isWatched),
            rewatchCount: Value(ep.rewatchCount),
            lastWatchedAt: Value(ep.lastWatchedAt),
          ),
        );
    _notify();
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

  Future<void> upsertMovie(MovieModel movie) async {
    _movies[movie.id] = movie;
    await _db.into(_db.moviesTable).insertOnConflictUpdate(
          MoviesTableCompanion.insert(
            id: Value(movie.id),
            tmdbId: Value(movie.tmdbId),
            imdbId: Value(movie.imdbId),
            title: movie.title,
            overview: Value(movie.overview),
            posterPath: Value(movie.posterPath),
            backdropPath: Value(movie.backdropPath),
            releaseDate: Value(movie.releaseDate),
            runtimeMinutes: Value(movie.runtimeMinutes),
            genres: Value(movie.genres.join(',')),
            isWatched: Value(movie.isWatched),
            isFollowed: Value(movie.isFollowed),
            watchedAt: Value(movie.watchedAt),
            rewatchCount: Value(movie.rewatchCount),
            voteAverage: Value(movie.voteAverage),
          ),
        );
    _notify();
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

  UserStatsModel getUserStats() {
    int totalMinutes = 0;
    if (_watchRecords.isNotEmpty) {
      for (final r in _watchRecords) {
        totalMinutes += r.runtimeMinutes;
      }
    } else {
      totalMinutes = 186576; // 4 Months 9 Days 13 Hours
    }

    // Dynamic 28 days activity from real watch records
    final now = DateTime.now();
    final List<int> activity28Days = List.filled(28, 0);
    bool hasRecentActivity = false;
    for (final r in _watchRecords) {
      final diff = now.difference(r.watchedAt).inDays;
      if (diff >= 0 && diff < 28) {
        activity28Days[27 - diff]++;
        hasRecentActivity = true;
      }
    }
    final finalActivity = hasRecentActivity
        ? activity28Days
        : const [
            1, 3, 0, 2, 4, 1, 0,
            2, 5, 3, 1, 0, 2, 4,
            3, 0, 1, 6, 2, 4, 3,
            1, 2, 5, 3, 0, 2, 4,
          ];

    // Dynamic rewatched shows
    final Map<int, int> rewatchMap = {};
    for (final ep in _episodes.values.where((e) => e.rewatchCount > 1)) {
      rewatchMap[ep.showId] = (rewatchMap[ep.showId] ?? 0) + ep.rewatchCount;
    }
    for (final r in _watchRecords.where((r) => r.rewatchCount > 1)) {
      final sId = r.showId ?? r.tvdbId ?? 0;
      if (sId > 0) {
        rewatchMap[sId] = (rewatchMap[sId] ?? 0) + r.rewatchCount;
      }
    }

    final List<RewatchItem> dynamicRewatches = [];
    final sortedRewatchEntries = rewatchMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedRewatchEntries.take(6)) {
      final s = getShowById(entry.key);
      if (s != null && s.posterPath != null) {
        dynamicRewatches.add(RewatchItem(
          title: s.name,
          count: entry.value,
          posterPath: s.posterPath!,
        ));
      }
    }

    // Fallback to top followed shows with real posters if no rewatches logged yet
    if (dynamicRewatches.isEmpty) {
      for (final s in getFollowedShows().where((s) => s.posterPath != null).take(4)) {
        dynamicRewatches.add(RewatchItem(
          title: s.name,
          count: 1,
          posterPath: s.posterPath!,
        ));
      }
    }

    // Dynamic genre distribution
    final Map<String, int> genreCounts = {};
    for (final s in _shows.values) {
      for (final g in s.genres) {
        if (g.isNotEmpty) genreCounts[g] = (genreCounts[g] ?? 0) + 1;
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
    } else {
      genreDistribution.addAll({
        'Sci-Fi': 38.0,
        'Drama': 29.0,
        'Crime': 21.0,
        'Comedy': 12.0,
      });
    }

    final watchedEpCount = _watchRecords.isNotEmpty
        ? _watchRecords.map((r) => '${r.showId}_${r.seasonNumber}_${r.episodeNumber}').toSet().length
        : 3393;

    return UserStatsModel(
      totalWatchMinutes: totalMinutes,
      showsFollowedCount: _shows.values.where((s) => s.isFollowed).length,
      episodesWatchedCount: watchedEpCount,
      moviesWatchedCount: _movies.values.any((m) => m.isWatched)
          ? _movies.values.where((m) => m.isWatched).length
          : 493,
      genreDistribution: genreDistribution,
      last28DaysActivity: finalActivity,
      rewatchedShows: dynamicRewatches,
    );
  }

  List<WatchRecordModel> getAllWatchRecords() => List.unmodifiable(_watchRecords);

  Future<void> insertWatchRecord(WatchRecordModel record) async {
    _watchRecords.removeWhere((r) =>
        (r.showId == record.showId || (record.tvdbId != null && r.tvdbId == record.tvdbId)) &&
        r.seasonNumber == record.seasonNumber &&
        r.episodeNumber == record.episodeNumber);
    _watchRecords.add(record);

    await _db.into(_db.episodeWatchHistoryTable).insertOnConflictUpdate(
          EpisodeWatchHistoryTableCompanion.insert(
            title: record.title,
            watchedAt: record.watchedAt,
            episodeId: Value(record.episodeId),
            showId: Value(record.showId),
            tvdbId: Value(record.tvdbId),
            sId: Value(record.sId ?? record.tvdbId),
            seasonNumber: Value(record.seasonNumber),
            episodeNumber: Value(record.episodeNumber),
            runtimeMinutes: Value(record.runtimeMinutes),
            rewatchCount: Value(record.rewatchCount),
          ),
        );

    final ep = _episodes.values.where((e) =>
        (e.showId == record.showId || (record.tvdbId != null && e.tvdbId == record.tvdbId)) &&
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
    _notify();
  }

  Future<void> removeWatchRecord({required int showId, required int seasonNumber, required int episodeNumber}) async {
    _watchRecords.removeWhere((r) =>
        (r.showId == showId || r.tvdbId == showId || r.sId == showId) &&
        r.seasonNumber == seasonNumber &&
        r.episodeNumber == episodeNumber);

    await (_db.delete(_db.episodeWatchHistoryTable)
          ..where((t) =>
              (t.showId.equals(showId) | t.tvdbId.equals(showId) | t.sId.equals(showId)) &
              t.seasonNumber.equals(seasonNumber) &
              t.episodeNumber.equals(episodeNumber)))
        .go();

    final ep = _episodes.values.where((e) =>
        (e.showId == showId || e.tvdbId == showId) &&
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
    _notify();
  }

  List<FriendModel> getFriends() => _friends;
}
