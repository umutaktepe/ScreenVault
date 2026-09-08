import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenvault/core/constants/app_constants.dart';
import 'package:screenvault/data/migration/tv_time_migrator.dart';
import 'package:screenvault/data/migration/tv_time_exporter.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/database/app_database.dart';
import 'package:screenvault/data/models/show_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TV Time Migration and Export Engine Tests', () {
    test('Verifies gdpr-data.zip exists in Screen Vault workspace', () {
      final defaultFile = File(AppConstants.defaultGdprPath);
      final exampleFile = File(AppConstants.exampleGdprPath);

      expect(defaultFile.existsSync() || exampleFile.existsSync(), isTrue,
          reason: 'At least one valid TV Time GDPR backup file must be present');
    });

    test('Imports gdpr-data.zip and verifies movie title integrity (no watch-date corruption)', () async {
      final db = AppDatabase.memory();
      final dbService = DatabaseService(db: db);
      final migrator = TvTimeMigrator(dbService: dbService);

      final path = File(AppConstants.defaultGdprPath).existsSync()
          ? AppConstants.defaultGdprPath
          : AppConstants.exampleGdprPath;

      final progressEvents = await migrator.importZipArchive(zipFilePath: path, enableTmdbEnrichment: false).toList();

      expect(progressEvents.isNotEmpty, isTrue);
      final lastEvent = progressEvents.last;

      expect(lastEvent.isError, isFalse, reason: 'Migration should complete without errors: ${lastEvent.errorMessage}');
      expect(lastEvent.isCompleted, isTrue);
      expect(lastEvent.percentage, 1.0);

      // Verify DB contains imported shows
      final shows = dbService.getFollowedShows();
      expect(shows.isNotEmpty, isTrue);

      // Verify movies were correctly parsed and NO movie has a title starting with 'watch-date-'
      final movies = dbService.getAllMovies();
      expect(movies.isNotEmpty, isTrue);
      expect(movies.any((m) => m.title == 'Fury'), isTrue,
          reason: 'Fury must be correctly parsed by its title, not its range key');
      expect(movies.any((m) => m.title.startsWith('watch-date-')), isFalse,
          reason: 'No movie title should be corrupted with watch-date range keys');

      // Verify rewatch count preservation for movies
      final interstellar = movies.firstWhere((m) => m.title == 'Interstellar');
      expect(interstellar.rewatchCount, 5,
          reason: 'Interstellar has 4 rewatches in TV Time so total viewings must be 5');

      final olumluDunya = movies.firstWhere((m) => m.title == 'Ölümlü Dünya');
      expect(olumluDunya.rewatchCount, 3,
          reason: 'Ölümlü Dünya has 2 rewatches in TV Time so total viewings must be 3');

      // Verify user stats rewatch library includes top rewatched items
      final stats = dbService.getUserStats();
      expect(stats.rewatchedShows.isNotEmpty, isTrue,
          reason: 'Rewatched items must be present in user stats');
      expect(stats.rewatchedShows.first.count, greaterThanOrEqualTo(3),
          reason: 'Top rewatched item should have count >= 3');

      await db.close();
    });

    test('Round-trip export and re-import integrity: columns, headers and data match', () async {
      final db = AppDatabase.memory();
      final dbService = DatabaseService(db: db);
      await dbService.init();

      final exporter = TvTimeExporter(dbService: dbService);
      final tempZipPath = '${Directory.systemTemp.path}/test_tv_time_roundtrip_export.zip';

      final exportedFile = await exporter.exportToZip(tempZipPath);
      expect(exportedFile.existsSync(), isTrue);
      expect(exportedFile.lengthSync() > 100, isTrue);

      // Inspect exported archive CSV headers and column counts
      final bytes = exportedFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final followedFile = archive.firstWhere((f) => f.name == 'followed_tv_show.csv');
      final followedLines = const LineSplitter().convert(utf8.decode(followedFile.content as List<int>));
      expect(followedLines.first.split(',').length, 11);

      final trackingV2File = archive.firstWhere((f) => f.name == 'tracking-prod-records-v2.csv');
      final trackingV2Lines = const LineSplitter().convert(utf8.decode(trackingV2File.content as List<int>));
      expect(trackingV2Lines.first.split(',').length, 29);
      // Verify data row column count
      for (int i = 1; i < trackingV2Lines.length; i++) {
        if (trackingV2Lines[i].trim().isEmpty) continue;
        final cols = trackingV2Lines[i].split(',');
        expect(cols.length, 29, reason: 'Row $i in tracking-prod-records-v2 must have exactly 29 columns');
      }

      final moviesFile = archive.firstWhere((f) => f.name == 'tracking-prod-records.csv');
      final moviesLines = const LineSplitter().convert(utf8.decode(moviesFile.content as List<int>));
      expect(moviesLines.first.split(',').length, 22);
      for (int i = 1; i < moviesLines.length; i++) {
        if (moviesLines[i].trim().isEmpty) continue;
        final cols = moviesLines[i].split(',');
        expect(cols.length, 22, reason: 'Row $i in tracking-prod-records must have exactly 22 columns');
      }

      // Re-import exported archive into fresh database
      final freshDb = AppDatabase.memory();
      final freshDbService = DatabaseService(db: freshDb);
      final freshMigrator = TvTimeMigrator(dbService: freshDbService);

      final reimportEvents = await freshMigrator.importZipArchive(zipFilePath: tempZipPath, enableTmdbEnrichment: false).toList();
      expect(reimportEvents.last.isCompleted, isTrue);
      expect(reimportEvents.last.isError, isFalse);

      final importedShows = freshDbService.getFollowedShows();
      expect(importedShows.length, dbService.getFollowedShows().length);

      final importedMovies = freshDbService.getAllMovies();
      expect(importedMovies.length, dbService.getAllMovies().length);

      // Clean up
      if (exportedFile.existsSync()) {
        exportedFile.deleteSync();
      }
      await db.close();
      await freshDb.close();
    });

    test('Imports gdpr-data.zip on an already-seeded database without UNIQUE constraint collisions', () async {
      final db = AppDatabase.memory();
      final dbService = DatabaseService(db: db);
      // With zero-seed architecture, insert a pre-existing show to test migration on an existing database
      await dbService.init();
      await dbService.upsertShow(const ShowModel(
        id: 1,
        tvdbId: 79168,
        name: 'Friends',
      ));

      final friendsBefore = dbService.getShowByTvdbId(79168);
      expect(friendsBefore, isNotNull);
      expect(friendsBefore!.id, 1);

      final migrator = TvTimeMigrator(dbService: dbService);
      final path = File(AppConstants.defaultGdprPath).existsSync()
          ? AppConstants.defaultGdprPath
          : AppConstants.exampleGdprPath;

      final progressEvents = await migrator.importZipArchive(zipFilePath: path, enableTmdbEnrichment: false).toList();
      expect(progressEvents.isNotEmpty, isTrue);
      final lastEvent = progressEvents.last;

      expect(lastEvent.isError, isFalse,
          reason: 'Migration on seeded DB must not crash: ${lastEvent.errorMessage}');
      expect(lastEvent.isCompleted, isTrue);

      // Verify Friends was updated in-place without duplicate
      final friendsAfter = dbService.getShowByTvdbId(79168);
      expect(friendsAfter, isNotNull);
      expect(friendsAfter!.id, 1);

      await db.close();
    });
  });
}
