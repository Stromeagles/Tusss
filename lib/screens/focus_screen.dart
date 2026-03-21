import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/focus_service.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusService = Provider.of<FocusService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0D1117), Color(0xFF161B22)]
                : const [Color(0xFFF0F5FF), Color(0xFFE8F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Ambient Glows
            Positioned(top: -100, right: -50,
                child: _AmbientBlob(color: AppTheme.cyan, size: 300, opacity: isDark ? 0.12 : 0.05)),
            Positioned(bottom: -50, left: -50,
                child: _AmbientBlob(color: AppTheme.neonPurple, size: 250, opacity: isDark ? 0.10 : 0.04)),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDark),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimerCircle(focusService, isDark),
                        const SizedBox(height: 40),
                        _buildControls(focusService, isDark),
                      ],
                    ),
                  ),
                  _buildSoundPicker(focusService, isDark),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            'FOCUS LAB',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildTimerCircle(FocusService service, bool isDark) {
    final progress = 1.0 - (service.secondsRemaining / (25 * 60)); // Hardcoded 25 for now
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Glow
        Container(
          width: 260, height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Progress Ring
        SizedBox(
          width: 240, height: 240,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            color: AppTheme.cyan,
            strokeCap: StrokeCap.round,
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
            Text(
              service.isRunning ? 'ODAKLANIYORSUN' : 'HAZIR',
              style: GoogleFonts.inter(
                color: AppTheme.cyan.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    ).animate(target: service.isRunning ? 1 : 0)
     .shimmer(duration: 2000.ms, color: AppTheme.cyan.withValues(alpha: 0.2));
  }

  Widget _buildControls(FocusService service, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: service.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onTap: () {
            HapticFeedback.mediumImpact();
            if (service.isRunning) {
              service.pauseTimer();
            } else {
              service.startTimer();
            }
          },
          primary: true,
          isDark: isDark,
        ),
        const SizedBox(width: 20),
        _ControlButton(
          icon: Icons.refresh_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            service.stopTimer();
          },
          primary: false,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSoundPicker(FocusService service, bool isDark) {
    return Column(
      children: [
        Text(
          'ODAKLANMA SESİ',
          style: GoogleFonts.inter(
            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: FocusSound.values.length,
            itemBuilder: (context, index) {
              final sound = FocusSound.values[index];
              final isSelected = service.currentSound == sound;
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  service.setSound(sound);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.cyan.withValues(alpha: 0.15)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.cyan : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getSoundIcon(sound),
                        color: isSelected ? AppTheme.cyan : (isDark ? Colors.white54 : Colors.black54),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sound.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: isSelected ? AppTheme.cyan : (isDark ? Colors.white38 : Colors.black38),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getSoundIcon(FocusSound sound) {
    switch (sound) {
      case FocusSound.none: return Icons.volume_off_rounded;
      case FocusSound.lofi: return Icons.headphones_rounded;
      case FocusSound.whiteNoise: return Icons.waves_rounded;
      case FocusSound.rain: return Icons.water_drop_rounded;
      case FocusSound.hospital: return Icons.local_hospital_rounded;
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool isDark;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: primary ? 80 : 60,
        height: primary ? 80 : 60,
        decoration: BoxDecoration(
          color: primary 
              ? AppTheme.cyan 
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          shape: BoxShape.circle,
          boxShadow: primary ? [
            BoxShadow(
              color: AppTheme.cyan.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ] : [],
        ),
        child: Icon(
          icon,
          color: primary ? Colors.white : (isDark ? Colors.white : Colors.black),
          size: primary ? 40 : 24,
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
