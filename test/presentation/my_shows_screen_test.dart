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
}
