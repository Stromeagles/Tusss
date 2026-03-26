import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/focus_service.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  WebSidebar — Daima 72px collapsed strip                                 ║
// ║  Logo ikonuna tıklanınca overlay panel açılır (AdaptiveAppShell yönetir) ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDark;
  final VoidCallback onToggle;

  const WebSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final focusService = Provider.of<FocusService>(context);
    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo — toggle butonu ────────────────────────────────────
          _LogoButton(isDark: isDark, onTap: onToggle),
          _Divider(isDark: isDark),
          // ── Nav ─────────────────────────────────────────────────────
          Expanded(
            child: _NavIconList(
              selectedIndex: selectedIndex,
              onTabSelected: onTabSelected,
              isDark: isDark,
              focusService: focusService,
            ),
          ),
        ],
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  WebSidebarOverlay — Glassmorphism overlay panel (240px)                 ║
// ║  AdaptiveAppShell tarafından Stack içinde konumlandırılır.               ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class WebSidebarOverlay extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDark;
  final VoidCallback onClose;

  const WebSidebarOverlay({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final focusService = Provider.of<FocusService>(context);

    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 240,
          decoration: BoxDecoration(
            color: bg.withValues(alpha: isDark ? 0.88 : 0.92),
            border: Border(right: BorderSide(color: border, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo + Kapat ───────────────────────────────────────
              _OverlayLogoSection(isDark: isDark, onClose: onClose),
              _Divider(isDark: isDark),
              // ── Nav ─────────────────────────────────────────────────
              Expanded(
                child: _NavExpandedList(
                  selectedIndex: selectedIndex,
                  onTabSelected: onTabSelected,
                  isDark: isDark,
                  focusService: focusService,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo Button (collapsed strip'deki ikon — toggle trigger) ─────────────────

class _LogoButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _LogoButton({required this.isDark, required this.onTap});

  @override
  State<_LogoButton> createState() => _LogoButtonState();
}

class _LogoButtonState extends State<_LogoButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          height: 64,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.cyan, AppTheme.neonPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(
                        alpha: _hovered ? 0.55 : 0.28),
                    blurRadius: _hovered ? 20 : 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'A',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Overlay Logo Section (expanded panel'deki logo + kapat butonu) ────────────

class _OverlayLogoSection extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClose;

  const _OverlayLogoSection({required this.isDark, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSub     = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onClose,
            child: Row(
              children: [
                // Gradient logo mark
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.cyan, AppTheme.neonPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.30),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AsisTus',
                        style: GoogleFonts.outfit(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'TUS Hazırlık',
                        style: GoogleFonts.inter(
                          color: textSub,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Kapat oku
                Icon(
                  Icons.chevron_left_rounded,
                  color: textSub,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Icon List (collapsed 72px strip için) ─────────────────────────────────

class _NavIconList extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDark;
  final FocusService focusService;

  const _NavIconList({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isDark,
    required this.focusService,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(focusService);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: items
          .map((item) => _SidebarNavItem(
                item: item,
                isActive: selectedIndex == item.index,
                expanded: false,
                isDark: isDark,
                onTap: () => onTabSelected(item.index),
              ))
          .toList(),
    );
  }
}

// ── Nav Expanded List (overlay panel için) ────────────────────────────────────

class _NavExpandedList extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDark;
  final FocusService focusService;

  const _NavExpandedList({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isDark,
    required this.focusService,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(focusService);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Text(
            'NAVİGASYON',
            style: GoogleFonts.inter(
              color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _SidebarNavItem(
              item: item,
              isActive: selectedIndex == item.index,
              expanded: true,
              isDark: isDark,
              onTap: () => onTabSelected(item.index),
            )),
      ],
    );
  }
}

// ── Shared nav items builder ──────────────────────────────────────────────────

List<_SidebarItem> _buildItems(FocusService focusService) => [
      _SidebarItem(
        index: 0,
        icon: Icons.dashboard_rounded,
        label: 'Ana Sayfa',
        color: AppTheme.cyan,
      ),
      _SidebarItem(
        index: 1,
        icon: Icons.folder_special_rounded,
        label: 'Koleksiyonlar',
        color: AppTheme.neonPurple,
      ),
      _SidebarItem(
        index: 2,
        icon: focusService.isRunning ? Icons.timer_rounded : Icons.timer_outlined,
        label: 'Odak Modu',
        color: AppTheme.success,
        badge: focusService.isRunning ? focusService.timerString : null,
        dot: focusService.isAudioPlaying,
      ),
      _SidebarItem(
        index: 3,
        icon: Icons.assignment_rounded,
        label: 'Deneme Sınavı',
        color: AppTheme.coral,
      ),
      _SidebarItem(
        index: 4,
        icon: Icons.bar_chart_rounded,
        label: 'Analitik',
        color: AppTheme.cyan,
      ),
      _SidebarItem(
        index: 5,
        icon: Icons.person_rounded,
        label: 'Profil',
        color: AppTheme.neonGold,
      ),
    ];

// ── Sidebar Item Data ─────────────────────────────────────────────────────────

class _SidebarItem {
  final int index;
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final bool dot;

  const _SidebarItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
    this.dot = false,
  });
}

// ── Sidebar Nav Item (hover + active states) ──────────────────────────────────

class _SidebarNavItem extends StatefulWidget {
  final _SidebarItem item;
  final bool isActive;
  final bool expanded;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.expanded,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppTheme.textPrimary    : AppTheme.lightTextPrimary;
    final subColor  = widget.isDark ? AppTheme.textSecondary  : AppTheme.lightTextSecondary;
    final color     = widget.item.color;

    Color bgColor = Colors.transparent;
    if (widget.isActive) {
      bgColor = color.withValues(alpha: widget.isDark ? 0.14 : 0.10);
    } else if (_hovered) {
      bgColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 12 : 0,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive
                ? Border.all(color: color.withValues(alpha: 0.22), width: 1)
                : null,
          ),
          child: widget.expanded
              ? _buildExpanded(textColor, subColor, color)
              : _buildCollapsed(subColor, color),
        ),
      ),
    );
  }

  Widget _buildExpanded(Color textColor, Color subColor, Color color) {
    final labelColor = widget.isActive ? color : (_hovered ? textColor : subColor);

    return Row(
      children: [
        _buildIcon(subColor, color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.item.label,
            style: GoogleFonts.inter(
              color: labelColor,
              fontSize: 13.5,
              fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.item.badge != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.item.badge!,
              style: GoogleFonts.inter(
                color: color, fontSize: 10, fontWeight: FontWeight.w700,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 2000.ms, color: color.withValues(alpha: 0.4)),
      ],
    );
  }

  Widget _buildCollapsed(Color subColor, Color color) {
    return Center(child: _buildIcon(subColor, color));
  }

  Widget _buildIcon(Color subColor, Color color) {
    final iconColor = widget.isActive ? color
        : (_hovered
            ? (widget.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary)
            : subColor);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(widget.item.icon, color: iconColor, size: 20),
        if (!widget.expanded && (widget.item.badge != null || widget.item.dot))
          Positioned(
            right: -5, top: -5,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
              ),
            ).animate(onPlay: (c) => c.repeat())
             .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.15, 1.15),
                    duration: 700.ms, curve: Curves.easeInOut)
             .then()
             .scale(begin: const Offset(1.15, 1.15), end: const Offset(0.8, 0.8),
                    duration: 700.ms, curve: Curves.easeInOut),
          ),
      ],
    );
  }
}

// ── Divider ────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.05),
    );
  }
}
