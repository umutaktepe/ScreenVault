import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../core/network/pocketbase_client.dart';
import '../models/friend_model.dart';
import '../models/show_model.dart';
import '../models/movie_model.dart';
import '../models/watch_record_model.dart';
import '../database/database_service.dart';

class SyncResult {
  final int uploadedRecords;
  final int downloadedRecords;
  final bool success;
  final String? error;

  const SyncResult({
    this.uploadedRecords = 0,
    this.downloadedRecords = 0,
    this.success = true,
    this.error,
  });
}

class EpisodeCommentData {
  final String id;
  final String user;
  final String author;
  final String authorAvatar;
  final String text;
  final bool isSpoiler;
  final DateTime createdAt;
  final int likes;
  final String emotion;

  const EpisodeCommentData({
    required this.id,
    required this.user,
    required this.author,
    required this.authorAvatar,
    required this.text,
    required this.isSpoiler,
    required this.createdAt,
    required this.likes,
    this.emotion = '🔥',
  });
}

/// Offline-First Synchronization Engine between local Drift SQLite and PocketBase.
class PocketBaseSyncEngine {
  static final PocketBaseSyncEngine _instance = PocketBaseSyncEngine._internal();
  factory PocketBaseSyncEngine() => _instance;
  PocketBaseSyncEngine._internal();

  final PocketBaseClient _client = PocketBaseClient();
  final DatabaseService _dbService = DatabaseService();

  PocketBase get _pb => _client.pb;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final _syncStatusController = StreamController<bool>.broadcast();

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  Stream<bool> get syncStatusStream => _syncStatusController.stream;
  bool get isAuthenticated => _client.isAuthenticated;

  bool _isSubscribed = false;
  Timer? _heartbeatTimer;
  bool _wasDisconnected = false;
  bool _batchSupported = true;

  // Echo Filter: Prevents local writes echoed back via SSE from triggering duplicate local updates
  final Map<String, DateTime> _recentPushedKeys = {};

  void _recordEcho(String key) {
    final now = DateTime.now();
    _recentPushedKeys[key] = now;
    // Evict entries older than 15 seconds
    _recentPushedKeys.removeWhere((_, time) => now.difference(time).inSeconds > 15);
  }

  bool _isEcho(String key) {
    final time = _recentPushedKeys[key];
    if (time == null) return false;
    return DateTime.now().difference(time).inSeconds <= 15;
  }

  int getCanonicalShowId(ShowModel s) {
    if (s.tvdbId != null && s.tvdbId! > 0) return s.tvdbId!;
    if (s.tmdbId != null && s.tmdbId! > 0) return s.tmdbId!;
    return s.id;
  }

  int getCanonicalMovieId(MovieModel m) {
    if (m.tmdbId != null && m.tmdbId! > 0) return m.tmdbId!;
    return m.id;
  }

  void _startConnectionMonitoring() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      if (!_client.isAuthenticated) return;

