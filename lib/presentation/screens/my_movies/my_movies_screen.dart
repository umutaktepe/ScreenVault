import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/database_service.dart';
import '../../../data/models/movie_model.dart';
import '../../../data/models/show_model.dart';
import '../movie_detail/movie_detail_screen.dart';
import '../watchlist/widgets/watchlist_movie_tile.dart';
import 'widgets/movie_grid_card.dart';
import 'widgets/my_movies_filter_sheet.dart';

/// Dedicated "All My Movies" library screen featuring:
/// - 3-column Grid View and List View toggle
/// - Live search filtering (by title and genres)
/// - Quick status filter chips (Tümü, İzlenecekler, İzlenenler)
/// - Advanced Filter & Sort bottom sheet (Genres, Years, Multi-criteria sorting)
/// - Infinite scroll pagination (18 per page - divisible by 3 for 3-column grid)
class MyMoviesScreen extends StatefulWidget {
  const MyMoviesScreen({super.key});

  @override
  State<MyMoviesScreen> createState() => _MyMoviesScreenState();
}

class _MyMoviesScreenState extends State<MyMoviesScreen> {
  static const int _pageSize = 18;

  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isGridView = true;
  String _searchQuery = '';
  String _quickStatus = 'Tümü'; // 'Tümü', 'İzlenecekler', 'İzlenenler'
  int _displayedCount = _pageSize;
  int _lastFilteredCount = 0;
  bool _isLoadingMore = false;

  MyMoviesFilterResult _filterResult = const MyMoviesFilterResult(
    sortOption: MovieSortOption.recentlyActive,
    genres: {},
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
          _displayedCount = _pageSize;
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll - 100) {
      if (_displayedCount < _lastFilteredCount) {
        _loadMore();
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    // Provide a brief tactile loading delay (300ms) to prevent cascading momentum flings
    // and give visual feedback to the user that a new batch of 18 is being fetched
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() {
      _displayedCount = (_displayedCount + _pageSize).clamp(0, _lastFilteredCount);
      _isLoadingMore = false;
    });
  }

  List<String> _extractAvailableGenres(List<MovieModel> movies) {
    final genres = <String>{};
    for (final m in movies) {
      genres.addAll(m.genres);
    }
    final sorted = genres.toList()..sort();
    return sorted;
  }

  List<int> _extractAvailableYears(List<MovieModel> movies) {
    final years = <int>{};
    for (final m in movies) {
      if (m.releaseDate != null) {
        years.add(m.releaseDate!.year);
      }
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  List<MovieModel> _filterAndSortMovies(List<MovieModel> allMovies) {
    var list = allMovies.toList();

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) {
        final titleMatch = m.title.toLowerCase().contains(q);
        final genreMatch = m.genres.any((g) => g.toLowerCase().contains(q));
        final overviewMatch = m.overview?.toLowerCase().contains(q) ?? false;
        return titleMatch || genreMatch || overviewMatch;
      }).toList();
    }

    // 2. Quick Status
    if (_quickStatus == 'İzlenecekler') {
      list = list.where((m) => !m.isWatched).toList();
    } else if (_quickStatus == 'İzlenenler') {
      list = list.where((m) => m.isWatched).toList();
    }

    // 3. Genres
    if (_filterResult.genres.isNotEmpty) {
      list = list.where((m) {
        return _filterResult.genres.every((g) => m.genres.contains(g));
      }).toList();
    }

    // 4. Release Year
    if (_filterResult.year != null) {
      list = list.where((m) => m.releaseDate?.year == _filterResult.year).toList();
    }

