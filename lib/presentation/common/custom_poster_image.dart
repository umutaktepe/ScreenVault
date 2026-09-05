import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../data/tmdb/tmdb_endpoints.dart';

/// Cached image helper with Obsidian loading placeholder and fallback
class CustomPosterImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final String size;

  const CustomPosterImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.fit = BoxFit.cover,
    this.size = 'w500',
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = TmdbEndpoints.imageUrl(path, size: size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: AppColors.surfaceHighlight,
        child: fullUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: fullUrl,
                width: width,
                height: height,
                fit: fit,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceHighlight,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceHighlight,
      child: const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: AppColors.secondarySlate,
          size: 28,
        ),
      ),
    );
  }
}
