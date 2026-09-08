import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/sync/pocketbase_sync_engine.dart';
import '../../../common/user_avatar.dart';
import '../../community/widgets/post_comment_sheet.dart';

/// List of Episode Comments with tap-to-reveal blurred spoiler protection and PocketBase sync
class SpoilerCommentsList extends StatefulWidget {
  final int showId;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeCode;
  final String showTitle;

  const SpoilerCommentsList({
    super.key,
    required this.showId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeCode,
    required this.showTitle,
  });

  @override
  State<SpoilerCommentsList> createState() => _SpoilerCommentsListState();
}

class _SpoilerCommentsListState extends State<SpoilerCommentsList> {
  final Set<String> _revealedCommentIds = {};
  List<EpisodeCommentData> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void didUpdateWidget(covariant SpoilerCommentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId ||
        oldWidget.seasonNumber != widget.seasonNumber ||
        oldWidget.episodeNumber != widget.episodeNumber) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await PocketBaseSyncEngine().fetchEpisodeComments(
        showId: widget.showId,
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
        episodeCode: widget.episodeCode,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAddCommentSheet() async {
    final result = await PostCommentSheet.show(
      context,
      defaultShowTitle: widget.showTitle,
      defaultEpisodeCode: widget.episodeCode,
      defaultShowId: widget.showId,
    );
    if (result == true) {
      _loadComments();
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} ay önce';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} gün önce';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} saat önce';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} dk önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMMUNITY DISCUSSIONS',
                style: AppTypography.labelCode,
              ),
              Row(
                children: [
                  Text(
                    '${_comments.length} Comments',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _openAddCommentSheet,
                    icon: const Icon(Icons.add_comment_outlined, size: 18, color: AppColors.primaryAccent),
                    tooltip: 'Yorum Yap',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAccent),
              ),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderStroke, width: 1),
            ),
            child: Column(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.secondarySlate, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Henüz yorum yapılmamış',
                  style: AppTypography.buttonSecondary.copyWith(color: AppColors.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bu bölüm hakkında ilk yorumu sen yap!',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.secondarySlate, fontSize: 11),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openAddCommentSheet,
                  icon: const Icon(Icons.add_comment_rounded, size: 14),
                  label: const Text('Yorum Yaz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAccent,
                    side: const BorderSide(color: AppColors.primaryAccent, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final isRevealed = _revealedCommentIds.contains(comment.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderStroke, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        UserAvatar(
                          radius: 14,
                          url: comment.authorAvatar,
                          fallbackText: comment.author,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          comment.author,
                          style: AppTypography.buttonSecondary.copyWith(fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Text(comment.emotion, style: const TextStyle(fontSize: 13)),
                        const Spacer(),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (comment.isSpoiler && !isRevealed)
                      GestureDetector(
                        onTap: () {
                          setState(() => _revealedCommentIds.add(comment.id));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  color: AppColors.surfaceHighlight,
                                  width: double.infinity,
                                  child: Text(
                                    comment.text,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: AppColors.canvasBase.withValues(alpha: 0.7),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppColors.primaryAccent,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Spoiler • Görmek için dokun',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.primaryAccent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        comment.text,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border_rounded, size: 14, color: AppColors.secondarySlate),
                        const SizedBox(width: 4),
                        Text(
                          '${comment.likes}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: _openAddCommentSheet,
                          child: Row(
                            children: [
                              const Icon(Icons.reply_rounded, size: 14, color: AppColors.secondarySlate),
                              const SizedBox(width: 4),
                              Text('Yanıtla', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
