import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'flashcard_screen.dart';
import 'case_study_screen.dart';
import 'topic_list_screen.dart';
import 'hierarchy_screens.dart';
import '../services/ai_coach_service.dart';
import '../models/sm2_model.dart';

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
  SrsSummary    _srsSummary = const SrsSummary(newCount: 0, toReviewCount: 0, learnedCount: 0, bookmarkCount: 0);
  CoachInsight? _coachInsight;

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
        SpacedRepetitionService().getAllData(), // SM-2 verisini önbellekle
      ]);
      if (mounted) {
        final topics   = results[0] as List<Topic>;
        final progress = results[1] as StudyProgress;
        final sm2Data  = results[2] as Map<String, SM2CardData>;

        // Tüm flashcard ve case ID'lerini topla
        final allIds = <String>[];
        for (final t in topics) {
          allIds.addAll(t.flashcards.map((fc) => fc.id));
          allIds.addAll(t.clinicalCases.map((cc) => cc.id).where((id) => id.isNotEmpty));
        }
        // getSummary → getAllData önbellekten döner, ekstra I/O yok
        final srsSummary = await SpacedRepetitionService().getSummary(
          allIds,
          dailyGoal: progress.dailyGoal,
        );
        final coachInsight = AiCoachService().analyze(topics, sm2Data);

        setState(() {
          _topics        = topics;
          _progress      = progress;
          _srsSummary    = srsSummary;
          _coachInsight  = coachInsight;
          _loading       = false;
        });
      }
    } catch (e) {
      debugPrint('🚨 KRİTİK HATA: Veri yükleme başarısız oldu: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler yüklenirken bir sorun oluştu. Bazı konular eksik olabilir.')),
        );
      }
    }
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  int    get _totalFlashcards => _topics.fold(0, (s, t) => s + t.totalFlashcards);

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
                              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).padding.bottom + 110,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  _buildAiCoachNote(isDark),
                                  if (_coachInsight != null) const SizedBox(height: 12),
                                  RepaintBoundary(child: _buildKomutaMerkezi(isDark)),
                                  const SizedBox(height: 12),
                                  _buildStreakBanner(isDark),
                                  const SizedBox(height: 20),
                                  _buildQuickActions(isDark),
                                  const SizedBox(height: 26),
                                  RepaintBoundary(child: _buildSubjectCarousel(isDark)),
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
          const SizedBox(width: 10),

          // Info Button
          GestureDetector(
            onTap: () => _showInfoSheet(context, isDark),
            child: ClipRRect(
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
                  child: Icon(Icons.info_outline_rounded,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
                ),
              ),
            ),
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

  // ── Info Sheet ────────────────────────────────────────────────────────────
  void _showInfoSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(isDark: isDark),
    );
  }

  // ── Streak Banner ─────────────────────────────────────────────────────────
  Widget _buildStreakBanner(bool isDark) {
    final streak = _progress.currentStreak;
    if (streak == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6B00).withValues(alpha: isDark ? 0.20 : 0.12),
              const Color(0xFFFF3B30).withValues(alpha: isDark ? 0.10 : 0.06),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Text('🔥', style: const TextStyle(fontSize: 22))
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2000.ms, color: const Color(0xFFFFCC00)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak Gündür Aralıksız!',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Serini korumaya devam et 💪',
                    style: GoogleFonts.inter(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.4)),
              ),
              child: Text(
                '🔥 $streak',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF6B00),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 150.ms).slideX(begin: -0.05, end: 0);
  }

  // ── Klasör Bazlı Ana Alan ─────────────────────────────────────────────────
  Widget _buildKomutaMerkezi(bool isDark) {
    final toReviewCount = _srsSummary.toReviewCount;
    final learnedCount  = _srsSummary.learnedCount;
    final bookmarkCount = _srsSummary.bookmarkCount;
    final newCount      = _srsSummary.newCount;
    final hasWork       = toReviewCount + learnedCount + newCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ── 3 Klasör Kartı ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _FolderCard(
                label: 'Bilemediklerim',
                icon: Icons.cancel_rounded,
                count: toReviewCount,
                color: AppTheme.error,
                isDark: isDark,
                onTap: toReviewCount > 0 ? () async {
                  await Navigator.push(context, AppRoute.slideUp(
                    const FlashcardScreen(initialMode: FlashcardMode.failedOnly)));
                  _loadData();
                } : null,
              ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutExpo)),
              const SizedBox(width: 12),
              Expanded(child: _FolderCard(
                label: 'Bildiklerim',
                icon: Icons.check_circle_rounded,
                count: learnedCount,
                color: AppTheme.success,
                isDark: isDark,
                onTap: learnedCount > 0 ? () async {
                  await Navigator.push(context, AppRoute.slideUp(
                    const FlashcardScreen(initialMode: FlashcardMode.learnedOnly)));
                  _loadData();
                } : null,
              ).animate().fadeIn(duration: 600.ms, delay: 180.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutExpo)),
              const SizedBox(width: 12),
              Expanded(child: _FolderCard(
                label: 'Ezberim',
                icon: Icons.star_rounded,
                count: bookmarkCount,
                color: AppTheme.neonGold,
                isDark: isDark,
                onTap: bookmarkCount > 0 ? () async {
                  await Navigator.push(context, AppRoute.slideUp(
                    const FlashcardScreen(initialMode: FlashcardMode.pocketOnly)));
                  _loadData();
                } : null,
              ).animate().fadeIn(duration: 600.ms, delay: 260.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutExpo)),
            ],
          ),

          const SizedBox(height: 24),

          // ── HAZIRSAN BAŞLA butonu ────────────────────────────────────────
          GestureDetector(
            onTap: hasWork ? () {
              HapticFeedback.mediumImpact();
              _startDailyGoalSession();
            } : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: hasWork
                    ? const LinearGradient(
                        colors: [Color(0xFF0099CC), Color(0xFF4A35CC), Color(0xFF9B2FBF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppTheme.cyan.withValues(alpha: 0.20),
                          AppTheme.neonPurple.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: hasWork
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4A35CC).withValues(alpha: 0.65),
                          blurRadius: 36,
                          spreadRadius: 0,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0099CC).withValues(alpha: 0.30),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        color: hasWork ? Colors.white : Colors.white38,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'HAZIRSAN BAŞLA',
                        style: GoogleFonts.inter(
                          color: hasWork ? Colors.white : Colors.white38,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.02, 1.02),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .shimmer(
              duration: 2200.ms,
              delay: 1800.ms,
              color: Colors.white.withValues(alpha: hasWork ? 0.30 : 0.0),
              angle: 0.4,
            ),
          ).animate().fadeIn(duration: 700.ms, delay: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutExpo),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.96, 0.96));
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
            title: 'Klinik Vaka', subtitle: 'Random Sorular',
            icon: Icons.biotech_rounded,
            color: const Color(0xFF79C0FF),
            isDark: isDark, onTap: _navigateToCases,
            badge: '🎯 %${_progress.accuracy.toInt()}',
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
            physics: const BouncingScrollPhysics(),
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



  Future<void> _startDailyGoalSession() async {
    final selected = _progress.selectedSubjectIds;
    await Navigator.push(
      context,
      AppRoute.slideUp(FlashcardScreen(
        subjectIds: selected.isEmpty ? null : selected,
        initialMode: FlashcardMode.dueOnly,
        dailyGoal: _progress.dailyGoal,
      )),
    );
    _loadData();
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
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
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

  Widget _buildAiCoachNote(bool isDark) {
    final insight = _coachInsight;
    if (insight == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.neonPurple.withValues(alpha: isDark ? 0.15 : 0.08),
                AppTheme.neonGold.withValues(alpha: isDark ? 0.06 : 0.03),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.neonPurple.withValues(alpha: 0.30),
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.neonPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.neonPurple.withValues(alpha: 0.35)),
                ),
                child: const Text('🤖', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASISTAN NOTU',
                      style: GoogleFonts.inter(
                        color: AppTheme.neonPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.message,
                      style: GoogleFonts.inter(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Goal skeleton
          _ShimmerBox(height: 160, borderRadius: 24, isDark: isDark),
          const SizedBox(height: 16),
          // Hero Card skeleton
          _ShimmerBox(height: 220, borderRadius: 30, isDark: isDark),
          const SizedBox(height: 20),
          // Quick Actions skeleton
          Row(children: [
            Expanded(child: _ShimmerBox(height: 90, borderRadius: 22, isDark: isDark)),
            const SizedBox(width: 14),
            Expanded(child: _ShimmerBox(height: 90, borderRadius: 22, isDark: isDark)),
          ]),
          const SizedBox(height: 26),
          // Subject carousel skeleton
          _ShimmerBox(height: 20, width: 140, borderRadius: 8, isDark: isDark),
          const SizedBox(height: 16),
          Row(children: [
            _ShimmerBox(height: 172, width: 158, borderRadius: 22, isDark: isDark),
            const SizedBox(width: 14),
            _ShimmerBox(height: 172, width: 158, borderRadius: 22, isDark: isDark),
          ]),
        ],
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  Sub-Widgets                                                             ║
// ╚══════════════════════════════════════════════════════════════════════════╝

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

    final accentColor = isActive ? AppTheme.cyan : module.color;

    return _PressableCard(
      onTap: onTap,
      child: Container(
        width: 158, margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: isActive
              ? [
                  BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.42), blurRadius: 28, spreadRadius: 2),
                  BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.18), blurRadius: 50, spreadRadius: 6),
                ]
              : [
                  BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                      blurRadius: 14, offset: const Offset(0, 6)),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [
                          AppTheme.cyan.withValues(alpha: isDark ? 0.18 : 0.12),
                          AppTheme.neonPurple.withValues(alpha: isDark ? 0.08 : 0.05),
                        ]
                      : [
                          Colors.white.withValues(alpha: isDark ? 0.07 : 0.72),
                          Colors.white.withValues(alpha: isDark ? 0.03 : 0.50),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isActive
                      ? AppTheme.cyan.withValues(alpha: isDark ? 0.65 : 0.45)
                      : Colors.white.withValues(alpha: isDark ? 0.10 : 0.55),
                  width: isActive ? 0.8 : 0.6,
                ),
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
                      boxShadow: isActive
                          ? [BoxShadow(color: module.color.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 1)]
                          : [],
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
                        color: accentColor,
                        fontSize: 10, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    // Neon Line progress bar
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor, accentColor.withValues(alpha: 0.6)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.65),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
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
  final String?      badge;

  const _QuickActionCard({
    required this.title,    required this.subtitle,
    required this.icon,     required this.color,
    required this.isDark,   required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
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
            child: Stack(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                if (badge != null)
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.40)),
                      ),
                      child: Text(badge!,
                        style: GoogleFonts.inter(
                          color: color, fontSize: 10, fontWeight: FontWeight.w800)),
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
class _FolderCard extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final int          count;
  final Color        color;
  final bool         isDark;
  final VoidCallback? onTap;

  const _FolderCard({
    required this.label,
    required this.icon,
    required this.count,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: () {
        if (active) {
          HapticFeedback.mediumImpact();
          onTap!();
        }
      },
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                          Colors.white.withValues(alpha: isDark ? 0.05 : 0.60),
                          Colors.white.withValues(alpha: isDark ? 0.02 : 0.40),
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
                  // İkon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: active
                          ? color.withValues(alpha: isDark ? 0.25 : 0.18)
                          : Colors.white.withValues(alpha: isDark ? 0.07 : 0.60),
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 14, spreadRadius: 1)]
                          : [],
                    ),
                    child: Icon(icon,
                      color: active ? color : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                      size: 22),
                  ),
                  const SizedBox(height: 10),
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
                      Text('TUS Asistanı Öğrenme Sistemi',
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
                    icon: Icons.repeat_rounded,
                    color: AppTheme.cyan,
                    title: 'Aralıklı Tekrar (SM-2)',
                    body:
                        'Uygulama, SM-2 algoritmasını kullanır. Her kart için doğru cevap verdiğinde tekrar aralığı uzar; yanlış cevap verdiğinde kart sıfırlanarak yakında tekrar karşına çıkar. Bu sayede beynin uzun süreli belleğe aktarma sürecine uyum sağlanır.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.flag_rounded,
                    color: AppTheme.warning,
                    title: 'Günlük Hedef',
                    body:
                        'Ana sayfadaki daire, bugünkü çalışma hedefinle ne kadar ilerlediğini gösterir. Yalnızca "BAŞLA" butonuyla başlattığın seanslar bu hedefe sayılır. Branş veya konu ekranlarından yapılan çalışmalar önizleme modunda çalışır ve hedefi etkilemez.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFFF453A),
                    title: 'Kritik Kartlar',
                    body:
                        '"⚠️ Kritik" butonuna bastığın kartlar Kritik havuzuna düşer. Bu kartlar en öncelikli tekrar grubundur. Ana sayfadaki kırmızı "Kritik Kartlar" butonu bu havuzu açar.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.sentiment_dissatisfied_rounded,
                    color: const Color(0xFFFF9F0A),
                    title: 'Geçici Hafıza',
                    body:
                        '"⟳ Tekrar" butonuna bastığın kartlar Geçici Hafıza havuzuna düşer. Tekrar sıfırlanır ve kartı en kısa sürede tekrar görürsün.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success,
                    title: 'Orta Hafıza & Uzun Hafıza',
                    body:
                        '"🎯 Orta Hafıza" seçeneği kartı normal SRS akışına alır. "🏆 Uzun Hafıza" seçeneği ise kartın çok iyi bilindiğini işaret eder ve tekrar aralığını uzatır. Yüksek aralıklı kartlar cebindedir ve sık çıkmaz.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.visibility_off_rounded,
                    color: AppTheme.neonPurple,
                    title: 'Önizleme Modu',
                    body:
                        'Branş seçimi veya konu detay sayfasından başlatılan seanslar önizleme modunda çalışır. Bu modda yaptığın cevaplar veritabanına kaydedilmez; SRS, günlük hedef ve seri etkilenmez. Özgürce incelemek için kullanabilirsin.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF9F0A),
                    title: 'Seri (Streak)',
                    body:
                        'Her gün en az 1 kart çalışırsan serin devam eder. Bir gün atlarsın serini sıfırlanır. Tutarlılık, TUS\'ta başarının temelidir.',
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
