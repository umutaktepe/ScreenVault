import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/core/theme/obsidian_theme.dart';
import 'package:screenvault/presentation/screens/profile/widgets/import_reconciliation_sheet.dart';
import 'package:screenvault/data/database/app_database.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/data/models/watch_record_model.dart';
import 'package:screenvault/data/models/unresolved_item_model.dart';
import 'package:screenvault/data/tmdb/title_sanitizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DatabaseService dbService;

  setUp(() {
    db = AppDatabase.memory();
    dbService = DatabaseService(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Reconciliation Engine & Unresolved Items Tests', () {
    test('Verifies UnresolvedItemModel serialization and copyWith', () {
      final item = UnresolvedItemModel(
        id: 349078,
        type: UnresolvedItemType.show,
        rawTitle: 'Show 349078',
        tvdbId: 349078,
        watchedEpisodesCount: 22,
        runtimeMinutes: 924,
        seasonsInfo: 'S1: 13 bölüm, S2: 9 bölüm',
      );

      expect(item.id, 349078);
      expect(item.type, UnresolvedItemType.show);
      expect(item.watchedEpisodesCount, 22);

      final map = item.toMap();
      expect(map['type'], 'show');
      expect(map['rawTitle'], 'Show 349078');

      final reconstructed = UnresolvedItemModel.fromMap(map);
      expect(reconstructed, equals(item));

      final updated = item.copyWith(rawTitle: 'Prison Break');
      expect(updated.rawTitle, 'Prison Break');
      expect(updated.id, item.id);
    });

    test('Resolves an unmatched TV show and preserves watch history', () async {
      // 1. Insert a placeholder show with generic TV Time name
      final unresolvedShow = ShowModel(
        id: 349078,
        tvdbId: 349078,
        name: 'Show 349078',
        isFollowed: true,
        watchedEpisodesCount: 2,
      );
      await dbService.upsertShow(unresolvedShow);

      // 2. Add watch records for this show
      final record1 = WatchRecordModel(
        id: 1,
        showId: 349078,
        tvdbId: 349078,
        seasonNumber: 1,
        episodeNumber: 1,
        title: 'Show 349078',
        runtimeMinutes: 45,
        watchedAt: DateTime(2023, 1, 1),
      );
      final record2 = WatchRecordModel(
        id: 2,
        showId: 349078,
        tvdbId: 349078,
        seasonNumber: 1,
        episodeNumber: 2,
        title: 'Show 349078',
        runtimeMinutes: 45,
        watchedAt: DateTime(2023, 1, 2),
      );
      await dbService.addWatchRecordsBatch([record1, record2]);

      final unresolvedItem = UnresolvedItemModel(
        id: 349078,
        type: UnresolvedItemType.show,
        rawTitle: 'Show 349078',
        tvdbId: 349078,
        watchedEpisodesCount: 2,
        seasonsInfo: 'S1: 2 bölüm',
      );
      dbService.setUnresolvedItems([unresolvedItem]);
      expect(dbService.getUnresolvedItems().length, 1);

      // 3. User selects TMDB match
      final matchedTmdb = ShowModel(
        id: 2288,
        tmdbId: 2288,
        name: 'Prison Break',
        posterPath: '/prison_break_poster.jpg',
        backdropPath: '/prison_break_backdrop.jpg',
        overview: 'An innocent man is sent to death row.',
        totalSeasons: 5,
        totalEpisodes: 90,
      );

      await dbService.resolveUnmatchedItem(unresolvedItem, matchedTmdb);

      // 4. Verify show metadata updated
      final resolved = dbService.getShowById(349078);
      expect(resolved, isNotNull);
      expect(resolved!.name, 'Prison Break');
      expect(resolved.tmdbId, 2288);
      expect(resolved.posterPath, '/prison_break_poster.jpg');

      // Verify watch records updated
      final records = dbService.getWatchRecordsForShow(349078);
      expect(records.length, 2);
      expect(records.first.title, 'Prison Break');

      // Verify unresolved queue cleared
      expect(dbService.getUnresolvedItems(), isEmpty);
    });

    test('Discards an unmatched TV show and purges associated records', () async {
      final show = ShowModel(
        id: 99999,
        tvdbId: 99999,
        name: 'Show 99999',
        isFollowed: true,
      );
      await dbService.upsertShow(show);

      final record = WatchRecordModel(
        id: 50,
        showId: 99999,
        tvdbId: 99999,
        seasonNumber: 1,
        episodeNumber: 1,
        title: 'Show 99999',
        runtimeMinutes: 40,
        watchedAt: DateTime.now(),
      );
      await dbService.addWatchRecordsBatch([record]);

      final unresolvedItem = UnresolvedItemModel(
        id: 99999,
        type: UnresolvedItemType.show,
        rawTitle: 'Show 99999',
        tvdbId: 99999,
      );
      dbService.setUnresolvedItems([unresolvedItem]);

      // Discard item
      await dbService.discardUnmatchedItem(unresolvedItem);

      expect(dbService.getShowById(99999), isNull);
      expect(dbService.getWatchRecordsForShow(99999), isEmpty);
      expect(dbService.getUnresolvedItems(), isEmpty);
    });

    test('Resolves and discards an unmatched Movie', () async {
      final movie = MovieModel(
        id: 2001,
        title: 'Unknown Indie Film',
        runtimeMinutes: 90,
        isWatched: true,
      );
      await dbService.upsertMovie(movie);

      final unresolvedMovie = UnresolvedItemModel(
        id: 2001,
        type: UnresolvedItemType.movie,
        rawTitle: 'Unknown Indie Film',
        runtimeMinutes: 90,
      );
      dbService.setUnresolvedItems([unresolvedMovie]);

      final matchedMovie = MovieModel(
        id: 550,
        tmdbId: 550,
        title: 'Fight Club',
        posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        runtimeMinutes: 139,
      );

      await dbService.resolveUnmatchedItem(unresolvedMovie, matchedMovie);

      final resolved = dbService.getAllMovies().firstWhere((m) => m.id == 2001);
      expect(resolved.title, 'Fight Club');
      expect(resolved.tmdbId, 550);
      expect(resolved.posterPath, '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg');
      expect(dbService.getUnresolvedItems(), isEmpty);

      // Now discard it
      final toDiscard = UnresolvedItemModel(
        id: 2001,
        type: UnresolvedItemType.movie,
        rawTitle: 'Fight Club',
      );
      await dbService.discardUnmatchedItem(toDiscard);
      expect(dbService.getAllMovies().where((m) => m.id == 2001), isEmpty);
    });

    test('Gracefully handles cross-model matching (Show resolved with MovieModel or Map)', () async {
      final unresolvedShow = ShowModel(
        id: 349079,
        tvdbId: 349079,
        name: 'Show 349079',
        isFollowed: true,
      );
      await dbService.upsertShow(unresolvedShow);

      final unresolvedItem = UnresolvedItemModel(
        id: 349079,
        type: UnresolvedItemType.show,
        rawTitle: 'Show 349079',
        tvdbId: 349079,
      );
      dbService.setUnresolvedItems([unresolvedItem]);

      // Cross-match with a MovieModel (or JSON map) - should NOT throw type cast exception
      final crossMatch = MovieModel(
        id: 999,
        tmdbId: 999,
        title: 'Band of Brothers',
        posterPath: '/bob.jpg',
        overview: 'Mini-series treated as movie on TMDB search',
      );

      await dbService.resolveUnmatchedItem(unresolvedItem, crossMatch);

      final resolved = dbService.getShowById(349079);
      expect(resolved, isNotNull);
      expect(resolved!.name, 'Band of Brothers');
      expect(resolved.tmdbId, 999);
      expect(resolved.posterPath, '/bob.jpg');
      expect(dbService.getUnresolvedItems(), isEmpty);
    });

    test('Extracts clean title and target year using TitleSanitizer in reconciliation context', () {
      final itemWithYear = UnresolvedItemModel(
        id: 76543,
        type: UnresolvedItemType.show,
        rawTitle: 'Lost in Space (2018)',
      );

      final parsed = TitleSanitizer.parseTitleAndYear(itemWithYear.rawTitle);
      expect(parsed.cleanTitle, 'Lost in Space');
      expect(parsed.extractedYear, 2018);

      final targetYear = parsed.extractedYear ?? itemWithYear.releaseYear;
      expect(targetYear, 2018);

      // Verify tolerance matching: ±1 year
      expect(TitleSanitizer.isWithinYearTolerance(2018, targetYear), isTrue);
      expect(TitleSanitizer.isWithinYearTolerance(2017, targetYear), isTrue);
      expect(TitleSanitizer.isWithinYearTolerance(2019, targetYear), isTrue);
      expect(TitleSanitizer.isWithinYearTolerance(1965, targetYear), isFalse);
      expect(TitleSanitizer.isWithinYearTolerance(null, targetYear), isFalse);
    });

    test('Resolves an unresolved item with year in title and preserves watch records', () async {
      final show = ShowModel(
        id: 88888,
        tvdbId: 88888,
        name: 'Lost in Space (2018)',
        isFollowed: true,
      );
      await dbService.upsertShow(show);

      final record = WatchRecordModel(
        id: 101,
        showId: 88888,
        tvdbId: 88888,
        seasonNumber: 1,
        episodeNumber: 1,
        title: 'Lost in Space (2018)',
        runtimeMinutes: 50,
        watchedAt: DateTime.now(),
      );
      await dbService.addWatchRecordsBatch([record]);

      final unresolved = UnresolvedItemModel(
        id: 88888,
        type: UnresolvedItemType.show,
        rawTitle: 'Lost in Space (2018)',
        tvdbId: 88888,
      );
      dbService.setUnresolvedItems([unresolved]);

      final parsed = TitleSanitizer.parseTitleAndYear(unresolved.rawTitle);
      expect(parsed.cleanTitle, 'Lost in Space');

      final matched = ShowModel(
        id: 75758,
        tmdbId: 75758,
        name: parsed.cleanTitle,
        posterPath: '/lost_in_space_2018.jpg',
        firstAirDate: DateTime(2018, 4, 13),
      );

      await dbService.resolveUnmatchedItem(unresolved, matched);

      final resolved = dbService.getShowById(88888);
      expect(resolved, isNotNull);
      expect(resolved!.name, 'Lost in Space');
      expect(resolved.tmdbId, 75758);
      expect(resolved.posterPath, '/lost_in_space_2018.jpg');

      final records = dbService.getWatchRecordsForShow(88888);
      expect(records.first.title, 'Lost in Space');
      expect(dbService.getUnresolvedItems(), isEmpty);
    });

    test('Safely creates and resolves show when no prior row existed in database', () async {
      final unresolved = UnresolvedItemModel(
        id: 77777,
        type: UnresolvedItemType.show,
        rawTitle: 'Completely New Show (2021)',
        tvdbId: 77777,
      );
      dbService.setUnresolvedItems([unresolved]);

      final matched = ShowModel(
        id: 99999,
        tmdbId: 99999,
        name: 'Completely New Show',
        posterPath: '/new_poster.jpg',
      );

      // Should not throw or discard silently; should create and resolve
      await dbService.resolveUnmatchedItem(unresolved, matched);

      final resolved = dbService.getShowById(77777);
      expect(resolved, isNotNull);
      expect(resolved!.name, 'Completely New Show');
      expect(resolved.tmdbId, 99999);
      expect(dbService.getUnresolvedItems(), isEmpty);
    });

    test('Safely creates and resolves movie when no prior row existed in database', () async {
      final unresolved = UnresolvedItemModel(
        id: 44444,
        type: UnresolvedItemType.movie,
        rawTitle: 'Brand New Movie (2023)',
      );
      dbService.setUnresolvedItems([unresolved]);

      final matched = MovieModel(
        id: 8888,
        tmdbId: 8888,
        title: 'Brand New Movie',
        posterPath: '/movie_poster.jpg',
      );

      await dbService.resolveUnmatchedItem(unresolved, matched);

      final resolved = dbService.getAllMovies().firstWhere((m) => m.id == 44444);
      expect(resolved.title, 'Brand New Movie');
      expect(resolved.tmdbId, 8888);
      expect(dbService.getUnresolvedItems(), isEmpty);
    });

    test('TitleSanitizer accurately handles exotic titles and spacing edge cases', () {
      // Brackets with spaces inside
      final res1 = TitleSanitizer.parseTitleAndYear('Lost in Space ( 2018 )');
      expect(res1.cleanTitle, 'Lost in Space');
      expect(res1.extractedYear, 2018);

      // Square brackets
      final res2 = TitleSanitizer.parseTitleAndYear('Dark [2017]');
      expect(res2.cleanTitle, 'Dark');
      expect(res2.extractedYear, 2017);

      // Non-year trailing numbers
      final res3 = TitleSanitizer.parseTitleAndYear('Blade Runner 2049');
      expect(res3.cleanTitle, 'Blade Runner 2049');
      expect(res3.extractedYear, isNull);

      // Leading year numbers
      final res4 = TitleSanitizer.parseTitleAndYear('2001: A Space Odyssey');
      expect(res4.cleanTitle, '2001: A Space Odyssey');
      expect(res4.extractedYear, isNull);

      // Parenthesis with only year
      final res5 = TitleSanitizer.parseTitleAndYear('(2020)');
      expect(res5.cleanTitle, '(2020)');
      expect(res5.extractedYear, isNull);

      // Empty string
      final res6 = TitleSanitizer.parseTitleAndYear('   ');
      expect(res6.cleanTitle, '');
      expect(res6.extractedYear, isNull);
    });

    testWidgets('ImportReconciliationSheet displays clean title and target year badge', (tester) async {
      final items = [
        UnresolvedItemModel(
          id: 54321,
          type: UnresolvedItemType.show,
          rawTitle: 'Lost in Space (2018)',
          watchedEpisodesCount: 15,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: Scaffold(
            body: ImportReconciliationSheet(items: items),
          ),
        ),
      );
      await tester.pump();

      // Verify header and badge
      expect(find.text('İÇERİK EŞLEŞTİRME'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.text('Hedef: 2018 (±1 Yıl: 2017 - 2019)'), findsOneWidget);

      // Verify search input prefilled with clean title
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Lost in Space');

      // Flush any pending network/debounce timers before test exit
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('ImportReconciliationSheet does not auto-search placeholder titles', (tester) async {
      final items = [
        UnresolvedItemModel(
          id: 99911,
          type: UnresolvedItemType.show,
          rawTitle: 'Show 99911',
          watchedEpisodesCount: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: Scaffold(
            body: ImportReconciliationSheet(items: items),
          ),
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('Hedef:'), findsNothing);
    });
  });
}
