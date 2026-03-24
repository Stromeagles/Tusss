import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Ortak Renkler — Deep Space Palette ───────────────────────────────────
  static const Color cyan       = Color(0xFF00E5FF); // Vibrant Cyan / ana aksan
  static const Color cyanDark   = Color(0xFF00B8D4); // Koyu cyan
  static const Color cyanGlow   = Color(0x2200E5FF); // Cyan glow
  static const Color neonPink   = Color(0xFFE0B0FF); // Soft lavender
  static const Color neonPurple = Color(0xFFA371F7); // Violet
  static const Color neonGold   = Color(0xFFE3B341); // Amber
  static const Color neonPinkGlow = Color(0x22D2A8FF);

  static const Color success    = Color(0xFF3FB950); // GitHub green
  static const Color error      = Color(0xFFF85149); // GitHub red
  static const Color warning    = Color(0xFFE3B341); // Amber
  static const Color hardColor  = Color(0xFFF85149);
  static const Color mediumColor= Color(0xFFE3B341);
  static const Color easyColor  = Color(0xFF3FB950);

  // ── Dark Renkler — GitHub Slate Dark ─────────────────────────────────────
  static const Color background     = Color(0xFF0D1117);
  static const Color surface        = Color(0xFF161B22);
  static const Color surfaceVariant = Color(0xFF1C2128);
  static const Color cardBackground = Color(0xFF161B22);
  static const Color textPrimary    = Color(0xFFF8FAFC);
  static const Color textSecondary  = Color(0xFF94A3B8);
  static const Color textMuted      = Color(0xFF64748B);
  static const Color divider        = Color(0xFF21262D);
  static const Color border         = Color(0xFF30363D);

  // ── Light Renkler ─────────────────────────────────────────────────────────
  static const Color lightBackground    = Color(0xFFEFF4FF);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightCard          = Color(0xFFF8FAFF);
  static const Color lightTextPrimary   = Color(0xFF0A0F1E);
  static const Color lightTextSecondary = Color(0xFF5A6478);
  static const Color lightDivider       = Color(0xFFE2E8F0);

  // ── Soft / Sepya Renkler — Göz Korumalı ─────────────────────────────────
  static const Color softBackground     = Color(0xFFF5F0E8);
  static const Color softSurface        = Color(0xFFFAF7F2);
  static const Color softCard           = Color(0xFFF0EBE3);
  static const Color softTextPrimary    = Color(0xFF2C2C2C);
  static const Color softTextSecondary  = Color(0xFF6B6358);
  static const Color softDivider        = Color(0xFFE0D9CE);
  static const Color softBorder         = Color(0xFFD4CCC0);
  static const Color softAccent         = Color(0xFFD4845A); // Warm coral for soft

  // ── Gradyanlar — Deep Space ───────────────────────────────────────────────
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFFA371F7)],
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
            ? glowColor.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.1),
        width: isActive ? 1.5 : 1.0,
      ),
      boxShadow: [
        // Layered shadow: yumuşak dış gölge + keskin iç derinlik
        if (isActive && glowColor != null) ...[
          BoxShadow(color: glowColor.withValues(alpha: 0.25), blurRadius: 28, spreadRadius: 0),
          BoxShadow(color: glowColor.withValues(alpha: 0.08), blurRadius: 56, spreadRadius: 4),
        ],
        BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10)),
        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 48, offset: const Offset(0, 20)),
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
      color: cardBackground.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glowColor != null
            ? glowColor.withValues(alpha: 0.18)
            : borderColor,
        width: borderWidth,
      ),
      boxShadow: [
        // Layered: yumuşak ana gölge + hafif ambient
        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 40, offset: const Offset(0, 16)),
        if (glowColor != null)
          BoxShadow(color: glowColor.withValues(alpha: 0.10), blurRadius: 32, spreadRadius: -2, offset: const Offset(0, 4)),
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
      colorScheme: ColorScheme.light(
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
      tabBarTheme: TabBarThemeData(
        indicatorColor: cyan, labelColor: cyan,
        unselectedLabelColor: lightTextSecondary,
        indicatorSize: TabBarIndicatorSize.label, dividerColor: Colors.transparent,
      ),
    );
  }

  // ── SOFT / SEPYA TEMA — Göz Korumalı ────────────────────────────────────
  static ThemeData get softTheme {
    final base = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: softBackground,
      colorScheme: ColorScheme.light(
        primary: softAccent, secondary: Color(0xFF8B7355),
        surface: softSurface, error: Color(0xFFC44D3E),
        onPrimary: Colors.white, onSecondary: Colors.white,
        onSurface: softTextPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base).copyWith(
        displayLarge:  GoogleFonts.inter(color: softTextPrimary,   fontWeight: FontWeight.w800, fontSize: 32),
        displayMedium: GoogleFonts.inter(color: softTextPrimary,   fontWeight: FontWeight.w700, fontSize: 26),
        titleLarge:    GoogleFonts.inter(color: softTextPrimary,   fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium:   GoogleFonts.inter(color: softTextPrimary,   fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge:     GoogleFonts.inter(color: softTextPrimary,   fontSize: 16, height: 1.65),
        bodyMedium:    GoogleFonts.inter(color: softTextSecondary, fontSize: 14, height: 1.55),
        labelLarge:    GoogleFonts.inter(color: softAccent,        fontWeight: FontWeight.w700, fontSize: 14),
        labelMedium:   GoogleFonts.inter(color: softTextSecondary, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: softBackground, elevation: 0, scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: softTextPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        iconTheme: const IconThemeData(color: softTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: softSurface, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: softBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: softDivider, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softAccent, foregroundColor: Colors.white,
          elevation: 0, shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: softAccent, side: const BorderSide(color: softAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: softAccent, labelColor: softAccent,
        unselectedLabelColor: softTextSecondary,
        indicatorSize: TabBarIndicatorSize.label, dividerColor: Colors.transparent,
      ),
    );
  }
}
