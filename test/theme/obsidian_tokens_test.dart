import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/core/theme/app_colors.dart';
import 'package:screenvault/core/theme/app_typography.dart';
import 'package:screenvault/core/theme/obsidian_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Obsidian Theme Tokens Tests', () {
    test('Verifies Stitch OLED Obsidian Color Codes', () {
      expect(AppColors.canvasBase, const Color(0xFF0E0F12));
      expect(AppColors.cardSurface, const Color(0xFF1A1C23));
      expect(AppColors.surfaceHighlight, const Color(0xFF222631));
      expect(AppColors.borderStroke, const Color(0xFF2A2D37));
      expect(AppColors.primaryAccent, const Color(0xFFFED530)); // Canary Yellow
      expect(AppColors.functionalSuccess, const Color(0xFF22C55E)); // Emerald Green
      expect(AppColors.secondarySlate, const Color(0xFF94A3B8));
    });

    testWidgets('Verifies ThemeData contains dark OLED scheme and colors', (tester) async {
      final theme = ObsidianTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.canvasBase);
      expect(theme.primaryColor, AppColors.primaryAccent);
      expect(theme.colorScheme.secondary, AppColors.functionalSuccess);
    });

    testWidgets('Verifies Typography styles', (tester) async {
      expect(AppTypography.ledDisplay.fontWeight, FontWeight.w800);
      expect(AppTypography.headline1.fontWeight, FontWeight.w800);
      expect(AppTypography.labelCode.fontWeight, FontWeight.w700);
    });
  });
}
