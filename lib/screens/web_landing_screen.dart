import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  WebLandingScreen — deploy_klinoi/index.html tasarımına sadık Flutter   ║
// ║  Nav → Hero (icon+badge+gradient H1+3 buton) → Features (6 kart)       ║
// ║  → Stats (3 kart) → CTA kutusu → Footer                                ║
// ╚══════════════════════════════════════════════════════════════════════════╝

const _kBg       = Color(0xFF0A0E14);
const _kSurface  = Color(0xFF12161E);
const _kBorder   = Color(0xFF1E2533);
const _kCyan     = Color(0xFF00D4FF);
const _kPurple   = Color(0xFFA855F7);
const _kTextPri  = Color(0xFFF0F6FC);
const _kTextSec  = Color(0xFF7B8BA3);

class WebLandingScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const WebLandingScreen({super.key, required this.onContinue});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  final _scrollCtrl  = ScrollController();
  final _featuresKey = GlobalKey();
  final _statsKey    = GlobalKey();
  final _downloadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide   = w > 768;
    final isNarrow = w < 640;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Arka plan glow efektleri ─────────────────────────────────
          _BgGlow(),

          // ── Sayfa içeriği ────────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildNav(isWide),
                      _buildHero(isNarrow),
                      _buildFeatures(isWide, isNarrow),
                      _buildStats(isNarrow),
                      _buildCta(isNarrow),
                      _buildFooter(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nav ──────────────────────────────────────────────────────────────────

  Widget _buildNav(bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/hero_splash.jpg',
                  width: 42, height: 42,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TUS Asistanı',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kTextPri,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Nav links — sadece geniş ekranda
          if (isWide) ...[
            _NavLink('Özellikler',    () => _scrollTo(_featuresKey)),
            const SizedBox(width: 32),
            _NavLink('İstatistikler', () => _scrollTo(_statsKey)),
            const SizedBox(width: 32),
            _NavLink('İndir',         () => _scrollTo(_downloadKey)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  // ── Hero ─────────────────────────────────────────────────────────────────

  Widget _buildHero(bool isNarrow) {
    final iconSize = isNarrow ? 110.0 : 140.0;
    final iconRadius = isNarrow ? 26.0 : 32.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isNarrow ? 60 : 80),
      child: Column(
        children: [
          // Simge + glow
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) {
              final t = _pulseCtrl.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Radial glow halkası
                  Container(
                    width: iconSize + 40 + t * 10,
                    height: iconSize + 40 + t * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _kCyan.withValues(alpha: 0.25 * (0.6 + t * 0.4)),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  // İkon
                  child!,
                ],
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(iconRadius),
                border: Border.all(color: _kCyan.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(color: _kCyan.withValues(alpha: 0.20), blurRadius: 40),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 60, offset: const Offset(0, 20)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(iconRadius),
                child: Image.asset(
                  'assets/images/hero_splash.jpg',
                  width: iconSize, height: iconSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 36),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: _kCyan.withValues(alpha: 0.08),
              border: Border.all(color: _kCyan.withValues(alpha: 0.20)),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Yapay Zeka Destekli',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: _kCyan,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 28),

          // H1
          Column(
            children: [
              Text(
                'TUS Hazırlığında',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: _clampFont(36, 60, MediaQuery.of(context).size.width),
                  fontWeight: FontWeight.w800,
                  color: _kTextPri,
                  height: 1.1,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_kCyan, _kPurple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  'Akıllı Asistanın',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: _clampFont(36, 60, MediaQuery.of(context).size.width),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.06, end: 0),

          const SizedBox(height: 20),

          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Flashcard\'lar, vaka analizleri, yapay zeka destekli açıklamalar ve pomodoro zamanlayıcı ile TUS\'a en etkili şekilde hazırlanın.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: _kTextSec,
                height: 1.6,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 40),

          // Butonlar
          Wrap(
            spacing: 16,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              // Birincil — Uygulamayı İndir
              _PrimaryBtn(
                label: 'Uygulamayı İndir',
                onTap: () => _scrollTo(_downloadKey),
              ),
              // Web butonu
              _WebBtn(
                label: 'Web\'den Devam Et',
                onTap: widget.onContinue,
              ),
              // İkincil
              _SecondaryBtn(
                label: 'Özellikleri Gör',
                onTap: () => _scrollTo(_featuresKey),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.06, end: 0),
        ],
      ),
    );
  }

  // ── Özellikler ────────────────────────────────────────────────────────────

  Widget _buildFeatures(bool isWide, bool isNarrow) {
    final cols = isWide ? 3 : (isNarrow ? 1 : 2);
    final features = _featureData();

    return Container(
      key: _featuresKey,
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          Text(
            'Neden TUS Asistanı?',
            style: GoogleFonts.outfit(
              fontSize: 32, fontWeight: FontWeight.w700,
              color: _kTextPri,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tıpta uzmanlık sınavına hazırlanmanın en akıllı yolu',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: _kTextSec),
          ),
          const SizedBox(height: 48),

          // Grid
          LayoutBuilder(builder: (_, constraints) {
            final cardW = (constraints.maxWidth - (cols - 1) * 20) / cols;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: features.asMap().entries.map((e) {
                return SizedBox(
                  width: cardW,
                  child: _FeatureCard(
                    emoji: e.value.$1,
                    title: e.value.$2,
                    desc:  e.value.$3,
                    delay: 200 + e.key * 80,
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  List<(String, String, String)> _featureData() => [
    ('📚', 'Akıllı Flashcard\'lar',
        'Binlerce TUS kartı ile Tinder-tarzı swipe mekanizması. Cloze formatı ile aktif öğrenme.'),
    ('🔄', 'Akıllı Tekrar (Spaced Repetition)',
        'SM-2 algoritması ile aralıklı tekrar. Tam unutmak üzereyken kartlar karşınıza çıkarılır.'),
    ('🎯', 'Vaka Analizleri',
        'Gerçekçi klinik vakalarla pratik yapın. TUS\'ta çıkan vaka stilinde sorular.'),
    ('🎧', 'Focus Lab — Odak Sesleri',
        'Dikkat dağıtıcı unsurlardan uzaklaşın. Konsantrasyonunuzu zirveye taşıyan odak ortamı.'),
    ('🧠', 'AI Destekli Eksik Kapatma',
        'Sadece soru çözmeyin, eksiklerinizi de görün! Zayıf konu odaklı kişiselleştirilmiş çalışma.'),
    ('🏆', 'Günlük Hedefler ve Freemium',
        'Her güne özel ücretsiz günlük kota ile disiplin kazanın. Premium ile sınırsız erişim.'),
  ];

  // ── İstatistikler ─────────────────────────────────────────────────────────

  Widget _buildStats(bool isNarrow) {
    final stats = [
      ('2000+', 'Flashcard'),
      ('15+',   'Tıbbi Branş'),
      ('AI',    'Destekli Açıklamalar'),
    ];

    return Container(
      key: _statsKey,
      padding: const EdgeInsets.only(bottom: 80),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: stats.asMap().entries.map((e) {
          return _StatCard(
            number: e.value.$1,
            label:  e.value.$2,
            delay:  200 + e.key * 100,
          );
        }).toList(),
      ),
    );
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  Widget _buildCta(bool isNarrow) {
    return Container(
      key: _downloadKey,
      padding: const EdgeInsets.only(bottom: 100),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 24 : 40,
          vertical: isNarrow ? 40 : 60,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF000D14), Color(0xFF0D0919)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: _kCyan.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(
              'Hemen Başlayın',
              style: GoogleFonts.outfit(
                fontSize: 28, fontWeight: FontWeight.w700,
                color: _kTextPri,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'TUS Asistanı yakın zamanda Google Play ve App Store\'da!',
              style: GoogleFonts.inter(fontSize: 15, color: _kTextSec, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                _PrimaryBtn(label: 'Google Play (Yakında)', onTap: () {}),
                _SecondaryBtn(label: 'App Store (Yakında)',  onTap: () {}),
                _WebBtn(label: 'Web\'den Devam Et', onTap: widget.onContinue),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _FooterLink('Gizlilik Politikası', () {}),
              _FooterLink('Kullanım Koşulları',  () {}),
              _FooterLink('Hesap Silme Talebi',  () {}),
              _FooterLink('İletişim',             () {}),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '© 2026 TUS Asistanı. Tüm hakları saklıdır.',
            style: GoogleFonts.inter(fontSize: 13, color: _kTextSec),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

// ── Yardımcı fonksiyon ─────────────────────────────────────────────────────

double _clampFont(double min, double max, double screenW) {
  final vw = screenW * 0.06;
  return vw.clamp(min, max);
}

// ── Arka plan glow ─────────────────────────────────────────────────────────

class _BgGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Üst-merkez cyan glow
            Positioned(
              top: -200,
              left: size.width / 2 - 400,
              child: Container(
                width: 800, height: 600,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _kCyan.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0, 1],
                  ),
                  shape: BoxShape.circle,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
            // Alt-sağ purple glow
            Positioned(
              bottom: -150,
              right: -100,
              child: Container(
                width: 500, height: 500,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _kPurple.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Butonlar ───────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kCyan, Color(0xFF0090B3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kCyan.withValues(alpha: _hovered ? 0.35 : 0.25),
                blurRadius: _hovered ? 32 : 24,
                offset: Offset(0, _hovered ? 12 : 8),
              ),
            ],
          ),
          transform: _hovered
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _WebBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _WebBtn({required this.label, required this.onTap});

  @override
  State<_WebBtn> createState() => _WebBtnState();
}

class _WebBtnState extends State<_WebBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [
                      _kCyan.withValues(alpha: 0.20),
                      _kPurple.withValues(alpha: 0.15),
                    ]
                  : [
                      _kCyan.withValues(alpha: 0.12),
                      _kPurple.withValues(alpha: 0.10),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _kCyan.withValues(alpha: _hovered ? 0.50 : 0.35),
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: _kCyan.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))]
                : [],
          ),
          transform: _hovered
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, color: _kCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: _kCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryBtn({required this.label, required this.onTap});

  @override
  State<_SecondaryBtn> createState() => _SecondaryBtnState();
}

class _SecondaryBtnState extends State<_SecondaryBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? _kCyan.withValues(alpha: 0.20)
                  : _kBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: _kTextPri,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Özellik Kartı ──────────────────────────────────────────────────────────

class _FeatureCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String desc;
  final int delay;
  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.delay,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? _kCyan.withValues(alpha: 0.25) : _kBorder,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 40, offset: const Offset(0, 12))]
              : [],
        ),
        transform: _hovered
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x1F00D4FF),  // cyan 12%
                    Color(0x14A855F7),  // purple 8%
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(widget.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: _kTextPri,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.desc,
              style: GoogleFonts.inter(
                fontSize: 14, color: _kTextSec, height: 1.7,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.delay)).slideY(begin: 0.05, end: 0);
  }
}

// ── İstatistik Kartı ───────────────────────────────────────────────────────

class _StatCard extends StatefulWidget {
  final String number;
  final String label;
  final int delay;
  const _StatCard({required this.number, required this.label, required this.delay});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? _kCyan.withValues(alpha: 0.20) : _kBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_kCyan, _kPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                widget.number,
                style: GoogleFonts.outfit(
                  fontSize: 42, fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: GoogleFonts.inter(fontSize: 14, color: _kTextSec),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.delay)).scale(begin: const Offset(0.95, 0.95));
  }
}

// ── Nav Link ───────────────────────────────────────────────────────────────

class _NavLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _NavLink(this.text, this.onTap);

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: _hovered ? _kCyan : _kTextSec,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}

// ── Footer Link ────────────────────────────────────────────────────────────

class _FooterLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _FooterLink(this.text, this.onTap);

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _hovered ? _kCyan : _kTextSec,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
