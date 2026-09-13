import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  test('getMovieById returns null when not found and correct model when present', () async {
    expect(db.getMovieById(9999), isNull);

    final movie = const MovieModel(
      id: 101,
      title: 'Inception',
      runtimeMinutes: 148,
      isFollowed: true,
    );
    await db.upsertMovie(movie);

    final retrieved = db.getMovieById(101);
    expect(retrieved, isNotNull);
    expect(retrieved!.title, 'Inception');
  });

  test('getFollowedOrWatchedMovies returns only followed or watched movies', () async {
    await db.upsertMovie(const MovieModel(id: 1, title: 'Followed Movie', isFollowed: true, isWatched: false));
    await db.upsertMovie(const MovieModel(id: 2, title: 'Watched Movie', isFollowed: false, isWatched: true));
    await db.upsertMovie(const MovieModel(id: 3, title: 'Ignored Movie', isFollowed: false, isWatched: false));

    final list = db.getFollowedOrWatchedMovies();
    final ids = list.map((m) => m.id).toSet();
    expect(ids, containsAll([1, 2]));
    expect(ids, isNot(contains(3)));
  });

  test('getSpotlightMovie prioritizes unwatched followed movie, falls back to latest watched', () async {
    final watchedMovie = MovieModel(
      id: 10,
      title: 'Past Watched',
      isFollowed: true,
      isWatched: true,
      watchedAt: DateTime(2025, 1, 1),
    );
    final watchlistMovie = const MovieModel(
      id: 20,
      title: 'Next To Watch',
      isFollowed: true,
      isWatched: false,
    );

    await db.upsertMovie(watchedMovie);
    expect(db.getSpotlightMovie()?.id, 10);

    await db.upsertMovie(watchlistMovie);
    expect(db.getSpotlightMovie()?.id, 20, reason: 'Watchlist movie should take priority over watched movie');
  });
}
