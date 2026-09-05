import 'dart:async';
import 'package:drift/drift.dart';
import '../models/show_model.dart';
import '../models/season_model.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import '../models/watch_record_model.dart';
import '../models/user_stats_model.dart';
import '../models/friend_model.dart';
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

  Stream<List<ShowModel>> get showsStream => _showsController.stream;
  Stream<UserStatsModel> get statsStream => _statsController.stream;

  /// Initializes database and seeds initial sample data if SQLite is empty
  Future<void> init() async {
    final existingShows = await _db.select(_db.showsTable).get();
    if (existingShows.isEmpty) {
      await _seedInitialData();
    } else {
      await _loadFromDb(existingShows);
    }
  }

  Future<void> _loadFromDb(List<ShowsTableData> existingShows) async {
    _shows.clear();
    for (final s in existingShows) {
      _shows[s.id] = ShowModel(
        id: s.id,
        tmdbId: s.tmdbId,
        tvdbId: s.tvdbId,
        name: s.name,
        originalName: s.originalName,
        overview: s.overview,
        posterPath: s.posterPath,
        backdropPath: s.backdropPath,
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
        posterPath: s.posterPath,
        episodeCount: s.episodeCount,
        airDate: s.airDate,
      );
    }

    final dbEpisodes = await _db.select(_db.episodesTable).get();
    _episodes.clear();
    for (final ep in dbEpisodes) {
      _episodes[ep.id] = EpisodeModel(
        id: ep.id,
        showId: ep.showId,
        seasonId: ep.seasonId,
        seasonNumber: ep.seasonNumber,
        episodeNumber: ep.episodeNumber,
        tvdbId: ep.tvdbId,
        tmdbId: ep.tmdbId,
        name: ep.name,
        overview: ep.overview,
        stillPath: ep.stillPath,
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
        posterPath: m.posterPath,
        backdropPath: m.backdropPath,
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

    _notify();
  }

  Future<void> _seedInitialData() async {
    // Top followed shows from TV Time archive
    final friends = ShowModel(
      id: 1,
      tmdbId: 1668,
      tvdbId: 79168,
      name: 'Friends',
      overview: 'Rachel Green, Ross Geller, Monica Geller, Joey Tribbiani, Chandler Bing and Phoebe Buffay are six twenty-somethings living in New York City.',
      posterPath: '/7bu30eqzkh9PSSt089V6B4Jz4k1.jpg',
      backdropPath: '/l0qVZIpXtIo7km9u5YAV0ecKpYH.jpg',
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
      tmdbId: 44026,
      tvdbId: 235881,
      name: 'Behzat Ç.',
      originalName: 'Behzat Ç. Bir Ankara Polisiyesi',
      overview: 'Behzat Ç. is a rough, violent, and morally ambiguous police commissioner in Ankara.',
      posterPath: '/h1qYgG4CjQzWqK8W1gqg6h7yU9a.jpg',
      backdropPath: '/vV2NnU6wW9nI8xJz0aD8y1o0K7l.jpg',
      status: 'Returning Series',
      totalSeasons: 5,
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
      posterPath: '/7hdg5kYwA5kE7w1h0U6cK7u.jpg',
      backdropPath: '/e2x9U7zU6aK5p9Y3m0O8b1.jpg',
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

    // Season 1 for Behzat Ç.
    final behzatSeason1 = SeasonModel(
      id: 1,
      showId: behzat.id,
      seasonNumber: 1,
      name: '1. Sezon',
      episodeCount: 38,
      airDate: DateTime(2010, 9, 19),
    );
    await upsertSeason(behzatSeason1);

    // Up next episode for Behzat Ç. (S01E36)
    final upNextEp = EpisodeModel(
      id: 201,
      showId: behzat.id,
      seasonId: 1,
      seasonNumber: 1,
      episodeNumber: 36,
      tvdbId: 4115317,
      name: '36. Bölüm',
      overview: 'Behzat Ç. ve ekibi Ankara sokaklarındaki cinayet şebekesini çözmeye bir adım daha yaklaşır.',
      stillPath: '/vV2NnU6wW9nI8xJz0aD8y1o0K7l.jpg',
      runtimeMinutes: 84,
      airDate: DateTime(2011, 5, 22),
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
      posterPath: '/pfte7mgXtq7cv1jl7aq5gr95Um6.jpg',
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
      posterPath: '/lsas4jgNHk4c4d7z8b3z3.jpg',
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

    _notify();
  }

  void _notify() {
    _showsController.add(getAllShows());
    _statsController.add(getUserStats());
  }

  // --- Shows Operations ---
  List<ShowModel> getAllShows() => _shows.values.toList();

  List<ShowModel> getFollowedShows() =>
      _shows.values.where((s) => s.isFollowed).toList();

  ShowModel? getShowById(int id) => _shows[id];

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
  List<SeasonModel> getSeasonsForShow(int showId) =>
      _seasons.values.where((s) => s.showId == showId).toList();

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
  List<EpisodeModel> getEpisodesForShow(int showId) {
    return _episodes.values.where((e) => e.showId == showId).toList();
  }

  EpisodeModel? getUpNextEpisode() {
    // Return first unwatched episode of a followed show
    for (final show in getFollowedShows()) {
      for (final ep in _episodes.values) {
        if (ep.showId == show.id && !ep.isWatched) {
          return ep;
        }
      }
    }
    // Fallback sample episode
    return _episodes.values.firstWhere(
      (e) => !e.isWatched,
      orElse: () => const EpisodeModel(
        id: 999,
        showId: 2,
        seasonId: 1,
        seasonNumber: 1,
        episodeNumber: 36,
        name: '36. Bölüm',
        stillPath: '/vV2NnU6wW9nI8xJz0aD8y1o0K7l.jpg',
        runtimeMinutes: 84,
      ),
    );
  }

  Future<void> markEpisodeWatched(int episodeId, {bool watched = true}) async {
    final ep = _episodes[episodeId];
    if (ep != null) {
      final newRewatch = watched ? ep.rewatchCount + 1 : ep.rewatchCount;
      final now = DateTime.now();

      _episodes[episodeId] = ep.copyWith(
        isWatched: watched,
        rewatchCount: newRewatch,
        lastWatchedAt: watched ? now : null,
      );

      await (_db.update(_db.episodesTable)..where((t) => t.id.equals(episodeId))).write(
        EpisodesTableCompanion(
          isWatched: Value(watched),
          rewatchCount: Value(newRewatch),
          lastWatchedAt: Value(watched ? now : null),
        ),
      );

      final show = _shows[ep.showId];
      if (show != null) {
        final newCount = watched
            ? show.watchedEpisodesCount + 1
            : (show.watchedEpisodesCount - 1).clamp(0, show.totalEpisodes);
        _shows[show.id] = show.copyWith(watchedEpisodesCount: newCount);
        await (_db.update(_db.showsTable)..where((t) => t.id.equals(show.id))).write(
          ShowsTableCompanion(
            watchedEpisodesCount: Value(newCount),
          ),
        );
      }

      if (watched) {
        final record = WatchRecordModel(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          episodeId: ep.id,
          showId: ep.showId,
          tvdbId: ep.tvdbId,
          seasonNumber: ep.seasonNumber,
          episodeNumber: ep.episodeNumber,
          title: ep.name,
          runtimeMinutes: ep.runtimeMinutes,
          watchedAt: now,
        );
        addWatchRecord(record);
      }

      _notify();
    }
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

    return UserStatsModel(
      totalWatchMinutes: totalMinutes,
      showsFollowedCount: _shows.values.where((s) => s.isFollowed).length,
      episodesWatchedCount: 3393,
      moviesWatchedCount: _movies.length > 2 ? _movies.length : 493,
      genreDistribution: const {
        'Sci-Fi': 38.0,
        'Drama': 29.0,
        'Crime': 21.0,
        'Comedy': 12.0,
      },
      last28DaysActivity: const [
        1, 3, 0, 2, 4, 1, 0,
        2, 5, 3, 1, 0, 2, 4,
        3, 0, 1, 6, 2, 4, 3,
        1, 2, 5, 3, 0, 2, 4,
      ],
      rewatchedShows: const [
        RewatchItem(title: 'Friends', count: 4, posterPath: '/7bu30eqzkh9PSSt089V6B4Jz4k1.jpg'),
        RewatchItem(title: 'Behzat Ç.', count: 3, posterPath: '/h1qYgG4CjQzWqK8W1gqg6h7yU9a.jpg'),
        RewatchItem(title: 'Breaking Bad', count: 3, posterPath: '/ggFHVNu6YYI5L9pCfOacjizRGt.jpg'),
        RewatchItem(title: 'Dark', count: 2, posterPath: '/apbrbWs8M9lyOpJYU5WXrpFbk1Z.jpg'),
      ],
    );
  }

  List<FriendModel> getFriends() => _friends;
}
