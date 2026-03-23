import 'package:flutter/material.dart';

/// Üç farklı tema modu: Dark, Light, Soft (Göz Korumalı Sepya)
enum AppThemeMode { dark, light, soft }

/// Global tema durumu — Provider gerektirmez.
/// Herhangi bir widget'tan [ThemeService.setMode()] ile anlık geçiş yapar.
class ThemeService {
  ThemeService._();

  static final ValueNotifier<AppThemeMode> mode =
      ValueNotifier(AppThemeMode.dark);

  /// Backward compat — eski toggle dark↔light, artık cycle yapar
  static void toggle() {
    switch (mode.value) {
      case AppThemeMode.dark:
        mode.value = AppThemeMode.light;
      case AppThemeMode.light:
        mode.value = AppThemeMode.soft;
      case AppThemeMode.soft:
        mode.value = AppThemeMode.dark;
    }
  }

  static void setMode(AppThemeMode m) => mode.value = m;

  static bool get isDark => mode.value == AppThemeMode.dark;
  static bool get isLight => mode.value == AppThemeMode.light;
  static bool get isSoft => mode.value == AppThemeMode.soft;

  /// Flutter ThemeMode karşılığı (soft → light olarak map'lenir)
  static ThemeMode get flutterThemeMode {
    switch (mode.value) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
      case AppThemeMode.soft:
        return ThemeMode.light;
    }
  }
}
