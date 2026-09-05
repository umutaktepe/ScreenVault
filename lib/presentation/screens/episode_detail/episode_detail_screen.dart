import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/show_model.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/database/database_service.dart';
import '../../common/custom_poster_image.dart';
import '../../common/emotion_meter.dart';
import 'widgets/character_mvp_picker.dart';
import 'widgets/spoiler_comments_list.dart';

/// Episode Detail Screen matching Stitch Obsidian Cinema & TV Tracker specification
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
  late bool _isWatched;
  late int _rewatchCount;

  @override
  void initState() {
    super.initState();
    _isWatched = widget.episode.isWatched;
    _rewatchCount = widget.episode.rewatchCount;
  }

  void _toggleWatched() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isWatched = !_isWatched;
      if (_isWatched && _rewatchCount == 0) {
        _rewatchCount = 1;
      }
    });
    _dbService.markEpisodeWatched(widget.episode.id, watched: _isWatched);
  }

  void _incrementRewatch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isWatched = true;
      _rewatchCount++;
    });
    _dbService.markEpisodeWatched(widget.episode.id, watched: true);
  }

  @override
  Widget build(BuildContext context) {
    final ep = widget.episode;
    final show = widget.show;

    return Scaffold(
      backgroundColor: AppColors.canvasBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 16:9 TMDB Still Hero with Scrim and Back Button
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPosterImage(
                    path: ep.stillPath ?? show.backdropPath,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                    size: 'w780',
                  ),
                  // Dual Gradient Scrim
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          AppColors.canvasBase,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // App Bar icons
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: CircleAvatar(
                          backgroundColor: AppColors.canvasBase.withValues(alpha: 0.7),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // S02 · E03 Badge & Show title
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ep.code,
                                style: AppTypography.labelCode.copyWith(
                                  color: AppColors.textOnAccent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              show.name,
                              style: AppTypography.headline3.copyWith(
                                color: AppColors.slateLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Episode Metadata & Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ep.name,
                    style: AppTypography.headline1.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
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
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.primaryAccent),
                      const SizedBox(width: 2),
                      Text(
                        ep.voteAverage > 0 ? ep.voteAverage.toStringAsFixed(1) : '9.1',
                        style: AppTypography.labelCodeSmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (ep.overview != null && ep.overview!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      ep.overview!,
                      style: AppTypography.bodyLarge.copyWith(height: 1.5),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Giant "I'VE WATCHED THIS" Button + Rewatch incrementer
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleWatched,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _isWatched
                                  ? AppColors.functionalSuccess
                                  : AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isWatched
                                          ? AppColors.functionalSuccess
                                          : AppColors.primaryAccent)
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
                  ),

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

                  // Spoiler-protected comments
                  const SpoilerCommentsList(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
