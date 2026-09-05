import 'package:flutter/material.dart';

/// Obsidian Cinema & TV Tracker color tokens
/// Project: Screen Vault (TV Time Alternative)
class AppColors {
  AppColors._();

  // Solid OLED Obsidian Base
  static const Color canvasBase = Color(0xFF0E0F12);

  // Card Surfaces
  static const Color cardSurface = Color(0xFF1A1C23);
  static const Color surfaceHighlight = Color(0xFF222631);
  static const Color surfaceElevated = Color(0xFF2A2D37);

  // Border & Hairlines
  static const Color borderStroke = Color(0xFF2A2D37);
  static const Color borderSubtle = Color(0xFF1E212B);

  // Brand Accents
  static const Color primaryAccent = Color(0xFFFED530); // Canary Yellow
  static const Color functionalSuccess = Color(0xFF22C55E); // Emerald Green
  static const Color secondarySlate = Color(0xFF94A3B8); // Muted Slate
  static const Color slateLight = Color(0xFFCBD5E1);

  // Status & Utility Colors
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF38BDF8);
  static const Color warningOrange = Color(0xFFF97316);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textOnAccent = Color(0xFF0E0F12);

  // Glassmorphism & Translucency
  static const Color glassBackground = Color(0xCC1A1C23); // 80% opacity cardSurface
  static const Color glassBorder = Color(0x40FED530); // 25% Canary Yellow
  static const Color glassOverlay = Color(0x600E0F12);
}
