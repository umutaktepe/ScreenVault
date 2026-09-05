import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/friend_model.dart';
import '../../../common/user_avatar.dart';

/// Friend Activity Card with tap-to-reveal spoiler protection
class FriendActivityCard extends StatefulWidget {
  final CommunityActivityItem activity;

  const FriendActivityCard({
    super.key,
    required this.activity,
  });

  @override
  State<FriendActivityCard> createState() => _FriendActivityCardState();
}

class _FriendActivityCardState extends State<FriendActivityCard> {
  bool _revealed = false;
  late int _likes;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.activity.likesCount;
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderStroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Action, Timestamp
          Row(
            children: [
              UserAvatar(
                radius: 18,
                url: act.userAvatar,
                fallbackText: act.userName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: act.userName,
                        style: AppTypography.buttonSecondary.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: ' ${act.actionType} ',
                            style: AppTypography.bodySmall,
                          ),
                          TextSpan(
                            text: act.showOrMovieTitle,
                            style: AppTypography.buttonSecondary.copyWith(
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatRelative(act.timestamp),
                      style: AppTypography.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Emotion Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  act.emotion,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),

          if (act.episodeCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                act.episodeCode!,
                style: AppTypography.labelCodeSmall.copyWith(color: AppColors.primaryAccent),
              ),
            ),
          ],

          if (act.comment != null) ...[
            const SizedBox(height: 12),
            if (act.isSpoiler && !_revealed)
              // Blurred Spoiler Warning Card
              GestureDetector(
                onTap: () => setState(() => _revealed = true),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: AppColors.surfaceHighlight,
                          width: double.infinity,
                          child: Text(
                            act.comment!,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: AppColors.canvasBase.withValues(alpha: 0.6),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.primaryAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Spoiler içerir • Görmek için dokun',
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
              // Revealed or Safe Comment
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  act.comment!,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ),
          ],

          const SizedBox(height: 12),

          // Footer: Likes and Reply buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLiked = !_isLiked;
                        _likes += _isLiked ? 1 : -1;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isLiked ? AppColors.errorRed : AppColors.secondarySlate,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_likes',
                          style: AppTypography.bodySmall.copyWith(
                            color: _isLiked ? AppColors.errorRed : AppColors.secondarySlate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.mode_comment_outlined, color: AppColors.secondarySlate, size: 16),
                  const SizedBox(width: 4),
                  Text('Yanıtla', style: AppTypography.bodySmall),
                ],
              ),
              const Icon(Icons.share_outlined, color: AppColors.secondarySlate, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
