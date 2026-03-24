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
  final String userName;
  final String targetBranch;

  const AiInsightSheet({
    super.key,
    required this.progress,
    required this.isDark,
    required this.mistakeCounts,
    required this.topMistakeTopics,
    this.userName = 'Doktor',
    this.targetBranch = 'Henüz Seçilmedi',
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
                  const SizedBox(height: 16),
                  _buildTargetBranchCard(),
                  const SizedBox(height: 16),
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
    final days = progress.daysToExam;
    final isUrgent = days <= 30;
    final isSoon = days <= 90 && days > 30;
    final urgentColor = isUrgent ? const Color(0xFFFF4757) : (isSoon ? AppTheme.neonGold : AppTheme.cyan);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: urgentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: urgentColor.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  isUrgent ? Icons.warning_amber_rounded : Icons.smart_toy_rounded,
                  color: urgentColor, size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba, $userName 👋',
                      style: GoogleFonts.inter(
                          color: textColor, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      isUrgent
                          ? 'Sınava $days gün kaldı — Kritik mod!'
                          : isSoon
                              ? 'Sınava $days gün kaldı — Son düzlük!'
                              : 'Yapay Zeka Analiz Raporu',
                      style: GoogleFonts.inter(
                          color: urgentColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isUrgent) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4757).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF4757).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFFF4757), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$days gün içinde TUS\'a giriyorsun. Yanlışlara tam gaz odaklan!',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFF4757),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final days = progress.daysToExam;
    final name = userName;
    final isUrgent = days <= 30;
    String advice;

    if (isUrgent) {
      advice = '$name, sınava $days gün kaldı ve $mainWeakness branşında kritik açıklar var. Artık yeni konu çalışma değil, sadece "Yanlışlar" listeni bitir. Her gün minimum ${progress.dailyGoal} kart, sıfır mazeret.';
    } else if (intensity == 'Efsane') {
      advice = '$name, $mainWeakness branşındaki yanlışların %10\'un altına düşmeli. Bu hafta sadece $mainWeakness "Kritik" kartlarına odaklanarak netlerini sabitleyebilirsin.';
    } else if (intensity == 'Uzman') {
      advice = '$name, hedefin yüksek. $mainWeakness konusundaki eksiklerin temel bilimlerde puanını baskılıyor. Bu branştaki vaka sorularına ağırlık vermelisin.';
    } else {
      advice = '$name, $mainWeakness branşından gelen yanlışlar çalışma düzenini bozabilir. Önce bu branştaki "En Çok Soru Çıkan" spotlara bakmanı öneririm.';
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

  /// TUS 2024-2025 branş minimum yerleşme puanı tahminleri
  static const Map<String, double> _branchMinScores = {
    'Acil Tıp': 57.0,
    'Aile Hekimliği': 52.0,
    'Anatomi': 53.0,
    'Anesteziyoloji': 63.0,
    'Beyin Cerrahisi': 70.0,
    'Biyokimya': 53.0,
    'Çocuk Cerrahisi': 69.0,
    'Çocuk Sağlığı': 64.0,
    'Dermatoloji': 74.0,
    'Enfeksiyon Hastalıkları': 59.0,
    'Fiziksel Tıp': 61.0,
    'Genel Cerrahi': 66.0,
    'Göğüs Cerrahisi': 66.0,
    'Göğüs Hastalıkları': 61.0,
    'Göz Hastalıkları': 71.0,
    'Histoloji': 53.0,
    'İç Hastalıkları': 66.0,
    'Kadın Hastalıkları': 68.0,
    'Kalp Damar Cerrahisi': 69.0,
    'Kardiyoloji': 73.0,
    'KBB': 71.0,
    'Mikrobiyoloji': 56.0,
    'Nöroloji': 66.0,
    'Ortopedi': 68.0,
    'Patoloji': 56.0,
    'Plastik Cerrahi': 70.0,
    'Psikiyatri': 66.0,
    'Radyoloji': 71.0,
    'Üroloji': 68.0,
  };

  Widget _buildTargetBranchCard() {
    final hasTarget = targetBranch != 'Henüz Seçilmedi' && targetBranch.isNotEmpty;
    final targetPuan = progress.targetScore;
    final mevcutPuan = progress.baseScore;
    final fark = (targetPuan - mevcutPuan).clamp(0.0, 100.0);
    final recommended = progress.recommendedDailyGoal;
    final days = progress.daysToExam;
    final branchMin = _branchMinScores[targetBranch];

    final Color accentColor = hasTarget ? AppTheme.neonPurple : AppTheme.textSecondary;

    // Yol haritası metni
    String roadmap;
    if (!hasTarget) {
      roadmap = 'Profil ekranından hedef branşını seçersen sana özel yol haritası çıkarırım.';
    } else if (branchMin != null && targetPuan < branchMin) {
      roadmap = '⚠️ $targetBranch için ortalama yerleşme puanı ${branchMin.toStringAsFixed(0)} civarında. Hedefini ${branchMin.toStringAsFixed(0)}+ olarak güncellemeyi düşün.';
    } else if (fark <= 2) {
      roadmap = '✅ $targetBranch için gerekli ${targetPuan.toStringAsFixed(0)} puana çok yakınsın. Mevcut temponu koru!';
    } else {
      final netArtisi = (fark * 4).ceil(); // ~4 net = 1 puan
      roadmap = '$targetBranch için $days günde ${fark.toStringAsFixed(0)} puanlık açığı kapatmak için günde $recommended kart/soru çözmelisin. Yaklaşık $netArtisi net artışı gerekiyor.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.12), accentColor.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'HEDEF BÖLÜM ANALİZİ',
                style: GoogleFonts.inter(color: accentColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              const Spacer(),
              if (hasTarget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    targetBranch,
                    style: GoogleFonts.inter(color: accentColor, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _ScoreChip(label: 'Mevcut', value: mevcutPuan.toStringAsFixed(0), color: AppTheme.neonGold),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: accentColor.withValues(alpha: 0.5), size: 16),
                const SizedBox(width: 8),
                _ScoreChip(label: 'Hedef', value: targetPuan.toStringAsFixed(0), color: accentColor),
                if (branchMin != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.4), size: 16),
                  const SizedBox(width: 8),
                  _ScoreChip(label: 'Min.Yerleşme', value: branchMin.toStringAsFixed(0), color: AppTheme.neonPink),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            roadmap,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
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

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.inter(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w700)),
          Text(value,
              style: GoogleFonts.inter(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
