import 'package:flutter/material.dart';
import '../../common/user_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/database_service.dart';
import '../../../data/models/show_model.dart';
import '../../../data/models/movie_model.dart';
import '../episode_detail/episode_detail_screen.dart';
import '../show_detail/show_detail_screen.dart';
import 'widgets/up_next_card.dart';
import 'widgets/watchlist_item_tile.dart';

/// Main Watchlist Screen matching Stitch TV Time Tracker UI specification
class WatchlistScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const WatchlistScreen({super.key, this.onProfileTap});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final DatabaseService _dbService = DatabaseService();
  int _selectedSegment = 0; // 0: TV Shows, 1: Movies
  String _filterCategory = 'All'; // All, In Progress, Up to Date

  @override
  void initState() {
    super.initState();
    _dbService.init();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvasBase,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar: "ScreenVault" + Avatar + Segmented Switcher
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ScreenVault',
                          style: AppTypography.headline1.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onProfileTap,
                          child: const UserAvatar(
                            radius: 19,
                            borderColor: AppColors.primaryAccent,
                            fallbackText: 'Umut',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // TV Shows / Movies Segmented Pill Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.borderStroke, width: 1),
                      ),
                      child: Row(
                        children: [
                          _buildSegmentButton(0, 'TV Shows'),
                          _buildSegmentButton(1, 'Movies'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_selectedSegment == 0) ...[
              // "Up Next" Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UP NEXT',
                        style: AppTypography.labelCode.copyWith(
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Next Episode',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // Up Next Card
              SliverToBoxAdapter(
                child: StreamBuilder<List<ShowModel>>(
                  stream: _dbService.showsStream,
                  builder: (context, snapshot) {
                    final upNextEp = _dbService.getUpNextEpisode();
                    final shows = _dbService.getFollowedShows();
                    final upNextShow = upNextEp != null
                        ? (_dbService.getShowById(upNextEp.showId) ?? (shows.isNotEmpty ? shows.first : null))
                        : (shows.isNotEmpty ? shows.first : null);

                    if (upNextShow == null || upNextEp == null) {
                      return const SizedBox.shrink();
                    }

                    return UpNextCard(
                      show: upNextShow,
                      episode: upNextEp,
                      onToggleWatched: (val) {
                        _dbService.markEpisodeWatched(upNextEp.id, watched: val);
                      },
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EpisodeDetailScreen(
                              show: upNextShow,
                              episode: upNextEp,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Filter Chips (All, In Progress, Completed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Progress'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed'),
                    ],
                  ),
                ),
              ),

              // Watchlist Vertical Stream
              StreamBuilder<List<ShowModel>>(
                stream: _dbService.showsStream,
                builder: (context, snapshot) {
                  var shows = _dbService.getFollowedShows();
                  if (_filterCategory == 'In Progress') {
                    shows = shows.where((s) => !s.isCompleted).toList();
                  } else if (_filterCategory == 'Completed') {
                    shows = shows.where((s) => s.isCompleted).toList();
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final show = shows[index];
                        return WatchlistItemTile(
                          show: show,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShowDetailScreen(
                                  show: show,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: shows.length,
                    ),
                  );
                },
              ),
            ] else ...[
              // Movies View
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final movies = _dbService.getAllMovies();
                      if (movies.isEmpty) {
                        return const Center(child: Text('No movies followed yet.'));
                      }
                      final movie = movies[index];
                      return _buildMovieTile(movie);
                    },
                    childCount: _dbService.getAllMovies().length,
                  ),
                ),
              ),
            ],

            // Bottom Spacing for Floating Navbar (64px + 16px bottom margin)
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(int index, String title) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Center(
            child: Text(
              title,
              style: AppTypography.buttonPrimary.copyWith(
                color: isSelected ? AppColors.textOnAccent : AppColors.secondarySlate,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _filterCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceHighlight : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryAccent : AppColors.secondarySlate,
          ),
        ),
      ),
    );
  }

  Widget _buildMovieTile(MovieModel movie) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.movie_rounded, color: AppColors.secondarySlate, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: AppTypography.headline3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${movie.runtimeMinutes} dk • ${movie.genres.join(', ')}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.functionalSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'İzlendi ✓',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.functionalSuccess,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
