import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/user_avatar.dart';

class EpisodeCommentItem {
  final String id;
  final String author;
  final String authorAvatar;
  final String text;
  final bool isSpoiler;
  final String timeAgo;
  final int likes;

  const EpisodeCommentItem({
    required this.id,
    required this.author,
    required this.authorAvatar,
    required this.text,
    required this.isSpoiler,
    required this.timeAgo,
    required this.likes,
  });
}

/// List of Episode Comments with tap-to-reveal blurred spoiler protection
class SpoilerCommentsList extends StatefulWidget {
  const SpoilerCommentsList({super.key});

  @override
  State<SpoilerCommentsList> createState() => _SpoilerCommentsListState();
}

class _SpoilerCommentsListState extends State<SpoilerCommentsList> {
  final Set<String> _revealedCommentIds = {};

  final List<EpisodeCommentItem> _comments = const [
    EpisodeCommentItem(
      id: 'c1',
      author: 'Caner Öz',
      authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&auto=format&fit=crop&q=80',
      text: 'Akbaba\'nın mezarlık sahnesinde söylediği sözler ciğerimi söktü...',
      isSpoiler: false,
      timeAgo: '2 saat önce',
      likes: 19,
    ),
    EpisodeCommentItem(
      id: 'c2',
      author: 'Deniz Demir',
      authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&auto=format&fit=crop&q=80',
      text: 'Ercüment Çözer cinayet delillerini göle attı ve Savcı Esra\'yı köşeye sıkıştırdı!',
      isSpoiler: true,
      timeAgo: '4 saat önce',
      likes: 42,
    ),
    EpisodeCommentItem(
      id: 'c3',
      author: 'Barış Koç',
      authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&auto=format&fit=crop&q=80',
      text: 'Bölümün sonundaki müzik seçimi inanılmaz iyiydi.',
      isSpoiler: false,
      timeAgo: '6 saat önce',
      likes: 11,
    ),
  ];

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
              Text(
                '${_comments.length} Comments',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                      const Spacer(),
                      Text(
                        comment.timeAgo,
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
                      const Icon(Icons.reply_rounded, size: 14, color: AppColors.secondarySlate),
                      const SizedBox(width: 4),
                      Text('Yanıtla', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
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
