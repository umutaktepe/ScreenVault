import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// User Avatar component with smooth fallback and cached loading
class UserAvatar extends StatelessWidget {
  final String? url;
  final String fallbackText;
  final double radius;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.url,
    this.fallbackText = 'U',
    this.radius = 18.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
        color: AppColors.surfaceHighlight,
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildFallback(),
                errorWidget: (context, url, error) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppColors.surfaceHighlight,
      child: Center(
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : 'U',
          style: AppTypography.buttonPrimary.copyWith(
            fontSize: radius * 0.8,
            color: AppColors.primaryAccent,
          ),
        ),
      ),
    );
  }
}
