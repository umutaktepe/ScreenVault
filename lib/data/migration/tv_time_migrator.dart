import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/duration_formatter.dart';
import '../models/show_model.dart';
import '../models/movie_model.dart';
import '../models/watch_record_model.dart';
import '../models/friend_model.dart';
import '../database/database_service.dart';

class MigrationProgress {
  final int current;
  final int total;
  final double percentage;
  final String status;
  final bool isCompleted;
  final bool isError;
  final String? errorMessage;

  const MigrationProgress({
    required this.current,
    required this.total,
    required this.percentage,
    required this.status,
    this.isCompleted = false,
    this.isError = false,
    this.errorMessage,
  });
}

/// TV Time GDPR Archive Migration Engine (Imports /home/umutaktepe/Screen Vault/gdpr-data.zip)
class TvTimeMigrator {
  final DatabaseService _dbService;

  TvTimeMigrator({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  /// Reads and parses gdpr-data.zip and populates the database
  Stream<MigrationProgress> importZipArchive({String? zipFilePath}) async* {
    final path = zipFilePath ??
        (File(AppConstants.defaultGdprPath).existsSync()
            ? AppConstants.defaultGdprPath
            : AppConstants.exampleGdprPath);

    yield const MigrationProgress(
      current: 0,
      total: 100,
      percentage: 0.05,
      status: 'ZIP arşivi okunuyor...',
    );

    final file = File(path);
    if (!file.existsSync()) {
      yield MigrationProgress(
        current: 0,
        total: 100,
        percentage: 0.0,
        status: 'Yedek dosyası bulunamadı!',
        isError: true,
        errorMessage: 'Dosya bulunamadı: $path',
      );
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      yield const MigrationProgress(
        current: 20,
        total: 100,
        percentage: 0.20,
        status: 'CSV verileri taranıyor...',
      );

      // 1. Parse followed_tv_show.csv
      ArchiveFile? followedShowsFile;
      ArchiveFile? trackingV2File;
      ArchiveFile? trackingMoviesFile;
      ArchiveFile? friendsFile;

      for (final archFile in archive) {
        if (archFile.name == 'followed_tv_show.csv') {
          followedShowsFile = archFile;
        } else if (archFile.name == 'tracking-prod-records-v2.csv') {
          trackingV2File = archFile;
        } else if (archFile.name == 'tracking-prod-records.csv') {
          trackingMoviesFile = archFile;
        } else if (archFile.name == 'friend.csv') {
          friendsFile = archFile;
        }
      }

      int totalShowsCount = 0;
      if (followedShowsFile != null) {
        yield const MigrationProgress(
          current: 35,
          total: 100,
          percentage: 0.35,
          status: 'Takip edilen diziler aktarılıyor...',
        );
        final content = utf8.decode(followedShowsFile.content as List<int>, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.length >= 10) {
            final tvShowId = int.tryParse(cols[0]);
            final tvShowName = cols[9];
            final active = cols[1] == '1';

            if (tvShowId != null) {
              totalShowsCount++;
              final show = ShowModel(
                id: tvShowId,
                tvdbId: tvShowId,
                name: tvShowName,
                isFollowed: active,
              );
              await _dbService.upsertShow(show);
            }
          }
        }
      }

      // 2. Parse tracking-prod-records-v2.csv (Episodes Watch Records)
      int totalWatchMinutes = 0;
      int episodesWatched = 0;
      if (trackingV2File != null) {
        yield const MigrationProgress(
          current: 60,
          total: 100,
          percentage: 0.60,
          status: 'İzleme geçmişi ve süreler hesaplanıyor...',
        );
        final content = utf8.decode(trackingV2File.content as List<int>, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.length >= 28) {
            final runtimeSec = int.tryParse(cols[2]) ?? 0;
            final runtimeMin = DurationFormatter.secondsToMinutes(runtimeSec);
            totalWatchMinutes += runtimeMin;
            episodesWatched++;

            final sId = int.tryParse(cols[7]);
            final epNo = int.tryParse(cols[1]) ?? int.tryParse(cols[28]) ?? 0;
            final sNo = int.tryParse(cols[8]) ?? int.tryParse(cols[27]) ?? 0;
            final title = cols[26].isNotEmpty ? cols[26] : 'Show $sId';

            final record = WatchRecordModel(
              id: i,
              sId: sId,
              seasonNumber: sNo,
              episodeNumber: epNo,
              title: title,
              runtimeMinutes: runtimeMin,
              watchedAt: DateTime.tryParse(cols[5]) ?? DateTime.now(),
            );
            _dbService.addWatchRecord(record);
          }
        }
      }

      // 3. Parse tracking-prod-records.csv (Movies)
      int moviesCount = 0;
      if (trackingMoviesFile != null) {
        yield const MigrationProgress(
          current: 85,
          total: 100,
          percentage: 0.85,
          status: 'Filmler ve arkadaş listesi senkronize ediliyor...',
        );
        final content = utf8.decode(trackingMoviesFile.content as List<int>, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.length >= 17) {
            final movieName = cols[17].isNotEmpty ? cols[17] : (cols.length > 18 ? cols[18] : '');
            if (movieName.isNotEmpty) {
              moviesCount++;
              final runtimeSec = int.tryParse(cols[11]) ?? 0;
              final movie = MovieModel(
                id: 1000 + moviesCount,
                title: movieName,
                runtimeMinutes: DurationFormatter.secondsToMinutes(runtimeSec),
                isWatched: true,
                isFollowed: true,
              );
              await _dbService.upsertMovie(movie);
            }
          }
        }
      }

      // 4. Parse friend.csv
      if (friendsFile != null) {
        final content = utf8.decode(friendsFile.content as List<int>, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.isNotEmpty) {
            final friendId = cols[0];
            final affinity = cols.length > 3 ? (double.tryParse(cols[3]) ?? 0.0) : 0.0;
            _dbService.getFriends().add(
                  FriendModel(
                    friendId: friendId,
                    name: 'TV Time Arkadaşı $friendId',
                    affinity: affinity,
                  ),
                );
          }
        }
      }

      yield MigrationProgress(
        current: 100,
        total: 100,
        percentage: 1.0,
        status: 'Başarılı! $totalShowsCount dizi, $episodesWatched bölüm ($totalWatchMinutes dk) ve $moviesCount film aktarıldı.',
        isCompleted: true,
      );
    } catch (e) {
      yield MigrationProgress(
        current: 0,
        total: 100,
        percentage: 0.0,
        status: 'İçe aktarma hatası: $e',
        isError: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// Simple and robust CSV line splitter handling quoted strings
  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString().trim());
    return result;
  }
}
