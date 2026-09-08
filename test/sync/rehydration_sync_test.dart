import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenvault/data/database/app_database.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/data/models/episode_model.dart';
import 'package:screenvault/data/models/watch_record_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DatabaseService dbService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
    dbService = DatabaseService(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Zero-Seed Architecture & Cloud Rehydration Sync Tests', () {
    test('Zero-seed init produces clean, empty state without mock shows, movies, or friends', () async {
      await dbService.init();

      expect(dbService.getAllShows(), isEmpty);
      expect(dbService.getFollowedShows(), isEmpty);
      expect(dbService.getAllMovies(), isEmpty);
      expect(dbService.getAllEpisodes(), isEmpty);
      expect(dbService.getAllWatchRecords(), isEmpty);
      expect(dbService.getFriends(), isEmpty);

      // Verify underlying SQLite tables are also completely empty
      final dbShows = await db.select(db.showsTable).get();
      final dbMovies = await db.select(db.moviesTable).get();
      final dbEpisodes = await db.select(db.episodesTable).get();
      final dbHistory = await db.select(db.episodeWatchHistoryTable).get();

      expect(dbShows, isEmpty);
      expect(dbMovies, isEmpty);
      expect(dbEpisodes, isEmpty);
      expect(dbHistory, isEmpty);
    });

    test('Rehydrates remote tracked shows into SQLite when not present locally', () async {
      await dbService.init();

      // Simulate remote tracked show downloaded from PocketBase
      const remoteTvdbId = 81189;
      const remoteTmdbId = 1396;
      final rehydratedShow = ShowModel(
        id: 101,
        tvdbId: remoteTvdbId,
        tmdbId: remoteTmdbId,
        name: 'Breaking Bad',
        posterPath: '/breaking_bad.jpg',
        isFollowed: true,
      );

      // Verify show does not exist locally prior to sync
      expect(dbService.findShow(tvdbId: remoteTvdbId), isNull);

      // Sync rehydration step
      await dbService.upsertShow(rehydratedShow, notify: false);

      // Verify cached in memory
      expect(dbService.getAllShows().length, 1);
      final stored = dbService.findShow(tvdbId: remoteTvdbId);
      expect(stored, isNotNull);
      expect(stored!.name, 'Breaking Bad');
      expect(stored.isFollowed, isTrue);
      expect(dbService.getFollowedShows().length, 1);

      // Verify persisted in SQLite
      final dbShows = await db.select(db.showsTable).get();
      expect(dbShows.length, 1);
      expect(dbShows.first.name, 'Breaking Bad');
      expect(dbShows.first.tvdbId, remoteTvdbId);
      expect(dbShows.first.isFollowed, isTrue);
    });

    test('Rehydrates remote movie watch history into SQLite when not present locally', () async {
      await dbService.init();

      final watchedDate = DateTime(2023, 10, 15, 20, 30);
      const remoteTmdbId = 550;
      final rehydratedMovie = MovieModel(
        id: remoteTmdbId,
        tmdbId: remoteTmdbId,
        title: 'Fight Club',
        posterPath: '/fight_club.jpg',
        runtimeMinutes: 139,
        isWatched: true,
        watchedAt: watchedDate,
      );

      // Verify movie does not exist locally prior to sync
      expect(dbService.getAllMovies().any((m) => m.tmdbId == remoteTmdbId), isFalse);

      // Sync rehydration step
      await dbService.upsertMovie(rehydratedMovie, notify: false);

      // Verify memory cache
      expect(dbService.getAllMovies().length, 1);
      final storedMovie = dbService.getAllMovies().first;
      expect(storedMovie.title, 'Fight Club');
      expect(storedMovie.isWatched, isTrue);
      expect(storedMovie.watchedAt, watchedDate);

      // Verify persisted in SQLite
      final dbMovies = await db.select(db.moviesTable).get();
      expect(dbMovies.length, 1);
      expect(dbMovies.first.title, 'Fight Club');
      expect(dbMovies.first.isWatched, isTrue);
      expect(dbMovies.first.watchedAt, watchedDate);
    });

    test('Rehydrates orphaned watch records by creating shell show and syncing episodes', () async {
      await dbService.init();

      const showId = 300;
      const tvdbId = 77777;

      // 1. Rehydrate shell show
      final shellShow = ShowModel(
        id: showId,
        tvdbId: tvdbId,
        name: 'Show $showId',
        isFollowed: false,
      );
      await dbService.upsertShow(shellShow, notify: false);

      // 2. Add episode
      final ep = EpisodeModel(
        id: 30001,
        showId: showId,
        seasonId: 1,
        seasonNumber: 1,
        episodeNumber: 1,
        name: 'Pilot',
        runtimeMinutes: 50,
      );
      await dbService.upsertEpisode(ep, notify: false);

      // 3. Add watch history record
      final watchRecord = WatchRecordModel(
        id: 1,
        showId: showId,
        tvdbId: tvdbId,
        seasonNumber: 1,
        episodeNumber: 1,
        title: 'Pilot',
        runtimeMinutes: 50,
        watchedAt: DateTime(2024, 2, 1),
        rewatchCount: 1,
      );
      await dbService.insertWatchRecord(watchRecord);

      // 4. Run episode-history reconciliation
      await dbService.syncEpisodesWithWatchHistory();

      expect(dbService.isEpisodeWatchedInHistory(showId: showId, seasonNumber: 1, episodeNumber: 1), isTrue);
      expect(dbService.getWatchedEpisodesCountForShow(showId), 1);
      final loadedEp = dbService.getAllEpisodes().firstWhere((e) => e.id == 30001);
      expect(loadedEp.isWatched, isTrue);
    });

    test('resetAllUserData purges all records and leaves database in absolute zero-state', () async {
      await dbService.init();

      // Populate some test data
      await dbService.upsertShow(ShowModel(id: 1, name: 'Sample Show', isFollowed: true), notify: false);
      await dbService.upsertMovie(MovieModel(id: 1, title: 'Sample Movie', isWatched: true), notify: false);
      await dbService.upsertEpisode(
        EpisodeModel(id: 1, showId: 1, seasonId: 1, seasonNumber: 1, episodeNumber: 1, name: 'Ep 1'),
        notify: false,
      );
      await dbService.insertWatchRecord(WatchRecordModel(
        id: 1,
        showId: 1,
        seasonNumber: 1,
        episodeNumber: 1,
        title: 'Ep 1',
        runtimeMinutes: 45,
        watchedAt: DateTime.now(),
      ));

      expect(dbService.getAllShows(), isNotEmpty);
      expect(dbService.getAllMovies(), isNotEmpty);
      expect(dbService.getAllEpisodes(), isNotEmpty);
      expect(dbService.getAllWatchRecords(), isNotEmpty);

      // Execute full reset
      await dbService.resetAllUserData();

      // Verify memory cache is completely empty
      expect(dbService.getAllShows(), isEmpty);
      expect(dbService.getFollowedShows(), isEmpty);
      expect(dbService.getAllMovies(), isEmpty);
      expect(dbService.getAllEpisodes(), isEmpty);
      expect(dbService.getAllWatchRecords(), isEmpty);
      expect(dbService.getFriends(), isEmpty);

      // Verify SQLite tables are completely empty without re-seeding
      final dbShows = await db.select(db.showsTable).get();
      final dbMovies = await db.select(db.moviesTable).get();
      final dbEpisodes = await db.select(db.episodesTable).get();
      final dbHistory = await db.select(db.episodeWatchHistoryTable).get();

      expect(dbShows, isEmpty);
      expect(dbMovies, isEmpty);
      expect(dbEpisodes, isEmpty);
      expect(dbHistory, isEmpty);
    });

    test('Unauthenticated app reboot preserves offline watch records and does not purge them', () async {
      await dbService.init();

      // User adds watch records in offline / unauthenticated guest mode
      await dbService.upsertShow(ShowModel(id: 10, name: 'Offline Series', isFollowed: true), notify: false);
      await dbService.insertWatchRecord(WatchRecordModel(
        id: 99,
        showId: 10,
        seasonNumber: 1,
        episodeNumber: 1,
        title: 'Episode 1',
        runtimeMinutes: 45,
        watchedAt: DateTime(2024, 3, 1),
      ));

      expect(dbService.getAllWatchRecords().length, 1);

      // Simulate app restart without PocketBase token
      final restartDbService = DatabaseService(db: db);
      await restartDbService.init();

      // Verify that offline watch record was strictly preserved and NOT wiped out
      expect(restartDbService.getAllWatchRecords().length, 1);
      expect(restartDbService.getAllWatchRecords().first.title, 'Episode 1');
      expect(restartDbService.getAllShows().length, 1);
      expect(restartDbService.getAllShows().first.name, 'Offline Series');
    });
  });
}
