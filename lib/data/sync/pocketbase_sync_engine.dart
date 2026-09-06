import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../core/network/pocketbase_client.dart';
import '../models/friend_model.dart';
import '../models/show_model.dart';
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

  bool _isSubscribed = false;

  /// Initializes the sync engine and listens to auth changes.
  void initialize() {
    _client.authStateStream.listen((event) {
      if (event.token.isNotEmpty && _client.isAuthenticated) {
        startRealtimeListener();
        // Background sync on login
        syncAll().catchError((e) {
          debugPrint('[SyncEngine] Background sync error on login: $e');
          return const SyncResult(success: false);
        });
      } else {
        stopRealtimeListener();
      }
    });

    if (_client.isAuthenticated) {
      startRealtimeListener();
    }
  }

  /// Full bi-directional sync between SQLite and PocketBase.
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

      // 1. Download watch history from PocketBase
      final remoteRecords = await _pb.collection('watch_history').getFullList(
        filter: 'user = "${user.id}"',
      );

      final localHistory = _dbService.getAllWatchRecords();
      final localKeys = <String>{};
      for (final r in localHistory) {
        localKeys.add('${r.showId ?? r.tvdbId}_${r.seasonNumber}_${r.episodeNumber}');
      }

      // Merge remote records into local database
      for (final item in remoteRecords) {
        final showId = (item.getIntValue('showId') > 0)
            ? item.getIntValue('showId')
            : item.getIntValue('tvdbId');
        final sNum = item.getIntValue('seasonNumber');
        final epNum = item.getIntValue('episodeNumber');
        final key = '${showId}_${sNum}_$epNum';

        if (!localKeys.contains(key)) {
          // New record from cloud -> save locally
          final dateStr = item.getStringValue('watchedAt');
          final watchedDate = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

          final newRecord = WatchRecordModel(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + downloaded,
            showId: showId,
            tvdbId: item.getIntValue('tvdbId'),
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
          downloaded++;
        }
      }

      // 2. Upload local history records that are not in PocketBase
      final remoteKeys = <String>{};
      for (final item in remoteRecords) {
        final sId = item.getIntValue('showId') > 0 ? item.getIntValue('showId') : item.getIntValue('tvdbId');
        remoteKeys.add('${sId}_${item.getIntValue('seasonNumber')}_${item.getIntValue('episodeNumber')}');
      }

      for (final local in localHistory) {
        final sId = local.showId ?? local.tvdbId ?? local.sId ?? 0;
        final key = '${sId}_${local.seasonNumber}_${local.episodeNumber}';

        if (!remoteKeys.contains(key)) {
          try {
            await _pb.collection('watch_history').create(body: {
              'user': user.id,
              'showId': sId,
              'tvdbId': local.tvdbId ?? local.sId ?? 0,
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
            debugPrint('[SyncEngine] Error uploading record: $e');
          }
        }
      }

      _lastSyncTime = DateTime.now();
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

    final sId = record.showId ?? record.tvdbId ?? record.sId ?? 0;
    final sNum = record.seasonNumber;
    final epNum = record.episodeNumber;

    try {
      if (isWatched) {
        // Check if record already exists on PocketBase
        final existing = await _pb.collection('watch_history').getList(
          page: 1,
          perPage: 1,
          filter: 'user = "${user.id}" && (showId = $sId || tvdbId = $sId) && seasonNumber = $sNum && episodeNumber = $epNum',
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
            'showId': sId,
            'tvdbId': record.tvdbId ?? record.sId ?? 0,
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
        // Delete or unmark
        final existing = await _pb.collection('watch_history').getList(
          page: 1,
          perPage: 1,
          filter: 'user = "${user.id}" && (showId = $sId || tvdbId = $sId) && seasonNumber = $sNum && episodeNumber = $epNum',
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
  Future<void> pushTrackedShow(ShowModel show, {String status = 'watching'}) async {
    if (!_client.isAuthenticated) return;
    final user = _client.currentUser;
    if (user == null) return;

    try {
      final existing = await _pb.collection('tracked_shows').getList(
        page: 1,
        perPage: 1,
        filter: 'user = "${user.id}" && (showId = ${show.id} || tmdbId = ${show.tmdbId ?? 0})',
      );

      if (existing.items.isNotEmpty) {
        await _pb.collection('tracked_shows').update(existing.items.first.id, body: {
          'status': status,
          'title': show.name,
          'posterPath': show.posterPath,
        });
      } else {
        await _pb.collection('tracked_shows').create(body: {
          'user': user.id,
          'showId': show.id,
          'tvdbId': show.tvdbId ?? 0,
          'tmdbId': show.tmdbId ?? 0,
          'title': show.name,
          'posterPath': show.posterPath,
          'status': status,
          'isFavorite': false,
        });
      }
    } catch (e) {
      debugPrint('[SyncEngine] pushTrackedShow error: $e');
    }
  }

  /// Starts real-time SSE listener for multi-device sync
  void startRealtimeListener() {
    if (_isSubscribed || !_client.isAuthenticated) return;

    try {
      _pb.collection('watch_history').subscribe('*', (e) {
        debugPrint('[SyncEngine] Realtime event received: ${e.action}');
        final record = e.record;
        if (record == null) return;

        final user = _client.currentUser;
        if (user == null || record.getStringValue('user') != user.id) return;

        final sId = record.getIntValue('showId') > 0 ? record.getIntValue('showId') : record.getIntValue('tvdbId');
        final sNum = record.getIntValue('seasonNumber');
        final epNum = record.getIntValue('episodeNumber');

        if (e.action == 'delete') {
          _dbService.removeWatchRecord(showId: sId, seasonNumber: sNum, episodeNumber: epNum);
        } else if (e.action == 'create' || e.action == 'update') {
          final isWatched = record.getBoolValue('isWatched');
          if (isWatched) {
            final dateStr = record.getStringValue('watchedAt');
            final watchedDate = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

            _dbService.insertWatchRecord(WatchRecordModel(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              showId: sId,
              tvdbId: record.getIntValue('tvdbId'),
              seasonNumber: sNum,
              episodeNumber: epNum,
              title: record.getStringValue('episodeTitle').isNotEmpty
                  ? record.getStringValue('episodeTitle')
                  : '$epNum. Bölüm',
              runtimeMinutes: record.getIntValue('runtimeMinutes'),
              watchedAt: watchedDate,
              rewatchCount: record.getIntValue('rewatchCount') > 0 ? record.getIntValue('rewatchCount') : 1,
            ));
          } else {
            _dbService.removeWatchRecord(showId: sId, seasonNumber: sNum, episodeNumber: epNum);
          }
        }
      });
      _isSubscribed = true;
      debugPrint('[SyncEngine] Subscribed to realtime watch_history events');
    } catch (e) {
      debugPrint('[SyncEngine] Failed to subscribe to realtime: $e');
    }
  }

  /// Stops real-time listener
  void stopRealtimeListener() {
    if (!_isSubscribed) return;
    try {
      _pb.collection('watch_history').unsubscribe('*');
      _isSubscribed = false;
      debugPrint('[SyncEngine] Unsubscribed from realtime watch_history');
    } catch (e) {
      debugPrint('[SyncEngine] Unsubscribe error: $e');
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

    final userName = user.getStringValue('name').isNotEmpty ? user.getStringValue('name') : user.getStringValue('email');
    final avatar = user.getStringValue('avatar');
    final avatarUrl = avatar.isNotEmpty ? '${_client.serverUrl}/api/files/${user.collectionId}/${user.id}/$avatar' : '';

    await _pb.collection('comments').create(body: {
      'user': user.id,
      'userName': userName,
      'userAvatar': avatarUrl,
      'showTitle': showTitle,
      'episodeCode': episodeCode,
      'showId': showId,
      'seasonNumber': seasonNumber ?? 1,
      'episodeNumber': episodeNumber ?? 1,
      'content': content.trim(),
      'isSpoiler': isSpoiler,
      'emotion': emotion,
      'likesCount': 0,
    });
  }
}
