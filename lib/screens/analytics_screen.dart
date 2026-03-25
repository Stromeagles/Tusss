import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/progress_model.dart';
import '../models/subject_registry.dart';
import '../services/data_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/specialty_score_service.dart';
import '../services/leaderboard_service.dart';

class ProgressAnalyticsScreen extends StatefulWidget {
  final UserProfile user;
  final StudyProgress progress;

  const ProgressAnalyticsScreen({
    super.key,
    required this.user,
    required this.progress,
  });

  @override
  State<ProgressAnalyticsScreen> createState() => _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  late Future<List<_SubjectMasteryData>> _masteryFuture;
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _masteryFuture = _loadMasteryData();
    _leaderboardFuture = LeaderboardService().getTopUsers();
  }

  Future<List<_SubjectMasteryData>> _loadMasteryData() async {
    final dataService = DataService();
    final srService = SpacedRepetitionService();
    final allSrsData = await srService.getAllData();
    final results = <_SubjectMasteryData>[];

    for (final module in SubjectRegistry.modules) {
      final topics = await dataService.loadTopics(subjectId: module.id);
      int totalFlashcards = 0;
      int masteredFlashcards = 0;
      int totalCases = 0;
      int masteredCases = 0;

      for (final topic in topics) {
        // Flashcard'lar
        totalFlashcards += topic.flashcards.length;
        for (final fc in topic.flashcards) {
          final srs = allSrsData[fc.id];
          if (srs != null && srs.isMastered) masteredFlashcards++;
        }
        // Klinik Vakalar (Sorular)
        totalCases += topic.clinicalCases.length;
        for (final cc in topic.clinicalCases) {
          final srs = allSrsData[cc.id];
          if (srs != null && srs.isMastered) masteredCases++;
        }
      }

      final totalAll = totalFlashcards + totalCases;
      final masteredAll = masteredFlashcards + masteredCases;

      if (totalAll > 0) {
        results.add(_SubjectMasteryData(
          name: module.name,
          color: module.color,
          total: totalAll,
          done: masteredAll,
          category: module.category,
        ));
      }
    }

    // Yüzdesine göre sırala (yüksekten düşüğe)
    results.sort((a, b) => b.percent.compareTo(a.percent));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final targetDate = widget.user.targetDate ?? now.add(const Duration(days: 90));
    final daysRemaining = targetDate.difference(now).inDays.clamp(0, 9999);

    final predictedIncrease = (widget.progress.totalFlashcardsStudied / 100) * 1.2 +
        (widget.progress.totalCasesAttempted / 20) * 0.8;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.background : Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCountdownCard(daysRemaining, isDark),
                  const SizedBox(height: 20),
                  _buildReadinessGauge(isDark),
                  const SizedBox(height: 20),
                  _buildScorePredictionCard(predictedIncrease, isDark),
                  const SizedBox(height: 28),
                  Text(
                    'Branş Bazlı Hakimiyet',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSubjectMastery(isDark),
                  const SizedBox(height: 28),
                  Text(
                    'Haftalık Sıralama',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLeaderboard(isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: isDark ? AppTheme.background : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Gidişat Analizi',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  // ── Readiness Gauge ────────────────────────────────────────────────────────
  Widget _buildReadinessGauge(bool isDark) {
    return FutureBuilder<List<_SubjectMasteryData>>(
      future: _masteryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: isDark ? AppTheme.surface : Colors.white,
              border: Border.all(
                  color: AppTheme.coral.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.coral, strokeWidth: 2.5),
            ),
          );
        }

        final masteryData = snapshot.data ?? [];

        // ── Rates ──────────────────────────────────────────────────────────
        final totalCards =
            masteryData.fold(0, (sum, s) => sum + s.total);
        final masteredCards =
            masteryData.fold(0, (sum, s) => sum + s.done);
        final masteryRate =
            totalCards > 0 ? (masteredCards / totalCards).clamp(0.0, 1.0) : 0.0;

        final accuracyRate = widget.progress.totalCasesAttempted > 0
            ? (widget.progress.correctAnswers /
                    widget.progress.totalCasesAttempted)
                .clamp(0.0, 1.0)
            : 0.0;

        final streakRate =
            (widget.progress.currentStreak / 30).clamp(0.0, 1.0);

        // ── Readiness Score (0-100) ─────────────────────────────────────────
        final readiness =
            masteryRate * 0.55 + accuracyRate * 0.35 + streakRate * 0.10;
        final readinessScore = (readiness * 100).round();

        // ── Projected TUS Score ─────────────────────────────────────────────
        final projectedScore = widget.progress.baseScore +
            (widget.progress.targetScore - widget.progress.baseScore) *
                readiness;

        // ── Target branch ───────────────────────────────────────────────────
        final hasTargetBranch =
            widget.user.targetBranch != 'Henüz Seçilmedi' &&
                widget.user.targetBranch.isNotEmpty;
        final branchScore = hasTargetBranch
            ? SpecialtyScoreService().getScoreFor(widget.user.targetBranch)
            : null;
        final targetBranchAvg =
            branchScore?.averageScore ?? widget.progress.targetScore;

        // ── Nets needed ─────────────────────────────────────────────────────
        final scoreGap = (targetBranchAvg - projectedScore).clamp(0.0, 50.0);
        final netsNeeded = (scoreGap / 0.05).round();

        // ── Readiness label ─────────────────────────────────────────────────
        final String readinessLabel;
        final Color readinessColor;
        if (readinessScore >= 80) {
          readinessLabel = 'Mükemmel';
          readinessColor = AppTheme.success;
        } else if (readinessScore >= 60) {
          readinessLabel = 'İyi';
          readinessColor = AppTheme.cyan;
        } else if (readinessScore >= 40) {
          readinessLabel = 'Orta';
          readinessColor = AppTheme.neonGold;
        } else {
          readinessLabel = 'Başlangıç';
          readinessColor = AppTheme.coral;
        }

        return _ReadinessGaugeCard(
          isDark: isDark,
          readinessScore: readinessScore,
          readinessLabel: readinessLabel,
          readinessColor: readinessColor,
          masteryRate: masteryRate,
          accuracyRate: accuracyRate,
          streakRate: streakRate,
          masteredCards: masteredCards,
          totalCards: totalCards,
          projectedScore: projectedScore,
          targetBranchAvg: targetBranchAvg,
          targetBranch:
              hasTargetBranch ? widget.user.targetBranch : null,
          netsNeeded: netsNeeded,
          currentStreak: widget.progress.currentStreak,
          targetScore: widget.progress.targetScore,
        );
      },
    );
  }

  Widget _buildCountdownCard(int days, bool isDark) {
    final progress = (days / 365).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyan.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 1 - progress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.cyan.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyan),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$days',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'GÜN',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TUS Rotalan',
                  style: GoogleFonts.inter(
                    color: AppTheme.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hedefine ulaşmak için zamanın var. Tempoyu koru!',
                  style: GoogleFonts.inter(
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePredictionCard(double increase, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TAHMİNİ ARTIŞ',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${increase.toStringAsFixed(1)} Puan',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Çalışma verilerine göre netlerin yükseliş trendinde.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectMastery(bool isDark) {
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return FutureBuilder<List<_SubjectMasteryData>>(
      future: _masteryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2.5),
            ),
          );
        }

        final subjects = snapshot.data ?? [];
        if (subjects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Henüz veri yok — kartlarla çalışmaya başla!',
              style: GoogleFonts.inter(color: subColor, fontSize: 14),
            ),
          );
        }

        final temelList = subjects.where((s) => s.category == SubjectCategory.temel).toList();
        final klinikList = subjects.where((s) => s.category == SubjectCategory.klinik).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Temel Bilimler Performansı ──
            _buildCategoryHeader(
              'Temel Bilimler Performansı',
              Icons.science_outlined,
              isDark,
              textColor,
            ),
            const SizedBox(height: 12),
            if (temelList.isEmpty)
              _buildEmptyCategory('Temel bilimler verisi henüz yok', subColor)
            else
              ...temelList.map((s) => _buildMasteryBar(s, isDark)),

            const SizedBox(height: 28),

            // ── Klinik Bilimler Performansı ──
            _buildCategoryHeader(
              'Klinik Bilimler Performansı',
              Icons.local_hospital_outlined,
              isDark,
              textColor,
            ),
            const SizedBox(height: 12),
            if (klinikList.isEmpty)
              _buildEmptyCategory('Klinik bilimler içeriği yakında eklenecek', subColor)
            else
              ...klinikList.map((s) => _buildMasteryBar(s, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon, bool isDark, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.cyan.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Text(title,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCategory(String message, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(message,
        style: GoogleFonts.inter(color: subColor.withValues(alpha: 0.6), fontSize: 13, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildLeaderboard(bool isDark) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: _leaderboardFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.coral, strokeWidth: 2.5),
            ),
          );
        }

        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.coral.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Henüz sıralama verisi yok — ilk sen ol!',
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontSize: 14,
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.coral.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.coral.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Color(0xFFFBBF24), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Bu Hafta En Çok Çözenler',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
              ...entries.asMap().entries.map(
                    (e) => _buildLeaderboardRow(e.key, e.value, isDark),
                  ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardRow(int index, LeaderboardEntry entry, bool isDark) {
    final rank = index + 1;
    final medalColors = {
      1: const Color(0xFFFBBF24), // altın
      2: const Color(0xFF9CA3AF), // gümüş
      3: const Color(0xFFB45309), // bronz
    };
    final rankColor = medalColors[rank] ?? AppTheme.textMuted;
    final isMe = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.coral.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: AppTheme.coral.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Sıra
          SizedBox(
            width: 28,
            child: rank <= 3
                ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 20)
                : Text(
                    '$rank',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.violet.withValues(alpha: 0.3),
            backgroundImage: entry.photoUrl != null
                ? NetworkImage(entry.photoUrl!)
                : null,
            child: entry.photoUrl == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // İsim
          Expanded(
            child: Text(
              isMe ? '${entry.displayName} (Sen)' : entry.displayName,
              style: GoogleFonts.inter(
                color: isMe
                    ? AppTheme.coral
                    : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                fontSize: 13,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Skor
          Text(
            '${entry.weeklyCount}',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'soru',
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryBar(_SubjectMasteryData s, bool isDark) {
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.name,
                style: GoogleFonts.inter(color: subColor, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('${s.done}/${s.total}  %${(s.percent * 100).toInt()}',
                style: GoogleFonts.inter(color: s.color, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8, width: double.infinity,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: s.percent.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [s.color, s.color.withValues(alpha: 0.6)]),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: s.color.withValues(alpha: 0.3), blurRadius: 8)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectMasteryData {
  final String name;
  final Color color;
  final int total;
  final int done;
  final SubjectCategory category;

  const _SubjectMasteryData({
    required this.name,
    required this.color,
    required this.total,
    required this.done,
    required this.category,
  });

  double get percent => total > 0 ? done / total : 0.0;
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  Readiness Gauge — 3-Halka Göstergesi (Apple Watch tarzı)                ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class _ReadinessGaugeCard extends StatelessWidget {
  final bool isDark;
  final int readinessScore;
  final String readinessLabel;
  final Color readinessColor;
  final double masteryRate;
  final double accuracyRate;
  final double streakRate;
  final int masteredCards;
  final int totalCards;
  final double projectedScore;
  final double targetBranchAvg;
  final String? targetBranch;
  final int netsNeeded;
  final int currentStreak;
  final double targetScore;

  const _ReadinessGaugeCard({
    required this.isDark,
    required this.readinessScore,
    required this.readinessLabel,
    required this.readinessColor,
    required this.masteryRate,
    required this.accuracyRate,
    required this.streakRate,
    required this.masteredCards,
    required this.totalCards,
    required this.projectedScore,
    required this.targetBranchAvg,
    this.targetBranch,
    required this.netsNeeded,
    required this.currentStreak,
    required this.targetScore,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppTheme.surface : Colors.white;
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: readinessColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: readinessColor.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.violet.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Text(
                  'SINAV HAZIRLIK SEVİYESİ',
                  style: GoogleFonts.inter(
                    color: subColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: readinessColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: readinessColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    readinessLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: readinessColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Gauge + Legend ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 3-Ring Gauge
                SizedBox(
                  width: 160,
                  height: 160,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.easeOutCubic,
                    builder: (_, progress, __) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(160, 160),
                            painter: _ReadinessRingPainter(
                              masteryRate: masteryRate * progress,
                              accuracyRate: accuracyRate * progress,
                              streakRate: streakRate * progress,
                            ),
                          ),
                          // Center text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$readinessScore%',
                                style: GoogleFonts.inter(
                                  color: textColor,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'HAZIRLIK',
                                style: GoogleFonts.inter(
                                  color: subColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(width: 20),

                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RingLegend(
                        color: AppTheme.coral,
                        icon: Icons.style_rounded,
                        label: 'Hakimiyet',
                        valueText:
                            '${(masteryRate * 100).toInt()}%  ($masteredCards/$totalCards)',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _RingLegend(
                        color: AppTheme.cyan,
                        icon: Icons.quiz_rounded,
                        label: 'Doğruluk',
                        valueText: '${(accuracyRate * 100).toInt()}%',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _RingLegend(
                        color: AppTheme.violet,
                        icon: Icons.local_fire_department_rounded,
                        label: 'Seri',
                        valueText: '$currentStreak gün',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    readinessColor.withValues(alpha: 0.3),
                    AppTheme.violet.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),

          // ── Projection Card ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppTheme.coral.withValues(alpha: 0.08),
                          AppTheme.violet.withValues(alpha: 0.08),
                        ]
                      : [
                          AppTheme.coral.withValues(alpha: 0.05),
                          AppTheme.violet.withValues(alpha: 0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: AppTheme.coral.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Projected score row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.coral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.track_changes_rounded,
                            color: AppTheme.coral, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.lightTextSecondary,
                                fontSize: 13),
                            children: [
                              const TextSpan(
                                  text: 'Tahmini TUS Puanın:  '),
                              TextSpan(
                                text: projectedScore.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  color: AppTheme.coral,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Target branch row
                  if (targetBranch != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 39),
                        Expanded(
                          child: Text(
                            'Hedef branş: $targetBranch  '
                            '(ort. ${targetBranchAvg.toStringAsFixed(0)} puan)',
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Nets needed row
                  if (netsNeeded > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppTheme.neonGold.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded,
                              color: AppTheme.neonGold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${targetBranchAvg.toStringAsFixed(0)} puana çıkmak için '
                              '~$netsNeeded net daha yapman lazım',
                              style: GoogleFonts.inter(
                                color: AppTheme.neonGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (netsNeeded == 0 && projectedScore >= targetBranchAvg) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppTheme.success.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: AppTheme.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hedefe ulaştın! Mevcut performansın yeterli.',
                              style: GoogleFonts.inter(
                                color: AppTheme.success,
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
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutExpo);
  }
}

// ── Ring Legend Row ────────────────────────────────────────────────────────
class _RingLegend extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String valueText;
  final bool isDark;

  const _RingLegend({
    required this.color,
    required this.icon,
    required this.label,
    required this.valueText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.6), blurRadius: 6)
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                valueText,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 3-Ring CustomPainter ───────────────────────────────────────────────────
class _ReadinessRingPainter extends CustomPainter {
  final double masteryRate;
  final double accuracyRate;
  final double streakRate;

  static const double _startDeg = 150.0; // 7 o'clock start (like Apple Watch)
  static const double _sweepDeg = 240.0; // 240° total sweep

  const _ReadinessRingPainter({
    required this.masteryRate,
    required this.accuracyRate,
    required this.streakRate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const ringStroke = 13.0;
    const ringGap    = 7.0;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer radius = half the canvas minus padding
    final r1 = size.shortestSide / 2 - 4;
    final r2 = r1 - ringStroke - ringGap;
    final r3 = r2 - ringStroke - ringGap;

    _drawRing(canvas, cx, cy, r1, masteryRate, AppTheme.coral);
    _drawRing(canvas, cx, cy, r2, accuracyRate, AppTheme.cyan);
    _drawRing(canvas, cx, cy, r3, streakRate, AppTheme.violet);
  }

  void _drawRing(
      Canvas canvas, double cx, double cy, double r, double value, Color color) {
    final start  = (_startDeg) * math.pi / 180;
    final sweep  = _sweepDeg  * math.pi / 180;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color      = color.withValues(alpha: 0.14)
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 13.0
        ..strokeCap  = StrokeCap.round,
    );

    if (value <= 0) return;

    final fillSweep = sweep * value.clamp(0.0, 1.0);

    // Glow
    canvas.drawArc(
      rect,
      start,
      fillSweep,
      false,
      Paint()
        ..color      = color.withValues(alpha: 0.35)
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 19.0
        ..strokeCap  = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Fill
    canvas.drawArc(
      rect,
      start,
      fillSweep,
      false,
      Paint()
        ..shader     = SweepGradient(
            startAngle: start,
            endAngle: start + fillSweep,
            colors: [color, color.withValues(alpha: 0.7)],
          ).createShader(rect)
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 13.0
        ..strokeCap  = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ReadinessRingPainter old) =>
      old.masteryRate  != masteryRate  ||
      old.accuracyRate != accuracyRate ||
      old.streakRate   != streakRate;
}

class _ChartPainter extends CustomPainter {
  final Color color;
  _ChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.9, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.1, size.width, size.height * 0.2);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width, size.height * 0.2), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
