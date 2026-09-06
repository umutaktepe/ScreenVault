import 'package:flutter/material.dart';
import '../../../../core/network/pocketbase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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
  late final TextEditingController _urlController;
  bool _isTesting = false;
  bool? _testSuccess;
  String? _testMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _client.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final testUrl = _urlController.text.trim();
    if (testUrl.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testMessage = null;
    });

    try {
      final isHealthy = await _client.checkHealth();
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = isHealthy;
          _testMessage = isHealthy
              ? 'Bağlantı başarılı! PocketBase aktif.'
              : 'Sunucuya ulaşılamadı. Adresi veya tüneli kontrol edin.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testMessage = 'Hata: $e';
        });
      }
    }
  }

  Future<void> _saveAndApply() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    final ok = await _client.updateServerUrl(newUrl);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.functionalSuccess,
            content: Text('PocketBase sunucu adresi güncellendi ve bağlandı!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warningOrange,
            content: Text('Adres kaydedildi fakat sunucu yanıt vermedi: $newUrl'),
          ),
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderStroke, width: 1),
        ),
      ),
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

          // Title & Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: AppColors.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POCKETBASE SUNUCU AYARLARI',
                      style: AppTypography.labelCode.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kendi barındırdığınız PocketBase veya Ngrok URL\'i',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // URL Text Field
          Text(
            'SUNUCU BAĞLANTI ADRESİ (URL)',
            style: AppTypography.labelCodeSmall.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceHighlight,
              hintText: 'https://...',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.link_rounded, color: AppColors.secondarySlate, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.restart_alt_rounded, color: AppColors.secondarySlate, size: 20),
                tooltip: 'Varsayılan Ngrok Adresine Sıfırla',
                onPressed: () {
                  _urlController.text = 'http://127.0.0.1:8090';
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

          if (_testMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _testSuccess == true
                    ? AppColors.functionalSuccess.withValues(alpha: 0.15)
                    : AppColors.errorRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _testSuccess == true ? AppColors.functionalSuccess : AppColors.errorRed,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: _testSuccess == true ? AppColors.functionalSuccess : AppColors.errorRed,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: _testSuccess == true ? AppColors.functionalSuccess : AppColors.errorRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Action buttons: Test Ping & Save
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderStroke),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
                          ),
                        )
                      : const Icon(Icons.network_check_rounded, size: 18),
                  label: Text('Bağlantıyı Test Et', style: AppTypography.buttonSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAndApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.textOnAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text('Kaydet & Bağlan', style: AppTypography.buttonPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
