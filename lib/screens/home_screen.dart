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
import '../widgets/notifications_sheet.dart';
import '../models/subject_registry.dart';
import '../models/sm2_model.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';
import '../services/user_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/theme_service.dart';
import '../utils/transitions.dart';
import 'flashcard_screen.dart';
import 'case_study_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'focus_screen.dart';
import 'spots_screen.dart';
import 'collections_screen.dart';
import 'mock_exam_setup_screen.dart';
import '../services/focus_service.dart';

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
        SpacedRepetitionService().getAllData(), // SM-2 verisini önbellekle
        _userService.loadUser(),
      ]);
      if (mounted) {
        final topics   = results[0] as List<Topic>;
        final progress = results[1] as StudyProgress;
        final sm2Data  = results[2] as Map<String, SM2CardData>;
        final user     = results[3] as UserProfile;

        // Tüm flashcard ve case ID'lerini topla
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler yüklenirken bir sorun oluştu. Bazı konular eksik olabilir.')),
        );
      }
    }
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
                ? const [Color(0xFF0F172A), Color(0xFF0F172A), Color(0xFF1E293B)]
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
                                  const SizedBox(height: 16),

                                  // ── Flashcard Hub ──────────────────────────────────────
                                  RepaintBoundary(child: _buildFlashcardHub(isDark)),

                                  const SizedBox(height: 32),

                                  // ── Questions Hub (Sorular) ─────────────────────────────
                                  RepaintBoundary(child: _buildCaseHub(isDark)),

                                  const SizedBox(height: 20),

                                  // ── Deneme Sınavı ─────────────────────────────────────
                                  _buildDenemeButton(isDark),

                                  const SizedBox(height: 12),

                                  // ── Spot Bilgiler Hızlı Erişim ────────────────────────
                                  _buildSpotBilgilerButton(isDark),

                                  const SizedBox(height: 12),

                                  // ── Klasörlerim Hızlı Erişim ──────────────────────────
                                  _buildKlasorlerimButton(isDark),

                                  const SizedBox(height: 20),
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
  Widget _buildAnimatedAvatar(bool isDark) {
    final hasImage = _user.profileImagePath != null &&
        _user.profileImagePath!.isNotEmpty &&
        !kIsWeb;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, AppRoute.slideUp(const ProfileScreen()));
        _loadData();
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

          // 🤖 AI BELL (CYAN) - BİREBİR ESKİ YERİ
          GestureDetector(
            onTap: _showAiInsightSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.psychology_rounded, color: AppTheme.cyan, size: 20),
            ),
          ),
          const SizedBox(width: 12),

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
          const SizedBox(width: 10),

          // Info Button
          GestureDetector(
            onTap: () => _showInfoSheet(context, isDark),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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

          // 🔔 BİLDİRİM ZİLİ (GLASSY) - AKTİF EDİLDİ
          GestureDetector(
            onTap: _showAppNotifications,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 9, right: 9,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
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

  // ── Flashcard Hub ──────────────────────────────────────────────────────────
  Widget _buildFlashcardHub(bool isDark) {
    return _buildHubSection(
      isDark: isDark,
      title: 'FlashKartlar',
      buttonLabel: 'FLASHKARTLAR',
      summary: _flashcardSummary,
      baseColor: AppTheme.cyan,
      folders: [
        (label: 'Doğrular', icon: Icons.check_circle_rounded, color: AppTheme.success, mode: FlashcardMode.learnedOnly),
        (label: 'Yanlışlar', icon: Icons.cancel_rounded, color: AppTheme.error, mode: FlashcardMode.failedOnly),
        (label: 'Favoriler', icon: Icons.bookmark_rounded, color: AppTheme.neonGold, mode: FlashcardMode.pocketOnly),
      ],
      onButtonTap: () => _showSubjectSelectionSheet(isCards: true, isDark: isDark),
      onFolderTap: (mode) async {
        await Navigator.push(context, AppRoute.slideUp(FlashcardScreen(initialMode: mode as FlashcardMode)));
        _loadData();
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1230), const Color(0xFF0F1A2E)]
                  : [const Color(0xFFF0E6FF), const Color(0xFFE6F0FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.neonPurple.withValues(alpha: isDark ? 0.25 : 0.15)),
          ),
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
      ),
    );
  }

  // ── Deneme Sınavı Hızlı Erişim ──────────────────────────────────────────────

  Widget _buildDenemeButton(bool isDark) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            AppRoute.slideUp(const MockExamSetupScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A0A10), const Color(0xFF1A1230)]
                  : [const Color(0xFFFFEEEE), const Color(0xFFFFEBF5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.cyan.withValues(alpha: isDark ? 0.30 : 0.20)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: isDark ? 0.10 : 0.05),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.cyan.withValues(alpha: 0.20),
                      AppTheme.neonPink.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.30)),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: AppTheme.cyan, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Deneme Sınavı',
                          style: GoogleFonts.inter(
                            color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('YENİ',
                            style: GoogleFonts.inter(
                              color: AppTheme.cyan, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('TUS formatında zamanlı sınav',
                      style: GoogleFonts.inter(
                        color: subColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.cyan.withValues(alpha: 0.6), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── Klasörlerim Hızlı Erişim ──────────────────────────────────────────────

  Widget _buildKlasorlerimButton(bool isDark) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            AppRoute.slideUp(const CollectionsScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F1A2E), const Color(0xFF1A1A30)]
                  : [const Color(0xFFE6F0FF), const Color(0xFFEEE6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.cyan.withValues(alpha: isDark ? 0.20 : 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_rounded,
                    color: AppTheme.cyan, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Klasörlerim',
                      style: GoogleFonts.inter(
                        color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('Kaydettiğin kartları organize et',
                      style: GoogleFonts.inter(
                        color: subColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.cyan.withValues(alpha: 0.6), size: 22),
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
      folders: [
        (label: 'Doğrular', icon: Icons.check_circle_rounded, color: AppTheme.success, mode: CaseStudyMode.learnedOnly),
        (label: 'Yanlışlar', icon: Icons.cancel_rounded, color: AppTheme.error, mode: CaseStudyMode.failedOnly),
        (label: 'Favoriler', icon: Icons.bookmark_rounded, color: AppTheme.neonGold, mode: CaseStudyMode.pocketOnly),
      ],
      onButtonTap: () => _showSubjectSelectionSheet(isCards: false, isDark: isDark),
      onFolderTap: (mode) async {
        await Navigator.push(context, AppRoute.slideUp(CaseStudyScreen(initialMode: mode as CaseStudyMode)));
        _loadData();
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
              final count = i == 0 ? summary.toReviewCount : (i == 1 ? summary.learnedCount : summary.bookmarkCount);
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                  child: _FolderCard(
                    label: f.label,
                    icon: f.icon,
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
                gradient: LinearGradient(
                  colors: [
                    baseColor,
                    baseColor.withValues(alpha: 0.8),
                    baseColor.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.015, 1.015), duration: 2500.ms, curve: Curves.easeInOut)
             .shimmer(duration: 2500.ms, color: Colors.white.withValues(alpha: 0.2)),
          ).animate().fadeIn(duration: 700.ms, delay: 300.ms),
        ],
      ),
    );
  }





  void _openAiInsightSheet(bool isDark) {
    // Branş → yanlış sayısı
    final Map<String, int> mistakeCounts = {};
    final Map<String, int> topicMistakes = {};

    for (final t in _topics) {
      for (final fc in t.flashcards) {
        final d = _sm2Data[fc.id];
        if (d != null && d.lastQuality == 1) {
          mistakeCounts[t.subject] = (mistakeCounts[t.subject] ?? 0) + 1;
          topicMistakes[t.subTopic] = (topicMistakes[t.subTopic] ?? 0) + 1;
        }
      }
      for (final cc in t.clinicalCases) {
        final d = _sm2Data[cc.id];
        if (d != null && d.lastQuality == 1) {
          mistakeCounts[t.subject] = (mistakeCounts[t.subject] ?? 0) + 1;
          topicMistakes[t.subTopic] = (topicMistakes[t.subTopic] ?? 0) + 1;
        }
      }
    }

    final topMistakeTopics = (topicMistakes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => e.key)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiInsightSheet(
        progress: _progress,
        isDark: isDark,
        mistakeCounts: mistakeCounts,
        topMistakeTopics: topMistakeTopics,
        userName: _user.name.isNotEmpty ? _user.name : 'Doktor',
        targetBranch: _user.targetBranch,
      ),
    );
  }

  void _showAppNotifications() {
    final isDark = ThemeService.isDark;
    
    // 🔍 Dinamik Veri Analizi
    final streak = _progress.currentStreak;
    final streakGoal = 10;
    
    // En kötü branşı bul
    Map<String, int> mistakeCounts = {};
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
    final topMistakeSubject = sortedMistakes.isEmpty ? "Derslerin" : sortedMistakes.first.key;
    final topSubjectMistakeCount = mistakeCounts[topMistakeSubject] ?? 0;

    final List<AppNotificationItem> notifications = [
      // 1. Seri Hatırlatıcısı
      AppNotificationItem(
        title: 'SERİ HATIRLATICISI',
        message: streak > 0 
          ? 'Kritik eşik! $streak günlük serini bozmamak için bugün en az $streakGoal kart bakmalısın. 🔥'
          : 'Bugün yeni bir seri başlatmak için harika bir gün! İlk 10 kartını çöz ve seriye başla. ⚡',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF6B00),
        timeLabel: 'Şimdi',
      ),
      
      // 2. SRS Uyarısı
      AppNotificationItem(
        title: 'TEKRAR UYARISI (SRS)',
        message: topSubjectMistakeCount > 0
          ? 'Dün \'Bilemedim\' dediğin $topSubjectMistakeCount $topMistakeSubject kartı seni bekliyor, hafızanı tazelemek istiyor. ⏳'
          : 'Tüm kartlarını başarıyla hafızana aldın! Yeni kartlarla devam edebilirsin. ✨',
        icon: Icons.history_edu_rounded,
        color: AppTheme.cyan,
        timeLabel: '2s önce',
      ),
      
      // 3. Haftalık Başarı
      AppNotificationItem(
        title: 'HAFTALIK BAŞARI RAPORU',
        message: 'Bu hafta yüksek doğruluk oranıyla bir \'$topMistakeSubject Canavarı\' oldun! Gelişimin harika gidiyor. 🏆',
        icon: Icons.emoji_events_rounded,
        color: AppTheme.neonGold,
        timeLabel: 'Dün',
      ),
      
      // 4. Sınav Sayacı
      AppNotificationItem(
        title: 'SINAV SAYACI',
        message: 'Geri sayım başladı: Hedef puanına ulaşmak için kalan ${_progress.daysToExam} günde her gün +${_progress.recommendedDailyGoal} soru çözmelisin. 📍',
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
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
    _loadData();
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    final focusService = Provider.of<FocusService>(context);
    final isFocusActive = focusService.isRunning || focusService.isAudioPlaying;

    final items = [
      (Icons.home_rounded,           Icons.home_outlined,           'Home'),
      (Icons.bar_chart_rounded,      Icons.bar_chart_outlined,      'Analiz'),
      (
        isFocusActive ? Icons.timer_rounded : Icons.timer_outlined,
        isFocusActive ? Icons.timer_rounded : Icons.timer_outlined,
        'Odak'
      ),
      (Icons.person_rounded,         Icons.person_outline_rounded,  'Profil'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                        // ── Focus Indicators (Next to Profile) ──
                        if (i == 5) ...[
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
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _onNavTap(int index) async {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: break; // Home
      case 1: // Analiz
        await Navigator.push(context, AppRoute.slideUp(ProgressAnalyticsScreen(user: _user, progress: _progress)));
        _loadData();
        break;
      case 2: // Odak
        await Navigator.push(context, AppRoute.slideUp(const FocusScreen()));
        _loadData();
        break;
      case 3: // Profil
        await Navigator.push(context, AppRoute.slideUp(const ProfileScreen()));
        _loadData();
        break;
    }
    if (mounted) setState(() => _navIndex = 0);
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
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                    icon: Icons.timer_rounded,
                    color: AppTheme.neonGold,
                    title: 'Günlük Limitler',
                    body:
                        'Her gün sana özel ücretsiz bir soru ve kart çözme kotası ayrılır. '
                        'Günlük limitini doldurduktan sonra yeni sorulara erişmek için ertesi günü bekleyebilir '
                        'veya sınırsız erişim için Premium\'a geçebilirsin.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.repeat_rounded,
                    color: AppTheme.cyan,
                    title: 'Akıllı Tekrar Algoritması',
                    body:
                        'Sistem sadece rastgele soru getirmez. Aralıklı tekrar (Spaced Repetition) algoritması '
                        'ile "Bilemediklerini" ve tam unutmak üzereyken "Tekrar Vakti Gelen Bildiklerini" '
                        'otomatik olarak önüne getirir. Zorlandığın kartlar daha sık, kolay kartlar daha seyrek gelir.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.bar_chart_rounded,
                    color: AppTheme.neonPurple,
                    title: 'Ustalık (Gidişat Analizi)',
                    body:
                        'İstatistiklerdeki branş hakimiyet barlarının dolması için bir soruyu sadece 1 kez değil, '
                        'en az 3 kez üst üste "Bildim" olarak yanıtlaman gerekir. '
                        'Böylece gerçekten öğrendiğin konular yüzdeliğe yansır.',
                  ),
                  _InfoSection(
                    isDark: isDark,
                    icon: Icons.psychology_rounded,
                    color: const Color(0xFFFF9F0A),
                    title: 'Zayıf Konular (Eksik Kapatma)',
                    body:
                        'AI Asistan sekmesi tamamen senin kişisel eksiklerini kapatmak için tasarlandı. '
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
