import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/friend_model.dart';
import '../../../data/database/database_service.dart';
import '../../common/user_avatar.dart';
import 'widgets/friend_activity_card.dart';

/// Community Screen with TV Time friend feed and spoiler-protected discussions
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final DatabaseService _dbService = DatabaseService();

  late final List<CommunityActivityItem> _activities;

  @override
  void initState() {
    super.initState();
    _activities = [
      CommunityActivityItem(
        id: '1',
        userName: 'Kerem Yılmaz',
        userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
        actionType: 'izledi',
        showOrMovieTitle: 'Behzat Ç.',
        episodeCode: 'S01 · E35',
        comment: 'Sezon finali öncesi bu sahne resmen şok etti, Ercüment Çözer geri döndü!',
        isSpoiler: true,
        emotion: '🤯',
        timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
        likesCount: 14,
      ),
      CommunityActivityItem(
        id: '2',
        userName: 'Selin Kaya',
        userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&auto=format&fit=crop&q=80',
        actionType: 'puanladı',
        showOrMovieTitle: 'Succession',
        episodeCode: 'S04 · E09',
        comment: 'Televizyon tarihinin en kusursuz cenaze bölümü. Jesse Armstrong bir dahi.',
        isSpoiler: false,
        emotion: '🔥',
        rating: 9.8,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        likesCount: 38,
      ),
      CommunityActivityItem(
        id: '3',
        userName: 'Emre Demir',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&auto=format&fit=crop&q=80',
        actionType: 'izledi',
        showOrMovieTitle: 'Dark',
        episodeCode: 'S03 · E08',
        comment: 'Döngü nihayet kırıldı ama son sahnede gözyaşlarımı tutamadım.',
        isSpoiler: true,
        emotion: '😢',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        likesCount: 22,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final friends = _dbService.getFriends();

    return Scaffold(
      backgroundColor: AppColors.canvasBase,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header: "Community"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Community',
                      style: AppTypography.headline1,
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryAccent),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.surfaceHighlight,
                            content: Text('Arkadaş davet bağlantısı kopyalandı!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Friends Horizontal Avatar Rail
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      'TV TIME FRIENDS',
                      style: AppTypography.labelCode,
                    ),
                  ),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: friends.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryAccent,
                                      width: 1.5,
                                    ),
                                    color: AppColors.cardSurface,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppColors.primaryAccent,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Arkadaş Ekle',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        }

                        final friend = friends[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Column(
                            children: [
                              UserAvatar(
                                radius: 28,
                                borderColor: AppColors.functionalSuccess,
                                fallbackText: friend.name,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                friend.name.split(' ').first,
                                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Feed Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT ACTIVITY & DISCUSSIONS',
                      style: AppTypography.labelCode,
                    ),
                    const Icon(Icons.tune_rounded, color: AppColors.secondarySlate, size: 18),
                  ],
                ),
              ),
            ),

            // Activity Cards Stream
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final act = _activities[index];
                  return FriendActivityCard(activity: act);
                },
                childCount: _activities.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
