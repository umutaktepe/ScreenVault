import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/presentation/screens/my_shows/widgets/show_grid_card.dart';

void main() {
  testWidgets('ShowGridCard renders show name, progress indicator, and triggers onTap', (tester) async {
    bool tapped = false;
    final show = ShowModel(
      id: 1,
      name: 'Severance',
      firstAirDate: DateTime(2022, 2, 18),
      totalEpisodes: 10,
      watchedEpisodesCount: 6,
      posterPath: '/path.jpg',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShowGridCard(
          show: show,
          onTap: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('Severance'), findsOneWidget);
    expect(find.text('6 / 10'), findsOneWidget);

    await tester.tap(find.byType(ShowGridCard));
    expect(tapped, isTrue);
  });
}
