import 'package:flutter/material.dart';

/// Global tema durumu — PackageManager veya Provider gerektirmez.
/// Herhangi bir widget'tan [ThemeService.toggle()] çağrısıyla anlık geçiş yapar.
class ThemeService {
  ThemeService._();

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.dark);

  static void toggle() {
    mode.value =
        mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  static bool get isDark => mode.value == ThemeMode.dark;
}
