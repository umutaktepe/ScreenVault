import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:archive/archive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/duration_formatter.dart';
import '../models/show_model.dart';
import '../models/movie_model.dart';
import '../models/watch_record_model.dart';
import '../models/friend_model.dart';
import '../models/unresolved_item_model.dart';
import '../database/database_service.dart';
import '../tmdb/tmdb_service.dart';

class MigrationProgress {
  final int current;
  final int total;
  final double percentage;
  final String status;
  final bool isCompleted;
  final bool isError;
  final String? errorMessage;
  final List<UnresolvedItemModel> unresolvedItems;

  const MigrationProgress({
    required this.current,
    required this.total,
    required this.percentage,
    required this.status,
    this.isCompleted = false,
    this.isError = false,
    this.errorMessage,
    this.unresolvedItems = const [],
  });
}

/// TV Time GDPR Archive Migration Engine with concurrent TMDB enrichment,
/// rate-limit protection, and unresolved items detection.
class TvTimeMigrator {
  final DatabaseService _dbService;
  final TmdbService _tmdbService;

  TvTimeMigrator({DatabaseService? dbService, TmdbService? tmdbService})
      : _dbService = dbService ?? DatabaseService(),
        _tmdbService = tmdbService ?? TmdbService();

  /// Reads and parses gdpr-data.zip and populates the database with concurrent TMDB enrichment
  Stream<MigrationProgress> importZipArchive({
    String? zipFilePath,
    List<int>? zipBytes,
    bool enableTmdbEnrichment = true,
  }) {
    final controller = StreamController<MigrationProgress>();

    _runImport(
      controller,
      zipFilePath: zipFilePath,
      zipBytes: zipBytes,
      enableTmdbEnrichment: enableTmdbEnrichment,
    );

    return controller.stream;
  }

  Future<void> _runImport(
    StreamController<MigrationProgress> controller, {
    String? zipFilePath,
    List<int>? zipBytes,
    required bool enableTmdbEnrichment,
  }) async {
    int lastCurrent = 0;
    int lastTotal = 100;
    double lastPercentage = 0.05;
    String lastStatus = 'ZIP arşivi okunuyor...';
    List<UnresolvedItemModel> currentUnresolved = [];

    void emit(
      int current,
      int total,
      double percentage,
      String status, {
      bool isCompleted = false,
      bool isError = false,
      String? errorMessage,
    }) {
      lastCurrent = current;
      lastTotal = total;
      lastPercentage = percentage;
      lastStatus = status;

      if (!controller.isClosed) {
        controller.add(MigrationProgress(
          current: current,
          total: total,
          percentage: percentage,
          status: status,
          isCompleted: isCompleted,
          isError: isError,
          errorMessage: errorMessage,
          unresolvedItems: currentUnresolved,
        ));
      }
    }

    emit(0, 100, 0.05, 'ZIP arşivi okunuyor...');

    List<int> bytes;
    if (zipBytes != null && zipBytes.isNotEmpty) {
      bytes = zipBytes;
    } else {
      final path = zipFilePath ??
          (File(AppConstants.defaultGdprPath).existsSync()
              ? AppConstants.defaultGdprPath
              : AppConstants.exampleGdprPath);

      final file = File(path);
      if (!file.existsSync()) {
        emit(0, 100, 0.0, 'Yedek dosyası bulunamadı!', isError: true, errorMessage: 'Dosya bulunamadı: $path');
        await controller.close();
        return;
      }

      try {
        bytes = await file.readAsBytes();
      } catch (e) {
        emit(0, 100, 0.0, 'Dosya okunamadı!', isError: true, errorMessage: 'Dosya okuma hatası: $e');
        await controller.close();
        return;
      }
    }

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      emit(10, 100, 0.10, 'Yedek dosyaları taranıyor ve kütüphane hazırlanıyor...');

      ArchiveFile? followedShowsFile;
      ArchiveFile? userTvShowDataFile;
      ArchiveFile? trackingV2File;
      ArchiveFile? trackingMoviesFile;
      ArchiveFile? friendsFile;

      for (final archFile in archive) {
        if (archFile.name == 'followed_tv_show.csv') {
          followedShowsFile = archFile;
        } else if (archFile.name == 'user_tv_show_data.csv') {
          userTvShowDataFile = archFile;
        } else if (archFile.name == 'tracking-prod-records-v2.csv') {
          trackingV2File = archFile;
        } else if (archFile.name == 'tracking-prod-records.csv') {
          trackingMoviesFile = archFile;
        } else if (archFile.name == 'friend.csv') {
          friendsFile = archFile;
        }
      }

      // --- 1. Parse TV Shows CSVs ---
      final Map<int, _TvTimeShowData> rawShows = {};
      if (followedShowsFile != null) {
        final content = utf8.decode(followedShowsFile.content as List<int>, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.length >= 10) {
            final tvShowId = int.tryParse(cols[0]);
            final tvShowName = cols[9].trim();
            final active = cols[1] == '1';

            if (tvShowId != null) {
              final entry = rawShows.putIfAbsent(
                tvShowId,
                () => _TvTimeShowData(tvdbId: tvShowId, name: tvShowName, isFollowed: active),
              );
              if (tvShowName.isNotEmpty && (entry.name.isEmpty || entry.name.startsWith('Show '))) {
                entry.name = tvShowName;
              }
              entry.isFollowed = entry.isFollowed || active;
            }
          }
        }
      }

