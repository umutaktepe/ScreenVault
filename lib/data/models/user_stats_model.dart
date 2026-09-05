import '../../core/utils/duration_formatter.dart';

/// User watch statistics and profile bento data
class UserStatsModel {
  final int totalWatchMinutes;
  final int showsFollowedCount;
  final int episodesWatchedCount;
  final int moviesWatchedCount;
  final Map<String, double> genreDistribution;
  final List<int> last28DaysActivity;
  final List<RewatchItem> rewatchedShows;

  const UserStatsModel({
    required this.totalWatchMinutes,
    required this.showsFollowedCount,
    required this.episodesWatchedCount,
    required this.moviesWatchedCount,
    this.genreDistribution = const {},
    this.last28DaysActivity = const [],
    this.rewatchedShows = const [],
  });

  WatchTimeParts get watchTimeParts => DurationFormatter.formatLifetimeMinutes(totalWatchMinutes);

  /// Default statistics reflecting the imported 3,832 TV Time watch records
  /// (186,576 minutes = 4 Months 9 Days 13 Hours)
  factory UserStatsModel.initialFromTvTime() {
    return UserStatsModel(
      totalWatchMinutes: 186576,
      showsFollowedCount: 103,
      episodesWatchedCount: 3393,
      moviesWatchedCount: 493,
      genreDistribution: const {
        'Sci-Fi': 38.0,
        'Drama': 29.0,
        'Crime': 21.0,
        'Comedy': 12.0,
      },
      last28DaysActivity: [
        1, 3, 0, 2, 4, 1, 0,
        2, 5, 3, 1, 0, 2, 4,
        3, 0, 1, 6, 2, 4, 3,
        1, 2, 5, 3, 0, 2, 4,
      ],
      rewatchedShows: const [
        RewatchItem(title: 'Friends', count: 4, posterPath: '/7bu30eqzkh9PSSt089V6B4Jz4k1.jpg'),
        RewatchItem(title: 'Behzat Ç.', count: 3, posterPath: '/h1qYgG4CjQzWqK8W1gqg6h7yU9a.jpg'),
        RewatchItem(title: 'Breaking Bad', count: 3, posterPath: '/ggFHVNu6YYI5L9pCfOacjizRGt.jpg'),
        RewatchItem(title: 'Dark', count: 2, posterPath: '/apbrbWs8M9lyOpJYU5WXrpFbk1Z.jpg'),
      ],
    );
  }
}

class RewatchItem {
  final String title;
  final int count;
  final String? posterPath;

  const RewatchItem({
    required this.title,
    required this.count,
    this.posterPath,
  });
}