      final isHealthy = await _client.checkHealth();
      if (!isHealthy) {
        if (!_wasDisconnected) {
          debugPrint('[SyncEngine] Connection lost to PocketBase server.');
          _wasDisconnected = true;
          _isSubscribed = false;
        }
      } else {
        if (_wasDisconnected) {
          debugPrint('[SyncEngine] Connection restored! Re-subscribing and syncing...');
          _wasDisconnected = false;
          startRealtimeListener(force: true);
          unawaited(syncAll());
        } else if (!_isSubscribed) {
          startRealtimeListener();
        }
      }
    });
  }

  /// Initializes the sync engine, monitors connection, and listens to auth state changes.
  void initialize() {
    _client.authStateStream.listen((event) {
      _recentPushedKeys.clear();
      _lastSyncTime = null;
      if (event.token.isNotEmpty && _client.isAuthenticated) {
        startRealtimeListener(force: true);
      } else {
        stopRealtimeListener();
      }
    });

    _startConnectionMonitoring();

    if (_client.isAuthenticated) {
      startRealtimeListener();
      // Startup sync for already authenticated session
      syncAll().catchError((e) {
        debugPrint('[SyncEngine] Startup sync error: $e');
        return const SyncResult(success: false);
      });
    }
  }

  /// Full bi-directional sync between SQLite and PocketBase using canonical IDs.
  Future<SyncResult> syncAll() async {
    if (_isSyncing) return const SyncResult(success: true);
    if (!_client.isAuthenticated) {
      return const SyncResult(success: false, error: 'Oturum açılmamış.');
    }

    _isSyncing = true;
    _syncStatusController.add(true);

    int uploaded = 0;
    int downloaded = 0;

    try {
      final user = _client.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı.');

      const batchSize = 20;

      // 1. Sync Tracked Shows
      try {
        final remoteTracked = await _pb.collection('tracked_shows').getFullList(
          filter: 'user = "${user.id}"',
        );

        final remoteTvdbIds = <int>{};
        final remoteTmdbIds = <int>{};
        final remoteShowIds = <int>{};
        final remoteTitles = <String>{};

        for (final item in remoteTracked) {
          final sId = item.getIntValue('showId');
          final tmdbId = item.getIntValue('tmdbId');
          final tvdbId = item.getIntValue('tvdbId');
          final title = item.getStringValue('title').trim().toLowerCase();

          if (sId > 0) remoteShowIds.add(sId);
          if (tvdbId > 0) remoteTvdbIds.add(tvdbId);
          if (tmdbId > 0) remoteTmdbIds.add(tmdbId);
          if (title.isNotEmpty) remoteTitles.add(title);

          final localShow = _dbService.findShow(showId: sId, tvdbId: tvdbId, tmdbId: tmdbId);
          final rawTitle = item.getStringValue('title').trim();
          final posterPath = item.getStringValue('posterPath').isNotEmpty
              ? item.getStringValue('posterPath')
              : null;

          if (localShow != null) {
            bool needsUpdate = false;
            var updated = localShow;
            if (!localShow.isFollowed) {
              updated = updated.copyWith(isFollowed: true);
              needsUpdate = true;
            }
            if (rawTitle.isNotEmpty && (updated.name.startsWith('Show ') || updated.name.isEmpty)) {
              updated = updated.copyWith(name: rawTitle);
              needsUpdate = true;
            }
            if ((updated.posterPath == null || updated.posterPath!.isEmpty) && posterPath != null) {
              updated = updated.copyWith(posterPath: posterPath);
              needsUpdate = true;
            }
            if (needsUpdate) {
              await _dbService.upsertShow(updated, notify: false);
              downloaded++;
            }
          } else {
            final effectiveId = sId > 0
                ? sId
                : (tvdbId > 0 ? tvdbId : (tmdbId > 0 ? tmdbId : DateTime.now().millisecondsSinceEpoch ~/ 1000 + downloaded));
            final newShow = ShowModel(
              id: effectiveId,
              tvdbId: tvdbId > 0 ? tvdbId : null,
              tmdbId: tmdbId > 0 ? tmdbId : null,
              name: rawTitle.isNotEmpty ? rawTitle : 'Show $effectiveId',
              posterPath: posterPath,
              isFollowed: true,
            );
            await _dbService.upsertShow(newShow, notify: false);
            downloaded++;
            unawaited(_dbService.enrichSingleShow(newShow));
          }
        }

        // Upload local followed shows not present on remote
        final localFollowed = _dbService.getFollowedShows();
        final showsToUpload = localFollowed.where((s) {
          final hasTvdb = s.tvdbId != null && s.tvdbId! > 0 && (remoteTvdbIds.contains(s.tvdbId) || remoteShowIds.contains(s.tvdbId));
          final hasTmdb = s.tmdbId != null && s.tmdbId! > 0 && (remoteTmdbIds.contains(s.tmdbId) || remoteShowIds.contains(s.tmdbId));
          final hasId = remoteShowIds.contains(s.id);
          final hasTitle = remoteTitles.contains(s.name.trim().toLowerCase());
          return !(hasTvdb || hasTmdb || hasId || hasTitle);
        }).toList();

        for (int i = 0; i < showsToUpload.length; i += batchSize) {
          final chunk = showsToUpload.skip(i).take(batchSize);
          await Future.wait(chunk.map((s) async {
            try {
              final canonicalId = getCanonicalShowId(s);
              _recordEcho('tracked_${canonicalId}_${s.tmdbId ?? 0}');
              await _pb.collection('tracked_shows').create(body: {
                'user': user.id,
                'showId': canonicalId,
                'tvdbId': s.tvdbId ?? 0,
                'tmdbId': s.tmdbId ?? 0,
                'title': s.name,
                'posterPath': s.posterPath,
                'status': 'watching',
                'isFavorite': false,
              });
              uploaded++;
            } catch (e) {
              debugPrint('[SyncEngine] Error uploading tracked_show: $e');
            }
          }));
        }
      } catch (e) {
        debugPrint('[SyncEngine] Error syncing tracked_shows: $e');
      }

      // 2. Sync Episode Watch History
      final remoteRecords = await _pb.collection('watch_history').getFullList(
        filter: 'user = "${user.id}"',
      );

      final localHistory = _dbService.getAllWatchRecords();
      final localCanonicalKeys = <String>{};
      for (final r in localHistory) {
        final show = _dbService.findShow(showId: r.showId, tvdbId: r.tvdbId);
        final canonicalId = show != null
            ? getCanonicalShowId(show)
            : (r.tvdbId != null && r.tvdbId! > 0 ? r.tvdbId! : (r.showId ?? 0));
        localCanonicalKeys.add('${canonicalId}_${r.seasonNumber}_${r.episodeNumber}');
      }

      // Merge remote records into local database
      for (final item in remoteRecords) {
        final rawShowId = item.getIntValue('showId');
        final rawTvdbId = item.getIntValue('tvdbId');
        final rawTmdbId = item.getIntValue('tmdbId');
        var localShow = _dbService.findShow(showId: rawShowId, tvdbId: rawTvdbId, tmdbId: rawTmdbId);

        if (localShow == null) {
          final effectiveShowId = rawShowId > 0
              ? rawShowId
              : (rawTvdbId > 0 ? rawTvdbId : (rawTmdbId > 0 ? rawTmdbId : DateTime.now().millisecondsSinceEpoch ~/ 1000 + downloaded));
          final shell = ShowModel(
            id: effectiveShowId,
            tvdbId: rawTvdbId > 0 ? rawTvdbId : null,
            tmdbId: rawTmdbId > 0 ? rawTmdbId : null,
            name: 'Show $effectiveShowId',
            isFollowed: false,
          );
          localShow = await _dbService.upsertShow(shell, notify: false);
          unawaited(_dbService.enrichSingleShow(shell));
        }

        final canonicalId = getCanonicalShowId(localShow);
        final sNum = item.getIntValue('seasonNumber');
        final epNum = item.getIntValue('episodeNumber');
        final key = '${canonicalId}_${sNum}_$epNum';

        if (!localCanonicalKeys.contains(key)) {
          final dateStr = item.getStringValue('watchedAt');
          final watchedDate = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

          final effectiveShowId = localShow.id;
          final effectiveTvdbId = rawTvdbId > 0 ? rawTvdbId : (localShow.tvdbId ?? 0);

          final newRecord = WatchRecordModel(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + downloaded,
            showId: effectiveShowId,
            tvdbId: effectiveTvdbId,
            seasonNumber: sNum,
            episodeNumber: epNum,
            title: item.getStringValue('episodeTitle').isNotEmpty
                ? item.getStringValue('episodeTitle')
                : '$epNum. Bölüm',
            runtimeMinutes: item.getIntValue('runtimeMinutes'),
            watchedAt: watchedDate,
            rewatchCount: item.getIntValue('rewatchCount') > 0 ? item.getIntValue('rewatchCount') : 1,
          );

          await _dbService.insertWatchRecord(newRecord);
          localCanonicalKeys.add(key);
          downloaded++;
        }
      }

      await _dbService.syncEpisodesWithWatchHistory();

      // Upload local history records that are missing on remote
      final remoteCanonicalKeys = <String>{};
      for (final item in remoteRecords) {
        final rawShowId = item.getIntValue('showId');
        final rawTvdbId = item.getIntValue('tvdbId');
        final rawTmdbId = item.getIntValue('tmdbId');
        final localShow = _dbService.findShow(showId: rawShowId, tvdbId: rawTvdbId, tmdbId: rawTmdbId);
        final canonicalId = localShow != null
            ? getCanonicalShowId(localShow)
            : (rawTvdbId > 0 ? rawTvdbId : rawShowId);
        remoteCanonicalKeys.add('${canonicalId}_${item.getIntValue('seasonNumber')}_${item.getIntValue('episodeNumber')}');
      }

      final recordsToUpload = localHistory.where((local) {
        final show = _dbService.findShow(showId: local.showId, tvdbId: local.tvdbId);
        final canonicalId = show != null
            ? getCanonicalShowId(show)
            : (local.tvdbId != null && local.tvdbId! > 0 ? local.tvdbId! : (local.showId ?? 0));
        final key = '${canonicalId}_${local.seasonNumber}_${local.episodeNumber}';
        return !remoteCanonicalKeys.contains(key);
      }).toList();

      for (int i = 0; i < recordsToUpload.length; i += batchSize) {
        final chunk = recordsToUpload.skip(i).take(batchSize);
        await Future.wait(chunk.map((local) async {
          try {
            final show = _dbService.findShow(showId: local.showId, tvdbId: local.tvdbId);
            final canonicalId = show != null
                ? getCanonicalShowId(show)
                : (local.tvdbId != null && local.tvdbId! > 0 ? local.tvdbId! : (local.showId ?? 0));

            _recordEcho('watch_${canonicalId}_${local.seasonNumber}_${local.episodeNumber}');
            await _pb.collection('watch_history').create(body: {
              'user': user.id,
              'showId': canonicalId,
              'tvdbId': local.tvdbId ?? show?.tvdbId ?? 0,
              'tmdbId': show?.tmdbId ?? 0,
              'seasonNumber': local.seasonNumber,
              'episodeNumber': local.episodeNumber,
              'episodeTitle': local.title,
              'runtimeMinutes': local.runtimeMinutes,
              'isWatched': true,
              'rewatchCount': local.rewatchCount > 0 ? local.rewatchCount : 1,
              'watchedAt': local.watchedAt.toIso8601String(),
            });
            uploaded++;
          } catch (e) {
            debugPrint('[SyncEngine] Error uploading watch record: $e');
          }
        }));
      }

      // 3. Sync Movie Watch History
      try {
        final remoteMovies = await _pb.collection('movie_watch_history').getFullList(
          filter: 'user = "${user.id}"',
        );

        final remoteTmdbIds = <int>{};
        final remoteMovieIds = <int>{};
        final remoteTitles = <String>{};

        for (final item in remoteMovies) {
          final mId = item.getIntValue('movieId');
          final tmdbId = item.getIntValue('tmdbId');
          final title = item.getStringValue('title').trim().toLowerCase();

          if (mId > 0) remoteMovieIds.add(mId);
          if (tmdbId > 0) remoteTmdbIds.add(tmdbId);
          if (title.isNotEmpty) remoteTitles.add(title);

          MovieModel? localMovie;
          if (tmdbId > 0 && _dbService.getAllMovies().any((m) => m.tmdbId == tmdbId)) {
            localMovie = _dbService.getAllMovies().firstWhere((m) => m.tmdbId == tmdbId);
          } else if (mId > 0 && _dbService.getAllMovies().any((m) => m.id == mId)) {
            localMovie = _dbService.getAllMovies().firstWhere((m) => m.id == mId);
          } else if (title.isNotEmpty && _dbService.getAllMovies().any((m) => m.title.trim().toLowerCase() == title)) {
            localMovie = _dbService.getAllMovies().firstWhere((m) => m.title.trim().toLowerCase() == title);
          }

          final rawTitle = item.getStringValue('title').trim();
          final posterPath = item.getStringValue('posterPath').isNotEmpty ? item.getStringValue('posterPath') : null;

          if (localMovie != null) {
            final isWatched = item.getBoolValue('isWatched');
            if (isWatched && !localMovie.isWatched) {
              final dateStr = item.getStringValue('watchedAt');
              final watchedDate = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
              await _dbService.toggleMovieWatched(localMovie.id, isWatched: true, watchedAt: watchedDate, syncRemote: false);
              downloaded++;
            }
            if (rawTitle.isNotEmpty && (localMovie.title.startsWith('Movie ') || localMovie.title.isEmpty)) {
              await _dbService.upsertMovie(localMovie.copyWith(
                title: rawTitle,
                posterPath: localMovie.posterPath ?? posterPath,
              ), notify: false);
            }
          } else {
            final effectiveId = mId > 0
                ? mId
                : (tmdbId > 0 ? tmdbId : DateTime.now().millisecondsSinceEpoch ~/ 1000 + downloaded);
            final runtime = item.getIntValue('runtimeMinutes');
            final dateStr = item.getStringValue('watchedAt');
            final watchedDate = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

            final newMovie = MovieModel(
              id: effectiveId,
              tmdbId: tmdbId > 0 ? tmdbId : null,
              title: rawTitle.isNotEmpty ? rawTitle : 'Movie $effectiveId',
              posterPath: posterPath,
              runtimeMinutes: runtime,
              isWatched: true,
              watchedAt: watchedDate,
            );
            await _dbService.upsertMovie(newMovie, notify: false);
            downloaded++;
            unawaited(_dbService.enrichSingleMovie(newMovie));
          }
        }

        // Upload local watched movies missing from remote
        final localWatchedMovies = _dbService.getAllMovies().where((m) => m.isWatched).toList();
        final moviesToUpload = localWatchedMovies.where((m) {
          final hasTmdb = m.tmdbId != null && m.tmdbId! > 0 && (remoteTmdbIds.contains(m.tmdbId) || remoteMovieIds.contains(m.tmdbId));
          final hasId = remoteMovieIds.contains(m.id);
          final hasTitle = remoteTitles.contains(m.title.trim().toLowerCase());
          return !(hasTmdb || hasId || hasTitle);
        }).toList();

        for (int i = 0; i < moviesToUpload.length; i += batchSize) {
          final chunk = moviesToUpload.skip(i).take(batchSize);
          await Future.wait(chunk.map((m) async {
            try {
              final canonicalId = getCanonicalMovieId(m);
              _recordEcho('movie_watch_${canonicalId}_${m.tmdbId ?? 0}');
              await _pb.collection('movie_watch_history').create(body: {
                'user': user.id,
                'movieId': canonicalId,
                'tmdbId': m.tmdbId ?? 0,
                'title': m.title,
                'posterPath': m.posterPath,
                'runtimeMinutes': m.runtimeMinutes,
                'isWatched': true,
                'watchedAt': (m.watchedAt ?? DateTime.now()).toIso8601String(),
              });
              uploaded++;
            } catch (e) {
              debugPrint('[SyncEngine] Error uploading movie watch record: $e');
            }
          }));
        }
      } catch (e) {
        debugPrint('[SyncEngine] Error syncing movie_watch_history: $e');
      }

      _lastSyncTime = DateTime.now();
      _dbService.notifyAll(immediate: true);
      debugPrint('[SyncEngine] Sync complete. Uploaded: $uploaded, Downloaded: $downloaded');
      return SyncResult(uploadedRecords: uploaded, downloadedRecords: downloaded, success: true);
    } catch (e) {
      debugPrint('[SyncEngine] Sync failed: $e');
      return SyncResult(success: false, error: e.toString());
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
    }
  }

  /// Pushes an episode watch toggle directly to PocketBase in the background.
  Future<void> pushWatchRecord(WatchRecordModel record, {bool isWatched = true}) async {
    if (!_client.isAuthenticated) return;

    final user = _client.currentUser;
    if (user == null) return;

    final show = _dbService.findShow(showId: record.showId, tvdbId: record.tvdbId);
    final canonicalId = show != null
        ? getCanonicalShowId(show)
        : (record.tvdbId != null && record.tvdbId! > 0 ? record.tvdbId! : (record.showId ?? 0));
    final tvdbId = record.tvdbId ?? show?.tvdbId ?? 0;
    final tmdbId = show?.tmdbId ?? 0;
    final sNum = record.seasonNumber;
    final epNum = record.episodeNumber;

    final echoKey = 'watch_${canonicalId}_${sNum}_$epNum';
    _recordEcho(echoKey);

    try {
      final showFilterParts = <String>['showId = $canonicalId'];
      if (tvdbId > 0 && tvdbId != canonicalId) showFilterParts.add('tvdbId = $tvdbId');
      if (tmdbId > 0 && tmdbId != canonicalId) showFilterParts.add('tmdbId = $tmdbId');
      final filter = 'user = "${user.id}" && (${showFilterParts.join(" || ")}) && seasonNumber = $sNum && episodeNumber = $epNum';

      if (isWatched) {
        final existing = await _pb.collection('watch_history').getList(
          page: 1,
          perPage: 1,
          filter: filter,
        );

        if (existing.items.isNotEmpty) {
          final target = existing.items.first;
          await _pb.collection('watch_history').update(target.id, body: {
            'isWatched': true,
            'rewatchCount': record.rewatchCount > 0 ? record.rewatchCount : 1,
            'watchedAt': record.watchedAt.toIso8601String(),
            'runtimeMinutes': record.runtimeMinutes,
          });
        } else {
          await _pb.collection('watch_history').create(body: {
            'user': user.id,
            'showId': canonicalId,
            'tvdbId': tvdbId,
            'tmdbId': tmdbId,
            'seasonNumber': sNum,
            'episodeNumber': epNum,
            'episodeTitle': record.title,
            'runtimeMinutes': record.runtimeMinutes,
            'isWatched': true,
            'rewatchCount': record.rewatchCount > 0 ? record.rewatchCount : 1,
            'watchedAt': record.watchedAt.toIso8601String(),
          });
        }
      } else {
        final existing = await _pb.collection('watch_history').getList(
          page: 1,
          perPage: 5,
          filter: filter,
        );
        for (final item in existing.items) {
          await _pb.collection('watch_history').delete(item.id);
        }
      }
      debugPrint('[SyncEngine] Pushed watch state for S${sNum}E$epNum (isWatched: $isWatched)');
    } catch (e) {
      debugPrint('[SyncEngine] pushWatchRecord error: $e');
    }
  }

  /// Pushes tracked show state to PocketBase
  Future<void> pushTrackedShow(ShowModel show, {bool isFollowed = true, String status = 'watching'}) async {
    if (!_client.isAuthenticated) return;
    final user = _client.currentUser;
    if (user == null) return;

    final canonicalId = getCanonicalShowId(show);
    final tvdbId = show.tvdbId ?? 0;
    final tmdbId = show.tmdbId ?? 0;

    final echoKey = 'tracked_${canonicalId}_$tmdbId';
    _recordEcho(echoKey);

    try {
      final filterParts = <String>['showId = $canonicalId'];
      if (tvdbId > 0 && tvdbId != canonicalId) filterParts.add('tvdbId = $tvdbId');
      if (tmdbId > 0 && tmdbId != canonicalId) filterParts.add('tmdbId = $tmdbId');
      final filter = 'user = "${user.id}" && (${filterParts.join(" || ")})';

      final existing = await _pb.collection('tracked_shows').getList(
        page: 1,
        perPage: 5,
        filter: filter,
      );

      if (!isFollowed) {
        for (final item in existing.items) {
          await _pb.collection('tracked_shows').delete(item.id);
        }
        debugPrint('[SyncEngine] Removed tracked_show for ${show.name}');
      } else {
        if (existing.items.isNotEmpty) {
          await _pb.collection('tracked_shows').update(existing.items.first.id, body: {
            'status': status,
            'title': show.name,
            'posterPath': show.posterPath,
          });
        } else {
          await _pb.collection('tracked_shows').create(body: {
            'user': user.id,
            'showId': canonicalId,
            'tvdbId': tvdbId,
            'tmdbId': tmdbId,
            'title': show.name,
            'posterPath': show.posterPath,
            'status': status,
            'isFavorite': false,
          });
        }
        debugPrint('[SyncEngine] Pushed tracked_show for ${show.name}');
      }
    } catch (e) {
      debugPrint('[SyncEngine] pushTrackedShow error: $e');
    }
  }

  /// Pushes tracked movie state to PocketBase
  Future<void> pushTrackedMovie(MovieModel movie, {bool isFollowed = true}) async {
    if (!_client.isAuthenticated) return;
    final user = _client.currentUser;
    if (user == null) return;

    final canonicalId = getCanonicalMovieId(movie);
    final tmdb = movie.tmdbId ?? 0;
    final echoKey = 'movie_watch_${canonicalId}_$tmdb';
    _recordEcho(echoKey);

    try {
      final filterParts = <String>['movieId = $canonicalId'];
      if (tmdb > 0 && tmdb != canonicalId) filterParts.add('tmdbId = $tmdb');
      final filter = 'user = "${user.id}" && (${filterParts.join(" || ")})';

      final existing = await _pb.collection('movie_watch_history').getList(
        page: 1,
        perPage: 5,
        filter: filter,
      );

      if (!isFollowed && !movie.isWatched) {
        for (final item in existing.items) {
          await _pb.collection('movie_watch_history').delete(item.id);
        }
        debugPrint('[SyncEngine] Removed movie from movie_watch_history for ${movie.title}');
      } else {
        if (existing.items.isNotEmpty) {
          await _pb.collection('movie_watch_history').update(existing.items.first.id, body: {
            'title': movie.title,
            'posterPath': movie.posterPath,
            'runtimeMinutes': movie.runtimeMinutes,
            'isWatched': movie.isWatched,
          });
        } else {
          await _pb.collection('movie_watch_history').create(body: {
            'user': user.id,
            'movieId': canonicalId,
            'tmdbId': tmdb,
            'title': movie.title,
            'posterPath': movie.posterPath,
            'runtimeMinutes': movie.runtimeMinutes,
            'isWatched': movie.isWatched,
            'watchedAt': movie.watchedAt?.toIso8601String(),
          });
        }
        debugPrint('[SyncEngine] Pushed tracked movie for ${movie.title}');
      }
    } catch (e) {
      debugPrint('[SyncEngine] pushTrackedMovie error: $e');
    }
  }

  /// Pushes movie watch state to PocketBase
  Future<void> pushMovieWatchRecord(MovieModel movie, {bool isWatched = true}) async {
    if (!_client.isAuthenticated) return;
    final user = _client.currentUser;
    if (user == null) return;

    final canonicalId = getCanonicalMovieId(movie);
    final tmdb = movie.tmdbId ?? 0;
    final echoKey = 'movie_watch_${canonicalId}_$tmdb';
    _recordEcho(echoKey);

    try {
      final filterParts = <String>['movieId = $canonicalId'];
      if (tmdb > 0 && tmdb != canonicalId) filterParts.add('tmdbId = $tmdb');
      final filter = 'user = "${user.id}" && (${filterParts.join(" || ")})';

      final existing = await _pb.collection('movie_watch_history').getList(
        page: 1,
        perPage: 5,
        filter: filter,
      );

      if (isWatched) {
        if (existing.items.isNotEmpty) {
          await _pb.collection('movie_watch_history').update(existing.items.first.id, body: {
            'title': movie.title,
            'posterPath': movie.posterPath,
            'runtimeMinutes': movie.runtimeMinutes,
            'isWatched': true,
            'watchedAt': (movie.watchedAt ?? DateTime.now()).toIso8601String(),
          });
        } else {
          await _pb.collection('movie_watch_history').create(body: {
            'user': user.id,
            'movieId': canonicalId,
            'tmdbId': tmdb,
            'title': movie.title,
            'posterPath': movie.posterPath,
            'runtimeMinutes': movie.runtimeMinutes,
            'isWatched': true,
            'watchedAt': (movie.watchedAt ?? DateTime.now()).toIso8601String(),
          });
        }
      } else {
        if (movie.isFollowed) {
          if (existing.items.isNotEmpty) {
            await _pb.collection('movie_watch_history').update(existing.items.first.id, body: {
              'isWatched': false,
            });
          }
        } else {
          for (final item in existing.items) {
            await _pb.collection('movie_watch_history').delete(item.id);
          }
        }
      }
      debugPrint('[SyncEngine] Pushed movie watch state for ${movie.title} (isWatched: $isWatched)');
    } catch (e) {
      debugPrint('[SyncEngine] pushMovieWatchRecord error: $e');
    }
  }

  /// Starts real-time SSE listener for multi-device sync
  void startRealtimeListener({bool force = false}) {
    if ((_isSubscribed && !force) || !_client.isAuthenticated) return;
    if (_isSubscribed && force) {
      stopRealtimeListener();
    }

    try {
      // 1. watch_history listener
      _pb.collection('watch_history').subscribe('*', (e) {
        if (_isSyncing) return;
        final record = e.record;
        if (record == null) return;

        final user = _client.currentUser;
        if (user == null || record.getStringValue('user') != user.id) return;

        final rawShowId = record.getIntValue('showId');
        final rawTvdbId = record.getIntValue('tvdbId');
        final rawTmdbId = record.getIntValue('tmdbId');
        final localShow = _dbService.findShow(showId: rawShowId, tvdbId: rawTvdbId, tmdbId: rawTmdbId);
        final canonicalId = localShow != null
            ? getCanonicalShowId(localShow)
            : (rawTvdbId > 0 ? rawTvdbId : rawShowId);
        final sNum = record.getIntValue('seasonNumber');
        final epNum = record.getIntValue('episodeNumber');
        final echoKey = 'watch_${canonicalId}_${sNum}_$epNum';

        if (_isEcho(echoKey)) {
          debugPrint('[SyncEngine] Dropping echo event for $echoKey');
          return;
        }

        debugPrint('[SyncEngine] Realtime watch_history event received: ${e.action}');

        final effectiveShowId = localShow?.id ?? rawShowId;
        final effectiveTvdbId = rawTvdbId > 0 ? rawTvdbId : (localShow?.tvdbId ?? 0);

        if (e.action == 'delete') {
          _dbService.removeWatchRecord(showId: effectiveShowId, seasonNumber: sNum, episodeNumber: epNum);
        } else if (e.action == 'create' || e.action == 'update') {
          final isWatched = record.getBoolValue('isWatched');
          if (isWatched) {
            final targetRewatch = record.getIntValue('rewatchCount') > 0 ? record.getIntValue('rewatchCount') : 1;
            final existingRecord = _dbService.getLatestWatchRecord(
              showId: effectiveShowId,
              tvdbId: effectiveTvdbId > 0 ? effectiveTvdbId : null,
              seasonNumber: sNum,
              episodeNumber: epNum,
            );
            if (existingRecord != null && existingRecord.rewatchCount == targetRewatch) {
              // Local is already recorded with identical status - skip
              return;
            }

            final dateStr = record.getStringValue('watchedAt');
            final watchedDate = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

            _dbService.insertWatchRecord(WatchRecordModel(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              showId: effectiveShowId,
              tvdbId: effectiveTvdbId,
              seasonNumber: sNum,
              episodeNumber: epNum,
              title: record.getStringValue('episodeTitle').isNotEmpty
                  ? record.getStringValue('episodeTitle')
                  : '$epNum. Bölüm',
              runtimeMinutes: record.getIntValue('runtimeMinutes'),
              watchedAt: watchedDate,
              rewatchCount: targetRewatch,
            ));
          } else {
            _dbService.removeWatchRecord(showId: effectiveShowId, seasonNumber: sNum, episodeNumber: epNum);
          }
        }
      });

      // 2. tracked_shows listener
      _pb.collection('tracked_shows').subscribe('*', (e) {
        if (_isSyncing) return;
        final record = e.record;
        if (record == null) return;

        final user = _client.currentUser;
        if (user == null || record.getStringValue('user') != user.id) return;

        final showId = record.getIntValue('showId');
        final tmdbId = record.getIntValue('tmdbId');
        final tvdbId = record.getIntValue('tvdbId');
        final localShow = _dbService.findShow(showId: showId, tvdbId: tvdbId, tmdbId: tmdbId);
        final canonicalId = localShow != null ? getCanonicalShowId(localShow) : showId;
        final echoKey = 'tracked_${canonicalId}_$tmdbId';

        if (_isEcho(echoKey)) {
          debugPrint('[SyncEngine] Dropping echo event for $echoKey');
          return;
        }

        debugPrint('[SyncEngine] Realtime tracked_shows event received: ${e.action}');

        if (localShow != null) {
          if (e.action == 'delete') {
            if (!localShow.isFollowed) return;
            _dbService.upsertShow(localShow.copyWith(isFollowed: false));
          } else if (e.action == 'create' || e.action == 'update') {
            if (localShow.isFollowed) return;
            _dbService.upsertShow(localShow.copyWith(isFollowed: true));
          }
        } else if (e.action == 'create' || e.action == 'update') {
          final effectiveId = showId > 0 ? showId : (tvdbId > 0 ? tvdbId : (tmdbId > 0 ? tmdbId : DateTime.now().millisecondsSinceEpoch ~/ 1000));
          final rawTitle = record.getStringValue('title').trim();
          final posterPath = record.getStringValue('posterPath').isNotEmpty ? record.getStringValue('posterPath') : null;
          final newShow = ShowModel(
            id: effectiveId,
            tvdbId: tvdbId > 0 ? tvdbId : null,
            tmdbId: tmdbId > 0 ? tmdbId : null,
            name: rawTitle.isNotEmpty ? rawTitle : 'Show $effectiveId',
            posterPath: posterPath,
            isFollowed: true,
          );
          _dbService.upsertShow(newShow);
          unawaited(_dbService.enrichSingleShow(newShow));
        }
      });

      // 3. movie_watch_history listener
      _pb.collection('movie_watch_history').subscribe('*', (e) {
        if (_isSyncing) return;
        final record = e.record;
        if (record == null) return;

        final user = _client.currentUser;
        if (user == null || record.getStringValue('user') != user.id) return;

        final rawMovieId = record.getIntValue('movieId');
        final rawTmdbId = record.getIntValue('tmdbId');
        final rawTitle = record.getStringValue('title').trim().toLowerCase();

        final localMovie = _dbService.findMovie(
          movieId: rawMovieId > 0 ? rawMovieId : null,
          tmdbId: rawTmdbId > 0 ? rawTmdbId : null,
          title: rawTitle.isNotEmpty ? rawTitle : null,
        );

        final canonicalId = localMovie != null
            ? getCanonicalMovieId(localMovie)
            : (rawTmdbId > 0 ? rawTmdbId : rawMovieId);
        final echoKey = 'movie_watch_${canonicalId}_$rawTmdbId';

        if (_isEcho(echoKey)) {
          debugPrint('[SyncEngine] Dropping echo event for $echoKey');
          return;
        }

        debugPrint('[SyncEngine] Realtime movie_watch_history event received: ${e.action}');

        if (localMovie != null) {
          final isWatched = record.getBoolValue('isWatched');
          // No-op guard: if local watch state and title already match incoming event, skip processing
          if (e.action != 'delete' &&
              localMovie.isWatched == isWatched &&
              (rawTitle.isEmpty || localMovie.title.trim().toLowerCase() == rawTitle)) {
            return;
          }

          if (e.action == 'delete' || !isWatched) {
            if (localMovie.isWatched) {
              _dbService.toggleMovieWatched(localMovie.id, isWatched: false, syncRemote: false);
            }
          } else if (e.action == 'create' || e.action == 'update') {
            if (isWatched && !localMovie.isWatched) {
              final dateStr = record.getStringValue('watchedAt');
              final watchedDate = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
              _dbService.toggleMovieWatched(localMovie.id, isWatched: true, watchedAt: watchedDate, syncRemote: false);
            }
          }
        } else if (e.action == 'create' || e.action == 'update') {
          final isWatched = record.getBoolValue('isWatched');
          if (isWatched) {
            final effectiveId = rawMovieId > 0 ? rawMovieId : (rawTmdbId > 0 ? rawTmdbId : DateTime.now().millisecondsSinceEpoch ~/ 1000);
            final rawTitle = record.getStringValue('title').trim();
            final posterPath = record.getStringValue('posterPath').isNotEmpty ? record.getStringValue('posterPath') : null;
            final runtime = record.getIntValue('runtimeMinutes');
            final dateStr = record.getStringValue('watchedAt');
            final watchedDate = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

            final newMovie = MovieModel(
              id: effectiveId,
              tmdbId: rawTmdbId > 0 ? rawTmdbId : null,
              title: rawTitle.isNotEmpty ? rawTitle : 'Movie $effectiveId',
              posterPath: posterPath,
              runtimeMinutes: runtime,
              isWatched: true,
              watchedAt: watchedDate,
            );
            _dbService.upsertMovie(newMovie);
            unawaited(_dbService.enrichSingleMovie(newMovie));
          }
        }
      });

      _isSubscribed = true;
      debugPrint('[SyncEngine] Subscribed to realtime events');
    } catch (e) {
      debugPrint('[SyncEngine] Failed to subscribe to realtime: $e');
    }
  }

  /// Stops real-time listener
  void stopRealtimeListener() {
    if (!_isSubscribed) return;
    try {
      _pb.collection('watch_history').unsubscribe('*');
      _pb.collection('tracked_shows').unsubscribe('*');
      _pb.collection('movie_watch_history').unsubscribe('*');
      _isSubscribed = false;
      debugPrint('[SyncEngine] Unsubscribed from realtime events');
    } catch (e) {
      debugPrint('[SyncEngine] Unsubscribe error: $e');
    }
  }

  /// Fetches episode comments from PocketBase
  Future<List<EpisodeCommentData>> fetchEpisodeComments({
    required int showId,
    required int seasonNumber,
    required int episodeNumber,
    String? episodeCode,
    int? tvdbId,
  }) async {
    try {
      final show = _dbService.findShow(showId: showId, tvdbId: tvdbId);
      final canonicalId = show != null
          ? getCanonicalShowId(show)
          : (tvdbId != null && tvdbId > 0 ? tvdbId : showId);
      final effectiveTvdb = tvdbId ?? show?.tvdbId ?? 0;

      final idConditions = <String>['showId = $showId'];
      if (canonicalId != showId) idConditions.add('showId = $canonicalId');
      if (effectiveTvdb > 0 && effectiveTvdb != showId && effectiveTvdb != canonicalId) {
        idConditions.add('showId = $effectiveTvdb');
      }

      final orIdStr = idConditions.length == 1 ? idConditions.first : '(${idConditions.join(" || ")})';

      String filter = '($orIdStr && seasonNumber = $seasonNumber && episodeNumber = $episodeNumber)';
      if (episodeCode != null && episodeCode.isNotEmpty) {
        filter = '$filter || ($orIdStr && episodeCode = "$episodeCode")';
      }

      final items = await _pb.collection('comments').getList(
        page: 1,
        perPage: 50,
        filter: filter,
        sort: '-created',
      );

      return items.items.map((item) {
        final avatar = item.getStringValue('userAvatar');
        final dateStr = item.getStringValue('created');
        final ts = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

        return EpisodeCommentData(
          id: item.id,
          user: item.getStringValue('user'),
          author: item.getStringValue('userName').isNotEmpty ? item.getStringValue('userName') : 'Kullanıcı',
          authorAvatar: avatar,
          text: item.getStringValue('content'),
          isSpoiler: item.getBoolValue('isSpoiler'),
          createdAt: ts,
          likes: item.getIntValue('likesCount'),
          emotion: item.getStringValue('emotion').isNotEmpty ? item.getStringValue('emotion') : '🔥',
        );
      }).toList();
    } catch (e) {
      debugPrint('[SyncEngine] fetchEpisodeComments error: $e');
      return [];
    }
  }

  /// Fetches community activities from PocketBase comments collection
  Future<List<CommunityActivityItem>> fetchCommunityActivities() async {
    try {
      final items = await _pb.collection('comments').getList(
        page: 1,
        perPage: 30,
        sort: '-created',
      );

      return items.items.map((item) {
        final avatar = item.getStringValue('userAvatar');
        final dateStr = item.getStringValue('created');
        final ts = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

        return CommunityActivityItem(
          id: item.id,
          userName: item.getStringValue('userName').isNotEmpty ? item.getStringValue('userName') : 'Kullanıcı',
          userAvatar: avatar.isNotEmpty ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
          actionType: 'yorum yaptı',
          showOrMovieTitle: item.getStringValue('showTitle'),
          episodeCode: item.getStringValue('episodeCode'),
          comment: item.getStringValue('content'),
          isSpoiler: item.getBoolValue('isSpoiler'),
          emotion: item.getStringValue('emotion').isNotEmpty ? item.getStringValue('emotion') : '🔥',
          timestamp: ts,
          likesCount: item.getIntValue('likesCount'),
        );
      }).toList();
    } catch (e) {
      debugPrint('[SyncEngine] fetchCommunityActivities error: $e');
      return [];
    }
  }

  /// Posts a new comment to PocketBase
  Future<void> postComment({
    required String showTitle,
    required String episodeCode,
    required int showId,
    int? seasonNumber,
    int? episodeNumber,
    required String content,
    bool isSpoiler = false,
    String emotion = '🔥',
  }) async {
    if (!_client.isAuthenticated) return;
    final user = _client.currentUser;
    if (user == null) return;

    final show = _dbService.findShow(showId: showId, tvdbId: showId);
    final canonicalId = show != null ? getCanonicalShowId(show) : showId;

    final userName = user.getStringValue('name').isNotEmpty ? user.getStringValue('name') : user.getStringValue('email');
    final avatar = user.getStringValue('avatar');
    final avatarUrl = avatar.isNotEmpty ? '${_client.serverUrl}/api/files/${user.collectionId}/${user.id}/$avatar' : '';

    await _pb.collection('comments').create(body: {
      'user': user.id,
      'userName': userName,
      'userAvatar': avatarUrl,
      'showTitle': showTitle,
      'episodeCode': episodeCode,
      'showId': canonicalId,
      'seasonNumber': seasonNumber ?? 1,
      'episodeNumber': episodeNumber ?? 1,
      'content': content.trim(),
      'isSpoiler': isSpoiler,
      'emotion': emotion,
      'likesCount': 0,
    });
  }

  /// Purges all remote data (tracked_shows, movie_watch_history, comments, episode_reactions, watch_history)
  /// belonging to the current user in PocketBase using transactional Batch API.
  Future<bool> purgeRemoteUserData({void Function(String status)? onProgress}) async {
    if (!_client.isAuthenticated) return false;
    final user = _client.currentUser;
    if (user == null) return false;

    // 1. Lock syncing and pause realtime listener so no race condition can occur
    _isSyncing = true;
    stopRealtimeListener();

    try {
      debugPrint('[SyncEngine] Starting transactional remote user data purge for user: ${user.id}...');
      onProgress?.call('Bulut veritabanı hazırlanıyor...');

      // Reset batch detection on explicit purge run so server-side setting changes take effect
      _batchSupported = true;

      // Priority order: First wipe tracked_shows, movies, comments, reactions, then watch_history
      final collectionsToPurge = [
        'tracked_shows',
        'movie_watch_history',
        'comments',
        'episode_reactions',
        'watch_history',
      ];

      for (final col in collectionsToPurge) {
        onProgress?.call('Siliniyor: $col...');
        await _purgeCollectionBatch(col, user.id, onProgress: onProgress);
      }

      // Zero-State verification pass: double check if any orphaned records remained
      onProgress?.call('Sıfırlama doğrulanıyor...');
      for (final col in collectionsToPurge) {
        try {
          final leftover = await _pb.collection(col).getFullList(
            filter: 'user = "${user.id}"',
          );
          if (leftover.isNotEmpty) {
            debugPrint('[SyncEngine] Verification pass found ${leftover.length} leftover records in $col. Cleaning up with concurrent pool...');
            const poolSize = 25;
            for (int p = 0; p < leftover.length; p += poolSize) {
              final pool = leftover.skip(p).take(poolSize).toList();
              await Future.wait(pool.map((item) async {
                try {
                  await _pb.collection(col).delete(item.id);
                } catch (_) {}
              }));
            }
          }
        } catch (e) {
          debugPrint('[SyncEngine] Verification check error for $col: $e');
        }
      }

      _recentPushedKeys.clear();
      _lastSyncTime = null;
      debugPrint('[SyncEngine] Remote user data purge successfully completed for all collections.');
      return true;
    } catch (e) {
      debugPrint('[SyncEngine] purgeRemoteUserData failed: $e');
      return false;
    } finally {
      _isSyncing = false;
      // Re-enable realtime listener with clean state
      if (_client.isAuthenticated) {
        startRealtimeListener(force: true);
      }
    }
  }

  /// Helper to purge a collection using PocketBase batch API with high-speed concurrent fallback
  Future<void> _purgeCollectionBatch(
    String collectionName,
    String userId, {
    void Function(String status)? onProgress,
  }) async {
    try {
      final remoteRecords = await _pb.collection(collectionName).getFullList(
        filter: 'user = "$userId"',
      );
      debugPrint('[SyncEngine] Found ${remoteRecords.length} records in $collectionName to purge.');
      if (remoteRecords.isEmpty) return;

      // Optimized batch size for PocketBase (configured to 200 on server)
      const batchChunkSize = 100;
      const parallelPoolSize = 25;

      int processed = 0;
      for (int i = 0; i < remoteRecords.length; i += batchChunkSize) {
        final chunk = remoteRecords.skip(i).take(batchChunkSize).toList();
        bool batchSucceeded = false;

        if (_batchSupported) {
          try {
            final batch = _pb.createBatch();
            for (final item in chunk) {
              batch.collection(collectionName).delete(item.id);
            }
            await batch.send();
            batchSucceeded = true;
            debugPrint('[SyncEngine] Batch deleted ${chunk.length} items from $collectionName');
          } catch (batchErr) {
            final errStr = batchErr.toString();
            if (errStr.contains('403') || errStr.toLowerCase().contains('batch requests are not allowed')) {
              _batchSupported = false;
              debugPrint('[SyncEngine] PocketBase Batch API disabled on server. Switching to 25-worker concurrent pool.');
            } else {
              debugPrint('[SyncEngine] Batch delete failed for $collectionName: $batchErr. Falling back to concurrent pool...');
            }
          }
        }

        if (!batchSucceeded) {
          for (int p = 0; p < chunk.length; p += parallelPoolSize) {
            final pool = chunk.skip(p).take(parallelPoolSize).toList();
            await Future.wait(pool.map((item) async {
              try {
                await _pb.collection(collectionName).delete(item.id);
              } catch (err) {
                debugPrint('[SyncEngine] Parallel delete failed for $collectionName item ${item.id}: $err');
              }
            }));
          }
        }

        processed += chunk.length;
        onProgress?.call('Siliniyor: $collectionName ($processed / ${remoteRecords.length})...');
      }
    } catch (e) {
      debugPrint('[SyncEngine] Error querying $collectionName to purge: $e');
    }
  }
}
