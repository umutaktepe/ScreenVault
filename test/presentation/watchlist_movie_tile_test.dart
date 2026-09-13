import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/common/checkmark_toggle_button.dart';
import 'package:screenvault/presentation/screens/watchlist/widgets/watchlist_movie_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  testWidgets('WatchlistMovieTile renders title, runtime, rating, and toggles watched', (tester) async {
    bool tapped = false;
    final movie = MovieModel(
      id: 50,
      title: 'Interstellar',
      releaseDate: DateTime(2014, 11, 7),
      runtimeMinutes: 169,
      genres: const ['Sci-Fi', 'Drama'],
      voteAverage: 8.7,
      isFollowed: true,
      isWatched: false,
    );
    await db.upsertMovie(movie);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WatchlistMovieTile(
          movie: movie,
          onTap: () => tapped = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.textContaining('2014'), findsOneWidget);
    expect(find.textContaining('169 dk'), findsOneWidget);
    expect(find.textContaining('8.7'), findsOneWidget);
    expect(find.text('İzlenecek'), findsOneWidget);

    // Tap card
    await tester.tap(find.text('Interstellar'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);

    // Tap CheckmarkToggleButton to toggle watched
    final checkmark = find.byType(CheckmarkToggleButton);
    expect(checkmark, findsOneWidget);
    await tester.tap(checkmark);
    await tester.pumpAndSettle();

    final updated = db.getMovieById(50);
    expect(updated?.isWatched, isTrue);
  });

  testWidgets('WatchlistMovieTile renders already watched movie with status pill and toggles back to unwatched', (tester) async {
    final movie = MovieModel(
      id: 51,
      title: 'Oppenheimer',
      releaseDate: DateTime(2023, 7, 21),
      runtimeMinutes: 180,
      genres: const ['Biography', 'Drama'],
      voteAverage: 8.9,
      isFollowed: true,
      isWatched: true,
    );
    await db.upsertMovie(movie);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WatchlistMovieTile(
          movie: movie,
          onTap: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Oppenheimer'), findsOneWidget);
    expect(find.text('İzlendi ✓'), findsOneWidget);

    // Tap CheckmarkToggleButton to unmark watched
    final checkmark = find.byType(CheckmarkToggleButton);
    await tester.tap(checkmark);
    await tester.pumpAndSettle();

    final updated = db.getMovieById(51);
    expect(updated?.isWatched, isFalse);
    expect(find.text('İzlenecek'), findsOneWidget);
  });

  testWidgets('WatchlistMovieTile handles missing release date and 0 runtime gracefully', (tester) async {
    const movie = MovieModel(
      id: 52,
      title: 'Upcoming Movie',
      releaseDate: null,
      runtimeMinutes: 0,
      voteAverage: 0.0,
      isFollowed: true,
      isWatched: false,
    );
    await db.upsertMovie(movie);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WatchlistMovieTile(
          movie: movie,
          onTap: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Movie'), findsOneWidget);
    expect(find.text('İzlenecek'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('WatchlistMovieTile syncs isWatched when movie id changes in didUpdateWidget', (tester) async {
    const movieA = MovieModel(
      id: 61,
      title: 'Movie A',
      isFollowed: true,
      isWatched: true,
    );
    const movieB = MovieModel(
      id: 62,
      title: 'Movie B',
      isFollowed: true,
      isWatched: false,
    );
    await db.upsertMovie(movieA);
    await db.upsertMovie(movieB);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WatchlistMovieTile(
          movie: movieA,
          onTap: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('İzlendi ✓'), findsOneWidget);

    // Rebuild with movieB (different ID, isWatched: false)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WatchlistMovieTile(
          movie: movieB,
          onTap: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('İzlenecek'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
