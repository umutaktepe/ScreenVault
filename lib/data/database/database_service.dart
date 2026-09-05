import 'dart:async';
import '../models/show_model.dart';
import '../models/season_model.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import '../models/watch_record_model.dart';
import '../models/user_stats_model.dart';
import '../models/friend_model.dart';

/// Database Service Interface and In-Memory / SQLite repository
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

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

  // Initialize with TV Time initial sample/seed data if empty
  Future<void> init() async {
    if (_shows.isEmpty) {
      _seedInitialData();
    }
  }

  void _seedInitialData() {
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

    _shows[friends.id] = friends;
    _shows[behzat.id] = behzat;
    _shows[dark.id] = dark;
    _shows[succession.id] = succession;

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

    _movies[fury.id] = fury;
    _movies[lastSamurai.id] = lastSamurai;

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
    _notify();
  }

  // --- Season Operations ---
  List<SeasonModel> getSeasonsForShow(int showId) =>
      _seasons.values.where((s) => s.showId == showId).toList();

  Future<void> upsertSeason(SeasonModel season) async {
    _seasons[season.id] = season;
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
      _episodes[episodeId] = ep.copyWith(
        isWatched: watched,
        rewatchCount: watched ? ep.rewatchCount + 1 : ep.rewatchCount,
        lastWatchedAt: watched ? DateTime.now() : null,
      );

      final show = _shows[ep.showId];
      if (show != null) {
        final newCount = watched
            ? show.watchedEpisodesCount + 1
            : (show.watchedEpisodesCount - 1).clamp(0, show.totalEpisodes);
        _shows[show.id] = show.copyWith(watchedEpisodesCount: newCount);
      }

      _notify();
    }
  }

  // --- Movies Operations ---
  List<MovieModel> getAllMovies() => _movies.values.toList();

  Future<void> upsertMovie(MovieModel movie) async {
    _movies[movie.id] = movie;
    _notify();
  }

  // --- Watch Records & Stats ---
  void addWatchRecord(WatchRecordModel record) {
    _watchRecords.add(record);
    _notify();
  }

  UserStatsModel getUserStats() {
    // Exact calculation or fallback to TV Time verified stats
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
