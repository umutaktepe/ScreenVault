import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/config/tmdb_config.dart';
import '../../../../core/network/pocketbase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/database/database_service.dart';
import '../../../../data/sync/pocketbase_sync_engine.dart';

class ServerSettingsSheet extends StatefulWidget {
  const ServerSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ServerSettingsSheet(),
    );
  }

  @override
  State<ServerSettingsSheet> createState() => _ServerSettingsSheetState();
}

class _ServerSettingsSheetState extends State<ServerSettingsSheet> {
  final PocketBaseClient _client = PocketBaseClient();
  final TmdbConfig _tmdbConfig = TmdbConfig();

  late final TextEditingController _urlController;
  late final TextEditingController _tmdbKeyController;

  bool _isTestingPb = false;
  bool? _pbTestSuccess;
  String? _pbTestMessage;

  bool _isTestingTmdb = false;
  bool? _tmdbTestSuccess;
  String? _tmdbTestMessage;

  bool _isSaving = false;
  bool _obscureTmdbKey = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _client.serverUrl);
    _tmdbKeyController = TextEditingController(text: _tmdbConfig.apiKey);

    if (_tmdbConfig.hasValidKey) {
      _tmdbTestSuccess = true;
      _tmdbTestMessage = 'TMDB API v3 anahtarı aktif ve tanımlı.';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tmdbKeyController.dispose();
    super.dispose();
  }

  Future<void> _testPbConnection() async {
    final testUrl = _urlController.text.trim();
    if (testUrl.isEmpty) return;

    setState(() {
      _isTestingPb = true;
      _pbTestSuccess = null;
      _pbTestMessage = null;
    });

    try {
      final isHealthy = await _client.checkUrlHealth(testUrl);
      if (mounted) {
        setState(() {
          _isTestingPb = false;
          _pbTestSuccess = isHealthy;
          _pbTestMessage = isHealthy
              ? 'Bağlantı başarılı! PocketBase aktif.'
              : 'Sunucuya ulaşılamadı. Adresi veya tüneli kontrol edin.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingPb = false;
          _pbTestSuccess = false;
          _pbTestMessage = 'Hata: $e';
        });
      }
    }
  }

  Future<void> _testTmdbConnection() async {
    final key = _tmdbKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _tmdbTestSuccess = false;
        _tmdbTestMessage = 'Lütfen bir TMDB v3 API anahtarı girin.';
      });
      return;
    }

    setState(() {
      _isTestingTmdb = true;
      _tmdbTestSuccess = null;
      _tmdbTestMessage = null;
    });

    final success = await _tmdbConfig.testApiKey(key);
    if (mounted) {
      setState(() {
        _isTestingTmdb = false;
        _tmdbTestSuccess = success;
        _tmdbTestMessage = success
            ? 'TMDB v3 API bağlantısı başarılı! Veri çekilebilir.'
            : 'Geçersiz veya yetkisiz TMDB anahtarı.';
      });
    }
  }

  Future<void> _saveAndApply() async {
    final newUrl = _urlController.text.trim();
    final newTmdbKey = _tmdbKeyController.text.trim();

    setState(() => _isSaving = true);

    bool pbOk = true;
    if (newUrl.isNotEmpty) {
      pbOk = await _client.updateServerUrl(newUrl);
      if (pbOk && _client.isAuthenticated) {
        PocketBaseSyncEngine().startRealtimeListener(force: true);
        unawaited(PocketBaseSyncEngine().syncAll());
      }
    }

    if (newTmdbKey.isNotEmpty) {
      await _tmdbConfig.updateApiKey(newTmdbKey);
      // Trigger background metadata enrichment with new key
      DatabaseService().enrichAllMissingMetadata();
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: pbOk ? AppColors.functionalSuccess : AppColors.warningOrange,
          content: Text(
            pbOk
                ? 'Sunucu ve TMDB ayarları başarıyla kaydedildi!'
                : 'Ayarlar kaydedildi, fakat PocketBase sunucusuna ulaşılamadı.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: RepaintBoundary(
          child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.borderStroke, width: 1),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_suggest_rounded,
                    color: AppColors.primaryAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUNUCU & API AYARLARI',
                        style: AppTypography.labelCode.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PocketBase backend ve TMDB veri sağlayıcısı',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- SECTION 1: POCKETBASE ---
            Row(
              children: [
                const Icon(Icons.dns_rounded, size: 16, color: AppColors.primaryAccent),
                const SizedBox(width: 8),
                Text(
                  'POCKETBASE SUNUCU URL',
                  style: AppTypography.labelCodeSmall.copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceHighlight,
                hintText: PocketBaseClient.defaultPocketBaseUrl,
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.secondarySlate, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.restart_alt_rounded, color: AppColors.secondarySlate, size: 20),
                  tooltip: 'Ngrok Domainine Sıfırla',
                  onPressed: () {
                    _urlController.text = PocketBaseClient.defaultPocketBaseUrl;
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                ),
              ),
            ),

            if (_pbTestMessage != null) ...[
              const SizedBox(height: 8),
              _buildStatusBadge(_pbTestSuccess == true, _pbTestMessage!),
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isTestingPb ? null : _testPbConnection,
                icon: _isTestingPb
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAccent),
                      )
                    : const Icon(Icons.network_check_rounded, size: 16),
                label: Text('PocketBase Test Et', style: AppTypography.labelCodeSmall),
              ),
            ),

            const Divider(color: AppColors.borderStroke, height: 24),

            // --- SECTION 2: TMDB API KEY ---
            Row(
              children: [
                const Icon(Icons.movie_filter_rounded, size: 16, color: AppColors.functionalSuccess),
                const SizedBox(width: 8),
                Text(
                  'TMDB v3 API ANAHTARI (GERÇEK VERİ)',
                  style: AppTypography.labelCodeSmall.copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tmdbKeyController,
              obscureText: _obscureTmdbKey,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceHighlight,
                hintText: 'TMDB API v3 Key (32 karakter)',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.secondarySlate, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureTmdbKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.secondarySlate,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureTmdbKey = !_obscureTmdbKey),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                ),
              ),
            ),

            if (_tmdbTestMessage != null) ...[
              const SizedBox(height: 8),
              _buildStatusBadge(_tmdbTestSuccess == true, _tmdbTestMessage!),
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isTestingTmdb ? null : _testTmdbConnection,
                icon: _isTestingTmdb
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAccent),
                      )
                    : const Icon(Icons.verified_rounded, size: 16),
                label: Text('TMDB Anahtarını Doğrula', style: AppTypography.labelCodeSmall),
              ),
            ),

            const SizedBox(height: 20),

            // Save & Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAndApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.textOnAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text('Ayarları Kaydet & Uygula', style: AppTypography.buttonPrimary),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
);
  }

  Widget _buildStatusBadge(bool isSuccess, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppColors.functionalSuccess.withValues(alpha: 0.15)
            : AppColors.errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSuccess ? AppColors.functionalSuccess : AppColors.errorRed,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isSuccess ? AppColors.functionalSuccess : AppColors.errorRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isSuccess ? AppColors.functionalSuccess : AppColors.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
