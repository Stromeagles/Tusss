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

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    int total = 0;
    for (final module in SubjectRegistry.modules) {
      final cases = await _dataService.loadCases(subjectId: module.id);
      _caseCounts[module.id] = cases.length;
      total += cases.length;
    }
    _caseCounts['__all__'] = total;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openCases(String? subjectId) async {
    await Navigator.push(
      context,
      AppRoute.slideUp(CaseStudyScreen(subjectId: subjectId)),
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

                // Sorular
                _CaseCard(
                  label: 'Sorular',
                  subtitle: 'Bütün branşları birlikte çöz',
                  icon: Icons.quiz_rounded,
                  color: const Color(0xFF79C0FF),
                  caseCount: _caseCounts['__all__'] ?? 0,
                  isDark: isDark,
                  onTap: () => _openCases(null),
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
                      child: _CaseCard(
                        label: module.name,
                        subtitle: module.shortLabel,
                        icon: module.icon,
                        color: module.color,
                        caseCount: _caseCounts[module.id] ?? 0,
                        isDark: isDark,
                        onTap: () => _openCases(module.id),
                      ),
                    )),
              ],
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
        ),
      ),
    );
  }
}
