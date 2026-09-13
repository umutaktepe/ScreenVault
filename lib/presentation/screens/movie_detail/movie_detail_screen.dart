import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/database/database_service.dart';
import '../../../data/models/movie_model.dart';
import '../../../data/models/show_model.dart';
import '../../common/custom_poster_image.dart';

/// Movie Detail Screen displaying backdrop hero, metadata, synopsis,
/// and live toggles for watchlist and watched status.
class MovieDetailScreen extends StatefulWidget {
  final MovieModel movie;

  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  late MovieModel _currentMovie;

  @override
  void initState() {
    super.initState();
    _currentMovie = _dbService.getMovieById(widget.movie.id) ?? widget.movie;

    // Self-healing metadata enrichment if missing
    if (_currentMovie.overview == null || _currentMovie.backdropPath == null) {
      unawaited(_dbService.enrichSingleMovie(_currentMovie).then((enriched) {
        if (enriched != null && mounted) {
          setState(() {
            _currentMovie = enriched;
          });
        }
      }));
    }
  }

  Future<void> _toggleWatchlist() async {
    HapticFeedback.lightImpact();
    if (_dbService.getMovieById(_currentMovie.id) == null) {
      await _dbService.upsertMovie(_currentMovie);
    }
    await _dbService.toggleMovieFollowed(_currentMovie.id);
    final up = _dbService.getMovieById(_currentMovie.id);
    if (up != null && mounted) {
      setState(() {
        _currentMovie = up;
      });
    }
  }

  Future<void> _toggleWatched() async {
    HapticFeedback.mediumImpact();
    if (_dbService.getMovieById(_currentMovie.id) == null) {
      await _dbService.upsertMovie(_currentMovie);
    }
    await _dbService.toggleMovieWatched(_currentMovie.id);
    final up = _dbService.getMovieById(_currentMovie.id);
    if (up != null && mounted) {
      setState(() {
        _currentMovie = up;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShowModel>>(
      stream: _dbService.showsStream,
      builder: (context, snapshot) {
        final movie = _dbService.getMovieById(_currentMovie.id) ?? _currentMovie;

        return Scaffold(
          backgroundColor: AppColors.canvasBase,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Hero Backdrop Header with Scrim, Back button & Action Pill
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.canvasBase,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: _toggleWatchlist,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: movie.isFollowed
                              ? AppColors.primaryAccent
                              : Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: movie.isFollowed
                                ? AppColors.primaryAccent
                                : AppColors.borderStroke,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              movie.isFollowed
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_add_outlined,
                              size: 16,
                              color: movie.isFollowed ? AppColors.textOnAccent : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPosterImage(
                        path: movie.backdropPath,
                        fallbackPath: movie.posterPath,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                        size: 'w780',
                      ),
                      // Gradient Overlay fading into canvasBase
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              AppColors.canvasBase,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Movie Details Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster + Info Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomPosterImage(
                            path: movie.posterPath,
                            width: 100,
                            height: 150,
                            borderRadius: 12,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  style: AppTypography.headline2.copyWith(fontSize: 22),
                                ),
                                const SizedBox(height: 6),
                                // Release year & Runtime
                                Text(
                                  [
                                    if (movie.releaseDate != null) '${movie.releaseDate!.year}',
                                    if (movie.runtimeMinutes > 0) '${movie.runtimeMinutes} dk',
                                  ].join(' • '),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.secondarySlate,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // TMDB Rating Badge
                                if (movie.voteAverage > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.borderStroke),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: AppColors.primaryAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          movie.voteAverage.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Genres
                                if (movie.genres.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: movie.genres.map((g) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceHighlight.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.borderStroke.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Text(
                                          g,
                                          style: const TextStyle(
                                            color: AppColors.secondarySlate,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons: Watchlist & Watched
                      Row(
                        children: [
                          // Watchlist Button
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleWatchlist,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: movie.isFollowed
                                      ? AppColors.primaryAccent
                                      : AppColors.cardSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: movie.isFollowed
                                        ? AppColors.primaryAccent
                                        : AppColors.borderStroke,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      movie.isFollowed
                                          ? Icons.bookmark_added_rounded
                                          : Icons.bookmark_add_outlined,
                                      color: movie.isFollowed
                                          ? AppColors.textOnAccent
                                          : Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        movie.isFollowed ? 'Listemde' : 'İzleme Listesine Ekle',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: movie.isFollowed
                                              ? AppColors.textOnAccent
                                              : Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Watched Button
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleWatched,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: movie.isWatched
                                      ? AppColors.functionalSuccess
                                      : AppColors.cardSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: movie.isWatched
                                        ? AppColors.functionalSuccess
                                        : AppColors.borderStroke,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      movie.isWatched
                                          ? Icons.check_circle_rounded
                                          : Icons.check_circle_outline_rounded,
                                      color: movie.isWatched
                                          ? Colors.white
                                          : AppColors.secondarySlate,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        movie.isWatched ? 'İzlendi ✓' : 'İzlendi Olarak İşaretle',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Watch Date Feedback
                      if (movie.isWatched && movie.watchedAt != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.functionalSuccess.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.functionalSuccess.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                size: 16,
                                color: AppColors.functionalSuccess,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'İzlenme Tarihi: ${DateFormatter.formatAirDate(movie.watchedAt)}',
                                style: const TextStyle(
                                  color: AppColors.functionalSuccess,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Synopsis / Overview Card
                      if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Özet',
                          style: AppTypography.headline3.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderStroke),
                          ),
                          child: Text(
                            movie.overview!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.secondarySlate,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