      if (userTvShowDataFile != null) {
        final content = utf8.decode(userTvShowDataFile.content as List<int>, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.length >= 5) {
            final tvShowId = int.tryParse(cols[3]);
            final tvShowName = cols[1].trim();
            final active = cols[4] == '1';
            final seenCount = int.tryParse(cols[0]) ?? 0;

            if (tvShowId != null) {
              final entry = rawShows.putIfAbsent(
                tvShowId,
                () => _TvTimeShowData(
                  tvdbId: tvShowId,
                  name: tvShowName,
                  isFollowed: active,
                  watchedEpisodesCount: seenCount,
                ),
              );
              if (tvShowName.isNotEmpty && (entry.name.isEmpty || entry.name.startsWith('Show '))) {
                entry.name = tvShowName;
              }
              entry.isFollowed = entry.isFollowed || active;
              if (seenCount > entry.watchedEpisodesCount) {
                entry.watchedEpisodesCount = seenCount;
              }
            }
          }
        }
      }

      // --- 2. Parse Movies CSV ---
      final Map<String, _TvTimeMovieData> rawMovies = {};
      if (trackingMoviesFile != null) {
        final content = utf8.decode(trackingMoviesFile.content as List<int>, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.length >= 19 && (cols.length <= 9 || cols[9] == 'movie' || cols[9].isEmpty)) {
            final movieName = cols[18].trim().isNotEmpty
                ? cols[18].trim()
                : (cols.length > 19 ? cols[19].trim() : '');

            if (movieName.isEmpty) continue;
            if (movieName.startsWith('watch-date-') || movieName.startsWith('release-date-')) continue;

            final entry = rawMovies.putIfAbsent(movieName, () => _TvTimeMovieData(name: movieName));

            final sec = int.tryParse(cols[11]) ?? 0;
            if (sec > entry.runtimeSec) entry.runtimeSec = sec;

            final dt = DateTime.tryParse(cols[4]) ?? DateTime.tryParse(cols[10]);
            if (dt != null) {
              if (entry.latestWatchedAt == null || dt.isAfter(entry.latestWatchedAt!)) {
                entry.latestWatchedAt = dt;
              }
            }

            final rel = DateTime.tryParse(cols[10]);
            if (rel != null && (entry.releaseDate == null || rel.isBefore(entry.releaseDate!))) {
              entry.releaseDate = rel;
            }

            if (cols.length > 14 && cols[14].isNotEmpty) {
              final rwVal = int.tryParse(cols[14]) ?? 0;
              if (rwVal > entry.maxRwCol) entry.maxRwCol = rwVal;
            }

            if (cols.length > 3) {
              final key = cols[3];
              if (key.startsWith('rewatch-')) {
                final lastPart = key.split('-').last;
                final sVal = int.tryParse(lastPart) ?? 0;
                if (sVal > entry.maxSuffix) entry.maxSuffix = sVal;
              }
            }

            if (cols.length > 13 && cols[13] == 'rewatch') {
              entry.rewatchTypeRows++;
            }
          }
        }
      }

      // Track rate-limiting events from TMDB client to display cinematic waiting message immediately
      _tmdbService.client.onRateLimitStateChanged = (paused, remaining) {
        if (paused) {
          if (!controller.isClosed) {
            controller.add(MigrationProgress(
              current: lastCurrent,
              total: lastTotal,
              percentage: lastPercentage,
              status: 'Afişler ve sinematik detaylar hazırlanıyor, lütfen bekleyin...',
              unresolvedItems: currentUnresolved,
            ));
          }
        } else {
          if (!controller.isClosed) {
            controller.add(MigrationProgress(
              current: lastCurrent,
              total: lastTotal,
              percentage: lastPercentage,
              status: lastStatus,
              unresolvedItems: currentUnresolved,
            ));
          }
        }
      };

      // --- Stage 2: Shows Import & TMDB Enrichment (%15 - %45) ---
      final showEntries = rawShows.values.toList();
      final int totalShows = showEntries.length;
      int processedShows = 0;
      const int showChunkSize = 8;

      for (int i = 0; i < totalShows; i += showChunkSize) {
        final end = math.min(i + showChunkSize, totalShows);
        final chunk = showEntries.sublist(i, end);

        if (enableTmdbEnrichment) {
          await Future.wait(chunk.map((showData) async {
            ShowModel? tmdbShow;
            if (showData.tvdbId > 0) {
              try {
                tmdbShow = await _tmdbService.findTvShowByTvdbId(showData.tvdbId);
              } catch (_) {}
            }
            if (tmdbShow == null && showData.name.isNotEmpty && !showData.name.startsWith('Show ')) {
              try {
                tmdbShow = await _tmdbService.searchTvShowWithFallback(showData.name);
              } catch (_) {}
            }

            final existing = _dbService.getShowByTvdbId(showData.tvdbId) ??
                _dbService.getShowById(showData.tvdbId) ??
                (showData.name.isNotEmpty ? _dbService.getShowByName(showData.name) : null);

            final displayName = (tmdbShow != null && tmdbShow.name.isNotEmpty)
                ? tmdbShow.name
                : (existing != null && existing.name.isNotEmpty && !existing.name.startsWith('Show ')
                    ? existing.name
                    : (showData.name.isNotEmpty ? showData.name : 'Show ${showData.tvdbId}'));

            final showModel = ShowModel(
              id: existing?.id ?? showData.tvdbId,
              tvdbId: showData.tvdbId,
              tmdbId: tmdbShow?.tmdbId ?? existing?.tmdbId,
              name: displayName,
              originalName: tmdbShow?.originalName ?? existing?.originalName,
              overview: tmdbShow?.overview ?? existing?.overview,
              posterPath: tmdbShow?.posterPath ?? existing?.posterPath,
              backdropPath: tmdbShow?.backdropPath ?? existing?.backdropPath,
              status: tmdbShow?.status ?? existing?.status,
              totalSeasons: (tmdbShow?.totalSeasons ?? 0) > 0 ? tmdbShow!.totalSeasons : (existing?.totalSeasons ?? 0),
              totalEpisodes: (tmdbShow?.totalEpisodes ?? 0) > 0 ? tmdbShow!.totalEpisodes : (existing?.totalEpisodes ?? 0),
              genres: (tmdbShow?.genres.isNotEmpty == true) ? tmdbShow!.genres : (existing?.genres ?? []),
              voteAverage: (tmdbShow?.voteAverage ?? 0) > 0 ? tmdbShow!.voteAverage : (existing?.voteAverage ?? 0.0),
              firstAirDate: tmdbShow?.firstAirDate ?? existing?.firstAirDate,
              isFollowed: showData.isFollowed || (existing?.isFollowed ?? false),
              watchedEpisodesCount: showData.watchedEpisodesCount > (existing?.watchedEpisodesCount ?? 0)
                  ? showData.watchedEpisodesCount
                  : (existing?.watchedEpisodesCount ?? 0),
            );

            await _dbService.upsertShow(showModel, notify: false);
          }));
        } else {
          for (final showData in chunk) {
            final existing = _dbService.getShowByTvdbId(showData.tvdbId) ??
                _dbService.getShowById(showData.tvdbId) ??
                (showData.name.isNotEmpty ? _dbService.getShowByName(showData.name) : null);

            final displayName = existing != null && existing.name.isNotEmpty && !existing.name.startsWith('Show ')
                ? existing.name
                : (showData.name.isNotEmpty ? showData.name : 'Show ${showData.tvdbId}');

            final showModel = ShowModel(
              id: existing?.id ?? showData.tvdbId,
              tvdbId: showData.tvdbId,
              tmdbId: existing?.tmdbId,
              name: displayName,
              originalName: existing?.originalName,
              overview: existing?.overview,
              posterPath: existing?.posterPath,
              backdropPath: existing?.backdropPath,
              status: existing?.status,
              totalSeasons: existing?.totalSeasons ?? 0,
              totalEpisodes: existing?.totalEpisodes ?? 0,
              genres: existing?.genres ?? [],
              voteAverage: existing?.voteAverage ?? 0.0,
              firstAirDate: existing?.firstAirDate,
              isFollowed: showData.isFollowed || (existing?.isFollowed ?? false),
              watchedEpisodesCount: showData.watchedEpisodesCount > (existing?.watchedEpisodesCount ?? 0)
                  ? showData.watchedEpisodesCount
                  : (existing?.watchedEpisodesCount ?? 0),
            );

            await _dbService.upsertShow(showModel, notify: false);
          }
        }

        processedShows = end;
        final pct = totalShows > 0 ? 0.15 + (0.30 * (processedShows / totalShows)) : 0.45;
        emit(
          processedShows,
          totalShows,
          pct,
          'Diziler taranıyor ve afişler yükleniyor (Dizi $processedShows / $totalShows)...',
        );
      }

      // --- Stage 3: Movies Import & TMDB Enrichment (%45 - %85) ---
      final movieEntries = rawMovies.values.toList();
      final int totalMovies = movieEntries.length;
      int processedMovies = 0;
      const int movieChunkSize = 10;

      for (int i = 0; i < totalMovies; i += movieChunkSize) {
        final end = math.min(i + movieChunkSize, totalMovies);
        final chunk = movieEntries.sublist(i, end);

        if (enableTmdbEnrichment) {
          await Future.wait(chunk.asMap().entries.map((entry) async {
            final idx = i + entry.key;
            final movieData = entry.value;

            MovieModel? tmdbMovie;
            try {
              tmdbMovie = await _tmdbService.searchMovieWithFallback(movieData.name, targetYear: movieData.releaseDate?.year);
            } catch (_) {}

            final movieModel = MovieModel(
              id: 1000 + idx + 1,
              tmdbId: tmdbMovie?.tmdbId,
              title: (tmdbMovie != null && tmdbMovie.title.isNotEmpty) ? tmdbMovie.title : movieData.name,
              overview: tmdbMovie?.overview,
              posterPath: tmdbMovie?.posterPath,
              backdropPath: tmdbMovie?.backdropPath,
              runtimeMinutes: (tmdbMovie != null && tmdbMovie.runtimeMinutes > 0)
                  ? tmdbMovie.runtimeMinutes
                  : DurationFormatter.secondsToMinutes(movieData.runtimeSec),
              genres: tmdbMovie?.genres ?? [],
              isWatched: true,
              isFollowed: true,
              watchedAt: movieData.latestWatchedAt ?? movieData.releaseDate,
              releaseDate: tmdbMovie?.releaseDate ?? movieData.releaseDate,
              rewatchCount: movieData.totalViews,
              voteAverage: tmdbMovie?.voteAverage ?? 0.0,
            );

            await _dbService.upsertMovie(movieModel, notify: false);
          }));
        } else {
          for (final entry in chunk.asMap().entries) {
            final idx = i + entry.key;
            final movieData = entry.value;

            final movieModel = MovieModel(
              id: 1000 + idx + 1,
              title: movieData.name,
              runtimeMinutes: DurationFormatter.secondsToMinutes(movieData.runtimeSec),
              isWatched: true,
              isFollowed: true,
              watchedAt: movieData.latestWatchedAt ?? movieData.releaseDate,
              releaseDate: movieData.releaseDate,
              rewatchCount: movieData.totalViews,
            );

            await _dbService.upsertMovie(movieModel, notify: false);
          }
        }

        processedMovies = end;
        final pct = totalMovies > 0 ? 0.45 + (0.40 * (processedMovies / totalMovies)) : 0.85;
        emit(
          processedMovies,
          totalMovies,
          pct,
          'Filmler taranıyor ve afişler yükleniyor (Film $processedMovies / $totalMovies)...',
        );
      }

      // --- Stage 4: Watch Records & Episodes (%85 - %95) ---
      int totalWatchMinutes = 0;
      int episodesWatched = 0;
      if (trackingV2File != null) {
        emit(85, 100, 0.85, 'İzleme geçmişi ve süreler senkronize ediliyor...');

        final content = utf8.decode(trackingV2File.content as List<int>, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        final List<_RawEpisodeRow> rawRows = [];
        final Map<String, List<_RawEpisodeRow>> epRowsMap = {};

        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.length >= 28) {
            final runtimeSec = int.tryParse(cols[2]) ?? 0;
            final runtimeMin = DurationFormatter.secondsToMinutes(runtimeSec);
            totalWatchMinutes += runtimeMin;

            final sId = int.tryParse(cols[7]);
            final epNo = int.tryParse(cols[1]) ?? (cols.length > 28 ? int.tryParse(cols[28]) : null) ?? 0;
            final sNo = int.tryParse(cols[8]) ?? int.tryParse(cols[27]) ?? 0;
            final title = cols.length > 26 && cols[26].isNotEmpty ? cols[26] : 'Show $sId';
            final watchedAt = DateTime.tryParse(cols[5]) ?? DateTime.now();
            final key = cols.length > 9 ? cols[9] : '';
            final rewatchCol = cols.length > 23 ? (int.tryParse(cols[23]) ?? 0) : 0;

            final rawRow = _RawEpisodeRow(
              index: i,
              sId: sId,
              epNo: epNo,
              sNo: sNo,
              title: title,
              runtimeMin: runtimeMin,
              watchedAt: watchedAt,
              key: key,
              rewatchCol: rewatchCol,
            );
            rawRows.add(rawRow);
            final epKey = '${sId ?? 0}_${sNo}_$epNo';
            epRowsMap.putIfAbsent(epKey, () => []).add(rawRow);
          }
        }

        final Map<String, int> episodeTotalViews = {};
        for (final entry in epRowsMap.entries) {
          final rows = entry.value;
          int maxRwCol = 0;
          int maxSuffix = 0;
          int rewatchKeyRows = 0;

          for (final r in rows) {
            if (r.rewatchCol > maxRwCol) maxRwCol = r.rewatchCol;
            if (r.key.contains('rewatch-episode')) {
              final lastPart = r.key.split('-').last;
              final sVal = int.tryParse(lastPart) ?? 0;
              if (sVal > maxSuffix) maxSuffix = sVal;
              rewatchKeyRows++;
            }
          }

          final effectiveRewatches = math.max(
            math.max(maxRwCol, maxSuffix),
            math.max(rewatchKeyRows, rows.length - 1),
          );
          episodeTotalViews[entry.key] = effectiveRewatches > 0 ? (effectiveRewatches + 1) : 1;
        }

        final List<WatchRecordModel> recordsToInsert = [];
        final Map<int, ShowModel> matchingShowsCache = {};

        for (final entry in epRowsMap.entries) {
          entry.value.sort((a, b) => a.watchedAt.compareTo(b.watchedAt));
        }

        episodesWatched = epRowsMap.length;

        for (final entry in epRowsMap.entries) {
          final rows = entry.value;
          final totalViews = episodeTotalViews[entry.key] ?? 1;

          for (int idx = 0; idx < rows.length; idx++) {
            final r = rows[idx];
            final isLatestRow = idx == rows.length - 1;

            int recordRewatchCount;
            if (isLatestRow) {
              recordRewatchCount = totalViews;
            } else if (r.key.contains('rewatch-episode')) {
              final lastPart = r.key.split('-').last;
              final suffix = int.tryParse(lastPart) ?? 0;
              recordRewatchCount = suffix > 0 ? (suffix + 1) : (idx + 1);
            } else {
              recordRewatchCount = idx + 1;
            }

            ShowModel? matchingShow;
            if (r.sId != null && r.sId! > 0) {
              matchingShow = matchingShowsCache[r.sId!] ??
                  _dbService.getShowByTvdbId(r.sId!) ??
                  _dbService.getShowById(r.sId!);
            }
            if (matchingShow == null && r.title.isNotEmpty) {
              matchingShow = _dbService.getShowByName(r.title);
            }

            if (matchingShow == null && r.sId != null && r.sId! > 0) {
              final newShow = ShowModel(
                id: r.sId!,
                tvdbId: r.sId!,
                name: r.title,
                isFollowed: true,
              );
              matchingShow = await _dbService.upsertShow(newShow, notify: false);
            }
            if (matchingShow != null && r.sId != null) {
              matchingShowsCache[r.sId!] = matchingShow;
            }

            final targetShowId = matchingShow?.id ?? r.sId ?? r.index;
            final record = WatchRecordModel(
              id: r.index,
              showId: targetShowId,
              sId: r.sId,
              tvdbId: r.sId,
              seasonNumber: r.sNo,
              episodeNumber: r.epNo,
              title: r.title,
              runtimeMinutes: r.runtimeMin,
              watchedAt: r.watchedAt,
              rewatchCount: recordRewatchCount,
            );
            recordsToInsert.add(record);
          }
        }

        if (recordsToInsert.isNotEmpty) {
          await _dbService.addWatchRecordsBatch(recordsToInsert);
        }

        for (final show in _dbService.getAllShows()) {
          final count = _dbService.getWatchedEpisodesCountForShow(show.id);
          if (count > 0 && count != show.watchedEpisodesCount) {
            await _dbService.upsertShow(show.copyWith(watchedEpisodesCount: count), notify: false);
          }
        }
        await _dbService.syncEpisodesWithWatchHistory();
      }

      // --- Stage 5: Friends & Unresolved Items Detection (%95 - %100) ---
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

      emit(95, 100, 0.95, 'Eşleşmeyen içerikler tespit ediliyor...');

      // Detect and compile unresolved items
      final List<UnresolvedItemModel> unresolvedItems = [];
      final allShows = _dbService.getAllShows();
      for (final show in allShows) {
        final isGeneric = show.name.startsWith('Show ') || show.name.isEmpty;
        final isMissing = show.tmdbId == null;
        if (isGeneric || isMissing) {
          final records = _dbService.getWatchRecordsForShow(show.id);
          final Set<String> distinctEpKeys = {};
          final Map<int, Set<int>> seasonEpisodes = {};
          int runMinutes = 0;
          DateTime? lastWatched;

          for (final r in records) {
            runMinutes += r.runtimeMinutes;
            if (r.seasonNumber > 0 && r.episodeNumber > 0) {
              distinctEpKeys.add('S${r.seasonNumber}E${r.episodeNumber}');
              seasonEpisodes.putIfAbsent(r.seasonNumber, () => <int>{}).add(r.episodeNumber);
            }
            if (lastWatched == null || r.watchedAt.isAfter(lastWatched)) {
              lastWatched = r.watchedAt;
            }
          }

          final sortedSeasons = seasonEpisodes.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
          final seasonsBreakdown = sortedSeasons.isEmpty
              ? null
              : sortedSeasons.map((e) => 'S${e.key}: ${e.value.length} bölüm').join(', ');

          unresolvedItems.add(UnresolvedItemModel(
            id: show.id,
            type: UnresolvedItemType.show,
            rawTitle: show.name,
            tvdbId: show.tvdbId,
            watchedEpisodesCount: distinctEpKeys.isNotEmpty
                ? distinctEpKeys.length
                : (records.isNotEmpty ? records.length : show.watchedEpisodesCount),
            runtimeMinutes: runMinutes,
            seasonsInfo: seasonsBreakdown,
            lastWatchedAt: lastWatched,
            posterPath: show.posterPath,
          ));
        }
      }

      final allMovies = _dbService.getAllMovies();
      for (final movie in allMovies) {
        if (movie.tmdbId == null) {
          unresolvedItems.add(UnresolvedItemModel(
            id: movie.id,
            type: UnresolvedItemType.movie,
            rawTitle: movie.title,
            runtimeMinutes: movie.runtimeMinutes,
            watchedEpisodesCount: movie.rewatchCount,
            lastWatchedAt: movie.watchedAt,
            releaseYear: movie.releaseDate?.year,
          ));
        }
      }

      currentUnresolved = unresolvedItems;
      _dbService.setUnresolvedItems(unresolvedItems);
      _dbService.notifyAll();

      _tmdbService.client.onRateLimitStateChanged = null;

      emit(
        100,
        100,
        1.0,
        'Başarılı! ${showEntries.length} dizi, $episodesWatched bölüm ($totalWatchMinutes dk) ve ${movieEntries.length} film aktarıldı.',
        isCompleted: true,
      );
    } catch (e) {
      _tmdbService.client.onRateLimitStateChanged = null;
      emit(0, 100, 0.0, 'İçe aktarma hatası: $e', isError: true, errorMessage: e.toString());
    } finally {
      _tmdbService.client.onRateLimitStateChanged = null;
      if (!controller.isClosed) {
        await controller.close();
      }
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

class _TvTimeShowData {
  final int tvdbId;
  String name;
  bool isFollowed;
  int watchedEpisodesCount;

  _TvTimeShowData({
    required this.tvdbId,
    required this.name,
    this.isFollowed = false,
    this.watchedEpisodesCount = 0,
  });
}

class _TvTimeMovieData {
  final String name;
  int runtimeSec = 0;
  DateTime? latestWatchedAt;
  DateTime? releaseDate;
  int maxRwCol = 0;
  int maxSuffix = 0;
  int rewatchTypeRows = 0;

  _TvTimeMovieData({required this.name});

  int get totalViews {
    final effectiveRewatches = math.max(
      math.max(maxRwCol, maxSuffix),
      rewatchTypeRows,
    );
    return effectiveRewatches > 0 ? (effectiveRewatches + 1) : 1;
  }
}

class _RawEpisodeRow {
  final int index;
  final int? sId;
  final int epNo;
  final int sNo;
  final String title;
  final int runtimeMin;
  final DateTime watchedAt;
  final String key;
  final int rewatchCol;

  const _RawEpisodeRow({
    required this.index,
    this.sId,
    required this.epNo,
    required this.sNo,
    required this.title,
    required this.runtimeMin,
    required this.watchedAt,
    required this.key,
    required this.rewatchCol,
  });
}
