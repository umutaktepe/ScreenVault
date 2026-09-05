import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/core/theme/obsidian_theme.dart';
import 'package:screenvault/core/utils/duration_formatter.dart';
import 'package:screenvault/presentation/common/floating_frosted_nav_bar.dart';
import 'package:screenvault/presentation/common/checkmark_toggle_button.dart';
import 'package:screenvault/presentation/common/led_time_counter.dart';
import 'package:screenvault/presentation/common/emotion_meter.dart';

void main() {
  group('Stitch Obsidian Widget Component Tests', () {
    testWidgets('FloatingFrostedNavBar renders 5 tabs and handles tap', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: FloatingFrostedNavBar(
              currentIndex: 0,
              onTabSelected: (idx) => tappedIndex = idx,
            ),
          ),
        ),
      );

      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap Discover (tab 2)
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 2);
    });

    testWidgets('CheckmarkToggleButton animates and toggles watched state', (tester) async {
      bool watched = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CheckmarkToggleButton(
                  isWatched: watched,
                  onToggle: (val) => setState(() => watched = val),
                  size: 40,
                );
              },
            ),
          ),
        ),
      );

      // Initially unwatched
      expect(find.byKey(const ValueKey('unchecked')), findsOneWidget);

      // Tap toggle button
      await tester.tap(find.byType(CheckmarkToggleButton));
      await tester.pumpAndSettle();

      expect(watched, isTrue);
      expect(find.byKey(const ValueKey('checked')), findsOneWidget);
    });

    testWidgets('LedTimeCounter renders 3-column gold LED digits: [ 04 ] Months [ 09 ] Days [ 13 ] Hours', (tester) async {
      const parts = WatchTimeParts(
        months: 4,
        days: 9,
        hours: 13,
        minutes: 36,
        totalMinutes: 186576,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: const Scaffold(
            body: LedTimeCounter(watchTimeParts: parts),
          ),
        ),
      );

      expect(find.text('04'), findsOneWidget);
      expect(find.text('MONTHS'), findsOneWidget);
      expect(find.text('09'), findsOneWidget);
      expect(find.text('DAYS'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
      expect(find.text('HOURS'), findsOneWidget);
    });

    testWidgets('EmotionMeter renders 5 emotions (🤯, 😢, 😂, 🔥, 😡) and selects', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: Scaffold(
            body: EmotionMeter(
              onEmotionSelected: (emoji) => selected = emoji,
            ),
          ),
        ),
      );

      expect(find.text('🤯'), findsOneWidget);
      expect(find.text('😢'), findsOneWidget);
      expect(find.text('😂'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('😡'), findsOneWidget);

      // Tap Mind Blown emoji 🤯
      await tester.tap(find.text('🤯'));
      await tester.pumpAndSettle();

      expect(selected, '🤯');
    });
  });
}
