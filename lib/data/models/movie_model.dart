/// Represents a Movie in Screen Vault
class MovieModel {
  final int id;
  final int? tmdbId;
  final String? imdbId;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final DateTime? releaseDate;
  final int runtimeMinutes;
  final List<String> genres;
  final bool isWatched;
  final bool isFollowed;
  final DateTime? watchedAt;
  final int rewatchCount;
  final double voteAverage;

  const MovieModel({
    required this.id,
    this.tmdbId,
    this.imdbId,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.runtimeMinutes = 0,
    this.genres = const [],
    this.isWatched = false,
    this.isFollowed = false,
    this.watchedAt,
    this.rewatchCount = 0,
    this.voteAverage = 0.0,
  });

  MovieModel copyWith({
    int? id,
    int? tmdbId,
    String? imdbId,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    DateTime? releaseDate,
    int? runtimeMinutes,
    List<String>? genres,
    bool? isWatched,
    bool? isFollowed,
    DateTime? watchedAt,
    int? rewatchCount,
    double? voteAverage,
  }) {
    return MovieModel(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      imdbId: imdbId ?? this.imdbId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      releaseDate: releaseDate ?? this.releaseDate,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      genres: genres ?? this.genres,
      isWatched: isWatched ?? this.isWatched,
      isFollowed: isFollowed ?? this.isFollowed,
      watchedAt: watchedAt ?? this.watchedAt,
      rewatchCount: rewatchCount ?? this.rewatchCount,
      voteAverage: voteAverage ?? this.voteAverage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'imdb_id': imdbId,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate?.toIso8601String(),
      'runtime_minutes': runtimeMinutes,
      'genres': genres.join(','),
      'is_watched': isWatched ? 1 : 0,
      'is_followed': isFollowed ? 1 : 0,
      'watched_at': watchedAt?.toIso8601String(),
      'rewatch_count': rewatchCount,
      'vote_average': voteAverage,
    };
  }

  factory MovieModel.fromMap(Map<String, dynamic> map) {
    return MovieModel(
      id: map['id'] as int? ?? 0,
      tmdbId: map['tmdb_id'] as int?,
      imdbId: map['imdb_id'] as String?,
      title: map['title'] as String? ?? '',
      overview: map['overview'] as String?,
      posterPath: map['poster_path'] as String?,
      backdropPath: map['backdrop_path'] as String?,
      releaseDate: map['release_date'] != null ? DateTime.tryParse(map['release_date'] as String) : null,
      runtimeMinutes: map['runtime_minutes'] as int? ?? 0,
      genres: (map['genres'] as String?)?.split(',').where((g) => g.isNotEmpty).toList() ?? [],
      isWatched: (map['is_watched'] as int? ?? 0) == 1,
      isFollowed: (map['is_followed'] as int? ?? 0) == 1,
      watchedAt: map['watched_at'] != null ? DateTime.tryParse(map['watched_at'] as String) : null,
      rewatchCount: map['rewatch_count'] as int? ?? 0,
      voteAverage: (map['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory MovieModel.fromTmdbJson(Map<String, dynamic> json) {
    final genresList = (json['genres'] as List?)
            ?.map((g) => g is Map ? g['name']?.toString() ?? '' : g.toString())
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];

    return MovieModel(
      id: json['id'] as int? ?? 0,
      tmdbId: json['id'] as int?,
      imdbId: json['imdb_id'] as String?,
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] != null ? DateTime.tryParse(json['release_date'] as String) : null,
      runtimeMinutes: json['runtime'] as int? ?? 0,
      genres: genresList,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
