import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/user_avatar.dart';

class CharacterMvpItem {
  final String id;
  final String name;
  final String actor;
  final String avatarUrl;
  final int votes;

  const CharacterMvpItem({
    required this.id,
    required this.name,
    required this.actor,
    required this.avatarUrl,
    required this.votes,
  });
}

/// Character MVP Voting Carousel matching Stitch Episode Detail specification
class CharacterMvpPicker extends StatefulWidget {
  final ValueChanged<String>? onVoted;

  const CharacterMvpPicker({super.key, this.onVoted});

  @override
  State<CharacterMvpPicker> createState() => _CharacterMvpPickerState();
}

class _CharacterMvpPickerState extends State<CharacterMvpPicker> {
  String? _selectedCharacterId;

  final List<CharacterMvpItem> _characters = const [
    CharacterMvpItem(
      id: '1',
      name: 'Behzat Ç.',
      actor: 'Erdal Beşikçioğlu',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=120&auto=format&fit=crop&q=80',
      votes: 382,
    ),
    CharacterMvpItem(
      id: '2',
      name: 'Harun',
      actor: 'Fatih Artman',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&auto=format&fit=crop&q=80',
      votes: 194,
    ),
    CharacterMvpItem(
      id: '3',
      name: 'Hayalet',
      actor: 'İnanç Konukçu',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=120&auto=format&fit=crop&q=80',
      votes: 145,
    ),
    CharacterMvpItem(
      id: '4',
      name: 'Akbaba',
      actor: 'Berkan Şal',
      avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=120&auto=format&fit=crop&q=80',
      votes: 168,
    ),
    CharacterMvpItem(
      id: '5',
      name: 'Ercüment Çözer',
      actor: 'Nejat İşler',
      avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=120&auto=format&fit=crop&q=80',
      votes: 279,
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
                'EPISODE MVP CHARACTER',
                style: AppTypography.labelCode,
              ),
              Text(
                'Vote the star',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _characters.length,
            itemBuilder: (context, index) {
              final character = _characters[index];
              final isSelected = _selectedCharacterId == character.id;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCharacterId = character.id);
                  widget.onVoted?.call(character.name);
                },
                child: Container(
                  width: 82,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          UserAvatar(
                            radius: 34,
                            url: character.avatarUrl,
                            fallbackText: character.name,
                            borderColor: isSelected
                                ? AppColors.primaryAccent
                                : AppColors.borderStroke,
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: AppColors.textOnAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        character.name,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryAccent : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${character.votes} votes',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 9,
                          color: AppColors.secondarySlate,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
