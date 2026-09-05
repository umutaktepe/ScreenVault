import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/show_model.dart';
import '../../../../data/models/movie_model.dart';
import '../../../common/custom_poster_image.dart';

/// Trending Hero Carousel matching Stitch Discover specification
class TrendingCarousel extends StatelessWidget {
  final List<dynamic> items;
  final ValueChanged<dynamic> onItemTap;

  const TrendingCarousel({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length.clamp(0, 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final String title = item is ShowModel ? item.name : (item is MovieModel ? item.title : '');
          final String? backdropPath = item is ShowModel ? item.backdropPath : (item is MovieModel ? item.backdropPath : null);
          final double rating = item is ShowModel ? item.voteAverage : (item is MovieModel ? item.voteAverage : 0.0);
          final String typeLabel = item is ShowModel ? 'TV SHOW' : 'MOVIE';

          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPosterImage(
                      path: backdropPath,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                      size: 'w780',
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                    // Rank badge (e.g. #1, #2)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${index + 1} TRENDING',
                          style: AppTypography.labelCode.copyWith(
                            fontSize: 10,
                            color: AppColors.textOnAccent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    // Title and rating
                    Positioned(
                      bottom: 14,
                      left: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                typeLabel,
                                style: AppTypography.labelCodeSmall.copyWith(
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star_rounded, color: AppColors.primaryAccent, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: AppTypography.labelCodeSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: AppTypography.headline3.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
