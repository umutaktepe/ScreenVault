// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ShowsTableTable extends ShowsTable
    with TableInfo<$ShowsTableTable, ShowsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShowsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvdbIdMeta = const VerificationMeta('tvdbId');
  @override
  late final GeneratedColumn<int> tvdbId = GeneratedColumn<int>(
    'tvdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropPathMeta = const VerificationMeta(
    'backdropPath',
  );
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
    'backdrop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalSeasonsMeta = const VerificationMeta(
    'totalSeasons',
  );
  @override
  late final GeneratedColumn<int> totalSeasons = GeneratedColumn<int>(
    'total_seasons',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalEpisodesMeta = const VerificationMeta(
    'totalEpisodes',
  );
  @override
  late final GeneratedColumn<int> totalEpisodes = GeneratedColumn<int>(
    'total_episodes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isFollowedMeta = const VerificationMeta(
    'isFollowed',
  );
  @override
  late final GeneratedColumn<bool> isFollowed = GeneratedColumn<bool>(
    'is_followed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_followed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _watchedEpisodesCountMeta =
      const VerificationMeta('watchedEpisodesCount');
  @override
  late final GeneratedColumn<int> watchedEpisodesCount = GeneratedColumn<int>(
    'watched_episodes_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _voteAverageMeta = const VerificationMeta(
    'voteAverage',
  );
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
    'vote_average',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _firstAirDateMeta = const VerificationMeta(
    'firstAirDate',
  );
  @override
  late final GeneratedColumn<DateTime> firstAirDate = GeneratedColumn<DateTime>(
    'first_air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tmdbId,
    tvdbId,
    name,
    originalName,
    overview,
    posterPath,
    backdropPath,
    status,
    totalSeasons,
    totalEpisodes,
    genres,
    isFollowed,
    watchedEpisodesCount,
    voteAverage,
    firstAirDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shows_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShowsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('tvdb_id')) {
      context.handle(
        _tvdbIdMeta,
        tvdbId.isAcceptableOrUnknown(data['tvdb_id']!, _tvdbIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
        _backdropPathMeta,
        backdropPath.isAcceptableOrUnknown(
          data['backdrop_path']!,
          _backdropPathMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('total_seasons')) {
      context.handle(
        _totalSeasonsMeta,
        totalSeasons.isAcceptableOrUnknown(
          data['total_seasons']!,
          _totalSeasonsMeta,
        ),
      );
    }
    if (data.containsKey('total_episodes')) {
      context.handle(
        _totalEpisodesMeta,
        totalEpisodes.isAcceptableOrUnknown(
          data['total_episodes']!,
          _totalEpisodesMeta,
        ),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('is_followed')) {
      context.handle(
        _isFollowedMeta,
        isFollowed.isAcceptableOrUnknown(data['is_followed']!, _isFollowedMeta),
      );
    }
    if (data.containsKey('watched_episodes_count')) {
      context.handle(
        _watchedEpisodesCountMeta,
        watchedEpisodesCount.isAcceptableOrUnknown(
          data['watched_episodes_count']!,
          _watchedEpisodesCountMeta,
        ),
      );
    }
    if (data.containsKey('vote_average')) {
      context.handle(
        _voteAverageMeta,
        voteAverage.isAcceptableOrUnknown(
          data['vote_average']!,
          _voteAverageMeta,
        ),
      );
    }
    if (data.containsKey('first_air_date')) {
      context.handle(
        _firstAirDateMeta,
        firstAirDate.isAcceptableOrUnknown(
          data['first_air_date']!,
          _firstAirDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {tmdbId},
    {tvdbId},
  ];
  @override
  ShowsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShowsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      tvdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tvdb_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      backdropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      totalSeasons: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seasons'],
      )!,
      totalEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_episodes'],
      )!,
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      )!,
      isFollowed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_followed'],
      )!,
      watchedEpisodesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}watched_episodes_count'],
      )!,
      voteAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vote_average'],
      )!,
      firstAirDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_air_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ShowsTableTable createAlias(String alias) {
    return $ShowsTableTable(attachedDatabase, alias);
  }
}

