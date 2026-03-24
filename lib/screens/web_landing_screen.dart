import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class WebLandingScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const WebLandingScreen({super.key, required this.onContinue});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Animasyonlu Arka Plan ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              final t = _bgController.value;
              return Stack(children: [
                Positioned(
                  top: -120 + t * 50,
                  right: -80 + t * 20,
                  child: _Blob(color: AppTheme.cyan, size: 480, opacity: 0.07),
                ),
                Positioned(
                  bottom: -80 + t * 40,
                  left: -80,
                  child: _Blob(color: AppTheme.neonPurple, size: 420, opacity: 0.07),
                ),
                Positioned(
                  top: size.height * 0.4 - t * 20,
                  left: size.width * 0.35,
                  child: _Blob(color: AppTheme.neonGold, size: 220, opacity: 0.035),
                ),
              ]);
            },
          ),

          // ── Sayfa İçeriği ─────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 40 : 22,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLogoRow(),
                        const SizedBox(height: 40),
                        _buildHero(size),
                        const SizedBox(height: 36),
                        _buildHeadline(),
                        const SizedBox(height: 32),
                        _buildStats(),
                        const SizedBox(height: 28),
                        isWide ? _buildFeaturesGrid() : _buildFeaturesList(),
                        const SizedBox(height: 36),
                        _buildPrimaryButton(),
                        const SizedBox(height: 14),
                        _buildStoreRow(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/hero_splash.jpg',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'AsisTus',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4FF), Color(0xFFA371F7)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'AI Destekli',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildHero(Size size) {
    final heroH = (size.height * 0.38).clamp(200.0, 340.0);
    return Container(
      width: double.infinity,
      height: heroH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyan.withValues(alpha: 0.18),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/hero_splash.jpg', fit: BoxFit.cover, cacheWidth: 1200),
            // Koyu alt gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.background.withValues(alpha: 0.75),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            // Hafif üst gradient (kenar yumuşatma)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Alt badge
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cyan.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.cyan, size: 14),
                    const SizedBox(width: 7),
                    Text(
                      'Spaced Repetition + AI',
                      style: GoogleFonts.inter(
                        color: AppTheme.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sağ alt — küçük istatistik pill
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.style_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '10.000+ kart',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 700.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildHeadline() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00D4FF), Color(0xFFFFFFFF), Color(0xFFA371F7)],
            stops: [0.0, 0.45, 1.0],
          ).createShader(bounds),
          child: Text(
            'TUS\'a Hazırlık\nArtık Daha Akıllı',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1.2,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08, end: 0),
        const SizedBox(height: 16),
        Text(
          'Binlerce TUS sorusu, klinik vaka ve AI destekli\nakıllı tekrar sistemi — her gün biraz daha güçlen.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.65,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildStats() {
    final stats = [
      (Icons.style_rounded,    '10.000+', 'Soru & Kart',    AppTheme.cyan),
      (Icons.psychology_rounded,'AI',      'Kişisel Mentor', AppTheme.neonPurple),
      (Icons.repeat_rounded,   'SM-2',    'Tekrar Motoru',  AppTheme.neonGold),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.border.withValues(alpha: 0.5),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(s.$1, color: s.$4, size: 18),
                      const SizedBox(height: 6),
                      Text(
                        s.$2,
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: s.$4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.$3,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildFeaturesGrid() {
    final features = [
      (Icons.psychology_rounded,    'AI Açıklamaları', 'Her soruya uzman anlatımı',   AppTheme.neonPurple),
      (Icons.repeat_rounded,        'Akıllı Tekrar',   'SM-2 ile güçlü hafıza',        AppTheme.cyan),
      (Icons.local_hospital_rounded,'Klinik Vakalar',  'Gerçek TUS tarzı vakalar',     AppTheme.success),
      (Icons.bookmark_rounded,      'Favoriler',       'Zor soruları kaydet & tekrar', AppTheme.neonGold),
    ];
    return Column(
      children: [
        Row(children: [
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _FeatureCard(f: features[0], delay: 520))),
          Expanded(child: _FeatureCard(f: features[1], delay: 590)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _FeatureCard(f: features[2], delay: 660))),
          Expanded(child: _FeatureCard(f: features[3], delay: 730)),
        ]),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      (Icons.psychology_rounded,    'AI Açıklamaları', 'Her soruya uzman hoca anlatımı',    AppTheme.neonPurple),
      (Icons.repeat_rounded,        'Akıllı Tekrar',   'SM-2 algoritmasıyla güçlü hafıza',  AppTheme.cyan),
      (Icons.local_hospital_rounded,'Klinik Vakalar',  'Gerçek TUS tarzı hasta vakaları',   AppTheme.success),
      (Icons.bookmark_rounded,      'Favori Listesi',  'Zor soruları kaydet, tekrar çalış', AppTheme.neonGold),
    ];
    return Column(
      children: features.asMap().entries.map((e) =>
        Padding(padding: const EdgeInsets.only(bottom: 10),
          child: _FeatureCard(f: e.value, delay: 520 + e.key * 70))).toList(),
    );
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTap: widget.onContinue,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cyan.withValues(alpha: 0.38),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Hemen Başla — Ücretsiz',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildStoreRow() {
    return Row(
      children: [
        Expanded(
          child: _StoreBtn(
            icon: Icons.apple_rounded,
            label: 'App Store',
            sub: 'iPhone & iPad',
            color: AppTheme.textPrimary,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StoreBtn(
            icon: Icons.android_rounded,
            label: 'Google Play',
            sub: 'Android',
            color: const Color(0xFF3DDC84),
            onTap: () {},
          ),
        ),
      ],
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FooterLink('Gizlilik Politikası', () {}),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: AppTheme.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            _FooterLink('Kullanım Şartları', () {}),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© 2025 AsisTus — Tüm hakları saklıdır.',
          style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    ).animate().fadeIn(delay: 1050.ms);
  }
}

// ── Yardımcı Widget'lar ───────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final (IconData, String, String, Color) f;
  final int delay;
  const _FeatureCard({required this.f, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: f.$4.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: f.$4.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: f.$4.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(f.$1, color: f.$4, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.$2,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  f.$3,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.05, end: 0);
  }
}

class _StoreBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _StoreBtn({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(sub,   style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _FooterLink(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppTheme.textMuted,
          fontSize: 11,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.textMuted,
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _Blob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
