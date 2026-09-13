import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/screens/movie_detail/movie_detail_screen.dart';
import 'package:screenvault/presentation/screens/my_movies/my_movies_screen.dart';
import 'package:screenvault/presentation/screens/watchlist/watchlist_screen.dart';
import 'package:screenvault/presentation/screens/watchlist/widgets/movie_spotlight_card.dart';
import 'package:screenvault/presentation/screens/watchlist/widgets/watchlist_movie_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  testWidgets('Watchlist Movies tab displays spotlight, section header, filter chips, and top 10 limit', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (int i = 1; i <= 15; i++) {
      await db.upsertMovie(MovieModel(
        id: i,
        title: 'Film $i',
        isFollowed: true,
        isWatched: i <= 5,
        runtimeMinutes: 110,
        genres: const ['Drama'],
      ));
    }

    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    // Switch to Movies tab
    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();

    expect(find.text('SPOTLIGHT'), findsOneWidget);
    expect(find.text('Filmlerim'), findsOneWidget);
    expect(find.text('Tümünü Gör >'), findsOneWidget);

    // Filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Watched'), findsOneWidget);

    // Scroll down to check Show More button
    for (int i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Tüm Filmlerimi Gör'), findsOneWidget);
    expect(find.textContaining('+5 film daha'), findsOneWidget);
  });

  testWidgets('Tapping spotlight card navigates to MovieDetailScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await db.upsertMovie(const MovieModel(
      id: 99,
      title: 'Spotlight Movie',
      isFollowed: true,
      isWatched: false,
      runtimeMinutes: 120,
    ));

    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MovieSpotlightCard));
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailScreen), findsOneWidget);
    expect(find.text('Spotlight Movie'), findsWidgets);
  });

  testWidgets('Tapping Tümünü Gör > navigates to MyMoviesScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await db.upsertMovie(const MovieModel(
      id: 1,
      title: 'Movie 1',
      isFollowed: true,
      isWatched: false,
    ));

    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tümünü Gör >'));
    await tester.pumpAndSettle();

    expect(find.byType(MyMoviesScreen), findsOneWidget);
  });

  testWidgets('Tapping movie filter chips filters movies correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await db.upsertMovie(const MovieModel(
      id: 1,
      title: 'Watchlist Movie Alpha',
      isFollowed: true,
      isWatched: false,
    ));
    await db.upsertMovie(const MovieModel(
      id: 2,
      title: 'Watched Movie Beta',
      isFollowed: true,
      isWatched: true,
    ));

    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();

    // Initially 'All' is selected: both appear in tiles
    expect(find.widgetWithText(WatchlistMovieTile, 'Watchlist Movie Alpha'), findsOneWidget);
    expect(find.widgetWithText(WatchlistMovieTile, 'Watched Movie Beta'), findsOneWidget);

    // Filter to Watchlist
    await tester.tap(find.text('Watchlist'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(WatchlistMovieTile, 'Watchlist Movie Alpha'), findsOneWidget);
    expect(find.widgetWithText(WatchlistMovieTile, 'Watched Movie Beta'), findsNothing);

    // Filter to Watched
    await tester.tap(find.text('Watched'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(WatchlistMovieTile, 'Watchlist Movie Alpha'), findsNothing);
    expect(find.widgetWithText(WatchlistMovieTile, 'Watched Movie Beta'), findsOneWidget);

    // Filter back to All
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(WatchlistMovieTile, 'Watchlist Movie Alpha'), findsOneWidget);
    expect(find.widgetWithText(WatchlistMovieTile, 'Watched Movie Beta'), findsOneWidget);
  });

  testWidgets('Watchlist Movies tab displays empty state when no movies exist', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();

    expect(find.text('Takip edilen veya izlenen film bulunmuyor.'), findsOneWidget);
  });
}
