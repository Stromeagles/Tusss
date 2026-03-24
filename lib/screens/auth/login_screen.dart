import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import '../../auth/auth_view_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'forgot_password_screen.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/social_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _pwCtrl       = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Submit handler ────────────────────────────────────────────────────────
  Future<void> _onSubmit(AuthViewModel vm) async {
    await vm.submit();
    if (!mounted) return;
    if (vm.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    }
  }

  // ── Firebase Social Sign-In ──────────────────────────────────────────────
  Future<void> _signInWithGoogle(BuildContext ctx) async {
    try {
      await AuthService.instance.signInWithGoogle();
      // AuthWrapper stream'i otomatik olarak HomeScreen'e yonlendirecek
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Google girisi basarisiz: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _signInWithApple(BuildContext ctx) async {
    try {
      await AuthService.instance.signInWithApple();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Apple girisi basarisiz: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Scaffold ve arka plan statik — Consumer sadece form içeriğini kapsar.
    // Her tuş vuruşunda tüm ekranın rebuild edilmesi önlenir.
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Consumer<AuthViewModel>(
                  builder: (context, vm, _) {
                    if (kIsWeb || constraints.maxWidth >= 900) {
                      return _buildDesktopLayout(vm);
                    }
                    return _buildMobileLayout(vm, constraints);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Desktop: iki sütun ────────────────────────────────────────────────────
  Widget _buildDesktopLayout(AuthViewModel vm) {
    return Row(
      children: [
        // Sol: hero görsel
        Expanded(
          flex: 55,
          child: _buildHeroPanel(vm),
        ),
        // İnce ayırıcı çizgi
        Container(
          width: 1,
          color: AppTheme.cyan.withValues(alpha: 0.10),
        ),
        // Sağ: form paneli
        Expanded(
          flex: 45,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.85),
              border: Border(
                left: BorderSide(color: AppTheme.cyan.withValues(alpha: 0.08)),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDesktopFormHeader(vm),
                        const SizedBox(height: 32),
                        _buildFormContent(vm),
                        const SizedBox(height: 28),
                        _buildBottomToggle(vm),
                        if (kIsWeb) ...[
                          const SizedBox(height: 40),
                          _buildStoreButtons(),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile: tek sütun ────────────────────────────────────────────────────
  Widget _buildMobileLayout(AuthViewModel vm, BoxConstraints constraints) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).padding.top + 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMobileHeader(vm),
              const SizedBox(height: 32),
              _buildGlassCard(vm),
              const SizedBox(height: 20),
              _buildBottomToggle(vm),
              if (kIsWeb) ...[
                const SizedBox(height: 40),
                _buildStoreButtons(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Base gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF0B1222),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          // Coral glow top-left
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.cyan.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Purple glow bottom-right
          Positioned(
            bottom: -60,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.neonPurple.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Tıbbi ikon deseni — çok hafif, dekoratif
          ..._medicalIcons(),
        ],
      ),
    );
  }

  /// Arka planda scatter edilmiş tıbbi ikonlar
  List<Widget> _medicalIcons() {
    Widget medIcon(IconData data, double size) => Opacity(
          opacity: 0.045,
          child: Icon(data, size: size, color: Colors.white),
        );
    return [
      Positioned(top:  80, left:  30, child: medIcon(Icons.favorite_border_rounded,    22)),
      Positioned(top: 160, right: 20, child: medIcon(Icons.add_circle_outline_rounded, 16)),
      Positioned(top: 280, left:  15, child: medIcon(Icons.biotech_outlined,           20)),
      Positioned(top: 420, right: 35, child: medIcon(Icons.medication_outlined,        18)),
      Positioned(top: 550, left:  40, child: medIcon(Icons.science_outlined,           14)),
      Positioned(top: 650, right: 25, child: medIcon(Icons.psychology_outlined,        24)),
      Positioned(top: 750, left:  25, child: medIcon(Icons.monitor_heart_outlined,     18)),
    ];
  }

  // ── Desktop sol panel: tam ekran hero ────────────────────────────────────
  Widget _buildHeroPanel(AuthViewModel vm) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/hero_login.jpg', fit: BoxFit.cover, cacheWidth: 1200),
        // Sağa doğru gradient — form paneliyle geçiş
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                AppTheme.surface.withValues(alpha: 0.25),
              ],
            ),
          ),
        ),
        // Alt gradient — yazı okunabilirliği
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        // Sol alt: logo + tagline
        Positioned(
          bottom: 40,
          left: 40,
          right: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AsisTus',
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TUS\'a hazırlığın en akıllı yolu.\nAI destekli, kişiselleştirilmiş öğrenme.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
        ),
      ],
    ).animate().fadeIn(duration: 700.ms);
  }

  // ── Desktop form başlığı ──────────────────────────────────────────────────
  Widget _buildDesktopFormHeader(AuthViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vm.mode == AuthMode.login ? 'Tekrar Hoş Geldin 👋' : 'Hesap Oluştur 🚀',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          vm.mode == AuthMode.login
              ? 'Devam etmek için giriş yap.'
              : 'Birkaç adımda TUS hazırlığına başla.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  // ── Mobile header: logo + başlık ─────────────────────────────────────────
  Widget _buildMobileHeader(AuthViewModel vm) {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.cyan, AppTheme.neonPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: 0.40),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.psychology_rounded, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'AsisTus',
          style: GoogleFonts.outfit(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.cyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.30)),
          ),
          child: Text(
            vm.mode == AuthMode.login ? 'Tekrar Hoş Geldin 👋' : 'Hesap Oluştur 🚀',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.cyan,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.08, end: 0);
  }

  // ── Form içeriği (login/signup) ───────────────────────────────────────────
  Widget _buildFormContent(AuthViewModel vm) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: vm.mode == AuthMode.login
          ? _LoginForm(
              key: const ValueKey('login'),
              vm: vm,
              emailCtrl: _emailCtrl,
              pwCtrl: _pwCtrl,
              onSubmit: () => _onSubmit(vm),
              onGoogleSignIn: () => _signInWithGoogle(context),
              onAppleSignIn: () => _signInWithApple(context),
            )
          : _SignupForm(
              key: const ValueKey('signup'),
              vm: vm,
              nameCtrl: _nameCtrl,
              emailCtrl: _emailCtrl,
              pwCtrl: _pwCtrl,
              confirmCtrl: _confirmCtrl,
              onSubmit: () => _onSubmit(vm),
            ),
    );
  }

  // ── Glass card (mobile only) ──────────────────────────────────────────────
  Widget _buildGlassCard(AuthViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: _buildFormContent(vm),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.15, end: 0, delay: 300.ms, duration: 600.ms, curve: Curves.easeOutQuart);
  }

  // ── Bottom toggle ─────────────────────────────────────────────────────────
  Widget _buildBottomToggle(AuthViewModel vm) {
    final isLogin = vm.mode == AuthMode.login;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? 'Hesabın yok mu?' : 'Zaten üyesin?',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: vm.isLoading ? null : vm.toggleMode,
          child: Text(
            isLogin ? 'Kayıt Ol' : 'Giriş Yap',
            style: GoogleFonts.inter(
              color: AppTheme.cyan,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 400.ms);
  }

  // ── Store buttons (Web only) ──────────────────────────────────────────────
  Widget _buildStoreButtons() {
    return Column(
      children: [
        Text(
          'Uygulamayı İndirin',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StoreButton(
              icon: Icons.apple_rounded,
              label: 'App Store',
              onTap: () {
                // TODO: App Store linki eklenecek
              },
            ),
            const SizedBox(width: 16),
            _StoreButton(
              icon: Icons.shop_rounded,
              label: 'Google Play',
              onTap: () {
                // TODO: Google Play linki eklenecek
              },
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LOGIN FORM
// ═══════════════════════════════════════════════════════════════════════════

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.vm,
    required this.emailCtrl,
    required this.pwCtrl,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  final AuthViewModel         vm;
  final TextEditingController emailCtrl;
  final TextEditingController pwCtrl;
  final VoidCallback          onSubmit;
  final Future<void> Function() onGoogleSignIn;
  final Future<void> Function() onAppleSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        AuthTextField(
          label: 'E-posta',
          hint: 'ornek@email.com',
          icon: Icons.email_outlined,
          controller: emailCtrl,
          errorText: vm.emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: vm.setEmail,
        ),
        const SizedBox(height: 16),

        // Password
        AuthTextField(
          label: 'Şifre',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          controller: pwCtrl,
          obscureText: vm.obscurePassword,
          errorText: vm.passwordError,
          textInputAction: TextInputAction.done,
          onChanged: vm.setPassword,
          suffix: IconButton(
            icon: Icon(
              vm.obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
            onPressed: vm.togglePasswordVisibility,
          ),
        ),
        const SizedBox(height: 10),

        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              );
            },
            child: Text(
              'Şifremi Unuttum',
              style: GoogleFonts.inter(
                color: AppTheme.cyan,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // General error
        if (vm.generalError != null) ...[
          _ErrorBanner(message: vm.generalError!),
          const SizedBox(height: 16),
        ],

        // Login button
        _GradientButton(
          label: 'GİRİŞ YAP',
          isLoading: vm.isLoading,
          onTap: onSubmit,
        ),
        const SizedBox(height: 24),

        // Divider
        _OrDivider(),
        const SizedBox(height: 20),

        // Social buttons
        SocialButton(
          label: 'Google ile Devam Et',
          icon: Icons.g_mobiledata_rounded,
          onTap: onGoogleSignIn,
        ),
        const SizedBox(height: 10),
        // Apple butonu sadece iOS/macOS'ta gosterilir
        if (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)
          SocialButton(
            label: 'Apple ile Devam Et',
            icon: Icons.apple_rounded,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            onTap: onAppleSignIn,
          ),
        if (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)
          const SizedBox(height: 10),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SIGNUP FORM
// ═══════════════════════════════════════════════════════════════════════════

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    super.key,
    required this.vm,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.pwCtrl,
    required this.confirmCtrl,
    required this.onSubmit,
  });

  final AuthViewModel         vm;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController pwCtrl;
  final TextEditingController confirmCtrl;
  final VoidCallback          onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name
        AuthTextField(
          label: 'Ad Soyad',
          hint: 'Ali Veli',
          icon: Icons.person_outline_rounded,
          controller: nameCtrl,
          errorText: vm.nameError,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onChanged: vm.setName,
        ),
        const SizedBox(height: 16),

        // Email
        AuthTextField(
          label: 'E-posta',
          hint: 'ornek@email.com',
          icon: Icons.email_outlined,
          controller: emailCtrl,
          errorText: vm.emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: vm.setEmail,
        ),
        const SizedBox(height: 16),

        // Password
        AuthTextField(
          label: 'Şifre',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          controller: pwCtrl,
          obscureText: vm.obscurePassword,
          errorText: vm.passwordError,
          textInputAction: TextInputAction.next,
          onChanged: vm.setPassword,
          suffix: IconButton(
            icon: Icon(
              vm.obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
            onPressed: vm.togglePasswordVisibility,
          ),
        ),
        const SizedBox(height: 8),

        // Password strength indicator
        if (vm.password.isNotEmpty)
          _PasswordStrengthBar(strength: vm.getPasswordStrength()),

        const SizedBox(height: 16),

        // Confirm password
        AuthTextField(
          label: 'Şifre Tekrar',
          hint: '••••••••',
          icon: Icons.lock_reset_rounded,
          controller: confirmCtrl,
          obscureText: vm.obscureConfirm,
          errorText: vm.confirmError,
          textInputAction: TextInputAction.done,
          onChanged: vm.setConfirmPassword,
          suffix: IconButton(
            icon: Icon(
              vm.obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
            onPressed: vm.toggleConfirmVisibility,
          ),
        ),
        const SizedBox(height: 20),

        // Terms checkbox
        _TermsCheckbox(vm: vm),
        const SizedBox(height: 16),

        // General error
        if (vm.generalError != null) ...[
          _ErrorBanner(message: vm.generalError!),
          const SizedBox(height: 12),
        ],

        // Signup button
        _GradientButton(
          label: 'HESAP OLUŞTUR',
          isLoading: vm.isLoading,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String     label;
  final bool       isLoading;
  final VoidCallback onTap;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? LinearGradient(
                    colors: [
                      AppTheme.cyan.withValues(alpha: 0.5),
                      AppTheme.neonPurple.withValues(alpha: 0.5),
                    ],
                  )
                : AppTheme.cyanGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.cyan.withValues(alpha: 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppTheme.divider),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});

  final PasswordStrength strength;

  Color get _color {
    switch (strength) {
      case PasswordStrength.weak:   return AppTheme.error;
      case PasswordStrength.medium: return AppTheme.warning;
      case PasswordStrength.strong: return AppTheme.success;
    }
  }

  String get _label {
    switch (strength) {
      case PasswordStrength.weak:   return 'Zayıf';
      case PasswordStrength.medium: return 'Orta';
      case PasswordStrength.strong: return 'Güçlü';
    }
  }

  int get _filledBars {
    switch (strength) {
      case PasswordStrength.weak:   return 1;
      case PasswordStrength.medium: return 2;
      case PasswordStrength.strong: return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 3 bars
        ...List.generate(3, (i) {
          final filled = i < _filledBars;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: filled
                      ? _color
                      : AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          _label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.vm});

  final AuthViewModel vm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => vm.setAcceptTerms(!vm.acceptTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom checkbox
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: vm.acceptTerms
                  ? AppTheme.cyan
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: vm.acceptTerms ? AppTheme.cyan : AppTheme.border,
                width: 1.5,
              ),
            ),
            child: vm.acceptTerms
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                children: const [
                  TextSpan(text: 'Okudum, '),
                  TextSpan(
                    text: 'Kullanım Koşulları',
                    style: TextStyle(
                      color: AppTheme.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' ve '),
                  TextSpan(
                    text: 'Gizlilik Politikası',
                    style: TextStyle(
                      color: AppTheme.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '\'nı kabul ediyorum.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppTheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
