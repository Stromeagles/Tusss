import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/progress_model.dart';
import '../models/subject_registry.dart';
import '../services/data_service.dart';
import '../services/spaced_repetition_service.dart';

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

  @override
  void initState() {
    super.initState();
    _masteryFuture = _loadMasteryData();
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
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontSize: 14,
              ),
            ),
          );
        }

        return Column(
          children: subjects.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.name,
                        style: GoogleFonts.inter(
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${s.done}/${s.total}  %${(s.percent * 100).toInt()}',
                        style: GoogleFonts.inter(
                          color: s.color,
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
                        width: double.infinity,
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
                            gradient: LinearGradient(
                              colors: [s.color, s.color.withValues(alpha: 0.6)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(color: s.color.withValues(alpha: 0.3), blurRadius: 8)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SubjectMasteryData {
  final String name;
  final Color color;
  final int total;
  final int done;

  const _SubjectMasteryData({
    required this.name,
    required this.color,
    required this.total,
    required this.done,
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
