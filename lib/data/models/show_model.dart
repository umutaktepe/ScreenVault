/// Represents a TV Show in Screen Vault
class ShowModel {
  final int id;
  final int? tmdbId;
  final int? tvdbId;
  final String name;
  final String? originalName;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? status;
  final int totalSeasons;
  final int totalEpisodes;
  final List<String> genres;
  final bool isFollowed;
  final int watchedEpisodesCount;
  final double voteAverage;
  final DateTime? firstAirDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShowModel({
    required this.id,
    this.tmdbId,
    this.tvdbId,
    required this.name,
    this.originalName,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.status,
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
    this.genres = const [],
    this.isFollowed = false,
    this.watchedEpisodesCount = 0,
    this.voteAverage = 0.0,
    this.firstAirDate,
    this.createdAt,
    this.updatedAt,
  });

  int get remainingEpisodes => (totalEpisodes - watchedEpisodesCount).clamp(0, totalEpisodes);
  double get progress => totalEpisodes > 0 ? (watchedEpisodesCount / totalEpisodes).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => totalEpisodes > 0 && watchedEpisodesCount >= totalEpisodes;

  ShowModel copyWith({
    int? id,
    int? tmdbId,
    int? tvdbId,
    String? name,
    String? originalName,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? status,
    int? totalSeasons,
    int? totalEpisodes,
    List<String>? genres,
    bool? isFollowed,
    int? watchedEpisodesCount,
    double? voteAverage,
    DateTime? firstAirDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShowModel(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      tvdbId: tvdbId ?? this.tvdbId,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      status: status ?? this.status,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      genres: genres ?? this.genres,
      isFollowed: isFollowed ?? this.isFollowed,
      watchedEpisodesCount: watchedEpisodesCount ?? this.watchedEpisodesCount,
      voteAverage: voteAverage ?? this.voteAverage,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'tvdb_id': tvdbId,
      'name': name,
      'original_name': originalName,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'status': status,
      'total_seasons': totalSeasons,
      'total_episodes': totalEpisodes,
      'genres': genres.join(','),
      'is_followed': isFollowed ? 1 : 0,
      'watched_episodes_count': watchedEpisodesCount,
      'vote_average': voteAverage,
      'first_air_date': firstAirDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ShowModel.fromMap(Map<String, dynamic> map) {
    return ShowModel(
      id: map['id'] as int? ?? 0,
      tmdbId: map['tmdb_id'] as int?,
      tvdbId: map['tvdb_id'] as int?,
      name: map['name'] as String? ?? '',
      originalName: map['original_name'] as String?,
      overview: map['overview'] as String?,
      posterPath: map['poster_path'] as String?,
      backdropPath: map['backdrop_path'] as String?,
      status: map['status'] as String?,
      totalSeasons: map['total_seasons'] as int? ?? 0,
      totalEpisodes: map['total_episodes'] as int? ?? 0,
      genres: (map['genres'] as String?)?.split(',').where((g) => g.isNotEmpty).toList() ?? [],
      isFollowed: (map['is_followed'] as int? ?? 0) == 1,
      watchedEpisodesCount: map['watched_episodes_count'] as int? ?? 0,
      voteAverage: (map['vote_average'] as num?)?.toDouble() ?? 0.0,
      firstAirDate: map['first_air_date'] != null ? DateTime.tryParse(map['first_air_date'] as String) : null,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }

  factory ShowModel.fromTmdbJson(Map<String, dynamic> json) {
    final genresList = (json['genres'] as List?)
            ?.map((g) => g is Map ? g['name']?.toString() ?? '' : g.toString())
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];

    final totalSeasons = json['number_of_seasons'] as int? ?? 0;
    final totalEpisodes = json['number_of_episodes'] as int? ?? 0;

    int? tvdbId;
    if (json['external_ids'] is Map) {
      tvdbId = (json['external_ids'] as Map)['tvdb_id'] as int?;
    }

    return ShowModel(
      id: json['id'] as int? ?? 0,
      tmdbId: json['id'] as int?,
      tvdbId: tvdbId,
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      originalName: json['original_name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      status: json['status'] as String?,
      totalSeasons: totalSeasons,
      totalEpisodes: totalEpisodes,
      genres: genresList,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      firstAirDate: json['first_air_date'] != null ? DateTime.tryParse(json['first_air_date'] as String) : null,
    );
  }
}
