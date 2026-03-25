import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/subject_registry.dart';
import '../models/topic_model.dart';
import '../services/data_service.dart';
import '../utils/transitions.dart';
import 'hierarchy_screens.dart';

class SubjectBrowserScreen extends StatefulWidget {
  const SubjectBrowserScreen({super.key});

  @override
  State<SubjectBrowserScreen> createState() => _SubjectBrowserScreenState();
}

class _SubjectBrowserScreenState extends State<SubjectBrowserScreen> {
  final _dataService = DataService();
  final Map<String, int> _topicCounts = {};
  final Map<String, int> _cardCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    for (final module in SubjectRegistry.modules) {
      final topics = await _dataService.loadTopics(subjectId: module.id);
      _topicCounts[module.id] = topics.length;
      _cardCounts[module.id] = topics.fold(0, (s, t) => s + t.totalFlashcards + t.totalCases);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openSubject(SubjectModule module) async {
    final topics = await _dataService.loadTopics(subjectId: module.id);
    if (!mounted) return;

    final chapters = <String, List<Topic>>{};
    for (final t in topics) {
      chapters.putIfAbsent(t.chapter, () => []).add(t);
    }

    Navigator.push(
      context,
      AppRoute.slideRight(
        ChapterListScreen(
          subjectName: module.name,
          chapters: chapters,
          accentColor: module.color,
        ),
      ),
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
          'Konu Tarayıcı',
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
                ...SubjectRegistry.modules.map((module) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SubjectTile(
                        module: module,
                        topicCount: _topicCounts[module.id] ?? 0,
                        cardCount: _cardCounts[module.id] ?? 0,
                        isDark: isDark,
                        onTap: () => _openSubject(module),
                      ),
                    )),
              ],
            ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final SubjectModule module;
  final int topicCount;
  final int cardCount;
  final bool isDark;
  final VoidCallback onTap;

  const _SubjectTile({
    required this.module,
    required this.topicCount,
    required this.cardCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glassBorder = isDark
        ? module.color.withValues(alpha: 0.25)
        : module.color.withValues(alpha: 0.30);
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: glassBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: module.color.withValues(alpha: 0.10),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    module.color.withValues(alpha: 0.25),
                    module.color.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(module.icon, color: module.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$topicCount konu  ·  $cardCount içerik',
                    style: GoogleFonts.inter(
                      color: subColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subColor, size: 22),
          ],
        ),
      ),
    );
  }
}
