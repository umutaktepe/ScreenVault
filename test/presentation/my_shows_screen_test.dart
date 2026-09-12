import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/presentation/screens/my_shows/my_shows_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  testWidgets('MyShowsScreen searches shows and toggles grid/list view', (tester) async {
    await db.upsertShow(ShowModel(
      id: 1,
      name: 'Breaking Bad',
      isFollowed: true,
      genres: const ['Drama', 'Crime'],
      firstAirDate: DateTime(2008, 1, 20),
    ));
    await db.upsertShow(ShowModel(
      id: 2,
      name: 'Better Call Saul',
      isFollowed: true,
      genres: const ['Drama'],
      firstAirDate: DateTime(2015, 2, 8),
    ));

    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tüm Dizilerim'), findsOneWidget);
    expect(find.text('Breaking Bad'), findsOneWidget);
    expect(find.text('Better Call Saul'), findsOneWidget);

    // Search 'Better'
    await tester.enterText(find.byType(TextField), 'Better');
    await tester.pumpAndSettle();

    expect(find.text('Better Call Saul'), findsOneWidget);
    expect(find.text('Breaking Bad'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Breaking Bad'), findsOneWidget);

    // Toggle view mode icon (default is grid view, toggle icon is view_list_rounded)
    final viewToggleIcon = find.byIcon(Icons.view_list_rounded);
    expect(viewToggleIcon, findsOneWidget);
    await tester.tap(viewToggleIcon);
    await tester.pumpAndSettle();

    // Now icon changes to grid_view_rounded
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
  });

  testWidgets('MyShowsScreen paginates 20 items and loads more on scroll', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (int i = 35; i >= 1; i--) {
      await db.upsertShow(ShowModel(
        id: i,
        name: 'Dizi $i',
        isFollowed: true,
        genres: const ['Drama'],
        firstAirDate: DateTime(2020, 1, 1),
      ), notify: false);
    }
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Dizi 1'), findsOneWidget);
    expect(find.text('Dizi 20'), findsOneWidget);
    expect(find.text('Dizi 25'), findsNothing);
    expect(find.text('Dizi 35'), findsNothing);

    // Drag down by -1200 offset to trigger auto-load of next page
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    // Scroll until the last show is visible to verify all remaining shows loaded
    await tester.scrollUntilVisible(find.text('Dizi 35'), 500);
    await tester.pumpAndSettle();

    expect(find.text('Dizi 25'), findsOneWidget);
    expect(find.text('Dizi 35'), findsOneWidget);
  });

  testWidgets('MyShowsScreen resets pagination to 20 when search query changes', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (int i = 35; i >= 1; i--) {
      await db.upsertShow(ShowModel(
        id: i,
        name: 'Dizi $i',
        isFollowed: true,
        genres: const ['Drama'],
        firstAirDate: DateTime(2020, 1, 1),
      ), notify: false);
    }
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    // Trigger load more
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Dizi 35'), 500);
    await tester.pumpAndSettle();
    expect(find.text('Dizi 35'), findsOneWidget);

    // Scroll back to top
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
    await tester.pumpAndSettle();

    // Entering text resets pagination
    await tester.enterText(find.byType(TextField), 'Dizi');
    await tester.pumpAndSettle();

    expect(find.text('Dizi 1'), findsOneWidget);
    expect(find.text('Dizi 20'), findsOneWidget);
    expect(find.text('Dizi 25'), findsNothing);
  });

  testWidgets('MyShowsScreen displays end-of-list indicator when all items are loaded', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (int i = 1; i <= 5; i++) {
      await db.upsertShow(ShowModel(
        id: i,
        name: 'Dizi $i',
        isFollowed: true,
        genres: const ['Drama'],
        firstAirDate: DateTime(2020, 1, 1),
      ), notify: false);
    }
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tüm 5 dizi listelendi'), findsOneWidget);
    expect(find.byIcon(Icons.movie_filter_outlined), findsOneWidget);
  });

  testWidgets('MyShowsScreen shows end-of-list indicator only after scrolling to bottom with multiple pages', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (int i = 35; i >= 1; i--) {
      await db.upsertShow(ShowModel(
        id: i,
        name: 'Dizi $i',
        isFollowed: true,
        genres: const ['Drama'],
        firstAirDate: DateTime(2020, 1, 1),
      ), notify: false);
    }
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    // With 35 items and 20 per page, initially indicator should not be shown
    expect(find.textContaining('Tüm 35 dizi listelendi'), findsNothing);
    expect(find.byIcon(Icons.movie_filter_outlined), findsNothing);

    // Trigger loading next page
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    // Scroll until indicator is visible
    await tester.scrollUntilVisible(find.byIcon(Icons.movie_filter_outlined), 500);
    await tester.pumpAndSettle();

    expect(find.textContaining('Tüm 35 dizi listelendi'), findsOneWidget);
    expect(find.byIcon(Icons.movie_filter_outlined), findsOneWidget);
  });

  testWidgets('MyShowsScreen does not display end-of-list indicator when show list is empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.movie_filter_outlined), findsNothing);
    expect(find.textContaining('dizi listelendi'), findsNothing);
  });
}
