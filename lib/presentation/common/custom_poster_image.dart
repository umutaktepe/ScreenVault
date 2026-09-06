import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../data/tmdb/tmdb_endpoints.dart';

/// Cached image helper with Obsidian loading placeholder and multi-tier fallback
class CustomPosterImage extends StatelessWidget {
  final String? path;
  final String? fallbackPath;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final String size;

  static const Set<String> _mockPaths = {
    '/7bu30eqzkh9PSSt089V6B4Jz4k1.jpg',
    '/h1qYgG4CjQzWqK8W1gqg6h7yU9a.jpg',
    '/7hdg5kYwA5kE7w1h0U6cK7u.jpg',
    '/pfte7mgXtq7cv1jl7aq5gr95Um6.jpg',
    '/lsas4jgNHk4c4d7z8b3z3.jpg',
    '/l0qVZIpXtIo7km9u5YAV0ecKpYH.jpg',
    '/vV2NnU6wW9nI8xJz0aD8y1o0K7l.jpg',
    '/e2x9U7zU6aK5p9Y3m0O8b1.jpg',
  };

  const CustomPosterImage({
    super.key,
    required this.path,
    this.fallbackPath,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.fit = BoxFit.cover,
    this.size = 'w500',
  });

  static bool _isValidPath(String? p) {
    if (p == null || p.isEmpty) return false;
    return !_mockPaths.contains(p);
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = _isValidPath(path) ? path : null;
    final effectiveFallback = _isValidPath(fallbackPath) ? fallbackPath : null;

    final targetPath = effectivePrimary ?? effectiveFallback;
    final fullUrl = TmdbEndpoints.imageUrl(targetPath, size: size);
    final fallbackUrl = effectiveFallback != null ? TmdbEndpoints.imageUrl(effectiveFallback, size: size) : '';

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
                errorWidget: (context, url, error) {
                  // Attempt secondary fallback if primary URL failed to load
                  if (fallbackUrl.isNotEmpty && fallbackUrl != fullUrl) {
                    return CachedNetworkImage(
                      imageUrl: fallbackUrl,
                      width: width,
                      height: height,
                      fit: fit,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceHighlight,
                      ),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    );
                  }
                  return _buildPlaceholder();
                },
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
