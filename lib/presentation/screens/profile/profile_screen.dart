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
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'widgets/genre_donut_chart.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/rewatch_rail.dart';
import 'widgets/cloud_sync_card.dart';
import 'widgets/server_settings_sheet.dart';
import 'widgets/import_reconciliation_sheet.dart';
import '../../../data/sync/pocketbase_sync_engine.dart';
import 'package:pocketbase/pocketbase.dart';

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
  final PocketBaseAuthService _authService = PocketBaseAuthService();

  bool _isMigrating = false;
  MigrationProgress? _migrationProgress;
  StreamSubscription<MigrationProgress>? _migrationSub;
  StreamSubscription<AuthStoreEvent>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = PocketBaseAuthService().authStateStream.listen((_) {
      if (mounted) {
        setState(() {
          _migrationProgress = null;
          _isMigrating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _migrationSub?.cancel();
    super.dispose();
  }

  Future<void> _startTvTimeRestore() async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (pickedFile == null) {
        // User cancelled file selection
        return;
      }

      final filePath = pickedFile.path;
      final fileBytes = await pickedFile.readAsBytes();

      if (filePath == null && fileBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.errorRed,
              content: Text('Seçilen dosya okunamadı. Lütfen tekrar deneyin.'),
            ),
          );
        }
        return;
      }

      setState(() {
        _isMigrating = true;
        _migrationProgress = const MigrationProgress(
          current: 0,
          total: 100,
          percentage: 0.05,
          status: 'ZIP arşivi okunuyor...',
        );
      });

      _migrationSub?.cancel();
      _migrationSub = _migrator
          .importZipArchive(zipFilePath: filePath, zipBytes: fileBytes)
          .listen((progress) {
        if (mounted) {
          setState(() {
            _migrationProgress = progress;
            if (progress.isCompleted || progress.isError) {
              _isMigrating = false;
              if (progress.isCompleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.functionalSuccess,
                    content: Text('TV Time yedeği başarıyla içeri aktarıldı!'),
                  ),
                );
                if (_authService.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text('Verileriniz PocketBase bulut hesabınıza eşitleniyor...'),
                    ),
                  );
                  unawaited(PocketBaseSyncEngine().syncAll());
                }
                if (progress.unresolvedItems.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ImportReconciliationSheet.show(
                        context,
                        items: progress.unresolvedItems,
                        onCompleted: () {
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.functionalSuccess,
                                content: Text('Tüm içerikler başarıyla eşleştirildi!'),
                              ),
                            );
                            if (_authService.isLoggedIn) {
                              unawaited(PocketBaseSyncEngine().syncAll());
                            }
                          }
                        },
                      );
                    }
                  });
                }
              }
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isMigrating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Dosya seçimi başarısız: $e'),
          ),
        );
      }
    }
  }

  Future<void> _startTvTimeExport() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportPath = '${dir.path}/screenvault_backup.zip';
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

  Future<void> _confirmAndResetAllData() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ResetDataConfirmationDialog(),
    );

    if (confirmed != true || !mounted) return;

    final statusNotifier = ValueNotifier<String>('Veriler sıfırlanıyor...');

    // Show non-dismissible modal progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderStroke),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.errorRed,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hesap Verileri Sıfırlanıyor',
                  style: AppTypography.headline2.copyWith(color: AppColors.textPrimary, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (context, val, _) {
                    return Text(
                      val,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 1. Wipe local SQLite tables and clear memory cache immediately
      statusNotifier.value = 'Yerel veritabanı temizleniyor...';
      await _dbService.resetAllUserData();

      // 2. Purge remote PocketBase watch history, tracked shows, comments, reactions
      if (_authService.isLoggedIn) {
        await PocketBaseSyncEngine().purgeRemoteUserData(
          onProgress: (status) {
            statusNotifier.value = status;
          },
        );
      }

      // 3. Final local cleanup pass ensuring 100% zero-state
      await _dbService.resetAllUserData();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;
    setState(() {
      _migrationProgress = null;
      _isMigrating = false;
    });

    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.functionalSuccess,
        duration: Duration(seconds: 4),
        content: Text('Tüm veriler (yerel ve bulut) sıfırlandı. Hesabınız yeni kaydolmuş gibi tertemiz başlangıç durumuna döndü!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvasBase,
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<UserStatsModel>(
          stream: _dbService.statsStream,
          initialData: _dbService.getUserStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? _dbService.getUserStats();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
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
                      final name = isLoggedIn ? auth.userName : 'Misafir Kullanıcı';
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
                    child: RepaintBoundary(
                      child: LedTimeCounter(
                        watchTimeParts: stats.watchTimeParts,
                      ),
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
                        RepaintBoundary(
                          child: GenreDonutChart(genreData: stats.genreDistribution),
                        ),
                        const SizedBox(height: 14),
                        RepaintBoundary(
                          child: ActivityHeatmap(activityCounts: stats.last28DaysActivity),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Rewatch Rail
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: RewatchRail(rewatchedShows: stats.rewatchedShows),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // PocketBase Cloud Sync Section
                const SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: CloudSyncCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Unresolved Items Reconciliation Banner
                if (_dbService.getUnresolvedItems().isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primaryAccent, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_dbService.getUnresolvedItems().length} İçerik Eşleştirme Bekliyor',
                                  style: AppTypography.headline3.copyWith(fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Yedekten aktarılan eksik yapımları canlı TMDB ile eşleştirin.',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.secondarySlate),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => ImportReconciliationSheet.show(
                              context,
                              onCompleted: () => setState(() {}),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              foregroundColor: AppColors.textOnAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            child: const Text('Eşleştir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],

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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _migrationProgress!.status,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: _migrationProgress!.isError
                                        ? AppColors.errorRed
                                        : AppColors.functionalSuccess,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_migrationProgress!.isCompleted || _migrationProgress!.isError)
                                InkWell(
                                  onTap: () => setState(() => _migrationProgress = null),
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.secondarySlate),
                                  ),
                                ),
                            ],
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

                // Reset Data & Account Section (Danger Zone)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'HESAP VE VERİ SIFIRLAMA',
                              style: AppTypography.labelCodeSmall.copyWith(
                                color: AppColors.errorRed,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tüm yerel izleme geçmişini, dizileri ve PocketBase bulut veritabanındaki kayıtları (watch_history, tracked_shows) temizleyerek sıfır kilometre bir başlangıç durumuna döndürür.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondarySlate,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _confirmAndResetAllData,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.errorRed,
                              side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.restart_alt_rounded, size: 20),
                            label: Text(
                              'Tüm Verileri Sıfırla (Temiz Hesap)',
                              style: AppTypography.buttonSecondary.copyWith(
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

class _ResetDataConfirmationDialog extends StatefulWidget {
  const _ResetDataConfirmationDialog();

  @override
  State<_ResetDataConfirmationDialog> createState() => _ResetDataConfirmationDialogState();
}

class _ResetDataConfirmationDialogState extends State<_ResetDataConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  final PocketBaseAuthService _authService = PocketBaseAuthService();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = _authService.isLoggedIn ? 'Lütfen şifrenizi girin.' : 'Lütfen onay kodunu girin.';
      });
      return;
    }

    // Developer / Emergency bypass if account was deleted on PocketBase
    if (input.toUpperCase() == 'SIFIRLA') {
      Navigator.of(context).pop(true);
      return;
    }

    if (_authService.isLoggedIn) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final errorMsg = await _authService.verifyPasswordDetailed(input);
      if (!mounted) return;

      if (errorMsg == null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Onaylamak için lütfen tam olarak "SIFIRLA" yazın.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _authService.isLoggedIn;
    final email = _authService.userEmail;

    return RepaintBoundary(
      child: AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderStroke),
        ),
      title: Row(
        children: [
          const Icon(Icons.lock_reset_rounded, color: AppColors.errorRed, size: 28),
          const SizedBox(width: 10),
          Text(
            'Verileri Sıfırla',
            style: AppTypography.headline2.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tüm yerel izleme geçmişiniz, kayıtlı dizileriniz ve PocketBase bulut veritabanınızdaki izleme kayıtları tamamen silinecektir. Bu işlem geri alınamaz.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isLoggedIn
                  ? 'İşlemi onaylamak için ($email) hesabınızın şifresini girin:'
                  : 'Yerel moddasınız. İşlemi onaylamak için lütfen aşağıya SIFIRLA yazın:',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              obscureText: isLoggedIn ? _obscureText : false,
              autocorrect: false,
              enableSuggestions: false,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: isLoggedIn ? 'Hesap Şifresi' : 'SIFIRLA',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                filled: true,
                fillColor: AppColors.canvasBase,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.errorRed),
                ),
                suffixIcon: isLoggedIn
                    ? IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.secondarySlate,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _handleConfirm(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.errorRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'İptal',
            style: AppTypography.buttonSecondary.copyWith(color: AppColors.secondarySlate),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Evet, Tümünü Sıfırla'),
        ),
      ],
    ),
    );
  }
}

