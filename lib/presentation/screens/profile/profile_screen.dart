import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/user_stats_model.dart';
import '../../../data/database/database_service.dart';
import '../../../data/migration/tv_time_migrator.dart';
import '../../../data/migration/tv_time_exporter.dart';
import '../../common/led_time_counter.dart';
import '../../common/user_avatar.dart';
import '../../../data/services/pocketbase_auth_service.dart';
import '../auth/auth_screen.dart';
import 'widgets/genre_donut_chart.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/rewatch_rail.dart';
import 'widgets/cloud_sync_card.dart';
import 'widgets/server_settings_sheet.dart';

/// Profile & Statistics Screen matching Stitch specification
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TvTimeMigrator _migrator = TvTimeMigrator();
  final TvTimeExporter _exporter = TvTimeExporter();

  bool _isMigrating = false;
  MigrationProgress? _migrationProgress;
  StreamSubscription<MigrationProgress>? _migrationSub;

  @override
  void dispose() {
    _migrationSub?.cancel();
    super.dispose();
  }

  void _startTvTimeRestore() {
    setState(() {
      _isMigrating = true;
      _migrationProgress = const MigrationProgress(
        current: 0,
        total: 100,
        percentage: 0.05,
        status: 'Yedekleme dosyası hazırlanıyor...',
      );
    });

    _migrationSub?.cancel();
    _migrationSub = _migrator.importZipArchive().listen((progress) {
      if (mounted) {
        setState(() {
          _migrationProgress = progress;
          if (progress.isCompleted || progress.isError) {
            _isMigrating = false;
          }
        });
      }
    });
  }

  Future<void> _startTvTimeExport() async {
    try {
      const exportPath = '/home/umutaktepe/Screen Vault/screenvault_backup.zip';
      final file = await _exporter.exportToZip(exportPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.functionalSuccess,
            content: Text('TV Time yedeği başarıyla oluşturuldu:\n${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Dışa aktarma hatası: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBase,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<UserStatsModel>(
          stream: _dbService.statsStream,
          initialData: _dbService.getUserStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? UserStatsModel.initialFromTvTime();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Bar: Profile title + Settings
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile & Stats',
                          style: AppTypography.headline1,
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppColors.secondarySlate),
                          tooltip: 'Sunucu Ayarları',
                          onPressed: () => ServerSettingsSheet.show(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // User Info Header
                SliverToBoxAdapter(
                  child: StreamBuilder(
                    stream: PocketBaseAuthService().authStateStream,
                    builder: (context, _) {
                      final auth = PocketBaseAuthService();
                      final isLoggedIn = auth.isLoggedIn;
                      final name = isLoggedIn ? auth.userName : 'Umut Aktepe';
                      final email = isLoggedIn ? auth.userEmail : 'ScreenVault Explorer • Yerel Mod';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: InkWell(
                          onTap: () async {
                            if (!isLoggedIn) {
                              await AuthScreen.navigate(context);
                              if (mounted) setState(() {});
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            children: [
                              UserAvatar(
                                radius: 32,
                                borderColor: isLoggedIn ? AppColors.functionalSuccess : AppColors.primaryAccent,
                                fallbackText: name,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: AppTypography.headline2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isLoggedIn) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified_rounded, color: AppColors.functionalSuccess, size: 18),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isLoggedIn ? email : 'Giriş yapmak için dokunun • Yerel Mod',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isLoggedIn ? AppColors.primaryAccent : AppColors.secondarySlate,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLoggedIn)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryAccent, width: 0.8),
                                  ),
                                  child: Text(
                                    'Giriş Yap',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3-Column Gold Digital LED Watch Time Counter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LedTimeCounter(
                      watchTimeParts: stats.watchTimeParts,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Metric Badges (Shows, Episodes, Movies)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildStatCard('FOLLOWED', '${stats.showsFollowedCount}', 'Shows'),
                        const SizedBox(width: 8),
                        _buildStatCard('WATCHED', '${stats.episodesWatchedCount}', 'Episodes'),
                        const SizedBox(width: 8),
                        _buildStatCard('SEEN', '${stats.moviesWatchedCount}', 'Movies'),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Bento Grid Section: Genre Donut & Activity Heatmap
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        GenreDonutChart(genreData: stats.genreDistribution),
                        const SizedBox(height: 14),
                        ActivityHeatmap(activityCounts: stats.last28DaysActivity),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Rewatch Rail
                SliverToBoxAdapter(
                  child: RewatchRail(rewatchedShows: stats.rewatchedShows),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // PocketBase Cloud Sync Section
                const SliverToBoxAdapter(
                  child: CloudSyncCard(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // TV Time Migration & Backup Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderStroke, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TV TIME DATA & ARCHIVE',
                          style: AppTypography.labelCode,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kullanıcının gdpr-data.zip yedeğini içeri aktarın veya mevcut verilerinizi TV Time formatında dışarı aktarın.',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        if (_migrationProgress != null) ...[
                          LinearProgressIndicator(
                            value: _migrationProgress!.percentage,
                            backgroundColor: AppColors.surfaceHighlight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _migrationProgress!.isError
                                  ? AppColors.errorRed
                                  : AppColors.functionalSuccess,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _migrationProgress!.status,
                            style: AppTypography.bodySmall.copyWith(
                              color: _migrationProgress!.isError
                                  ? AppColors.errorRed
                                  : AppColors.functionalSuccess,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isMigrating ? null : _startTvTimeRestore,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryAccent,
                                  foregroundColor: AppColors.textOnAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: _isMigrating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.black),
                                        ),
                                      )
                                    : const Icon(Icons.archive_outlined, size: 18),
                                label: Text(
                                  _isMigrating ? 'Aktarılıyor...' : 'Yedeği İçe Aktar',
                                  style: AppTypography.buttonPrimary.copyWith(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isMigrating ? null : _startTvTimeExport,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(color: AppColors.borderStroke),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.upload_file_outlined, size: 18),
                                label: Text(
                                  'Dışa Aktar (ZIP)',
                                  style: AppTypography.buttonSecondary.copyWith(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderStroke, width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.labelCodeSmall.copyWith(fontSize: 9),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.headline2.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              unit,
              style: AppTypography.bodySmall.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
