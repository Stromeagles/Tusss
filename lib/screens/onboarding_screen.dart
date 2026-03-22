import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _PageData(
      title: 'Sıradan Bir Soru Bankası Değil',
      subtitle: 'Akıllı Tekrar Algoritması',
      body:
          'AsisTus, klasik soru bankalarından farklı olarak arkasında güçlü bir '
          'Aralıklı Tekrar (Spaced Repetition) motoru barındırır.\n\n'
          'Sadece bir branş seç ve çalışmaya başla. Sistem senin yerine düşünür:\n\n'
          '• Yanlış yaptığın sorular unutma eğrine göre tam zamanında tekrar gelir\n'
          '• Doğru bildiklerin giderek seyrekleşir — zamanını çalmaz\n'
          '• AI Asistan en zayıf konularını tespit edip sana özel plan sunar',
      icon: Icons.psychology_rounded,
      color: AppTheme.cyan,
    ),
    _PageData(
      title: 'Günlük Disiplin Kotası',
      subtitle: 'Ücretsiz Plan',
      body:
          'Her gün sana özel bir çalışma kotası ayrılır. '
          'Bu bir kısıtlama değil, bir disiplin aracıdır.\n\n'
          '• Her gün 50 flashcard + 50 soru hakkın var\n'
          '• Sistem önce "Yanlışlarını" ve "Tekrar Vakti Gelenleri" getirir\n'
          '• Kalan kotanla yeni konulara geçersin\n\n'
          'Düzenli çalışma alışkanlığı kazandıran bu sistem, '
          'TUS maratonunda seni her gün bir adım ileriye taşır.',
      icon: Icons.timer_rounded,
      color: AppTheme.neonGold,
    ),
    _PageData(
      title: 'Premium ile Sınırları Kaldır',
      subtitle: 'Neden Premium?',
      body: '',
      icon: Icons.workspace_premium_rounded,
      color: AppTheme.neonPurple,
      isPremiumPage: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080C12) : Colors.white,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -150, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _pages[_page].color.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      'Geç',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: page.isPremiumPage
                            ? _buildPremiumPage(isDark, page)
                            : _buildInfoPage(isDark, page),
                      );
                    },
                  ),
                ),

                // Dots + Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Row(
                    children: [
                      // Page dots
                      Row(
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 8),
                            width: _page == i ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _page == i
                                  ? _pages[_page].color
                                  : (isDark ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      // Next / Start button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (_page < _pages.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          } else {
                            widget.onComplete();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.symmetric(
                            horizontal: _page == _pages.length - 1 ? 28 : 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _pages[_page].color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_page].color.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            _page == _pages.length - 1 ? 'Başla' : 'Devam',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPage(bool isDark, _PageData page) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // Icon
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: page.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: page.color.withValues(alpha: 0.25)),
          ),
          child: Icon(page.icon, color: page.color, size: 34),
        ),
        const SizedBox(height: 28),
        // Subtitle
        Text(
          page.subtitle.toUpperCase(),
          style: GoogleFonts.inter(
            color: page.color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        // Title
        Text(
          page.title,
          style: GoogleFonts.outfit(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        // Body
        Text(
          page.body,
          style: GoogleFonts.inter(
            color: subColor,
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumPage(bool isDark, _PageData page) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.neonGold.withValues(alpha: 0.2), AppTheme.neonPurple.withValues(alpha: 0.15)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.neonGold, size: 34),
        ),
        const SizedBox(height: 28),
        Text(
          'NEDEN PREMİUM?',
          style: GoogleFonts.inter(
            color: AppTheme.neonGold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Premium ile\nSınırları Kaldır',
          style: GoogleFonts.outfit(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),

        _PremiumFeature(
          isDark: isDark,
          icon: Icons.all_inclusive_rounded,
          color: AppTheme.cyan,
          title: 'Sınırsız Erişim',
          body: 'Günlük kota kalkar. On binlerce kart ve soruya 7/24 sınırsız erişim.',
        ),
        _PremiumFeature(
          isDark: isDark,
          icon: Icons.bar_chart_rounded,
          color: AppTheme.neonPurple,
          title: 'Gidişat Analizi & Ustalık',
          body: 'Bir soruyu üst üste 3 kez doğru yapana kadar peşini bırakmayan sistemin ürettiği kişisel gelişim grafikleri.',
        ),
        _PremiumFeature(
          isDark: isDark,
          icon: Icons.psychology_rounded,
          color: const Color(0xFFFF9F0A),
          title: 'AI Eksik Kapatma Kampı',
          body: 'En zorlandığın konulardan sana özel üretilen analiz kampı. TUS puanını en hızlı yükseltecek özellik.',
        ),
        _PremiumFeature(
          isDark: isDark,
          icon: Icons.headphones_rounded,
          color: AppTheme.success,
          title: 'Focus Lab & Ortam Sesleri',
          body: 'Yağmur, kütüphane, kafe... Odaklanmanı artıran ortam sesleriyle kesintisiz çalışma seansları.',
        ),

        const SizedBox(height: 16),
        Text(
          'Premium yakında aktif olacak. Şimdilik ücretsiz planla başla!',
          style: GoogleFonts.inter(
            color: subColor,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _PageData {
  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final Color color;
  final bool isPremiumPage;

  const _PageData({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    required this.color,
    this.isPremiumPage = false,
  });
}

class _PremiumFeature extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _PremiumFeature({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
