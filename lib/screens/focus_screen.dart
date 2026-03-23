import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/focus_service.dart';
import '../services/premium_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // Pomodoro süreleri (dakika)
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  bool _isPomodoro = true; // true = Pomodoro geri sayım, false = Stopwatch
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final premium = await PremiumService().isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FocusService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0B1120), Color(0xFF0F172A), Color(0xFF152035)]
                : const [Color(0xFFF0F5FF), Color(0xFFE8F0FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow
            Positioned(
              top: -120, left: -80,
              child: _BreathingBlob(
                color: AppTheme.cyan, size: 350,
                opacity: isDark ? 0.10 : 0.04,
                isActive: service.isRunning,
              ),
            ),
            Positioned(
              bottom: -100, right: -60,
              child: _BreathingBlob(
                color: AppTheme.neonPurple, size: 280,
                opacity: isDark ? 0.08 : 0.03,
                isActive: service.isRunning,
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDark),
                  const Spacer(flex: 1),
                  _buildTimerCircle(service, isDark),
                  const SizedBox(height: 12),
                  _buildStatusText(service, isDark),
                  const Spacer(flex: 1),
                  _buildControls(context, service, isDark),
                  const SizedBox(height: 24),
                  _buildSoundPicker(service, isDark),
                  const SizedBox(height: 12),
                  _buildStats(service, isDark),
                  const SizedBox(height: 20),
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
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white60 : AppTheme.lightTextPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'FOCUS LAB',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white54 : AppTheme.lightTextPrimary,
              fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3.0,
            ),
          ),
          const Spacer(),
          // Mod toggle
          GestureDetector(
            onTap: () {
              final service = Provider.of<FocusService>(context, listen: false);
              if (!service.isRunning) {
                if (_isPomodoro && !_isPremium) {
                  // Free kullanıcılar serbest mod kullanamaz
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text('Serbest mod — Premium özellik',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.9),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                setState(() => _isPomodoro = !_isPomodoro);
                HapticFeedback.selectionClick();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (_isPomodoro ? AppTheme.cyan : AppTheme.neonPurple).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isPomodoro ? AppTheme.cyan : AppTheme.neonPurple).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _isPomodoro ? 'Pomodoro' : 'Serbest',
                style: GoogleFonts.inter(
                  color: _isPomodoro ? AppTheme.cyan : AppTheme.neonPurple,
                  fontSize: 11, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(FocusService service, bool isDark) {
    return GestureDetector(
      onLongPress: service.isRunning ? null : () => _showDurationPicker(isDark),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dış glow
          if (service.isRunning)
            Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.12),
                    blurRadius: 60, spreadRadius: 10,
                  ),
                ],
              ),
            ),

          // Ring
          SizedBox(
            width: 260, height: 260,
            child: CustomPaint(
              painter: _FlowRingPainter(
                progress: _isPomodoro ? service.pomodoroProgress(_focusMinutes) : service.stopwatchProgress,
                isActive: service.isRunning,
                color: service.isBreak ? AppTheme.success : AppTheme.cyan,
                trackColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Glass center
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 210, height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.5),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ),
          ),

          // Timer text — tıklanabilir
          GestureDetector(
            onTap: service.isRunning ? null : () => _showDurationPicker(isDark),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (service.isBreak)
                  Text(
                    'MOLA',
                    style: GoogleFonts.inter(
                      color: AppTheme.success.withValues(alpha: 0.8),
                      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2,
                    ),
                  ),
                Text(
                  _isPomodoro ? service.pomodoroString(_focusMinutes) : service.timerString,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 52, fontWeight: FontWeight.w600, letterSpacing: -1,
                  ),
                ),
                if (!service.isRunning && !service.isBreak)
                  Text(
                    'Ayarlamak için dokun',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                      fontSize: 10, fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(FocusService service, bool isDark) {
    String text;
    if (service.isBreak) {
      text = 'Mola vaktinde rahatla...';
    } else if (service.isRunning) {
      text = 'Akışta kalıyorsun...';
    } else if (service.elapsedSeconds > 0) {
      text = 'Duraklatıldı';
    } else {
      text = _isPomodoro ? '$_focusMinutes dk odak / $_breakMinutes dk mola' : 'Serbest mod — sınırsız odak';
    }

    return Text(
      text,
      style: GoogleFonts.inter(
        color: service.isRunning
            ? (service.isBreak ? AppTheme.success : AppTheme.cyan).withValues(alpha: 0.7)
            : (isDark ? Colors.white30 : Colors.black26),
        fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildControls(BuildContext context, FocusService service, bool isDark) {
    final hasElapsed = service.elapsedSeconds > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasElapsed) ...[
          _ControlButton(
            icon: Icons.stop_rounded, label: 'Bitir',
            onTap: () {
              HapticFeedback.mediumImpact();
              _showSessionSummary(context, service);
            },
            primary: false, isDark: isDark,
          ),
          const SizedBox(width: 28),
        ],
        _ControlButton(
          icon: service.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: service.isRunning ? 'Duraklat' : 'Başla',
          onTap: () {
            HapticFeedback.mediumImpact();
            if (service.isRunning) {
              service.pauseTimer();
            } else {
              if (_isPomodoro) {
                service.startPomodoro(_focusMinutes, _breakMinutes, onPhaseEnd: () => _showPhaseNotification(service));
              } else {
                service.startTimer();
              }
            }
          },
          primary: true, isDark: isDark,
        ),
      ],
    );
  }

  void _showPhaseNotification(FocusService service) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final isBreak = service.isBreak;
    final message = isBreak ? 'Harika! Şimdi Mola Zamanı.' : 'Mola Bitti, Yeni Odak!';
    final color = isBreak ? AppTheme.success : AppTheme.cyan;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isBreak ? Icons.coffee_rounded : Icons.local_fire_department_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSessionSummary(BuildContext context, FocusService service) {
    final elapsed = service.endSession();
    service.stopSound();
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF12161E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 28),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppTheme.cyan, AppTheme.neonPurple]),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Harika Odaklanma!',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              minutes > 0 ? '$minutes dk $seconds sn kesintisiz odaklandın.' : '$seconds sn odaklandın.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Tamam', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDurationPicker(bool isDark) {
    int tempFocus = _focusMinutes;
    int tempBreak = _breakMinutes;
    // Free: sadece 10, 15, 25 dk | Premium: tüm seçenekler
    final freePresets = [10, 15, 25];
    final premiumPresets = [10, 15, 25, 45, 50, 60, 90, 120];
    final presets = _isPremium ? premiumPresets : freePresets;

    final freeBreaks = [5];
    final premiumBreaks = [5, 10, 15, 20];
    final breaks = _isPremium ? premiumBreaks : freeBreaks;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF12161E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Süre Ayarla', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  if (_isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.cyan, AppTheme.neonPurple]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('PRO', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Preset chips
              Text('ODAK SÜRESİ', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 8,
                children: presets.map((m) {
                  final selected = tempFocus == m;
                  final label = m >= 60 ? '${m ~/ 60}s ${m % 60 > 0 ? "${m % 60}dk" : ""}' : '$m dk';
                  return GestureDetector(
                    onTap: () => setSheetState(() => tempFocus = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.cyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AppTheme.cyan : Colors.transparent, width: 1.5),
                      ),
                      child: Text(label.trim(),
                        style: GoogleFonts.inter(
                          color: selected ? AppTheme.cyan : Colors.white54,
                          fontSize: 14, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Mola süresi
              Text('MOLA SÜRESİ', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: breaks.map((m) {
                  final selected = tempBreak == m;
                  return GestureDetector(
                    onTap: () => setSheetState(() => tempBreak = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.success.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AppTheme.success : Colors.transparent, width: 1.5),
                      ),
                      child: Text('$m dk',
                        style: GoogleFonts.inter(
                          color: selected ? AppTheme.success : Colors.white54,
                          fontSize: 14, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Free kullanıcılar için premium teşvik
              if (!_isPremium) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.cyan.withValues(alpha: 0.08), AppTheme.neonPurple.withValues(alpha: 0.08)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppTheme.cyan, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Premium ile 2 saate kadar odak, özel mola süreleri ve tüm ortam sesleri!',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _focusMinutes = tempFocus;
                      _breakMinutes = tempBreak;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyan, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundPicker(FocusService service, bool isDark) {
    // Free: Sessiz + Yağmur | Premium: tümü
    final freeSounds = {FocusSound.none, FocusSound.yagmur};

    return Column(
      children: [
        Text('ORTAM SESİ',
          style: GoogleFonts.inter(color: isDark ? Colors.white24 : AppTheme.lightTextSecondary,
              fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
        const SizedBox(height: 14),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: FocusSound.values.length,
            itemBuilder: (context, index) {
              final sound = FocusSound.values[index];
              final isSelected = service.currentSound == sound;
              final isLocked = !_isPremium && !freeSounds.contains(sound);

              return GestureDetector(
                onTap: () {
                  if (isLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text('${sound.label} — Premium özellik',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.9),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  HapticFeedback.selectionClick();
                  service.setSound(sound);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 72, margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.cyan.withValues(alpha: 0.12)
                        : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.cyan.withValues(alpha: 0.5)
                          : isLocked
                              ? AppTheme.neonPurple.withValues(alpha: 0.15)
                              : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_getSoundEmoji(sound),
                            style: TextStyle(fontSize: 22, color: isLocked ? Colors.white.withValues(alpha: 0.3) : null)),
                          const SizedBox(height: 6),
                          Text(sound.label, textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: isLocked
                                  ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.20))
                                  : isSelected ? AppTheme.cyan : (isDark ? Colors.white30 : Colors.black38),
                              fontSize: 9, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (isLocked)
                        Positioned(
                          top: 4, right: 4,
                          child: Icon(Icons.lock_rounded,
                            size: 12,
                            color: AppTheme.neonPurple.withValues(alpha: 0.5)),
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

  String _getSoundEmoji(FocusSound sound) {
    switch (sound) {
      case FocusSound.none: return '🔇';
      case FocusSound.yagmur: return '🌧️';
      case FocusSound.deepSng: return '🎵';
      case FocusSound.kabalikCafe: return '☕';
      case FocusSound.ruzgar: return '🍃';
      case FocusSound.tikTak: return '⏰';
    }
  }

  Widget _buildStats(FocusService service, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(icon: Icons.schedule_rounded, label: 'Bugün', value: service.todayFocusFormatted, isDark: isDark),
            Container(width: 1, height: 30, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
            _StatChip(icon: Icons.coffee_rounded, label: 'Mola', value: service.todayBreakFormatted, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool isDark;

  const _ControlButton({required this.icon, required this.label, required this.onTap, required this.primary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: primary ? 76 : 56, height: primary ? 76 : 56,
            decoration: BoxDecoration(
              color: primary ? AppTheme.cyan : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
              shape: BoxShape.circle,
              border: primary ? null : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08)),
              boxShadow: primary ? [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))] : [],
            ),
            child: Icon(icon, color: primary ? Colors.white : (isDark ? Colors.white60 : Colors.black45), size: primary ? 36 : 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(color: isDark ? Colors.white30 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _StatChip({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: isDark ? Colors.white24 : Colors.black26, size: 16),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.inter(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26, fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BreathingBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  final bool isActive;
  const _BreathingBlob({required this.color, required this.size, this.opacity = 0.10, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0.0)]),
      ),
    ).animate(
      onPlay: (c) => isActive ? c.repeat(reverse: true) : null,
      target: isActive ? 1 : 0,
    ).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: 4000.ms, curve: Curves.easeInOut)
     .fadeIn(duration: 1000.ms);
  }
}

class _FlowRingPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final Color color;
  final Color trackColor;
  _FlowRingPainter({required this.progress, required this.isActive, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const strokeWidth = 6.0;

    canvas.drawCircle(center, radius, Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);

    if (progress <= 0.001) return;

    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2, endAngle: -pi / 2 + sweepAngle,
        colors: [color.withValues(alpha: 0.4), color],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, sweepAngle, false, progressPaint);

    final dotAngle = -pi / 2 + sweepAngle;
    final dotCenter = Offset(center.dx + radius * cos(dotAngle), center.dy + radius * sin(dotAngle));
    canvas.drawCircle(dotCenter, 6, Paint()..color = color.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(dotCenter, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FlowRingPainter old) => old.progress != progress || old.isActive != isActive || old.color != color;
}
