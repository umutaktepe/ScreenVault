import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/show_model.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/database/database_service.dart';
import '../../common/custom_poster_image.dart';
import '../episode_detail/episode_detail_screen.dart';
import 'widgets/calendar_day_strip.dart';

/// Calendar Screen with weekly timeline strip and upcoming releases
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  int _filterIndex = 0; // 0: Followed Shows, 1: All Premieres

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvasBase,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Calendar" + Month
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendar',
                        style: AppTypography.headline1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatMonthYear(_selectedDate),
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.today_rounded, color: AppColors.primaryAccent),
                    onPressed: () {
                      setState(() => _selectedDate = DateTime.now());
                    },
                  ),
                ],
              ),
            ),

            // 7-day Horizontal Day Strip
            CalendarDayStrip(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
            ),

            const SizedBox(height: 8),

            // Segmented Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderStroke, width: 1),
                ),
                child: Row(
                  children: [
                    _buildSegment(0, 'Followed Shows'),
                    _buildSegment(1, 'All Premieres'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Upcoming Episodes List
            Expanded(
              child: Builder(
                builder: (context) {
                  final db = DatabaseService();
                  final followedShows = db.getFollowedShows();
                  final followedIds = followedShows.map((s) => s.id).toSet();
                  final allEps = db.getAllEpisodes();

                  // Filter real episodes for followed shows
                  final List<Map<String, dynamic>> realUpcoming = [];
                  for (final ep in allEps) {
                    if (followedIds.contains(ep.showId) && !ep.isWatched) {
                      final show = followedShows.firstWhere((s) => s.id == ep.showId);
                      realUpcoming.add({
                        'show': show,
                        'episode': ep,
                        'airDate': ep.airDate ?? DateTime.now(),
                      });
                    }
                  }

                  realUpcoming.sort((a, b) => (a['airDate'] as DateTime).compareTo(b['airDate'] as DateTime));

                  if (realUpcoming.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceHighlight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                color: AppColors.secondarySlate,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Yaklaşan Yeni Bölüm Yok',
                              style: AppTypography.headline3.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Takip ettiğiniz dizilerin yeni bölümleri yayınlandıkça takviminizde burada listelenecektir.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: realUpcoming.length + 1, // +1 for navbar padding
                    itemBuilder: (context, index) {
                      if (index == realUpcoming.length) {
                        return const SizedBox(height: 100);
                      }
                      final item = realUpcoming[index];
                      final show = item['show'] as ShowModel;
                      final ep = item['episode'] as EpisodeModel;
                      return _buildReleaseCard(
                        showTitle: show.name,
                        episodeCode: ep.code,
                        episodeTitle: ep.name,
                        airDate: ep.airDate ?? (item['airDate'] as DateTime),
                        network: show.genres.isNotEmpty ? show.genres.first : 'TV Series',
                        posterPath: show.posterPath,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EpisodeDetailScreen(
                                show: show,
                                episode: ep,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(int index, String title) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              title,
              style: AppTypography.buttonPrimary.copyWith(
                fontSize: 12,
                color: isSelected ? AppColors.textOnAccent : AppColors.secondarySlate,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReleaseCard({
    required String showTitle,
    required String episodeCode,
    required String episodeTitle,
    required DateTime airDate,
    required String network,
    String? posterPath,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        final sampleShow = ShowModel(
          id: 99,
          name: showTitle,
          posterPath: posterPath,
          overview: 'New season premiere available soon on $network.',
        );
        final sampleEp = EpisodeModel(
          id: 99,
          showId: 99,
          seasonId: 1,
          seasonNumber: 1,
          episodeNumber: 1,
          name: episodeTitle,
          airDate: airDate,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EpisodeDetailScreen(
              show: sampleShow,
              episode: sampleEp,
            ),
          ),
        );
      },
      child: Container(
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
              width: 54,
              height: 80,
              child: CustomPosterImage(
                path: posterPath,
                borderRadius: 10,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderStroke),
                        ),
                        child: Text(
                          episodeCode,
                          style: AppTypography.labelCodeSmall.copyWith(
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.functionalSuccess.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormatter.formatRelative(airDate),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.functionalSuccess,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    showTitle,
                    style: AppTypography.headline3.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episodeTitle,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.tv_rounded, size: 12, color: AppColors.secondarySlate),
                      const SizedBox(width: 4),
                      Text(
                        network,
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
