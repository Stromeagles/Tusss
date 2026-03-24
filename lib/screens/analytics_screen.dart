import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/progress_model.dart';
import '../models/subject_registry.dart';
import '../services/data_service.dart';
import '../services/spaced_repetition_service.dart';
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
