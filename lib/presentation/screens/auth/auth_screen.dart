import 'package:flutter/material.dart';
import '../../../../core/network/pocketbase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/services/pocketbase_auth_service.dart';
import '../profile/widgets/server_settings_sheet.dart';

/// Cinematic OLED Login & Sign-Up Screen matching Screen Vault design language
class AuthScreen extends StatefulWidget {
  final bool initialRegisterMode;

  const AuthScreen({
    super.key,
    this.initialRegisterMode = false,
  });

  static Future<bool?> navigate(BuildContext context, {bool registerMode = false}) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(initialRegisterMode: registerMode),
      ),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final PocketBaseAuthService _authService = PocketBaseAuthService();
  final PocketBaseClient _client = PocketBaseClient();

  late bool _isRegisterMode;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialRegisterMode;
  }

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
      setState(() => _errorMessage = 'Lütfen e-posta ve şifrenizi girin.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Lütfen geçerli bir e-posta adresi girin.');
      return;
    }

    if (_isRegisterMode) {
      if (password.length < 8) {
        setState(() => _errorMessage = 'Şifreniz en az 8 karakter uzunluğunda olmalıdır.');
        return;
      }
      if (password != confirm) {
        setState(() => _errorMessage = 'Girdiğiniz şifreler birbiriyle eşleşmiyor.');
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isRegisterMode
                        ? 'Hesabınız başarıyla oluşturuldu ve oturum açıldı!'
                        : 'Hoş geldiniz! Giriş başarılı.',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
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
                ? 'Bu e-posta adresi zaten kayıtlı veya bilgiler geçersiz.'
                : 'Hatalı e-posta adresi veya şifre girdiniz.';
          } else if (errStr.contains('SocketException') || errStr.contains('Connection refused')) {
            _errorMessage = 'Sunucuya bağlanılamadı. Lütfen sunucu ayarlarından bağlantıyı kontrol edin.';
          } else {
            _errorMessage = 'Bağlantı hatası: PocketBase sunucusunun çalıştığından emin olun.';
          }
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderStroke),
        ),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppColors.primaryAccent, size: 22),
            const SizedBox(width: 10),
            Text(
              'Şifre Sıfırlama',
              style: AppTypography.headline3.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Kendi sunucunuzda (self-hosted PocketBase) şifrenizi sıfırlamak için PocketBase Admin paneline gidip kullanıcı kaydını güncelleyebilir veya yeni bir şifre belirleyebilirsiniz.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Anladım',
              style: AppTypography.buttonSecondary.copyWith(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverDomain = Uri.tryParse(_client.serverUrl)?.host ?? _client.serverUrl;

    return Scaffold(
      backgroundColor: AppColors.canvasBase,
      body: Stack(
        children: [
          // Cinematic Top Radial Lighting Glow
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            height: 380,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryAccent.withValues(alpha: 0.14),
                    AppColors.cardSurface.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: Column(
              children: [
                // Top Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.cardSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderStroke, width: 0.8),
                          ),
                          padding: const EdgeInsets.all(10),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      // Server Connection Pill
                      GestureDetector(
                        onTap: () async {
                          await ServerSettingsSheet.show(context);
                          if (mounted) setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderStroke, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.functionalSuccess,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  serverDomain,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.tune_rounded,
                                size: 14,
                                color: AppColors.secondarySlate,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Server Settings Shortcut
                      IconButton(
                        onPressed: () async {
                          await ServerSettingsSheet.show(context);
                          if (mounted) setState(() {});
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.cardSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderStroke, width: 0.8),
                          ),
                          padding: const EdgeInsets.all(10),
                        ),
                        icon: const Icon(
                          Icons.dns_outlined,
                          size: 18,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form & Branding Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // Logo & Brand Header
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryAccent.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryAccent.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_movies_rounded,
                              color: AppColors.primaryAccent,
                              size: 32,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // App Title
                        Text(
                          'SCREENVAULT',
                          style: AppTypography.headline1.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Subtitle Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primaryAccent.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'OBSIDIAN CINEMA & TV TRACKER',
                            style: AppTypography.labelCode.copyWith(
                              fontSize: 10,
                              color: AppColors.primaryAccent,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _isRegisterMode
                              ? 'Hesabınızı oluşturun, izleme geçmişinizi bulutta güvenle saklayın.'
                              : 'Kişisel dizi & film kasanıza giriş yapın.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Segmented Animated Tab Selector (Giriş Yap / Kayıt Ol)
                        Container(
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderStroke, width: 1),
                          ),
                          child: Stack(
                            children: [
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeInOutCubic,
                                alignment: _isRegisterMode ? Alignment.centerRight : Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 0.5,
                                  heightFactor: 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primaryAccent.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        if (_isRegisterMode) {
                                          setState(() {
                                            _isRegisterMode = false;
                                            _errorMessage = null;
                                          });
                                        }
                                      },
                                      child: Center(
                                        child: Text(
                                          'Giriş Yap',
                                          style: AppTypography.buttonSecondary.copyWith(
                                            color: !_isRegisterMode
                                                ? AppColors.primaryAccent
                                                : AppColors.textSecondary,
                                            fontWeight: !_isRegisterMode
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        if (!_isRegisterMode) {
                                          setState(() {
                                            _isRegisterMode = true;
                                            _errorMessage = null;
                                          });
                                        }
                                      },
                                      child: Center(
                                        child: Text(
                                          'Kayıt Ol',
                                          style: AppTypography.buttonSecondary.copyWith(
                                            color: _isRegisterMode
                                                ? AppColors.primaryAccent
                                                : AppColors.textSecondary,
                                            fontWeight: _isRegisterMode
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Form Inputs
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full Name (Only on Register)
                            if (_isRegisterMode) ...[
                              Text(
                                'AD SOYAD VEYA KULLANICI ADI',
                                style: AppTypography.labelCodeSmall.copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              _buildInputField(
                                controller: _nameController,
                                hintText: 'Örn: Umut Aktepe',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email Field
                            Text(
                              'E-POSTA ADRESİ',
                              style: AppTypography.labelCodeSmall.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            _buildInputField(
                              controller: _emailController,
                              hintText: 'ornek@screenvault.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.alternate_email_rounded,
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ŞİFRE',
                                  style: AppTypography.labelCodeSmall.copyWith(fontSize: 11),
                                ),
                                if (!_isRegisterMode)
                                  GestureDetector(
                                    onTap: _showForgotPasswordDialog,
                                    child: Text(
                                      'Şifremi Unuttum',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.primaryAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildInputField(
                              controller: _passwordController,
                              hintText: '••••••••',
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.secondarySlate,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              onChanged: (_) {
                                if (_isRegisterMode) setState(() {});
                              },
                            ),

                            // Password length indicator on Register
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    _passwordController.text.length >= 8
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 14,
                                    color: _passwordController.text.length >= 8
                                        ? AppColors.functionalSuccess
                                        : AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'En az 8 karakter uzunluğunda olmalı',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: _passwordController.text.length >= 8
                                          ? AppColors.functionalSuccess
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Password Confirm (Only on Register)
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 16),
                              Text(
                                'ŞİFRE TEKRARI',
                                style: AppTypography.labelCodeSmall.copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              _buildInputField(
                                controller: _confirmPasswordController,
                                hintText: '••••••••',
                                obscureText: _obscureConfirmPassword,
                                prefixIcon: Icons.lock_reset_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.secondarySlate,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                            ],

                            // Remember Me (Only on Login)
                            if (!_isRegisterMode) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                        activeColor: AppColors.primaryAccent,
                                        checkColor: Colors.black,
                                        side: const BorderSide(color: AppColors.borderStroke, width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Beni hatırla',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Error Alert
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.7), width: 0.8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.errorRed,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 26),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryAccent,
                                  foregroundColor: AppColors.textOnAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppColors.primaryAccent.withValues(alpha: 0.4),
                                ),
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation(Colors.black),
                                        ),
                                      )
                                    : Icon(
                                        _isRegisterMode ? Icons.person_add_rounded : Icons.login_rounded,
                                        size: 20,
                                        color: AppColors.textOnAccent,
                                      ),
                                label: Text(
                                  _isLoading
                                      ? 'Lütfen Bekleyin...'
                                      : (_isRegisterMode ? 'Hesap Oluştur & Giriş Yap' : 'Giriş Yap'),
                                  style: AppTypography.buttonPrimary.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                    color: AppColors.textOnAccent,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Switch Mode Footer Text
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isRegisterMode = !_isRegisterMode;
                                    _errorMessage = null;
                                  });
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: _isRegisterMode
                                        ? 'Zaten bir hesabınız var mı? '
                                        : 'Henüz hesabınız yok mu? ',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _isRegisterMode ? 'Giriş Yap' : 'Hemen Kayıt Ol',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.primaryAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Guest / Continue Offline Option
                            Center(
                              child: TextButton.icon(
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.textTertiary,
                                ),
                                label: Text(
                                  'Giriş Yapmadan Devam Et (Yerel Mod)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStroke, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: Icon(prefixIcon, color: AppColors.secondarySlate, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
