import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Ortak Renkler — Deep Space Palette ───────────────────────────────────
  static const Color cyan       = Color(0xFFF78166); // Coral / ana aksan
  static const Color cyanDark   = Color(0xFFCF5C47); // Koyu coral
  static const Color cyanGlow   = Color(0x22F78166); // Coral glow
  static const Color neonPink   = Color(0xFFD2A8FF); // Soft purple
  static const Color neonPurple = Color(0xFFA371F7); // Violet
  static const Color neonGold   = Color(0xFFE3B341); // Amber
  static const Color neonPinkGlow = Color(0x22D2A8FF);

  static const Color success    = Color(0xFF3FB950); // GitHub green
  static const Color error      = Color(0xFFF85149); // GitHub red
  static const Color warning    = Color(0xFFE3B341); // Amber
  static const Color hardColor  = Color(0xFFF85149);
  static const Color mediumColor= Color(0xFFE3B341);
  static const Color easyColor  = Color(0xFF3FB950);

  // ── Dark Renkler — GitHub Dark ────────────────────────────────────────────
  static const Color background     = Color(0xFF0D1117);
  static const Color surface        = Color(0xFF161B22);
  static const Color surfaceVariant = Color(0xFF1C2333);
  static const Color cardBackground = Color(0xFF161B22);
  static const Color textPrimary    = Color(0xFFE6EDF3);
  static const Color textSecondary  = Color(0xFF8B949E);
  static const Color textMuted      = Color(0xFF484F58);
  static const Color divider        = Color(0xFF21262D);
  static const Color border         = Color(0xFF30363D);

  // ── Light Renkler ─────────────────────────────────────────────────────────
  static const Color lightBackground    = Color(0xFFEFF4FF);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightCard          = Color(0xFFF8FAFF);
  static const Color lightTextPrimary   = Color(0xFF0A0F1E);
  static const Color lightTextSecondary = Color(0xFF5A6478);
  static const Color lightDivider       = Color(0xFFE2E8F0);

  // ── Gradyanlar — Deep Space ───────────────────────────────────────────────
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFFF78166), Color(0xFFA371F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient neonPinkGradient = LinearGradient(
    colors: [Color(0xFFD2A8FF), Color(0xFF79C0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldCyanGradient = LinearGradient(
    colors: [Color(0xFFE3B341), Color(0xFFF78166)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glassmorphism yardımcıları ────────────────────────────────────────────

  /// Kart arka plan rengi — isDark parametresine göre uyum sağlar.
  static Color glassBg(bool isDark, {double darkAlpha = 0.07, double lightAlpha = 0.78}) =>
      isDark
          ? Colors.white.withValues(alpha: darkAlpha)
          : Colors.white.withValues(alpha: lightAlpha);

  /// Kart kenarlık rengi — isDark parametresine göre uyum sağlar.
  static Color glassBorder(bool isDark, {double darkAlpha = 0.12, double lightAlpha = 0.07}) =>
      isDark
          ? Colors.white.withValues(alpha: darkAlpha)
          : Colors.black.withValues(alpha: lightAlpha);

  /// Gölge rengi — isDark'a göre uyum sağlar.
  static Color shadowColor(bool isDark) =>
      isDark
          ? Colors.black.withValues(alpha: 0.55)
          : Colors.black.withValues(alpha: 0.08);

  static BoxDecoration glassDecoration({
    double radius = 24,
    Color? glowColor,
    bool isActive = false,
    double backgroundAlpha = 0.05,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: backgroundAlpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isActive && glowColor != null
            ? glowColor.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.08),
        width: isActive ? 1.5 : 0.8,
      ),
      boxShadow: [
        if (isActive && glowColor != null) ...[
          BoxShadow(color: glowColor.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 2),
          BoxShadow(color: glowColor.withValues(alpha: 0.12), blurRadius: 48, spreadRadius: 6),
        ],
        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 14)),
      ],
    );
  }

  static BoxDecoration glassCard({
    Color borderColor = border,
    double borderWidth = 1,
    double radius = 18,
    Color? glowColor,
  }) {
    return BoxDecoration(
      color: cardBackground.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
        if (glowColor != null)
          BoxShadow(color: glowColor.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 4)),
      ],
    );
  }

  static BoxDecoration surfaceCard({double radius = 14, Color? accent}) {
    return BoxDecoration(
      color: surfaceVariant,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accent != null ? accent.withValues(alpha: 0.25) : border,
        width: 1,
      ),
    );
  }

  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.25}) => [
    BoxShadow(color: color.withValues(alpha: intensity), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  // ── DARK TEMA ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: cyan, secondary: neonPurple,
        surface: surface, error: error,
        onPrimary: Colors.white, onSecondary: Colors.white, onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base).copyWith(
        displayLarge:  GoogleFonts.inter(color: textPrimary,   fontWeight: FontWeight.w800, fontSize: 32),
        displayMedium: GoogleFonts.inter(color: textPrimary,   fontWeight: FontWeight.w700, fontSize: 26),
        titleLarge:    GoogleFonts.inter(color: textPrimary,   fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium:   GoogleFonts.inter(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge:     GoogleFonts.inter(color: textPrimary,   fontSize: 16, height: 1.65),
        bodyMedium:    GoogleFonts.inter(color: textSecondary, fontSize: 14, height: 1.55),
        labelLarge:    GoogleFonts.inter(color: cyan,          fontWeight: FontWeight.w700, fontSize: 14),
        labelMedium:   GoogleFonts.inter(color: textSecondary, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background, elevation: 0, scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBackground, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: border, width: 1)),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan, foregroundColor: background,
          elevation: 0, shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyan, side: const BorderSide(color: cyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: cyan, labelColor: cyan, unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.label, dividerColor: Colors.transparent,
      ),
    );
  }

  // ── LIGHT TEMA ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: cyan, secondary: neonPink,
        surface: lightSurface, error: error,
        onPrimary: Colors.white, onSecondary: Colors.white,
        onSurface: lightTextPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base).copyWith(
        displayLarge:  GoogleFonts.inter(color: lightTextPrimary,   fontWeight: FontWeight.w800, fontSize: 32),
        displayMedium: GoogleFonts.inter(color: lightTextPrimary,   fontWeight: FontWeight.w700, fontSize: 26),
        titleLarge:    GoogleFonts.inter(color: lightTextPrimary,   fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium:   GoogleFonts.inter(color: lightTextPrimary,   fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge:     GoogleFonts.inter(color: lightTextPrimary,   fontSize: 16, height: 1.65),
        bodyMedium:    GoogleFonts.inter(color: lightTextSecondary, fontSize: 14, height: 1.55),
        labelLarge:    GoogleFonts.inter(color: cyan,               fontWeight: FontWeight.w700, fontSize: 14),
        labelMedium:   GoogleFonts.inter(color: lightTextSecondary, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground, elevation: 0, scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightSurface, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.07), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan, foregroundColor: Colors.white,
          elevation: 0, shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyan, side: const BorderSide(color: cyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: cyan, labelColor: cyan,
        unselectedLabelColor: lightTextSecondary,
        indicatorSize: TabBarIndicatorSize.label, dividerColor: Colors.transparent,
      ),
    );
  }
}
