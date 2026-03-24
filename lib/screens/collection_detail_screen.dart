import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/collection_model.dart';
import '../models/topic_model.dart';
import '../services/collection_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'flashcard_screen.dart';
import 'case_study_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final CardCollection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final _colService = CollectionService();
  final _dataService = DataService();

  List<Flashcard> _flashcards = [];
  List<ClinicalCase> _cases = [];
  bool _loading = true;

  late CardCollection _col;

  @override
  void initState() {
    super.initState();
    _col = widget.collection;
    _colService.addListener(_rebuild);
    _loadCards();
  }

  @override
  void dispose() {
    _colService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    final updated = _colService.getById(_col.id);
    if (updated != null) {
      _col = updated;
      _loadCards();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadCards() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final cardIds = Set<String>.from(_col.cardIds);
    final flashcards = <Flashcard>[];
    final cases = <ClinicalCase>[];

    try {
      final topics = await _dataService.loadTopics();
      for (final topic in topics) {
        for (final fc in topic.flashcards) {
          if (cardIds.contains(fc.id)) flashcards.add(fc);
        }
        for (final cc in topic.clinicalCases) {
          if (cardIds.contains(cc.id)) cases.add(cc);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _flashcards = flashcards;
        _cases = cases;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _col.color;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    Color.lerp(const Color(0xFF0F172A), color, 0.06)!,
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFEDF3FF),
                    Color.lerp(Colors.white, color, 0.04)!,
                    const Color(0xFFF0F5FF),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(isDark, color),
            if (_loading)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.neonPurple, strokeWidth: 2)))
            else if (_flashcards.isEmpty && _cases.isEmpty)
              _buildEmpty(isDark)
            else
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    if (_flashcards.isNotEmpty) ...[
                      _buildSectionHeader(
                          '🃏 Flashcard\'lar',
                          _flashcards.length,
                          isDark),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _buildFlashcardTile(
                              _flashcards[i], isDark, i),
                          childCount: _flashcards.length,
                        ),
                      ),
                    ],
                    if (_cases.isNotEmpty) ...[
                      _buildSectionHeader(
                          '🩺 Vaka Soruları',
                          _cases.length,
                          isDark),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) =>
                              _buildCaseTile(_cases[i], isDark, i),
                          childCount: _cases.length,
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 20),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: (_flashcards.isNotEmpty || _cases.isNotEmpty)
          ? _buildStudyFab(isDark, color)
          : null,
    );
  }

  Widget _buildHeader(bool isDark, Color color) {
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return SafeArea(
      bottom: false,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
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
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(_col.emoji,
                      style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_col.name,
                          style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      Text(
                          '${_flashcards.length} flashcard · ${_cases.length} vaka',
                          style: GoogleFonts.inter(
                              color: subColor, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(
      String title, int count, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: GoogleFonts.inter(
                      color: AppTheme.neonPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardTile(Flashcard fc, bool isDark, int i) {
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.style_rounded,
                  color: AppTheme.cyan, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fc.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(fc.answer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: AppTheme.cyan, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await _colService.removeCard(_col.id, fc.id);
              },
              child: Icon(Icons.remove_circle_outline_rounded,
                  color: subColor.withValues(alpha: 0.4), size: 18),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: i * 40), duration: 250.ms);
  }

  Widget _buildCaseTile(ClinicalCase cc, bool isDark, int i) {
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medical_services_rounded,
                  color: AppTheme.neonPink, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cc.cleanText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('Doğru cevap: ${cc.correctAnswer}',
                      style: GoogleFonts.inter(
                          color: AppTheme.neonPink, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await _colService.removeCard(_col.id, cc.id);
              },
              child: Icon(Icons.remove_circle_outline_rounded,
                  color: subColor.withValues(alpha: 0.4), size: 18),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: i * 40), duration: 250.ms);
  }

  Widget _buildEmpty(bool isDark) {
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_col.emoji,
                  style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('Bu klasör boş',
                  style: GoogleFonts.inter(
                      color: isDark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Flashcard veya vaka ekranında 📁 ikonuna\nbasarak kart ekleyebilirsin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: subColor, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyFab(bool isDark, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, Color.lerp(color, AppTheme.neonPurple, 0.4)!]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (_flashcards.isNotEmpty) {
              // Flashcard modunda çalış
              final topic = Topic(
                id: _col.id,
                subject: _col.name,
                chapter: '',
                topic: _col.name,
                subTopic: '',
                contentSummary: '',
                flashcards: _flashcards,
                tusSpots: [],
                clinicalCases: _cases,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlashcardScreen(
                    topicFilter: topic,
                    initialMode: FlashcardMode.all,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CaseStudyScreen(
                    topicFilter: Topic(
                      id: _col.id,
                      subject: _col.name,
                      chapter: '',
                      topic: _col.name,
                      subTopic: '',
                      contentSummary: '',
                      flashcards: const [],
                      tusSpots: const [],
                      clinicalCases: _cases,
                    ),
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Çalış',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
