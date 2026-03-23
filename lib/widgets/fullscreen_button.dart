import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Conditional import: web implementation vs no-op stub
import 'fullscreen_button_stub.dart'
    if (dart.library.js_interop) 'fullscreen_button_web.dart' as platform;

/// A fullscreen toggle button for Flutter Web on desktop-sized screens.
///
/// - Only visible on Web + screen width >= 768px
/// - Uses browser Fullscreen API via dart:js_interop
/// - Toggles icon between fullscreen / fullscreen_exit
/// - Designed for AppBar actions or header rows
class FullscreenButton extends StatefulWidget {
  const FullscreenButton({super.key});

  @override
  State<FullscreenButton> createState() => _FullscreenButtonState();
}

class _FullscreenButtonState extends State<FullscreenButton> {
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _isFullscreen = platform.isFullscreen();
      platform.onFullscreenChange(() {
        if (mounted) {
          setState(() => _isFullscreen = platform.isFullscreen());
        }
      });
    }
  }

  void _toggle() {
    if (!kIsWeb) return;
    if (_isFullscreen) {
      platform.exitFullscreen();
    } else {
      platform.requestFullscreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show on web + wide screens (desktop/tablet)
    if (!kIsWeb) return const SizedBox.shrink();
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: _isFullscreen ? 'Tam Ekrandan Çık' : 'Tam Ekran',
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isFullscreen
                ? AppTheme.cyan.withValues(alpha: 0.15)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            shape: BoxShape.circle,
            border: Border.all(
              color: _isFullscreen
                  ? AppTheme.cyan.withValues(alpha: 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
              key: ValueKey(_isFullscreen),
              color: _isFullscreen
                  ? AppTheme.cyan
                  : (isDark ? Colors.white70 : Colors.black54),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
