/// Represents an episode or movie watch event
class WatchRecordModel {
  final int id;
  final int? episodeId;
  final int? showId;
  final int? movieId;
  final int? tvdbId;
  final int? sId; // TVDB Series ID
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final int runtimeMinutes;
  final DateTime watchedAt;
  final int rewatchCount;
  final bool isMovie;

  const WatchRecordModel({
    required this.id,
    this.episodeId,
    this.showId,
    this.movieId,
    this.tvdbId,
    this.sId,
    this.seasonNumber = 0,
    this.episodeNumber = 0,
    required this.title,
    required this.runtimeMinutes,
    required this.watchedAt,
    this.rewatchCount = 0,
    this.isMovie = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'episode_id': episodeId,
      'show_id': showId,
      'movie_id': movieId,
      'tvdb_id': tvdbId,
      's_id': sId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'title': title,
      'runtime_minutes': runtimeMinutes,
      'watched_at': watchedAt.toIso8601String(),
      'rewatch_count': rewatchCount,
      'is_movie': isMovie ? 1 : 0,
    };
  }

  factory WatchRecordModel.fromMap(Map<String, dynamic> map) {
    return WatchRecordModel(
      id: map['id'] as int? ?? 0,
      episodeId: map['episode_id'] as int?,
      showId: map['show_id'] as int?,
      movieId: map['movie_id'] as int?,
      tvdbId: map['tvdb_id'] as int?,
      sId: map['s_id'] as int?,
      seasonNumber: map['season_number'] as int? ?? 0,
      episodeNumber: map['episode_number'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      runtimeMinutes: map['runtime_minutes'] as int? ?? 0,
      watchedAt: DateTime.tryParse(map['watched_at'] as String? ?? '') ?? DateTime.now(),
      rewatchCount: map['rewatch_count'] as int? ?? 0,
      isMovie: (map['is_movie'] as int? ?? 0) == 1,
    );
  }
}
