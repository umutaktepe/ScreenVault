import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/show_model.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/models/season_model.dart';
import '../../../data/database/database_service.dart';
import '../../common/custom_poster_image.dart';
import '../../common/emotion_meter.dart';
import 'widgets/character_mvp_picker.dart';
import 'widgets/spoiler_comments_list.dart';

/// Ultra-efficient In-Page Episode & Season Detail Screen
/// Inspired by WeTrakr & Stitch Obsidian Cinema & TV Tracker:
/// - Pinned top app bar with perfectly aligned back button & show title
/// - Horizontal WeTrakr-style Episode Rail (< [S1·E35] [S1·E36] [S1·E37] >)
/// - In-place episode switching without navigating away to any separate page
/// - Interactive Modal Bottom Sheet for instant multi-season episode jumping
class EpisodeDetailScreen extends StatefulWidget {
  final ShowModel show;
  final EpisodeModel episode;

  const EpisodeDetailScreen({
    super.key,
    required this.show,
    required this.episode,
  });

  @override
  State<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ScrollController _railScrollController = ScrollController();

  late EpisodeModel _currentEpisode;
  late int _currentSeasonNumber;
  late bool _isWatched;
  late int _rewatchCount;

  List<SeasonModel> _seasons = [];
  List<EpisodeModel> _episodes = [];
  bool _isLoadingEpisodes = false;
  StreamSubscription? _dbSub;

