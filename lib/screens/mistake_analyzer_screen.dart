import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/topic_model.dart';
import '../models/sm2_model.dart';
import '../models/subject_registry.dart';
import '../services/data_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/ai_service.dart';
import 'flashcard_screen.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  MistakeAnalyzerScreen — Hata Analiz Motoru V2                           ║
// ╚══════════════════════════════════════════════════════════════════════════╝

enum _Severity { critical, warning, caution, ok }

class MistakeAnalyzerScreen extends StatefulWidget {
  const MistakeAnalyzerScreen({super.key});

  @override
  State<MistakeAnalyzerScreen> createState() => _MistakeAnalyzerScreenState();
}

class _MistakeAnalyzerScreenState extends State<MistakeAnalyzerScreen> {
  final _dataService = DataService();
  final _srService   = SpacedRepetitionService();
  final _aiService   = AIService();

  bool    _loading     = true;
  bool    _aiAnalyzing = false;
  String? _aiResult;

  // subject display name → count
  Map<String, int>         _failedBySubject        = {};
  // subject display name → top 3 topic strings
  Map<String, List<String>> _failedTopicsBySubject  = {};
  int _totalFailed  = 0;
  int _totalStudied = 0;

  @override
  void initState() {
    super.initState();
    _analyzeData();
  }

  // ── Data Loading ───────────────────────────────────────────────────────────

