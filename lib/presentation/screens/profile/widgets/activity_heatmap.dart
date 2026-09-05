import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// 28-day Activity Heatmap matching Stitch Profile Bento specification
/// (GitHub contribution format: 7 rows x 4 columns matrix)
class ActivityHeatmap extends StatelessWidget {
  final List<int> activityCounts; // 28 values

  const ActivityHeatmap({
    super.key,
    required this.activityCounts,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we have 28 days
    final counts = activityCounts.length == 28
        ? activityCounts
        : List.generate(28, (i) => i < activityCounts.length ? activityCounts[i] : 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderStroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '28-DAY ACTIVITY HEATMAP',
                style: AppTypography.labelCode,
              ),
              Text(
                'Past 4 Weeks',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 4 columns (weeks) x 7 rows (days Mon-Sun)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (weekIndex) {
              return Column(
                children: List.generate(7, (dayIndex) {
                  final index = weekIndex * 7 + dayIndex;
                  final count = counts[index];
                  return Container(
                    width: 22,
                    height: 16,
                    margin: const EdgeInsets.symmetric(vertical: 2.5),
                    decoration: BoxDecoration(
                      color: _getColorForCount(count),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Heatmap Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              const SizedBox(width: 4),
              _buildLegendBox(AppColors.surfaceHighlight),
              _buildLegendBox(AppColors.functionalSuccess.withValues(alpha: 0.3)),
              _buildLegendBox(AppColors.functionalSuccess.withValues(alpha: 0.6)),
              _buildLegendBox(AppColors.functionalSuccess),
              const SizedBox(width: 4),
              Text('More', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColorForCount(int count) {
    if (count <= 0) return AppColors.surfaceHighlight;
    if (count == 1) return AppColors.functionalSuccess.withValues(alpha: 0.35);
    if (count <= 3) return AppColors.functionalSuccess.withValues(alpha: 0.65);
    return AppColors.functionalSuccess;
  }
}
