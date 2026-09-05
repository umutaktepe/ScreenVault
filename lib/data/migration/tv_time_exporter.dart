import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../database/database_service.dart';

/// Exports current database contents back into a valid TV Time gdpr-data.zip archive
class TvTimeExporter {
  final DatabaseService _dbService;

  TvTimeExporter({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  Future<File> exportToZip(String destinationPath) async {
    final archive = Archive();

    // 1. followed_tv_show.csv (11 columns)
    final shows = _dbService.getFollowedShows();
    final followedShowsCsv = StringBuffer();
    followedShowsCsv.writeln('tv_show_id,active,diffusion,notification_type,folder_id,archived,notification_offset,user_id,updated_at,tv_show_name,created_at');
    for (final s in shows) {
      final tvdbId = s.tvdbId ?? s.id;
      final name = s.name.replaceAll('"', '""');
      final date = s.createdAt?.toIso8601String() ?? '2026-09-06 00:00:00';
      followedShowsCsv.writeln('$tvdbId,1,original,2,,0,1440,59986310,$date,"$name",$date');
    }
    final followedBytes = utf8.encode(followedShowsCsv.toString());
    archive.addFile(ArchiveFile('followed_tv_show.csv', followedBytes.length, followedBytes));

    // 2. tracking-prod-records-v2.csv (29 columns)
    // Indexes:
    // 0: user_id, 1: ep_no, 2: runtime, 3: gsi, 4: bulk_type, 5: created_at, 6: ep_id, 7: s_id, 8: s_no
    // 9: key, 10: updated_at, 11: ep_watch_count, 12: total_movies_runtime, 13: movie_watch_count, 14: total_series_runtime
    // 15: series_follow_count, 16: is_for_later, 17: is_archived, 18: most_recent_ep_watched, 19: followed_at, 20: uuid
    // 21: is_followed, 22: is_unitary, 23: rewatch_count, 24: is_special, 25: movie_name, 26: series_name, 27: season_number, 28: episode_number
    final trackingV2Csv = StringBuffer();
    trackingV2Csv.writeln('user_id,ep_no,runtime,gsi,bulk_type,created_at,ep_id,s_id,s_no,key,updated_at,ep_watch_count,total_movies_runtime,movie_watch_count,total_series_runtime,series_follow_count,is_for_later,is_archived,most_recent_ep_watched,followed_at,uuid,is_followed,is_unitary,rewatch_count,is_special,movie_name,series_name,season_number,episode_number');
    for (final s in shows) {
      final episodes = _dbService.getEpisodesForShow(s.id);
      for (final ep in episodes.where((e) => e.isWatched)) {
        final runtimeSec = ep.runtimeMinutes * 60;
        final date = ep.lastWatchedAt?.toIso8601String() ?? '2026-09-06 00:00:00';
        final seriesName = s.name.replaceAll('"', '""');
        // Construct line matching exact 29 columns
        trackingV2Csv.writeln('59986310,${ep.episodeNumber},$runtimeSec,watch-episode,season,$date,${ep.tvdbId ?? ep.id},${s.tvdbId ?? s.id},${ep.seasonNumber},,$date,1,,,,,,,,,,,,${ep.rewatchCount},,,"$seriesName",${ep.seasonNumber},${ep.episodeNumber}');
      }
    }
    final trackingBytes = utf8.encode(trackingV2Csv.toString());
    archive.addFile(ArchiveFile('tracking-prod-records-v2.csv', trackingBytes.length, trackingBytes));

    // 3. tracking-prod-records.csv (Movies - 22 columns)
    // 0: watch_count, 1: watches, 2: user_id, 3: type-uuid-n, 4: created_at, 5: alpha_range_key
    // 6: release_date_range_key, 7: uuid, 8: follow_date_range_key, 9: entity_type, 10: release_date
    // 11: runtime, 12: updated_at, 13: type, 14: rewatch_count, 15: total_movies_runtime, 16: country
    // 17: watch_date_range_key, 18: movie_name, 19: series_name, 20: season_number, 21: episode_number
    final moviesCsv = StringBuffer();
    moviesCsv.writeln('watch_count,watches,user_id,type-uuid-n,created_at,alpha_range_key,release_date_range_key,uuid,follow_date_range_key,entity_type,release_date,runtime,updated_at,type,rewatch_count,total_movies_runtime,country,watch_date_range_key,movie_name,series_name,season_number,episode_number');
    final movies = _dbService.getAllMovies();
    for (final m in movies) {
      final runtimeSec = m.runtimeMinutes * 60;
      final date = m.watchedAt?.toIso8601String() ?? '2026-09-06 00:00:00';
      final title = m.title.replaceAll('"', '""');
      moviesCsv.writeln('1,,59986310,follow-$title,$date,,,,,movie,$date,$runtimeSec,$date,follow,${m.rewatchCount},,,,"$title",,,');
    }
    final moviesBytes = utf8.encode(moviesCsv.toString());
    archive.addFile(ArchiveFile('tracking-prod-records.csv', moviesBytes.length, moviesBytes));

    // 4. user_statistics.csv (13 columns)
    final stats = _dbService.getUserStats();
    final statsCsv = StringBuffer();
    statsCsv.writeln('created_at,nb_shows_followed,nb_episodes_watched,nb_friends,time_spent,nb_likes,nb_comments,user_id,score,id,nb_memes,nb_reviews,updated_at');
    statsCsv.writeln('2022-05-01 14:24:38,${stats.showsFollowedCount},${stats.episodesWatchedCount},1,${stats.totalWatchMinutes},0,0,59986310,0,59986310,0,0,2026-09-06 00:00:00');
    final statsBytes = utf8.encode(statsCsv.toString());
    archive.addFile(ArchiveFile('user_statistics.csv', statsBytes.length, statsBytes));

    // 5. friend.csv (5 columns)
    final friendsCsv = StringBuffer();
    friendsCsv.writeln('friend_id,created_at,updated_at,affinity,user_id');
    final friends = _dbService.getFriends();
    for (final f in friends) {
      friendsCsv.writeln('${f.friendId},2024-06-13 10:18:38,2024-06-13 10:18:38,${f.affinity},59986310');
    }
    final friendsBytes = utf8.encode(friendsCsv.toString());
    archive.addFile(ArchiveFile('friend.csv', friendsBytes.length, friendsBytes));

    // Encode to ZIP format
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    if (zipData == null) {
      throw Exception('Failed to encode ZIP archive');
    }

    final targetFile = File(destinationPath);
    await targetFile.writeAsBytes(zipData);
    return targetFile;
  }
}
