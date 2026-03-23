import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/subject_registry.dart';
import '../services/data_service.dart';

/// Tek bir spot bilgi verisi
class _SpotItem {
  final String text;
  final String subject;
  final String chapter;
  final String topicName;
  final Color color;

  const _SpotItem({
    required this.text,
    required this.subject,
    required this.chapter,
    required this.topicName,
    required this.color,
  });
}

/// TikTok/Reels tarzı dikey kaydırmalı Spot Bilgiler Ekranı.
/// Mevcut JSON'lardaki tus_spots alanlarını kullanır.
class SpotsScreen extends StatefulWidget {
  const SpotsScreen({super.key});

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  final _dataService = DataService();
  List<_SpotItem> _allSpots = [];
  List<_SpotItem> _spots = [];
  bool _loading = true;
  String? _selectedSubjectId; // null = tümü
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSpots() async {
    final spots = <_SpotItem>[];

    for (final module in SubjectRegistry.activeModules) {
      final topics = await _dataService.loadTopics(subjectId: module.id);
      for (final topic in topics) {
        for (final spot in topic.tusSpots) {
          if (spot.trim().isNotEmpty) {
            spots.add(_SpotItem(
              text: spot,
              subject: topic.subject,
              chapter: topic.chapter,
              topicName: topic.topic,
              color: module.color,
            ));
          }
        }
      }
    }

    spots.shuffle(Random());

    if (mounted) {
      setState(() {
        _allSpots = spots;
        _spots = spots;
        _loading = false;
      });
    }
  }

  void _filterBySubject(String? subjectId) {
    setState(() {
      _selectedSubjectId = subjectId;
      if (subjectId == null) {
        _spots = List.from(_allSpots);
      } else {
        final module = SubjectRegistry.findById(subjectId);
        if (module != null) {
          _spots = _allSpots.where((s) => s.subject == module.name).toList();
        }
      }
      _currentPage = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _shuffle() {
    setState(() {
      _spots.shuffle(Random());
      _currentPage = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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
        title: Text('Spot Bilgiler',
          style: GoogleFonts.inter(color: textColor, fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          if (!_loading && _spots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '${_currentPage + 1}/${_spots.length}',
                  style: GoogleFonts.inter(color: subColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.shuffle_rounded, color: AppTheme.cyan, size: 22),
            tooltip: 'Karıştır',
            onPressed: _shuffle,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2.5))
          : Column(
              children: [
                // ── Konu Filtre Chip Bar ──
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _filterChip('Tümü', null, isDark),
                      ...SubjectRegistry.activeModules.map((m) =>
                          _filterChip(m.shortLabel, m.id, isDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Spot Kartları (Dikey Kaydırma) ──
                Expanded(
                  child: _spots.isEmpty
                      ? Center(
                          child: Text('Bu kategoride spot bilgi yok',
                            style: GoogleFonts.inter(color: subColor, fontSize: 14)),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _spots.length,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          itemBuilder: (_, index) =>
                              _SpotCard(spot: _spots[index], isDark: isDark),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String label, String? subjectId, bool isDark) {
    final selected = _selectedSubjectId == subjectId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _filterBySubject(subjectId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.cyan.withValues(alpha: 0.15)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppTheme.cyan.withValues(alpha: 0.4)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppTheme.cyan
                  : (isDark ? Colors.white60 : Colors.black45),
            )),
        ),
      ),
    );
  }
}

/// Tek bir spot kartı — tam ekran, glassmorphism
class _SpotCard extends StatelessWidget {
  final _SpotItem spot;
  final bool isDark;

  const _SpotCard({required this.spot, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? spot.color.withValues(alpha: 0.06)
                  : spot.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: spot.color.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: spot.color.withValues(alpha: 0.08),
                  blurRadius: 30, spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Konu Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: spot.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: spot.color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            color: spot.color, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            spot.topicName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: spot.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Spot Metin
                  Expanded(
                    child: Center(
                      child: Text(
                        spot.text,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.6,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Alt bilgi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kaynak
                      Flexible(
                        child: Text(
                          '${spot.subject} — ${spot.chapter}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: subColor, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                      // Kopyala butonu
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: spot.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kopyalandı!',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppTheme.cyan,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.copy_rounded, color: subColor, size: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Kaydırma ipucu
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: subColor.withValues(alpha: 0.4), size: 24),
                        Text('Kaydır',
                          style: GoogleFonts.inter(
                            color: subColor.withValues(alpha: 0.3),
                            fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
