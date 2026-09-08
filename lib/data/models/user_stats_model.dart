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

  /// Empty statistics representing zero state
  factory UserStatsModel.empty() {
    return const UserStatsModel(
      totalWatchMinutes: 0,
      showsFollowedCount: 0,
      episodesWatchedCount: 0,
      moviesWatchedCount: 0,
      genreDistribution: {},
      last28DaysActivity: [],
      rewatchedShows: [],
    );
  }

  /// Clean initial statistics for zero-state database
  factory UserStatsModel.initialFromTvTime() => UserStatsModel.empty();
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
