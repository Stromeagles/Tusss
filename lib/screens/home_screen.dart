import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../utils/transitions.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';
import '../services/spaced_repetition_service.dart';
import '../models/progress_model.dart';
import '../models/topic_model.dart';
import '../models/subject_registry.dart';
import 'flashcard_subject_screen.dart';
import 'case_study_screen.dart';
import 'topic_list_screen.dart';
import 'hierarchy_screens.dart';
import 'goal_settings_screen.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  HomeScreen                                                              ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dataService     = DataService();
  final _progressService = ProgressService();

  String?       _selectedSubjectId;
  StudyProgress _progress = const StudyProgress();
  List<Topic>   _topics   = [];
  bool          _loading  = true;
  int           _navIndex = 0;
  SrsSummary    _srsSummary = const SrsSummary(newCount: 0, dueCount: 0, pocketCount: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _dataService.loadTopics(subjectId: _selectedSubjectId),
      _progressService.loadProgress(),
    ]);
    if (mounted) {
      final topics = results[0] as List<Topic>;
      final progress = results[1] as StudyProgress;

      // Tüm flashcard ve case ID'lerini topla
      final allIds = <String>[];
      for (final t in topics) {
        allIds.addAll(t.flashcards.map((fc) => fc.id));
        allIds.addAll(t.clinicalCases.map((cc) => cc.id).where((id) => id.isNotEmpty));
      }
      final srsSummary = await SpacedRepetitionService().getSummary(allIds);

      setState(() {
        _topics     = topics;
        _progress   = progress;
        _srsSummary = srsSummary;
        _loading    = false;
      });
    }
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  int    get _totalFlashcards => _topics.fold(0, (s, t) => s + t.totalFlashcards);
  int    get _totalCases      => _topics.fold(0, (s, t) => s + t.totalCases);

  double get _overallProgress {
    final total   = _totalFlashcards + _totalCases;
    final studied = _progress.totalFlashcardsStudied + _progress.totalCasesAttempted;
    return total > 0 ? (studied / total).clamp(0.0, 1.0) : 0.0;
  }

  double get _hoursStudied =>
      (_progress.totalFlashcardsStudied + _progress.totalCasesAttempted) * 2.5 / 60;

  int get _daysToExam => _progress.daysToExam;

  /// İlerlemeye göre dinamik renk paleti
  List<Color> get _progressColors {
    final p = _overallProgress;
    if (p >= 0.80) return const [AppTheme.neonGold, AppTheme.cyan];      // Altın başarı
    if (p >= 0.30) return const [AppTheme.cyan, AppTheme.neonPink];       // Normal ilerleme
    return const [AppTheme.neonPink, AppTheme.neonPurple];                // Düşük — uyarı
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0D1117), Color(0xFF0D1117), Color(0xFF161B22)]
                : const [Color(0xFFEDF3FF), Color(0xFFE8F0FF), Color(0xFFF0F5FF)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Ambient Neon Glows ──────────────────────────────────────────
            Positioned(top: -160, left: -120,
                child: _AmbientBlob(color: AppTheme.cyan,      size: 500, opacity: isDark ? 0.12 : 0.05)),
            Positioned(top: 180, right: -140,
                child: _AmbientBlob(color: AppTheme.neonPink,  size: 420, opacity: isDark ? 0.10 : 0.04)),
            Positioned(bottom: 150, left: -100,
                child: _AmbientBlob(color: AppTheme.neonPurple,size: 360, opacity: isDark ? 0.10 : 0.04)),
            Positioned(bottom: -80, right: -60,
                child: _AmbientBlob(color: AppTheme.cyan,      size: 300, opacity: isDark ? 0.07 : 0.03)),

            // ── Main Content ────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(isDark),
                  Expanded(
                    child: _loading
                        ? _buildLoadingState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.cyan,
                            backgroundColor: isDark ? AppTheme.surface : Colors.white,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).padding.bottom + 110,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  _buildHeroCard(isDark),
                                  const SizedBox(height: 20),
                                  _buildQuickActions(isDark),
                                  const SizedBox(height: 26),
                                  _buildSubjectCarousel(isDark),
                                  const SizedBox(height: 26),
                                  _buildDailyGoal(isDark),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          // Gradient Avatar
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.cyan, AppTheme.neonPink],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.40), blurRadius: 14, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Text('T',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),

          // Welcome
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,',
                  style: GoogleFonts.inter(color: subColor, fontSize: 12, fontWeight: FontWeight.w500)),
                Text('Doktor Adayı! 👋',
                  style: GoogleFonts.inter(color: textColor, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          ),

          // ── Tema Toggle Butonu ─────────────────────────────────────
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.mode,
            builder: (_, mode, __) {
              final dark = mode == ThemeMode.dark;
              return GestureDetector(
                onTap: ThemeService.toggle,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: dark
                            ? AppTheme.cyan.withValues(alpha: 0.12)
                            : AppTheme.neonPink.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: dark
                              ? AppTheme.cyan.withValues(alpha: 0.30)
                              : AppTheme.neonPink.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (dark ? AppTheme.cyan : AppTheme.neonPink).withValues(alpha: 0.20),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: dark ? AppTheme.cyan : AppTheme.neonPink,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),

          // Notification Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.07),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.notifications_outlined,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
                  ),
                ),
              ),
              Positioned(
                top: 9, right: 9,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFF3B30).withValues(alpha: 0.7), blurRadius: 6, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.08, end: 0);
  }

  // ── Hero Card ──────────────────────────────────────────────────────────────
  Widget _buildHeroCard(bool isDark) {
    final cardBg     = AppTheme.glassBg(isDark, darkAlpha: 0.08, lightAlpha: 0.82);
    final cardBorder = AppTheme.glassBorder(isDark);
    final shadow     = AppTheme.shadowColor(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardBg, cardBg.withValues(alpha: cardBg.a * 0.4)],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(color: AppTheme.cyan.withValues(alpha: isDark ? 0.07 : 0.10), blurRadius: 50, spreadRadius: -5),
                BoxShadow(color: shadow, blurRadius: 35, offset: const Offset(0, 18)),
              ],
            ),
            child: Column(
              children: [
                // ── Top: giant glow progress + stats ────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // DEV NEON PROGRESS — %30-40 büyütülmüş + çok katmanlı glow
                    _GradientCircularProgress(
                      value:       _overallProgress,
                      size:        158,           // önceki: 122
                      colors:      _progressColors,
                      strokeWidth: 11,
                      isDark:      isDark,
                    ),
                    const SizedBox(width: 20),
                    // Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ÇALIŞMA DURUMU',
                            style: GoogleFonts.inter(
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _StatItem(icon: Icons.access_time_filled_rounded,
                            label: 'Çalışma Saati',
                            value: '${_hoursStudied.toStringAsFixed(1)} s',
                            color: AppTheme.cyan, isDark: isDark),
                          const SizedBox(height: 14),
                          _StatItem(icon: Icons.event_rounded,
                            label: 'Sınava Kalan',
                            value: '$_daysToExam gün',
                            color: AppTheme.neonPink, isDark: isDark),
                          const SizedBox(height: 14),
                          _StatItem(icon: Icons.bolt_rounded,
                            label: 'Başarı Oranı',
                            value: '${(_progress.accuracy * 100).toInt()}%',
                            color: const Color(0xFF3FB950), isDark: isDark),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
                      Colors.transparent,
                    ]),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Weekly bar chart ─────────────────────────────────────────
                _WeeklyBarChart(accent: AppTheme.cyan, isDark: isDark),

                // Anki-style sayaçlar
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AnkiStat(label: 'Yeni', count: _srsSummary.newCount, color: const Color(0xFF58A6FF)),
                    Container(width: 1, height: 32, color: AppTheme.border),
                    _AnkiStat(label: 'Bugün', count: _srsSummary.dueCount, color: AppTheme.cyan),
                    Container(width: 1, height: 32, color: AppTheme.border),
                    _AnkiStat(label: 'Cepte', count: _srsSummary.pocketCount, color: AppTheme.success),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 100.ms)
        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1));
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _QuickActionCard(
            title: 'Bilgi Maratonu', subtitle: 'Flashcardlar',
            icon: Icons.auto_awesome_motion_rounded,
            color: const Color(0xFFF78166),
            isDark: isDark, onTap: _navigateToFlashcards,
          )),
          const SizedBox(width: 14),
          Expanded(child: _QuickActionCard(
            title: 'Klinik Vaka', subtitle: 'Random Çözüm',
            icon: Icons.biotech_rounded,
            color: const Color(0xFF79C0FF),
            isDark: isDark, onTap: _navigateToCases,
          )),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 250.ms).slideY(begin: 0.12, end: 0);
  }

  // ── Subject Carousel ───────────────────────────────────────────────────────
  Widget _buildSubjectCarousel(bool isDark) {
    final modules  = SubjectRegistry.modules;
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text('Çalışma Branşları',
                  style: GoogleFonts.inter(color: textColor, fontSize: 19,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:   AppTheme.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text('${modules.length}',
                    style: GoogleFonts.inter(color: AppTheme.cyan, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ]),
              GestureDetector(
                onTap: _navigateToTopicList,
                child: Text('Tümünü Gör →',
                  style: GoogleFonts.inter(color: AppTheme.cyan, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 172,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 8),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              final isActive  = _selectedSubjectId == module.id;
              final moduleTopics = _topics.where((t) => t.subject == module.name).toList();
              final cardCount    = moduleTopics.fold(0, (s, t) => s + t.totalFlashcards);
              final share = _totalFlashcards > 0
                  ? (cardCount / _totalFlashcards).clamp(0.0, 1.0)
                  : 0.0;

              return _SubjectCarouselCard(
                module: module, cardCount: cardCount,
                progress: share, isActive: isActive, isDark: isDark,
                onTap: () {
                  setState(() => _selectedSubjectId = isActive ? null : module.id);
                  _navigateToModule(module, moduleTopics);
                },
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 700.ms, delay: 400.ms);
  }

  // ── Daily Goal ─────────────────────────────────────────────────────────────
  Widget _buildDailyGoal(bool isDark) {
    final dailyGoal = _progress.todayGoalHours;
    final studied   = _hoursStudied;
    final goalProg  = (studied / dailyGoal).clamp(0.0, 1.0);
    final cardBg    = AppTheme.glassBg(isDark, darkAlpha: 0.07, lightAlpha: 0.80);
    final cardBorder= AppTheme.glassBorder(isDark);
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(color: AppTheme.shadowColor(isDark), blurRadius: 30, offset: const Offset(0, 14)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Günlük Hedef',
                      style: GoogleFonts.inter(color: textColor, fontSize: 16,
                          fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:  AppTheme.neonPink.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.25), width: 1),
                        ),
                        child: Text('Bugün',
                          style: GoogleFonts.inter(color: AppTheme.neonPink, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final saved = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) =>
                                GoalSettingsScreen(progress: _progress)),
                          );
                          if (saved == true) _loadData();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.25), width: 1),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppTheme.cyan, size: 14),
                        ),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${studied.toStringAsFixed(1)} / ${dailyGoal.toInt()}',
                        style: GoogleFonts.inter(color: textColor, fontSize: 26,
                            fontWeight: FontWeight.w900, letterSpacing: -1.2)),
                      Text('Saat', style: GoogleFonts.inter(color: subColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                    const Spacer(),
                    _GradientCircularProgress(
                      value: goalProg, size: 74,
                      colors: const [AppTheme.neonPink, AppTheme.cyan],
                      strokeWidth: 7, isDark: isDark, showLabel: false,
                      centerWidget: Text('${(goalProg * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _GoalMetric(icon: Icons.assignment_rounded,
                        label: 'QBank', value: '${_progress.totalCasesAttempted}',
                        color: AppTheme.neonPink, isDark: isDark),
                      const SizedBox(height: 12),
                      _GoalMetric(icon: Icons.style_rounded,
                        label: 'Flashcard', value: '${_progress.totalFlashcardsStudied}',
                        color: AppTheme.cyan, isDark: isDark),
                      const SizedBox(height: 12),
                      _GoalMetric(icon: Icons.menu_book_rounded,
                        label: 'Okuma',
                        value: '${(_progress.totalFlashcardsStudied / 10).toInt()}',
                        color: const Color(0xFF3FB950), isDark: isDark),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 700.ms, delay: 550.ms).slideY(begin: 0.10, end: 0);
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    const items = [
      (Icons.home_rounded,           Icons.home_outlined,           'Home'),
      (Icons.school_rounded,         Icons.school_outlined,         'Study'),
      (Icons.bar_chart_rounded,      Icons.bar_chart_outlined,      'Progress'),
      (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Program'),
      (Icons.person_rounded,         Icons.person_outline_rounded,  'Profil'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.85),
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
                    padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12, vertical: 8),
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
                    child: Column(
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
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _onNavTap(int index) async {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: break;
      case 1: await _navigateToFlashcards(); break;
      case 2: _navigateToTopicList(); break;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Yakında geliyor! 🚀',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.surfaceVariant,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ));
        }
    }
    if (mounted) setState(() => _navIndex = 0);
  }

  Future<void> _navigateToModule(SubjectModule module, List<Topic> topics) async {
    final chapters = <String, List<Topic>>{};
    for (final t in topics) { chapters.putIfAbsent(t.chapter, () => []).add(t); }
    await Navigator.push(context, AppRoute.slideRight(
      ChapterListScreen(subjectName: module.name, chapters: chapters, accentColor: module.color),
    ));
    _loadData();
  }

  Future<void> _navigateToFlashcards() async {
    await Navigator.push(context, AppRoute.slideUp(const FlashcardSubjectScreen()));
    _loadData();
  }

  Future<void> _navigateToCases() async {
    await Navigator.push(context, AppRoute.slideUp(CaseStudyScreen(subjectId: _selectedSubjectId)));
    _loadData();
  }

  void _navigateToTopicList() {
    Navigator.push(context, AppRoute.slideRight(TopicListScreen(subjectId: _selectedSubjectId)));
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2.5));
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  Sub-Widgets                                                             ║
// ╚══════════════════════════════════════════════════════════════════════════╝

// ── DEV NEON Gradient Circular Progress ───────────────────────────────────
/// 3 katmanlı glow bloom + gradient arc + fütüristik Outfit fontu
class _GradientCircularProgress extends StatelessWidget {
  final double      value;
  final double      size;
  final List<Color> colors;
  final double      strokeWidth;
  final bool        isDark;
  final bool        showLabel;
  final Widget?     centerWidget;

  const _GradientCircularProgress({
    required this.value,
    required this.size,
    required this.colors,
    required this.strokeWidth,
    required this.isDark,
    this.showLabel    = true,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final primary   = colors.first;
    final secondary = colors.length > 1 ? colors.last : colors.first;

    // İlerlemeye göre glow yoğunluğunu artır
    final glowStrength = (0.18 + value * 0.18).clamp(0.18, 0.36);
    final darkMult     = isDark ? 1.0 : 0.5;

    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Katman 1: Dış diffuse bloom ──────────────────────────────────
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: glowStrength * darkMult),
                  blurRadius: 50, spreadRadius: 12,
                ),
                BoxShadow(
                  color: secondary.withValues(alpha: (glowStrength * 0.6) * darkMult),
                  blurRadius: 80, spreadRadius: 20,
                ),
              ],
            ),
          ),

          // ── Katman 2: Orta halka yansıması (cam yüzeye glow) ─────────────
          Container(
            width: size * 0.72, height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: (glowStrength * 1.2).clamp(0, 0.5) * darkMult),
                  blurRadius: 28, spreadRadius: 4,
                ),
              ],
            ),
          ),

          // ── Katman 3: Sıkı iç parlama (blur refleksiyon) ─────────────────
          Container(
            width: size * 0.50, height: size * 0.50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: secondary.withValues(alpha: (glowStrength * 0.8) * darkMult),
                  blurRadius: 16, spreadRadius: 2,
                ),
              ],
            ),
          ),

          // ── Gradient Arc (CustomPainter) ──────────────────────────────────
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              progress:    value,
              gradColors:  colors,
              strokeWidth: strokeWidth,
              trackColor:  isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),

          // ── Merkez Etiket ─────────────────────────────────────────────────
          if (centerWidget != null)
            centerWidget!
          else if (showLabel)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(value * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: size * 0.185,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  'tamamlandı',
                  style: GoogleFonts.inter(
                    color: colors.first.withValues(alpha: 0.80),
                    fontSize: size * 0.075,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Arc Painter ────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double      progress;
  final List<Color> gradColors;
  final double      strokeWidth;
  final Color       trackColor;

  const _ArcPainter({
    required this.progress,
    required this.gradColors,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(center, radius,
      Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..isAntiAlias = true..color = trackColor,
    );

    if (progress <= 0) return;

    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle:    3 * pi / 2,
      colors: [...gradColors, gradColors.first],
      stops:  [0.0, 0.65, 1.0],
    );
    final shader = gradient.createShader(rect);

    // Glow layer
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap   = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 10)
        ..shader      = shader,
    );

    // Main arc
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round
        ..isAntiAlias = true
        ..shader      = shader,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ── Weekly Bar Chart ───────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final Color accent;
  final bool  isDark;

  const _WeeklyBarChart({required this.accent, required this.isDark});

  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const _vals = [0.45,  0.72,  0.50,  0.90,  0.62,  0.38,  0.80];
  static const _maxH = 46.0;

  @override
  Widget build(BuildContext context) {
    final today   = DateTime.now().weekday - 1;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('HAFTALIK ÇALIŞMA',
              style: GoogleFonts.inter(color: subColor, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 2.2)),
            Text('Son 7 Gün',
              style: GoogleFonts.inter(color: subColor.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final isToday = i == today;
            final barH    = _maxH * _vals[i];

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(children: [
                  SizedBox(
                    height: _maxH,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 500 + i * 60),
                        curve: Curves.easeOutCubic,
                        width: double.infinity, height: barH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: isToday
                              ? LinearGradient(colors: [accent, AppTheme.neonPink],
                                  begin: Alignment.bottomCenter, end: Alignment.topCenter)
                              : null,
                          color: isToday ? null : accent.withValues(alpha: isDark ? 0.20 : 0.25),
                          boxShadow: isToday
                              ? [BoxShadow(color: accent.withValues(alpha: 0.60), blurRadius: 12, spreadRadius: 1)]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_days[i],
                    style: GoogleFonts.inter(
                      color: isToday ? accent : subColor.withValues(alpha: 0.55),
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                    )),
                ]),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Stat Item ──────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     isDark;

  const _StatItem({
    required this.icon,  required this.label,
    required this.value, required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.20), width: 1),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
          style: GoogleFonts.inter(color: textColor, fontSize: 16,
              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        Text(label,
          style: GoogleFonts.inter(color: subColor, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

// ── Subject Carousel Card ──────────────────────────────────────────────────
class _SubjectCarouselCard extends StatelessWidget {
  final SubjectModule module;
  final int           cardCount;
  final double        progress;
  final bool          isActive;
  final bool          isDark;
  final VoidCallback  onTap;

  const _SubjectCarouselCard({
    required this.module,   required this.cardCount,
    required this.progress, required this.isActive,
    required this.isDark,   required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158, margin: const EdgeInsets.only(right: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [AppTheme.cyan.withValues(alpha: 0.16), AppTheme.cyan.withValues(alpha: 0.04)]
                      : (isDark
                          ? [Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0.02)]
                          : [Colors.white.withValues(alpha: 0.82), Colors.white.withValues(alpha: 0.60)]),
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isActive
                      ? AppTheme.cyan.withValues(alpha: 0.65)
                      : AppTheme.glassBorder(isDark),
                  width: isActive ? 1.5 : 0.8,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.42), blurRadius: 24, spreadRadius: 2),
                        BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.15), blurRadius: 50, spreadRadius: 6),
                      ]
                    : [
                        BoxShadow(color: (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.30 : 0.06),
                            blurRadius: 14, offset: const Offset(0, 6)),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: module.color.withValues(alpha: isActive ? 0.30 : 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(module.icon, color: module.color, size: 20),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(module.shortLabel.toUpperCase(),
                      style: GoogleFonts.inter(color: textColor, fontSize: 13,
                          fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text('$cardCount kart',
                      style: GoogleFonts.inter(color: subColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text('${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        color: isActive ? AppTheme.cyan : subColor,
                        fontSize: 10, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress, minHeight: 4,
                        backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isActive ? AppTheme.cyan : module.color),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Card ──────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final String       title;
  final String       subtitle;
  final IconData     icon;
  final Color        color;
  final bool         isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,    required this.subtitle,
    required this.icon,     required this.color,
    required this.isDark,   required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [color.withValues(alpha: 0.14), color.withValues(alpha: 0.04)]
                    : [color.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.70)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withValues(alpha: isDark ? 0.28 : 0.20), width: 1.0),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 10, spreadRadius: 1)],
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 14),
              Text(subtitle,
                style: GoogleFonts.inter(color: color.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Goal Metric ────────────────────────────────────────────────────────────
class _GoalMetric extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     isDark;

  const _GoalMetric({
    required this.icon,  required this.label,
    required this.value, required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 13),
      ),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
          style: GoogleFonts.inter(color: textColor, fontSize: 15,
              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        Text(label,
          style: GoogleFonts.inter(color: subColor, fontSize: 9, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

// ── Ambient Blob ───────────────────────────────────────────────────────────
class _AmbientBlob extends StatelessWidget {
  final Color  color;
  final double size;
  final double opacity;

  const _AmbientBlob({required this.color, required this.size, this.opacity = 0.10});

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
    );
  }
}

// ── Anki Stat ──────────────────────────────────────────────────────────────
class _AnkiStat extends StatelessWidget {
  const _AnkiStat({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
          style: GoogleFonts.outfit(
            fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ],
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
