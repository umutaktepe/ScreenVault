import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/common/checkmark_toggle_button.dart';
import 'package:screenvault/presentation/screens/watchlist/widgets/movie_spotlight_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  testWidgets('MovieSpotlightCard displays hero information and handles tap', (tester) async {
    bool tapped = false;
    final movie = MovieModel(
      id: 99,
      title: 'Dune: Part Two',
      runtimeMinutes: 166,
      genres: const ['Sci-Fi', 'Adventure'],
      voteAverage: 8.5,
      isFollowed: true,
      isWatched: false,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MovieSpotlightCard(
          movie: movie,
          onTap: () => tapped = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('SPOTLIGHT'), findsOneWidget);
    expect(find.text('Dune: Part Two'), findsOneWidget);
    expect(find.textContaining('166 dk'), findsOneWidget);
    expect(find.text('Sci-Fi'), findsOneWidget);
    expect(find.text('Adventure'), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
    expect(find.text('Sıradaki Film'), findsOneWidget);

    await tester.tap(find.text('Dune: Part Two'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('MovieSpotlightCard toggles watched state via CheckmarkToggleButton and updates database', (tester) async {
    final movie = MovieModel(
      id: 101,
      title: 'Blade Runner 2049',
      runtimeMinutes: 164,
      genres: const ['Sci-Fi', 'Mystery'],
      voteAverage: 8.0,
      isFollowed: true,
      isWatched: false,
    );
    await db.upsertMovie(movie);

    bool? toggleCallbackValue;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MovieSpotlightCard(
          movie: movie,
          onTap: () {},
          onToggleWatched: (val) => toggleCallbackValue = val,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sıradaki Film'), findsOneWidget);

    // Tap the CheckmarkToggleButton
    final checkmark = find.byType(CheckmarkToggleButton);
    expect(checkmark, findsOneWidget);
    await tester.tap(checkmark);
    await tester.pumpAndSettle();

    expect(toggleCallbackValue, isTrue);
    final updated = db.getMovieById(101);
    expect(updated?.isWatched, isTrue);
    expect(find.text('Son İzlenen'), findsOneWidget);
  });

  testWidgets('MovieSpotlightCard displays watched movie state correctly and allows toggling back to unwatched', (tester) async {
    final movie = MovieModel(
      id: 102,
      title: 'Inception',
      runtimeMinutes: 148,
      genres: const ['Action', 'Sci-Fi'],
      voteAverage: 8.8,
      isFollowed: true,
      isWatched: true,
    );
    await db.upsertMovie(movie);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MovieSpotlightCard(
          movie: movie,
          onTap: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Son İzlenen'), findsOneWidget);

    // Tap to unmark watched
    final checkmark = find.byType(CheckmarkToggleButton);
    await tester.tap(checkmark);
    await tester.pumpAndSettle();

    final updated = db.getMovieById(102);
    expect(updated?.isWatched, isFalse);
    expect(find.text('Sıradaki Film'), findsOneWidget);
  });

  testWidgets('MovieSpotlightCard handles missing backdrop, empty genres, and 0 runtime gracefully', (tester) async {
    const movie = MovieModel(
      id: 103,
      title: 'Mystery Film',
      runtimeMinutes: 0,
      genres: [],
      voteAverage: 0.0,
      isFollowed: true,
      isWatched: false,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MovieSpotlightCard(
          movie: movie,
          onTap: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('SPOTLIGHT'), findsOneWidget);
    expect(find.text('Mystery Film'), findsOneWidget);
    expect(find.text('Sıradaki Film'), findsOneWidget);
  });
}
