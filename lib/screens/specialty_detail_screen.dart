import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/specialty_score_service.dart';
import '../theme/app_theme.dart';

/// Branş detay ekranı — Hero animasyonlu görsel başlık + puan/tavsiye içeriği.
class SpecialtyDetailScreen extends StatelessWidget {
  final String branchName;

  /// Hero tag'i dış kaynakla eşleşmelidir: 'specialty_hero_$branchName'
  const SpecialtyDetailScreen({super.key, required this.branchName});

  @override
  Widget build(BuildContext context) {
    final imagePath = SpecialtyScoreService.getImagePath(branchName);
    final score = SpecialtyScoreService().getScoreFor(branchName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.background : Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Görselli AppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 60),
              title: Text(
                branchName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              background: Hero(
                tag: 'specialty_hero_$branchName',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(imagePath, fit: BoxFit.cover, cacheWidth: 800),
                    // Vignette gradient — metin okunabilirliği
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.35, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── İçerik ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (score != null) ...[
                    // Zorluk + Ortalama puan
                    Row(
                      children: [
                        _DifficultyBadge(difficulty: score.difficulty),
                        const SizedBox(width: 10),
                        _ScoreChip(score: score.averageScore),
                      ],
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),

                    // Ortalama puan çubuğu
                    _buildScoreBar(score.averageScore, isDark),
                    const SizedBox(height: 24),

                    // Tavsiye kartı
                    _buildAdviceCard(score.advice, isDark),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Skor verisi yok
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Bu branş için detaylı TUS verisi henüz eklenmedi.',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Çalışma ipuçları
                  _buildStudyTipsCard(branchName, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(double score, bool isDark) {
    final pct = (score / 100).clamp(0.0, 1.0);
    final barColor = score >= 70
        ? AppTheme.error
        : score >= 60
            ? AppTheme.neonGold
            : AppTheme.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TUS 2024 Ortalama Yerleşme Puanı',
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              score.toStringAsFixed(1),
              style: GoogleFonts.inter(
                color: barColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: barColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [barColor.withValues(alpha: 0.8), barColor],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildAdviceCard(String advice, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonPurple.withValues(alpha: 0.10),
            AppTheme.neonPurple.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: AppTheme.neonPurple, size: 16),
              const SizedBox(width: 8),
              Text(
                'UZMAN TAVSİYESİ',
                style: GoogleFonts.inter(
                  color: AppTheme.neonPurple,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advice,
            style: GoogleFonts.inter(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.black87,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildStudyTipsCard(String branch, bool isDark) {
    final tips = _getTips(branch);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surface.withValues(alpha: 0.6)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  color: AppTheme.cyan, size: 16),
              const SizedBox(width: 8),
              Text(
                'ÇALIŞMA İPUÇLARI',
                style: GoogleFonts.inter(
                  color: AppTheme.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: const BoxDecoration(
                      color: AppTheme.cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.inter(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.08, end: 0);
  }

  List<String> _getTips(String branch) {
    final lower = branch.toLowerCase();
    if (lower.contains('dahiliye') || lower.contains('ic hastali')) {
      return [
        'Günde en az 20 vaka sorusu çöz',
        'SM-2 kartlarını atlamadan tekrar et',
        'Organ sistemleri bazında organize çalış',
      ];
    } else if (lower.contains('cerrahi')) {
      return [
        'Anatomi temelini güçlendir',
        'Vaka çözme hızını artır',
        'Komplikasyon yönetimi sorularına odaklan',
      ];
    } else if (lower.contains('çocuk') || lower.contains('pediatri')) {
      return [
        'Yaşa göre normal değerleri ezberle',
        'Gelişimsel kilometre taşlarına hak',
        'Neonatoloji sorularına ekstra ağırlık ver',
      ];
    } else if (lower.contains('radyo') || lower.contains('nükleer')) {
      return [
        'Görüntü okuma pratiği yap',
        'Modalite seçimi sorularını tekrar et',
        'Klinik endikasyonları bil',
      ];
    }
    return [
      'Her gün düzenli tekrar yap',
      'Zayıf konularını AI analiz ile tespit et',
      'Spaced repetition ile kalıcı öğren',
    ];
  }
}

// ── Yardımcı Widget'lar ────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final lower = difficulty.toLowerCase();
    final color = lower.contains('cok yuksek')
        ? AppTheme.error
        : lower.contains('yuksek')
            ? AppTheme.neonGold
            : lower.contains('orta')
                ? AppTheme.success
                : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            difficulty.replaceAll('Cok Yuksek', 'Çok Yüksek')
                .replaceAll('Yuksek', 'Yüksek')
                .replaceAll('Dusuk', 'Düşük'),
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final double score;
  const _ScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: AppTheme.cyan, size: 14),
          const SizedBox(width: 6),
          Text(
            'Ort. ${score.toStringAsFixed(1)} net',
            style: GoogleFonts.inter(
              color: AppTheme.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
