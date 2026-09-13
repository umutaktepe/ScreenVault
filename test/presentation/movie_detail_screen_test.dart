import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/screens/discover/discover_screen.dart';
import 'package:screenvault/presentation/screens/movie_detail/movie_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  testWidgets('MovieDetailScreen displays overview, toggle watchlist, and toggle watched', (tester) async {
    final movie = MovieModel(
      id: 200,
      title: 'Oppenheimer',
      overview: 'The story of J. Robert Oppenheimer.',
      runtimeMinutes: 180,
      releaseDate: DateTime(2023, 7, 21),
      genres: const ['Biography', 'Drama', 'History'],
      voteAverage: 8.9,
      isFollowed: true,
      isWatched: false,
    );
    await db.upsertMovie(movie);

    await tester.pumpWidget(MaterialApp(
      home: MovieDetailScreen(movie: movie),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Oppenheimer'), findsOneWidget);
    expect(find.text('The story of J. Robert Oppenheimer.'), findsOneWidget);
    expect(find.textContaining('180 dk'), findsOneWidget);
    expect(find.textContaining('8.9'), findsOneWidget);

    // Initial watchlist button state
    final watchlistButton = find.text('Listemde');
    expect(watchlistButton, findsOneWidget);

    // Toggle watchlist to unfollow
    await tester.tap(watchlistButton);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(db.getMovieById(200)?.isFollowed, isFalse);
    expect(find.text('İzleme Listesine Ekle'), findsOneWidget);

    // Toggle watchlist back to followed
    await tester.tap(find.text('İzleme Listesine Ekle'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(db.getMovieById(200)?.isFollowed, isTrue);
    expect(find.text('Listemde'), findsOneWidget);

    // Toggle watched
    final watchedButton = find.text('İzlendi Olarak İşaretle');
    expect(watchedButton, findsOneWidget);
    await tester.tap(watchedButton);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    final updated = db.getMovieById(200);
    expect(updated?.isWatched, isTrue);
    expect(find.text('İzlendi ✓'), findsOneWidget);
  });

  testWidgets('MovieDetailScreen back button pops screen', (tester) async {
    final movie = MovieModel(
      id: 201,
      title: 'Barbie',
      runtimeMinutes: 114,
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
              );
            },
            child: const Text('Open Movie'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open Movie'));
    await tester.pumpAndSettle();

    expect(find.text('Barbie'), findsOneWidget);

    // Tap back button
    final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Open Movie'), findsOneWidget);
    expect(find.text('Barbie'), findsNothing);
  });

  testWidgets('MovieDetailScreen toggles watched state from watched to unwatched', (tester) async {
    final movie = MovieModel(
      id: 202,
      title: 'Inception',
      runtimeMinutes: 148,
      isFollowed: true,
      isWatched: true,
      watchedAt: DateTime(2024, 1, 1),
    );
    await db.upsertMovie(movie);

    await tester.pumpWidget(MaterialApp(
      home: MovieDetailScreen(movie: movie),
    ));
    await tester.pumpAndSettle();

    expect(find.text('İzlendi ✓'), findsOneWidget);
    expect(find.textContaining('İzlenme Tarihi:'), findsOneWidget);

    // Tap to unmark watched
    await tester.tap(find.text('İzlendi ✓'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    final updated = db.getMovieById(202);
    expect(updated?.isWatched, isFalse);
    expect(find.text('İzlendi Olarak İşaretle'), findsOneWidget);
    expect(find.textContaining('İzlenme Tarihi:'), findsNothing);
  });

  testWidgets('DiscoverScreen navigates to MovieDetailScreen when movie is tapped', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DiscoverScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final interstellar = find.text('Interstellar');
    expect(interstellar, findsOneWidget);
    await tester.tap(interstellar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MovieDetailScreen), findsOneWidget);
  });
}
