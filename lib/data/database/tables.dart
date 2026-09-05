import 'package:drift/drift.dart';

/// Shows Table definition in Drift
class ShowsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbId => integer().nullable()();
  IntColumn get tvdbId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get originalName => text().nullable()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();
  TextColumn get status => text().nullable()();
  IntColumn get totalSeasons => integer().withDefault(const Constant(0))();
  IntColumn get totalEpisodes => integer().withDefault(const Constant(0))();
  TextColumn get genres => text().withDefault(const Constant(''))();
  BoolColumn get isFollowed => boolean().withDefault(const Constant(false))();
  IntColumn get watchedEpisodesCount => integer().withDefault(const Constant(0))();
  RealColumn get voteAverage => real().withDefault(const Constant(0.0))();
  DateTimeColumn get firstAirDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {tmdbId},
        {tvdbId},
      ];
}

/// Seasons Table definition in Drift
class SeasonsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get showId => integer()();
  IntColumn get seasonNumber => integer()();
  TextColumn get name => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  IntColumn get episodeCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get airDate => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {showId, seasonNumber},
      ];
}

/// Episodes Table definition in Drift
class EpisodesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get showId => integer()();
  IntColumn get seasonId => integer()();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeNumber => integer()();
  IntColumn get tvdbId => integer().nullable()();
  IntColumn get tmdbId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get stillPath => text().nullable()();
  IntColumn get runtimeMinutes => integer().withDefault(const Constant(0))();
  DateTimeColumn get airDate => dateTime().nullable()();
  RealColumn get voteAverage => real().withDefault(const Constant(0.0))();
  BoolColumn get isWatched => boolean().withDefault(const Constant(false))();
  IntColumn get rewatchCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastWatchedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {showId, seasonNumber, episodeNumber},
        {tvdbId},
      ];
}

/// Episode Watch History Table definition in Drift
class EpisodeWatchHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get episodeId => integer().nullable()();
  IntColumn get showId => integer().nullable()();
  IntColumn get tvdbId => integer().nullable()();
  IntColumn get sId => integer().nullable()(); // TVDB Series ID
  IntColumn get seasonNumber => integer().withDefault(const Constant(0))();
  IntColumn get episodeNumber => integer().withDefault(const Constant(0))();
  TextColumn get title => text()();
  IntColumn get runtimeMinutes => integer().withDefault(const Constant(0))();
  DateTimeColumn get watchedAt => dateTime()();
  IntColumn get rewatchCount => integer().withDefault(const Constant(0))();
}

/// Movies Table definition in Drift
class MoviesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbId => integer().nullable()();
  TextColumn get imdbId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();
  DateTimeColumn get releaseDate => dateTime().nullable()();
  IntColumn get runtimeMinutes => integer().withDefault(const Constant(0))();
  TextColumn get genres => text().withDefault(const Constant(''))();
  BoolColumn get isWatched => boolean().withDefault(const Constant(false))();
  BoolColumn get isFollowed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get watchedAt => dateTime().nullable()();
  IntColumn get rewatchCount => integer().withDefault(const Constant(0))();
  RealColumn get voteAverage => real().withDefault(const Constant(0.0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {tmdbId},
      ];
}

/// Movie Watch History Table definition in Drift
class MovieWatchHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get movieId => integer().nullable()();
  IntColumn get tmdbId => integer().nullable()();
  TextColumn get title => text()();
  IntColumn get runtimeMinutes => integer().withDefault(const Constant(0))();
  DateTimeColumn get watchedAt => dateTime()();
  IntColumn get rewatchCount => integer().withDefault(const Constant(0))();
}

/// Import Queue Table for TV Time migration background worker
class ImportQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tvdbId => integer().nullable()();
  IntColumn get tmdbId => integer().nullable()();
  TextColumn get mediaType => text()(); // 'tv' or 'movie'
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, completed, failed
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
