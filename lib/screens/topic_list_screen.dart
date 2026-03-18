import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/topic_model.dart';
import '../services/data_service.dart';
import 'topic_detail_screen.dart';
import '../utils/transitions.dart';

class TopicListScreen extends StatefulWidget {
  /// Null = tüm dersler; değer verilirse o branş filtrelenmiş açılır.
  final String? subjectId;

  const TopicListScreen({super.key, this.subjectId});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  final _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();

  List<Topic> _allTopics = [];
  List<Topic> _filtered = [];
  bool _loading = true;
  String _query = '';

  // Hangi chapter başlıkları açık?
  final Set<String> _expandedChapters = {};

  @override
  void initState() {
    super.initState();
    _loadTopics();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    final topics = await _dataService.loadTopics(
        subjectId: widget.subjectId);
    if (mounted) {
      setState(() {
        _allTopics = topics;
        _filtered = topics;
        _loading = false;
        // Tüm chapter'ları varsayılan açık başlat
        for (final t in topics) {
          _expandedChapters.add(_chapterKey(t));
        }
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _filtered = _allTopics;
      } else {
        _filtered = _allTopics.where((t) {
          return t.subject.toLowerCase().contains(q) ||
              t.chapter.toLowerCase().contains(q) ||
              t.topic.toLowerCase().contains(q) ||
              t.subTopic.toLowerCase().contains(q) ||
              t.contentSummary.toLowerCase().contains(q) ||
              t.flashcards.any((fc) =>
                  fc.question.toLowerCase().contains(q) ||
                  fc.answer.toLowerCase().contains(q)) ||
              t.tusSpots.any((s) => s.toLowerCase().contains(q));
        }).toList();
      }
    });
  }

  String _chapterKey(Topic t) => '${t.subject}__${t.chapter}';

  // Filtrelenmiş topiclerden subject → chapter → [topics] hiyerarşisi oluştur
  Map<String, Map<String, List<Topic>>> get _hierarchy {
    final result = <String, Map<String, List<Topic>>>{};
    for (final t in _filtered) {
      result.putIfAbsent(t.subject, () => {});
      result[t.subject]!.putIfAbsent(t.chapter, () => []);
      result[t.subject]![t.chapter]!.add(t);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Konu Tarayıcı'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _SearchBar(controller: _searchController),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.cyan))
          : _filtered.isEmpty
              ? _buildEmptySearch()
              : ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  children: [
                    for (final subject in _hierarchy.keys)
                      _SubjectSection(
                        subject: subject,
                        chapters: _hierarchy[subject]!,
                        expandedChapters: _expandedChapters,
                        query: _query,
                        onToggleChapter: (key) {
                          setState(() {
                            if (_expandedChapters.contains(key)) {
                              _expandedChapters.remove(key);
                            } else {
                              _expandedChapters.add(key);
                            }
                          });
                        },
                      ),
                  ],
                ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppTheme.textMuted, size: 56),
          const SizedBox(height: 16),
          Text('"$_query" için sonuç bulunamadı',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Farklı bir kelime deneyin',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: controller,
        style:
            const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Konu, kart veya TUS noktası ara...',
          hintStyle:
              TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppTheme.textMuted, size: 20),
          suffixIcon: _ClearButton(),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton();

  @override
  Widget build(BuildContext context) {
    // controller'a doğrudan erişmek için ancestor'dan alıyoruz
    final controller = (context
            .findAncestorWidgetOfExactType<_SearchBar>())
        ?.controller;
    if (controller == null || controller.text.isEmpty) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: controller.clear,
      child: const Icon(Icons.close_rounded,
          color: AppTheme.textMuted, size: 18),
    );
  }
}

class _SubjectSection extends StatelessWidget {
  final String subject;
  final Map<String, List<Topic>> chapters;
  final Set<String> expandedChapters;
  final String query;
  final void Function(String key) onToggleChapter;

  const _SubjectSection({
    required this.subject,
    required this.chapters,
    required this.expandedChapters,
    required this.query,
    required this.onToggleChapter,
  });

  @override
  Widget build(BuildContext context) {
    final totalCards = chapters.values
        .expand((topics) => topics)
        .fold(0, (sum, t) => sum + t.totalFlashcards);
    final totalCases = chapters.values
        .expand((topics) => topics)
        .fold(0, (sum, t) => sum + t.totalCases);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject başlığı
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cyanGlow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.science_rounded,
                    color: AppTheme.cyan, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    Text('$totalCards kart · $totalCases vaka',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Chapter'lar
        ...chapters.entries.map((entry) {
          final chapterKey = '${subject}__${entry.key}';
          final isExpanded = expandedChapters.contains(chapterKey);
          return _ChapterAccordion(
            chapter: entry.key,
            topics: entry.value,
            isExpanded: isExpanded,
            query: query,
            onToggle: () => onToggleChapter(chapterKey),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ChapterAccordion extends StatelessWidget {
  final String chapter;
  final List<Topic> topics;
  final bool isExpanded;
  final String query;
  final VoidCallback onToggle;

  const _ChapterAccordion({
    required this.chapter,
    required this.topics,
    required this.isExpanded,
    required this.query,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final totalCards =
        topics.fold(0, (sum, t) => sum + t.totalFlashcards);
    final totalCases =
        topics.fold(0, (sum, t) => sum + t.totalCases);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Chapter başlık satırı
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.folder_rounded,
                      color: AppTheme.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chapter,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text(
                            '${topics.length} konu · $totalCards kart · $totalCases vaka',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Topic listesi
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: [
                      const Divider(
                          height: 1, color: AppTheme.divider),
                      ...topics.map((t) =>
                          _TopicRow(topic: t, query: query)),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final Topic topic;
  final String query;

  const _TopicRow({required this.topic, required this.query});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        AppRoute.slideUp(TopicDetailScreen(topic: topic)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                color: AppTheme.cyan,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(
                    text: topic.subTopic,
                    query: query,
                    baseStyle: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${topic.totalFlashcards} kart · ${topic.totalCases} vaka',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

/// Arama sorgusuyla eşleşen metni vurgular.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (idx > start) {
        spans.add(
            TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + lowerQuery.length),
        style: baseStyle.copyWith(
            color: AppTheme.cyan,
            backgroundColor: AppTheme.cyanGlow,
            fontWeight: FontWeight.w700),
      ));
      start = idx + lowerQuery.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}
