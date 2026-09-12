import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/database_service.dart';
import '../../../data/models/show_model.dart';
import '../show_detail/show_detail_screen.dart';
import '../watchlist/widgets/watchlist_item_tile.dart';
import 'widgets/my_shows_filter_sheet.dart';
import 'widgets/show_grid_card.dart';

/// Dedicated "All My Shows" library screen featuring:
/// - 3-column Grid View and List View toggle
/// - Live search filtering
/// - Quick status filter chips (All, In Progress, Completed, Not Started)
/// - Advanced Filter & Sort bottom sheet (Genres, Years, Multi-criteria sorting)
class MyShowsScreen extends StatefulWidget {
  const MyShowsScreen({super.key});

  @override
  State<MyShowsScreen> createState() => _MyShowsScreenState();
}

class _MyShowsScreenState extends State<MyShowsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isGridView = true;
  String _searchQuery = '';
  String _quickStatus = 'Tümü'; // 'Tümü', 'Devam Eden', 'Tamamlanan', 'Başlanmayan'

  MyShowsFilterResult _filterResult = const MyShowsFilterResult(
    sortOption: ShowSortOption.recentlyActive,
    genres: {},
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _searchQuery) {
        setState(() => _searchQuery = text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _extractAvailableGenres(List<ShowModel> shows) {
    final genres = <String>{};
    for (final s in shows) {
      genres.addAll(s.genres);
    }
    final sorted = genres.toList()..sort();
    return sorted;
  }

  List<int> _extractAvailableYears(List<ShowModel> shows) {
    final years = <int>{};
    for (final s in shows) {
      if (s.firstAirDate != null) {
        years.add(s.firstAirDate!.year);
      }
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  List<ShowModel> _filterAndSortShows(List<ShowModel> allShows) {
    var list = allShows.where((s) => s.isFollowed).toList();

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        final nameMatch = s.name.toLowerCase().contains(q);
        final origMatch = s.originalName?.toLowerCase().contains(q) ?? false;
        return nameMatch || origMatch;
      }).toList();
    }

    // 2. Quick Status
    if (_quickStatus == 'Devam Eden') {
      list = list.where((s) => !s.isCompleted && s.watchedEpisodesCount > 0).toList();
    } else if (_quickStatus == 'Tamamlanan') {
      list = list.where((s) => s.isCompleted).toList();
    } else if (_quickStatus == 'Başlanmayan') {
      list = list.where((s) => s.watchedEpisodesCount == 0).toList();
    }

    // 3. Genres
    if (_filterResult.genres.isNotEmpty) {
      list = list.where((s) {
        return _filterResult.genres.every((g) => s.genres.contains(g));
      }).toList();
    }

    // 4. Release Year
    if (_filterResult.year != null) {
      list = list.where((s) => s.firstAirDate?.year == _filterResult.year).toList();
    }

    // 5. Sorting
    if (_filterResult.sortOption == ShowSortOption.recentlyActive) {
      final dateMap = <int, DateTime?>{
        for (final s in list) s.id: _dbService.getLastWatchedDateForShow(s.id),
      };
      list.sort((a, b) {
        final aDate = dateMap[a.id];
        final bDate = dateMap[b.id];
        if (aDate != null && bDate != null) return bDate.compareTo(aDate);
        if (aDate != null) return -1;
        if (bDate != null) return 1;
        final aTime = a.updatedAt ?? a.createdAt;
        final bTime = b.updatedAt ?? b.createdAt;
        if (aTime != null && bTime != null) return bTime.compareTo(aTime);
        return b.id.compareTo(a.id);
      });
    } else {
      list.sort((a, b) {
        switch (_filterResult.sortOption) {
          case ShowSortOption.recentlyActive:
            return 0; // Handled above

        case ShowSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());

        case ShowSortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());

        case ShowSortOption.ratingDesc:
          return b.voteAverage.compareTo(a.voteAverage);

        case ShowSortOption.yearDesc:
          final aYear = a.firstAirDate?.year ?? 0;
          final bYear = b.firstAirDate?.year ?? 0;
          return bYear.compareTo(aYear);

        case ShowSortOption.yearAsc:
          final aYear = a.firstAirDate?.year ?? 9999;
          final bYear = b.firstAirDate?.year ?? 9999;
          return aYear.compareTo(bYear);

        case ShowSortOption.progressDesc:
          return b.progress.compareTo(a.progress);
      }
    });
  }

  return list;
}

  void _openFilterSheet(List<ShowModel> allFollowed) async {
    final availableGenres = _extractAvailableGenres(allFollowed);
    final availableYears = _extractAvailableYears(allFollowed);

    final result = await showModalBottomSheet<MyShowsFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MyShowsFilterSheet(
        availableGenres: availableGenres,
        availableYears: availableYears,
        currentSort: _filterResult.sortOption,
        currentGenres: _filterResult.genres,
        currentYear: _filterResult.year,
      ),
    );

    if (result != null) {
      setState(() => _filterResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: StreamBuilder<List<ShowModel>>(
          stream: _dbService.showsStream,
          builder: (context, snapshot) {
            final followedCount = _dbService.getFollowedShows().length;
            return Row(
              children: [
                const Text(
                  'Tüm Dizilerim',
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
                    '$followedCount',
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // View Mode Toggle
          IconButton(
            tooltip: _isGridView ? 'Liste Görünümü' : 'Izgara Görünümü',
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          // Filter & Sort Button with Active Badge
          StreamBuilder<List<ShowModel>>(
            stream: _dbService.showsStream,
            builder: (context, snapshot) {
              final allFollowed = _dbService.getFollowedShows();
              final isCustomized = _filterResult.isCustomized;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Filtrele ve Sırala',
                    icon: Icon(
                      Icons.tune_rounded,
                      color: isCustomized ? AppColors.primaryAccent : AppColors.textPrimary,
                      size: 22,
                    ),
                    onPressed: () => _openFilterSheet(allFollowed),
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
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<ShowModel>>(
        stream: _dbService.showsStream,
        builder: (context, snapshot) {
          final allFollowed = _dbService.getFollowedShows();
          final filteredShows = _filterAndSortShows(allFollowed);

          return CustomScrollView(
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
                            hintText: 'Dizilerimde ara...',
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
                            _buildQuickStatusChip('Devam Eden'),
                            const SizedBox(width: 8),
                            _buildQuickStatusChip('Tamamlanan'),
                            const SizedBox(width: 8),
                            _buildQuickStatusChip('Başlanmayan'),
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
                              _filterResult = const MyShowsFilterResult(
                                sortOption: ShowSortOption.recentlyActive,
                                genres: {},
                              );
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
              if (allFollowed.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.live_tv_rounded, size: 64, color: AppColors.borderStroke),
                          SizedBox(height: 16),
                          Text(
                            'Takip Ettiğiniz Dizi Bulunmuyor',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Keşfet sekmesinden yeni diziler arayıp takip listenize ekleyebilirsiniz.',
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
              else if (filteredShows.isEmpty)
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
                            'Aramanızla Eşleşen Dizi Bulunamadı',
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
                                _filterResult = const MyShowsFilterResult(
                                  sortOption: ShowSortOption.recentlyActive,
                                  genres: {},
                                );
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
                        final show = filteredShows[index];
                        return ShowGridCard(
                          show: show,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShowDetailScreen(show: show),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filteredShows.length,
                    ),
                  ),
                )
              else
                // Rich Vertical List View
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final show = filteredShows[index];
                        return WatchlistItemTile(
                          show: show,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShowDetailScreen(show: show),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filteredShows.length,
                    ),
                  ),
                ),

              // Bottom Padding for smooth scrolling
              const SliverToBoxAdapter(
                child: SizedBox(height: 48),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickStatusChip(String label) {
    final isSelected = _quickStatus == label;
    return GestureDetector(
      onTap: () => setState(() => _quickStatus = label),
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
