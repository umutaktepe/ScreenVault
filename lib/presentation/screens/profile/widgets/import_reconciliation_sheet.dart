import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/database/database_service.dart';
import '../../../../data/models/unresolved_item_model.dart';
import '../../../../data/models/show_model.dart';
import '../../../../data/models/movie_model.dart';
import '../../../../data/tmdb/tmdb_service.dart';
import '../../../../data/tmdb/title_sanitizer.dart';
import '../../../../data/sync/pocketbase_sync_engine.dart';
import '../../../common/custom_poster_image.dart';

/// Obsidian Cinema themed modal sheet for reconciling unresolved TV Time items
class ImportReconciliationSheet extends StatefulWidget {
  final List<UnresolvedItemModel> items;
  final VoidCallback? onCompleted;

  const ImportReconciliationSheet({
    super.key,
    required this.items,
    this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    List<UnresolvedItemModel>? items,
    VoidCallback? onCompleted,
  }) {
    final db = DatabaseService();
    final unresolved = items ?? db.getUnresolvedItems();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImportReconciliationSheet(
        items: unresolved,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<ImportReconciliationSheet> createState() => _ImportReconciliationSheetState();
}

class _ImportReconciliationSheetState extends State<ImportReconciliationSheet> {
  final DatabaseService _dbService = DatabaseService();
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();

  late List<UnresolvedItemModel> _remainingItems;
  int _currentIndex = 0;
  bool _isSearching = false;
  bool _isProcessing = false;
  List<dynamic> _searchResults = [];
  Timer? _debounceTimer;

  bool _isPlaceholderTitle(String title) {
    final t = title.trim();
    return t.isEmpty ||
        t.startsWith('Show ') ||
        t.startsWith('Movie ') ||
        RegExp(r'^(Show|Movie)\s+\d+$', caseSensitive: false).hasMatch(t);
  }

  @override
  void initState() {
    super.initState();
    _remainingItems = List.from(widget.items);
    if (_remainingItems.isNotEmpty) {
      final item = _remainingItems.first;
      if (!_isPlaceholderTitle(item.rawTitle)) {
        final parsedTitle = TitleSanitizer.parseTitleAndYear(item.rawTitle).cleanTitle;
        final query = parsedTitle.isNotEmpty ? parsedTitle : item.rawTitle;
        _searchController.text = query;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _triggerSearch(query);
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initSearchForCurrentItem() {
    if (_currentIndex >= _remainingItems.length) return;
    final item = _remainingItems[_currentIndex];
    // If the title is not a generic placeholder like "Show 123" or "Movie 456", prepopulate the search bar with clean title
    if (!_isPlaceholderTitle(item.rawTitle)) {
      final parsedTitle = TitleSanitizer.parseTitleAndYear(item.rawTitle).cleanTitle;
      final query = parsedTitle.isNotEmpty ? parsedTitle : item.rawTitle;
      _searchController.text = query;
      _triggerSearch(query);
    } else {
      _searchController.clear();
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _triggerSearch(query);
    });
  }

  Future<void> _triggerSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _tmdbService.searchMulti(clean);
      if (!mounted || _searchController.text.trim() != clean) return;

      final currentItem = (_remainingItems.isNotEmpty && _currentIndex < _remainingItems.length)
          ? _remainingItems[_currentIndex]
          : null;

      final sortedResults = List<dynamic>.from(results);

      // Prioritize results matching the current item's type, exact clean title, and target year tolerance
      if (currentItem != null && sortedResults.isNotEmpty) {
        final isShow = currentItem.type == UnresolvedItemType.show;
        final cleanTarget = TitleSanitizer.parseTitleAndYear(currentItem.rawTitle).cleanTitle.toLowerCase().trim();
        final targetYear = TitleSanitizer.parseTitleAndYear(currentItem.rawTitle).extractedYear ?? currentItem.releaseYear;

        sortedResults.sort((a, b) {
          final aIsShow = a is ShowModel ||
              (a is Map<String, dynamic> &&
                  (a['media_type'] == 'tv' || a.containsKey('first_air_date')));
          final bIsShow = b is ShowModel ||
              (b is Map<String, dynamic> &&
                  (b['media_type'] == 'tv' || b.containsKey('first_air_date')));
          if (isShow) {
            if (aIsShow && !bIsShow) return -1;
            if (!aIsShow && bIsShow) return 1;
          } else {
            if (!aIsShow && bIsShow) return -1;
            if (aIsShow && !bIsShow) return 1;
          }

          if (targetYear != null) {
            int? aYear;
            if (a is ShowModel) {
              aYear = a.firstAirDate?.year;
            } else if (a is MovieModel) {
              aYear = a.releaseDate?.year;
            } else if (a is Map<String, dynamic>) {
              final d = a['first_air_date'] ?? a['release_date'];
              if (d != null && d.toString().length >= 4) aYear = int.tryParse(d.toString().substring(0, 4));
            }

            int? bYear;
            if (b is ShowModel) {
              bYear = b.firstAirDate?.year;
            } else if (b is MovieModel) {
              bYear = b.releaseDate?.year;
            } else if (b is Map<String, dynamic>) {
              final d = b['first_air_date'] ?? b['release_date'];
              if (d != null && d.toString().length >= 4) bYear = int.tryParse(d.toString().substring(0, 4));
            }

            final aMatch = TitleSanitizer.isWithinYearTolerance(aYear, targetYear);
            final bMatch = TitleSanitizer.isWithinYearTolerance(bYear, targetYear);
            if (aMatch && !bMatch) return -1;
            if (!aMatch && bMatch) return 1;
          }

          if (cleanTarget.isNotEmpty) {
            final aTitle = (a is ShowModel
                    ? a.name
                    : (a is MovieModel ? a.title : (a is Map ? (a['name'] ?? a['title'] ?? '') : '')))
                .toString()
                .toLowerCase()
                .trim();
            final bTitle = (b is ShowModel
                    ? b.name
                    : (b is MovieModel ? b.title : (b is Map ? (b['name'] ?? b['title'] ?? '') : '')))
                .toString()
                .toLowerCase()
                .trim();
            final aExact = aTitle == cleanTarget;
            final bExact = bTitle == cleanTarget;
            if (aExact && !bExact) return -1;
            if (!aExact && bExact) return 1;
          }

          return 0;
        });
      }

      if (mounted) {
        setState(() {
          _searchResults = sortedResults;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _resolveCurrent(dynamic matchedItem) async {
    if (_isProcessing || _remainingItems.isEmpty || _currentIndex >= _remainingItems.length) return;
    final item = _remainingItems[_currentIndex];

    setState(() => _isProcessing = true);
    try {
      await _dbService.resolveUnmatchedItem(item, matchedItem);
      if (PocketBaseSyncEngine().isAuthenticated) {
        unawaited(PocketBaseSyncEngine().syncAll());
      }

      if (mounted) {
        setState(() {
          _remainingItems.removeAt(_currentIndex);
          if (_currentIndex >= _remainingItems.length && _remainingItems.isNotEmpty) {
            _currentIndex = _remainingItems.length - 1;
          }
        });

        if (_remainingItems.isEmpty) {
          widget.onCompleted?.call();
        } else {
          _initSearchForCurrentItem();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _discardCurrent() async {
    if (_isProcessing || _remainingItems.isEmpty || _currentIndex >= _remainingItems.length) return;
    final item = _remainingItems[_currentIndex];

    setState(() => _isProcessing = true);
    try {
      await _dbService.discardUnmatchedItem(item);
      if (PocketBaseSyncEngine().isAuthenticated) {
        unawaited(PocketBaseSyncEngine().syncAll());
      }

      if (mounted) {
        setState(() {
          _remainingItems.removeAt(_currentIndex);
          if (_currentIndex >= _remainingItems.length && _remainingItems.isNotEmpty) {
            _currentIndex = _remainingItems.length - 1;
          }
        });

        if (_remainingItems.isEmpty) {
          widget.onCompleted?.call();
        } else {
          _initSearchForCurrentItem();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.canvasBase,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderStroke, width: 1),
          left: BorderSide(color: AppColors.borderStroke, width: 1),
          right: BorderSide(color: AppColors.borderStroke, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStroke,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'İÇERİK EŞLEŞTİRME',
                            style: AppTypography.labelCode.copyWith(
                              color: AppColors.primaryAccent,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (_remainingItems.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / ${_remainingItems.length}',
                                style: AppTypography.labelCodeSmall.copyWith(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Otomatik eşleşmeyen TV Time içeriklerini TMDB ile bulun veya kütüphaneden atlayın.',
                        style: AppTypography.bodySmall.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.secondarySlate, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderStroke, height: 1),

          Expanded(
            child: _remainingItems.isEmpty
                ? _buildEmptyOrCompletedState()
                : _buildReconciliationBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrCompletedState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.functionalSuccess.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.functionalSuccess,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tüm İçerikler Tamamlandı!',
            style: AppTypography.headline2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            'Kütüphanenizdeki tüm yapımlar afiş ve detaylarıyla eşleştirildi.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.textOnAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text('Kütüphaneme Dön', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationBody() {
    final currentItem = _remainingItems[_currentIndex];
    final isShow = currentItem.type == UnresolvedItemType.show;
    final targetYear = TitleSanitizer.parseTitleAndYear(currentItem.rawTitle).extractedYear ?? currentItem.releaseYear;

    return Column(
      children: [
        // Current Unresolved Item Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderStroke, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isShow ? Icons.tv_rounded : Icons.movie_rounded,
                    color: AppColors.primaryAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentItem.rawTitle,
                        style: AppTypography.headline3.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isShow
                            ? '${currentItem.watchedEpisodesCount} Bölüm İzlenmiş${currentItem.seasonsInfo != null ? ' • (${currentItem.seasonsInfo})' : ''}'
                            : '${currentItem.runtimeMinutes > 0 ? '${currentItem.runtimeMinutes} dk • ' : ''}İzleme Kaydı',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondarySlate,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (targetYear != null) ...[
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primaryAccent.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Hedef: $targetYear (±1 Yıl: ${targetYear - 1} - ${targetYear + 1})',
                              style: AppTypography.labelCodeSmall.copyWith(
                                color: AppColors.primaryAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_remainingItems.length > 1) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Önceki',
                    onPressed: _currentIndex > 0
                        ? () {
                            setState(() => _currentIndex--);
                            _initSearchForCurrentItem();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Sonraki',
                    onPressed: _currentIndex < _remainingItems.length - 1
                        ? () {
                            setState(() => _currentIndex++);
                            _initSearchForCurrentItem();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Live Search Input Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: isShow
                  ? 'Dizinin gerçek adını arayın (örn. Behzat Ç., Lost)...'
                  : 'Filmin adını arayın (örn. Inception, Prestij)...',
              hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondarySlate, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.secondarySlate, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.cardSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryAccent),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Search Results List
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryAccent,
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _searchController.text.trim().isEmpty
                              ? 'Arama yaparak TMDB üzerindeki doğru yapımı seçin.'
                              : 'Sonuç bulunamadı. Lütfen farklı anahtar kelimelerle arayın.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.secondarySlate),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final res = _searchResults[index];
                        return _buildSearchResultTile(res, currentItem);
                      },
                    ),
        ),

        // Bottom Discard / Skip Action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.canvasBase,
            border: Border(top: BorderSide(color: AppColors.borderStroke, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _discardCurrent,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text(
                  'Ben de Bulamadım (Bu İçeriği Atla)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultTile(dynamic result, UnresolvedItemModel currentItem) {
    String title = '';
    String? posterPath;
    String year = '';
    String overview = '';
    bool isShow = false;

    if (result is ShowModel) {
      title = result.name;
      posterPath = result.posterPath;
      year = result.firstAirDate != null ? result.firstAirDate!.year.toString() : '';
      overview = result.overview ?? '';
      isShow = true;
    } else if (result is MovieModel) {
      title = result.title;
      posterPath = result.posterPath;
      year = result.releaseDate != null ? result.releaseDate!.year.toString() : '';
      overview = result.overview ?? '';
      isShow = false;
    } else if (result is Map<String, dynamic>) {
      title = (result['name'] ?? result['title'] ?? '').toString();
      posterPath = result['poster_path']?.toString();
      final date = (result['first_air_date'] ?? result['release_date'])?.toString();
      year = date != null && date.length >= 4 ? date.substring(0, 4) : '';
      overview = (result['overview'] ?? '').toString();
      isShow = result['media_type'] == 'tv' || result.containsKey('first_air_date');
    }

    final targetYear = TitleSanitizer.parseTitleAndYear(currentItem.rawTitle).extractedYear ?? currentItem.releaseYear;
    final candidateYear = int.tryParse(year);
    final isYearMatch = targetYear != null &&
        candidateYear != null &&
        TitleSanitizer.isWithinYearTolerance(candidateYear, targetYear);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStroke, width: 1),
      ),
      child: Row(
        children: [
          // Poster Thumbnail
          SizedBox(
            width: 44,
            height: 66,
            child: posterPath != null && posterPath.isNotEmpty
                ? CustomPosterImage(
                    path: posterPath,
                    borderRadius: 8,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isShow ? Icons.tv_rounded : Icons.movie_rounded,
                      color: AppColors.secondarySlate,
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headline3.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Text(
                      isShow ? 'Dizi' : 'Film',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondarySlate,
                        fontSize: 11,
                      ),
                    ),
                    if (year.isNotEmpty) ...[
                      const Text(
                        '•',
                        style: TextStyle(
                          color: AppColors.secondarySlate,
                          fontSize: 11,
                        ),
                      ),
                      if (isYearMatch)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.functionalSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.functionalSuccess.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '✓ $year (Hedef Yıla Uygun)',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.functionalSuccess,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Text(
                          year,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondarySlate,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ],
                ),
                if (overview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    overview,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Match Button
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _resolveCurrent(result),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.textOnAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
            child: const Text('Eşleştir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
