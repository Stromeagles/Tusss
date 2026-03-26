import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/analytics_screen.dart' show ProgressAnalyticsScreen;
import '../models/progress_model.dart';
import '../models/user_model.dart';
import '../services/progress_service.dart';
import '../services/user_service.dart';
import '../screens/collections_screen.dart';
import '../screens/focus_screen.dart';
import '../screens/home_screen.dart';
import '../screens/mock_exam_setup_screen.dart';
import '../screens/profile_screen.dart';
import 'widgets/web_sidebar.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  AdaptiveAppShell — Platform-aware navigasyon kabuğu                     ║
// ║  • Web  → Stack: 72px daima-görünür strip + overlay panel               ║
// ║  • Mobil → HomeScreen olduğu gibi (geriye dönük uyumluluk)              ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class AdaptiveAppShell extends StatefulWidget {
  const AdaptiveAppShell({super.key});

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = false;

  /// Web'e özel tab ekranları — IndexedStack'te canlı tutulur.
  late final List<Widget> _screens = [
    const HomeScreen(hideBottomNav: true),   // 0 — Ana Sayfa
    const CollectionsScreen(),               // 1 — Koleksiyonlar
    const FocusScreen(),                     // 2 — Odak Modu
    const MockExamSetupScreen(),             // 3 — Deneme Sınavı
    const _AnalyticsTab(),                   // 4 — Analitik (lazy yükler)
    const ProfileScreen(),                   // 5 — Profil
  ];

  void _onTabSelected(int index) {
    setState(() {
      if (_selectedIndex != index) _selectedIndex = index;
      _sidebarExpanded = false; // tab seçilince overlay kapanır
    });
  }

  void _toggleSidebar() {
    setState(() => _sidebarExpanded = !_sidebarExpanded);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Mobil: hiçbir şey değişmez — HomeScreen kendi nav'ıyla çalışır
    if (!kIsWeb) return const HomeScreen();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Web geri tuşu boş sayfaya/siyah ekrana düşmesin
      child: Scaffold(
      backgroundColor: isDark ? AppTheme.background : AppTheme.lightBackground,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) => _handleKeyEvent(event),
        child: Stack(
          children: [
            // ── Layer 0: Content (72px boşluk bırakarak) ─────────────
            Positioned(
              left: 72,
              top: 0,
              right: 0,
              bottom: 0,
              child: _WebContentArea(
                index: _selectedIndex,
                screens: _screens,
                isDark: isDark,
              ),
            ),

            // ── Layer 1: Daima görünür 72px collapsed strip ───────────
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 72,
              child: WebSidebar(
                selectedIndex: _selectedIndex,
                onTabSelected: _onTabSelected,
                isDark: isDark,
                onToggle: _toggleSidebar,
              ),
            ),

            // ── Layer 2: Barrier — dışarıya tıklanınca kapat ─────────
            if (_sidebarExpanded)
              Positioned(
                left: 240,
                top: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarExpanded = false),
                  child: Container(color: Colors.transparent),
                ),
              ),

            // ── Layer 3: Overlay expanded panel ──────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: _sidebarExpanded ? 0 : -240,
              top: 0,
              bottom: 0,
              width: 240,
              child: WebSidebarOverlay(
                selectedIndex: _selectedIndex,
                onTabSelected: _onTabSelected,
                isDark: isDark,
                onClose: () => setState(() => _sidebarExpanded = false),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ── Klavye Kısayolları ─────────────────────────────────────────────────────
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isAlt = HardwareKeyboard.instance.isAltPressed;
    if (!isAlt) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final Map<LogicalKeyboardKey, int> bindings = {
      LogicalKeyboardKey.digit1: 0,
      LogicalKeyboardKey.digit2: 1,
      LogicalKeyboardKey.digit3: 2,
      LogicalKeyboardKey.digit4: 3,
      LogicalKeyboardKey.digit5: 4,
      LogicalKeyboardKey.digit6: 5,
    };

    if (bindings.containsKey(key)) {
      _onTabSelected(bindings[key]!);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

// ── Web Content Area ──────────────────────────────────────────────────────────

class _WebContentArea extends StatelessWidget {
  final int index;
  final List<Widget> screens;
  final bool isDark;

  const _WebContentArea({
    required this.index,
    required this.screens,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      children: screens,
    );
  }
}

// ── Analytics Tab Wrapper ─────────────────────────────────────────────────────

class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab();

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  UserProfile? _user;
  StudyProgress? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      UserService().loadUser(),
      ProgressService().loadProgressCached(),
    ]);
    if (!mounted) return;
    setState(() {
      _user     = results[0] as UserProfile;
      _progress = results[1] as StudyProgress;
      _loading  = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.cyan)),
      );
    }
    return ProgressAnalyticsScreen(user: _user!, progress: _progress!);
  }
}

// ── Web Top Bar (isteğe bağlı — tab başlıkları için) ─────────────────────────

class WebTopBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget>? actions;

  const WebTopBar({
    super.key,
    required this.title,
    required this.isDark,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.surface : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
