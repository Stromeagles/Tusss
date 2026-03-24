import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/progress_model.dart';
import '../services/specialty_score_service.dart';
import '../services/premium_service.dart';
import 'paywall_widget.dart';

class AiInsightSheet extends StatefulWidget {
  final StudyProgress progress;
  final bool isDark;
  final Map<String, int> mistakeCounts;
  final List<String> topMistakeTopics;
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
  State<AiInsightSheet> createState() => _AiInsightSheetState();
}

class _AiInsightSheetState extends State<AiInsightSheet> {
  bool _serviceReady = false;

  @override
  void initState() {
    super.initState();
    SpecialtyScoreService().init().then((_) {
      if (mounted) setState(() => _serviceReady = true);
    });
  }

  // ── Getters (kısaltma) ─────────────────────────────────────────────────────
  StudyProgress get progress => widget.progress;
  bool get isDark => widget.isDark;
  Map<String, int> get mistakeCounts => widget.mistakeCounts;
  List<String> get topMistakeTopics => widget.topMistakeTopics;
  String get userName => widget.userName;
  String get targetBranch => widget.targetBranch;

  // ── Fallback minimum puan haritası (specialty_scores.json'da olmayan branşlar) ──
  static const Map<String, double> _fallbackMinScores = {
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

  /// Hedef branş için servis (gerçek TUS verisi) ya da fallback map'ten puan döner.
  double? _getMinScore() {
    if (_serviceReady) {
      final score = SpecialtyScoreService().getScoreFor(targetBranch);
      if (score != null) return score.averageScore;
    }
    return _fallbackMinScores[targetBranch];
  }

  /// Hedef branşa özel çalışma tavsiyesi (servis'ten veya null).
  String? _getBranchAdvice() {
    if (!_serviceReady) return null;
    return SpecialtyScoreService().getScoreFor(targetBranch)?.advice;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    final sortedMistakes = mistakeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mainWeakness = sortedMistakes.isNotEmpty
        ? sortedMistakes.first.key
        : 'Henüz veri yok';

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
            ),
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
                  const SizedBox(height: 20),
                  _buildPremiumCta(),
                  if (topMistakeTopics.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildTopicSection(textColor, subColor),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(Color textColor, Color subColor) {
    final days = progress.daysToExam;
    final isUrgent = days <= 30;
    final isSoon = days <= 90 && days > 30;
    final urgentColor = isUrgent
        ? const Color(0xFFFF4757)
        : (isSoon ? AppTheme.neonGold : AppTheme.cyan);

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

  // ── Intensity Card ─────────────────────────────────────────────────────────
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
          colors: [
            intensityColor.withValues(alpha: 0.15),
            intensityColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                        color: intensityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(
                  '${progress.targetScore} Puan hedefin için analiz tamamlandı.',
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hedef Branş Kartı (SpecialtyScoreService entegreli) ───────────────────
  Widget _buildTargetBranchCard() {
    final hasTarget = targetBranch != 'Henüz Seçilmedi' && targetBranch.isNotEmpty;
    final targetPuan = progress.targetScore;
    final mevcutPuan = progress.baseScore;
    final days = progress.daysToExam;
    final recommended = progress.recommendedDailyGoal;

    final branchMin = _getMinScore();
    final branchAdvice = _getBranchAdvice();

    final Color accentColor = hasTarget ? AppTheme.neonPurple : AppTheme.textSecondary;

    // ── Akıllı yol haritası ─────────────────────────────────────────────────
    String roadmap;
    if (!hasTarget) {
      roadmap = 'Profil ekranından hedef branşını seçersen sana özel yol haritası çıkarırım.';
    } else if (branchMin == null) {
      // Branş veritabanında yok — genel tavsiye
      final fark = (targetPuan - mevcutPuan).clamp(0.0, 100.0);
      if (fark <= 2) {
        roadmap = '✅ $targetBranch için hedeflediğin ${targetPuan.toStringAsFixed(0)} puana çok yakınsın. Mevcut temponu koru!';
      } else {
        final netArtisi = (fark * 1.5).ceil();
        roadmap = '$targetBranch hedefi için $days günde yaklaşık $netArtisi net artışı gerekiyor. Günde $recommended kart/soru çözmelisin.';
      }
    } else {
      // Veritabanında gerçek veri var
      final gapToMin = (branchMin - mevcutPuan).clamp(0.0, 100.0);
      final gapToTarget = (branchMin - targetPuan).clamp(-100.0, 100.0);
      final netArtisi = (gapToMin * 1.5).ceil();

      // Zayıf dersleri bul (en fazla 2 tane)
      final sortedMistakes = mistakeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final weakSubjects = sortedMistakes.take(2).map((e) => e.key).toList();
      final weakText = weakSubjects.isNotEmpty
          ? weakSubjects.join(' ve ')
          : 'Temel Bilimler';

      if (mevcutPuan >= branchMin) {
        roadmap = '🎯 $targetBranch için gereken ${branchMin.toStringAsFixed(0)} puanın üstündesin! '
            'Mevcut performansını koru ve $weakText hatalarını sıfıra indir — derece hedefleyebilirsin.';
      } else if (gapToTarget > 5) {
        roadmap = '⚠️ $targetBranch için ortalama yerleşme ${branchMin.toStringAsFixed(0)} puan. '
            'Hedefini en az ${branchMin.toStringAsFixed(0)}\'e yükseltmeni öneririm. '
            'Açığı kapatmak için $netArtisi net artışı ve $days günde günde $recommended kart gerekiyor.';
      } else {
        final netStr = netArtisi > 0 ? '+$netArtisi net' : 'mevcut netlerini sabit tut';
        roadmap = '$targetBranch için $netStr artışı gerekiyor. '
            '$weakText konularındaki yanlışlarını azaltırsan bu hedefe ulaşırsın. '
            '${days > 0 ? "Kalan $days günde günde $recommended kart/soru hedefle." : ""}';
      }

      // Branşa özel tavsiyeyi ekle (servis'ten geliyorsa)
      if (branchAdvice != null && branchAdvice.isNotEmpty) {
        roadmap += '\n\n💡 $branchAdvice';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.04),
          ],
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
                style: GoogleFonts.inter(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5),
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
                    style: GoogleFonts.inter(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _ScoreChip(
                    label: 'Mevcut',
                    value: mevcutPuan.toStringAsFixed(0),
                    color: AppTheme.neonGold),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    color: accentColor.withValues(alpha: 0.5), size: 16),
                const SizedBox(width: 8),
                _ScoreChip(
                    label: 'Hedef',
                    value: targetPuan.toStringAsFixed(0),
                    color: accentColor),
                if (branchMin != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      color: AppTheme.textSecondary.withValues(alpha: 0.4), size: 16),
                  const SizedBox(width: 8),
                  _ScoreChip(
                      label: 'Min.Yerleşme',
                      value: branchMin.toStringAsFixed(0),
                      color: AppTheme.neonPink),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            roadmap,
            style: GoogleFonts.inter(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.black87,
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Zayıf Halkalar ─────────────────────────────────────────────────────────
  Widget _buildMistakeSection(
      Color textColor,
      Color subColor,
      List<MapEntry<String, int>> sortedMistakes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ZAYIF HALKALAR',
            style: GoogleFonts.inter(
                color: subColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        if (sortedMistakes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Henüz yeterli yanlış verisi yok. Daha fazla çözmelisin!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: subColor, fontSize: 13),
              ),
            ),
          )
        else
          ...sortedMistakes
              .take(3)
              .map((e) => _buildMistakeBar(e.key, e.value, sortedMistakes.first.value)),
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
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text('$count hata',
                  style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
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
                    gradient: const LinearGradient(
                        colors: [Colors.redAccent, Colors.orangeAccent]),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.3),
                          blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── AI Tavsiye Kartı ───────────────────────────────────────────────────────
  Widget _buildAdviceCard(String mainWeakness) {
    final intensity = progress.scoreIntensity;
    final days = progress.daysToExam;
    final name = userName;
    final isUrgent = days <= 30;
    String advice;

    if (isUrgent) {
      advice =
          '$name, sınava $days gün kaldı ve $mainWeakness branşında kritik açıklar var. '
          'Artık yeni konu çalışma değil, sadece "Yanlışlar" listeni bitir. '
          'Her gün minimum ${progress.dailyGoal} kart, sıfır mazeret.';
    } else if (intensity == 'Efsane') {
      advice =
          '$name, $mainWeakness branşındaki yanlışların %10\'un altına düşmeli. '
          'Bu hafta sadece $mainWeakness "Kritik" kartlarına odaklanarak netlerini sabitleyebilirsin.';
    } else if (intensity == 'Uzman') {
      advice =
          '$name, hedefin yüksek. $mainWeakness konusundaki eksiklerin temel bilimlerde '
          'puanını baskılıyor. Bu branştaki vaka sorularına ağırlık vermelisin.';
    } else {
      advice =
          '$name, $mainWeakness branşından gelen yanlışlar çalışma düzenini bozabilir. '
          'Önce bu branştaki "En Çok Soru Çıkan" spotlara bakmanı öneririm.';
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
                  style: GoogleFonts.inter(
                      color: AppTheme.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice,
              style: GoogleFonts.inter(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black87,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ── Premium CTA ────────────────────────────────────────────────────────────
  Widget _buildPremiumCta() {
    const coral = Color(0xFFF78166);
    const violet = Color(0xFFA371F7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            coral.withValues(alpha: isDark ? 0.18 : 0.12),
            violet.withValues(alpha: isDark ? 0.18 : 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: coral.withValues(alpha: isDark ? 0.40 : 0.25),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                    color: coral.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [coral, violet]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Premium\'a Geç — Sınır Tanıma!',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PremiumBullet(
            icon: Icons.all_inclusive_rounded,
            text: 'Sınırsız vaka sorusu çöz — günlük limit yok',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _PremiumBullet(
            icon: Icons.folder_special_rounded,
            text: 'Özel klasörler oluştur, kartlarını organize et',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _PremiumBullet(
            icon: Icons.smart_toy_rounded,
            text: 'AI Koç tam erişim — derinlemesine analiz raporları',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [coral, violet]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: coral.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PaywallWidget(
                        type: 'ai_coach',
                        dailyLimit: PremiumService.dailyFreeCaseLimit,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        '✨  Premium\'a Geç',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
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

  // ── Konu Bölümü ────────────────────────────────────────────────────────────
  Widget _buildTopicSection(Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EN ÇOK HATA YAPILAN KONULAR',
            style: GoogleFonts.inter(
                color: subColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topMistakeTopics
              .map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: subColor.withValues(alpha: 0.15)),
                    ),
                    child: Text(t,
                        style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Score Chip ────────────────────────────────────────────────────────────────
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
              style: GoogleFonts.inter(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontSize: 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ── Premium Bullet ────────────────────────────────────────────────────────────
class _PremiumBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _PremiumBullet(
      {required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFF78166), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.80)
                  : Colors.black.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
