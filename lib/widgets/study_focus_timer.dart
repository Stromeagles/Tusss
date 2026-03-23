import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_service.dart';
import '../screens/focus_screen.dart';
import '../theme/app_theme.dart';
import '../utils/transitions.dart';

class StudyFocusTimer extends StatelessWidget {
  const StudyFocusTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FocusService>(
      builder: (context, focus, child) {
        if (!focus.isRunning && !focus.isAudioPlaying) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(context, AppRoute.slideUp(const FocusScreen()));
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.cyan.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (focus.isRunning) ...[
                  Text(
                    focus.timerString,
                    style: const TextStyle(
                      color: AppTheme.cyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (focus.isAudioPlaying) const _PulseNoteIcon(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PulseNoteIcon extends StatefulWidget {
  const _PulseNoteIcon();

  @override
  State<_PulseNoteIcon> createState() => _PulseNoteIconState();
}

class _PulseNoteIconState extends State<_PulseNoteIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_controller.value * 0.3),
          child: Opacity(
            opacity: 0.6 + (_controller.value * 0.4),
            child: const Icon(Icons.music_note_rounded,
                color: AppTheme.cyan, size: 14),
          ),
        );
      },
    );
  }
}
