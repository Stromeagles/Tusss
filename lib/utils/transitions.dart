import 'package:flutter/material.dart';

/// Uygulamada kullanılan özel sayfa geçişleri.
class AppRoute {
  AppRoute._();

  /// Slide-up + fade — modal/detay ekranları için
  static Route<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      opaque: false,   // fade sırasında alttaki ekran render edilsin (siyah kalmasın)
      pageBuilder: (_, animation, __) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
        );
        // Önceki ekranı hafifçe scale-down yap
        final prevScale = Tween<double>(begin: 1.0, end: 0.96).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInOut,
          ),
        );
        return ScaleTransition(
          scale: prevScale,
          child: SlideTransition(
            position: slide,
            child: FadeTransition(opacity: fade, child: child),
          ),
        );
      },
    );
  }

  /// Slide-right + fade — yatay navigasyon için
  static Route<T> slideRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      opaque: false,
      pageBuilder: (_, animation, __) => page,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  /// Sadece fade — overlay/dialog benzeri geçişler için
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      opaque: false,
      pageBuilder: (_, animation, __) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }
}
