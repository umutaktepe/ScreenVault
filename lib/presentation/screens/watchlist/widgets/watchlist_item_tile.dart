import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/show_model.dart';
import '../../../common/custom_poster_image.dart';

/// Vertical stream item tile matching Stitch Watchlist design
/// (2:3 vertical poster, 1.5px emerald green progress bar, remaining episode count)
class WatchlistItemTile extends StatelessWidget {
  final ShowModel show;
  final VoidCallback onTap;

  const WatchlistItemTile({
    super.key,
    required this.show,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStroke, width: 1),
        ),
        child: Row(
          children: [
            // 2:3 Vertical Poster
            SizedBox(
              width: 60,
              height: 90,
              child: CustomPosterImage(
                path: show.posterPath,
                borderRadius: 10,
              ),
            ),
            const SizedBox(width: 14),
            // Show Details and Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          show.name,
                          style: AppTypography.headline3.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (show.voteAverage > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.primaryAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              show.voteAverage.toStringAsFixed(1),
                              style: AppTypography.labelCode.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    show.remainingEpisodes > 0
                        ? '${show.remainingEpisodes} izlenmemiş bölüm kaldı'
                        : 'Tüm bölümler izlendi ✓',
                    style: AppTypography.bodySmall.copyWith(
                      color: show.remainingEpisodes > 0
                          ? AppColors.secondarySlate
                          : AppColors.functionalSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 1.5px Emerald Green Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: show.progress,
                      minHeight: 2.0,
                      backgroundColor: AppColors.surfaceHighlight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.functionalSuccess,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${show.watchedEpisodesCount} / ${show.totalEpisodes} Bölüm',
                        style: AppTypography.bodySmall.copyWith(fontSize: 10),
                      ),
                      Text(
                        '${(show.progress * 100).toStringAsFixed(0)}%',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.functionalSuccess,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
