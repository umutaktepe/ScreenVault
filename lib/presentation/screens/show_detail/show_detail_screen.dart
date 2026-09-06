import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/show_model.dart';
import '../../../data/models/season_model.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/database/database_service.dart';
import '../../common/custom_poster_image.dart';
import '../../common/checkmark_toggle_button.dart';
import '../episode_detail/episode_detail_screen.dart';

/// Show Detail Screen allowing users to browse seasons, select any episode,
/// and track series watching progress matching Stitch Obsidian specification.
class ShowDetailScreen extends StatefulWidget {
  final ShowModel show;

  const ShowDetailScreen({
    super.key,
    required this.show,
  });

  @override
  State<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends State<ShowDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  late ShowModel _currentShow;
  late List<SeasonModel> _seasons;
  int _selectedSeasonNumber = 1;
  List<EpisodeModel> _episodes = [];
  bool _isLoadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _currentShow = widget.show;
    _loadShowAndSeasons();
  }

  void _loadShowAndSeasons() {
    final updatedShow = _dbService.getShowById(_currentShow.id) ?? _currentShow;
    _currentShow = updatedShow;
    _seasons = _dbService.getSeasonsForShow(_currentShow.id);
    if (_seasons.isNotEmpty) {
      // Pick first season or current selected
      if (!_seasons.any((s) => s.seasonNumber == _selectedSeasonNumber)) {
        _selectedSeasonNumber = _seasons.first.seasonNumber;
      }
    }
    _loadEpisodesForSelectedSeason();

    _dbService.fetchOrLoadSeasons(_currentShow).then((fresh) {
      if (mounted && fresh.length != _seasons.length) {
        setState(() {
          _seasons = fresh;
        });
      }
    });
  }

  Future<void> _loadEpisodesForSelectedSeason() async {
    final local = _dbService.getEpisodesForShowAndSeason(_currentShow.id, _selectedSeasonNumber);
    setState(() {
      _episodes = local;
      _isLoadingEpisodes = local.isEmpty;
    });
    final episodes = await _dbService.fetchOrLoadSeasonEpisodes(
      _currentShow,
      _selectedSeasonNumber,
    );
    final updatedShow = _dbService.getShowById(_currentShow.id) ?? _currentShow;
    if (mounted) {
      setState(() {
        _currentShow = updatedShow;
        _episodes = episodes;
        _isLoadingEpisodes = false;
      });
    }
  }

  void _toggleFollowed() async {
    HapticFeedback.lightImpact();
    await _dbService.toggleShowFollowed(_currentShow.id);
    final updated = _dbService.getShowById(_currentShow.id);
    if (updated != null && mounted) {
      setState(() => _currentShow = updated);
    }
  }

  void _toggleEpisode(EpisodeModel ep, bool watched) async {
    await _dbService.markEpisodeWatched(
      ep.id,
      watched: watched,
      showId: _currentShow.id,
      seasonNumber: ep.seasonNumber,
      episodeNumber: ep.episodeNumber,
    );
    final updatedShow = _dbService.getShowById(_currentShow.id);
    final updatedEpisodes = _dbService.getEpisodesForShowAndSeason(_currentShow.id, _selectedSeasonNumber);
    if (mounted) {
      setState(() {
        if (updatedShow != null) _currentShow = updatedShow;
        _episodes = updatedEpisodes;
      });
    }
  }

  void _markAllSeasonWatched(bool watched) async {
    HapticFeedback.mediumImpact();
    await _dbService.markSeasonWatched(_currentShow.id, _selectedSeasonNumber, watched: watched);
    final updatedShow = _dbService.getShowById(_currentShow.id);
    final updatedEpisodes = _dbService.getEpisodesForShowAndSeason(_currentShow.id, _selectedSeasonNumber);
    if (mounted) {
      setState(() {
        if (updatedShow != null) _currentShow = updatedShow;
        _episodes = updatedEpisodes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceHighlight,
          duration: const Duration(seconds: 2),
          content: Text(
            watched
                ? '$_selectedSeasonNumber. Sezondaki tüm bölümler izlendi olarak işaretlendi.'
                : '$_selectedSeasonNumber. Sezon izlenmedi olarak işaretlendi.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = _currentShow;
    final totalEpisodes = show.totalEpisodes > 0 ? show.totalEpisodes : 1;
    final progressPercent = (show.watchedEpisodesCount / totalEpisodes).clamp(0.0, 1.0);
    final seasonWatchedCount = _episodes.where((e) =>
        e.isWatched ||
        _dbService.isEpisodeWatchedInHistory(
          showId: _currentShow.id,
          tvdbId: _currentShow.tvdbId,
          seasonNumber: e.seasonNumber,
          episodeNumber: e.episodeNumber,
          episodeId: e.id,
        )).length;
    final allSeasonWatched = _episodes.isNotEmpty && seasonWatchedCount == _episodes.length;

    return Scaffold(
      backgroundColor: AppColors.canvasBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Hero Backdrop Header with Scrim and Actions
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
                  onTap: _toggleFollowed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: show.isFollowed
                          ? AppColors.primaryAccent
                          : Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: show.isFollowed
                            ? AppColors.primaryAccent
                            : AppColors.borderStroke,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          show.isFollowed ? Icons.check_rounded : Icons.bookmark_add_outlined,
                          size: 16,
                          color: show.isFollowed ? AppColors.textOnAccent : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          show.isFollowed ? 'Takipte' : 'Takip Et',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: show.isFollowed ? AppColors.textOnAccent : Colors.white,
                          ),
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
                    path: show.backdropPath,
                    fallbackPath: show.posterPath,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                    size: 'w780',
                  ),
                  // Gradient Overlay
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

          // 2. Show Metadata Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vertical Show Poster
                      CustomPosterImage(
                        path: show.posterPath,
                        width: 96,
                        height: 144,
                        borderRadius: 12,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              show.name,
                              style: AppTypography.headline2.copyWith(fontSize: 22),
                            ),
                            if (show.firstAirDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${show.firstAirDate!.year} • ${show.totalSeasons} Sezon',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.secondarySlate,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Badges (Rating + Status)
                            Row(
                              children: [
                                if (show.voteAverage > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.borderStroke),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: AppColors.primaryAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          show.voteAverage.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (show.status != null && show.status!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.functionalSuccess.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.functionalSuccess.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      show.status == 'Ended' ? 'Tamamlandı' : 'Devam Ediyor',
                                      style: const TextStyle(
                                        color: AppColors.functionalSuccess,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Genres
                            if (show.genres.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: show.genres.take(3).map((g) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      g,
                                      style: const TextStyle(
                                        color: AppColors.secondarySlate,
                                        fontSize: 10,
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

                  // Overview
                  if (show.overview != null && show.overview!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      show.overview!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.secondarySlate,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Progress Bar Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'İzleme Durumu',
                              style: AppTypography.headline3.copyWith(fontSize: 13),
                            ),
                            Text(
                              '${show.watchedEpisodesCount} / ${show.totalEpisodes} Bölüm (%${(progressPercent * 100).toInt()})',
                              style: const TextStyle(
                                color: AppColors.functionalSuccess,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceHighlight,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.functionalSuccess),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Season Selection Header + Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SEZONLAR',
                        style: AppTypography.headline3.copyWith(fontSize: 15),
                      ),
                      if (_episodes.isNotEmpty)
                        GestureDetector(
                          onTap: () => _markAllSeasonWatched(!allSeasonWatched),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                  allSeasonWatched
                                      ? 'Sezon İzlendi ($seasonWatchedCount/${_episodes.length})'
                                      : 'Tüm Sezonu İzlendi Yap ($seasonWatchedCount/${_episodes.length})',
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

                  const SizedBox(height: 10),

                  // Horizontal Season Tabs / Pills
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _seasons.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final season = _seasons[index];
                        final isSelected = season.seasonNumber == _selectedSeasonNumber;
                        return GestureDetector(
                          onTap: () {
                            if (!isSelected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedSeasonNumber = season.seasonNumber;
                              });
                              _loadEpisodesForSelectedSeason();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryAccent : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                season.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.textOnAccent : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 3. Episodes List for Selected Season
          if (_isLoadingEpisodes)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                    ),
                  ),
                ),
              ),
            )
          else if (_episodes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Bu sezon için bölüm bulunamadı.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.secondarySlate),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ep = _episodes[index];
                    return _buildEpisodeTile(ep);
                  },
                  childCount: _episodes.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(EpisodeModel ep) {
    final bool isWatched = ep.isWatched ||
        _dbService.isEpisodeWatchedInHistory(
          showId: _currentShow.id,
          tvdbId: _currentShow.tvdbId,
          seasonNumber: ep.seasonNumber,
          episodeNumber: ep.episodeNumber,
          episodeId: ep.id,
        );
    final latestRecord = isWatched
        ? _dbService.getLatestWatchRecord(
            showId: _currentShow.id,
            tvdbId: _currentShow.tvdbId,
            seasonNumber: ep.seasonNumber,
            episodeNumber: ep.episodeNumber,
            episodeId: ep.id,
          )
        : null;
    final resolvedEp = ep.copyWith(
      isWatched: isWatched,
      rewatchCount: (latestRecord != null && latestRecord.rewatchCount > 0)
          ? latestRecord.rewatchCount
          : (ep.rewatchCount > 0 ? ep.rewatchCount : (isWatched ? 1 : 0)),
      lastWatchedAt: latestRecord?.watchedAt ?? ep.lastWatchedAt,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWatched
              ? AppColors.functionalSuccess.withValues(alpha: 0.3)
              : AppColors.borderStroke,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EpisodeDetailScreen(
                  show: _currentShow,
                  episode: resolvedEp,
                ),
              ),
            ).then((_) {
              _loadShowAndSeasons();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // 16:9 Thumbnail
                Stack(
                  children: [
                    CustomPosterImage(
                      path: ep.stillPath,
                      fallbackPath: _currentShow.posterPath,
                      width: 100,
                      height: 60,
                      borderRadius: 8,
                      fit: BoxFit.cover,
                      size: 'w300',
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ep.code,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                    ),
                    if (isWatched)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.functionalSuccess,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Episode Title, Runtime, Air Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ep.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isWatched ? AppColors.secondarySlate : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isWatched) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.functionalSuccess.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.functionalSuccess.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, size: 10, color: AppColors.functionalSuccess),
                                  SizedBox(width: 3),
                                  Text(
                                    'İZLENDİ',
                                    style: TextStyle(
                                      color: AppColors.functionalSuccess,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (ep.runtimeMinutes > 0) ...[
                            Text(
                              '${ep.runtimeMinutes} dk',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondarySlate,
                              ),
                            ),
                            const Text(' • ', style: TextStyle(color: AppColors.secondarySlate)),
                          ],
                          if (ep.airDate != null)
                            Text(
                              DateFormatter.formatAirDate(ep.airDate),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondarySlate,
                              ),
                            ),
                        ],
                      ),
                      if (ep.overview != null && ep.overview!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ep.overview!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondarySlate.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Checkmark Toggle Button
                CheckmarkToggleButton(
                  isWatched: isWatched,
                  size: 34,
                  onToggle: (val) => _toggleEpisode(resolvedEp, val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
