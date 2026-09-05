import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/core/constants/app_constants.dart';
import 'package:screenvault/data/migration/tv_time_migrator.dart';
import 'package:screenvault/data/migration/tv_time_exporter.dart';
import 'package:screenvault/data/database/database_service.dart';

void main() {
  group('TV Time Migration and Export Engine Tests', () {
    test('Verifies gdpr-data.zip exists in Screen Vault workspace', () {
      final defaultFile = File(AppConstants.defaultGdprPath);
      final exampleFile = File(AppConstants.exampleGdprPath);

      expect(defaultFile.existsSync() || exampleFile.existsSync(), isTrue,
          reason: 'At least one valid TV Time GDPR backup file must be present');
    });

    test('Imports gdpr-data.zip and streams progress to completion', () async {
      final dbService = DatabaseService();
      final migrator = TvTimeMigrator(dbService: dbService);

      final path = File(AppConstants.defaultGdprPath).existsSync()
          ? AppConstants.defaultGdprPath
          : AppConstants.exampleGdprPath;

      final progressEvents = await migrator.importZipArchive(zipFilePath: path).toList();

      expect(progressEvents.isNotEmpty, isTrue);
      final lastEvent = progressEvents.last;

      expect(lastEvent.isError, isFalse, reason: 'Migration should complete without errors');
      expect(lastEvent.isCompleted, isTrue);
      expect(lastEvent.percentage, 1.0);

      // Verify DB contains imported shows
      final shows = dbService.getFollowedShows();
      expect(shows.isNotEmpty, isTrue);
    });

    test('Exports current state to a valid TV Time gdpr-data.zip archive', () async {
      final dbService = DatabaseService();
      await dbService.init();

      final exporter = TvTimeExporter(dbService: dbService);
      final tempZipPath = '${Directory.systemTemp.path}/test_tv_time_export.zip';

      final exportedFile = await exporter.exportToZip(tempZipPath);
      expect(exportedFile.existsSync(), isTrue);
      expect(exportedFile.lengthSync() > 100, isTrue);

      // Clean up
      if (exportedFile.existsSync()) {
        exportedFile.deleteSync();
      }
    });
  });
}
