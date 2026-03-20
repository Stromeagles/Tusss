import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/subject_registry.dart';
import '../services/data_service.dart';
import '../utils/transitions.dart';
import 'flashcard_screen.dart';

class FlashcardSubjectScreen extends StatefulWidget {
  const FlashcardSubjectScreen({super.key});

  @override
  State<FlashcardSubjectScreen> createState() => _FlashcardSubjectScreenState();
}

class _FlashcardSubjectScreenState extends State<FlashcardSubjectScreen> {
  final _dataService = DataService();
  final Map<String, int> _cardCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    int total = 0;
    for (final module in SubjectRegistry.modules) {
      final cards = await _dataService.loadFlashcards(subjectId: module.id);
      _cardCounts[module.id] = cards.length;
      total += cards.length;
    }
    _cardCounts['__all__'] = total;
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Flashcard Çalışması',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Ders Seç',
                  style: GoogleFonts.inter(
                    color: subColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Tüm Kartlar
                _SubjectCard(
                  label: 'Tüm Kartlar',
                  subtitle: 'Bütün branşları birlikte çalış',
                  icon: Icons.auto_awesome_motion_rounded,
                  color: AppTheme.cyan,
                  cardCount: _cardCounts['__all__'] ?? 0,
                  isDark: isDark,
                  onTap: () => _openFlashcards(null),
                ),
                const SizedBox(height: 12),

                Text(
                  'Branşa Göre',
                  style: GoogleFonts.inter(
                    color: subColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                ...SubjectRegistry.modules.map((module) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SubjectCard(
                        label: module.name,
                        subtitle: module.shortLabel,
                        icon: module.icon,
                        color: module.color,
                        cardCount: _cardCounts[module.id] ?? 0,
                        isDark: isDark,
                        onTap: () => _openFlashcards(module.id),
                      ),
                    )),
              ],
            ),
    );
  }

  Future<void> _openFlashcards(String? subjectId) async {
    await Navigator.push(
      context,
      AppRoute.slideUp(FlashcardScreen(subjectId: subjectId, isPreview: true)),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int cardCount;
  final bool isDark;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.cardCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glassBg = isDark
        ? color.withValues(alpha: 0.07)
        : color.withValues(alpha: 0.08);
    final glassBorder = isDark
        ? color.withValues(alpha: 0.25)
        : color.withValues(alpha: 0.30);
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.10),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: color.withValues(alpha: 0.35), width: 1.2),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$cardCount',
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'kart',
                      style: GoogleFonts.inter(
                        color: subColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: color.withValues(alpha: 0.6), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
