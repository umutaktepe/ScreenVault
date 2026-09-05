import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/user_stats_model.dart';
import '../../../common/custom_poster_image.dart';

/// Rewatch Library Rail with 4x, 3x, 2x badges matching Stitch specification
class RewatchRail extends StatelessWidget {
  final List<RewatchItem> rewatchedShows;

  const RewatchRail({
    super.key,
    required this.rewatchedShows,
  });

  @override
  Widget build(BuildContext context) {
    if (rewatchedShows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REWATCH LIBRARY',
                style: AppTypography.labelCode,
              ),
              Text(
                'Most Replayed',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rewatchedShows.length,
            itemBuilder: (context, index) {
              final item = rewatchedShows[index];

              return Container(
                width: 85,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          width: 85,
                          height: 110,
                          child: CustomPosterImage(
                            path: item.posterPath,
                            borderRadius: 12,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.count}x',
                              style: AppTypography.labelCodeSmall.copyWith(
                                color: AppColors.textOnAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
