enum UnresolvedItemType { show, movie }

/// Model representing a show or movie imported from TV Time that could not
/// be automatically resolved with TMDB metadata or posters.
class UnresolvedItemModel {
  final int id;
  final UnresolvedItemType type;
  final String rawTitle;
  final int? tvdbId;
  final int watchedEpisodesCount;
  final int runtimeMinutes;
  final String? seasonsInfo;
  final DateTime? lastWatchedAt;
  final String? posterPath;
  final int? releaseYear;

  const UnresolvedItemModel({
    required this.id,
    required this.type,
    required this.rawTitle,
    this.tvdbId,
    this.watchedEpisodesCount = 0,
    this.runtimeMinutes = 0,
    this.seasonsInfo,
    this.lastWatchedAt,
    this.posterPath,
    this.releaseYear,
  });

  UnresolvedItemModel copyWith({
    int? id,
    UnresolvedItemType? type,
    String? rawTitle,
    int? tvdbId,
    int? watchedEpisodesCount,
    int? runtimeMinutes,
    String? seasonsInfo,
    DateTime? lastWatchedAt,
    String? posterPath,
    int? releaseYear,
  }) {
    return UnresolvedItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      rawTitle: rawTitle ?? this.rawTitle,
      tvdbId: tvdbId ?? this.tvdbId,
      watchedEpisodesCount: watchedEpisodesCount ?? this.watchedEpisodesCount,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      seasonsInfo: seasonsInfo ?? this.seasonsInfo,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      posterPath: posterPath ?? this.posterPath,
      releaseYear: releaseYear ?? this.releaseYear,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'rawTitle': rawTitle,
      'tvdbId': tvdbId,
      'watchedEpisodesCount': watchedEpisodesCount,
      'runtimeMinutes': runtimeMinutes,
      'seasonsInfo': seasonsInfo,
      'lastWatchedAt': lastWatchedAt?.toIso8601String(),
      'posterPath': posterPath,
      'releaseYear': releaseYear,
    };
  }

  factory UnresolvedItemModel.fromMap(Map<String, dynamic> map) {
    return UnresolvedItemModel(
      id: map['id'] as int,
      type: (map['type'] as String?) == 'movie'
          ? UnresolvedItemType.movie
          : UnresolvedItemType.show,
      rawTitle: map['rawTitle'] as String? ?? '',
      tvdbId: map['tvdbId'] as int?,
      watchedEpisodesCount: map['watchedEpisodesCount'] as int? ?? 0,
      runtimeMinutes: map['runtimeMinutes'] as int? ?? 0,
      seasonsInfo: map['seasonsInfo'] as String?,
      lastWatchedAt: map['lastWatchedAt'] != null
          ? DateTime.tryParse(map['lastWatchedAt'] as String)
          : null,
      posterPath: map['posterPath'] as String?,
      releaseYear: map['releaseYear'] as int?,
    );
  }

  @override
  String toString() {
    return 'UnresolvedItemModel(id: $id, type: $type, rawTitle: $rawTitle, tvdbId: $tvdbId, watchedEpisodes: $watchedEpisodesCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnresolvedItemModel &&
        other.id == id &&
        other.type == type &&
        other.rawTitle == rawTitle;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ rawTitle.hashCode;
}
