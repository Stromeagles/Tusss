import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mock_exam_model.dart';
import '../models/subject_registry.dart';
import '../theme/app_theme.dart';
import 'mock_exam_screen.dart';

class MockExamSetupScreen extends StatefulWidget {
  const MockExamSetupScreen({super.key});

  @override
  State<MockExamSetupScreen> createState() => _MockExamSetupScreenState();
}

class _MockExamSetupScreenState extends State<MockExamSetupScreen> {
  int _questionCount = 20;
  final Set<String> _selectedSubjects = {'mikrobiyoloji', 'patoloji'};
  bool _instantFeedback = false;

  static const _questionOptions = [10, 20, 50, 100];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF0A1628), Color(0xFF0F172A)]
                : const [Color(0xFFEDF3FF), Color(0xFFE8F0FF), Color(0xFFF0F5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionCountSection(isDark),
                      const SizedBox(height: 28),
                      _buildSubjectSection(isDark),
                      const SizedBox(height: 28),
                      _buildOptionsSection(isDark),
                      const SizedBox(height: 28),
                      _buildSummaryCard(isDark),
                      const SizedBox(height: 24),
                      _buildStartButton(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deneme Sınavı',
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                Text('TUS koşullarında sınav hazırla',
                    style: GoogleFonts.inter(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: GoogleFonts.inter(
              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildQuestionCountSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Soru Sayısı', isDark),
        Row(
          children: _questionOptions.map((count) {
            final isSelected = count == _questionCount;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _questionCount = count),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.cyan.withValues(alpha: isDark ? 0.20 : 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white.withValues(alpha: 0.7)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.cyan.withValues(alpha: 0.5)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: AppTheme.cyan.withValues(alpha: 0.2),
                                blurRadius: 12)
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text('$count',
                          style: GoogleFonts.inter(
                              color: isSelected
                                  ? AppTheme.cyan
                                  : (isDark
                                      ? AppTheme.textPrimary
                                      : AppTheme.lightTextPrimary),
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      Text('soru',
                          style: GoogleFonts.inter(
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 10)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildSubjectSection(bool isDark) {
    final temel = SubjectRegistry.modules
        .where((m) => m.category == SubjectCategory.temel)
        .toList();
    final klinik = SubjectRegistry.modules
        .where((m) => m.category == SubjectCategory.klinik)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Branş Seçimi', isDark)),
            GestureDetector(
              onTap: () => setState(() {
                if (_selectedSubjects.length ==
                    SubjectRegistry.modules.length) {
                  _selectedSubjects.clear();
                } else {
                  _selectedSubjects.addAll(
                      SubjectRegistry.modules.map((m) => m.id));
                }
              }),
              child: Text(
                _selectedSubjects.length == SubjectRegistry.modules.length
                    ? 'Tümünü Kaldır'
                    : 'Tümünü Seç',
                style: GoogleFonts.inter(
                    color: AppTheme.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        _buildCategoryRow('Temel Bilimler', temel, isDark),
        const SizedBox(height: 14),
        _buildCategoryRow('Klinik Bilimler', klinik, isDark),
      ],
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildCategoryRow(
      String title, List<SubjectModule> modules, bool isDark) {
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                color: subColor, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modules.map((m) {
            final isSelected = _selectedSubjects.contains(m.id);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedSubjects.remove(m.id);
                } else {
                  _selectedSubjects.add(m.id);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? m.color.withValues(alpha: isDark ? 0.18 : 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? m.color.withValues(alpha: 0.45)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: m.color.withValues(alpha: 0.18),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.icon,
                        color: isSelected
                            ? m.color
                            : (isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary),
                        size: 14),
                    const SizedBox(width: 6),
                    Text(m.shortLabel,
                        style: GoogleFonts.inter(
                            color: isSelected
                                ? m.color
                                : (isDark
                                    ? AppTheme.textPrimary
                                    : AppTheme.lightTextPrimary),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(bool isDark) {
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Seçenekler', isDark),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
          child: SwitchListTile(
            title: Text('Anında Geri Bildirim',
                style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Her soruda doğru/yanlış görülür',
              style: GoogleFonts.inter(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 11),
            ),
            value: _instantFeedback,
            onChanged: (v) => setState(() => _instantFeedback = v),
            activeThumbColor: AppTheme.cyan,
            activeTrackColor: AppTheme.cyan.withValues(alpha: 0.4),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildSummaryCard(bool isDark) {
    final timeMin = (_questionCount * 1.5).ceil();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppTheme.cyan.withValues(alpha: 0.15),
                  AppTheme.neonPurple.withValues(alpha: 0.12),
                ]
              : [
                  AppTheme.cyan.withValues(alpha: 0.10),
                  AppTheme.neonPurple.withValues(alpha: 0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.cyan.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          _buildStatItem(
              '⏱️', '$timeMin dk', 'Süre', isDark),
          _buildDivider(isDark),
          _buildStatItem(
              '📝', '$_questionCount', 'Soru', isDark),
          _buildDivider(isDark),
          _buildStatItem(
              '🎯',
              '${_selectedSubjects.length}',
              'Branş',
              isDark),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1));
  }

  Widget _buildStatItem(
      String emoji, String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  color:
                      isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: GoogleFonts.inter(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) => Container(
        width: 1,
        height: 50,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
      );

  Widget _buildStartButton(bool isDark) {
    final canStart = _selectedSubjects.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: canStart ? _startExam : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: canStart
                ? const LinearGradient(
                    colors: [AppTheme.cyan, Color(0xFFFF6B8A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canStart ? null : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: canStart
                ? [
                    BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                canStart ? 'Sınavı Başlat' : 'Branş Seç',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  void _startExam() {
    if (_selectedSubjects.isEmpty) return;
    final config = MockExamConfig.create(
      questionCount: _questionCount,
      subjectIds: _selectedSubjects.toList(),
      showInstantFeedback: _instantFeedback,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockExamScreen(config: config),
      ),
    );
  }
}
