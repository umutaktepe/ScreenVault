import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/tmdb/tmdb_service.dart';
import '../../../data/models/show_model.dart';
import '../../../data/models/movie_model.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/database/database_service.dart';
import '../../common/custom_poster_image.dart';
import '../episode_detail/episode_detail_screen.dart';
import 'widgets/trending_carousel.dart';
import 'widgets/platform_filter_bar.dart';

/// Discover Screen with Live TMDB v3 search, Trending Hero carousel, and Platform filters
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TmdbService _tmdbService = TmdbService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _trendingItems = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _platformShows = [];
  bool _isLoadingTrending = true;
  bool _isLoadingPlatform = false;
  bool _isSearching = false;
  int? _selectedProviderId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _tmdbService.dispose();
    super.dispose();
  }

  Future<void> _onPlatformSelected(int? providerId) async {
    setState(() {
      _selectedProviderId = providerId;
      _isLoadingPlatform = providerId != null;
    });

    if (providerId == null) {
      setState(() => _platformShows = []);
      return;
    }

    final shows = await _tmdbService.getShowsByProvider(providerId);
    if (mounted) {
      setState(() {
        _platformShows = shows;
        _isLoadingPlatform = false;
      });
    }
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoadingTrending = true);
    final results = await _tmdbService.getTrendingAllDay();
    if (mounted) {
      setState(() {
        _trendingItems = results.isNotEmpty ? results : _fallbackTrending();
        _isLoadingTrending = false;
      });
    }
  }

  List<dynamic> _fallbackTrending() {
    return [
      const ShowModel(
        id: 1399,
        name: 'Game of Thrones',
        backdropPath: '/2OMB0ynKlyIenMJWI2Dy9IWT4c.jpg',
        posterPath: '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
        voteAverage: 8.4,
      ),
      const ShowModel(
        id: 66732,
        name: 'Stranger Things',
        backdropPath: '/56v2KjBlU4XaOv9rVYEQypROD7P.jpg',
        posterPath: '/49WJfeN0moxb9IPfGn8AIqMGskD.jpg',
        voteAverage: 8.6,
      ),
      const MovieModel(
        id: 157336,
        title: 'Interstellar',
        backdropPath: '/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
        posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        voteAverage: 8.7,
      ),
    ];
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await _tmdbService.searchMulti(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _handleItemTap(dynamic item) {
    if (item is ShowModel) {
      final defaultEp = EpisodeModel(
        id: 101,
        showId: item.id,
        seasonId: 1,
        seasonNumber: 1,
        episodeNumber: 1,
        name: 'Pilot',
        overview: item.overview,
        stillPath: item.backdropPath,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EpisodeDetailScreen(
            show: item,
            episode: defaultEp,
          ),
        ),
      );
    } else if (item is MovieModel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceHighlight,
          content: Text('${item.title} izleme listesine eklendi!'),
        ),
      );
      _dbService.upsertMovie(item.copyWith(isFollowed: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.canvasBase,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Bar: "Discover" + Live Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover',
                      style: AppTypography.headline1,
                    ),
                    const SizedBox(height: 14),
                    // Live TMDB v3 Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderStroke, width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: AppTypography.bodyLarge,
                        cursorColor: AppColors.primaryAccent,
                        decoration: InputDecoration(
                          hintText: 'Dizi, film veya oyuncu ara...',
                          hintStyle: AppTypography.bodyMedium,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.secondarySlate,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppColors.secondarySlate),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (hasSearchQuery) ...[
              // Search Results Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SEARCH RESULTS',
                        style: AppTypography.labelCode,
                      ),
                      if (_isSearching)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (_searchResults.isEmpty && !_isSearching)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Sonuç bulunamadı.',
                        style: TextStyle(color: AppColors.secondarySlate),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _searchResults[index];
                        return _buildSearchResultTile(item);
                      },
                      childCount: _searchResults.length,
                    ),
                  ),
                ),
            ] else ...[
              // Trending Hero Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRENDING TODAY',
                        style: AppTypography.labelCode.copyWith(letterSpacing: 1.2),
                      ),
                      Text(
                        'Top 10 Global',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _isLoadingTrending
                    ? const SizedBox(
                        height: 220,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
                          ),
                        ),
                      )
                    : TrendingCarousel(
                        items: _trendingItems,
                        onItemTap: _handleItemTap,
                      ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Regional Platform Filter Pills
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'STREAMING PLATFORMS (TR)',
                        style: AppTypography.labelCode,
                      ),
                    ),
                    PlatformFilterBar(
                      selectedProviderId: _selectedProviderId,
                      onSelect: _onPlatformSelected,
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Featured & Popular Picks
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    _selectedProviderId != null ? 'SHOWS ON SELECTED PLATFORM' : 'POPULAR SHOWS',
                    style: AppTypography.labelCode,
                  ),
                ),
              ),

              if (_isLoadingPlatform)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final items = _selectedProviderId != null && _platformShows.isNotEmpty
                            ? _platformShows
                            : _trendingItems;
                        final item = items.isNotEmpty
                            ? items[index % items.length]
                            : null;
                        if (item == null) return const SizedBox.shrink();
                        return _buildSearchResultTile(item);
                      },
                      childCount: (_selectedProviderId != null && _platformShows.isNotEmpty
                              ? _platformShows
                              : _trendingItems)
                          .length,
                    ),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(dynamic item) {
    final String title = item is ShowModel ? item.name : (item is MovieModel ? item.title : '');
    final String? posterPath = item is ShowModel ? item.posterPath : (item is MovieModel ? item.posterPath : null);
    final double rating = item is ShowModel ? item.voteAverage : (item is MovieModel ? item.voteAverage : 0.0);
    final String type = item is ShowModel ? 'Dizi' : 'Film';

    return GestureDetector(
      onTap: () => _handleItemTap(item),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStroke, width: 1),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 75,
              child: CustomPosterImage(
                path: posterPath,
                borderRadius: 8,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, color: AppColors.primaryAccent, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTypography.headline3.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.primaryAccent),
              onPressed: () {
                if (item is ShowModel) {
                  _dbService.upsertShow(item.copyWith(isFollowed: true));
                } else if (item is MovieModel) {
                  _dbService.upsertMovie(item.copyWith(isFollowed: true));
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceHighlight,
                    content: Text('$title takip listesine eklendi!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
