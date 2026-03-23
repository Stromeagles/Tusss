import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/pomodoro_service.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<PomodoroService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Faza göre renk teması
    final phaseColor = service.isFocusPhase
        ? AppTheme.cyan           // Coral — odaklanma
        : const Color(0xFF3FB950); // Yeşil — mola

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
                : const [Color(0xFFF0F5FF), Color(0xFFE8F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Ambient Glow Blobs ──────────────────────────────
            Positioned(
              top: -100, right: -60,
              child: _AmbientBlob(color: phaseColor, size: 320, opacity: isDark ? 0.14 : 0.06),
            ),
            Positioned(
              bottom: -80, left: -60,
              child: _AmbientBlob(color: AppTheme.neonPurple, size: 260, opacity: isDark ? 0.10 : 0.04),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDark),
                  const SizedBox(height: 8),

                  // ── Faz Göstergesi ──────────────────────────────
                  _buildPhaseChip(service, isDark, phaseColor),

                  // ── Timer Alanı ─────────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimerRing(service, isDark, phaseColor),
                        const SizedBox(height: 44),
                        _buildControls(service, isDark, phaseColor),
                      ],
                    ),
                  ),

                  // ── Alt Bilgi Kartları ──────────────────────────
                  _buildStatsBar(service, isDark, phaseColor),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'POMODORO',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Faz Chip'i (Odaklanma / Mola) ──────────────────────────────────────────
  Widget _buildPhaseChip(PomodoroService service, bool isDark, Color phaseColor) {
    final label = service.isFocusPhase ? 'ODAKLANMA' : 'MOLA';
    final icon = service.isFocusPhase ? Icons.local_fire_department_rounded : Icons.coffee_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phaseColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: phaseColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: phaseColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(service.isFocusPhase))
     .fadeIn(duration: 300.ms)
     .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  // ── Dairesel Timer ──────────────────────────────────────────────────────────
  Widget _buildTimerRing(PomodoroService service, bool isDark, Color phaseColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dış glow
        Container(
          width: 280, height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: service.isRunning ? 0.20 : 0.08),
                blurRadius: 60,
                spreadRadius: 5,
              ),
            ],
          ),
        ),

        // Custom Painter — Dairesel İlerleme Çubuğu
        SizedBox(
          width: 260, height: 260,
          child: CustomPaint(
            painter: _PomodoroRingPainter(
              progress: service.progress,
              color: phaseColor,
              trackColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),

        // İç glassmorphism daire
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.6),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
          ),
        ),

        // Timer Text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              service.timerString,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 64,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service.isRunning
                  ? (service.isFocusPhase ? 'ODAKLANIYORSUN' : 'MOLA VERİYORSUN')
                  : 'HAZIR',
              style: GoogleFonts.inter(
                color: phaseColor.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    ).animate(target: service.isRunning ? 1 : 0)
     .shimmer(duration: 2500.ms, color: phaseColor.withValues(alpha: 0.15));
  }

  // ── Kontrol Butonları ───────────────────────────────────────────────────────
  Widget _buildControls(PomodoroService service, bool isDark, Color phaseColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset / Sıfırla
        _ControlButton(
          icon: Icons.refresh_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            service.reset();
          },
          primary: false,
          isDark: isDark,
          color: phaseColor,
        ),
        const SizedBox(width: 24),

        // Play / Pause
        _ControlButton(
          icon: service.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onTap: () {
            HapticFeedback.mediumImpact();
            service.isRunning ? service.pause() : service.start();
          },
          primary: true,
          isDark: isDark,
          color: phaseColor,
        ),
        const SizedBox(width: 24),

        // Skip / Geç
        _ControlButton(
          icon: Icons.skip_next_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            service.skip();
          },
          primary: false,
          isDark: isDark,
          color: phaseColor,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.15, end: 0);
  }

  // ── Alt İstatistik Barı ─────────────────────────────────────────────────────
  Widget _buildStatsBar(PomodoroService service, bool isDark, Color phaseColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Toplam Çalışma Süresi
            Expanded(
              child: _StatItem(
                icon: Icons.schedule_rounded,
                label: 'Bugün Toplam',
                value: service.todayFocusFormatted,
                color: phaseColor,
                isDark: isDark,
              ),
            ),
            Container(
              width: 1, height: 36,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            // Tamamlanan Pomodoro Sayısı
            Expanded(
              child: _StatItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Pomodoro',
                value: '${service.completedPomodoros}',
                color: AppTheme.neonGold,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Alt Widget'lar ──────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool isDark;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.primary,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: primary ? 80 : 56,
        height: primary ? 80 : 56,
        decoration: BoxDecoration(
          color: primary
              ? color
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          shape: BoxShape.circle,
          border: primary
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: primary
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black54),
          size: primary ? 40 : 22,
        ),
      ),
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  final Color color;
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

// ═══════════════════════════════════════════════════════════════════════════════
// ── Custom Painter — Dairesel İlerleme Çubuğu ─────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _PomodoroRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _PomodoroRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const strokeWidth = 10.0;

    // Track (arka plan halkası)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // İlerleme yayı
    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;

      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: -pi / 2 + sweepAngle,
          colors: [
            color.withValues(alpha: 0.6),
            color,
          ],
          stops: const [0.0, 1.0],
          transform: const GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,         // 12 o'clock'tan başla
        sweepAngle,
        false,
        progressPaint,
      );

      // Uç noktada parlak nokta
      final dotAngle = -pi / 2 + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * cos(dotAngle),
        center.dy + radius * sin(dotAngle),
      );

      // Glow
      canvas.drawCircle(
        dotCenter,
        8,
        Paint()..color = color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Dot
      canvas.drawCircle(
        dotCenter,
        5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_PomodoroRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
