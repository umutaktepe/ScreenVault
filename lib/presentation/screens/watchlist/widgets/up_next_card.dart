import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/episode_model.dart';
import '../../../../data/models/show_model.dart';
import '../../../common/checkmark_toggle_button.dart';
import '../../../common/custom_poster_image.dart';

/// 16:9 Cinematic "Up Next" Card matching Stitch specification
class UpNextCard extends StatelessWidget {
  final ShowModel show;
  final EpisodeModel episode;
  final ValueChanged<bool> onToggleWatched;
  final VoidCallback onTap;

  const UpNextCard({
    super.key,
    required this.show,
    required this.episode,
    required this.onToggleWatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderStroke, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 16:9 Cinematic Still with Badges & Toggle Button
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPosterImage(
                      path: episode.stillPath ?? show.backdropPath,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                      size: 'w780',
                    ),
                    // Gradient scrim
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                    // S02 · E03 Badge
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.canvasBase.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryAccent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          episode.code,
                          style: AppTypography.labelCode,
                        ),
                      ),
                    ),
                    // 40px Circular CheckmarkToggleButton
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: CheckmarkToggleButton(
                        isWatched: episode.isWatched,
                        onToggle: onToggleWatched,
                        size: 40,
                      ),
                    ),
                    // Air Date / Duration Label
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.slateLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${episode.runtimeMinutes}m • ${DateFormatter.formatAirDate(episode.airDate)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.slateLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Show and Episode Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show.name,
                      style: AppTypography.headline3.copyWith(
                        color: AppColors.primaryAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (episode.overview != null && episode.overview!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        episode.overview!,
                        style: AppTypography.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
