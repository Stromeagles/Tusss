import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../../auth/auth_view_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
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

  // ── Guest handler ─────────────────────────────────────────────────────────
  Future<void> _onGuest(AuthViewModel vm) async {
    await vm.loginAsGuest();
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
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              // Background gradient
              _buildBackground(),
              // Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      // Logo area
                      _buildLogoArea(vm),
                      const SizedBox(height: 32),
                      // Glass card
                      _buildGlassCard(vm),
                      const SizedBox(height: 28),
                      // Bottom toggle
                      _buildBottomToggle(vm),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                  Color(0xFF0D1117),
                  Color(0xFF0A0E1A),
                  Color(0xFF0D1117),
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

  // ── Logo area ─────────────────────────────────────────────────────────────
  Widget _buildLogoArea(AuthViewModel vm) {
    return Column(
      children: [
        // Icon container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.cyanGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.psychology_rounded,
            color: Colors.white,
            size: 42,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: -0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // App name
        Text(
          'TUS Asistanı',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 6),

        // Subtitle
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            vm.mode == AuthMode.login ? 'Hoş geldiniz' : 'Hesap oluştur',
            key: ValueKey<AuthMode>(vm.mode),
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms),
      ],
    );
  }

  // ── Glass card ────────────────────────────────────────────────────────────
  Widget _buildGlassCard(AuthViewModel vm) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: vm.mode == AuthMode.login
                ? _LoginForm(
                    key: const ValueKey('login'),
                    vm: vm,
                    emailCtrl: _emailCtrl,
                    pwCtrl: _pwCtrl,
                    onSubmit: () => _onSubmit(vm),
                    onGuest: () => _onGuest(vm),
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
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 250.ms, duration: 500.ms)
        .slideY(begin: 0.15, end: 0, delay: 250.ms, duration: 500.ms, curve: Curves.easeOut);
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
    required this.onGuest,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  final AuthViewModel         vm;
  final TextEditingController emailCtrl;
  final TextEditingController pwCtrl;
  final VoidCallback          onSubmit;
  final VoidCallback          onGuest;
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Yakında!',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.surfaceVariant,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  duration: const Duration(seconds: 2),
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
        const SizedBox(height: 24),

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
        const SizedBox(height: 4),

        // Guest button
        OutlinedButton(
          onPressed: vm.isLoading ? null : onGuest,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.border, width: 1),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Misafir Olarak Giriş Yap',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
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