  @override
  void initState() {
    super.initState();
    final watchedInHistory = _dbService.isEpisodeWatchedInHistory(
      showId: widget.show.id,
      tvdbId: widget.show.tvdbId,
      seasonNumber: widget.episode.seasonNumber,
      episodeNumber: widget.episode.episodeNumber,
      episodeId: widget.episode.id,
    );
    _isWatched = widget.episode.isWatched || watchedInHistory;
    final latest = watchedInHistory
        ? _dbService.getLatestWatchRecord(
            showId: widget.show.id,
            tvdbId: widget.show.tvdbId,
            seasonNumber: widget.episode.seasonNumber,
            episodeNumber: widget.episode.episodeNumber,
            episodeId: widget.episode.id,
          )
        : null;
    _rewatchCount = (latest != null && latest.rewatchCount > 0)
        ? latest.rewatchCount
        : (widget.episode.rewatchCount > 0 ? widget.episode.rewatchCount : (_isWatched ? 1 : 0));
    _currentEpisode = widget.episode.copyWith(
      isWatched: _isWatched,
      rewatchCount: _rewatchCount,
      lastWatchedAt: latest?.watchedAt ?? widget.episode.lastWatchedAt,
    );
    _currentSeasonNumber = widget.episode.seasonNumber;

    _seasons = _dbService.getSeasonsForShow(widget.show.id);
    _loadEpisodesForSeason(_currentSeasonNumber);

    _dbService.fetchOrLoadSeasons(widget.show).then((fresh) {
      if (mounted && fresh.length != _seasons.length) {
        setState(() {
          _seasons = fresh;
        });
      }
    });

    _dbSub = _dbService.showsStream.listen((_) {
      if (mounted) {
        final watchedInHistory = _dbService.isEpisodeWatchedInHistory(
          showId: widget.show.id,
          tvdbId: widget.show.tvdbId,
          seasonNumber: _currentEpisode.seasonNumber,
          episodeNumber: _currentEpisode.episodeNumber,
          episodeId: _currentEpisode.id,
        );
        final freshEp = _dbService.getEpisodeById(_currentEpisode.id);
        final isW = (freshEp?.isWatched ?? false) || watchedInHistory;
        final latest = watchedInHistory
            ? _dbService.getLatestWatchRecord(
                showId: widget.show.id,
                tvdbId: widget.show.tvdbId,
                seasonNumber: _currentEpisode.seasonNumber,
                episodeNumber: _currentEpisode.episodeNumber,
                episodeId: _currentEpisode.id,
              )
            : null;
        final rewatch = (latest != null && latest.rewatchCount > 0)
            ? latest.rewatchCount
            : ((freshEp?.rewatchCount ?? 0) > 0 ? freshEp!.rewatchCount : (isW ? 1 : 0));
        setState(() {
          _isWatched = isW;
          _rewatchCount = rewatch;
          _currentEpisode = _currentEpisode.copyWith(
            isWatched: isW,
            rewatchCount: rewatch,
            lastWatchedAt: latest?.watchedAt ?? freshEp?.lastWatchedAt ?? _currentEpisode.lastWatchedAt,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _dbSub?.cancel();
    _railScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodesForSeason(int seasonNum) async {
    final local = _dbService.getEpisodesForShowAndSeason(widget.show.id, seasonNum);
    setState(() {
      _currentSeasonNumber = seasonNum;
      _episodes = local;
      _isLoadingEpisodes = local.isEmpty;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerActiveEpisodeInRail();
    });

    final fresh = await _dbService.fetchOrLoadSeasonEpisodes(widget.show, seasonNum);
    if (mounted && fresh.isNotEmpty) {
      setState(() {
        _episodes = fresh;
        _isLoadingEpisodes = false;
        final matching = fresh.where((e) => e.episodeNumber == _currentEpisode.episodeNumber);
        if (matching.isNotEmpty && _currentEpisode.seasonNumber == seasonNum) {
          final matchedEp = matching.first;
          final watchedInHistory = _dbService.isEpisodeWatchedInHistory(
            showId: widget.show.id,
            tvdbId: widget.show.tvdbId,
            seasonNumber: matchedEp.seasonNumber,
            episodeNumber: matchedEp.episodeNumber,
            episodeId: matchedEp.id,
          );
          final resolvedWatched = matchedEp.isWatched || _isWatched || watchedInHistory;
          _currentEpisode = matchedEp.copyWith(isWatched: resolvedWatched);
          _isWatched = resolvedWatched;
          _rewatchCount = matchedEp.rewatchCount > 0
              ? matchedEp.rewatchCount
              : (_rewatchCount > 0 ? _rewatchCount : (resolvedWatched ? 1 : 0));
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerActiveEpisodeInRail();
      });
    } else if (mounted) {
      setState(() {
        _isLoadingEpisodes = false;
      });
    }
  }

  void _centerActiveEpisodeInRail() {
    if (!_railScrollController.hasClients || _episodes.isEmpty) return;
    final idx = _episodes.indexWhere((e) => e.episodeNumber == _currentEpisode.episodeNumber);
    if (idx >= 0) {
      const itemWidth = 86.0;
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = (idx * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      final clamped = targetOffset.clamp(
        0.0,
        _railScrollController.position.maxScrollExtent,
      );
      _railScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToEpisode(EpisodeModel ep) {
    HapticFeedback.selectionClick();
    final watchedInHistory = _dbService.isEpisodeWatchedInHistory(
      showId: widget.show.id,
      tvdbId: widget.show.tvdbId,
      seasonNumber: ep.seasonNumber,
      episodeNumber: ep.episodeNumber,
      episodeId: ep.id,
    );
    final isWatched = ep.isWatched || watchedInHistory;
    final latest = watchedInHistory
        ? _dbService.getLatestWatchRecord(
            showId: widget.show.id,
            tvdbId: widget.show.tvdbId,
            seasonNumber: ep.seasonNumber,
            episodeNumber: ep.episodeNumber,
            episodeId: ep.id,
          )
        : null;
    final rewatch = (latest != null && latest.rewatchCount > 0)
        ? latest.rewatchCount
        : (ep.rewatchCount > 0 ? ep.rewatchCount : (isWatched ? 1 : 0));
    final resolvedEp = ep.copyWith(
      isWatched: isWatched,
      rewatchCount: rewatch,
      lastWatchedAt: latest?.watchedAt ?? ep.lastWatchedAt,
    );

    setState(() {
      _currentEpisode = resolvedEp;
      _currentSeasonNumber = resolvedEp.seasonNumber;
      _isWatched = isWatched;
      _rewatchCount = rewatch;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerActiveEpisodeInRail();
    });
  }

  void _goToPreviousEpisode() {
    final idx = _episodes.indexWhere((e) => e.episodeNumber == _currentEpisode.episodeNumber);
    if (idx > 0) {
      _goToEpisode(_episodes[idx - 1]);
    } else if (_currentSeasonNumber > 1) {
      final prevSeason = _currentSeasonNumber - 1;
      final prevEps = _dbService.getEpisodesForShowAndSeason(widget.show.id, prevSeason);
      if (prevEps.isNotEmpty) {
        setState(() {
          _currentSeasonNumber = prevSeason;
          _episodes = prevEps;
        });
        _goToEpisode(prevEps.last);
      } else {
        _loadEpisodesForSeason(prevSeason);
      }
    }
  }

  void _goToNextEpisode() {
    final idx = _episodes.indexWhere((e) => e.episodeNumber == _currentEpisode.episodeNumber);
    if (idx >= 0 && idx < _episodes.length - 1) {
      _goToEpisode(_episodes[idx + 1]);
    } else {
      final nextSeason = _currentSeasonNumber + 1;
      final seasons = _dbService.getSeasonsForShow(widget.show.id);
      if (seasons.any((s) => s.seasonNumber == nextSeason)) {
        final nextEps = _dbService.getEpisodesForShowAndSeason(widget.show.id, nextSeason);
        if (nextEps.isNotEmpty) {
          setState(() {
            _currentSeasonNumber = nextSeason;
            _episodes = nextEps;
          });
          _goToEpisode(nextEps.first);
        } else {
          _loadEpisodesForSeason(nextSeason);
        }
      }
    }
  }

  void _toggleWatched() async {
    HapticFeedback.mediumImpact();
    final newWatched = !_isWatched;
    final newRewatch = (newWatched && _rewatchCount == 0) ? 1 : (newWatched ? _rewatchCount : 0);
    setState(() {
      _isWatched = newWatched;
      _rewatchCount = newRewatch;
      _currentEpisode = _currentEpisode.copyWith(
        isWatched: newWatched,
        rewatchCount: newRewatch,
      );
      final idx = _episodes.indexWhere((e) =>
          e.id == _currentEpisode.id ||
          (e.seasonNumber == _currentEpisode.seasonNumber && e.episodeNumber == _currentEpisode.episodeNumber));
      if (idx >= 0) {
        _episodes[idx] = _episodes[idx].copyWith(
          isWatched: newWatched,
          rewatchCount: newRewatch,
        );
      }
    });
    await _dbService.markEpisodeWatched(
      _currentEpisode.id,
      watched: newWatched,
      showId: widget.show.id,
      seasonNumber: _currentEpisode.seasonNumber,
      episodeNumber: _currentEpisode.episodeNumber,
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _incrementRewatch() async {
    HapticFeedback.lightImpact();
    final newRewatch = _rewatchCount + 1;
    setState(() {
      _isWatched = true;
      _rewatchCount = newRewatch;
      _currentEpisode = _currentEpisode.copyWith(
        isWatched: true,
        rewatchCount: newRewatch,
      );
      final idx = _episodes.indexWhere((e) =>
          e.id == _currentEpisode.id ||
          (e.seasonNumber == _currentEpisode.seasonNumber && e.episodeNumber == _currentEpisode.episodeNumber));
      if (idx >= 0) {
        _episodes[idx] = _episodes[idx].copyWith(
          isWatched: true,
          rewatchCount: newRewatch,
        );
      }
    });
    await _dbService.markEpisodeWatched(
      _currentEpisode.id,
      watched: true,
      showId: widget.show.id,
      seasonNumber: _currentEpisode.seasonNumber,
      episodeNumber: _currentEpisode.episodeNumber,
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _showSeasonPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        int sheetSeason = _currentSeasonNumber;
        List<EpisodeModel> sheetEpisodes = _dbService.getEpisodesForShowAndSeason(widget.show.id, sheetSeason);

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final allSeasonWatched = sheetEpisodes.isNotEmpty && sheetEpisodes.every((e) => e.isWatched);

            return DraggableScrollableSheet(
              initialChildSize: 0.68,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.secondarySlate.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bölüm ve Sezon Seç',
                                style: AppTypography.headline3.copyWith(fontSize: 17),
                              ),
                              Text(
                                widget.show.name,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              await _dbService.markSeasonWatched(
                                widget.show.id,
                                sheetSeason,
                                watched: !allSeasonWatched,
                              );
                              setSheetState(() {
                                sheetEpisodes = _dbService.getEpisodesForShowAndSeason(widget.show.id, sheetSeason);
                              });
                              if (mounted) {
                                setState(() {
                                  _episodes = _dbService.getEpisodesForShowAndSeason(widget.show.id, _currentSeasonNumber);
                                  final fresh = _episodes.where((e) => e.id == _currentEpisode.id);
                                  if (fresh.isNotEmpty) {
                                    _isWatched = fresh.first.isWatched;
                                    _currentEpisode = fresh.first;
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: allSeasonWatched
                                    ? AppColors.functionalSuccess.withValues(alpha: 0.15)
                                    : AppColors.surfaceHighlight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: allSeasonWatched
                                      ? AppColors.functionalSuccess.withValues(alpha: 0.4)
                                      : AppColors.borderStroke,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    allSeasonWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: allSeasonWatched ? AppColors.functionalSuccess : AppColors.secondarySlate,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    allSeasonWatched ? 'Sezon İzlendi' : 'Sezonu Tamamla',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: allSeasonWatched ? AppColors.functionalSuccess : AppColors.secondarySlate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Season Chips in Bottom Sheet
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _seasons.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final season = _seasons[idx];
                          final isSelected = season.seasonNumber == sheetSeason;
                          return GestureDetector(
                            onTap: () async {
                              setSheetState(() {
                                sheetSeason = season.seasonNumber;
                                sheetEpisodes = _dbService.getEpisodesForShowAndSeason(widget.show.id, sheetSeason);
                              });
                              if (sheetEpisodes.isEmpty) {
                                final fresh = await _dbService.fetchOrLoadSeasonEpisodes(widget.show, sheetSeason);
                                if (mounted) {
                                  setSheetState(() {
                                    sheetEpisodes = fresh;
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryAccent : AppColors.surfaceHighlight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  season.name,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.textOnAccent : Colors.white,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(color: AppColors.borderSubtle, height: 1),

                    // Episodes List
                    Expanded(
                      child: sheetEpisodes.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: sheetEpisodes.length,
                              separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
                              itemBuilder: (context, i) {
                                final ep = sheetEpisodes[i];
                                final isCurrent = ep.id == _currentEpisode.id;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  leading: Container(
                                    width: 44,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? AppColors.primaryAccent
                                          : (ep.isWatched
                                              ? AppColors.functionalSuccess.withValues(alpha: 0.2)
                                              : AppColors.surfaceHighlight),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.primaryAccent
                                            : (ep.isWatched
                                                ? AppColors.functionalSuccess.withValues(alpha: 0.5)
                                                : AppColors.borderStroke),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'E${ep.episodeNumber}',
                                        style: TextStyle(
                                          color: isCurrent
                                              ? AppColors.textOnAccent
                                              : (ep.isWatched ? AppColors.functionalSuccess : Colors.white),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    ep.name,
                                    style: TextStyle(
                                      color: isCurrent ? AppColors.primaryAccent : Colors.white,
                                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${ep.runtimeMinutes > 0 ? ep.runtimeMinutes : 50} dk • ${DateFormatter.formatAirDate(ep.airDate)}',
                                    style: AppTypography.bodySmall,
                                  ),
                                  trailing: ep.isWatched
                                      ? const Icon(Icons.check_circle_rounded, color: AppColors.functionalSuccess, size: 20)
                                      : const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.secondarySlate, size: 20),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (_currentSeasonNumber != sheetSeason) {
                                      _loadEpisodesForSeason(sheetSeason).then((_) {
                                        _goToEpisode(ep);
                                      });
                                    } else {
                                      _goToEpisode(ep);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ep = _currentEpisode;
    final show = widget.show;

    final currentIdx = _episodes.indexWhere((e) => e.episodeNumber == ep.episodeNumber);
    final bool canGoPrev = currentIdx > 0 || _currentSeasonNumber > 1;
    final bool canGoNext = (currentIdx >= 0 && currentIdx < _episodes.length - 1) ||
        _seasons.any((s) => s.seasonNumber > _currentSeasonNumber);

    return Scaffold(
      backgroundColor: AppColors.canvasBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Pinned Top Bar (Back button, Show Name, Season Picker Pill)
            _buildTopBar(),

            // 2. WeTrakr Horizontal Episode Rail (< [S1·E35] [S1·E36] [S1·E37] >)
            _buildWeTrakrRail(canGoPrev, canGoNext),

            // 3. Scrollable Episode Details Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // 16:9 Thumbnail Image with Badges
                    _buildThumbnailHero(ep, show),

                    const SizedBox(height: 14),

                    // Title & Metadata
                    _buildTitleAndMetadata(ep, show),

                    const SizedBox(height: 14),

                    // Overview
                    if (ep.overview != null && ep.overview!.isNotEmpty) ...[
                      Text(
                        ep.overview!,
                        style: AppTypography.bodyLarge.copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Watched Action Button
                    _buildWatchedButton(),

                    const SizedBox(height: 24),

                    // 5-Emotion Meter
                    const EmotionMeter(),

                    const SizedBox(height: 24),

                    // MVP Character Picker
                    CharacterMvpPicker(
                      onVoted: (name) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceHighlight,
                            content: Text('MVP oyunuz $name için kaydedildi!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Spoiler Comments
                    SpoilerCommentsList(
                      showId: widget.show.id,
                      seasonNumber: _currentSeasonNumber,
                      episodeNumber: _currentEpisode.episodeNumber,
                      episodeCode: 'S${_currentSeasonNumber.toString().padLeft(2, '0')}E${_currentEpisode.episodeNumber.toString().padLeft(2, '0')}',
                      showTitle: widget.show.name,
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.canvasBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Perfectly Aligned Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Show Title in Center
          Expanded(
            child: Text(
              widget.show.name,
              style: AppTypography.headline3.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Season Dropdown Pill (Opens Bottom Sheet, Never redirects)
          GestureDetector(
            onTap: _showSeasonPickerSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_currentSeasonNumber. Sezon',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.primaryAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeTrakrRail(bool canGoPrev, bool canGoNext) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderStroke, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Previous Episode Arrow <
          GestureDetector(
            onTap: canGoPrev ? _goToPreviousEpisode : null,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: canGoPrev ? AppColors.surfaceHighlight : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canGoPrev ? AppColors.borderStroke : AppColors.borderSubtle,
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: canGoPrev ? Colors.white : AppColors.secondarySlate.withValues(alpha: 0.3),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Horizontal Episode Carousel Rail
          Expanded(
            child: _isLoadingEpisodes
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _railScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _episodes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final ep = _episodes[index];
                      final isSelected = ep.id == _currentEpisode.id ||
                          (ep.seasonNumber == _currentEpisode.seasonNumber &&
                              ep.episodeNumber == _currentEpisode.episodeNumber);

                          final isEpWatched = isSelected
                              ? _isWatched
                              : (ep.isWatched ||
                                  _dbService.isEpisodeWatchedInHistory(
                                    showId: widget.show.id,
                                    tvdbId: widget.show.tvdbId,
                                    seasonNumber: ep.seasonNumber,
                                    episodeNumber: ep.episodeNumber,
                                    episodeId: ep.id,
                                  ));

                          return GestureDetector(
                            onTap: () => _goToEpisode(ep),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryAccent.withValues(alpha: 0.15)
                                    : AppColors.surfaceHighlight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryAccent.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isEpWatched) ...[
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: AppColors.functionalSuccess,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    'S${ep.seasonNumber} · E${ep.episodeNumber}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primaryAccent
                                          : (isEpWatched ? AppColors.slateLight : AppColors.secondarySlate),
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                    },
                  ),
          ),
          const SizedBox(width: 6),

          // Next Episode Arrow >
          GestureDetector(
            onTap: canGoNext ? _goToNextEpisode : null,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: canGoNext ? AppColors.surfaceHighlight : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canGoNext ? AppColors.borderStroke : AppColors.borderSubtle,
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: canGoNext ? Colors.white : AppColors.secondarySlate.withValues(alpha: 0.3),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailHero(EpisodeModel ep, ShowModel show) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPosterImage(
                path: ep.stillPath ?? show.backdropPath,
                fallbackPath: show.posterPath,
                fit: BoxFit.cover,
                borderRadius: 0,
                size: 'w780',
              ),

              // Gradient Scrim
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Top Badges
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  children: [
                    if (ep.episodeNumber == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SEASON PREMIERE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      )
                    else if (_episodes.isNotEmpty && ep.episodeNumber == _episodes.length && _episodes.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SEASON FINALE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Right Watched Tag
              if (_isWatched)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.functionalSuccess,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'İZLENDİ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAndMetadata(EpisodeModel ep, ShowModel show) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show Name & Season Code
        Text(
          '${show.name.toUpperCase()} · ${ep.seasonNumber}. SEZON',
          style: AppTypography.labelCodeSmall.copyWith(
            color: AppColors.primaryAccent,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),

        // Episode Title
        Text(
          ep.name,
          style: AppTypography.headline1.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),

        // Runtime, Air Date, Rating Badges
        Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 14, color: AppColors.secondarySlate),
            const SizedBox(width: 4),
            Text(
              '${ep.runtimeMinutes > 0 ? ep.runtimeMinutes : 54} dakika',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(width: 12),
            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.secondarySlate),
            const SizedBox(width: 4),
            Text(
              DateFormatter.formatAirDate(ep.airDate),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 13, color: AppColors.primaryAccent),
                  const SizedBox(width: 3),
                  Text(
                    ep.voteAverage > 0
                        ? ep.voteAverage.toStringAsFixed(1)
                        : (show.voteAverage > 0 ? show.voteAverage.toStringAsFixed(1) : '8.5'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWatchedButton() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _toggleWatched,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isWatched ? AppColors.functionalSuccess : AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_isWatched ? AppColors.functionalSuccess : AppColors.primaryAccent)
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isWatched ? Icons.check_circle_rounded : Icons.check_rounded,
                    color: _isWatched ? Colors.white : AppColors.textOnAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isWatched ? 'I\'VE WATCHED THIS' : 'MARK AS WATCHED',
                    style: AppTypography.buttonPrimary.copyWith(
                      color: _isWatched ? Colors.white : AppColors.textOnAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isWatched) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _incrementRewatch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderStroke, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.replay_rounded, color: AppColors.primaryAccent, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '+${_rewatchCount}x',
                    style: AppTypography.buttonPrimary.copyWith(
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
