import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/main.dart';
import 'package:screenvault/presentation/screens/main_navigation_shell.dart';

void main() {
  testWidgets('ScreenVaultApp smoke test renders navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ScreenVaultApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(MainNavigationShell), findsOneWidget);
    expect(find.text('Trackr'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
  });
}
