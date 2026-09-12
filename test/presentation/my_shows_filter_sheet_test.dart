import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/presentation/screens/my_shows/widgets/my_shows_filter_sheet.dart';

void main() {
  testWidgets('MyShowsFilterSheet allows selecting sort option, genres, and applying', (tester) async {
    MyShowsFilterResult? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showModalBottomSheet<MyShowsFilterResult>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const MyShowsFilterSheet(
                  availableGenres: ['Drama', 'Sci-Fi', 'Comedy'],
                  availableYears: [2024, 2023, 2022],
                  currentSort: ShowSortOption.recentlyActive,
                  currentGenres: {'Drama'},
                  currentYear: 2024,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Filtrele ve Sırala'), findsOneWidget);
    expect(find.text('Sıralama Ölçütü'), findsOneWidget);
    expect(find.text('Türler'), findsOneWidget);

    // Tap Sci-Fi chip
    await tester.tap(find.text('Sci-Fi'));
    await tester.pumpAndSettle();

    // Tap Uygula
    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.genres.contains('Sci-Fi'), isTrue);
    expect(result!.genres.contains('Drama'), isTrue);
  });
}
