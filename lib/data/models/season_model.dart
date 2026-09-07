/// Represents a Season of a TV Show
class SeasonModel {
  final int id;
  final int showId;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final int episodeCount;
  final DateTime? airDate;

  const SeasonModel({
    required this.id,
    required this.showId,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    this.episodeCount = 0,
    this.airDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'show_id': showId,
      'season_number': seasonNumber,
      'name': name,
      'overview': overview,
      'poster_path': posterPath,
      'episode_count': episodeCount,
      'air_date': airDate?.toIso8601String(),
    };
  }

  factory SeasonModel.fromMap(Map<String, dynamic> map) {
    return SeasonModel(
      id: map['id'] as int? ?? 0,
      showId: map['show_id'] as int? ?? 0,
      seasonNumber: map['season_number'] as int? ?? 0,
      name: map['name'] as String? ?? 'Season ${map['season_number']}',
      overview: map['overview'] as String?,
      posterPath: map['poster_path'] as String?,
      episodeCount: map['episode_count'] as int? ?? 0,
      airDate: map['air_date'] != null ? DateTime.tryParse(map['air_date'] as String) : null,
    );
  }

  factory SeasonModel.fromTmdbJson(Map<String, dynamic> json, int showId) {
    final sNum = json['season_number'] as int? ?? 0;
    final detId = showId > 0 ? (showId * 100 + sNum) : (json['id'] as int? ?? 0);
    return SeasonModel(
      id: detId,
      showId: showId,
      seasonNumber: sNum,
      name: json['name'] as String? ?? '$sNum. Sezon',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      episodeCount: json['episode_count'] as int? ?? 0,
      airDate: json['air_date'] != null ? DateTime.tryParse(json['air_date'] as String) : null,
    );
  }
}
