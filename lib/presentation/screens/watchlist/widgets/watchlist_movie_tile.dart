import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/database/database_service.dart';
import '../../../../data/models/movie_model.dart';
import '../../../common/checkmark_toggle_button.dart';
import '../../../common/custom_poster_image.dart';

/// Interactive watchlist movie tile widget displaying rich metadata:
/// - 2:3 vertical poster with border radius 10
/// - Movie title with AppTypography.headline3
/// - Subtitle with release year, runtime in minutes, and TMDB star rating
/// - Status badge ('İzlendi ✓' in emerald or 'İzlenecek' in gold) and genre pill
/// - Interactive CheckmarkToggleButton to toggle watched state
/// - Card onTap callback for navigation
class WatchlistMovieTile extends StatefulWidget {
  final MovieModel movie;
  final VoidCallback onTap;
  final DatabaseService? databaseService;
  final ValueChanged<bool>? onToggleWatched;

  const WatchlistMovieTile({
    super.key,
    required this.movie,
    required this.onTap,
    this.databaseService,
    this.onToggleWatched,
  });

  @override
  State<WatchlistMovieTile> createState() => _WatchlistMovieTileState();
}

class _WatchlistMovieTileState extends State<WatchlistMovieTile> {
  late bool _isWatched;
  late final DatabaseService _dbService;

  @override
  void initState() {
    super.initState();
    _isWatched = widget.movie.isWatched;
    _dbService = widget.databaseService ?? DatabaseService();
  }

  @override
  void didUpdateWidget(covariant WatchlistMovieTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.isWatched != widget.movie.isWatched) {
      _isWatched = widget.movie.isWatched;
    }
  }

  Future<void> _handleToggleWatched(bool watched) async {
    setState(() {
      _isWatched = watched;
    });
    await _dbService.toggleMovieWatched(widget.movie.id, isWatched: watched);
    widget.onToggleWatched?.call(watched);
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (widget.movie.releaseDate != null) {
      parts.add('${widget.movie.releaseDate!.year}');
    }
    if (widget.movie.runtimeMinutes > 0) {
      parts.add('${widget.movie.runtimeMinutes} dk');
    }
    if (widget.movie.voteAverage > 0) {
      parts.add('⭐ ${widget.movie.voteAverage.toStringAsFixed(1)}');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final subtitle = _buildSubtitle();

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStroke, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 2:3 Vertical Poster
                  SizedBox(
                    width: 60,
                    height: 90,
                    child: CustomPosterImage(
                      path: movie.posterPath,
                      borderRadius: 10,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Movie Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movie.title,
                          style: AppTypography.headline3.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondarySlate,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (_isWatched ? AppColors.functionalSuccess : AppColors.primaryAccent)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (_isWatched ? AppColors.functionalSuccess : AppColors.primaryAccent)
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _isWatched ? 'İzlendi ✓' : 'İzlenecek',
                                style: AppTypography.labelCodeSmall.copyWith(
                                  color: _isWatched ? AppColors.functionalSuccess : AppColors.primaryAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (movie.genres.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceHighlight,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.borderStroke,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    movie.genres.first,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 10,
                                      color: AppColors.secondarySlate,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Checkmark toggle button
                  CheckmarkToggleButton(
                    isWatched: _isWatched,
                    onToggle: _handleToggleWatched,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
