import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/topic_model.dart';
import '../services/spaced_repetition_service.dart';
import '../widgets/difficulty_badge_widget.dart';
import 'flashcard_screen.dart';
import 'case_study_screen.dart';
import '../utils/transitions.dart';

class TopicDetailScreen extends StatefulWidget {
  final Topic topic;
  const TopicDetailScreen({super.key, required this.topic});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _srService = SpacedRepetitionService();

  Map<String, int> _dueStatus = {}; // cardId → interval
  bool _srLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSRData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSRData() async {
    final status = <String, int>{};
    for (final fc in widget.topic.flashcards) {
      final data = await _srService.getCardData(fc.id);
      status[fc.id] = data.interval;
    }
    if (mounted) {
      setState(() {
        _dueStatus = status;
        _srLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(topic.subTopic,
            style: const TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cyan,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.cyan,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Özet'),
            Tab(text: 'Kartlar'),
            Tab(text: 'Vakalar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SummaryTab(topic: topic),
          _FlashcardsTab(
            topic: topic,
            dueStatus: _dueStatus,
            srLoaded: _srLoaded,
          ),
          _CasesTab(topic: topic),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        AppRoute.slideUp(FlashcardScreen(topicFilter: widget.topic, isPreview: true)),
      ),
      backgroundColor: AppTheme.cyan,
      foregroundColor: AppTheme.background,
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('Bu Konuyu Çalış',
          style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

// ── Tab 1: Özet ───────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final Topic topic;
  const _SummaryTab({required this.topic});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _Breadcrumb(topic: topic),
          const SizedBox(height: 20),

          // İçerik özeti
          _SectionCard(
            icon: Icons.summarize_rounded,
            color: AppTheme.cyan,
            title: 'Konu Özeti',
            child: Text(topic.contentSummary,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    height: 1.65)),
          ),
          const SizedBox(height: 16),

          // TUS noktaları
          if (topic.tusSpots.isNotEmpty) ...[
            _SectionCard(
              icon: Icons.star_rounded,
              color: AppTheme.warning,
              title: 'TUS Noktaları',
              child: Column(
                children: topic.tusSpots
                    .map((spot) => _TusSpotRow(text: spot))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final Topic topic;
  const _Breadcrumb({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(topic.subject,
            style: const TextStyle(
                color: AppTheme.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textMuted, size: 14),
        Text(topic.chapter,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textMuted, size: 14),
        Text(topic.topic,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _TusSpotRow extends StatelessWidget {
  final String text;
  const _TusSpotRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, color: AppTheme.warning, size: 6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.55)),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Flash Kartlar ──────────────────────────────────────────────────────

class _FlashcardsTab extends StatelessWidget {
  final Topic topic;
  final Map<String, int> dueStatus;
  final bool srLoaded;

  const _FlashcardsTab({
    required this.topic,
    required this.dueStatus,
    required this.srLoaded,
  });

  @override
  Widget build(BuildContext context) {
    if (topic.flashcards.isEmpty) {
      return const Center(
        child: Text('Bu konuda kart yok',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: topic.flashcards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final fc = topic.flashcards[i];
        final interval = dueStatus[fc.id] ?? 0;
        final isDue = interval == 0;
        return _FlashcardPreviewTile(
          flashcard: fc,
          isDue: isDue,
          intervalDays: interval,
          srLoaded: srLoaded,
        );
      },
    );
  }
}

class _FlashcardPreviewTile extends StatefulWidget {
  final Flashcard flashcard;
  final bool isDue;
  final int intervalDays;
  final bool srLoaded;

  const _FlashcardPreviewTile({
    required this.flashcard,
    required this.isDue,
    required this.intervalDays,
    required this.srLoaded,
  });

  @override
  State<_FlashcardPreviewTile> createState() =>
      _FlashcardPreviewTileState();
}

class _FlashcardPreviewTileState extends State<_FlashcardPreviewTile> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final fc = widget.flashcard;
    return GestureDetector(
      onTap: () => setState(() => _showAnswer = !_showAnswer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isDue
                ? AppTheme.cyan.withOpacity(0.4)
                : AppTheme.divider,
            width: widget.isDue ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DifficultyBadge(difficulty: fc.difficulty),
                const Spacer(),
                if (widget.srLoaded)
                  _SRBadge(
                      isDue: widget.isDue,
                      intervalDays: widget.intervalDays),
              ],
            ),
            const SizedBox(height: 12),
            Text(fc.question,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5)),
            if (_showAnswer) ...[
              const SizedBox(height: 12),
              const Divider(color: AppTheme.divider, height: 1),
              const SizedBox(height: 12),
              Text(fc.answer,
                  style: const TextStyle(
                      color: AppTheme.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                ...fc.tags.map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.cyanGlow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                color: AppTheme.cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    )),
                const Spacer(),
                Text(_showAnswer ? 'Gizle' : 'Cevabı gör',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _SRBadge extends StatelessWidget {
  final bool isDue;
  final int intervalDays;

  const _SRBadge({required this.isDue, required this.intervalDays});

  @override
  Widget build(BuildContext context) {
    if (isDue) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.cyan.withOpacity(0.4), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_rounded,
                color: AppTheme.cyan, size: 11),
            SizedBox(width: 4),
            Text('Tekrar zamanı',
                style: TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Text('$intervalDays gün sonra',
        style: const TextStyle(
            color: AppTheme.textMuted, fontSize: 11));
  }
}

// ── Tab 3: Vakalar ────────────────────────────────────────────────────────────

class _CasesTab extends StatelessWidget {
  final Topic topic;
  const _CasesTab({required this.topic});

  @override
  Widget build(BuildContext context) {
    if (topic.clinicalCases.isEmpty) {
      return const Center(
        child: Text('Bu konuda vaka yok',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: topic.clinicalCases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final cc = topic.clinicalCases[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('VAKA ${1}',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(cc.caseText,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.55)),
              const SizedBox(height: 10),
              Text('Doğru cevap: ${cc.correctAnswer}',
                  style: const TextStyle(
                      color: AppTheme.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  AppRoute.slideUp(CaseStudyScreen(topicFilter: topic, isPreview: true)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Bu Vakayı Çöz'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Ortak bileşen ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
