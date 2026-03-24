import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mock_exam_model.dart';
import '../theme/app_theme.dart';
import 'mock_exam_setup_screen.dart';

class MockExamResultScreen extends StatelessWidget {
  final MockExamResult result;

  const MockExamResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    final netStr = result.netScore.toStringAsFixed(2);
    final accuracy = (result.accuracy * 100).toStringAsFixed(0);
    final grade = _gradeLabel(result.accuracy);
    final gradeColor = _gradeColor(result.accuracy);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF0A1628), Color(0xFF0F172A)]
                : const [Color(0xFFEDF3FF), Color(0xFFE8F0FF), Color(0xFFF0F5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Sınav ekranlarını stack'ten temizle
                        Navigator.of(context)
                            .popUntil((r) => r.isFirst);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.home_rounded,
                            color: textColor, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('Sınav Sonucu',
                        style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    children: [
                      // ── Ana skor kartı ──
                      _buildScoreCard(isDark, textColor, subColor, grade,
                          gradeColor, netStr, accuracy),
                      const SizedBox(height: 20),

                      // ── İstatistikler ──
                      _buildStatsRow(isDark, textColor, subColor),
                      const SizedBox(height: 20),

                      // ── Konu bazlı analiz ──
                      if (result.subjectBreakdown.isNotEmpty)
                        _buildSubjectBreakdown(
                            isDark, textColor, subColor),

                      const SizedBox(height: 24),

                      // ── Aksiyon butonları ──
                      _buildActions(context, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(bool isDark, Color textColor, Color subColor,
      String grade, Color gradeColor, String netStr, String accuracy) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      gradeColor.withValues(alpha: 0.12),
                      AppTheme.neonPurple.withValues(alpha: 0.08),
                    ]
                  : [
                      gradeColor.withValues(alpha: 0.08),
                      AppTheme.neonPurple.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: gradeColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              // Derece rozeti
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: gradeColor.withValues(alpha: 0.35)),
                ),
                child: Text(grade,
                    style: GoogleFonts.inter(
                        color: gradeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack),
              const SizedBox(height: 20),

              // Net skoru
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(netStr,
                      style: GoogleFonts.inter(
                          color: gradeColor,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2))
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms),
                  const SizedBox(width: 6),
                  Text(' / ${result.totalQuestions}',
                      style: GoogleFonts.inter(
                          color: subColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Text('Net Puan',
                  style: GoogleFonts.inter(
                      color: subColor, fontSize: 12)),
              const SizedBox(height: 16),

              // Doğruluk çubuğu
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Başarı Oranı',
                                style: GoogleFonts.inter(
                                    color: subColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            Text('%$accuracy',
                                style: GoogleFonts.inter(
                                    color: gradeColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: result.accuracy,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor:
                                AlwaysStoppedAnimation(gradeColor),
                            minHeight: 8,
                          ),
                        )
                            .animate()
                            .custom(
                              delay: 400.ms,
                              duration: 800.ms,
                              builder: (_, v, child) => ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: result.accuracy * v,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                  valueColor: AlwaysStoppedAnimation(
                                      gradeColor),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, Color textColor, Color subColor) {
    return Row(
      children: [
        _buildStatBox('✅', '${result.correctAnswers}', 'Doğru',
            AppTheme.success, isDark),
        const SizedBox(width: 10),
        _buildStatBox('❌', '${result.wrongAnswers}', 'Yanlış',
            AppTheme.error, isDark),
        const SizedBox(width: 10),
        _buildStatBox('⬜', '${result.unanswered}', 'Boş',
            AppTheme.textSecondary, isDark),
        const SizedBox(width: 10),
        _buildStatBox('⏱️', result.formattedTime, 'Süre',
            AppTheme.neonPurple, isDark),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatBox(String emoji, String value, String label,
      Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.10 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectBreakdown(
      bool isDark, Color textColor, Color subColor) {
    final sorted = result.subjectBreakdown.values.toList()
      ..sort((a, b) => b.accuracy.compareTo(a.accuracy));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Konu Bazlı Analiz',
            style: GoogleFonts.inter(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...sorted.asMap().entries.map(
          (entry) => _buildSubjectRow(entry.value, isDark, textColor,
              subColor, entry.key),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildSubjectRow(SubjectScore score, bool isDark, Color textColor,
      Color subColor, int i) {
    final color = _accuracyColor(score.accuracy);
    final pct = (score.accuracy * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(score.subjectName,
                        style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text(
                      '${score.correct}/${score.total} · %$pct',
                      style: GoogleFonts.inter(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.accuracy,
                    backgroundColor:
                        isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 400 + i * 60), duration: 300.ms);
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.home_rounded, size: 16),
            label: Text('Ana Sayfa',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? AppTheme.textSecondary
                  : AppTheme.lightTextSecondary,
              side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.10)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const MockExamSetupScreen()),
              );
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('Yeni Sınav',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cyan,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ── Yardımcı ─────────────────────────────────────────────────────────────

  String _gradeLabel(double accuracy) {
    if (accuracy >= 0.85) return '🏆 Mükemmel';
    if (accuracy >= 0.70) return '🎯 Çok İyi';
    if (accuracy >= 0.55) return '📚 İyi';
    if (accuracy >= 0.40) return '⚡ Geliştirilmeli';
    return '💪 Çalışmaya Devam';
  }

  Color _gradeColor(double accuracy) {
    if (accuracy >= 0.70) return AppTheme.success;
    if (accuracy >= 0.55) return AppTheme.neonGold;
    return AppTheme.error;
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 0.70) return AppTheme.success;
    if (accuracy >= 0.50) return AppTheme.neonGold;
    return AppTheme.error;
  }
}
