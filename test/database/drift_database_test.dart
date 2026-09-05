import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift SQLite AppDatabase Tests', () {
    test('Verifies table creation and CRUD operations on ShowsTable', () async {
      final showCompanion = ShowsTableCompanion.insert(
        id: const Value(1),
        name: 'Friends',
        tvdbId: const Value(79168),
        tmdbId: const Value(1668),
        isFollowed: const Value(true),
        totalSeasons: const Value(10),
        totalEpisodes: const Value(236),
      );

      await db.into(db.showsTable).insert(showCompanion);

      final allShows = await db.select(db.showsTable).get();
      expect(allShows.length, 1);
      expect(allShows.first.name, 'Friends');
      expect(allShows.first.tvdbId, 79168);
      expect(allShows.first.isFollowed, true);
    });

    test('Verifies CRUD operations on EpisodesTable and EpisodeWatchHistoryTable', () async {
      await db.into(db.showsTable).insert(
        ShowsTableCompanion.insert(
          id: const Value(2),
          name: 'Behzat Ç.',
          tvdbId: const Value(235881),
        ),
      );

      await db.into(db.episodesTable).insert(
        EpisodesTableCompanion.insert(
          id: const Value(201),
          showId: 2,
          seasonId: 1,
          seasonNumber: 1,
          episodeNumber: 36,
          name: '36. Bölüm',
          runtimeMinutes: const Value(84),
        ),
      );

      final episodes = await db.select(db.episodesTable).get();
      expect(episodes.length, 1);
      expect(episodes.first.name, '36. Bölüm');
      expect(episodes.first.runtimeMinutes, 84);

      // Insert watch history record
      await db.into(db.episodeWatchHistoryTable).insert(
        EpisodeWatchHistoryTableCompanion.insert(
          title: '36. Bölüm',
          watchedAt: DateTime(2024, 6, 26),
          episodeId: const Value(201),
          showId: const Value(2),
          runtimeMinutes: const Value(84),
        ),
      );

      final history = await db.select(db.episodeWatchHistoryTable).get();
      expect(history.length, 1);
      expect(history.first.title, '36. Bölüm');
    });

    test('Verifies MoviesTable and ImportQueueTable', () async {
      await db.into(db.moviesTable).insert(
        MoviesTableCompanion.insert(
          id: const Value(1001),
          title: 'Fury',
          tmdbId: const Value(228150),
          runtimeMinutes: const Value(134),
          isWatched: const Value(true),
        ),
      );

      final movies = await db.select(db.moviesTable).get();
      expect(movies.length, 1);
      expect(movies.first.title, 'Fury');

      // Test ImportQueueTable
      await db.into(db.importQueueTable).insert(
        ImportQueueTableCompanion.insert(
          mediaType: 'tv',
          createdAt: DateTime.now(),
          tvdbId: const Value(79168),
          status: const Value('completed'),
        ),
      );

      final queue = await db.select(db.importQueueTable).get();
      expect(queue.length, 1);
      expect(queue.first.status, 'completed');
    });
  });
}
