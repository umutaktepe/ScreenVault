import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/screens/movie_detail/movie_detail_screen.dart';
import 'package:screenvault/presentation/screens/my_movies/my_movies_screen.dart';
import 'package:screenvault/presentation/screens/my_movies/widgets/movie_grid_card.dart';
import 'package:screenvault/presentation/screens/my_movies/widgets/my_movies_filter_sheet.dart';
import 'package:screenvault/presentation/screens/watchlist/widgets/watchlist_movie_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  testWidgets('MyMoviesScreen renders grid and list view with search filter', (tester) async {
    for (int i = 1; i <= 25; i++) {
      await db.upsertMovie(MovieModel(
        id: i,
        title: 'Movie $i',
        isFollowed: true,
        isWatched: i <= 10,
        runtimeMinutes: 100 + i,
        genres: const ['Action'],
      ));
    }

    await tester.pumpWidget(const MaterialApp(
      home: MyMoviesScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tüm Filmlerim'), findsOneWidget);
    expect(find.textContaining('25 Film'), findsOneWidget);

    // Search filter with substring
    await tester.enterText(find.byType(TextField), '12');
    await tester.pumpAndSettle();
    expect(find.text('Movie 12'), findsOneWidget);
    expect(find.text('Movie 13'), findsNothing);

    // Search filter with full title
    await tester.enterText(find.byType(TextField), 'Movie 12');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MovieGridCard, 'Movie 12'), findsOneWidget);
    expect(find.text('Movie 13'), findsNothing);
    expect(find.text('1 Film'), findsOneWidget);

    // Search with 0 matches displays '0 Film' in AppBar badge
    await tester.enterText(find.byType(TextField), 'NonExistentMovie');
    await tester.pumpAndSettle();
    expect(find.text('0 Film'), findsOneWidget);
    expect(find.text('25 Film'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('25 Film'), findsOneWidget);

    // Toggle between Grid and List view
    final listToggleIcon = find.byIcon(Icons.view_agenda_rounded);
    expect(listToggleIcon, findsOneWidget);
    await tester.tap(listToggleIcon);
    await tester.pumpAndSettle();

    // Now in list view, WatchlistMovieTile widgets should be rendered
    expect(find.byType(WatchlistMovieTile), findsWidgets);

    // Toggle back to grid view
    final gridToggleIcon = find.byIcon(Icons.grid_view_rounded);
    expect(gridToggleIcon, findsOneWidget);
    await tester.tap(gridToggleIcon);
    await tester.pumpAndSettle();
    expect(find.byType(MovieGridCard), findsWidgets);
  });

  testWidgets('MyMoviesScreen quick status chips filter movies properly', (tester) async {
    await db.upsertMovie(const MovieModel(
      id: 1,
      title: 'Unwatched Movie',
      isFollowed: true,
      isWatched: false,
    ));
    await db.upsertMovie(const MovieModel(
      id: 2,
      title: 'Watched Movie',
      isFollowed: true,
      isWatched: true,
    ));

    await tester.pumpWidget(const MaterialApp(
      home: MyMoviesScreen(),
    ));
    await tester.pumpAndSettle();

    // Initially "Tümü" is selected, both visible
    expect(find.text('Unwatched Movie'), findsOneWidget);
    expect(find.text('Watched Movie'), findsOneWidget);

    // Tap "İzlenecekler"
    await tester.tap(find.text('İzlenecekler'));
    await tester.pumpAndSettle();
    expect(find.text('Unwatched Movie'), findsOneWidget);
    expect(find.text('Watched Movie'), findsNothing);

    // Tap "İzlenenler"
    await tester.tap(find.text('İzlenenler'));
    await tester.pumpAndSettle();
    expect(find.text('Unwatched Movie'), findsNothing);
    expect(find.text('Watched Movie'), findsOneWidget);

    // Tap back to "Tümü"
    await tester.tap(find.text('Tümü'));
    await tester.pumpAndSettle();
    expect(find.text('Unwatched Movie'), findsOneWidget);
    expect(find.text('Watched Movie'), findsOneWidget);
  });

  testWidgets('MyMoviesScreen opens filter sheet and applies sort and genre filter', (tester) async {
    await db.upsertMovie(const MovieModel(
      id: 1,
      title: 'Alpha SciFi',
      isFollowed: true,
      voteAverage: 8.5,
      genres: ['Sci-Fi'],
    ));
    await db.upsertMovie(const MovieModel(
      id: 2,
      title: 'Beta Drama',
      isFollowed: true,
      voteAverage: 9.0,
      genres: ['Drama'],
    ));

    await tester.pumpWidget(const MaterialApp(
      home: MyMoviesScreen(),
    ));
    await tester.pumpAndSettle();

    // Open filter sheet
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(MyMoviesFilterSheet), findsOneWidget);
    expect(find.text('Filtrele ve Sırala'), findsOneWidget);

    // Select Sci-Fi genre filter
    await tester.tap(find.text('Sci-Fi'));
    await tester.pumpAndSettle();

    // Apply
    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha SciFi'), findsOneWidget);
    expect(find.text('Beta Drama'), findsNothing);
  });

  testWidgets('Tapping MovieGridCard navigates to MovieDetailScreen', (tester) async {
    await db.upsertMovie(const MovieModel(
      id: 1,
      title: 'Interstellar',
      isFollowed: true,
      overview: 'Mankind was born on Earth. It was never meant to die here.',
    ));

    await tester.pumpWidget(const MaterialApp(
      home: MyMoviesScreen(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MovieGridCard));
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailScreen), findsOneWidget);
    expect(find.text('Interstellar'), findsWidgets);
  });

  testWidgets('MyMoviesScreen shows empty state when library is empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MyMoviesScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Listenizde Film Bulunmuyor'), findsOneWidget);
  });

  testWidgets('MovieGridCard renders title, rating badge, and watched badge', (tester) async {
    final movie = MovieModel(
      id: 1,
      title: 'The Dark Knight',
      voteAverage: 9.0,
      isWatched: true,
      runtimeMinutes: 152,
      releaseDate: DateTime(2008, 7, 18),
    );

    bool tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 150,
          height: 250,
          child: MovieGridCard(
            movie: movie,
            onTap: () => tapped = true,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('The Dark Knight'), findsOneWidget);
    expect(find.text('9.0'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('152 dk'), findsOneWidget);

    await tester.tap(find.byType(MovieGridCard));
    expect(tapped, isTrue);
  });

  testWidgets('MyMoviesScreen paginates 18 items and loads more on scroll', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (int i = 35; i >= 1; i--) {
      await db.upsertMovie(MovieModel(
        id: i,
        title: 'Movie $i',
        isFollowed: true,
      ), notify: false);
    }
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(const MaterialApp(home: MyMoviesScreen()));
    await tester.pumpAndSettle();

    // Initially 18 items loaded (Movie 35 down to Movie 18)
    expect(find.text('Movie 35'), findsOneWidget);
    expect(find.text('Movie 18'), findsOneWidget);
    expect(find.text('Movie 17'), findsNothing);
    expect(find.text('Movie 10'), findsNothing);
    expect(find.text('Movie 1'), findsNothing);

    // Scroll down to load more
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    // Scroll until last movie is visible
    await tester.scrollUntilVisible(find.text('Movie 1'), 500);
    await tester.pumpAndSettle();

    expect(find.text('Movie 10'), findsOneWidget);
    expect(find.text('Movie 1'), findsOneWidget);
    expect(find.textContaining('Tüm 35 film listelendi'), findsOneWidget);
  });

  testWidgets('MyMoviesFilterSheet resets filters on Sıfırla tap', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MyMoviesFilterSheet(
          availableGenres: const ['Action', 'Comedy'],
          availableYears: const [2024, 2023],
          currentSort: MovieSortOption.ratingDesc,
          currentGenres: const {'Action'},
          currentYear: 2024,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sıfırla'), findsOneWidget);
    await tester.tap(find.text('Sıfırla'));
    await tester.pumpAndSettle();

    // After reset, 'En Son İzlenen' should be selected
    final recentlyActiveChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'En Son İzlenen'),
    );
    expect(recentlyActiveChip.selected, isTrue);
  });
}

