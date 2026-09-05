import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PlatformItem {
  final String name;
  final int providerId;
  final Color badgeColor;

  const PlatformItem({
    required this.name,
    required this.providerId,
    required this.badgeColor,
  });
}

/// Regional streaming platform filter bar (Netflix, Prime, BluTV, Disney+, Apple TV+)
class PlatformFilterBar extends StatelessWidget {
  final int? selectedProviderId;
  final ValueChanged<int?> onSelect;

  static const List<PlatformItem> platforms = [
    PlatformItem(name: 'All', providerId: 0, badgeColor: AppColors.primaryAccent),
    PlatformItem(name: 'Netflix', providerId: 8, badgeColor: Color(0xFFE50914)),
    PlatformItem(name: 'Prime Video', providerId: 119, badgeColor: Color(0xFF00A8E1)),
    PlatformItem(name: 'BluTV', providerId: 341, badgeColor: Color(0xFF00D26A)),
    PlatformItem(name: 'Disney+', providerId: 337, badgeColor: Color(0xFF113CCF)),
    PlatformItem(name: 'Apple TV+', providerId: 350, badgeColor: Color(0xFFA2AAAD)),
  ];

  const PlatformFilterBar({
    super.key,
    required this.selectedProviderId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: platforms.length,
        itemBuilder: (context, index) {
          final platform = platforms[index];
          final isSelected = (selectedProviderId ?? 0) == platform.providerId;

          return GestureDetector(
            onTap: () {
              onSelect(platform.providerId == 0 ? null : platform.providerId);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceHighlight : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (platform.providerId != 0) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: platform.badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    platform.name,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryAccent : AppColors.secondarySlate,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