class ShowsTableData extends DataClass implements Insertable<ShowsTableData> {
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
  final String genres;
  final bool isFollowed;
  final int watchedEpisodesCount;
  final double voteAverage;
  final DateTime? firstAirDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const ShowsTableData({
    required this.id,
    this.tmdbId,
    this.tvdbId,
    required this.name,
    this.originalName,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.status,
    required this.totalSeasons,
    required this.totalEpisodes,
    required this.genres,
    required this.isFollowed,
    required this.watchedEpisodesCount,
    required this.voteAverage,
    this.firstAirDate,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    if (!nullToAbsent || tvdbId != null) {
      map['tvdb_id'] = Variable<int>(tvdbId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || originalName != null) {
      map['original_name'] = Variable<String>(originalName);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['total_seasons'] = Variable<int>(totalSeasons);
    map['total_episodes'] = Variable<int>(totalEpisodes);
    map['genres'] = Variable<String>(genres);
    map['is_followed'] = Variable<bool>(isFollowed);
    map['watched_episodes_count'] = Variable<int>(watchedEpisodesCount);
    map['vote_average'] = Variable<double>(voteAverage);
    if (!nullToAbsent || firstAirDate != null) {
      map['first_air_date'] = Variable<DateTime>(firstAirDate);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ShowsTableCompanion toCompanion(bool nullToAbsent) {
    return ShowsTableCompanion(
      id: Value(id),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      tvdbId: tvdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tvdbId),
      name: Value(name),
      originalName: originalName == null && nullToAbsent
          ? const Value.absent()
          : Value(originalName),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      totalSeasons: Value(totalSeasons),
      totalEpisodes: Value(totalEpisodes),
      genres: Value(genres),
      isFollowed: Value(isFollowed),
      watchedEpisodesCount: Value(watchedEpisodesCount),
      voteAverage: Value(voteAverage),
      firstAirDate: firstAirDate == null && nullToAbsent
          ? const Value.absent()
          : Value(firstAirDate),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ShowsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShowsTableData(
      id: serializer.fromJson<int>(json['id']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      tvdbId: serializer.fromJson<int?>(json['tvdbId']),
      name: serializer.fromJson<String>(json['name']),
      originalName: serializer.fromJson<String?>(json['originalName']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      status: serializer.fromJson<String?>(json['status']),
      totalSeasons: serializer.fromJson<int>(json['totalSeasons']),
      totalEpisodes: serializer.fromJson<int>(json['totalEpisodes']),
      genres: serializer.fromJson<String>(json['genres']),
      isFollowed: serializer.fromJson<bool>(json['isFollowed']),
      watchedEpisodesCount: serializer.fromJson<int>(
        json['watchedEpisodesCount'],
      ),
      voteAverage: serializer.fromJson<double>(json['voteAverage']),
      firstAirDate: serializer.fromJson<DateTime?>(json['firstAirDate']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'tvdbId': serializer.toJson<int?>(tvdbId),
      'name': serializer.toJson<String>(name),
      'originalName': serializer.toJson<String?>(originalName),
      'overview': serializer.toJson<String?>(overview),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'status': serializer.toJson<String?>(status),
      'totalSeasons': serializer.toJson<int>(totalSeasons),
      'totalEpisodes': serializer.toJson<int>(totalEpisodes),
      'genres': serializer.toJson<String>(genres),
      'isFollowed': serializer.toJson<bool>(isFollowed),
      'watchedEpisodesCount': serializer.toJson<int>(watchedEpisodesCount),
      'voteAverage': serializer.toJson<double>(voteAverage),
      'firstAirDate': serializer.toJson<DateTime?>(firstAirDate),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ShowsTableData copyWith({
    int? id,
    Value<int?> tmdbId = const Value.absent(),
    Value<int?> tvdbId = const Value.absent(),
    String? name,
    Value<String?> originalName = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    Value<String?> backdropPath = const Value.absent(),
    Value<String?> status = const Value.absent(),
    int? totalSeasons,
    int? totalEpisodes,
    String? genres,
    bool? isFollowed,
    int? watchedEpisodesCount,
    double? voteAverage,
    Value<DateTime?> firstAirDate = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => ShowsTableData(
    id: id ?? this.id,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    tvdbId: tvdbId.present ? tvdbId.value : this.tvdbId,
    name: name ?? this.name,
    originalName: originalName.present ? originalName.value : this.originalName,
    overview: overview.present ? overview.value : this.overview,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    backdropPath: backdropPath.present ? backdropPath.value : this.backdropPath,
    status: status.present ? status.value : this.status,
    totalSeasons: totalSeasons ?? this.totalSeasons,
    totalEpisodes: totalEpisodes ?? this.totalEpisodes,
    genres: genres ?? this.genres,
    isFollowed: isFollowed ?? this.isFollowed,
    watchedEpisodesCount: watchedEpisodesCount ?? this.watchedEpisodesCount,
    voteAverage: voteAverage ?? this.voteAverage,
    firstAirDate: firstAirDate.present ? firstAirDate.value : this.firstAirDate,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ShowsTableData copyWithCompanion(ShowsTableCompanion data) {
    return ShowsTableData(
      id: data.id.present ? data.id.value : this.id,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      tvdbId: data.tvdbId.present ? data.tvdbId.value : this.tvdbId,
      name: data.name.present ? data.name.value : this.name,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      status: data.status.present ? data.status.value : this.status,
      totalSeasons: data.totalSeasons.present
          ? data.totalSeasons.value
          : this.totalSeasons,
      totalEpisodes: data.totalEpisodes.present
          ? data.totalEpisodes.value
          : this.totalEpisodes,
      genres: data.genres.present ? data.genres.value : this.genres,
      isFollowed: data.isFollowed.present
          ? data.isFollowed.value
          : this.isFollowed,
      watchedEpisodesCount: data.watchedEpisodesCount.present
          ? data.watchedEpisodesCount.value
          : this.watchedEpisodesCount,
      voteAverage: data.voteAverage.present
          ? data.voteAverage.value
          : this.voteAverage,
      firstAirDate: data.firstAirDate.present
          ? data.firstAirDate.value
          : this.firstAirDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShowsTableData(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('name: $name, ')
          ..write('originalName: $originalName, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('status: $status, ')
          ..write('totalSeasons: $totalSeasons, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('genres: $genres, ')
          ..write('isFollowed: $isFollowed, ')
          ..write('watchedEpisodesCount: $watchedEpisodesCount, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('firstAirDate: $firstAirDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tmdbId,
    tvdbId,
    name,
    originalName,
    overview,
    posterPath,
    backdropPath,
    status,
    totalSeasons,
    totalEpisodes,
    genres,
    isFollowed,
    watchedEpisodesCount,
    voteAverage,
    firstAirDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShowsTableData &&
          other.id == this.id &&
          other.tmdbId == this.tmdbId &&
          other.tvdbId == this.tvdbId &&
          other.name == this.name &&
          other.originalName == this.originalName &&
          other.overview == this.overview &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.status == this.status &&
          other.totalSeasons == this.totalSeasons &&
          other.totalEpisodes == this.totalEpisodes &&
          other.genres == this.genres &&
          other.isFollowed == this.isFollowed &&
          other.watchedEpisodesCount == this.watchedEpisodesCount &&
          other.voteAverage == this.voteAverage &&
          other.firstAirDate == this.firstAirDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShowsTableCompanion extends UpdateCompanion<ShowsTableData> {
  final Value<int> id;
  final Value<int?> tmdbId;
  final Value<int?> tvdbId;
  final Value<String> name;
  final Value<String?> originalName;
  final Value<String?> overview;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<String?> status;
  final Value<int> totalSeasons;
  final Value<int> totalEpisodes;
  final Value<String> genres;
  final Value<bool> isFollowed;
  final Value<int> watchedEpisodesCount;
  final Value<double> voteAverage;
  final Value<DateTime?> firstAirDate;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  const ShowsTableCompanion({
    this.id = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.tvdbId = const Value.absent(),
    this.name = const Value.absent(),
    this.originalName = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.status = const Value.absent(),
    this.totalSeasons = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.genres = const Value.absent(),
    this.isFollowed = const Value.absent(),
    this.watchedEpisodesCount = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.firstAirDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ShowsTableCompanion.insert({
    this.id = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.tvdbId = const Value.absent(),
    required String name,
    this.originalName = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.status = const Value.absent(),
    this.totalSeasons = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.genres = const Value.absent(),
    this.isFollowed = const Value.absent(),
    this.watchedEpisodesCount = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.firstAirDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ShowsTableData> custom({
    Expression<int>? id,
    Expression<int>? tmdbId,
    Expression<int>? tvdbId,
    Expression<String>? name,
    Expression<String>? originalName,
    Expression<String>? overview,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<String>? status,
    Expression<int>? totalSeasons,
    Expression<int>? totalEpisodes,
    Expression<String>? genres,
    Expression<bool>? isFollowed,
    Expression<int>? watchedEpisodesCount,
    Expression<double>? voteAverage,
    Expression<DateTime>? firstAirDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (tvdbId != null) 'tvdb_id': tvdbId,
      if (name != null) 'name': name,
      if (originalName != null) 'original_name': originalName,
      if (overview != null) 'overview': overview,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (status != null) 'status': status,
      if (totalSeasons != null) 'total_seasons': totalSeasons,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (genres != null) 'genres': genres,
      if (isFollowed != null) 'is_followed': isFollowed,
      if (watchedEpisodesCount != null)
        'watched_episodes_count': watchedEpisodesCount,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (firstAirDate != null) 'first_air_date': firstAirDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ShowsTableCompanion copyWith({
    Value<int>? id,
    Value<int?>? tmdbId,
    Value<int?>? tvdbId,
    Value<String>? name,
    Value<String?>? originalName,
    Value<String?>? overview,
    Value<String?>? posterPath,
    Value<String?>? backdropPath,
    Value<String?>? status,
    Value<int>? totalSeasons,
    Value<int>? totalEpisodes,
    Value<String>? genres,
    Value<bool>? isFollowed,
    Value<int>? watchedEpisodesCount,
    Value<double>? voteAverage,
    Value<DateTime?>? firstAirDate,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return ShowsTableCompanion(
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

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (tvdbId.present) {
      map['tvdb_id'] = Variable<int>(tvdbId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalSeasons.present) {
      map['total_seasons'] = Variable<int>(totalSeasons.value);
    }
    if (totalEpisodes.present) {
      map['total_episodes'] = Variable<int>(totalEpisodes.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (isFollowed.present) {
      map['is_followed'] = Variable<bool>(isFollowed.value);
    }
    if (watchedEpisodesCount.present) {
      map['watched_episodes_count'] = Variable<int>(watchedEpisodesCount.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (firstAirDate.present) {
      map['first_air_date'] = Variable<DateTime>(firstAirDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShowsTableCompanion(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('name: $name, ')
          ..write('originalName: $originalName, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('status: $status, ')
          ..write('totalSeasons: $totalSeasons, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('genres: $genres, ')
          ..write('isFollowed: $isFollowed, ')
          ..write('watchedEpisodesCount: $watchedEpisodesCount, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('firstAirDate: $firstAirDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SeasonsTableTable extends SeasonsTable
    with TableInfo<$SeasonsTableTable, SeasonsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _showIdMeta = const VerificationMeta('showId');
  @override
  late final GeneratedColumn<int> showId = GeneratedColumn<int>(
    'show_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeCountMeta = const VerificationMeta(
    'episodeCount',
  );
  @override
  late final GeneratedColumn<int> episodeCount = GeneratedColumn<int>(
    'episode_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _airDateMeta = const VerificationMeta(
    'airDate',
  );
  @override
  late final GeneratedColumn<DateTime> airDate = GeneratedColumn<DateTime>(
    'air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    showId,
    seasonNumber,
    name,
    overview,
    posterPath,
    episodeCount,
    airDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeasonsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('show_id')) {
      context.handle(
        _showIdMeta,
        showId.isAcceptableOrUnknown(data['show_id']!, _showIdMeta),
      );
    } else if (isInserting) {
      context.missing(_showIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('episode_count')) {
      context.handle(
        _episodeCountMeta,
        episodeCount.isAcceptableOrUnknown(
          data['episode_count']!,
          _episodeCountMeta,
        ),
      );
    }
    if (data.containsKey('air_date')) {
      context.handle(
        _airDateMeta,
        airDate.isAcceptableOrUnknown(data['air_date']!, _airDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {showId, seasonNumber},
  ];
  @override
  SeasonsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeasonsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      showId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}show_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      episodeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_count'],
      )!,
      airDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}air_date'],
      ),
    );
  }

  @override
  $SeasonsTableTable createAlias(String alias) {
    return $SeasonsTableTable(attachedDatabase, alias);
  }
}

class SeasonsTableData extends DataClass
    implements Insertable<SeasonsTableData> {
  final int id;
  final int showId;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final int episodeCount;
  final DateTime? airDate;
  const SeasonsTableData({
    required this.id,
    required this.showId,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    required this.episodeCount,
    this.airDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['show_id'] = Variable<int>(showId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    map['episode_count'] = Variable<int>(episodeCount);
    if (!nullToAbsent || airDate != null) {
      map['air_date'] = Variable<DateTime>(airDate);
    }
    return map;
  }

  SeasonsTableCompanion toCompanion(bool nullToAbsent) {
    return SeasonsTableCompanion(
      id: Value(id),
      showId: Value(showId),
      seasonNumber: Value(seasonNumber),
      name: Value(name),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      episodeCount: Value(episodeCount),
      airDate: airDate == null && nullToAbsent
          ? const Value.absent()
          : Value(airDate),
    );
  }

  factory SeasonsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeasonsTableData(
      id: serializer.fromJson<int>(json['id']),
      showId: serializer.fromJson<int>(json['showId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      name: serializer.fromJson<String>(json['name']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      episodeCount: serializer.fromJson<int>(json['episodeCount']),
      airDate: serializer.fromJson<DateTime?>(json['airDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'showId': serializer.toJson<int>(showId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'name': serializer.toJson<String>(name),
      'overview': serializer.toJson<String?>(overview),
      'posterPath': serializer.toJson<String?>(posterPath),
      'episodeCount': serializer.toJson<int>(episodeCount),
      'airDate': serializer.toJson<DateTime?>(airDate),
    };
  }

  SeasonsTableData copyWith({
    int? id,
    int? showId,
    int? seasonNumber,
    String? name,
    Value<String?> overview = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    int? episodeCount,
    Value<DateTime?> airDate = const Value.absent(),
  }) => SeasonsTableData(
    id: id ?? this.id,
    showId: showId ?? this.showId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    name: name ?? this.name,
    overview: overview.present ? overview.value : this.overview,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    episodeCount: episodeCount ?? this.episodeCount,
    airDate: airDate.present ? airDate.value : this.airDate,
  );
  SeasonsTableData copyWithCompanion(SeasonsTableCompanion data) {
    return SeasonsTableData(
      id: data.id.present ? data.id.value : this.id,
      showId: data.showId.present ? data.showId.value : this.showId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      name: data.name.present ? data.name.value : this.name,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      episodeCount: data.episodeCount.present
          ? data.episodeCount.value
          : this.episodeCount,
      airDate: data.airDate.present ? data.airDate.value : this.airDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsTableData(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('airDate: $airDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    showId,
    seasonNumber,
    name,
    overview,
    posterPath,
    episodeCount,
    airDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeasonsTableData &&
          other.id == this.id &&
          other.showId == this.showId &&
          other.seasonNumber == this.seasonNumber &&
          other.name == this.name &&
          other.overview == this.overview &&
          other.posterPath == this.posterPath &&
          other.episodeCount == this.episodeCount &&
          other.airDate == this.airDate);
}

class SeasonsTableCompanion extends UpdateCompanion<SeasonsTableData> {
  final Value<int> id;
  final Value<int> showId;
  final Value<int> seasonNumber;
  final Value<String> name;
  final Value<String?> overview;
  final Value<String?> posterPath;
  final Value<int> episodeCount;
  final Value<DateTime?> airDate;
  const SeasonsTableCompanion({
    this.id = const Value.absent(),
    this.showId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.airDate = const Value.absent(),
  });
  SeasonsTableCompanion.insert({
    this.id = const Value.absent(),
    required int showId,
    required int seasonNumber,
    required String name,
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.airDate = const Value.absent(),
  }) : showId = Value(showId),
       seasonNumber = Value(seasonNumber),
       name = Value(name);
  static Insertable<SeasonsTableData> custom({
    Expression<int>? id,
    Expression<int>? showId,
    Expression<int>? seasonNumber,
    Expression<String>? name,
    Expression<String>? overview,
    Expression<String>? posterPath,
    Expression<int>? episodeCount,
    Expression<DateTime>? airDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (showId != null) 'show_id': showId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (name != null) 'name': name,
      if (overview != null) 'overview': overview,
      if (posterPath != null) 'poster_path': posterPath,
      if (episodeCount != null) 'episode_count': episodeCount,
      if (airDate != null) 'air_date': airDate,
    });
  }

  SeasonsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? showId,
    Value<int>? seasonNumber,
    Value<String>? name,
    Value<String?>? overview,
    Value<String?>? posterPath,
    Value<int>? episodeCount,
    Value<DateTime?>? airDate,
  }) {
    return SeasonsTableCompanion(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      episodeCount: episodeCount ?? this.episodeCount,
      airDate: airDate ?? this.airDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (showId.present) {
      map['show_id'] = Variable<int>(showId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (episodeCount.present) {
      map['episode_count'] = Variable<int>(episodeCount.value);
    }
    if (airDate.present) {
      map['air_date'] = Variable<DateTime>(airDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsTableCompanion(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('airDate: $airDate')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTableTable extends EpisodesTable
    with TableInfo<$EpisodesTableTable, EpisodesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _showIdMeta = const VerificationMeta('showId');
  @override
  late final GeneratedColumn<int> showId = GeneratedColumn<int>(
    'show_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<int> seasonId = GeneratedColumn<int>(
    'season_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tvdbIdMeta = const VerificationMeta('tvdbId');
  @override
  late final GeneratedColumn<int> tvdbId = GeneratedColumn<int>(
    'tvdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stillPathMeta = const VerificationMeta(
    'stillPath',
  );
  @override
  late final GeneratedColumn<String> stillPath = GeneratedColumn<String>(
    'still_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimeMinutesMeta = const VerificationMeta(
    'runtimeMinutes',
  );
  @override
  late final GeneratedColumn<int> runtimeMinutes = GeneratedColumn<int>(
    'runtime_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _airDateMeta = const VerificationMeta(
    'airDate',
  );
  @override
  late final GeneratedColumn<DateTime> airDate = GeneratedColumn<DateTime>(
    'air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voteAverageMeta = const VerificationMeta(
    'voteAverage',
  );
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
    'vote_average',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isWatchedMeta = const VerificationMeta(
    'isWatched',
  );
  @override
  late final GeneratedColumn<bool> isWatched = GeneratedColumn<bool>(
    'is_watched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_watched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rewatchCountMeta = const VerificationMeta(
    'rewatchCount',
  );
  @override
  late final GeneratedColumn<int> rewatchCount = GeneratedColumn<int>(
    'rewatch_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastWatchedAtMeta = const VerificationMeta(
    'lastWatchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt =
      GeneratedColumn<DateTime>(
        'last_watched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    showId,
    seasonId,
    seasonNumber,
    episodeNumber,
    tvdbId,
    tmdbId,
    name,
    overview,
    stillPath,
    runtimeMinutes,
    airDate,
    voteAverage,
    isWatched,
    rewatchCount,
    lastWatchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('show_id')) {
      context.handle(
        _showIdMeta,
        showId.isAcceptableOrUnknown(data['show_id']!, _showIdMeta),
      );
    } else if (isInserting) {
      context.missing(_showIdMeta);
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('tvdb_id')) {
      context.handle(
        _tvdbIdMeta,
        tvdbId.isAcceptableOrUnknown(data['tvdb_id']!, _tvdbIdMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('still_path')) {
      context.handle(
        _stillPathMeta,
        stillPath.isAcceptableOrUnknown(data['still_path']!, _stillPathMeta),
      );
    }
    if (data.containsKey('runtime_minutes')) {
      context.handle(
        _runtimeMinutesMeta,
        runtimeMinutes.isAcceptableOrUnknown(
          data['runtime_minutes']!,
          _runtimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('air_date')) {
      context.handle(
        _airDateMeta,
        airDate.isAcceptableOrUnknown(data['air_date']!, _airDateMeta),
      );
    }
    if (data.containsKey('vote_average')) {
      context.handle(
        _voteAverageMeta,
        voteAverage.isAcceptableOrUnknown(
          data['vote_average']!,
          _voteAverageMeta,
        ),
      );
    }
    if (data.containsKey('is_watched')) {
      context.handle(
        _isWatchedMeta,
        isWatched.isAcceptableOrUnknown(data['is_watched']!, _isWatchedMeta),
      );
    }
    if (data.containsKey('rewatch_count')) {
      context.handle(
        _rewatchCountMeta,
        rewatchCount.isAcceptableOrUnknown(
          data['rewatch_count']!,
          _rewatchCountMeta,
        ),
      );
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
        _lastWatchedAtMeta,
        lastWatchedAt.isAcceptableOrUnknown(
          data['last_watched_at']!,
          _lastWatchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {showId, seasonNumber, episodeNumber},
    {tvdbId},
  ];
  @override
  EpisodesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      showId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}show_id'],
      )!,
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      )!,
      tvdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tvdb_id'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      stillPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}still_path'],
      ),
      runtimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_minutes'],
      )!,
      airDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}air_date'],
      ),
      voteAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vote_average'],
      )!,
      isWatched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_watched'],
      )!,
      rewatchCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rewatch_count'],
      )!,
      lastWatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_watched_at'],
      ),
    );
  }

  @override
  $EpisodesTableTable createAlias(String alias) {
    return $EpisodesTableTable(attachedDatabase, alias);
  }
}

class EpisodesTableData extends DataClass
    implements Insertable<EpisodesTableData> {
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
  const EpisodesTableData({
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
    required this.runtimeMinutes,
    this.airDate,
    required this.voteAverage,
    required this.isWatched,
    required this.rewatchCount,
    this.lastWatchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['show_id'] = Variable<int>(showId);
    map['season_id'] = Variable<int>(seasonId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_number'] = Variable<int>(episodeNumber);
    if (!nullToAbsent || tvdbId != null) {
      map['tvdb_id'] = Variable<int>(tvdbId);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || stillPath != null) {
      map['still_path'] = Variable<String>(stillPath);
    }
    map['runtime_minutes'] = Variable<int>(runtimeMinutes);
    if (!nullToAbsent || airDate != null) {
      map['air_date'] = Variable<DateTime>(airDate);
    }
    map['vote_average'] = Variable<double>(voteAverage);
    map['is_watched'] = Variable<bool>(isWatched);
    map['rewatch_count'] = Variable<int>(rewatchCount);
    if (!nullToAbsent || lastWatchedAt != null) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    }
    return map;
  }

  EpisodesTableCompanion toCompanion(bool nullToAbsent) {
    return EpisodesTableCompanion(
      id: Value(id),
      showId: Value(showId),
      seasonId: Value(seasonId),
      seasonNumber: Value(seasonNumber),
      episodeNumber: Value(episodeNumber),
      tvdbId: tvdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tvdbId),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      name: Value(name),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      stillPath: stillPath == null && nullToAbsent
          ? const Value.absent()
          : Value(stillPath),
      runtimeMinutes: Value(runtimeMinutes),
      airDate: airDate == null && nullToAbsent
          ? const Value.absent()
          : Value(airDate),
      voteAverage: Value(voteAverage),
      isWatched: Value(isWatched),
      rewatchCount: Value(rewatchCount),
      lastWatchedAt: lastWatchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWatchedAt),
    );
  }

  factory EpisodesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodesTableData(
      id: serializer.fromJson<int>(json['id']),
      showId: serializer.fromJson<int>(json['showId']),
      seasonId: serializer.fromJson<int>(json['seasonId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      tvdbId: serializer.fromJson<int?>(json['tvdbId']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      name: serializer.fromJson<String>(json['name']),
      overview: serializer.fromJson<String?>(json['overview']),
      stillPath: serializer.fromJson<String?>(json['stillPath']),
      runtimeMinutes: serializer.fromJson<int>(json['runtimeMinutes']),
      airDate: serializer.fromJson<DateTime?>(json['airDate']),
      voteAverage: serializer.fromJson<double>(json['voteAverage']),
      isWatched: serializer.fromJson<bool>(json['isWatched']),
      rewatchCount: serializer.fromJson<int>(json['rewatchCount']),
      lastWatchedAt: serializer.fromJson<DateTime?>(json['lastWatchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'showId': serializer.toJson<int>(showId),
      'seasonId': serializer.toJson<int>(seasonId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'tvdbId': serializer.toJson<int?>(tvdbId),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'name': serializer.toJson<String>(name),
      'overview': serializer.toJson<String?>(overview),
      'stillPath': serializer.toJson<String?>(stillPath),
      'runtimeMinutes': serializer.toJson<int>(runtimeMinutes),
      'airDate': serializer.toJson<DateTime?>(airDate),
      'voteAverage': serializer.toJson<double>(voteAverage),
      'isWatched': serializer.toJson<bool>(isWatched),
      'rewatchCount': serializer.toJson<int>(rewatchCount),
      'lastWatchedAt': serializer.toJson<DateTime?>(lastWatchedAt),
    };
  }

  EpisodesTableData copyWith({
    int? id,
    int? showId,
    int? seasonId,
    int? seasonNumber,
    int? episodeNumber,
    Value<int?> tvdbId = const Value.absent(),
    Value<int?> tmdbId = const Value.absent(),
    String? name,
    Value<String?> overview = const Value.absent(),
    Value<String?> stillPath = const Value.absent(),
    int? runtimeMinutes,
    Value<DateTime?> airDate = const Value.absent(),
    double? voteAverage,
    bool? isWatched,
    int? rewatchCount,
    Value<DateTime?> lastWatchedAt = const Value.absent(),
  }) => EpisodesTableData(
    id: id ?? this.id,
    showId: showId ?? this.showId,
    seasonId: seasonId ?? this.seasonId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    tvdbId: tvdbId.present ? tvdbId.value : this.tvdbId,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    name: name ?? this.name,
    overview: overview.present ? overview.value : this.overview,
    stillPath: stillPath.present ? stillPath.value : this.stillPath,
    runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
    airDate: airDate.present ? airDate.value : this.airDate,
    voteAverage: voteAverage ?? this.voteAverage,
    isWatched: isWatched ?? this.isWatched,
    rewatchCount: rewatchCount ?? this.rewatchCount,
    lastWatchedAt: lastWatchedAt.present
        ? lastWatchedAt.value
        : this.lastWatchedAt,
  );
  EpisodesTableData copyWithCompanion(EpisodesTableCompanion data) {
    return EpisodesTableData(
      id: data.id.present ? data.id.value : this.id,
      showId: data.showId.present ? data.showId.value : this.showId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      tvdbId: data.tvdbId.present ? data.tvdbId.value : this.tvdbId,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      name: data.name.present ? data.name.value : this.name,
      overview: data.overview.present ? data.overview.value : this.overview,
      stillPath: data.stillPath.present ? data.stillPath.value : this.stillPath,
      runtimeMinutes: data.runtimeMinutes.present
          ? data.runtimeMinutes.value
          : this.runtimeMinutes,
      airDate: data.airDate.present ? data.airDate.value : this.airDate,
      voteAverage: data.voteAverage.present
          ? data.voteAverage.value
          : this.voteAverage,
      isWatched: data.isWatched.present ? data.isWatched.value : this.isWatched,
      rewatchCount: data.rewatchCount.present
          ? data.rewatchCount.value
          : this.rewatchCount,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesTableData(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonId: $seasonId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('stillPath: $stillPath, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('airDate: $airDate, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('isWatched: $isWatched, ')
          ..write('rewatchCount: $rewatchCount, ')
          ..write('lastWatchedAt: $lastWatchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    showId,
    seasonId,
    seasonNumber,
    episodeNumber,
    tvdbId,
    tmdbId,
    name,
    overview,
    stillPath,
    runtimeMinutes,
    airDate,
    voteAverage,
    isWatched,
    rewatchCount,
    lastWatchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodesTableData &&
          other.id == this.id &&
          other.showId == this.showId &&
          other.seasonId == this.seasonId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.tvdbId == this.tvdbId &&
          other.tmdbId == this.tmdbId &&
          other.name == this.name &&
          other.overview == this.overview &&
          other.stillPath == this.stillPath &&
          other.runtimeMinutes == this.runtimeMinutes &&
          other.airDate == this.airDate &&
          other.voteAverage == this.voteAverage &&
          other.isWatched == this.isWatched &&
          other.rewatchCount == this.rewatchCount &&
          other.lastWatchedAt == this.lastWatchedAt);
}

class EpisodesTableCompanion extends UpdateCompanion<EpisodesTableData> {
  final Value<int> id;
  final Value<int> showId;
  final Value<int> seasonId;
  final Value<int> seasonNumber;
  final Value<int> episodeNumber;
  final Value<int?> tvdbId;
  final Value<int?> tmdbId;
  final Value<String> name;
  final Value<String?> overview;
  final Value<String?> stillPath;
  final Value<int> runtimeMinutes;
  final Value<DateTime?> airDate;
  final Value<double> voteAverage;
  final Value<bool> isWatched;
  final Value<int> rewatchCount;
  final Value<DateTime?> lastWatchedAt;
  const EpisodesTableCompanion({
    this.id = const Value.absent(),
    this.showId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.tvdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.name = const Value.absent(),
    this.overview = const Value.absent(),
    this.stillPath = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.airDate = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.isWatched = const Value.absent(),
    this.rewatchCount = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
  });
  EpisodesTableCompanion.insert({
    this.id = const Value.absent(),
    required int showId,
    required int seasonId,
    required int seasonNumber,
    required int episodeNumber,
    this.tvdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    required String name,
    this.overview = const Value.absent(),
    this.stillPath = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.airDate = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.isWatched = const Value.absent(),
    this.rewatchCount = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
  }) : showId = Value(showId),
       seasonId = Value(seasonId),
       seasonNumber = Value(seasonNumber),
       episodeNumber = Value(episodeNumber),
       name = Value(name);
  static Insertable<EpisodesTableData> custom({
    Expression<int>? id,
    Expression<int>? showId,
    Expression<int>? seasonId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<int>? tvdbId,
    Expression<int>? tmdbId,
    Expression<String>? name,
    Expression<String>? overview,
    Expression<String>? stillPath,
    Expression<int>? runtimeMinutes,
    Expression<DateTime>? airDate,
    Expression<double>? voteAverage,
    Expression<bool>? isWatched,
    Expression<int>? rewatchCount,
    Expression<DateTime>? lastWatchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (showId != null) 'show_id': showId,
      if (seasonId != null) 'season_id': seasonId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (tvdbId != null) 'tvdb_id': tvdbId,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (name != null) 'name': name,
      if (overview != null) 'overview': overview,
      if (stillPath != null) 'still_path': stillPath,
      if (runtimeMinutes != null) 'runtime_minutes': runtimeMinutes,
      if (airDate != null) 'air_date': airDate,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (isWatched != null) 'is_watched': isWatched,
      if (rewatchCount != null) 'rewatch_count': rewatchCount,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
    });
  }

  EpisodesTableCompanion copyWith({
    Value<int>? id,
    Value<int>? showId,
    Value<int>? seasonId,
    Value<int>? seasonNumber,
    Value<int>? episodeNumber,
    Value<int?>? tvdbId,
    Value<int?>? tmdbId,
    Value<String>? name,
    Value<String?>? overview,
    Value<String?>? stillPath,
    Value<int>? runtimeMinutes,
    Value<DateTime?>? airDate,
    Value<double>? voteAverage,
    Value<bool>? isWatched,
    Value<int>? rewatchCount,
    Value<DateTime?>? lastWatchedAt,
  }) {
    return EpisodesTableCompanion(
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

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (showId.present) {
      map['show_id'] = Variable<int>(showId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<int>(seasonId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (tvdbId.present) {
      map['tvdb_id'] = Variable<int>(tvdbId.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (stillPath.present) {
      map['still_path'] = Variable<String>(stillPath.value);
    }
    if (runtimeMinutes.present) {
      map['runtime_minutes'] = Variable<int>(runtimeMinutes.value);
    }
    if (airDate.present) {
      map['air_date'] = Variable<DateTime>(airDate.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (isWatched.present) {
      map['is_watched'] = Variable<bool>(isWatched.value);
    }
    if (rewatchCount.present) {
      map['rewatch_count'] = Variable<int>(rewatchCount.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesTableCompanion(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonId: $seasonId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('stillPath: $stillPath, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('airDate: $airDate, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('isWatched: $isWatched, ')
          ..write('rewatchCount: $rewatchCount, ')
          ..write('lastWatchedAt: $lastWatchedAt')
          ..write(')'))
        .toString();
  }
}

class $EpisodeWatchHistoryTableTable extends EpisodeWatchHistoryTable
    with
        TableInfo<
          $EpisodeWatchHistoryTableTable,
          EpisodeWatchHistoryTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodeWatchHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<int> episodeId = GeneratedColumn<int>(
    'episode_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showIdMeta = const VerificationMeta('showId');
  @override
  late final GeneratedColumn<int> showId = GeneratedColumn<int>(
    'show_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvdbIdMeta = const VerificationMeta('tvdbId');
  @override
  late final GeneratedColumn<int> tvdbId = GeneratedColumn<int>(
    'tvdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sIdMeta = const VerificationMeta('sId');
  @override
  late final GeneratedColumn<int> sId = GeneratedColumn<int>(
    's_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runtimeMinutesMeta = const VerificationMeta(
    'runtimeMinutes',
  );
  @override
  late final GeneratedColumn<int> runtimeMinutes = GeneratedColumn<int>(
    'runtime_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rewatchCountMeta = const VerificationMeta(
    'rewatchCount',
  );
  @override
  late final GeneratedColumn<int> rewatchCount = GeneratedColumn<int>(
    'rewatch_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    episodeId,
    showId,
    tvdbId,
    sId,
    seasonNumber,
    episodeNumber,
    title,
    runtimeMinutes,
    watchedAt,
    rewatchCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episode_watch_history_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeWatchHistoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    }
    if (data.containsKey('show_id')) {
      context.handle(
        _showIdMeta,
        showId.isAcceptableOrUnknown(data['show_id']!, _showIdMeta),
      );
    }
    if (data.containsKey('tvdb_id')) {
      context.handle(
        _tvdbIdMeta,
        tvdbId.isAcceptableOrUnknown(data['tvdb_id']!, _tvdbIdMeta),
      );
    }
    if (data.containsKey('s_id')) {
      context.handle(
        _sIdMeta,
        sId.isAcceptableOrUnknown(data['s_id']!, _sIdMeta),
      );
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('runtime_minutes')) {
      context.handle(
        _runtimeMinutesMeta,
        runtimeMinutes.isAcceptableOrUnknown(
          data['runtime_minutes']!,
          _runtimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    if (data.containsKey('rewatch_count')) {
      context.handle(
        _rewatchCountMeta,
        rewatchCount.isAcceptableOrUnknown(
          data['rewatch_count']!,
          _rewatchCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpisodeWatchHistoryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeWatchHistoryTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_id'],
      ),
      showId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}show_id'],
      ),
      tvdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tvdb_id'],
      ),
      sId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}s_id'],
      ),
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      runtimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_minutes'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
      rewatchCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rewatch_count'],
      )!,
    );
  }

  @override
  $EpisodeWatchHistoryTableTable createAlias(String alias) {
    return $EpisodeWatchHistoryTableTable(attachedDatabase, alias);
  }
}

class EpisodeWatchHistoryTableData extends DataClass
    implements Insertable<EpisodeWatchHistoryTableData> {
  final int id;
  final int? episodeId;
  final int? showId;
  final int? tvdbId;
  final int? sId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final int runtimeMinutes;
  final DateTime watchedAt;
  final int rewatchCount;
  const EpisodeWatchHistoryTableData({
    required this.id,
    this.episodeId,
    this.showId,
    this.tvdbId,
    this.sId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.runtimeMinutes,
    required this.watchedAt,
    required this.rewatchCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || episodeId != null) {
      map['episode_id'] = Variable<int>(episodeId);
    }
    if (!nullToAbsent || showId != null) {
      map['show_id'] = Variable<int>(showId);
    }
    if (!nullToAbsent || tvdbId != null) {
      map['tvdb_id'] = Variable<int>(tvdbId);
    }
    if (!nullToAbsent || sId != null) {
      map['s_id'] = Variable<int>(sId);
    }
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['title'] = Variable<String>(title);
    map['runtime_minutes'] = Variable<int>(runtimeMinutes);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    map['rewatch_count'] = Variable<int>(rewatchCount);
    return map;
  }

  EpisodeWatchHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return EpisodeWatchHistoryTableCompanion(
      id: Value(id),
      episodeId: episodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeId),
      showId: showId == null && nullToAbsent
          ? const Value.absent()
          : Value(showId),
      tvdbId: tvdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tvdbId),
      sId: sId == null && nullToAbsent ? const Value.absent() : Value(sId),
      seasonNumber: Value(seasonNumber),
      episodeNumber: Value(episodeNumber),
      title: Value(title),
      runtimeMinutes: Value(runtimeMinutes),
      watchedAt: Value(watchedAt),
      rewatchCount: Value(rewatchCount),
    );
  }

  factory EpisodeWatchHistoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeWatchHistoryTableData(
      id: serializer.fromJson<int>(json['id']),
      episodeId: serializer.fromJson<int?>(json['episodeId']),
      showId: serializer.fromJson<int?>(json['showId']),
      tvdbId: serializer.fromJson<int?>(json['tvdbId']),
      sId: serializer.fromJson<int?>(json['sId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      title: serializer.fromJson<String>(json['title']),
      runtimeMinutes: serializer.fromJson<int>(json['runtimeMinutes']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
      rewatchCount: serializer.fromJson<int>(json['rewatchCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'episodeId': serializer.toJson<int?>(episodeId),
      'showId': serializer.toJson<int?>(showId),
      'tvdbId': serializer.toJson<int?>(tvdbId),
      'sId': serializer.toJson<int?>(sId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'title': serializer.toJson<String>(title),
      'runtimeMinutes': serializer.toJson<int>(runtimeMinutes),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
      'rewatchCount': serializer.toJson<int>(rewatchCount),
    };
  }

  EpisodeWatchHistoryTableData copyWith({
    int? id,
    Value<int?> episodeId = const Value.absent(),
    Value<int?> showId = const Value.absent(),
    Value<int?> tvdbId = const Value.absent(),
    Value<int?> sId = const Value.absent(),
    int? seasonNumber,
    int? episodeNumber,
    String? title,
    int? runtimeMinutes,
    DateTime? watchedAt,
    int? rewatchCount,
  }) => EpisodeWatchHistoryTableData(
    id: id ?? this.id,
    episodeId: episodeId.present ? episodeId.value : this.episodeId,
    showId: showId.present ? showId.value : this.showId,
    tvdbId: tvdbId.present ? tvdbId.value : this.tvdbId,
    sId: sId.present ? sId.value : this.sId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    title: title ?? this.title,
    runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
    watchedAt: watchedAt ?? this.watchedAt,
    rewatchCount: rewatchCount ?? this.rewatchCount,
  );
  EpisodeWatchHistoryTableData copyWithCompanion(
    EpisodeWatchHistoryTableCompanion data,
  ) {
    return EpisodeWatchHistoryTableData(
      id: data.id.present ? data.id.value : this.id,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      showId: data.showId.present ? data.showId.value : this.showId,
      tvdbId: data.tvdbId.present ? data.tvdbId.value : this.tvdbId,
      sId: data.sId.present ? data.sId.value : this.sId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      title: data.title.present ? data.title.value : this.title,
      runtimeMinutes: data.runtimeMinutes.present
          ? data.runtimeMinutes.value
          : this.runtimeMinutes,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
      rewatchCount: data.rewatchCount.present
          ? data.rewatchCount.value
          : this.rewatchCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeWatchHistoryTableData(')
          ..write('id: $id, ')
          ..write('episodeId: $episodeId, ')
          ..write('showId: $showId, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('sId: $sId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rewatchCount: $rewatchCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    episodeId,
    showId,
    tvdbId,
    sId,
    seasonNumber,
    episodeNumber,
    title,
    runtimeMinutes,
    watchedAt,
    rewatchCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeWatchHistoryTableData &&
          other.id == this.id &&
          other.episodeId == this.episodeId &&
          other.showId == this.showId &&
          other.tvdbId == this.tvdbId &&
          other.sId == this.sId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.title == this.title &&
          other.runtimeMinutes == this.runtimeMinutes &&
          other.watchedAt == this.watchedAt &&
          other.rewatchCount == this.rewatchCount);
}

class EpisodeWatchHistoryTableCompanion
    extends UpdateCompanion<EpisodeWatchHistoryTableData> {
  final Value<int> id;
  final Value<int?> episodeId;
  final Value<int?> showId;
  final Value<int?> tvdbId;
  final Value<int?> sId;
  final Value<int> seasonNumber;
  final Value<int> episodeNumber;
  final Value<String> title;
  final Value<int> runtimeMinutes;
  final Value<DateTime> watchedAt;
  final Value<int> rewatchCount;
  const EpisodeWatchHistoryTableCompanion({
    this.id = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.showId = const Value.absent(),
    this.tvdbId = const Value.absent(),
    this.sId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.rewatchCount = const Value.absent(),
  });
  EpisodeWatchHistoryTableCompanion.insert({
    this.id = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.showId = const Value.absent(),
    this.tvdbId = const Value.absent(),
    this.sId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    required String title,
    this.runtimeMinutes = const Value.absent(),
    required DateTime watchedAt,
    this.rewatchCount = const Value.absent(),
  }) : title = Value(title),
       watchedAt = Value(watchedAt);
  static Insertable<EpisodeWatchHistoryTableData> custom({
    Expression<int>? id,
    Expression<int>? episodeId,
    Expression<int>? showId,
    Expression<int>? tvdbId,
    Expression<int>? sId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<String>? title,
    Expression<int>? runtimeMinutes,
    Expression<DateTime>? watchedAt,
    Expression<int>? rewatchCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (episodeId != null) 'episode_id': episodeId,
      if (showId != null) 'show_id': showId,
      if (tvdbId != null) 'tvdb_id': tvdbId,
      if (sId != null) 's_id': sId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (title != null) 'title': title,
      if (runtimeMinutes != null) 'runtime_minutes': runtimeMinutes,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (rewatchCount != null) 'rewatch_count': rewatchCount,
    });
  }

  EpisodeWatchHistoryTableCompanion copyWith({
    Value<int>? id,
    Value<int?>? episodeId,
    Value<int?>? showId,
    Value<int?>? tvdbId,
    Value<int?>? sId,
    Value<int>? seasonNumber,
    Value<int>? episodeNumber,
    Value<String>? title,
    Value<int>? runtimeMinutes,
    Value<DateTime>? watchedAt,
    Value<int>? rewatchCount,
  }) {
    return EpisodeWatchHistoryTableCompanion(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      showId: showId ?? this.showId,
      tvdbId: tvdbId ?? this.tvdbId,
      sId: sId ?? this.sId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      watchedAt: watchedAt ?? this.watchedAt,
      rewatchCount: rewatchCount ?? this.rewatchCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<int>(episodeId.value);
    }
    if (showId.present) {
      map['show_id'] = Variable<int>(showId.value);
    }
    if (tvdbId.present) {
      map['tvdb_id'] = Variable<int>(tvdbId.value);
    }
    if (sId.present) {
      map['s_id'] = Variable<int>(sId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (runtimeMinutes.present) {
      map['runtime_minutes'] = Variable<int>(runtimeMinutes.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (rewatchCount.present) {
      map['rewatch_count'] = Variable<int>(rewatchCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeWatchHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('episodeId: $episodeId, ')
          ..write('showId: $showId, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('sId: $sId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rewatchCount: $rewatchCount')
          ..write(')'))
        .toString();
  }
}

class $MoviesTableTable extends MoviesTable
    with TableInfo<$MoviesTableTable, MoviesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imdbIdMeta = const VerificationMeta('imdbId');
  @override
  late final GeneratedColumn<String> imdbId = GeneratedColumn<String>(
    'imdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropPathMeta = const VerificationMeta(
    'backdropPath',
  );
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
    'backdrop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> releaseDate = GeneratedColumn<DateTime>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimeMinutesMeta = const VerificationMeta(
    'runtimeMinutes',
  );
  @override
  late final GeneratedColumn<int> runtimeMinutes = GeneratedColumn<int>(
    'runtime_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isWatchedMeta = const VerificationMeta(
    'isWatched',
  );
  @override
  late final GeneratedColumn<bool> isWatched = GeneratedColumn<bool>(
    'is_watched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_watched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isFollowedMeta = const VerificationMeta(
    'isFollowed',
  );
  @override
  late final GeneratedColumn<bool> isFollowed = GeneratedColumn<bool>(
    'is_followed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_followed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rewatchCountMeta = const VerificationMeta(
    'rewatchCount',
  );
  @override
  late final GeneratedColumn<int> rewatchCount = GeneratedColumn<int>(
    'rewatch_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _voteAverageMeta = const VerificationMeta(
    'voteAverage',
  );
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
    'vote_average',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tmdbId,
    imdbId,
    title,
    overview,
    posterPath,
    backdropPath,
    releaseDate,
    runtimeMinutes,
    genres,
    isWatched,
    isFollowed,
    watchedAt,
    rewatchCount,
    voteAverage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoviesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('imdb_id')) {
      context.handle(
        _imdbIdMeta,
        imdbId.isAcceptableOrUnknown(data['imdb_id']!, _imdbIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
        _backdropPathMeta,
        backdropPath.isAcceptableOrUnknown(
          data['backdrop_path']!,
          _backdropPathMeta,
        ),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('runtime_minutes')) {
      context.handle(
        _runtimeMinutesMeta,
        runtimeMinutes.isAcceptableOrUnknown(
          data['runtime_minutes']!,
          _runtimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('is_watched')) {
      context.handle(
        _isWatchedMeta,
        isWatched.isAcceptableOrUnknown(data['is_watched']!, _isWatchedMeta),
      );
    }
    if (data.containsKey('is_followed')) {
      context.handle(
        _isFollowedMeta,
        isFollowed.isAcceptableOrUnknown(data['is_followed']!, _isFollowedMeta),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    }
    if (data.containsKey('rewatch_count')) {
      context.handle(
        _rewatchCountMeta,
        rewatchCount.isAcceptableOrUnknown(
          data['rewatch_count']!,
          _rewatchCountMeta,
        ),
      );
    }
    if (data.containsKey('vote_average')) {
      context.handle(
        _voteAverageMeta,
        voteAverage.isAcceptableOrUnknown(
          data['vote_average']!,
          _voteAverageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {tmdbId},
  ];
  @override
  MoviesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoviesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      imdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imdb_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      backdropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_path'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}release_date'],
      ),
      runtimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_minutes'],
      )!,
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      )!,
      isWatched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_watched'],
      )!,
      isFollowed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_followed'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      ),
      rewatchCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rewatch_count'],
      )!,
      voteAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vote_average'],
      )!,
    );
  }

  @override
  $MoviesTableTable createAlias(String alias) {
    return $MoviesTableTable(attachedDatabase, alias);
  }
}

class MoviesTableData extends DataClass implements Insertable<MoviesTableData> {
  final int id;
  final int? tmdbId;
  final String? imdbId;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final DateTime? releaseDate;
  final int runtimeMinutes;
  final String genres;
  final bool isWatched;
  final bool isFollowed;
  final DateTime? watchedAt;
  final int rewatchCount;
  final double voteAverage;
  const MoviesTableData({
    required this.id,
    this.tmdbId,
    this.imdbId,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    required this.runtimeMinutes,
    required this.genres,
    required this.isWatched,
    required this.isFollowed,
    this.watchedAt,
    required this.rewatchCount,
    required this.voteAverage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    if (!nullToAbsent || imdbId != null) {
      map['imdb_id'] = Variable<String>(imdbId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<DateTime>(releaseDate);
    }
    map['runtime_minutes'] = Variable<int>(runtimeMinutes);
    map['genres'] = Variable<String>(genres);
    map['is_watched'] = Variable<bool>(isWatched);
    map['is_followed'] = Variable<bool>(isFollowed);
    if (!nullToAbsent || watchedAt != null) {
      map['watched_at'] = Variable<DateTime>(watchedAt);
    }
    map['rewatch_count'] = Variable<int>(rewatchCount);
    map['vote_average'] = Variable<double>(voteAverage);
    return map;
  }

  MoviesTableCompanion toCompanion(bool nullToAbsent) {
    return MoviesTableCompanion(
      id: Value(id),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      imdbId: imdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(imdbId),
      title: Value(title),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      runtimeMinutes: Value(runtimeMinutes),
      genres: Value(genres),
      isWatched: Value(isWatched),
      isFollowed: Value(isFollowed),
      watchedAt: watchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(watchedAt),
      rewatchCount: Value(rewatchCount),
      voteAverage: Value(voteAverage),
    );
  }

  factory MoviesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoviesTableData(
      id: serializer.fromJson<int>(json['id']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      imdbId: serializer.fromJson<String?>(json['imdbId']),
      title: serializer.fromJson<String>(json['title']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      releaseDate: serializer.fromJson<DateTime?>(json['releaseDate']),
      runtimeMinutes: serializer.fromJson<int>(json['runtimeMinutes']),
      genres: serializer.fromJson<String>(json['genres']),
      isWatched: serializer.fromJson<bool>(json['isWatched']),
      isFollowed: serializer.fromJson<bool>(json['isFollowed']),
      watchedAt: serializer.fromJson<DateTime?>(json['watchedAt']),
      rewatchCount: serializer.fromJson<int>(json['rewatchCount']),
      voteAverage: serializer.fromJson<double>(json['voteAverage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'imdbId': serializer.toJson<String?>(imdbId),
      'title': serializer.toJson<String>(title),
      'overview': serializer.toJson<String?>(overview),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'releaseDate': serializer.toJson<DateTime?>(releaseDate),
      'runtimeMinutes': serializer.toJson<int>(runtimeMinutes),
      'genres': serializer.toJson<String>(genres),
      'isWatched': serializer.toJson<bool>(isWatched),
      'isFollowed': serializer.toJson<bool>(isFollowed),
      'watchedAt': serializer.toJson<DateTime?>(watchedAt),
      'rewatchCount': serializer.toJson<int>(rewatchCount),
      'voteAverage': serializer.toJson<double>(voteAverage),
    };
  }

  MoviesTableData copyWith({
    int? id,
    Value<int?> tmdbId = const Value.absent(),
    Value<String?> imdbId = const Value.absent(),
    String? title,
    Value<String?> overview = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    Value<String?> backdropPath = const Value.absent(),
    Value<DateTime?> releaseDate = const Value.absent(),
    int? runtimeMinutes,
    String? genres,
    bool? isWatched,
    bool? isFollowed,
    Value<DateTime?> watchedAt = const Value.absent(),
    int? rewatchCount,
    double? voteAverage,
  }) => MoviesTableData(
    id: id ?? this.id,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    imdbId: imdbId.present ? imdbId.value : this.imdbId,
    title: title ?? this.title,
    overview: overview.present ? overview.value : this.overview,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    backdropPath: backdropPath.present ? backdropPath.value : this.backdropPath,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
    genres: genres ?? this.genres,
    isWatched: isWatched ?? this.isWatched,
    isFollowed: isFollowed ?? this.isFollowed,
    watchedAt: watchedAt.present ? watchedAt.value : this.watchedAt,
    rewatchCount: rewatchCount ?? this.rewatchCount,
    voteAverage: voteAverage ?? this.voteAverage,
  );
  MoviesTableData copyWithCompanion(MoviesTableCompanion data) {
    return MoviesTableData(
      id: data.id.present ? data.id.value : this.id,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      imdbId: data.imdbId.present ? data.imdbId.value : this.imdbId,
      title: data.title.present ? data.title.value : this.title,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      runtimeMinutes: data.runtimeMinutes.present
          ? data.runtimeMinutes.value
          : this.runtimeMinutes,
      genres: data.genres.present ? data.genres.value : this.genres,
      isWatched: data.isWatched.present ? data.isWatched.value : this.isWatched,
      isFollowed: data.isFollowed.present
          ? data.isFollowed.value
          : this.isFollowed,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
      rewatchCount: data.rewatchCount.present
          ? data.rewatchCount.value
          : this.rewatchCount,
      voteAverage: data.voteAverage.present
          ? data.voteAverage.value
          : this.voteAverage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoviesTableData(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('imdbId: $imdbId, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('genres: $genres, ')
          ..write('isWatched: $isWatched, ')
          ..write('isFollowed: $isFollowed, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rewatchCount: $rewatchCount, ')
          ..write('voteAverage: $voteAverage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tmdbId,
    imdbId,
    title,
    overview,
    posterPath,
    backdropPath,
    releaseDate,
    runtimeMinutes,
    genres,
    isWatched,
    isFollowed,
    watchedAt,
    rewatchCount,
    voteAverage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoviesTableData &&
          other.id == this.id &&
          other.tmdbId == this.tmdbId &&
          other.imdbId == this.imdbId &&
          other.title == this.title &&
          other.overview == this.overview &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.releaseDate == this.releaseDate &&
          other.runtimeMinutes == this.runtimeMinutes &&
          other.genres == this.genres &&
          other.isWatched == this.isWatched &&
          other.isFollowed == this.isFollowed &&
          other.watchedAt == this.watchedAt &&
          other.rewatchCount == this.rewatchCount &&
          other.voteAverage == this.voteAverage);
}

class MoviesTableCompanion extends UpdateCompanion<MoviesTableData> {
  final Value<int> id;
  final Value<int?> tmdbId;
  final Value<String?> imdbId;
  final Value<String> title;
  final Value<String?> overview;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<DateTime?> releaseDate;
  final Value<int> runtimeMinutes;
  final Value<String> genres;
  final Value<bool> isWatched;
  final Value<bool> isFollowed;
  final Value<DateTime?> watchedAt;
  final Value<int> rewatchCount;
  final Value<double> voteAverage;
  const MoviesTableCompanion({
    this.id = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.genres = const Value.absent(),
    this.isWatched = const Value.absent(),
    this.isFollowed = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.rewatchCount = const Value.absent(),
    this.voteAverage = const Value.absent(),
  });
  MoviesTableCompanion.insert({
    this.id = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.imdbId = const Value.absent(),
    required String title,
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.genres = const Value.absent(),
    this.isWatched = const Value.absent(),
    this.isFollowed = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.rewatchCount = const Value.absent(),
    this.voteAverage = const Value.absent(),
  }) : title = Value(title);
  static Insertable<MoviesTableData> custom({
    Expression<int>? id,
    Expression<int>? tmdbId,
    Expression<String>? imdbId,
    Expression<String>? title,
    Expression<String>? overview,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<DateTime>? releaseDate,
    Expression<int>? runtimeMinutes,
    Expression<String>? genres,
    Expression<bool>? isWatched,
    Expression<bool>? isFollowed,
    Expression<DateTime>? watchedAt,
    Expression<int>? rewatchCount,
    Expression<double>? voteAverage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (imdbId != null) 'imdb_id': imdbId,
      if (title != null) 'title': title,
      if (overview != null) 'overview': overview,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (releaseDate != null) 'release_date': releaseDate,
      if (runtimeMinutes != null) 'runtime_minutes': runtimeMinutes,
      if (genres != null) 'genres': genres,
      if (isWatched != null) 'is_watched': isWatched,
      if (isFollowed != null) 'is_followed': isFollowed,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (rewatchCount != null) 'rewatch_count': rewatchCount,
      if (voteAverage != null) 'vote_average': voteAverage,
    });
  }

  MoviesTableCompanion copyWith({
    Value<int>? id,
    Value<int?>? tmdbId,
    Value<String?>? imdbId,
    Value<String>? title,
    Value<String?>? overview,
    Value<String?>? posterPath,
    Value<String?>? backdropPath,
    Value<DateTime?>? releaseDate,
    Value<int>? runtimeMinutes,
    Value<String>? genres,
    Value<bool>? isWatched,
    Value<bool>? isFollowed,
    Value<DateTime?>? watchedAt,
    Value<int>? rewatchCount,
    Value<double>? voteAverage,
  }) {
    return MoviesTableCompanion(
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

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (imdbId.present) {
      map['imdb_id'] = Variable<String>(imdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<DateTime>(releaseDate.value);
    }
    if (runtimeMinutes.present) {
      map['runtime_minutes'] = Variable<int>(runtimeMinutes.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (isWatched.present) {
      map['is_watched'] = Variable<bool>(isWatched.value);
    }
    if (isFollowed.present) {
      map['is_followed'] = Variable<bool>(isFollowed.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (rewatchCount.present) {
      map['rewatch_count'] = Variable<int>(rewatchCount.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesTableCompanion(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('imdbId: $imdbId, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('genres: $genres, ')
          ..write('isWatched: $isWatched, ')
          ..write('isFollowed: $isFollowed, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rewatchCount: $rewatchCount, ')
          ..write('voteAverage: $voteAverage')
          ..write(')'))
        .toString();
  }
}

class $MovieWatchHistoryTableTable extends MovieWatchHistoryTable
    with TableInfo<$MovieWatchHistoryTableTable, MovieWatchHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovieWatchHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _movieIdMeta = const VerificationMeta(
    'movieId',
  );
  @override
  late final GeneratedColumn<int> movieId = GeneratedColumn<int>(
    'movie_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runtimeMinutesMeta = const VerificationMeta(
    'runtimeMinutes',
  );
  @override
  late final GeneratedColumn<int> runtimeMinutes = GeneratedColumn<int>(
    'runtime_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rewatchCountMeta = const VerificationMeta(
    'rewatchCount',
  );
  @override
  late final GeneratedColumn<int> rewatchCount = GeneratedColumn<int>(
    'rewatch_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    movieId,
    tmdbId,
    title,
    runtimeMinutes,
    watchedAt,
    rewatchCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movie_watch_history_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovieWatchHistoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('movie_id')) {
      context.handle(
        _movieIdMeta,
        movieId.isAcceptableOrUnknown(data['movie_id']!, _movieIdMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('runtime_minutes')) {
      context.handle(
        _runtimeMinutesMeta,
        runtimeMinutes.isAcceptableOrUnknown(
          data['runtime_minutes']!,
          _runtimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    if (data.containsKey('rewatch_count')) {
      context.handle(
        _rewatchCountMeta,
        rewatchCount.isAcceptableOrUnknown(
          data['rewatch_count']!,
          _rewatchCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovieWatchHistoryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovieWatchHistoryTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      movieId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}movie_id'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      runtimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_minutes'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
      rewatchCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rewatch_count'],
      )!,
    );
  }

  @override
  $MovieWatchHistoryTableTable createAlias(String alias) {
    return $MovieWatchHistoryTableTable(attachedDatabase, alias);
  }
}

class MovieWatchHistoryTableData extends DataClass
    implements Insertable<MovieWatchHistoryTableData> {
  final int id;
  final int? movieId;
  final int? tmdbId;
  final String title;
  final int runtimeMinutes;
  final DateTime watchedAt;
  final int rewatchCount;
  const MovieWatchHistoryTableData({
    required this.id,
    this.movieId,
    this.tmdbId,
    required this.title,
    required this.runtimeMinutes,
    required this.watchedAt,
    required this.rewatchCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || movieId != null) {
      map['movie_id'] = Variable<int>(movieId);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    map['title'] = Variable<String>(title);
    map['runtime_minutes'] = Variable<int>(runtimeMinutes);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    map['rewatch_count'] = Variable<int>(rewatchCount);
    return map;
  }

  MovieWatchHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return MovieWatchHistoryTableCompanion(
      id: Value(id),
      movieId: movieId == null && nullToAbsent
          ? const Value.absent()
          : Value(movieId),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      title: Value(title),
      runtimeMinutes: Value(runtimeMinutes),
      watchedAt: Value(watchedAt),
      rewatchCount: Value(rewatchCount),
    );
  }

  factory MovieWatchHistoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovieWatchHistoryTableData(
      id: serializer.fromJson<int>(json['id']),
      movieId: serializer.fromJson<int?>(json['movieId']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      title: serializer.fromJson<String>(json['title']),
      runtimeMinutes: serializer.fromJson<int>(json['runtimeMinutes']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
      rewatchCount: serializer.fromJson<int>(json['rewatchCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'movieId': serializer.toJson<int?>(movieId),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'title': serializer.toJson<String>(title),
      'runtimeMinutes': serializer.toJson<int>(runtimeMinutes),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
      'rewatchCount': serializer.toJson<int>(rewatchCount),
    };
  }

  MovieWatchHistoryTableData copyWith({
    int? id,
    Value<int?> movieId = const Value.absent(),
    Value<int?> tmdbId = const Value.absent(),
    String? title,
    int? runtimeMinutes,
    DateTime? watchedAt,
    int? rewatchCount,
  }) => MovieWatchHistoryTableData(
    id: id ?? this.id,
    movieId: movieId.present ? movieId.value : this.movieId,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    title: title ?? this.title,
    runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
    watchedAt: watchedAt ?? this.watchedAt,
    rewatchCount: rewatchCount ?? this.rewatchCount,
  );
  MovieWatchHistoryTableData copyWithCompanion(
    MovieWatchHistoryTableCompanion data,
  ) {
    return MovieWatchHistoryTableData(
      id: data.id.present ? data.id.value : this.id,
      movieId: data.movieId.present ? data.movieId.value : this.movieId,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      title: data.title.present ? data.title.value : this.title,
      runtimeMinutes: data.runtimeMinutes.present
          ? data.runtimeMinutes.value
          : this.runtimeMinutes,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
      rewatchCount: data.rewatchCount.present
          ? data.rewatchCount.value
          : this.rewatchCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovieWatchHistoryTableData(')
          ..write('id: $id, ')
          ..write('movieId: $movieId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rewatchCount: $rewatchCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    movieId,
    tmdbId,
    title,
    runtimeMinutes,
    watchedAt,
    rewatchCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovieWatchHistoryTableData &&
          other.id == this.id &&
          other.movieId == this.movieId &&
          other.tmdbId == this.tmdbId &&
          other.title == this.title &&
          other.runtimeMinutes == this.runtimeMinutes &&
          other.watchedAt == this.watchedAt &&
          other.rewatchCount == this.rewatchCount);
}

class MovieWatchHistoryTableCompanion
    extends UpdateCompanion<MovieWatchHistoryTableData> {
  final Value<int> id;
  final Value<int?> movieId;
  final Value<int?> tmdbId;
  final Value<String> title;
  final Value<int> runtimeMinutes;
  final Value<DateTime> watchedAt;
  final Value<int> rewatchCount;
  const MovieWatchHistoryTableCompanion({
    this.id = const Value.absent(),
    this.movieId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.rewatchCount = const Value.absent(),
  });
  MovieWatchHistoryTableCompanion.insert({
    this.id = const Value.absent(),
    this.movieId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    required String title,
    this.runtimeMinutes = const Value.absent(),
    required DateTime watchedAt,
    this.rewatchCount = const Value.absent(),
  }) : title = Value(title),
       watchedAt = Value(watchedAt);
  static Insertable<MovieWatchHistoryTableData> custom({
    Expression<int>? id,
    Expression<int>? movieId,
    Expression<int>? tmdbId,
    Expression<String>? title,
    Expression<int>? runtimeMinutes,
    Expression<DateTime>? watchedAt,
    Expression<int>? rewatchCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (movieId != null) 'movie_id': movieId,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (runtimeMinutes != null) 'runtime_minutes': runtimeMinutes,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (rewatchCount != null) 'rewatch_count': rewatchCount,
    });
  }

  MovieWatchHistoryTableCompanion copyWith({
    Value<int>? id,
    Value<int?>? movieId,
    Value<int?>? tmdbId,
    Value<String>? title,
    Value<int>? runtimeMinutes,
    Value<DateTime>? watchedAt,
    Value<int>? rewatchCount,
  }) {
    return MovieWatchHistoryTableCompanion(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      watchedAt: watchedAt ?? this.watchedAt,
      rewatchCount: rewatchCount ?? this.rewatchCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (movieId.present) {
      map['movie_id'] = Variable<int>(movieId.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (runtimeMinutes.present) {
      map['runtime_minutes'] = Variable<int>(runtimeMinutes.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (rewatchCount.present) {
      map['rewatch_count'] = Variable<int>(rewatchCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovieWatchHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('movieId: $movieId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rewatchCount: $rewatchCount')
          ..write(')'))
        .toString();
  }
}

class $ImportQueueTableTable extends ImportQueueTable
    with TableInfo<$ImportQueueTableTable, ImportQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tvdbIdMeta = const VerificationMeta('tvdbId');
  @override
  late final GeneratedColumn<int> tvdbId = GeneratedColumn<int>(
    'tvdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tvdbId,
    tmdbId,
    mediaType,
    status,
    errorMessage,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tvdb_id')) {
      context.handle(
        _tvdbIdMeta,
        tvdbId.isAcceptableOrUnknown(data['tvdb_id']!, _tvdbIdMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tvdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tvdb_id'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ImportQueueTableTable createAlias(String alias) {
    return $ImportQueueTableTable(attachedDatabase, alias);
  }
}

class ImportQueueTableData extends DataClass
    implements Insertable<ImportQueueTableData> {
  final int id;
  final int? tvdbId;
  final int? tmdbId;
  final String mediaType;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;
  const ImportQueueTableData({
    required this.id,
    this.tvdbId,
    this.tmdbId,
    required this.mediaType,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || tvdbId != null) {
      map['tvdb_id'] = Variable<int>(tvdbId);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    map['media_type'] = Variable<String>(mediaType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ImportQueueTableCompanion toCompanion(bool nullToAbsent) {
    return ImportQueueTableCompanion(
      id: Value(id),
      tvdbId: tvdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tvdbId),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      mediaType: Value(mediaType),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
    );
  }

  factory ImportQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      tvdbId: serializer.fromJson<int?>(json['tvdbId']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tvdbId': serializer.toJson<int?>(tvdbId),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'mediaType': serializer.toJson<String>(mediaType),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ImportQueueTableData copyWith({
    int? id,
    Value<int?> tvdbId = const Value.absent(),
    Value<int?> tmdbId = const Value.absent(),
    String? mediaType,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
  }) => ImportQueueTableData(
    id: id ?? this.id,
    tvdbId: tvdbId.present ? tvdbId.value : this.tvdbId,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    mediaType: mediaType ?? this.mediaType,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
  );
  ImportQueueTableData copyWithCompanion(ImportQueueTableCompanion data) {
    return ImportQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      tvdbId: data.tvdbId.present ? data.tvdbId.value : this.tvdbId,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportQueueTableData(')
          ..write('id: $id, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tvdbId,
    tmdbId,
    mediaType,
    status,
    errorMessage,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportQueueTableData &&
          other.id == this.id &&
          other.tvdbId == this.tvdbId &&
          other.tmdbId == this.tmdbId &&
          other.mediaType == this.mediaType &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt);
}

class ImportQueueTableCompanion extends UpdateCompanion<ImportQueueTableData> {
  final Value<int> id;
  final Value<int?> tvdbId;
  final Value<int?> tmdbId;
  final Value<String> mediaType;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  const ImportQueueTableCompanion({
    this.id = const Value.absent(),
    this.tvdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ImportQueueTableCompanion.insert({
    this.id = const Value.absent(),
    this.tvdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    required String mediaType,
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
  }) : mediaType = Value(mediaType),
       createdAt = Value(createdAt);
  static Insertable<ImportQueueTableData> custom({
    Expression<int>? id,
    Expression<int>? tvdbId,
    Expression<int>? tmdbId,
    Expression<String>? mediaType,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tvdbId != null) 'tvdb_id': tvdbId,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (mediaType != null) 'media_type': mediaType,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ImportQueueTableCompanion copyWith({
    Value<int>? id,
    Value<int?>? tvdbId,
    Value<int?>? tmdbId,
    Value<String>? mediaType,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
  }) {
    return ImportQueueTableCompanion(
      id: id ?? this.id,
      tvdbId: tvdbId ?? this.tvdbId,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tvdbId.present) {
      map['tvdb_id'] = Variable<int>(tvdbId.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ShowsTableTable showsTable = $ShowsTableTable(this);
  late final $SeasonsTableTable seasonsTable = $SeasonsTableTable(this);
  late final $EpisodesTableTable episodesTable = $EpisodesTableTable(this);
  late final $EpisodeWatchHistoryTableTable episodeWatchHistoryTable =
      $EpisodeWatchHistoryTableTable(this);
  late final $MoviesTableTable moviesTable = $MoviesTableTable(this);
  late final $MovieWatchHistoryTableTable movieWatchHistoryTable =
      $MovieWatchHistoryTableTable(this);
  late final $ImportQueueTableTable importQueueTable = $ImportQueueTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    showsTable,
    seasonsTable,
    episodesTable,
    episodeWatchHistoryTable,
    moviesTable,
    movieWatchHistoryTable,
    importQueueTable,
  ];
}

typedef $$ShowsTableTableCreateCompanionBuilder =
    ShowsTableCompanion Function({
      Value<int> id,
      Value<int?> tmdbId,
      Value<int?> tvdbId,
      required String name,
      Value<String?> originalName,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<String?> status,
      Value<int> totalSeasons,
      Value<int> totalEpisodes,
      Value<String> genres,
      Value<bool> isFollowed,
      Value<int> watchedEpisodesCount,
      Value<double> voteAverage,
      Value<DateTime?> firstAirDate,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$ShowsTableTableUpdateCompanionBuilder =
    ShowsTableCompanion Function({
      Value<int> id,
      Value<int?> tmdbId,
      Value<int?> tvdbId,
      Value<String> name,
      Value<String?> originalName,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<String?> status,
      Value<int> totalSeasons,
      Value<int> totalEpisodes,
      Value<String> genres,
      Value<bool> isFollowed,
      Value<int> watchedEpisodesCount,
      Value<double> voteAverage,
      Value<DateTime?> firstAirDate,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
    });

class $$ShowsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ShowsTableTable> {
  $$ShowsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeasons => $composableBuilder(
    column: $table.totalSeasons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFollowed => $composableBuilder(
    column: $table.isFollowed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get watchedEpisodesCount => $composableBuilder(
    column: $table.watchedEpisodesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstAirDate => $composableBuilder(
    column: $table.firstAirDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShowsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ShowsTableTable> {
  $$ShowsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeasons => $composableBuilder(
    column: $table.totalSeasons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFollowed => $composableBuilder(
    column: $table.isFollowed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get watchedEpisodesCount => $composableBuilder(
    column: $table.watchedEpisodesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstAirDate => $composableBuilder(
    column: $table.firstAirDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShowsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShowsTableTable> {
  $$ShowsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<int> get tvdbId =>
      $composableBuilder(column: $table.tvdbId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalSeasons => $composableBuilder(
    column: $table.totalSeasons,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<bool> get isFollowed => $composableBuilder(
    column: $table.isFollowed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get watchedEpisodesCount => $composableBuilder(
    column: $table.watchedEpisodesCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstAirDate => $composableBuilder(
    column: $table.firstAirDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShowsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShowsTableTable,
          ShowsTableData,
          $$ShowsTableTableFilterComposer,
          $$ShowsTableTableOrderingComposer,
          $$ShowsTableTableAnnotationComposer,
          $$ShowsTableTableCreateCompanionBuilder,
          $$ShowsTableTableUpdateCompanionBuilder,
          (
            ShowsTableData,
            BaseReferences<_$AppDatabase, $ShowsTableTable, ShowsTableData>,
          ),
          ShowsTableData,
          PrefetchHooks Function()
        > {
  $$ShowsTableTableTableManager(_$AppDatabase db, $ShowsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShowsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShowsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShowsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> originalName = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> totalSeasons = const Value.absent(),
                Value<int> totalEpisodes = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<bool> isFollowed = const Value.absent(),
                Value<int> watchedEpisodesCount = const Value.absent(),
                Value<double> voteAverage = const Value.absent(),
                Value<DateTime?> firstAirDate = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => ShowsTableCompanion(
                id: id,
                tmdbId: tmdbId,
                tvdbId: tvdbId,
                name: name,
                originalName: originalName,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                status: status,
                totalSeasons: totalSeasons,
                totalEpisodes: totalEpisodes,
                genres: genres,
                isFollowed: isFollowed,
                watchedEpisodesCount: watchedEpisodesCount,
                voteAverage: voteAverage,
                firstAirDate: firstAirDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                required String name,
                Value<String?> originalName = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> totalSeasons = const Value.absent(),
                Value<int> totalEpisodes = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<bool> isFollowed = const Value.absent(),
                Value<int> watchedEpisodesCount = const Value.absent(),
                Value<double> voteAverage = const Value.absent(),
                Value<DateTime?> firstAirDate = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => ShowsTableCompanion.insert(
                id: id,
                tmdbId: tmdbId,
                tvdbId: tvdbId,
                name: name,
                originalName: originalName,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                status: status,
                totalSeasons: totalSeasons,
                totalEpisodes: totalEpisodes,
                genres: genres,
                isFollowed: isFollowed,
                watchedEpisodesCount: watchedEpisodesCount,
                voteAverage: voteAverage,
                firstAirDate: firstAirDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShowsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShowsTableTable,
      ShowsTableData,
      $$ShowsTableTableFilterComposer,
      $$ShowsTableTableOrderingComposer,
      $$ShowsTableTableAnnotationComposer,
      $$ShowsTableTableCreateCompanionBuilder,
      $$ShowsTableTableUpdateCompanionBuilder,
      (
        ShowsTableData,
        BaseReferences<_$AppDatabase, $ShowsTableTable, ShowsTableData>,
      ),
      ShowsTableData,
      PrefetchHooks Function()
    >;
typedef $$SeasonsTableTableCreateCompanionBuilder =
    SeasonsTableCompanion Function({
      Value<int> id,
      required int showId,
      required int seasonNumber,
      required String name,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<int> episodeCount,
      Value<DateTime?> airDate,
    });
typedef $$SeasonsTableTableUpdateCompanionBuilder =
    SeasonsTableCompanion Function({
      Value<int> id,
      Value<int> showId,
      Value<int> seasonNumber,
      Value<String> name,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<int> episodeCount,
      Value<DateTime?> airDate,
    });

class $$SeasonsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeasonsTableTable> {
  $$SeasonsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get showId => $composableBuilder(
    column: $table.showId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get airDate => $composableBuilder(
    column: $table.airDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeasonsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeasonsTableTable> {
  $$SeasonsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get showId => $composableBuilder(
    column: $table.showId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get airDate => $composableBuilder(
    column: $table.airDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeasonsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeasonsTableTable> {
  $$SeasonsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get showId =>
      $composableBuilder(column: $table.showId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => column);
}

class $$SeasonsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeasonsTableTable,
          SeasonsTableData,
          $$SeasonsTableTableFilterComposer,
          $$SeasonsTableTableOrderingComposer,
          $$SeasonsTableTableAnnotationComposer,
          $$SeasonsTableTableCreateCompanionBuilder,
          $$SeasonsTableTableUpdateCompanionBuilder,
          (
            SeasonsTableData,
            BaseReferences<_$AppDatabase, $SeasonsTableTable, SeasonsTableData>,
          ),
          SeasonsTableData,
          PrefetchHooks Function()
        > {
  $$SeasonsTableTableTableManager(_$AppDatabase db, $SeasonsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeasonsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeasonsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> showId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<int> episodeCount = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
              }) => SeasonsTableCompanion(
                id: id,
                showId: showId,
                seasonNumber: seasonNumber,
                name: name,
                overview: overview,
                posterPath: posterPath,
                episodeCount: episodeCount,
                airDate: airDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int showId,
                required int seasonNumber,
                required String name,
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<int> episodeCount = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
              }) => SeasonsTableCompanion.insert(
                id: id,
                showId: showId,
                seasonNumber: seasonNumber,
                name: name,
                overview: overview,
                posterPath: posterPath,
                episodeCount: episodeCount,
                airDate: airDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeasonsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeasonsTableTable,
      SeasonsTableData,
      $$SeasonsTableTableFilterComposer,
      $$SeasonsTableTableOrderingComposer,
      $$SeasonsTableTableAnnotationComposer,
      $$SeasonsTableTableCreateCompanionBuilder,
      $$SeasonsTableTableUpdateCompanionBuilder,
      (
        SeasonsTableData,
        BaseReferences<_$AppDatabase, $SeasonsTableTable, SeasonsTableData>,
      ),
      SeasonsTableData,
      PrefetchHooks Function()
    >;
typedef $$EpisodesTableTableCreateCompanionBuilder =
    EpisodesTableCompanion Function({
      Value<int> id,
      required int showId,
      required int seasonId,
      required int seasonNumber,
      required int episodeNumber,
      Value<int?> tvdbId,
      Value<int?> tmdbId,
      required String name,
      Value<String?> overview,
      Value<String?> stillPath,
      Value<int> runtimeMinutes,
      Value<DateTime?> airDate,
      Value<double> voteAverage,
      Value<bool> isWatched,
      Value<int> rewatchCount,
      Value<DateTime?> lastWatchedAt,
    });
typedef $$EpisodesTableTableUpdateCompanionBuilder =
    EpisodesTableCompanion Function({
      Value<int> id,
      Value<int> showId,
      Value<int> seasonId,
      Value<int> seasonNumber,
      Value<int> episodeNumber,
      Value<int?> tvdbId,
      Value<int?> tmdbId,
      Value<String> name,
      Value<String?> overview,
      Value<String?> stillPath,
      Value<int> runtimeMinutes,
      Value<DateTime?> airDate,
      Value<double> voteAverage,
      Value<bool> isWatched,
      Value<int> rewatchCount,
      Value<DateTime?> lastWatchedAt,
    });

class $$EpisodesTableTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTableTable> {
  $$EpisodesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get showId => $composableBuilder(
    column: $table.showId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stillPath => $composableBuilder(
    column: $table.stillPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get airDate => $composableBuilder(
    column: $table.airDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWatched => $composableBuilder(
    column: $table.isWatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTableTable> {
  $$EpisodesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get showId => $composableBuilder(
    column: $table.showId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stillPath => $composableBuilder(
    column: $table.stillPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get airDate => $composableBuilder(
    column: $table.airDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWatched => $composableBuilder(
    column: $table.isWatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTableTable> {
  $$EpisodesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get showId =>
      $composableBuilder(column: $table.showId, builder: (column) => column);

  GeneratedColumn<int> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tvdbId =>
      $composableBuilder(column: $table.tvdbId, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get stillPath =>
      $composableBuilder(column: $table.stillPath, builder: (column) => column);

  GeneratedColumn<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => column);

  GeneratedColumn<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWatched =>
      $composableBuilder(column: $table.isWatched, builder: (column) => column);

  GeneratedColumn<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => column,
  );
}

class $$EpisodesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTableTable,
          EpisodesTableData,
          $$EpisodesTableTableFilterComposer,
          $$EpisodesTableTableOrderingComposer,
          $$EpisodesTableTableAnnotationComposer,
          $$EpisodesTableTableCreateCompanionBuilder,
          $$EpisodesTableTableUpdateCompanionBuilder,
          (
            EpisodesTableData,
            BaseReferences<
              _$AppDatabase,
              $EpisodesTableTable,
              EpisodesTableData
            >,
          ),
          EpisodesTableData,
          PrefetchHooks Function()
        > {
  $$EpisodesTableTableTableManager(_$AppDatabase db, $EpisodesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> showId = const Value.absent(),
                Value<int> seasonId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> stillPath = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
                Value<double> voteAverage = const Value.absent(),
                Value<bool> isWatched = const Value.absent(),
                Value<int> rewatchCount = const Value.absent(),
                Value<DateTime?> lastWatchedAt = const Value.absent(),
              }) => EpisodesTableCompanion(
                id: id,
                showId: showId,
                seasonId: seasonId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                tvdbId: tvdbId,
                tmdbId: tmdbId,
                name: name,
                overview: overview,
                stillPath: stillPath,
                runtimeMinutes: runtimeMinutes,
                airDate: airDate,
                voteAverage: voteAverage,
                isWatched: isWatched,
                rewatchCount: rewatchCount,
                lastWatchedAt: lastWatchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int showId,
                required int seasonId,
                required int seasonNumber,
                required int episodeNumber,
                Value<int?> tvdbId = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                required String name,
                Value<String?> overview = const Value.absent(),
                Value<String?> stillPath = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
                Value<double> voteAverage = const Value.absent(),
                Value<bool> isWatched = const Value.absent(),
                Value<int> rewatchCount = const Value.absent(),
                Value<DateTime?> lastWatchedAt = const Value.absent(),
              }) => EpisodesTableCompanion.insert(
                id: id,
                showId: showId,
                seasonId: seasonId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                tvdbId: tvdbId,
                tmdbId: tmdbId,
                name: name,
                overview: overview,
                stillPath: stillPath,
                runtimeMinutes: runtimeMinutes,
                airDate: airDate,
                voteAverage: voteAverage,
                isWatched: isWatched,
                rewatchCount: rewatchCount,
                lastWatchedAt: lastWatchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTableTable,
      EpisodesTableData,
      $$EpisodesTableTableFilterComposer,
      $$EpisodesTableTableOrderingComposer,
      $$EpisodesTableTableAnnotationComposer,
      $$EpisodesTableTableCreateCompanionBuilder,
      $$EpisodesTableTableUpdateCompanionBuilder,
      (
        EpisodesTableData,
        BaseReferences<_$AppDatabase, $EpisodesTableTable, EpisodesTableData>,
      ),
      EpisodesTableData,
      PrefetchHooks Function()
    >;
typedef $$EpisodeWatchHistoryTableTableCreateCompanionBuilder =
    EpisodeWatchHistoryTableCompanion Function({
      Value<int> id,
      Value<int?> episodeId,
      Value<int?> showId,
      Value<int?> tvdbId,
      Value<int?> sId,
      Value<int> seasonNumber,
      Value<int> episodeNumber,
      required String title,
      Value<int> runtimeMinutes,
      required DateTime watchedAt,
      Value<int> rewatchCount,
    });
typedef $$EpisodeWatchHistoryTableTableUpdateCompanionBuilder =
    EpisodeWatchHistoryTableCompanion Function({
      Value<int> id,
      Value<int?> episodeId,
      Value<int?> showId,
      Value<int?> tvdbId,
      Value<int?> sId,
      Value<int> seasonNumber,
      Value<int> episodeNumber,
      Value<String> title,
      Value<int> runtimeMinutes,
      Value<DateTime> watchedAt,
      Value<int> rewatchCount,
    });

class $$EpisodeWatchHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodeWatchHistoryTableTable> {
  $$EpisodeWatchHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get showId => $composableBuilder(
    column: $table.showId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sId => $composableBuilder(
    column: $table.sId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodeWatchHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodeWatchHistoryTableTable> {
  $$EpisodeWatchHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get showId => $composableBuilder(
    column: $table.showId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sId => $composableBuilder(
    column: $table.sId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodeWatchHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodeWatchHistoryTableTable> {
  $$EpisodeWatchHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get showId =>
      $composableBuilder(column: $table.showId, builder: (column) => column);

  GeneratedColumn<int> get tvdbId =>
      $composableBuilder(column: $table.tvdbId, builder: (column) => column);

  GeneratedColumn<int> get sId =>
      $composableBuilder(column: $table.sId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  GeneratedColumn<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => column,
  );
}

class $$EpisodeWatchHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodeWatchHistoryTableTable,
          EpisodeWatchHistoryTableData,
          $$EpisodeWatchHistoryTableTableFilterComposer,
          $$EpisodeWatchHistoryTableTableOrderingComposer,
          $$EpisodeWatchHistoryTableTableAnnotationComposer,
          $$EpisodeWatchHistoryTableTableCreateCompanionBuilder,
          $$EpisodeWatchHistoryTableTableUpdateCompanionBuilder,
          (
            EpisodeWatchHistoryTableData,
            BaseReferences<
              _$AppDatabase,
              $EpisodeWatchHistoryTableTable,
              EpisodeWatchHistoryTableData
            >,
          ),
          EpisodeWatchHistoryTableData,
          PrefetchHooks Function()
        > {
  $$EpisodeWatchHistoryTableTableTableManager(
    _$AppDatabase db,
    $EpisodeWatchHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodeWatchHistoryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EpisodeWatchHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EpisodeWatchHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> episodeId = const Value.absent(),
                Value<int?> showId = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                Value<int?> sId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<int> rewatchCount = const Value.absent(),
              }) => EpisodeWatchHistoryTableCompanion(
                id: id,
                episodeId: episodeId,
                showId: showId,
                tvdbId: tvdbId,
                sId: sId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                title: title,
                runtimeMinutes: runtimeMinutes,
                watchedAt: watchedAt,
                rewatchCount: rewatchCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> episodeId = const Value.absent(),
                Value<int?> showId = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                Value<int?> sId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                required String title,
                Value<int> runtimeMinutes = const Value.absent(),
                required DateTime watchedAt,
                Value<int> rewatchCount = const Value.absent(),
              }) => EpisodeWatchHistoryTableCompanion.insert(
                id: id,
                episodeId: episodeId,
                showId: showId,
                tvdbId: tvdbId,
                sId: sId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                title: title,
                runtimeMinutes: runtimeMinutes,
                watchedAt: watchedAt,
                rewatchCount: rewatchCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodeWatchHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodeWatchHistoryTableTable,
      EpisodeWatchHistoryTableData,
      $$EpisodeWatchHistoryTableTableFilterComposer,
      $$EpisodeWatchHistoryTableTableOrderingComposer,
      $$EpisodeWatchHistoryTableTableAnnotationComposer,
      $$EpisodeWatchHistoryTableTableCreateCompanionBuilder,
      $$EpisodeWatchHistoryTableTableUpdateCompanionBuilder,
      (
        EpisodeWatchHistoryTableData,
        BaseReferences<
          _$AppDatabase,
          $EpisodeWatchHistoryTableTable,
          EpisodeWatchHistoryTableData
        >,
      ),
      EpisodeWatchHistoryTableData,
      PrefetchHooks Function()
    >;
typedef $$MoviesTableTableCreateCompanionBuilder =
    MoviesTableCompanion Function({
      Value<int> id,
      Value<int?> tmdbId,
      Value<String?> imdbId,
      required String title,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<DateTime?> releaseDate,
      Value<int> runtimeMinutes,
      Value<String> genres,
      Value<bool> isWatched,
      Value<bool> isFollowed,
      Value<DateTime?> watchedAt,
      Value<int> rewatchCount,
      Value<double> voteAverage,
    });
typedef $$MoviesTableTableUpdateCompanionBuilder =
    MoviesTableCompanion Function({
      Value<int> id,
      Value<int?> tmdbId,
      Value<String?> imdbId,
      Value<String> title,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<DateTime?> releaseDate,
      Value<int> runtimeMinutes,
      Value<String> genres,
      Value<bool> isWatched,
      Value<bool> isFollowed,
      Value<DateTime?> watchedAt,
      Value<int> rewatchCount,
      Value<double> voteAverage,
    });

class $$MoviesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MoviesTableTable> {
  $$MoviesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWatched => $composableBuilder(
    column: $table.isWatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFollowed => $composableBuilder(
    column: $table.isFollowed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoviesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MoviesTableTable> {
  $$MoviesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWatched => $composableBuilder(
    column: $table.isWatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFollowed => $composableBuilder(
    column: $table.isFollowed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoviesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoviesTableTable> {
  $$MoviesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get imdbId =>
      $composableBuilder(column: $table.imdbId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<bool> get isWatched =>
      $composableBuilder(column: $table.isWatched, builder: (column) => column);

  GeneratedColumn<bool> get isFollowed => $composableBuilder(
    column: $table.isFollowed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  GeneratedColumn<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => column,
  );
}

class $$MoviesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoviesTableTable,
          MoviesTableData,
          $$MoviesTableTableFilterComposer,
          $$MoviesTableTableOrderingComposer,
          $$MoviesTableTableAnnotationComposer,
          $$MoviesTableTableCreateCompanionBuilder,
          $$MoviesTableTableUpdateCompanionBuilder,
          (
            MoviesTableData,
            BaseReferences<_$AppDatabase, $MoviesTableTable, MoviesTableData>,
          ),
          MoviesTableData,
          PrefetchHooks Function()
        > {
  $$MoviesTableTableTableManager(_$AppDatabase db, $MoviesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoviesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoviesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoviesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<bool> isWatched = const Value.absent(),
                Value<bool> isFollowed = const Value.absent(),
                Value<DateTime?> watchedAt = const Value.absent(),
                Value<int> rewatchCount = const Value.absent(),
                Value<double> voteAverage = const Value.absent(),
              }) => MoviesTableCompanion(
                id: id,
                tmdbId: tmdbId,
                imdbId: imdbId,
                title: title,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                releaseDate: releaseDate,
                runtimeMinutes: runtimeMinutes,
                genres: genres,
                isWatched: isWatched,
                isFollowed: isFollowed,
                watchedAt: watchedAt,
                rewatchCount: rewatchCount,
                voteAverage: voteAverage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                required String title,
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<bool> isWatched = const Value.absent(),
                Value<bool> isFollowed = const Value.absent(),
                Value<DateTime?> watchedAt = const Value.absent(),
                Value<int> rewatchCount = const Value.absent(),
                Value<double> voteAverage = const Value.absent(),
              }) => MoviesTableCompanion.insert(
                id: id,
                tmdbId: tmdbId,
                imdbId: imdbId,
                title: title,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                releaseDate: releaseDate,
                runtimeMinutes: runtimeMinutes,
                genres: genres,
                isWatched: isWatched,
                isFollowed: isFollowed,
                watchedAt: watchedAt,
                rewatchCount: rewatchCount,
                voteAverage: voteAverage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoviesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoviesTableTable,
      MoviesTableData,
      $$MoviesTableTableFilterComposer,
      $$MoviesTableTableOrderingComposer,
      $$MoviesTableTableAnnotationComposer,
      $$MoviesTableTableCreateCompanionBuilder,
      $$MoviesTableTableUpdateCompanionBuilder,
      (
        MoviesTableData,
        BaseReferences<_$AppDatabase, $MoviesTableTable, MoviesTableData>,
      ),
      MoviesTableData,
      PrefetchHooks Function()
    >;
typedef $$MovieWatchHistoryTableTableCreateCompanionBuilder =
    MovieWatchHistoryTableCompanion Function({
      Value<int> id,
      Value<int?> movieId,
      Value<int?> tmdbId,
      required String title,
      Value<int> runtimeMinutes,
      required DateTime watchedAt,
      Value<int> rewatchCount,
    });
typedef $$MovieWatchHistoryTableTableUpdateCompanionBuilder =
    MovieWatchHistoryTableCompanion Function({
      Value<int> id,
      Value<int?> movieId,
      Value<int?> tmdbId,
      Value<String> title,
      Value<int> runtimeMinutes,
      Value<DateTime> watchedAt,
      Value<int> rewatchCount,
    });

class $$MovieWatchHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $MovieWatchHistoryTableTable> {
  $$MovieWatchHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movieId => $composableBuilder(
    column: $table.movieId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MovieWatchHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MovieWatchHistoryTableTable> {
  $$MovieWatchHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movieId => $composableBuilder(
    column: $table.movieId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovieWatchHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovieWatchHistoryTableTable> {
  $$MovieWatchHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get movieId =>
      $composableBuilder(column: $table.movieId, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  GeneratedColumn<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => column,
  );
}

class $$MovieWatchHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovieWatchHistoryTableTable,
          MovieWatchHistoryTableData,
          $$MovieWatchHistoryTableTableFilterComposer,
          $$MovieWatchHistoryTableTableOrderingComposer,
          $$MovieWatchHistoryTableTableAnnotationComposer,
          $$MovieWatchHistoryTableTableCreateCompanionBuilder,
          $$MovieWatchHistoryTableTableUpdateCompanionBuilder,
          (
            MovieWatchHistoryTableData,
            BaseReferences<
              _$AppDatabase,
              $MovieWatchHistoryTableTable,
              MovieWatchHistoryTableData
            >,
          ),
          MovieWatchHistoryTableData,
          PrefetchHooks Function()
        > {
  $$MovieWatchHistoryTableTableTableManager(
    _$AppDatabase db,
    $MovieWatchHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovieWatchHistoryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MovieWatchHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MovieWatchHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> movieId = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<int> rewatchCount = const Value.absent(),
              }) => MovieWatchHistoryTableCompanion(
                id: id,
                movieId: movieId,
                tmdbId: tmdbId,
                title: title,
                runtimeMinutes: runtimeMinutes,
                watchedAt: watchedAt,
                rewatchCount: rewatchCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> movieId = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                required String title,
                Value<int> runtimeMinutes = const Value.absent(),
                required DateTime watchedAt,
                Value<int> rewatchCount = const Value.absent(),
              }) => MovieWatchHistoryTableCompanion.insert(
                id: id,
                movieId: movieId,
                tmdbId: tmdbId,
                title: title,
                runtimeMinutes: runtimeMinutes,
                watchedAt: watchedAt,
                rewatchCount: rewatchCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MovieWatchHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovieWatchHistoryTableTable,
      MovieWatchHistoryTableData,
      $$MovieWatchHistoryTableTableFilterComposer,
      $$MovieWatchHistoryTableTableOrderingComposer,
      $$MovieWatchHistoryTableTableAnnotationComposer,
      $$MovieWatchHistoryTableTableCreateCompanionBuilder,
      $$MovieWatchHistoryTableTableUpdateCompanionBuilder,
      (
        MovieWatchHistoryTableData,
        BaseReferences<
          _$AppDatabase,
          $MovieWatchHistoryTableTable,
          MovieWatchHistoryTableData
        >,
      ),
      MovieWatchHistoryTableData,
      PrefetchHooks Function()
    >;
typedef $$ImportQueueTableTableCreateCompanionBuilder =
    ImportQueueTableCompanion Function({
      Value<int> id,
      Value<int?> tvdbId,
      Value<int?> tmdbId,
      required String mediaType,
      Value<String> status,
      Value<String?> errorMessage,
      required DateTime createdAt,
    });
typedef $$ImportQueueTableTableUpdateCompanionBuilder =
    ImportQueueTableCompanion Function({
      Value<int> id,
      Value<int?> tvdbId,
      Value<int?> tmdbId,
      Value<String> mediaType,
      Value<String> status,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
    });

class $$ImportQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $ImportQueueTableTable> {
  $$ImportQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportQueueTableTable> {
  $$ImportQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportQueueTableTable> {
  $$ImportQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tvdbId =>
      $composableBuilder(column: $table.tvdbId, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ImportQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportQueueTableTable,
          ImportQueueTableData,
          $$ImportQueueTableTableFilterComposer,
          $$ImportQueueTableTableOrderingComposer,
          $$ImportQueueTableTableAnnotationComposer,
          $$ImportQueueTableTableCreateCompanionBuilder,
          $$ImportQueueTableTableUpdateCompanionBuilder,
          (
            ImportQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $ImportQueueTableTable,
              ImportQueueTableData
            >,
          ),
          ImportQueueTableData,
          PrefetchHooks Function()
        > {
  $$ImportQueueTableTableTableManager(
    _$AppDatabase db,
    $ImportQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ImportQueueTableCompanion(
                id: id,
                tvdbId: tvdbId,
                tmdbId: tmdbId,
                mediaType: mediaType,
                status: status,
                errorMessage: errorMessage,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                required String mediaType,
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
              }) => ImportQueueTableCompanion.insert(
                id: id,
                tvdbId: tvdbId,
                tmdbId: tmdbId,
                mediaType: mediaType,
                status: status,
                errorMessage: errorMessage,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportQueueTableTable,
      ImportQueueTableData,
      $$ImportQueueTableTableFilterComposer,
      $$ImportQueueTableTableOrderingComposer,
      $$ImportQueueTableTableAnnotationComposer,
      $$ImportQueueTableTableCreateCompanionBuilder,
      $$ImportQueueTableTableUpdateCompanionBuilder,
      (
        ImportQueueTableData,
        BaseReferences<
          _$AppDatabase,
          $ImportQueueTableTable,
          ImportQueueTableData
        >,
      ),
      ImportQueueTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ShowsTableTableTableManager get showsTable =>
      $$ShowsTableTableTableManager(_db, _db.showsTable);
  $$SeasonsTableTableTableManager get seasonsTable =>
      $$SeasonsTableTableTableManager(_db, _db.seasonsTable);
  $$EpisodesTableTableTableManager get episodesTable =>
      $$EpisodesTableTableTableManager(_db, _db.episodesTable);
  $$EpisodeWatchHistoryTableTableTableManager get episodeWatchHistoryTable =>
      $$EpisodeWatchHistoryTableTableTableManager(
        _db,
        _db.episodeWatchHistoryTable,
      );
  $$MoviesTableTableTableManager get moviesTable =>
      $$MoviesTableTableTableManager(_db, _db.moviesTable);
  $$MovieWatchHistoryTableTableTableManager get movieWatchHistoryTable =>
      $$MovieWatchHistoryTableTableTableManager(
        _db,
        _db.movieWatchHistoryTable,
      );
  $$ImportQueueTableTableTableManager get importQueueTable =>
      $$ImportQueueTableTableTableManager(_db, _db.importQueueTable);
}
