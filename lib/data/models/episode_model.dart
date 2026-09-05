/// Represents a TV Episode
class EpisodeModel {
  final int id;
  final int showId;
  final int seasonId;
  final int seasonNumber;
  final int episodeNumber;
  final int? tvdbId;
  final int? tmdbId;
  final String name;
  final String? overview;
  final String? stillPath;
  final int runtimeMinutes;
  final DateTime? airDate;
  final double voteAverage;
  final bool isWatched;
  final int rewatchCount;
  final DateTime? lastWatchedAt;

  const EpisodeModel({
    required this.id,
    required this.showId,
    required this.seasonId,
    required this.seasonNumber,
    required this.episodeNumber,
    this.tvdbId,
    this.tmdbId,
    required this.name,
    this.overview,
    this.stillPath,
    this.runtimeMinutes = 0,
    this.airDate,
    this.voteAverage = 0.0,
    this.isWatched = false,
    this.rewatchCount = 0,
    this.lastWatchedAt,
  });

  /// Standard code format: S02 · E03
  String get code => 'S${seasonNumber.toString().padLeft(2, '0')} · E${episodeNumber.toString().padLeft(2, '0')}';
  String get compactCode => 'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';

  EpisodeModel copyWith({
    int? id,
    int? showId,
    int? seasonId,
    int? seasonNumber,
    int? episodeNumber,
    int? tvdbId,
    int? tmdbId,
    String? name,
    String? overview,
    String? stillPath,
    int? runtimeMinutes,
    DateTime? airDate,
    double? voteAverage,
    bool? isWatched,
    int? rewatchCount,
    DateTime? lastWatchedAt,
  }) {
    return EpisodeModel(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      seasonId: seasonId ?? this.seasonId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      tvdbId: tvdbId ?? this.tvdbId,
      tmdbId: tmdbId ?? this.tmdbId,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      stillPath: stillPath ?? this.stillPath,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      airDate: airDate ?? this.airDate,
      voteAverage: voteAverage ?? this.voteAverage,
      isWatched: isWatched ?? this.isWatched,
      rewatchCount: rewatchCount ?? this.rewatchCount,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'show_id': showId,
      'season_id': seasonId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'tvdb_id': tvdbId,
      'tmdb_id': tmdbId,
      'name': name,
      'overview': overview,
      'still_path': stillPath,
      'runtime_minutes': runtimeMinutes,
      'air_date': airDate?.toIso8601String(),
      'vote_average': voteAverage,
      'is_watched': isWatched ? 1 : 0,
      'rewatch_count': rewatchCount,
      'last_watched_at': lastWatchedAt?.toIso8601String(),
    };
  }

  factory EpisodeModel.fromMap(Map<String, dynamic> map) {
    return EpisodeModel(
      id: map['id'] as int? ?? 0,
      showId: map['show_id'] as int? ?? 0,
      seasonId: map['season_id'] as int? ?? 0,
      seasonNumber: map['season_number'] as int? ?? 0,
      episodeNumber: map['episode_number'] as int? ?? 0,
      tvdbId: map['tvdb_id'] as int?,
      tmdbId: map['tmdb_id'] as int?,
      name: map['name'] as String? ?? 'Episode ${map['episode_number']}',
      overview: map['overview'] as String?,
      stillPath: map['still_path'] as String?,
      runtimeMinutes: map['runtime_minutes'] as int? ?? 0,
      airDate: map['air_date'] != null ? DateTime.tryParse(map['air_date'] as String) : null,
      voteAverage: (map['vote_average'] as num?)?.toDouble() ?? 0.0,
      isWatched: (map['is_watched'] as int? ?? 0) == 1,
      rewatchCount: map['rewatch_count'] as int? ?? 0,
      lastWatchedAt: map['last_watched_at'] != null ? DateTime.tryParse(map['last_watched_at'] as String) : null,
    );
  }

  factory EpisodeModel.fromTmdbJson(Map<String, dynamic> json, int showId, int seasonId) {
    return EpisodeModel(
      id: json['id'] as int? ?? 0,
      showId: showId,
      seasonId: seasonId,
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      tmdbId: json['id'] as int?,
      name: json['name'] as String? ?? 'Episode ${json['episode_number']}',
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      runtimeMinutes: json['runtime'] as int? ?? 0,
      airDate: json['air_date'] != null ? DateTime.tryParse(json['air_date'] as String) : null,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
