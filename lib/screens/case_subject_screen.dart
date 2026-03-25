import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/subject_registry.dart';
import '../services/data_service.dart';
import '../utils/transitions.dart';
import 'case_study_screen.dart';

class CaseSubjectScreen extends StatefulWidget {
  const CaseSubjectScreen({super.key});

  @override
  State<CaseSubjectScreen> createState() => _CaseSubjectScreenState();
}

class _CaseSubjectScreenState extends State<CaseSubjectScreen> {
  final _dataService = DataService();
  final Map<String, int> _caseCounts = {};
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
        _caseCounts[module.id] = 0;
        continue;
      }
      final cases = await _dataService.loadCases(subjectId: module.id);
      _caseCounts[module.id] = cases.length;
      total += cases.length;
    }
    _caseCounts['__all__'] = total;
    if (mounted) setState(() => _loading = false);
  }

  List<SubjectModule> get _filteredModules =>
      SubjectRegistry.byCategory(_category).where((m) => m.assetPaths.isNotEmpty).toList();

  int get _categoryTotal => _filteredModules.fold(
      0, (sum, m) => sum + (_caseCounts[m.id] ?? 0));

  Future<void> _openCases(String? subjectId, {List<String>? subjectIds}) async {
    await Navigator.push(
      context,
      AppRoute.slideUp(CaseStudyScreen(
        subjectId: subjectId,
        subjectIds: subjectIds,
      )),
    );
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
          'Vaka Soruları',
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
                // Reuse from flashcard_subject_screen via import
                _CaseCategorySegment(
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

                // Kategorideki Tüm Sorular
                _CaseCard(
                  label: _category == SubjectCategory.temel
                      ? 'Tüm Temel Sorular'
                      : 'Tüm Klinik Sorular',
                  subtitle: _category == SubjectCategory.temel
                      ? 'Temel bilimleri birlikte çöz'
                      : 'Klinik bilimleri birlikte çöz',
                  icon: Icons.quiz_rounded,
                  color: const Color(0xFF79C0FF),
                  caseCount: _categoryTotal,
                  isDark: isDark,
                  onTap: () {
                    final ids = _filteredModules
                        .where((m) => m.assetPaths.isNotEmpty)
                        .map((m) => m.id)
                        .toList();
                    if (ids.isEmpty) return;
                    _openCases(null, subjectIds: ids);
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
                  final count = _caseCounts[module.id] ?? 0;
                  final hasContent = module.assetPaths.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Opacity(
                      opacity: hasContent ? 1.0 : 0.45,
                      child: _CaseCard(
                        label: module.name,
                        subtitle: hasContent ? module.shortLabel : 'Yakında',
                        icon: module.icon,
                        color: module.color,
                        caseCount: count,
                        isDark: isDark,
                        onTap: hasContent ? () => _openCases(module.id) : () {},
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

/// Temel / Klinik segmented control for cases
class _CaseCategorySegment extends StatelessWidget {
  final SubjectCategory selected;
  final bool isDark;
  final ValueChanged<SubjectCategory> onChanged;

  const _CaseCategorySegment({
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

class _CaseCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int caseCount;
  final bool isDark;
  final VoidCallback onTap;

  const _CaseCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.caseCount,
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
                      '$caseCount',
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'soru',
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
    );
  }
}
