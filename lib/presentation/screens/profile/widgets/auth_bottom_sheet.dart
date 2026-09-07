import 'package:flutter/material.dart';
import '../../../../data/services/pocketbase_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AuthBottomSheet(),
    );
  }

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  final PocketBaseAuthService _authService = PocketBaseAuthService();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Lütfen tüm zorunlu alanları doldurun.');
      return;
    }

    if (_isRegisterMode) {
      if (password.length < 8) {
        setState(() => _errorMessage = 'Şifre en az 8 karakter olmalıdır.');
        return;
      }
      if (password != confirm) {
        setState(() => _errorMessage = 'Şifreler birbiriyle eşleşmiyor.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await _authService.register(
          email: email,
          password: password,
          name: name.isNotEmpty ? name : null,
        );
      } else {
        await _authService.login(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.functionalSuccess,
            content: Text(_isRegisterMode
                ? 'Hesap başarıyla oluşturuldu ve giriş yapıldı!'
                : 'Hoş geldiniz! Giriş başarılı.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final errStr = e.toString();
          if (errStr.contains('Failed to authenticate') || errStr.contains('400')) {
            _errorMessage = _isRegisterMode
                ? 'Bu e-posta zaten kayıtlı veya geçersiz bilgiler.'
                : 'Hatalı e-posta veya şifre girdiniz.';
          } else {
            _errorMessage = 'Bağlantı hatası: Lütfen sunucunun açık olduğundan emin olun.';
          }
        });
      }
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
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
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

            // Mode Selector Tabs (Giriş Yap / Kayıt Ol)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.canvasBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isRegisterMode = false;
                        _errorMessage = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isRegisterMode ? AppColors.surfaceElevated : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            'Giriş Yap',
                            style: AppTypography.buttonSecondary.copyWith(
                              color: !_isRegisterMode ? AppColors.primaryAccent : AppColors.textSecondary,
                              fontWeight: !_isRegisterMode ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isRegisterMode = true;
                        _errorMessage = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isRegisterMode ? AppColors.surfaceElevated : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            'Kayıt Ol',
                            style: AppTypography.buttonSecondary.copyWith(
                              color: _isRegisterMode ? AppColors.primaryAccent : AppColors.textSecondary,
                              fontWeight: _isRegisterMode ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_isRegisterMode) ...[
              Text(
                'AD SOYAD VEYA KULLANICI ADI',
                style: AppTypography.labelCodeSmall.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceHighlight,
                  hintText: 'Örn: Ahmet Yılmaz',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.secondarySlate, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderStroke)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderStroke)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),
            ],

            Text(
              'E-POSTA ADRESİ',
              style: AppTypography.labelCodeSmall.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceHighlight,
                hintText: 'ornek@screenvault.com',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.secondarySlate, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderStroke)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderStroke)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5)),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'ŞİFRE',
              style: AppTypography.labelCodeSmall.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceHighlight,
                hintText: '••••••••',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.secondarySlate, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.secondarySlate,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderStroke)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderStroke)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5)),
              ),
            ),

            if (_isRegisterMode) ...[
              const SizedBox(height: 14),
              Text(
                'ŞİFRE TEKRARI',
                style: AppTypography.labelCodeSmall.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceHighlight,
                  hintText: '••••••••',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.secondarySlate, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderStroke)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderStroke)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5)),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.errorRed, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.textOnAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      )
                    : Icon(_isRegisterMode ? Icons.person_add_rounded : Icons.login_rounded, size: 18),
                label: Text(
                  _isLoading
                      ? 'Lütfen bekleyin...'
                      : (_isRegisterMode ? 'Hesap Oluştur & Giriş Yap' : 'Giriş Yap'),
                  style: AppTypography.buttonPrimary.copyWith(fontSize: 13),
                ),
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
}
