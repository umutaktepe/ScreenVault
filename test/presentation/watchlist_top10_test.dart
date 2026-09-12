import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/presentation/screens/watchlist/watchlist_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.clearActiveUserData();
  });

  testWidgets('Watchlist shows only top 10 items and displays Show More button when > 10', (tester) async {
    for (int i = 1; i <= 15; i++) {
      await db.upsertShow(ShowModel(
        id: i,
        name: 'Show $i',
        isFollowed: true,
        totalEpisodes: 10,
        watchedEpisodesCount: i <= 5 ? 2 : 0,
      ));
    }

    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Dizilerim'), findsOneWidget);
    expect(find.text('Tümünü Gör >'), findsOneWidget);

    // Scroll down to the bottom
    for (int i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Tüm Dizilerimi Gör'), findsOneWidget);
    expect(find.textContaining('+5 dizi daha'), findsOneWidget);
  });
}
