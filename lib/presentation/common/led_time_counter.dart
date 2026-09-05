import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/duration_formatter.dart';

/// 3-Column Gold Digital LED Lifetime Watch Time Counter
/// Displays: [ 04 ] Months   [ 09 ] Days   [ 13 ] Hours
class LedTimeCounter extends StatelessWidget {
  final WatchTimeParts watchTimeParts;

  const LedTimeCounter({
    super.key,
    required this.watchTimeParts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderStroke, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'LIFETIME WATCH TIME',
            style: AppTypography.ledLabel.copyWith(
              color: AppColors.secondarySlate,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitColumn(watchTimeParts.formattedMonths, 'MONTHS'),
              _buildSeparator(),
              _buildDigitColumn(watchTimeParts.formattedDays, 'DAYS'),
              _buildSeparator(),
              _buildDigitColumn(watchTimeParts.formattedHours, 'HOURS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitColumn(String digits, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.canvasBase,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            digits,
            style: AppTypography.ledDisplay,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.ledLabel,
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        ':',
        style: AppTypography.ledDisplay.copyWith(
          color: AppColors.secondarySlate.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