  Future<void> _analyzeData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _dataService.loadAllTopics(),
        _srService.getAllData(),
      ]);

      final topics  = results[0] as List<Topic>;
      final sm2Map  = results[1] as Map<String, SM2CardData>;

      // cardId → (subjectName, topicName)
      final Map<String, ({String subject, String topic})> cardInfo = {};
      for (final t in topics) {
        final topicLabel = t.topic.isNotEmpty ? t.topic : t.chapter;
        for (final fc in t.flashcards) {
          cardInfo[fc.id] = (subject: t.subject, topic: topicLabel);
        }
        for (final cc in t.clinicalCases) {
          if (cc.id.isNotEmpty) {
            cardInfo[cc.id] = (subject: t.subject, topic: topicLabel);
          }
        }
      }

      // Count failures
      final Map<String, int>          failedBySubject   = {};
      final Map<String, Map<String, int>> failedTopicRaw = {};
      int total   = 0;
      int studied = 0;

      for (final entry in sm2Map.entries) {
        final d = entry.value;
        if (d.repetitions > 0 || d.lastQuality != null) studied++;
        if (d.lastQuality == 1) {
          total++;
          final info    = cardInfo[entry.key];
          final subject = info?.subject.isNotEmpty == true ? info!.subject : 'Diğer';
          final topic   = info?.topic.isNotEmpty  == true ? info!.topic  : 'Genel';
          failedBySubject[subject] = (failedBySubject[subject] ?? 0) + 1;
          failedTopicRaw[subject] ??= {};
          failedTopicRaw[subject]![topic] =
              (failedTopicRaw[subject]![topic] ?? 0) + 1;
        }
      }

      // Sort subjects by failure count desc
      final sorted = failedBySubject.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final Map<String, int>          sortedFailed  = {};
      final Map<String, List<String>> topicsPerSubj = {};
      for (final e in sorted) {
        sortedFailed[e.key] = e.value;
        final topicEntries = (failedTopicRaw[e.key] ?? {}).entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topicsPerSubj[e.key] = topicEntries
            .take(3)
            .map((t) => '${t.key} (${t.value})')
            .toList();
      }

      setState(() {
        _failedBySubject       = sortedFailed;
        _failedTopicsBySubject = topicsPerSubj;
        _totalFailed           = total;
        _totalStudied          = studied;
        _loading               = false;
        _aiAnalyzing           = total > 0;
      });

      if (total > 0) _runAiAnalysis(sortedFailed, topicsPerSubj);
    } catch (e) {
      debugPrint('MistakeAnalyzerScreen: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAiAnalysis(
    Map<String, int>          failedBySubject,
    Map<String, List<String>> topicsPerSubj,
  ) async {
    final buf = StringBuffer();
    for (final e in failedBySubject.entries.take(6)) {
      buf.writeln('${e.key}: ${e.value} hata');
      for (final t in (topicsPerSubj[e.key] ?? [])) {
        buf.writeln('  - $t');
      }
    }

    final result = await _aiService.analyzeWeakness(buf.toString());
    if (mounted) {
      setState(() {
        _aiResult    = result;
        _aiAnalyzing = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  _Severity _getSeverity(int count) {
    if (count >= 20) return _Severity.critical;
    if (count >= 10) return _Severity.warning;
    if (count >= 5)  return _Severity.caution;
    return _Severity.ok;
  }

  Color _severityColor(_Severity s) {
    switch (s) {
      case _Severity.critical: return AppTheme.error;
      case _Severity.warning:  return const Color(0xFFF97316); // orange
      case _Severity.caution:  return AppTheme.neonGold;
      case _Severity.ok:       return AppTheme.success;
    }
  }

  String _severityLabel(_Severity s) {
    switch (s) {
      case _Severity.critical: return 'KRİTİK';
      case _Severity.warning:  return 'UYARI';
      case _Severity.caution:  return 'DİKKAT';
      case _Severity.ok:       return 'NORMAL';
    }
  }

  /// Subject display name → SubjectModule id
  String? _subjectNameToId(String name) {
    try {
      return SubjectRegistry.modules
          .firstWhere((m) => m.name == name)
          .id;
    } catch (_) {
      return null;
    }
  }

  void _navigateToStudy(String subjectName) {
    HapticFeedback.mediumImpact();
    final id = _subjectNameToId(subjectName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          subjectId: id,
          initialMode: FlashcardMode.failedOnly,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1A0A2E)]
                : [const Color(0xFFFDF4FF), const Color(0xFFFFF4F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              Expanded(
                child: _loading
                    ? _buildLoadingState()
                    : _totalFailed == 0
                        ? _buildEmptyState(isDark)
                        : _buildContent(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              size: 20,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.error, AppTheme.coral]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.error.withValues(alpha: 0.45),
                    blurRadius: 14)
              ],
            ),
            child: const Icon(Icons.analytics_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hata Analiz Motoru',
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'SM-2 tabanlı zayıflık haritası',
                  style: GoogleFonts.inter(
                    color: AppTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_totalFailed > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.4)),
              ),
              child: Text(
                '$_totalFailed hata',
                style: GoogleFonts.inter(
                    color: AppTheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }

  // ── States ─────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.coral),
          const SizedBox(height: 16),
          Text('SM-2 verileri taranıyor...',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            'Harika! Kayıtlı hata yok.',
            style: GoogleFonts.inter(
              color: isDark
                  ? AppTheme.textPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tüm kartları doğru cevapladın veya henüz çalışmaya başlamadın.',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────────

  Widget _buildContent(bool isDark) {
    final maxCount = _failedBySubject.values.isNotEmpty
        ? _failedBySubject.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          _buildSummaryHeader(isDark),
          const SizedBox(height: 28),

          // ── Branch Bars ─────────────────────────────────────────────────
          _SectionTitle(
              label: 'Branş Bazlı Hata Dağılımı',
              icon: Icons.bar_chart_rounded,
              isDark: isDark),
          const SizedBox(height: 14),

          ..._failedBySubject.entries.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _BranchBar(
                subject: e.key,
                count: e.value,
                maxCount: maxCount,
                severity: _getSeverity(e.value),
                severityColor: _severityColor(_getSeverity(e.value)),
                severityLabel: _severityLabel(_getSeverity(e.value)),
                topics: _failedTopicsBySubject[e.key] ?? [],
                isDark: isDark,
                animDelay: 100 + i * 80,
                onStudyTap: () => _navigateToStudy(e.key),
              ),
            );
          }),

          const SizedBox(height: 28),

          // ── AI Analysis ─────────────────────────────────────────────────
          _SectionTitle(
              label: 'AI Örüntü Analizi',
              icon: Icons.psychology_rounded,
              isDark: isDark),
          const SizedBox(height: 14),
          _buildAiCard(isDark),

          // ── Gap Closing Plan ────────────────────────────────────────────
          if (_aiResult != null) ...[
            const SizedBox(height: 28),
            _SectionTitle(
                label: 'Eksik Kapatma Planı',
                icon: Icons.task_alt_rounded,
                isDark: isDark),
            const SizedBox(height: 14),
            _buildGapPlan(isDark),
          ],
        ],
      ),
    );
  }

  // ── Summary Header ─────────────────────────────────────────────────────────

  Widget _buildSummaryHeader(bool isDark) {
    final criticalCount =
        _failedBySubject.values.where((v) => v >= 20).length;
    final warningCount =
        _failedBySubject.values.where((v) => v >= 10 && v < 20).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A0E1E), const Color(0xFF1A0A2E)]
              : [const Color(0xFFFFF0F0), const Color(0xFFF3ECFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.38), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalFailed Hata Tespit Edildi',
                  style: GoogleFonts.inter(
                    color: AppTheme.error,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_failedBySubject.length} branşta zayıflık  •  '
                  '$_totalStudied kart analiz edildi',
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (criticalCount > 0)
                _StatBadge(
                    label: 'KRİTİK',
                    count: criticalCount,
                    color: AppTheme.error),
              if (warningCount > 0) ...[
                const SizedBox(height: 6),
                _StatBadge(
                    label: 'UYARI',
                    count: warningCount,
                    color: const Color(0xFFF97316)),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ── AI Card ────────────────────────────────────────────────────────────────

  Widget _buildAiCard(bool isDark) {
    if (_aiAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          border: Border.all(
              color: AppTheme.violet.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppTheme.coral, AppTheme.violet]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 18),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                        duration: 1500.ms,
                        color: AppTheme.violet.withValues(alpha: 0.6)),
                const SizedBox(width: 12),
                Text(
                  'Hata örüntüleri analiz ediliyor...',
                  style: GoogleFonts.inter(
                    color: AppTheme.violet,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 13,
                  width: i == 3 ? 160 : double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppTheme.violet.withValues(alpha: 0.1),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                        duration: 1200.ms,
                        delay: Duration(milliseconds: i * 200),
                        color: AppTheme.violet.withValues(alpha: 0.35)),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    if (_aiResult == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF130E24), const Color(0xFF0F1A2E)]
              : [const Color(0xFFF3ECFF), const Color(0xFFEFF8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border:
            Border.all(color: AppTheme.violet.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet
                .withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
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
                      colors: [AppTheme.coral, AppTheme.violet]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Profesör AI Analizi',
                style: GoogleFonts.inter(
                  color: isDark
                      ? AppTheme.textPrimary
                      : AppTheme.lightTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AiResultText(text: _aiResult!, isDark: isDark),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08, end: 0);
  }

  // ── Gap Closing Plan ───────────────────────────────────────────────────────

  Widget _buildGapPlan(bool isDark) {
    return Column(
      children: _failedBySubject.entries.take(3).toList().asMap().entries.map(
        (entry) {
          final i = entry.key;
          final e = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GapPlanCard(
              priority: i + 1,
              subject: e.key,
              failCount: e.value,
              severityColor: _severityColor(_getSeverity(e.value)),
              severityLabel: _severityLabel(_getSeverity(e.value)),
              isDark: isDark,
              animDelay: i * 120,
              onStudyTap: () => _navigateToStudy(e.key),
            ),
          );
        },
      ).toList(),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  Private Widgets                                                          ║
// ╚══════════════════════════════════════════════════════════════════════════╝

// ── Section Title ──────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  const _SectionTitle(
      {required this.label, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.coral, size: 18),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: isDark
                ? AppTheme.textSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Stat Badge ─────────────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$count $label',
        style: GoogleFonts.inter(
            color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ── Branch Bar ─────────────────────────────────────────────────────────────
class _BranchBar extends StatelessWidget {
  final String subject;
  final int count;
  final int maxCount;
  final _Severity severity;
  final Color severityColor;
  final String severityLabel;
  final List<String> topics;
  final bool isDark;
  final int animDelay;
  final VoidCallback onStudyTap;

  const _BranchBar({
    required this.subject,
    required this.count,
    required this.maxCount,
    required this.severity,
    required this.severityColor,
    required this.severityLabel,
    required this.topics,
    required this.isDark,
    required this.animDelay,
    required this.onStudyTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount > 0 ? count / maxCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark
            ? severityColor.withValues(alpha: 0.06)
            : severityColor.withValues(alpha: 0.04),
        border:
            Border.all(color: severityColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: subject + severity badge + count
          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: severityColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  severityLabel,
                  style: GoogleFonts.inter(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count hata',
                style: GoogleFonts.inter(
                  color: severityColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Animated bar
          LayoutBuilder(builder: (ctx, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: Duration(milliseconds: 700 + animDelay),
                  curve: Curves.easeOutExpo,
                  builder: (_, v, __) => Container(
                    height: 8,
                    width: constraints.maxWidth * v,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          severityColor,
                          severityColor.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: severityColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),

          // Topics
          if (topics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: topics
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.inter(
                          color: severityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 12),

          // Study button
          GestureDetector(
            onTap: onStudyTap,
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    severityColor,
                    severityColor.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: severityColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Hataları Çalış',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: Duration(milliseconds: animDelay))
        .slideX(begin: 0.06, end: 0, curve: Curves.easeOutExpo);
  }
}

// ── Gap Plan Card ──────────────────────────────────────────────────────────
class _GapPlanCard extends StatelessWidget {
  final int priority;
  final String subject;
  final int failCount;
  final Color severityColor;
  final String severityLabel;
  final bool isDark;
  final int animDelay;
  final VoidCallback onStudyTap;

  const _GapPlanCard({
    required this.priority,
    required this.subject,
    required this.failCount,
    required this.severityColor,
    required this.severityLabel,
    required this.isDark,
    required this.animDelay,
    required this.onStudyTap,
  });

  String get _actionText {
    if (failCount >= 20) return '"Yanlışlar" modunda tüm $subject kartlarını tekrar et.';
    if (failCount >= 10) return '$subject zayıf konularını flashcard modunda pekiştir.';
    return '$subject kartlarını dueOnly modunda gözden geçir.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? AppTheme.surface : Colors.white,
        border: Border.all(
            color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [severityColor, severityColor.withValues(alpha: 0.6)],
              ),
              boxShadow: [
                BoxShadow(
                    color: severityColor.withValues(alpha: 0.4),
                    blurRadius: 10)
              ],
            ),
            child: Center(
              child: Text(
                '$priority',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.inter(
                        color: isDark
                            ? AppTheme.textPrimary
                            : AppTheme.lightTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$failCount hata',
                      style: GoogleFonts.inter(
                          color: severityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _actionText,
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onStudyTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: severityColor.withValues(alpha: 0.12),
                      border: Border.all(
                          color: severityColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: severityColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Hemen Çalış',
                          style: GoogleFonts.inter(
                            color: severityColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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
            duration: 500.ms,
            delay: Duration(milliseconds: 200 + animDelay))
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutExpo);
  }
}

// ── AI Result Text (markdown-lite renderer) ────────────────────────────────
class _AiResultText extends StatelessWidget {
  final String text;
  final bool isDark;
  const _AiResultText({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              line.replaceFirst('### ', ''),
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }
        if (line.startsWith('- ') || line.startsWith('1. ') ||
            line.startsWith('2. ') || line.startsWith('3. ')) {
          final cleaned = line
              .replaceAll('**', '')
              .replaceAll('*', '');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 8),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.coral,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    cleaned.replaceFirst(RegExp(r'^[-\d]+[.)]\s*'), ''),
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
          );
        }
        if (line.trim().isEmpty) return const SizedBox(height: 4);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line.replaceAll('**', '').replaceAll('*', ''),
            style: GoogleFonts.inter(
              color: isDark
                  ? AppTheme.textSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        );
      }).toList(),
    );
  }
}
