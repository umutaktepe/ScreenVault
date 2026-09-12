import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ShowSortOption {
  recentlyActive('En Son İzlenen'),
  nameAsc('İsim (A-Z)'),
  nameDesc('İsim (Z-A)'),
  ratingDesc('TMDB Puanı'),
  yearDesc('Yıl (Yeni - Eski)'),
  yearAsc('Yıl (Eski - Yeni)'),
  progressDesc('İlerleme Durumu (%)');

  final String label;
  const ShowSortOption(this.label);
}

class MyShowsFilterResult {
  final ShowSortOption sortOption;
  final Set<String> genres;
  final int? year;

  const MyShowsFilterResult({
    required this.sortOption,
    required this.genres,
    this.year,
  });

  bool get isCustomized =>
      sortOption != ShowSortOption.recentlyActive ||
      genres.isNotEmpty ||
      year != null;
}

class MyShowsFilterSheet extends StatefulWidget {
  final List<String> availableGenres;
  final List<int> availableYears;
  final ShowSortOption currentSort;
  final Set<String> currentGenres;
  final int? currentYear;

  const MyShowsFilterSheet({
    super.key,
    required this.availableGenres,
    required this.availableYears,
    required this.currentSort,
    required this.currentGenres,
    this.currentYear,
  });

  @override
  State<MyShowsFilterSheet> createState() => _MyShowsFilterSheetState();
}

class _MyShowsFilterSheetState extends State<MyShowsFilterSheet> {
  late ShowSortOption _selectedSort;
  late Set<String> _selectedGenres;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.currentSort;
    _selectedGenres = Set<String>.from(widget.currentGenres);
    _selectedYear = widget.currentYear;
  }

  void _resetFilters() {
    setState(() {
      _selectedSort = ShowSortOption.recentlyActive;
      _selectedGenres.clear();
      _selectedYear = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtrele ve Sırala',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text(
                        'Sıfırla',
                        style: TextStyle(
                          color: AppColors.primaryAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.borderStroke),

              // Sort Section
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text(
                  'Sıralama Ölçütü',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ShowSortOption.values.map((option) {
                    final isSelected = _selectedSort == option;
                    return ChoiceChip(
                      label: Text(
                        option.label,
                        style: TextStyle(
                          color: isSelected ? AppColors.textOnAccent : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryAccent,
                      backgroundColor: AppColors.surfaceHighlight,
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedSort = option);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),

              // Genres Section
              if (widget.availableGenres.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Türler',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableGenres.map((genre) {
                      final isSelected = _selectedGenres.contains(genre);
                      return FilterChip(
                        label: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.secondarySlate,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.surfaceElevated,
                        backgroundColor: AppColors.surfaceHighlight,
                        checkmarkColor: AppColors.primaryAccent,
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenres.add(genre);
                            } else {
                              _selectedGenres.remove(genre);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Years Section
              if (widget.availableYears.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Çıkış Yılı',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tüm Yıllar', style: TextStyle(fontSize: 12)),
                        selected: _selectedYear == null,
                        selectedColor: AppColors.primaryAccent,
                        backgroundColor: AppColors.surfaceHighlight,
                        side: BorderSide(
                          color: _selectedYear == null ? AppColors.primaryAccent : AppColors.borderStroke,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _selectedYear = null),
                      ),
                      ...widget.availableYears.take(12).map((year) {
                        final isSelected = _selectedYear == year;
                        return ChoiceChip(
                          label: Text(
                            '$year',
                            style: TextStyle(
                              color: isSelected ? AppColors.textOnAccent : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryAccent,
                          backgroundColor: AppColors.surfaceHighlight,
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
                          ),
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              _selectedYear = selected ? year : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Apply Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: AppColors.textOnAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(
                        MyShowsFilterResult(
                          sortOption: _selectedSort,
                          genres: _selectedGenres,
                          year: _selectedYear,
                        ),
                      );
                    },
                    child: const Text(
                      'Uygula',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