    // 5. Sorting
    list.sort((a, b) {
      switch (_filterResult.sortOption) {
        case MovieSortOption.recentlyActive:
          if (a.watchedAt != null && b.watchedAt != null) {
            return b.watchedAt!.compareTo(a.watchedAt!);
          }
          if (a.watchedAt != null) return -1;
          if (b.watchedAt != null) return 1;
          return b.id.compareTo(a.id);

        case MovieSortOption.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());

        case MovieSortOption.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());

        case MovieSortOption.ratingDesc:
          return b.voteAverage.compareTo(a.voteAverage);

        case MovieSortOption.releaseDateDesc:
          final aDate = a.releaseDate?.millisecondsSinceEpoch ?? 0;
          final bDate = b.releaseDate?.millisecondsSinceEpoch ?? 0;
          return bDate.compareTo(aDate);

        case MovieSortOption.releaseDateAsc:
          final aDate = a.releaseDate?.millisecondsSinceEpoch ?? 99999999999999;
          final bDate = b.releaseDate?.millisecondsSinceEpoch ?? 99999999999999;
          return aDate.compareTo(bDate);

        case MovieSortOption.runtimeDesc:
          return b.runtimeMinutes.compareTo(a.runtimeMinutes);

        case MovieSortOption.runtimeAsc:
          return a.runtimeMinutes.compareTo(b.runtimeMinutes);
      }
    });

    return list;
  }

  void _openFilterSheet(List<MovieModel> allMovies) async {
    final availableGenres = _extractAvailableGenres(allMovies);
    final availableYears = _extractAvailableYears(allMovies);

    final result = await showModalBottomSheet<MyMoviesFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MyMoviesFilterSheet(
        availableGenres: availableGenres,
        availableYears: availableYears,
        currentSort: _filterResult.sortOption,
        currentGenres: _filterResult.genres,
        currentYear: _filterResult.year,
      ),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _filterResult = result;
        _displayedCount = _pageSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShowModel>>(
      stream: _dbService.showsStream,
      builder: (context, snapshot) {
        final allMovies = _dbService.getFollowedOrWatchedMovies();
        final filteredMovies = _filterAndSortMovies(allMovies);
        _lastFilteredCount = filteredMovies.length;
        final paginatedMovies = filteredMovies.take(_displayedCount).toList();
        final isCustomized = _filterResult.isCustomized;
        final countLabel = '${filteredMovies.length} Film';

        return Scaffold(
          backgroundColor: AppColors.canvasBase,
          appBar: AppBar(
            backgroundColor: AppColors.canvasBase,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                const Text(
                  'Tüm Filmlerim',
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
                    countLabel,
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // View Mode Toggle (Icons.view_agenda_rounded for list mode, Icons.grid_view_rounded for grid mode)
              IconButton(
                tooltip: _isGridView ? 'Liste Görünümü' : 'Izgara Görünümü',
                icon: Icon(
                  _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              // Filter & Sort Button with Active Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Filtrele ve Sırala',
                    icon: Icon(
                      Icons.tune_rounded,
                      color: isCustomized ? AppColors.primaryAccent : AppColors.textPrimary,
                      size: 22,
                    ),
                    onPressed: () => _openFilterSheet(allMovies),
                  ),
                  if (isCustomized)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            slivers: [
              // Sticky-style Search & Quick Filter Controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Field
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderStroke, width: 1),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Filmlerimde ara...',
                            hintStyle: const TextStyle(color: AppColors.secondarySlate, fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondarySlate, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: AppColors.secondarySlate, size: 18),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quick Status Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickStatusChip('Tümü'),
                            const SizedBox(width: 8),
                            _buildQuickStatusChip('İzlenecekler'),
                            const SizedBox(width: 8),
                            _buildQuickStatusChip('İzlenenler'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Summary Tag Bar (if any custom filters applied)
              if (_filterResult.isCustomized)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_outlined, color: AppColors.primaryAccent, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Sıralama: ${_filterResult.sortOption.label}'
                            '${_filterResult.genres.isNotEmpty ? " • Türler: ${_filterResult.genres.join(", ")}" : ""}'
                            '${_filterResult.year != null ? " • Yıl: ${_filterResult.year}" : ""}',
                            style: const TextStyle(
                              color: AppColors.primaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterResult = const MyMoviesFilterResult(
                                sortOption: MovieSortOption.recentlyActive,
                                genres: {},
                              );
                              _displayedCount = _pageSize;
                            });
                          },
                          child: const Text(
                            'Sıfırla',
                            style: TextStyle(
                              color: AppColors.errorRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Empty States or List/Grid View
              if (allMovies.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.movie_outlined, size: 64, color: AppColors.borderStroke),
                          SizedBox(height: 16),
                          Text(
                            'Listenizde Film Bulunmuyor',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Keşfet sekmesinden yeni filmler arayıp listenize ekleyebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.secondarySlate,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (filteredMovies.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 56, color: AppColors.borderStroke),
                          const SizedBox(height: 16),
                          const Text(
                            'Aramanızla Eşleşen Film Bulunamadı',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Filtreleri veya arama terimini değiştirip tekrar deneyin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.secondarySlate,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceHighlight,
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderStroke),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _quickStatus = 'Tümü';
                                _filterResult = const MyMoviesFilterResult(
                                  sortOption: MovieSortOption.recentlyActive,
                                  genres: {},
                                );
                                _displayedCount = _pageSize;
                              });
                            },
                            child: const Text('Filtreleri Temizle'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_isGridView)
                // 3-Column Posters Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = paginatedMovies[index];
                        return MovieGridCard(
                          movie: movie,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MovieDetailScreen(movie: movie),
                              ),
                            );
                          },
                        );
                      },
                      childCount: paginatedMovies.length,
                    ),
                  ),
                )
              else
                // Rich Vertical List View using WatchlistMovieTile
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = paginatedMovies[index];
                        return WatchlistMovieTile(
                          movie: movie,
                          databaseService: _dbService,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MovieDetailScreen(movie: movie),
                              ),
                            );
                          },
                        );
                      },
                      childCount: paginatedMovies.length,
                    ),
                  ),
                ),

              // Loading More Indicator (only active while fetching next batch)
              if (_isLoadingMore)
                _buildLoadingIndicator(),

              // End of List Indicator (when all items loaded)
              if (!_isLoadingMore && paginatedMovies.isNotEmpty && _displayedCount >= filteredMovies.length)
                _buildEndOfListIndicator(filteredMovies.length),

              // Bottom Padding for smooth scrolling
              const SliverToBoxAdapter(
                child: SizedBox(height: 48),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Daha fazla film yükleniyor...',
                style: TextStyle(
                  color: AppColors.secondarySlate.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndOfListIndicator(int totalCount) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: AppColors.borderStroke.withValues(alpha: 0.6),
                thickness: 0.8,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.movie_filter_outlined,
                    color: AppColors.secondarySlate,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tüm $totalCount film listelendi',
                    style: const TextStyle(
                      color: AppColors.secondarySlate,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Divider(
                color: AppColors.borderStroke.withValues(alpha: 0.6),
                thickness: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusChip(String label) {
    final isSelected = _quickStatus == label;
    return GestureDetector(
      onTap: () {
        if (_quickStatus != label) {
          setState(() {
            _quickStatus = label;
            _displayedCount = _pageSize;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textOnAccent : AppColors.secondarySlate,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
