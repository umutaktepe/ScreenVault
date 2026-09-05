import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Central Drift SQLite Database for Screen Vault
@DriftDatabase(tables: [
  ShowsTable,
  SeasonsTable,
  EpisodesTable,
  EpisodeWatchHistoryTable,
  MoviesTable,
  MovieWatchHistoryTable,
  ImportQueueTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return NativeDatabase.memory();
    }
    return driftDatabase(name: 'screen_vault');
  }

  /// In-memory database instance for testing
  factory AppDatabase.memory() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return AppDatabase(NativeDatabase.memory());
  }
}
