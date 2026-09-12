import 'package:flutter/material.dart';
import '../../common/user_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/database_service.dart';
import '../../../data/services/pocketbase_auth_service.dart';
import '../../../data/models/show_model.dart';
import '../../../data/models/movie_model.dart';
import '../episode_detail/episode_detail_screen.dart';
import '../show_detail/show_detail_screen.dart';
import '../my_shows/my_shows_screen.dart';
import '../../common/custom_poster_image.dart';
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
  final Set<int> _enrichingMovieIds = {};
  final Set<int> _enrichingShowIds = {};
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
                          child: StreamBuilder(
                            stream: PocketBaseAuthService().authStateStream,
                            builder: (context, _) {
                              final auth = PocketBaseAuthService();
                              final name = auth.isLoggedIn ? auth.userName : 'Misafir';
                              return UserAvatar(
                                radius: 19,
                                borderColor: auth.isLoggedIn ? AppColors.functionalSuccess : AppColors.primaryAccent,
                                url: auth.avatarUrl,
                                fallbackText: name,
                              );
                            },
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

              // Section Header: "Dizilerim" & "Tümünü Gör >"
              SliverToBoxAdapter(
                child: StreamBuilder<List<ShowModel>>(
                  stream: _dbService.showsStream,
                  builder: (context, snapshot) {
                    final allFollowed = _dbService.getFollowedShows();
                    if (allFollowed.isEmpty) return const SizedBox.shrink();

                    final totalCount = allFollowed.length;
                    final shownCount = totalCount > 10 ? 10 : totalCount;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Dizilerim',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.borderStroke, width: 0.5),
                                ),
                                child: Text(
                                  '$shownCount / $totalCount',
                                  style: const TextStyle(
                                    color: AppColors.primaryAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const MyShowsScreen(),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Tümünü Gör >',
                                style: TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Filter Chips (All, In Progress, Completed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

              // Watchlist Vertical Stream (Top 10 most recently active shows)
              StreamBuilder<List<ShowModel>>(
                stream: _dbService.showsStream,
                builder: (context, snapshot) {
                  var shows = _dbService.getRecentlyActiveFollowedShows();
                  if (_filterCategory == 'In Progress') {
                    shows = shows.where((s) => !s.isCompleted).toList();
                  } else if (_filterCategory == 'Completed') {
                    shows = shows.where((s) => s.isCompleted).toList();
                  }

                  final totalShowsCount = shows.length;
                  final hasMore = totalShowsCount > 10;
                  final displayedShows = shows.take(10).toList();

                  if (displayedShows.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Text(
                            'Takip edilen dizi bulunmuyor.',
                            style: TextStyle(color: AppColors.secondarySlate, fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Trailing "Show More" Button Card
                        if (index == displayedShows.length) {
                          return _buildShowMoreButton(
                            context,
                            totalShowsCount,
                            totalShowsCount - 10,
                          );
                        }

                        final show = displayedShows[index];
                        if ((show.posterPath == null || show.posterPath!.isEmpty) && !_enrichingShowIds.contains(show.id)) {
                          _enrichingShowIds.add(show.id);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _dbService.enrichSingleShow(show).then((_) {
                              if (mounted) setState(() {});
                            });
                          });
                        }
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
                      childCount: displayedShows.length + (hasMore ? 1 : 0),
                    ),
                  );
                },
              ),
            ] else ...[
              // Movies View
              StreamBuilder<List<ShowModel>>(
                stream: _dbService.showsStream,
                builder: (context, snapshot) {
                  final movies = _dbService.getAllMovies().where((m) => m.isFollowed || m.isWatched).toList();
                  if (movies.isEmpty) {
                    return const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              'Takip edilen veya izlenen film bulunmuyor.',
                              style: TextStyle(color: AppColors.secondarySlate, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final movie = movies[index];
                          return _buildMovieTile(movie);
                        },
                        childCount: movies.length,
                      ),
                    ),
                  );
                },
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

  Widget _buildShowMoreButton(BuildContext context, int totalCount, int remainingCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MyShowsScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderStroke),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.grid_view_rounded, color: AppColors.primaryAccent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tüm Dizilerimi Gör',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+$remainingCount dizi daha kütüphanenizde',
                        style: const TextStyle(
                          color: AppColors.secondarySlate,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.secondarySlate, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieTile(MovieModel movie) {
    if ((movie.posterPath == null || movie.posterPath!.isEmpty) && !_enrichingMovieIds.contains(movie.id)) {
      _enrichingMovieIds.add(movie.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dbService.enrichSingleMovie(movie).then((_) {
          if (mounted) setState(() {});
        });
      });
    }

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
          SizedBox(
            width: 60,
            height: 90,
            child: movie.posterPath != null && movie.posterPath!.isNotEmpty
                ? CustomPosterImage(
                    path: movie.posterPath,
                    borderRadius: 10,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.movie_rounded, color: AppColors.secondarySlate, size: 28),
                    ),
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
                Row(
                  children: [
                    if (movie.isWatched)
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
                      )
                    else if (movie.isFollowed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'İzlenecek',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
