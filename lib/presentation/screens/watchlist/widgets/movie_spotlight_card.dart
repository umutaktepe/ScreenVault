import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/database/database_service.dart';
import '../../../../data/models/movie_model.dart';
import '../../../common/checkmark_toggle_button.dart';
import '../../../common/custom_poster_image.dart';

/// Hero showcase spotlight card for movies matching UpNextCard visual quality:
/// - 16:9 cinematic backdrop with gradient scrim
/// - 18px rounded corners with subtle border stroke
/// - Top header with gold "SPOTLIGHT" badge and status pill ("Sıradaki Film" / "Son İzlenen")
/// - Large title, star rating, runtime, and genre pills
/// - Integrated 40px CheckmarkToggleButton for instant watched state toggling
/// - InkWell tap gesture triggering navigation onTap
class MovieSpotlightCard extends StatefulWidget {
  final MovieModel movie;
  final VoidCallback onTap;
  final DatabaseService? databaseService;
  final ValueChanged<bool>? onToggleWatched;

  const MovieSpotlightCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.databaseService,
    this.onToggleWatched,
  });

  @override
  State<MovieSpotlightCard> createState() => _MovieSpotlightCardState();
}

class _MovieSpotlightCardState extends State<MovieSpotlightCard> {
  late bool _isWatched;
  late final DatabaseService _dbService;

  @override
  void initState() {
    super.initState();
    _isWatched = widget.movie.isWatched;
    _dbService = widget.databaseService ?? DatabaseService();
  }

  @override
  void didUpdateWidget(covariant MovieSpotlightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.id != widget.movie.id ||
        oldWidget.movie.isWatched != widget.movie.isWatched) {
      _isWatched = widget.movie.isWatched;
    }
  }

  Future<void> _handleToggleWatched(bool watched) async {
    final previousState = _isWatched;
    setState(() {
      _isWatched = watched;
    });
    try {
      if (_dbService.getMovieById(widget.movie.id) == null) {
        await _dbService.upsertMovie(widget.movie);
      }
      await _dbService.toggleMovieWatched(widget.movie.id, isWatched: watched);
      widget.onToggleWatched?.call(watched);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isWatched = previousState;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 16:9 Cinematic Backdrop with Badges & Checkmark
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPosterImage(
                        path: movie.backdropPath ?? movie.posterPath,
                        fallbackPath: movie.posterPath,
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
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.9),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                      // Top Badges: SPOTLIGHT + Status ("Sıradaki Film" / "Son İzlenen")
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Gold SPOTLIGHT Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primaryAccent.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 11,
                                    color: AppColors.primaryAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SPOTLIGHT',
                                    style: AppTypography.labelCode.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.canvasBase.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _isWatched
                                      ? AppColors.functionalSuccess.withValues(alpha: 0.6)
                                      : AppColors.borderStroke,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _isWatched ? 'Son İzlenen' : 'Sıradaki Film',
                                style: AppTypography.labelCodeSmall.copyWith(
                                  color: _isWatched
                                      ? AppColors.functionalSuccess
                                      : AppColors.secondarySlate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 40px Circular CheckmarkToggleButton
                      Positioned(
                        bottom: 14,
                        right: 14,
                        child: CheckmarkToggleButton(
                          isWatched: _isWatched,
                          onToggle: _handleToggleWatched,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                // Movie Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Title
                      Text(
                        movie.title,
                        style: AppTypography.headline2.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Metadata row: Star rating, Runtime, Release year
                      Row(
                        children: [
                          if (movie.voteAverage > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.primaryAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                color: AppColors.secondarySlate.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (movie.runtimeMinutes > 0) ...[
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.secondarySlate,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${movie.runtimeMinutes} dk',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondarySlate,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (movie.releaseDate != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: AppColors.secondarySlate.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                          if (movie.releaseDate != null) ...[
                            Text(
                              '${movie.releaseDate!.year}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondarySlate,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Genres pills
                      if (movie.genres.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: movie.genres.take(3).map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.canvasBase.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderStroke, width: 0.5),
                              ),
                              child: Text(
                                genre,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondarySlate,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      // Overview (if present)
                      if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          movie.overview!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.secondarySlate,
                            fontSize: 13,
                          ),
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
      ),
    );
  }
}
