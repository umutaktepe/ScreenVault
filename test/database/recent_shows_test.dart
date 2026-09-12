import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/data/models/watch_record_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  test('getRecentlyActiveFollowedShows sorts shows by most recent watch activity', () async {
    final show1 = ShowModel(id: 1, name: 'Show A', isFollowed: true, totalEpisodes: 10);
    final show2 = ShowModel(id: 2, name: 'Show B', isFollowed: true, totalEpisodes: 10);
    final show3 = ShowModel(id: 3, name: 'Show C', isFollowed: true, totalEpisodes: 10);
    final showUnfollowed = ShowModel(id: 4, name: 'Show D', isFollowed: false);

    await db.upsertShow(show1);
    await db.upsertShow(show2);
    await db.upsertShow(show3);
    await db.upsertShow(showUnfollowed);

    // Show 2 watched 2 hours ago
    await db.insertWatchRecord(WatchRecordModel(
      id: 101,
      showId: 2,
      seasonNumber: 1,
      episodeNumber: 1,
      title: 'Ep 1',
      runtimeMinutes: 45,
      watchedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ));

    // Show 1 watched 10 minutes ago (most recent)
    await db.insertWatchRecord(WatchRecordModel(
      id: 102,
      showId: 1,
      seasonNumber: 1,
      episodeNumber: 1,
      title: 'Ep 1',
      runtimeMinutes: 45,
      watchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ));

    final recent = db.getRecentlyActiveFollowedShows(limit: 2);
    expect(recent.length, 2);
    expect(recent[0].id, 1, reason: 'Show 1 watched most recently');
    expect(recent[1].id, 2, reason: 'Show 2 watched second most recently');
  });

  test('getRecentlyActiveFollowedShows places unwatched shows after watched ones and respects limit', () async {
    final showWatched = ShowModel(id: 10, name: 'Watched', isFollowed: true);
    final showUnwatched1 = ShowModel(id: 20, name: 'Unwatched 1', isFollowed: true, updatedAt: DateTime(2025, 1, 1));
    final showUnwatched2 = ShowModel(id: 30, name: 'Unwatched 2', isFollowed: true, updatedAt: DateTime(2025, 2, 1));

    await db.upsertShow(showWatched);
    await db.upsertShow(showUnwatched1);
    await db.upsertShow(showUnwatched2);

    await db.insertWatchRecord(WatchRecordModel(
      id: 201,
      showId: 10,
      seasonNumber: 1,
      episodeNumber: 1,
      title: 'Ep 1',
      runtimeMinutes: 45,
      watchedAt: DateTime.now(),
    ));

    final recent = db.getRecentlyActiveFollowedShows();
    expect(recent.map((s) => s.id).toList(), [10, 30, 20]);

    final limited = db.getRecentlyActiveFollowedShows(limit: 2);
    expect(limited.length, 2);
    expect(limited.map((s) => s.id).toList(), [10, 30]);
  });
}
