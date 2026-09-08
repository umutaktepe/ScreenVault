import 'package:flutter/material.dart';
import '../../../../core/network/pocketbase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/services/pocketbase_auth_service.dart';
import '../../../../data/sync/pocketbase_sync_engine.dart';
import '../../auth/auth_screen.dart';
import 'server_settings_sheet.dart';

class CloudSyncCard extends StatefulWidget {
  const CloudSyncCard({super.key});

  @override
  State<CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends State<CloudSyncCard> {
  final PocketBaseClient _client = PocketBaseClient();
  final PocketBaseAuthService _auth = PocketBaseAuthService();
  final PocketBaseSyncEngine _syncEngine = PocketBaseSyncEngine();

  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth.authStateStream,
      builder: (streamCtx, _) {
        final isLoggedIn = _auth.isLoggedIn;
        final email = _auth.userEmail;
        final name = _auth.userName;
        final serverDomain = Uri.tryParse(_client.serverUrl)?.host ?? _client.serverUrl;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLoggedIn
                  ? AppColors.functionalSuccess.withValues(alpha: 0.35)
                  : AppColors.borderStroke,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isLoggedIn
                              ? AppColors.functionalSuccess.withValues(alpha: 0.15)
                              : AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.cloud_sync_rounded,
                          color: isLoggedIn
                              ? AppColors.functionalSuccess
                              : AppColors.secondarySlate,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'POCKETBASE CLOUD SYNC',
                            style: AppTypography.labelCode.copyWith(fontSize: 12),
                          ),
                          Text(
                            serverDomain,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Online/Offline Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLoggedIn
                          ? AppColors.functionalSuccess.withValues(alpha: 0.12)
                          : AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLoggedIn
                            ? AppColors.functionalSuccess.withValues(alpha: 0.4)
                            : AppColors.borderStroke,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLoggedIn
                                ? AppColors.functionalSuccess
                                : AppColors.secondarySlate,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isLoggedIn ? 'Çevrimiçi' : 'Yerel Mod',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: isLoggedIn
                                ? AppColors.functionalSuccess
                                : AppColors.secondarySlate,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // User Info or Guest Message
              if (isLoggedIn) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderStroke, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: AppTypography.headline2.copyWith(
                            fontSize: 14,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              email,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.errorRed),
                        tooltip: 'Çıkış Yap',
                        onPressed: () async {
                          await _auth.logout();
                          if (!context.mounted) return;
                          setState(() {});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.surfaceHighlight,
                                content: Text('PocketBase oturumu kapatıldı ve yerel veriler temizlendi.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Tüm cihazlarınız arasında otomatik izleme geçmişi ve favori dizileri eşitlemek için PocketBase hesabınıza giriş yapın.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 14),

              // Action Buttons: "Şimdi Eşitle" & "Giriş Yap" / "Sunucu Ayarları"
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (!isLoggedIn || _isSyncing)
                          ? (isLoggedIn
                              ? null
                              : () async {
                                  final res = await AuthScreen.navigate(context);
                                  if (res == true && mounted) {
                                    setState(() {});
                                  }
                                })
                          : () async {
                              setState(() => _isSyncing = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final res = await _syncEngine.syncAll();
                              if (mounted) {
                                setState(() => _isSyncing = false);
                                messenger.showSnackBar(
                                  SnackBar(
                                    backgroundColor: res.success
                                        ? AppColors.functionalSuccess
                                        : AppColors.errorRed,
                                    content: Text(res.success
                                        ? 'Eşitleme tamamlandı! (${res.uploadedRecords} yüklendi, ${res.downloadedRecords} indirildi)'
                                        : 'Eşitleme hatası: ${res.error}'),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLoggedIn
                            ? AppColors.primaryAccent
                            : AppColors.surfaceElevated,
                        foregroundColor: isLoggedIn
                            ? AppColors.textOnAccent
                            : AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.black),
                              ),
                            )
                          : Icon(
                              isLoggedIn ? Icons.sync_rounded : Icons.login_rounded,
                              size: 18,
                              color: isLoggedIn ? Colors.black : AppColors.primaryAccent,
                            ),
                      label: Text(
                        _isSyncing
                            ? 'Eşitleniyor...'
                            : (isLoggedIn ? 'Şimdi Eşitle' : 'Giriş / Kayıt'),
                        style: AppTypography.buttonPrimary.copyWith(
                          fontSize: 12,
                          color: isLoggedIn ? Colors.black : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ServerSettingsSheet.show(context);
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderStroke),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(
                      'Sunucu',
                      style: AppTypography.buttonSecondary.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
