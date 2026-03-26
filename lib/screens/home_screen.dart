import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/fullscreen_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/progress_model.dart';
import '../models/topic_model.dart';
import '../widgets/ai_insight_sheet.dart';
import '../widgets/goal_setup_sheet.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/readiness_card.dart';
import '../models/subject_registry.dart';
import '../models/sm2_model.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';
import '../services/user_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/theme_service.dart';
import '../utils/transitions.dart';
import '../utils/error_handler.dart';
import 'flashcard_screen.dart';
import 'case_study_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'focus_screen.dart';
import 'spots_screen.dart';
import 'collections_screen.dart';
import 'mock_exam_setup_screen.dart';
import 'mistake_analyzer_screen.dart';
import '../services/focus_service.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  HomeScreen                                                              ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class HomeScreen extends StatefulWidget {
  /// Web AdaptiveAppShell içinde kullanılırken true yapılır:
  /// shell kendi sidebar nav'ını sağladığından HomeScreen'in
  /// alt nav çubuğunu gizler.
  final bool hideBottomNav;

  const HomeScreen({super.key, this.hideBottomNav = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dataService     = DataService();
  final _progressService = ProgressService();
  final _userService     = UserService();

  String?       _selectedSubjectId;
  StudyProgress _progress = const StudyProgress();
  UserProfile   _user     = const UserProfile();
  List<Topic>   _topics   = [];
  bool          _loading  = true;
  int           _navIndex = 0;
  SrsSummary    _flashcardSummary = const SrsSummary(newCount: 0, toReviewCount: 0, learnedCount: 0, bookmarkCount: 0);
  SrsSummary    _caseSummary      = const SrsSummary(newCount: 0, toReviewCount: 0, learnedCount: 0, bookmarkCount: 0);
  Map<String, SM2CardData> _sm2Data = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      final results = await Future.wait([
        _dataService.loadTopics(subjectId: _selectedSubjectId),
        _progressService.loadProgress(),
        SpacedRepetitionService().getAllData(),
        _userService.loadUser(),
      ]);
      if (mounted) {
        final topics   = results[0] as List<Topic>;
        final progress = results[1] as StudyProgress;
        final sm2Data  = results[2] as Map<String, SM2CardData>;
        final user     = results[3] as UserProfile;

        final fcIds = <String>[];
        final ccIds = <String>[];
        for (final t in topics) {
          fcIds.addAll(t.flashcards.map((fc) => fc.id));
          ccIds.addAll(t.clinicalCases.map((cc) => cc.id).where((id) => id.isNotEmpty));
        }

        final summaries = await Future.wait([
          SpacedRepetitionService().getSummary(fcIds, dailyGoal: progress.dailyGoal),
          SpacedRepetitionService().getSummary(ccIds, dailyGoal: progress.dailyGoal),
        ]);

        setState(() {
          _topics           = topics;
          _progress         = progress;
          _user             = user;
          _flashcardSummary = summaries[0];
          _caseSummary      = summaries[1];
          _sm2Data          = sm2Data;
          _loading          = false;
        });
      }
    } catch (e) {
      debugPrint('🚨 KRİTİK HATA: Veri yükleme başarısız oldu: $e');
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.showSnackbar(
          context,
          message: 'Veri güncelleniyor, lütfen bekleyin...',
          isError: false,
          onRetry: _loadData,
        );
      }
    }
  }

  /// Ekrandan geri dönünce çağrılır — loading göstermeden istatistikleri günceller
  Future<void> _refreshStats() async {
    if (!mounted || _topics.isEmpty) return;
    try {
      final results = await Future.wait([
        _progressService.loadProgressCached(), // Firestore'a gitme — yerel yeterli
        SpacedRepetitionService().getAllData(),
        _userService.loadUser(),
      ]);
      if (!mounted) return;
      final progress = results[0] as StudyProgress;
      final sm2Data  = results[1] as Map<String, SM2CardData>;
      final user     = results[2] as UserProfile;

      final fcIds = <String>[];
      final ccIds = <String>[];
      for (final t in _topics) {
        fcIds.addAll(t.flashcards.map((fc) => fc.id));
        ccIds.addAll(t.clinicalCases.map((cc) => cc.id).where((id) => id.isNotEmpty));
      }

      final summaries = await Future.wait([
        SpacedRepetitionService().getSummary(fcIds, dailyGoal: progress.dailyGoal),
        SpacedRepetitionService().getSummary(ccIds, dailyGoal: progress.dailyGoal),
      ]);

      if (mounted) {
        setState(() {
          _progress         = progress;
          _user             = user;
          _flashcardSummary = summaries[0];
          _caseSummary      = summaries[1];
          _sm2Data          = sm2Data;
        });
      }
    } catch (e) {
      debugPrint('_refreshStats hata: $e');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Ana ekranda geri tuşu uygulamayı kapatmasın / siyah ekran olmasın
      child: Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF0F172A), Color(0xFF1E293B)]
                : const [Color(0xFFEDF3FF), Color(0xFFE8F0FF), Color(0xFFF0F5FF)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Ambient Neon Glows — RepaintBoundary ile izole edildi ────────
            Positioned(top: -160, left: -120,
                child: RepaintBoundary(child: _AmbientBlob(color: AppTheme.cyan,      size: 500, opacity: isDark ? 0.12 : 0.05, pulseDuration: const Duration(milliseconds: 6000)))),
            Positioned(top: 180, right: -140,
                child: RepaintBoundary(child: _AmbientBlob(color: AppTheme.neonPink,  size: 420, opacity: isDark ? 0.10 : 0.04, pulseDuration: const Duration(milliseconds: 7500)))),
            Positioned(bottom: 150, left: -100,
                child: RepaintBoundary(child: _AmbientBlob(color: AppTheme.neonPurple,size: 360, opacity: isDark ? 0.10 : 0.04, pulseDuration: const Duration(milliseconds: 5200)))),
            Positioned(bottom: -80, right: -60,
                child: RepaintBoundary(child: _AmbientBlob(color: AppTheme.cyan,      size: 300, opacity: isDark ? 0.07 : 0.03, pulseDuration: const Duration(milliseconds: 8000)))),

            // ── Main Content ────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Web'de header gereksiz — sol panel profili gösteriyor
                  if (!kIsWeb) _buildHeader(isDark),
                  // ── Platform-Aware Content ──────────────────────────
                  Expanded(
                    child: _loading
                        ? _buildLoadingState()
                        : kIsWeb
                            ? LayoutBuilder(
                                builder: (ctx, c) => c.maxWidth > 900
                                    ? _buildDesktopDashboard(isDark)
                                    : _buildMobileScrollContent(isDark),
                              )
                            : _buildMobileScrollContent(isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.hideBottomNav ? null : _buildBottomNav(isDark),
      ),
    );
  }

  // ── Mobile Scroll Content (mevcut layout) ─────────────────────────────────
  Widget _buildMobileScrollContent(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.cyan,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 110,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildGreeting(isDark),
                const SizedBox(height: 16),
                _buildAiCoachPanel(isDark),
                const SizedBox(height: 16),
                _buildSmartTaskCard(isDark),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (ctx, c) {
                  if (c.maxWidth > 820) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _WebHoverSection(isDark: isDark, child: _buildFlashcardHub(isDark))),
                        const SizedBox(width: 16),
                        Expanded(child: _WebHoverSection(isDark: isDark, child: _buildCaseHub(isDark))),
                      ],
                    );
                  }
                  return Column(children: [
                    _buildFlashcardHub(isDark),
                    const SizedBox(height: 32),
                    _buildCaseHub(isDark),
                  ]);
                }),
                const SizedBox(height: 20),
                _buildSpotBilgilerButton(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop 3-Column Dashboard ─────────────────────────────────────────────
  Widget _buildDesktopDashboard(bool isDark) {
    final divColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      children: [
        // ── Desktop Top Bar: Hızlı Erişim ────────────────────────────
        Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: divColor)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Ana Sayfa',
                style: GoogleFonts.inter(
                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildIconTrio(isDark),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // ── 3 Sütun Dashboard ─────────────────────────────────────────
        Expanded(child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sol Panel (240px) ─────────────────────────────────────────
        SizedBox(
          width: 240,
          child: Container(
            decoration:
                BoxDecoration(border: Border(right: BorderSide(color: divColor))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              physics: const BouncingScrollPhysics(),
              child: _buildDesktopLeftPanel(isDark),
            ),
          ),
        ),

        // ── Orta Panel (flex) ─────────────────────────────────────────
        Expanded(
          flex: 5,
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.cyan,
            backgroundColor: isDark ? AppTheme.surface : Colors.white,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildGreeting(isDark),
                  const SizedBox(height: 16),
                  _buildAiCoachPanel(isDark),
                  const SizedBox(height: 16),
                  _buildSmartTaskCard(isDark),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _WebHoverSection(
                              isDark: isDark,
                              child: _buildFlashcardHub(isDark))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _WebHoverSection(
                              isDark: isDark, child: _buildCaseHub(isDark))),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // ── Sağ Panel (260px) ─────────────────────────────────────────
        SizedBox(
          width: 260,
          child: Container(
            decoration:
                BoxDecoration(border: Border(left: BorderSide(color: divColor))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              physics: const BouncingScrollPhysics(),
              child: _buildDesktopRightPanel(isDark),
            ),
          ),
        ),
      ]),
      ),
      ],
    );
  }

  // ── Desktop Sol Panel: Profil + İstatistikler ─────────────────────────────
  Widget _buildDesktopLeftPanel(bool isDark) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final surfaceBg = isDark ? AppTheme.surface : Colors.white;
    final divColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);
    final accuracy = _progress.totalFlashcardsStudied > 0
        ? (_progress.correctAnswers / _progress.totalFlashcardsStudied * 100).round()
        : 0;
    final dailyPct = _progress.dailyGoal > 0
        ? (_progress.todayStudied / _progress.dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Profil Kartı ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divColor),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.20)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + isim
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.cyan, AppTheme.neonPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.cyan.withValues(alpha: 0.30),
                              blurRadius: 10)
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _user.profileEmoji,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user.name,
                            style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_user.targetBranch.isNotEmpty)
                            Text(
                              _user.targetBranch,
                              style: GoogleFonts.inter(
                                  color: AppTheme.cyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: divColor),
                const SizedBox(height: 12),
                // İstatistikler
                Row(
                  children: [
                    Expanded(
                        child: _DesktopStatChip(
                            icon: Icons.local_fire_department_rounded,
                            value: '${_progress.currentStreak}',
                            label: 'Seri',
                            color: AppTheme.coral,
                            isDark: isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _DesktopStatChip(
                            icon: Icons.check_circle_rounded,
                            value: '%$accuracy',
                            label: 'Doğruluk',
                            color: AppTheme.success,
                            isDark: isDark)),
                  ],
                ),
                const SizedBox(height: 8),
                _DesktopStatChip(
                    icon: Icons.style_rounded,
                    value: '${_progress.totalFlashcardsStudied}',
                    label: 'Toplam Çalışılan Kart',
                    color: AppTheme.neonPurple,
                    isDark: isDark),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Günlük İlerleme ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Günlük Hedef',
                        style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    Text(
                      '${_progress.todayStudied}/${_progress.dailyGoal}',
                      style: GoogleFonts.inter(
                          color: AppTheme.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: dailyPct,
                    minHeight: 7,
                    backgroundColor:
                        AppTheme.cyan.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.cyan),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _progress.baseScore.toStringAsFixed(0),
                      style: GoogleFonts.inter(
                          color: subColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color: AppTheme.neonGold.withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        '→ ${_progress.targetScore.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            color: AppTheme.neonGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: subColor),
                    const SizedBox(width: 4),
                    Text(
                      'Sınava ${_progress.daysToExam} gün kaldı',
                      style: GoogleFonts.inter(
                          color: subColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Haftalık Aktivite ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Haftalık Aktivite',
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _buildWeeklyBarChart(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Desktop Sağ Panel: Hızlı Erişim + Oturum İstatistikleri ───────────────
  Widget _buildDesktopRightPanel(bool isDark) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final surfaceBg = isDark ? AppTheme.surface : Colors.white;
    final divColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hızlı Erişim ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HIZLI ERİŞİM',
                style: GoogleFonts.inter(
                    color: subColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              _DesktopQuickLink(
                icon: Icons.local_fire_department_rounded,
                label: 'Spot Bilgiler',
                sublabel: 'TUS\'ta en çok çıkan',
                color: AppTheme.neonPurple,
                isDark: isDark,
                onTap: () => Navigator.push(
                    context, AppRoute.slideUp(const SpotsScreen())),
              ),
              const SizedBox(height: 6),
              _DesktopQuickLink(
                icon: Icons.assignment_rounded,
                label: 'Deneme Sınavı',
                sublabel: 'Performansını test et',
                color: AppTheme.coral,
                isDark: isDark,
                onTap: () => Navigator.push(
                    context, AppRoute.slideUp(const MockExamSetupScreen())),
              ),
              const SizedBox(height: 6),
              _DesktopQuickLink(
                icon: Icons.analytics_rounded,
                label: 'Hata Analizi',
                sublabel: 'Zayıf noktalarını bul',
                color: AppTheme.error,
                isDark: isDark,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MistakeAnalyzerScreen())),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Kart & Vaka Özeti ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kart & Vaka Özeti',
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _DesktopMiniStat(
                            value: '${_flashcardSummary.cardCount}',
                            label: 'Kart',
                            color: AppTheme.cyan,
                            isDark: isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _DesktopMiniStat(
                            value: '${_caseSummary.cardCount}',
                            label: 'Vaka',
                            color: AppTheme.neonPurple,
                            isDark: isDark)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _DesktopMiniStat(
                            value: '${_flashcardSummary.toReviewCount}',
                            label: 'Bekleyen',
                            color: AppTheme.neonGold,
                            isDark: isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _DesktopMiniStat(
                            value: '${_flashcardSummary.learnedCount}',
                            label: 'Öğrenildi',
                            color: AppTheme.success,
                            isDark: isDark)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Klavye İpuçları (web'e özel) ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cyan.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppTheme.cyan.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.keyboard_rounded,
                        color: AppTheme.cyan, size: 14),
                    const SizedBox(width: 6),
                    Text('Klavye Kısayolları',
                        style: GoogleFonts.inter(
                            color: AppTheme.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  ('Alt+1', 'Ana Sayfa'),
                  ('Alt+2', 'Koleksiyonlar'),
                  ('Alt+3', 'Odak Modu'),
                  ('Alt+4', 'Deneme'),
                  ('Alt+5', 'Analitik'),
                  ('Alt+6', 'Profil'),
                ].map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(e.$1,
                                style: GoogleFonts.inter(
                                    color: AppTheme.cyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Text(e.$2,
                              style: GoogleFonts.inter(
                                  color: subColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Haftalık Bar Grafik ────────────────────────────────────────────────────
  Widget _buildWeeklyBarChart(bool isDark) {
    const dayLabels = ['Pt', 'Sl', 'Çr', 'Pr', 'Cm', 'Ct', 'Pz'];
    final now = DateTime.now();
    // Son 7 günü Map'ten çıkar
    final data = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return _progress.weeklyStats[key] ?? 0;
    });
    final maxVal = data
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 9999);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final val = data[i];
        final pct = val / maxVal;
        final dayOfWeek =
            now.subtract(Duration(days: 6 - i)).weekday - 1; // 0=Mon
        final isToday = i == 6;
        return Column(
          children: [
            Container(
              width: 22,
              height: 48,
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 350 + i * 40),
                curve: Curves.easeOutCubic,
                width: 12,
                height: (48 * pct).clamp(3.0, 48.0),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppTheme.cyan
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.10)),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                              color: AppTheme.cyan.withValues(alpha: 0.40),
                              blurRadius: 8)
                        ]
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayLabels[dayOfWeek % 7],
              style: GoogleFonts.inter(
                color: isToday
                    ? AppTheme.cyan
                    : (isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary),
                fontSize: 9,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildAnimatedAvatar(bool isDark) {
    final hasImage = _user.profileImagePath != null &&
        _user.profileImagePath!.isNotEmpty &&
        !kIsWeb;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, AppRoute.slideUp(const ProfileScreen()));
        _refreshStats();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasImage
                  ? null
                  : const LinearGradient(
                      colors: [AppTheme.cyan, AppTheme.neonPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              image: hasImage
                  ? DecorationImage(
                      image: FileImage(File(_user.profileImagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.40),
                    blurRadius: 14,
                    spreadRadius: 2),
              ],
            ),
            child: hasImage
                ? null
                : Center(
                    child: Text(_user.profileEmoji,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.easeOutBack)
        .then()
        .shimmer(
            delay: 1500.ms,
            duration: 1200.ms,
            color: AppTheme.cyan.withValues(alpha: 0.25))
        .then()
        .shake(
            delay: 8000.ms,
            duration: 600.ms,
            hz: 3,
            offset: const Offset(1.5, 0));
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          // Gradient Avatar → Profil ekranına git
          _buildAnimatedAvatar(isDark),
          const SizedBox(width: 12),

          Expanded(
            child: Text('${_user.name}! 👋',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: textColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ),
          const SizedBox(width: 8),

          // 🖥️ Fullscreen toggle (only visible on web + desktop)
          const FullscreenButton(),
          const SizedBox(width: 4),

          // ── Tema Toggle Butonu ─────────────────────────────────────
          ValueListenableBuilder<AppThemeMode>(
            valueListenable: ThemeService.mode,
            builder: (_, mode, __) {
              final dark = mode == AppThemeMode.dark;
              return GestureDetector(
                onTap: ThemeService.toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: 80, height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: dark
                          ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)]
                          : [const Color(0xFFFFB347), const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFF4A90D9).withValues(alpha: 0.5)
                          : const Color(0xFFFFD93D).withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: dark
                            ? const Color(0xFF4A90D9).withValues(alpha: 0.35)
                            : const Color(0xFFFF6B6B).withValues(alpha: 0.40),
                        blurRadius: 14,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Arka plan dekoratif noktalar (yıldız / güneş ışınları)
                      if (dark) ...[
                        Positioned(left: 10, top: 8,
                          child: Container(width: 3, height: 3,
                            decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle))),
                        Positioned(left: 18, top: 18,
                          child: Container(width: 2, height: 2,
                            decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle))),
                        Positioned(left: 12, bottom: 8,
                          child: Container(width: 2, height: 2,
                            decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle))),
                      ],
                      // Kaydırıcı top
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Icon(
                              dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              key: ValueKey(dark),
                              size: 16,
                              color: dark ? const Color(0xFF1A1A2E) : const Color(0xFFFF8E53),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // 🧠ℹ️🔔 Premium İkon Üçlüsü
          _buildIconTrio(isDark),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: -0.05, end: 0);
  }

  // ── Premium İkon Üçlüsü (Mobil sağ üst + Desktop top bar) ───────────────
  Widget _buildIconTrio(bool isDark) {
    final bgBase = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);
    final divCol = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: bgBase,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🧠 Akıllı Koç
              _TrioButton(
                icon: Icons.psychology_rounded,
                color: AppTheme.cyan,
                glowColor: AppTheme.cyan,
                tooltip: 'Akıllı Koç',
                isDark: isDark,
                onTap: _showAiInsightSheet,
              ),
              // Divider
              Container(width: 1, height: 22, color: divCol),
              // ℹ️ Bilgi
              _TrioButton(
                icon: Icons.info_outline_rounded,
                color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                glowColor: AppTheme.neonPurple,
                tooltip: 'Nasıl Çalışır',
                isDark: isDark,
                onTap: () => _showInfoSheet(context, isDark),
              ),
              // Divider
              Container(width: 1, height: 22, color: divCol),
              // 🔔 Bildirimler
              _TrioButtonWithBadge(
                icon: Icons.notifications_rounded,
                color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                isDark: isDark,
                onTap: _showAppNotifications,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info Sheet ────────────────────────────────────────────────────────────
  void _showInfoSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(isDark: isDark),
    );
  }

  // ── Günün Akıllı Görevi ────────────────────────────────────────────────────
  // ── Günün Akıllı Görevi — Kompakt Versiyon ─────────────────────────────────
  // ── AI Koç Çalışma Rehberi Paneli ────────────────────────────────────────
  Widget _buildAiCoachPanel(bool isDark) {
    final targetScore    = _progress.targetScore.toStringAsFixed(0);
    final daysToExam     = _progress.daysToExam;
    final recommended    = _progress.recommendedDailyGoal;
    final todayStudied   = _progress.todayStudied;
    final dailyGoal      = _progress.dailyGoal;
    final remaining      = (dailyGoal - todayStudied).clamp(0, 9999);
    final dueCards       = _flashcardSummary.toReviewCount;
    final dueCases       = _caseSummary.toReviewCount;

    // Tekrar vakti gelen SM-2 kartları — branş bazında say
    final Map<String, int> dueBranchMap = {};
    for (final t in _topics) {
      for (final fc in t.flashcards) {
        final d = _sm2Data[fc.id];
        if (d != null && d.isDue && t.subject.isNotEmpty) {
          dueBranchMap[t.subject] = (dueBranchMap[t.subject] ?? 0) + 1;
        }
      }
    }
    final dueBranches = (dueBranchMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .toList();

    // Sınav aciliyeti rengi
    final examColor = daysToExam <= 30
        ? AppTheme.error
        : daysToExam <= 90
            ? AppTheme.neonGold
            : AppTheme.success;

    final textColor = isDark ? AppTheme.textPrimary   : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0E1628), const Color(0xFF12192E)]
                    : [Colors.white.withValues(alpha: 0.9), const Color(0xFFF0F8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.cyan.withValues(alpha: isDark ? 0.22 : 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cyan.withValues(alpha: isDark ? 0.18 : 0.08),
                  blurRadius: 28,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.neonPurple.withValues(alpha: isDark ? 0.10 : 0.04),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(10, 20),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Başlık satırı ─────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppTheme.cyan, AppTheme.neonPurple]),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyan.withValues(alpha: 0.40),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI Koç Çalışma Rehberi',
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    // Sınav sayacı badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: examColor.withValues(alpha: isDark ? 0.15 : 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: examColor.withValues(alpha: 0.40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_rounded,
                              color: examColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$daysToExam gün',
                            style: GoogleFonts.inter(
                              color: examColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Hedefi Güncelle butonu
                    GestureDetector(
                      onTap: () => showGoalSetupSheet(context, isDark, onSaved: _refreshStats),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.neonGold.withValues(alpha: isDark ? 0.15 : 0.10),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.35)),
                        ),
                        child: Icon(Icons.tune_rounded, color: AppTheme.neonGold, size: 15),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Hedef başlığı ─────────────────────────────────────
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                        fontSize: 13, color: subColor, height: 1.4),
                    children: [
                      const TextSpan(text: 'Hedeflediğin '),
                      TextSpan(
                        text: '$targetScore puan',
                        style: GoogleFonts.inter(
                          color: AppTheme.neonGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const TextSpan(text: ' için bugün yapman gerekenler:'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── İki stat chip ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _CoachChip(
                        icon: Icons.style_rounded,
                        label: 'Günlük Hedef',
                        value: '$remaining kart',
                        subValue: todayStudied > 0
                            ? '($todayStudied/$dailyGoal tamamlandı)'
                            : 'Henüz başlamadın',
                        color: AppTheme.cyan,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CoachChip(
                        icon: Icons.bolt_rounded,
                        label: 'Önerilen Tempo',
                        value: '$recommended kart/gün',
                        subValue: 'hedefe ulaşmak için',
                        color: AppTheme.neonPurple,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                // ── SM-2 Sıradaki görevler ────────────────────────────
                if (dueCards > 0 || dueCases > 0 || dueBranches.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.repeat_rounded,
                                color: AppTheme.neonGold, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              'Sıradaki Tekrar Görevleri',
                              style: GoogleFonts.inter(
                                color: AppTheme.neonGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            if (dueCards > 0)
                              _DueBadge(
                                  label: '$dueCards kart',
                                  color: AppTheme.cyan),
                            if (dueCases > 0) ...[
                              const SizedBox(width: 4),
                              _DueBadge(
                                  label: '$dueCases vaka',
                                  color: AppTheme.neonPurple),
                            ],
                          ],
                        ),
                        if (dueBranches.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...dueBranches.map((e) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: AppTheme.cyan
                                            .withValues(alpha: 0.6),
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      e.key,
                                      style: GoogleFonts.inter(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${e.value} kart',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.cyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 50.ms)
        .slideY(begin: -0.04, end: 0, curve: Curves.easeOutExpo);
  }

  // ── Doktor Selamlama ───────────────────────────────────────────────────────
  Widget _buildGreeting(bool isDark) {
    final isNew    = _progress.totalFlashcardsStudied == 0;
    final streak   = _progress.currentStreak;
    final firstName = _user.name.isNotEmpty
        ? _user.name.split(' ').first
        : 'Doktor';
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNew) ...[
                  Text(
                    'Hoş geldin, Dr. $firstName! 👋',
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Başarılarla dolu bir serüvene hazır mısın?',
                    style: GoogleFonts.inter(
                      color: subColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ] else ...[
                  Text(
                    'İyi çalışmalar, Dr. $firstName! 🩺',
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bugün hedefine bir adım daha yaklaşalım.',
                    style: GoogleFonts.inter(
                      color: subColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Streak badge — 2+ günden itibaren göster
          if (streak >= 2) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.40),
                    blurRadius: 12, spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.96, end: 1.04, duration: 1500.ms, curve: Curves.easeInOut),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 80.ms)
        .slideY(begin: -0.05, end: 0, curve: Curves.easeOutExpo);
  }

  // ── Sınav Hazırlık Seviyesi Kartı ─────────────────────────────────────────
  Widget _buildReadinessCard(bool isDark) {
    final totalSeen =
        _flashcardSummary.learnedCount + _flashcardSummary.toReviewCount;
    final masteryRatio = totalSeen > 0
        ? (_flashcardSummary.learnedCount / totalSeen).clamp(0.0, 1.0)
        : 0.0;
    final dailyRatio = _progress.dailyGoal > 0
        ? (_progress.todayStudied / _progress.dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final streakRatio = (_progress.currentStreak / 30.0).clamp(0.0, 1.0);

    final rd = computeReadiness(
      masteryRatio: masteryRatio,
      dailyRatio: dailyRatio,
      streakRatio: streakRatio,
      targetScore: _progress.targetScore,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ReadinessCard(
        readiness: rd.readiness,
        readinessPct: rd.readinessPct,
        gaugeColor: rd.gaugeColor,
        scoreIntensity: _progress.scoreIntensity,
        targetScore: _progress.targetScore,
        recommendedDailyGoal: _progress.recommendedDailyGoal,
        masteryTarget: rd.masteryTarget,
        currentMastery: rd.currentMastery,
        daysToExam: _progress.daysToExam,
        isDark: isDark,
      ),
    );
  }

  Widget _buildSmartTaskCard(bool isDark) {
    final dueCards = _flashcardSummary.toReviewCount.clamp(0, 20);
    final dueCases = _caseSummary.toReviewCount.clamp(0, 5);

    if (dueCards == 0 && dueCases == 0) return const SizedBox.shrink();

    // En çok hata yapılan branşlar (SM-2 lastQuality=1) — max 2
    final Map<String, int> failedBySubject = {};
    for (final t in _topics) {
      int fail = 0;
      for (final fc in t.flashcards) {
        final d = _sm2Data[fc.id];
        if (d != null && d.lastQuality == 1) fail++;
      }
      if (fail > 0 && t.subject.isNotEmpty) {
        failedBySubject[t.subject] = (failedBySubject[t.subject] ?? 0) + fail;
      }
    }
    final topSubjects = (failedBySubject.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(2)
        .map((e) => e.key)
        .toList();

    final estimatedMin = (dueCards * 0.5 + dueCases * 3).round().clamp(5, 60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E0E2C), const Color(0xFF0C1525)]
                : [const Color(0xFFFFF3F0), const Color(0xFFF3ECFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppTheme.coral.withValues(alpha: 0.40),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.coral.withValues(alpha: isDark ? 0.22 : 0.10),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Satır 1: İkon + Başlık + PREMIUM + Süre ───────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [AppTheme.coral, AppTheme.violet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.coral.withValues(alpha: 0.45),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.psychology_alt_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Günün Akıllı Görevi',
                          style: GoogleFonts.inter(
                            color: isDark
                                ? AppTheme.textPrimary
                                : AppTheme.lightTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppTheme.coral, AppTheme.violet]),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '~$estimatedMin dk',
                    style: GoogleFonts.inter(
                      color: AppTheme.coral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.bolt_rounded,
                      color: AppTheme.neonGold, size: 18),
                ],
              ),

              const SizedBox(height: 10),

              // ── Satır 2: Sayaçlar + Hata Branşları + Butonlar ──────────
              Row(
                children: [
                  _SmartCounter(
                    icon: Icons.style_rounded,
                    label: 'Kart',
                    count: dueCards,
                    color: AppTheme.cyan,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _SmartCounter(
                    icon: Icons.quiz_rounded,
                    label: 'Vaka',
                    count: dueCases,
                    color: AppTheme.violet,
                    isDark: isDark,
                  ),
                  if (topSubjects.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ...topSubjects.map((s) {
                      final lbl = s.length > 6 ? '${s.substring(0, 6)}…' : s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.error
                                .withValues(alpha: isDark ? 0.13 : 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppTheme.error
                                    .withValues(alpha: 0.30)),
                          ),
                          child: Text(
                            lbl,
                            style: GoogleFonts.inter(
                              color: AppTheme.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const Spacer(),
                  // ── Kompakt Butonlar ─────────────────────────────────
                  _CompactActionButton(
                    label: 'Fokus',
                    icon: Icons.play_arrow_rounded,
                    gradient: const LinearGradient(
                        colors: [AppTheme.coral, AppTheme.violet]),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _startSmartSession();
                    },
                  ),
                  const SizedBox(width: 8),
                  _CompactActionButton(
                    label: 'Hatalar',
                    icon: Icons.analytics_rounded,
                    outlineColor: AppTheme.error,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MistakeAnalyzerScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms, delay: 60.ms)
          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutExpo),
    );
  }

  void _startSmartSession() async {
    await Navigator.push(
      context,
      AppRoute.slideUp(
        FlashcardScreen(
          subjectIds: _progress.selectedSubjectIds.isNotEmpty
              ? _progress.selectedSubjectIds
              : null,
          initialMode: FlashcardMode.dueOnly,
          dailyGoal: 20,
        ),
      ),
    );
    _refreshStats();
  }

  // ── Flashcard Hub ──────────────────────────────────────────────────────────
  Widget _buildFlashcardHub(bool isDark) {
    return _buildHubSection(
      isDark: isDark,
      title: 'FlashKartlar',
      buttonLabel: 'FLASHKARTLAR',
      summary: _flashcardSummary,
      baseColor: AppTheme.cyan,
      bgImage: 'assets/images/tus_Deneme.jpg',
      folders: [
        (label: 'Doğrular', icon: Icons.check_circle_rounded, color: AppTheme.success, mode: FlashcardMode.learnedOnly),
        (label: 'Yanlışlar', icon: Icons.cancel_rounded, color: AppTheme.error, mode: FlashcardMode.failedOnly),
        (label: 'Favoriler', icon: Icons.bookmark_rounded, color: AppTheme.neonGold, mode: FlashcardMode.pocketOnly),
      ],
      onButtonTap: () => _showSubjectSelectionSheet(isCards: true, isDark: isDark),
      onFolderTap: (mode) async {
        await Navigator.push(context, AppRoute.slideUp(FlashcardScreen(initialMode: mode as FlashcardMode)));
        _refreshStats();
      },
    );
  }

  // ── Spot Bilgiler Hızlı Erişim ──────────────────────────────────────────────

  Widget _buildSpotBilgilerButton(bool isDark) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            AppRoute.slideUp(const SpotsScreen())),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.neonPurple.withValues(alpha: isDark ? 0.25 : 0.15)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arka plan gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A1230), const Color(0xFF0F1A2E)]
                        : [const Color(0xFFF0E6FF), const Color(0xFFE6F0FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Sağ taraf — dekoratif görsel
              Positioned(
                right: 0, top: 0, bottom: 0,
                child: SizedBox(
                  width: 110,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/ilerleme_gorseli.jpg',
                        fit: BoxFit.cover,
                        cacheWidth: 220,
                        cacheHeight: 160,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              (isDark ? const Color(0xFF1A1230) : const Color(0xFFF0E6FF)),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // İçerik
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.neonPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_fire_department_rounded,
                          color: AppTheme.neonPurple, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Spot Bilgiler',
                            style: GoogleFonts.inter(
                              color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('TUS\'ta en çok çıkan hap bilgiler',
                            style: GoogleFonts.inter(
                              color: subColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppTheme.neonPurple.withValues(alpha: 0.6), size: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sorular Hub (Eski Case Hub) ─────────────────────────────────────────────
  Widget _buildCaseHub(bool isDark) {
    return _buildHubSection(
      isDark: isDark,
      title: 'Sorular',
      buttonLabel: 'SORULAR',
      summary: _caseSummary,
      baseColor: const Color(0xFF6366F1), // Indigo
      bgImage: 'assets/images/sınav.jpg',
      folders: [
        (label: 'Doğrular', icon: Icons.check_circle_rounded, color: AppTheme.success, mode: CaseStudyMode.learnedOnly),
        (label: 'Yanlışlar', icon: Icons.cancel_rounded, color: AppTheme.error, mode: CaseStudyMode.failedOnly),
        (label: 'Favoriler', icon: Icons.bookmark_rounded, color: AppTheme.neonGold, mode: CaseStudyMode.pocketOnly),
      ],
      onButtonTap: () => _showSubjectSelectionSheet(isCards: false, isDark: isDark),
      onFolderTap: (mode) async {
        await Navigator.push(context, AppRoute.slideUp(CaseStudyScreen(initialMode: mode as CaseStudyMode)));
        _refreshStats();
      },
    );
  }

  // ── Reusable Hub Helper ────────────────────────────────────────────────────
  Widget _buildHubSection({
    required bool isDark,
    required String title,
    required String buttonLabel,
    required SrsSummary summary,
    required Color baseColor,
    String? bgImage,
    required List<({String label, IconData icon, Color color, dynamic mode})> folders,
    required VoidCallback onButtonTap,
    required Function(dynamic) onFolderTap,
  }) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2,
              ),
            ),
          ),
          // ── 3 Folder Cards ──────────────────────────────────────────────
          Row(
            children: folders.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              // Mode'a göre count — index'e değil, sıra değişse bile doğru kalır
              final isLearned = f.mode == FlashcardMode.learnedOnly || f.mode == CaseStudyMode.learnedOnly;
              final isFailed  = f.mode == FlashcardMode.failedOnly  || f.mode == CaseStudyMode.failedOnly;
              final count = isLearned ? summary.learnedCount
                          : isFailed  ? summary.toReviewCount
                          : summary.bookmarkCount;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                  child: _FolderCard(
                    label: f.label,
                    count: count,
                    color: f.color,
                    isDark: isDark,
                    onTap: count > 0 ? () => onFolderTap(f.mode) : null,
                  ).animate().fadeIn(duration: 600.ms, delay: (100 + i * 80).ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutExpo),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ── Action Button ────────────────────────────────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onButtonTap();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Arka plan görseli (varsa)
                  if (bgImage != null)
                    Image.asset(bgImage, fit: BoxFit.cover, cacheWidth: 600),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          baseColor.withValues(alpha: bgImage != null ? 0.82 : 1.0),
                          baseColor.withValues(alpha: bgImage != null ? 0.65 : 0.6),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  // Label
                  Center(
                    child: Text(
                      buttonLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 500.ms, delay: 350.ms)
          .then(delay: 600.ms)
          .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.25)),
        ],
      ),
    );
  }





  void _showAppNotifications() {
    final isDark = ThemeService.isDark;

    final streak = _progress.currentStreak;
    final todayStudied = _progress.todayStudied;
    final dailyGoal = _progress.dailyGoal;
    final remaining = (dailyGoal - todayStudied).clamp(0, dailyGoal);
    final daysToExam = _progress.daysToExam;
    final accuracy = _progress.totalFlashcardsStudied > 0
        ? (_progress.correctAnswers / _progress.totalFlashcardsStudied * 100).round()
        : 0;

    // En çok hata yapılan branş
    final Map<String, int> mistakeCounts = {};
    for (final t in _topics) {
      for (final fc in t.flashcards) {
        final d = _sm2Data[fc.id];
        if (d != null && d.lastQuality == 1) {
          mistakeCounts[t.subject] = (mistakeCounts[t.subject] ?? 0) + 1;
        }
      }
    }
    final sortedMistakes = mistakeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMistakeSubject = sortedMistakes.isEmpty ? 'Dersler' : sortedMistakes.first.key;
    final topMistakeCount = sortedMistakes.isEmpty ? 0 : sortedMistakes.first.value;

    // Pending cards
    final pendingCards = _flashcardSummary.toReviewCount;

    final List<AppNotificationItem> notifications = [
      // Günlük hedef durumu
      if (remaining > 0)
        AppNotificationItem(
          title: 'GÜNLÜK HEDEF',
          message: 'Hedefe $remaining kart kaldı! Bugünkü $dailyGoal kartlık hedefinin ${todayStudied > 0 ? "${todayStudied}ını" : "hiçbirini"} tamamladın. Şimdi devam et ⚡',
          icon: Icons.track_changes_rounded,
          color: AppTheme.cyan,
          timeLabel: 'Şimdi',
        )
      else
        AppNotificationItem(
          title: 'GÜNLÜK HEDEF TAMAMLANDI 🎉',
          message: 'Harika! Bugünkü $dailyGoal kartlık hedefini tamamladın. Yarın yeni kartlarla devam edeceksin.',
          icon: Icons.check_circle_rounded,
          color: AppTheme.success,
          timeLabel: 'Bugün',
        ),

      // Seri bilgisi
      if (streak >= 5)
        AppNotificationItem(
          title: 'SERİ REKOR 🔥',
          message: '$streak günlük kesintisiz çalışma serisi! Bu tempoyla TUS\'a hazır olacaksın. Bugün de serini koru.',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6B00),
          timeLabel: 'Bugün',
        )
      else if (streak > 0)
        AppNotificationItem(
          title: 'SERİ DEVAM EDİYOR',
          message: '$streak günlük serin var! Serini bozmamak için bugün en az ${(dailyGoal * 0.5).round()} kart çözmelisin. 💪',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6B00),
          timeLabel: 'Bugün',
        )
      else
        AppNotificationItem(
          title: 'YENİ SERİ BAŞLAT',
          message: 'Henüz aktif bir seriniz yok. Bugün ${(dailyGoal * 0.5).round()} kart çözerek yeni bir seri başlat! ⚡',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6B00),
          timeLabel: 'Bugün',
        ),

      // Bekleyen kartlar
      if (pendingCards > 0)
        AppNotificationItem(
          title: 'TEKRAR VAKTİ (SRS)',
          message: '$pendingCards kart seni bekliyor! SM-2 algoritması bu kartların şu an tekrarlanması gerektiğini hesapladı. Bekletme.',
          icon: Icons.history_edu_rounded,
          color: AppTheme.neonPurple,
          timeLabel: 'Şimdi',
        ),

      // Zayıf branş uyarısı
      if (topMistakeCount > 2)
        AppNotificationItem(
          title: 'ZAYIF HALKA TESPİT EDİLDİ',
          message: '$topMistakeSubject dersinde $topMistakeCount hata saptandı. AI Hata Analizi ile bu konuyu derinlemesine çalışmanı öneririz.',
          icon: Icons.analytics_rounded,
          color: AppTheme.coral,
          timeLabel: 'Analiz',
        ),

      // Doğruluk oranı
      if (accuracy > 0)
        AppNotificationItem(
          title: 'DOĞRULUK ORANI',
          message: accuracy >= 75
              ? 'Harika! %$accuracy doğruluk oranınla üst %25\'tesin. Bu tempo ile sınav günü hazır olacaksın. 🏆'
              : 'Doğruluk oranın %$accuracy. Hata yaptığın kartlara daha fazla zaman ayır ve AI açıklamalarını oku.',
          icon: Icons.pie_chart_rounded,
          color: accuracy >= 75 ? AppTheme.success : AppTheme.neonGold,
          timeLabel: 'İstatistik',
        ),

      // Sınav geri sayım
      AppNotificationItem(
        title: 'SINAV GERİ SAYIM',
        message: 'TUS\'a $daysToExam gün kaldı. Hedefe ulaşmak için her gün ${_progress.recommendedDailyGoal} kart çözmen gerekiyor. Planını takip et! 📍',
        icon: Icons.timer_rounded,
        color: AppTheme.neonPink,
        timeLabel: 'Bugün',
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppNotificationsSheet(
        isDark: isDark,
        notifications: notifications,
      ),
    );
  }

  void _showAiInsightSheet() {
    final isDark = ThemeService.isDark;

    // Analiz için veri hazırlığı
    Map<String, int> mistakeCounts = {};
    Map<String, int> topicMistakes = {};

    // ID -> Subject/Topic map'i oluştur (topics'ten çek)
    for (final t in _topics) {
      for (final fc in t.flashcards) {
        final d = _sm2Data[fc.id];
        if (d != null && d.lastQuality == 1) {
          mistakeCounts[t.subject] = (mistakeCounts[t.subject] ?? 0) + 1;
          topicMistakes[t.topic] = (topicMistakes[t.topic] ?? 0) + 1;
        }
      }
      for (final cc in t.clinicalCases) {
        if (cc.id.isEmpty) continue;
        final d = _sm2Data[cc.id];
        if (d != null && d.lastQuality == 1) {
          mistakeCounts[t.subject] = (mistakeCounts[t.subject] ?? 0) + 1;
          topicMistakes[t.topic] = (topicMistakes[t.topic] ?? 0) + 1;
        }
      }
    }

    final topTopics = topicMistakes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3Topics = topTopics.take(3).map((e) => e.key).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiInsightSheet(
        progress: _progress,
        isDark: isDark,
        mistakeCounts: mistakeCounts,
        topMistakeTopics: top3Topics,
        targetBranch: _user.targetBranch,
      ),
    );
  }


  void _showSubjectSelectionSheet({required bool isCards, required bool isDark}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.background : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        isCards ? 'Flash Kart Branşı Seç' : 'Vaka Sorusu Branşı Seç',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                          fontSize: 20, fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      // Kalan Hedef Göstergesi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Kalan: ${(_progress.dailyGoal - _progress.todayStudied).clamp(0, 9999)}',
                          style: GoogleFonts.inter(
                            color: AppTheme.cyan,
                            fontSize: 12, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // BRANŞLAR — kullanıcı spesifik branş seçmek zorunda
                        ...SubjectRegistry.activeModules.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSubjectItem(
                            title: m.name,
                            subtitle: 'Hemen Başla', // Ünite sayısı kaldırıldı
                            icon: m.icon,
                            color: m.color,
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(context);
                              _launchStudy(isCards: isCards, mode: CaseStudyMode.dueOnly, subjectId: m.id);
                            },
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSubjectItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return _PressableCard(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      fontSize: 16, fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(subtitle,
                    style: GoogleFonts.inter(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  void _launchStudy({required bool isCards, required CaseStudyMode mode, String? subjectId}) async {
    final List<String>? selected = subjectId != null ? [subjectId] : (_progress.selectedSubjectIds.isEmpty ? null : _progress.selectedSubjectIds);
    
    final remaining = (_progress.dailyGoal - _progress.todayStudied).clamp(0, 9999);
    
    if (isCards) {
      FlashcardMode fMode = FlashcardMode.all;
      if (mode == CaseStudyMode.dueOnly) fMode = FlashcardMode.dueOnly;
      else if (mode == CaseStudyMode.failedOnly) fMode = FlashcardMode.failedOnly;
      else if (mode == CaseStudyMode.learnedOnly) fMode = FlashcardMode.learnedOnly;
      else if (mode == CaseStudyMode.pocketOnly) fMode = FlashcardMode.pocketOnly;

      await Navigator.push(context, AppRoute.slideUp(FlashcardScreen(
        subjectIds: selected,
        initialMode: fMode,
        dailyGoal: remaining,
      )));
    } else {
      await Navigator.push(context, AppRoute.slideUp(CaseStudyScreen(
        subjectIds: selected,
        initialMode: mode,
        dailyGoal: remaining,
      )));
    }
    _refreshStats();
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    final focusService = Provider.of<FocusService>(context);
    final isFocusActive = focusService.isRunning || focusService.isAudioPlaying;

    final items = [
      (Icons.home_rounded,                Icons.home_outlined,                'Home'),
      (Icons.folder_special_rounded,      Icons.folder_special_outlined,      'Klasörler'),
      (
        isFocusActive ? Icons.timer_rounded : Icons.timer_outlined,
        isFocusActive ? Icons.timer_rounded : Icons.timer_outlined,
        'Odak'
      ),
      (Icons.assignment_rounded,          Icons.assignment_outlined,          'Deneme'),
      (Icons.bar_chart_rounded,           Icons.bar_chart_outlined,           'Analiz'),
      (Icons.person_rounded,              Icons.person_outline_rounded,       'Profil'),
    ];

    return RepaintBoundary(
      child: Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2235)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.07),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.07),
                  blurRadius: 30, offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final isActive = _navIndex == i;
                final (activeIcon, inactiveIcon, label) = items[i];

                return GestureDetector(
                  onTap: () => _onNavTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(horizontal: isActive ? 10 : 6, vertical: 8),
                    decoration: isActive
                        ? BoxDecoration(
                            color:  AppTheme.cyan.withValues(alpha: isDark ? 0.14 : 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.30), width: 1),
                            boxShadow: [
                              BoxShadow(color: AppTheme.cyan.withValues(alpha: isDark ? 0.28 : 0.18),
                                  blurRadius: 14, spreadRadius: 1),
                            ],
                          )
                        : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isActive ? activeIcon : inactiveIcon,
                              color: isActive
                                  ? AppTheme.cyan
                                  : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                              size: 22,
                            ),
                            if (isActive) ...[
                              const SizedBox(height: 3),
                              Text(label,
                                style: GoogleFonts.inter(color: AppTheme.cyan, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                        // ── Focus Indicators (Odak sekmesi: index 2) ──
                        if (i == 2) ...[
                          if (focusService.isRunning)
                            Positioned(
                              left: -18, top: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.cyan.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  focusService.timerString,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms),
                            ),
                          if (focusService.isAudioPlaying)
                            Positioned(
                              right: -12, top: -2,
                              child: const Icon(Icons.music_note_rounded, color: AppTheme.neonPink, size: 12)
                                  .animate(onPlay: (c) => c.repeat())
                                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms)
                                  .then().fadeOut(duration: 400.ms),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _onNavTap(int index) async {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: break; // Home
      case 1: // Klasörler
        await Navigator.push(context, AppRoute.slideUp(const CollectionsScreen()));
        _refreshStats();
        break;
      case 2: // Odak
        await Navigator.push(context, AppRoute.slideUp(const FocusScreen()));
        _refreshStats();
        break;
      case 3: // Deneme
        await Navigator.push(context, AppRoute.slideUp(const MockExamSetupScreen()));
        _refreshStats();
        break;
      case 4: // Analiz
        await Navigator.push(context, AppRoute.slideUp(ProgressAnalyticsScreen(user: _user, progress: _progress)));
        _refreshStats();
        break;
      case 5: // Profil
        await Navigator.push(context, AppRoute.slideUp(const ProfileScreen()));
        _refreshStats();
        break;
    }
    if (mounted) setState(() => _navIndex = 0);
  }


  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Neon glow logo — Hero ile splash'dan bu noktaya akıcı geçiş
          Hero(
            tag: 'asistus-logo',
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.cyan, AppTheme.neonPurple],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.45), blurRadius: 28, spreadRadius: 2),
                  BoxShadow(color: AppTheme.neonPurple.withValues(alpha: 0.25), blurRadius: 48),
                ],
              ),
              child: Center(child: Text('A', style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.95, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut),
          const SizedBox(height: 28),
          Text(
            'Sana özel TUS planı hazırlanıyor...',
            style: GoogleFonts.inter(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              fontSize: 14, fontWeight: FontWeight.w500,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1800.ms, color: AppTheme.cyan.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            'Kartların ve istatistiklerin yükleniyor',
            style: GoogleFonts.inter(
              color: (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary).withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 40),
          // Animated dots
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.cyan, shape: BoxShape.circle))
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(delay: Duration(milliseconds: i * 200))
              .then(delay: 400.ms)
              .fadeOut(duration: 400.ms)
              .then(delay: Duration(milliseconds: (2 - i) * 200)),
            ],
          ]),
        ],
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  Sub-Widgets                                                             ║
// ╚══════════════════════════════════════════════════════════════════════════╝

// ── Ambient Blob ───────────────────────────────────────────────────────────
// ── AI Koç Paneli Yardımcı Widget'ları ───────────────────────────────────

class _CoachChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final Color color;
  final bool isDark;

  const _CoachChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subValue,
            style: GoogleFonts.inter(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _DueBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Readiness Paneli Yardımcı Widget'ları ─────────────────────────────────

// ── İkon Üçlüsü Butonları ─────────────────────────────────────────────────

class _TrioButton extends StatefulWidget {
  final IconData   icon;
  final Color      color;
  final Color      glowColor;
  final String     tooltip;
  final bool       isDark;
  final VoidCallback onTap;

  const _TrioButton({
    required this.icon,
    required this.color,
    required this.glowColor,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TrioButton> createState() => _TrioButtonState();
}

class _TrioButtonState extends State<_TrioButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      preferBelow: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.glowColor.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _hovered
                  ? [BoxShadow(color: widget.glowColor.withValues(alpha: 0.25), blurRadius: 10)]
                  : [],
            ),
            child: Icon(widget.icon, color: widget.color, size: 19),
          ),
        ),
      ),
    );
  }
}

class _TrioButtonWithBadge extends StatefulWidget {
  final IconData   icon;
  final Color      color;
  final bool       isDark;
  final VoidCallback onTap;

  const _TrioButtonWithBadge({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TrioButtonWithBadge> createState() => _TrioButtonWithBadgeState();
}

class _TrioButtonWithBadgeState extends State<_TrioButtonWithBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Bildirimler',
      preferBelow: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _hovered
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _hovered
                  ? [BoxShadow(color: const Color(0xFFFF3B30).withValues(alpha: 0.20), blurRadius: 10)]
                  : [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: 19),
                Positioned(
                  top: 7, right: 7,
                  child: Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x66FF3B30), blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ambient Blob ──────────────────────────────────────────────────────────

class _AmbientBlob extends StatelessWidget {
  final Color  color;
  final double size;
  final double opacity;
  final Duration pulseDuration;

  const _AmbientBlob({
    required this.color,
    required this.size,
    this.opacity = 0.10,
    this.pulseDuration = const Duration(milliseconds: 5000),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0.0),
        ]),
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .scaleXY(
      begin: 0.88, end: 1.12,
      duration: pulseDuration,
      curve: Curves.easeInOut,
    );
  }
}

// ── Pressable Card (scale + haptic) ───────────────────────────────────────
/// Scale 1.0→0.97 press animasyonu + HapticFeedback
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableCard({required this.child, this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── Shimmer Box (loading skeleton) ────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final bool isDark;

  const _ShimmerBox({
    required this.height,
    required this.borderRadius,
    required this.isDark,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
        );
  }
}

// ── Glow Icon Box (shared) ─────────────────────────────────────────────────
class GlowIconBox extends StatelessWidget {
  final IconData icon;
  final Color    color;

  const GlowIconBox({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

// ── Folder Card ────────────────────────────────────────────────────────────
// ── Günün Akıllı Görevi — Sayaç Chip'i ────────────────────────────────────────
// ── Kompakt Aksiyon Butonu (SmartTaskCard için) ───────────────────────────────

class _CompactActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient? gradient;
  final Color? outlineColor;
  final bool isDark;
  final VoidCallback onTap;

  const _CompactActionButton({
    required this.label,
    required this.icon,
    this.gradient,
    this.outlineColor,
    this.isDark = false,
    required this.onTap,
  });

  @override
  State<_CompactActionButton> createState() => _CompactActionButtonState();
}

class _CompactActionButtonState extends State<_CompactActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.gradient != null
        ? Colors.white
        : (widget.outlineColor ?? AppTheme.cyan);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: widget.gradient != null
              ? BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.coral
                          .withValues(alpha: _hovered ? 0.50 : 0.28),
                      blurRadius: _hovered ? 14 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                )
              : BoxDecoration(
                  color: fgColor.withValues(
                      alpha: _hovered
                          ? (widget.isDark ? 0.18 : 0.12)
                          : (widget.isDark ? 0.10 : 0.07)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: fgColor.withValues(alpha: 0.38)),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: fgColor, size: 15),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: fgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Web Hover Section Wrapper ─────────────────────────────────────────────────
/// Web geniş ekranda bölümlere hover edildiğinde border + shadow belirginleşir.
/// Mobilde sadece child döndürür — sıfır ek maliyet.

class _WebHoverSection extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const _WebHoverSection({required this.child, required this.isDark});

  @override
  State<_WebHoverSection> createState() => _WebHoverSectionState();
}

class _WebHoverSectionState extends State<_WebHoverSection> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppTheme.cyan.withValues(alpha: 0.22)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.cyan
                        .withValues(alpha: widget.isDark ? 0.10 : 0.07),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

// ── Smart Counter ─────────────────────────────────────────────────────────────

class _SmartCounter extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _SmartCounter({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.13 : 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String       label;
  final int          count;
  final Color        color;
  final bool         isDark;
  final VoidCallback? onTap;

  const _FolderCard({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;

    return _PressableCard(
      onTap: active ? () { HapticFeedback.mediumImpact(); onTap!(); } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.20),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: active
                      ? [
                          color.withValues(alpha: isDark ? 0.22 : 0.14),
                          color.withValues(alpha: isDark ? 0.08 : 0.05),
                        ]
                      : [
                          isDark ? const Color(0xFF1E2A3A) : Colors.white.withValues(alpha: 0.80),
                          isDark ? const Color(0xFF162030) : Colors.white.withValues(alpha: 0.60),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active
                      ? color.withValues(alpha: isDark ? 0.60 : 0.40)
                      : Colors.white.withValues(alpha: isDark ? 0.10 : 0.50),
                  width: 0.7,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sayaç badge
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.22 : 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: active
                          ? (isDark ? Colors.white : AppTheme.lightTextPrimary)
                          : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// ── Info Sheet ─────────────────────────────────────────────────────────────
class _InfoSheet extends StatelessWidget {
  final bool isDark;
  const _InfoSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppTheme.cyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nasıl Çalışır?',
                          style: GoogleFonts.inter(
                              color: textColor, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('AsisTus Öğrenme Sistemi',
                          style: GoogleFonts.inter(
                              color: subColor, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.bolt_rounded,
                    color: AppTheme.coral,
                    title: 'Günün Akıllı Görevi',
                    body: 'Her gün, sana özel bir "Akıllı Görev" hazırlanır. '
                        'Bugünkü tekrar gerektiren kartları, bilmediğin soruları ve süreyi '
                        'tek bakışta görürsün. Göreve başlamak için dokunman yeterli.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.repeat_rounded,
                    color: AppTheme.cyan,
                    title: 'SM-2 Akıllı Tekrar Algoritması',
                    body: 'SuperMemo-2 algoritması, her kart için ayrı aralıklı tekrar programı oluşturur. '
                        '"Bildim" dediğin kartlar giderek daha seyrek gelir. '
                        '"Bilemedim" dediğin kartlar ertesi gün tekrar karşına çıkar. '
                        '3 kez üst üste "Bildim" = Ustalaştın sayılırsın. 🎯',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.analytics_rounded,
                    color: AppTheme.neonPurple,
                    title: 'AI Hata Analiz Motoru',
                    body: 'AI asistan, çözdüğün soruları ve hata kalıplarını analiz ederek zayıf noktalarını tespit eder. '
                        '"Hata Analizi" sekmesinde branş bazında derinlemesine rapor alabilir, '
                        'eksiklerini kapatmaya yönelik kişiselleştirilmiş çalışma planı görebilirsin.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.bar_chart_rounded,
                    color: AppTheme.neonGold,
                    title: 'Branş Hakimiyet Analizi',
                    body: 'Analitik ekranında her branş için ayrı bir hakimiyet barı görürsün. '
                        'Bu bar, sadece "Bildim" dediğin soruları değil, '
                        'üst üste doğru yanıtladığın (gerçekten öğrendiğin) soruları ölçer. '
                        'Böylece gerçek güçlü ve zayıf branşlarını net görürsün.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.computer_rounded,
                    color: AppTheme.success,
                    title: 'Web & Masaüstü Deneyimi',
                    body: 'AsisTus hem mobil hem web için optimize edilmiştir. '
                        'Tarayıcıda açtığında sol kenar çubuğu ile 6 ana seksi (Ana Sayfa, Koleksiyonlar, '
                        'Odak Modu, Deneme, Analitik, Profil) hızla geçiş yapabilirsin. '
                        'Alt+1–6 klavye kısayolları da desteklenmektedir.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.timer_rounded,
                    color: AppTheme.neonGold,
                    title: 'Günlük Limitler & Premium',
                    body: 'Her gün ücretsiz olarak belirli sayıda kart ve soru çözebilirsin. '
                        'Günlük limitini doldurduktan sonra ertesi gün bekleyebilir '
                        'veya sınırsız erişim için Premium\'a geçebilirsin.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.psychology_rounded,
                    color: const Color(0xFFFF9F0A),
                    title: 'Kişisel AI Danışman',
                    body: 'AI Asistan sekmesi tamamen senin kişisel eksiklerini kapatmak için tasarlandı. '
                        'İstatistiklerini yorumlayarak en çok zorlandığın konuları tespit eder ve '
                        '"Bilemediklerini" eritmeye odaklı kişiselleştirilmiş bir çalışma planı sunar.',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop Stat Chip ─────────────────────────────────────────────────────────
class _DesktopStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _DesktopStatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: isDark ? 0.10 : 0.07);
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop Quick Link ────────────────────────────────────────────────────────
class _DesktopQuickLink extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _DesktopQuickLink({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DesktopQuickLink> createState() => _DesktopQuickLinkState();
}

class _DesktopQuickLinkState extends State<_DesktopQuickLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor  = widget.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final bg = _hovered
        ? widget.color.withValues(alpha: widget.isDark ? 0.12 : 0.08)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    Text(widget.sublabel,
                        style: GoogleFonts.inter(
                            color: subColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: _hovered ? widget.color : subColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop Mini Stat ─────────────────────────────────────────────────────────
class _DesktopMiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _DesktopMiniStat({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final bg = color.withValues(alpha: isDark ? 0.08 : 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
                color: textColor, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
                color: color, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _InfoSection({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark
        ? color.withValues(alpha: 0.06)
        : color.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(body,
                    style: GoogleFonts.inter(
                        color: subColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
