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
  SubjectCategory _category = SubjectCategory.temel;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    int total = 0;
    for (final module in SubjectRegistry.modules) {
      if (module.assetPaths.isEmpty) {
        _cardCounts[module.id] = 0;
        continue;
      }
      final cards = await _dataService.loadFlashcards(subjectId: module.id);
      _cardCounts[module.id] = cards.length;
      total += cards.length;
    }
    _cardCounts['__all__'] = total;
    if (mounted) setState(() => _loading = false);
  }

  List<SubjectModule> get _filteredModules =>
      SubjectRegistry.byCategory(_category).where((m) => m.assetPaths.isNotEmpty).toList();

  int get _categoryTotal => _filteredModules.fold(
      0, (sum, m) => sum + (_cardCounts[m.id] ?? 0));

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
                // ── Temel / Klinik Segmented Control ──
                _CategorySegment(
                  selected: _category,
                  isDark: isDark,
                  onChanged: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 20),

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

                // Kategorideki Tüm Kartlar
                _SubjectCard(
                  label: _category == SubjectCategory.temel
                      ? 'Tüm Temel Kartlar'
                      : 'Tüm Klinik Kartlar',
                  subtitle: _category == SubjectCategory.temel
                      ? 'Temel bilimleri birlikte çalış'
                      : 'Klinik bilimleri birlikte çalış',
                  icon: Icons.auto_awesome_motion_rounded,
                  color: AppTheme.cyan,
                  cardCount: _categoryTotal,
                  isDark: isDark,
                  onTap: () {
                    final ids = _filteredModules
                        .where((m) => m.assetPaths.isNotEmpty)
                        .map((m) => m.id)
                        .toList();
                    if (ids.isEmpty) return;
                    _openFlashcards(null, subjectIds: ids);
                  },
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

                ..._filteredModules.map((module) {
                  final count = _cardCounts[module.id] ?? 0;
                  final hasContent = module.assetPaths.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Opacity(
                      opacity: hasContent ? 1.0 : 0.45,
                      child: _SubjectCard(
                        label: module.name,
                        subtitle: hasContent ? module.shortLabel : 'Yakında',
                        icon: module.icon,
                        color: module.color,
                        cardCount: count,
                        isDark: isDark,
                        onTap: hasContent ? () => _openFlashcards(module.id) : () {},
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Future<void> _openFlashcards(String? subjectId, {List<String>? subjectIds}) async {
    await Navigator.push(
      context,
      AppRoute.slideUp(FlashcardScreen(
        subjectId: subjectId,
        subjectIds: subjectIds,
        isPreview: true,
      )),
    );
  }
}

/// Temel / Klinik segmented control — reusable widget
class _CategorySegment extends StatelessWidget {
  final SubjectCategory selected;
  final bool isDark;
  final ValueChanged<SubjectCategory> onChanged;

  const _CategorySegment({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: SubjectCategory.values.map((cat) {
          final isSelected = cat == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.cyan.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.cyan.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat == SubjectCategory.temel
                          ? Icons.science_outlined
                          : Icons.local_hospital_outlined,
                      size: 18,
                      color: isSelected
                          ? AppTheme.cyan
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat == SubjectCategory.temel
                          ? 'Temel Bilimler'
                          : 'Klinik Bilimler',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.cyan
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
