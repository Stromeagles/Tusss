import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Sınav Hazırlık Seviyesi paneli — HomeScreen ve AnalyticsScreen tarafından
/// ortak kullanılır.
class ReadinessCard extends StatelessWidget {
  /// 0.0 – 1.0 arası ham oran (gauge dolum değeri)
  final double readiness;

  /// 0–100 arası yüzde (readiness * 100)
  final int readinessPct;

  final Color gaugeColor;
  final String scoreIntensity;
  final double targetScore;
  final int recommendedDailyGoal;

  /// Hedef hakimiyet yüzdesi (targetScore'a göre belirlenir)
  final int masteryTarget;

  /// Mevcut hakimiyet yüzdesi (0–100)
  final int currentMastery;

  final int daysToExam;
  final bool isDark;

  const ReadinessCard({
    super.key,
    required this.readiness,
    required this.readinessPct,
    required this.gaugeColor,
    required this.scoreIntensity,
    required this.targetScore,
    required this.recommendedDailyGoal,
    required this.masteryTarget,
    required this.currentMastery,
    required this.daysToExam,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final surfaceBg = isDark
        ? AppTheme.surface.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.90);
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: gaugeColor.withValues(alpha: isDark ? 0.14 : 0.07),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Başlık satırı ──────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Sınav Hazırlık Seviyesi',
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: gaugeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gaugeColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '%$readinessPct',
                      style: GoogleFonts.outfit(
                        color: gaugeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Arc Gauge + merkez metin ───────────────────────────────
              Center(
                child: SizedBox(
                  width: 160,
                  height: 90,
                  child: CustomPaint(
                    painter: ReadinessGaugePainter(
                      value: readiness,
                      activeColor: gaugeColor,
                      bgColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.07),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '%$readinessPct',
                              style: GoogleFonts.outfit(
                                color: gaugeColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              scoreIntensity,
                              style: GoogleFonts.inter(
                                color: subColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Dinamik başlık ─────────────────────────────────────────
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 13, color: subColor, height: 1.4),
                  children: [
                    const TextSpan(text: 'Hedeflediğin '),
                    TextSpan(
                      text: '${targetScore.toStringAsFixed(0)} puan',
                      style: GoogleFonts.inter(
                        color: AppTheme.neonGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const TextSpan(text: ' için:'),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── 3 aksiyon satırı ───────────────────────────────────────
              ReadinessRow(
                emoji: '🎯',
                text: 'Günde ortalama ',
                highlight: '$recommendedDailyGoal soru/kart',
                suffix: ' çözmelisin.',
                color: AppTheme.cyan,
                isDark: isDark,
              ),
              const SizedBox(height: 7),
              ReadinessRow(
                emoji: '📊',
                text: 'Hakimiyetini ',
                highlight: '%$masteryTarget',
                suffix: ' üzerine çıkarmalısın (şu an: %$currentMastery).',
                color: AppTheme.neonPurple,
                isDark: isDark,
              ),
              const SizedBox(height: 7),
              ReadinessRow(
                emoji: '⏳',
                text: 'Sınava kalan ',
                highlight: '$daysToExam günü',
                suffix: ' bu tempoyla değerlendir.',
                color: AppTheme.neonGold,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutExpo);
  }
}

// ── Yardımcı: readiness verisi hesaplama ─────────────────────────────────────

/// Sınav hazırlık skoru ve bağlı değerleri hesaplar.
/// [masteryRatio] : öğrenilen kart / toplam görülen kart (0-1)
/// [dailyRatio]   : bugün çözülen / günlük hedef (0-1)
/// [streakRatio]  : mevcut seri / 30 (0-1)
ReadinessData computeReadiness({
  required double masteryRatio,
  required double dailyRatio,
  required double streakRatio,
  required double targetScore,
}) {
  final readiness =
      (masteryRatio * 0.40 + dailyRatio * 0.35 + streakRatio * 0.25)
          .clamp(0.0, 1.0);
  final readinessPct = (readiness * 100).round();

  final gaugeColor = readinessPct >= 70
      ? AppTheme.success
      : readinessPct >= 40
          ? AppTheme.cyan
          : readinessPct >= 20
              ? AppTheme.neonGold
              : AppTheme.error;

  final masteryTarget = targetScore >= 75
      ? 65
      : targetScore >= 65
          ? 55
          : targetScore >= 55
              ? 45
              : 35;
  final currentMastery = (masteryRatio * 100).round();

  return ReadinessData(
    readiness: readiness,
    readinessPct: readinessPct,
    gaugeColor: gaugeColor,
    masteryTarget: masteryTarget,
    currentMastery: currentMastery,
  );
}

class ReadinessData {
  final double readiness;
  final int readinessPct;
  final Color gaugeColor;
  final int masteryTarget;
  final int currentMastery;

  const ReadinessData({
    required this.readiness,
    required this.readinessPct,
    required this.gaugeColor,
    required this.masteryTarget,
    required this.currentMastery,
  });
}

// ── ReadinessRow ──────────────────────────────────────────────────────────────

class ReadinessRow extends StatelessWidget {
  final String emoji;
  final String text;
  final String highlight;
  final String suffix;
  final Color color;
  final bool isDark;

  const ReadinessRow({
    super.key,
    required this.emoji,
    required this.text,
    required this.highlight,
    required this.suffix,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sub = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 12, color: sub, height: 1.5),
              children: [
                TextSpan(text: text),
                TextSpan(
                  text: highlight,
                  style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                TextSpan(text: suffix),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── ReadinessGaugePainter ─────────────────────────────────────────────────────

/// Yarım daire arc gauge (CustomPainter)
class ReadinessGaugePainter extends CustomPainter {
  final double value; // 0.0 – 1.0
  final Color activeColor;
  final Color bgColor;

  ReadinessGaugePainter({
    required this.value,
    required this.activeColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;
    const strokeW = 11.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..color = bgColor,
    );

    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        3.14159,
        3.14159 * value.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..color = activeColor,
      );
    }
  }

  @override
  bool shouldRepaint(ReadinessGaugePainter old) =>
      old.value != value || old.activeColor != activeColor;
}
