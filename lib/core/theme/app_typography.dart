import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography configuration matching Stitch Obsidian Cinema & TV Tracker
class AppTypography {
  AppTypography._();

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
  }

  // 3-Column LED Lifetime Watch Time Digits
  static TextStyle get ledDisplay => _inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryAccent,
        letterSpacing: -0.02,
      );

  static TextStyle get ledLabel => _inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.secondarySlate,
        letterSpacing: 0.08,
      );

  // Headlines
  static TextStyle get headline1 => _inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.02,
      );

  static TextStyle get headline2 => _inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headline3 => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Labels & Badges (e.g. S02 · E03)
  static TextStyle get labelCode => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryAccent,
        letterSpacing: 0.06,
      );

  static TextStyle get labelCodeSmall => _inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.secondarySlate,
        letterSpacing: 0.04,
      );

  // Body Text
  static TextStyle get bodyLarge => _inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMedium => _inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get bodySmall => _inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.secondarySlate,
      );

  // Buttons
  static TextStyle get buttonPrimary => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnAccent,
        letterSpacing: 0.04,
      );

  static TextStyle get buttonSecondary => _inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
}
