import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/progress_model.dart';

class AiInsightSheet extends StatelessWidget {
  final StudyProgress progress;
  final bool isDark;
  final Map<String, int> mistakeCounts; // Brans -> Yanlış Sayısı
  final List<String> topMistakeTopics; // En çok yanlış yapılan 3 konu

  const AiInsightSheet({
    super.key,
    required this.progress,
    required this.isDark,
    required this.mistakeCounts,
    required this.topMistakeTopics,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    // En çok yanlış yapılan branş
    final sortedMistakes = mistakeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mainWeakness = sortedMistakes.isNotEmpty ? sortedMistakes.first.key : 'Henüz veri yok';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cyan.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: subColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildHeader(textColor, subColor),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  _buildIntensityCard(),
                  const SizedBox(height: 24),
                  _buildMistakeSection(textColor, subColor, sortedMistakes),
                  const SizedBox(height: 24),
                  _buildAdviceCard(mainWeakness),
                  const SizedBox(height: 24),
                  if (topMistakeTopics.isNotEmpty)
                    _buildTopicSection(textColor, subColor),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.psychology_rounded, color: AppTheme.cyan, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dahi Asistan',
                  style: GoogleFonts.inter(
                      color: textColor, fontSize: 22, fontWeight: FontWeight.w900)),
              Text('Yapay Zeka Analiz Raporu',
                  style: GoogleFonts.inter(
                      color: subColor, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityCard() {
    final intensity = progress.scoreIntensity;
    Color intensityColor;
    String label;
    IconData icon;

    switch (intensity) {
      case 'Efsane':
        intensityColor = AppTheme.neonPink;
        label = 'DERECE HEDEFİ';
        icon = Icons.whatshot_rounded;
        break;
      case 'Uzman':
        intensityColor = AppTheme.cyan;
        label = 'UZMAN BRANŞ HEDEFİ';
        icon = Icons.stars_rounded;
        break;
      default:
        intensityColor = AppTheme.neonGold;
        label = 'STANDART HEDEF';
        icon = Icons.bolt_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [intensityColor.withValues(alpha: 0.15), intensityColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: intensityColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: intensityColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: intensityColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('${progress.targetScore} Puan hedefin için analiz tamamlandı.',
                    style: GoogleFonts.inter(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeSection(Color textColor, Color subColor, List<MapEntry<String, int>> sortedMistakes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ZAYIF HALKALAR',
            style: GoogleFonts.inter(
                color: subColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        if (sortedMistakes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text('Henüz yeterli yanlış verisi yok. Daha fazla çözmelisin!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: subColor, fontSize: 13)),
            ),
          )
        else
          ...sortedMistakes.take(3).map((e) => _buildMistakeBar(e.key, e.value, sortedMistakes.first.value)),
      ],
    );
  }

  Widget _buildMistakeBar(String subject, int count, int maxCount) {
    final ratio = count / maxCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject,
                  style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w700)),
              Text('$count hata',
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.redAccent, Colors.orangeAccent]),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(String mainWeakness) {
    final intensity = progress.scoreIntensity;
    String advice;

    if (intensity == 'Efsane') {
      advice = '$mainWeakness branşındaki yanlışların %10\'un altına düşmeli. Bu hafta sadece $mainWeakness "Kritik" kartlarına odaklanarak netlerini sabitleyebilirsin.';
    } else if (intensity == 'Uzman') {
      advice = 'Hedefin yüksek. $mainWeakness konusundaki eksiklerin temel bilimlerde puanını baskılıyor. Bu branştaki vaka sorularına ağırlık vermelisin.';
    } else {
      advice = '$mainWeakness branşından gelen yanlışlar çalışma düzenini bozabilir. Önce bu branştaki "En Çok Soru Çıkan" spotlara bakmanı öneririm.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.cyan, size: 20),
              const SizedBox(width: 8),
              Text('AI TAVSİYESİ',
                  style: GoogleFonts.inter(color: AppTheme.cyan, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                fontSize: 14, height: 1.5, fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  Widget _buildTopicSection(Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EN ÇOK HATA YAPILAN KONULAR',
            style: GoogleFonts.inter(
                color: subColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topMistakeTopics.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subColor.withValues(alpha: 0.15)),
            ),
            child: Text(t, style: GoogleFonts.inter(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
          )).toList(),
        ),
      ],
    );
  }
}
