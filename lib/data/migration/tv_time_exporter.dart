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

    // 1. followed_tv_show.csv
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

    // 2. tracking-prod-records-v2.csv
    final trackingV2Csv = StringBuffer();
    trackingV2Csv.writeln('user_id,ep_no,runtime,gsi,bulk_type,created_at,ep_id,s_id,s_no,key,updated_at,ep_watch_count,total_movies_runtime,movie_watch_count,total_series_runtime,series_follow_count,is_for_later,is_archived,most_recent_ep_watched,followed_at,uuid,is_followed,is_unitary,rewatch_count,is_special,movie_name,series_name,season_number,episode_number');
    for (final s in shows) {
      final episodes = _dbService.getEpisodesForShow(s.id);
      for (final ep in episodes.where((e) => e.isWatched)) {
        final runtimeSec = ep.runtimeMinutes * 60;
        final date = ep.lastWatchedAt?.toIso8601String() ?? '2026-09-06 00:00:00';
        final seriesName = s.name.replaceAll('"', '""');
        trackingV2Csv.writeln('59986310,${ep.episodeNumber},$runtimeSec,watch-episode,season,$date,${ep.tvdbId ?? ep.id},${s.tvdbId ?? s.id},${ep.seasonNumber},,,,,,,,,,,,,,,${ep.rewatchCount},,"$seriesName",${ep.seasonNumber},${ep.episodeNumber}');
      }
    }
    final trackingBytes = utf8.encode(trackingV2Csv.toString());
    archive.addFile(ArchiveFile('tracking-prod-records-v2.csv', trackingBytes.length, trackingBytes));

    // 3. tracking-prod-records.csv (Movies)
    final moviesCsv = StringBuffer();
    moviesCsv.writeln(',,user_id,key,created_at,alpha,release_date,uuid,follow_date,media_type,release_timestamp,runtime,updated_at,action,,,,movie_title,,,');
    final movies = _dbService.getAllMovies();
    for (final m in movies) {
      final runtimeSec = m.runtimeMinutes * 60;
      final date = m.watchedAt?.toIso8601String() ?? '2026-09-06 00:00:00';
      final title = m.title.replaceAll('"', '""');
      moviesCsv.writeln(',,59986310,follow-$title,$date,,$date,,,$date,movie,$date,$runtimeSec,$date,follow,,,,,"$title",,,');
    }
    final moviesBytes = utf8.encode(moviesCsv.toString());
    archive.addFile(ArchiveFile('tracking-prod-records.csv', moviesBytes.length, moviesBytes));

    // 4. user_statistics.csv
    final stats = _dbService.getUserStats();
    final statsCsv = StringBuffer();
    statsCsv.writeln('created_at,nb_shows_followed,nb_episodes_watched,nb_friends,time_spent,nb_likes,nb_comments,user_id,score,id,nb_memes,nb_reviews,updated_at');
    statsCsv.writeln('2022-05-01 14:24:38,${stats.showsFollowedCount},${stats.episodesWatchedCount},1,${stats.totalWatchMinutes},0,0,59986310,0,59986310,0,0,2026-09-06 00:00:00');
    final statsBytes = utf8.encode(statsCsv.toString());
    archive.addFile(ArchiveFile('user_statistics.csv', statsBytes.length, statsBytes));

    // 5. friend.csv
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
