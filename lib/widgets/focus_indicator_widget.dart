import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/focus_service.dart';
import '../theme/app_theme.dart';

/// AppBar'da gösterilen kompakt odaklanma sayacı.
/// Sadece timer aktifken veya ses çalarken görünür.
class FocusIndicatorWidget extends StatelessWidget {
  const FocusIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = Provider.of<FocusService>(context);
    final isActive = focus.isRunning || focus.isAudioPlaying;

    if (!isActive) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (focus.isRunning) ...[
            const Icon(Icons.timer_rounded, color: AppTheme.cyan, size: 14),
            const SizedBox(width: 4),
            Text(
              focus.timerString,
              style: const TextStyle(
                color: AppTheme.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
          if (focus.isRunning && focus.isAudioPlaying)
            const SizedBox(width: 6),
          if (focus.isAudioPlaying)
            const Icon(Icons.music_note_rounded, color: AppTheme.neonPink, size: 14)
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.15, 1.15),
                  duration: 600.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.15, 1.15),
                  end: const Offset(0.85, 0.85),
                  duration: 600.ms,
                ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(duration: 3000.ms, color: AppTheme.cyan.withValues(alpha: 0.15));
  }
}
