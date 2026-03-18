import 'package:flutter/material.dart';
import '../models/topic_model.dart';
import '../theme/app_theme.dart';
import 'topic_detail_screen.dart';
import '../utils/transitions.dart';

class ChapterListScreen extends StatelessWidget {
  final String subjectName;
  final Map<String, List<Topic>> chapters;
  final Color accentColor;

  const ChapterListScreen({
    super.key,
    required this.subjectName,
    required this.chapters,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(subjectName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapterName = chapters.keys.elementAt(index);
          final topics = chapters[chapterName]!;
          final totalCards = topics.fold(0, (sum, t) => sum + t.totalFlashcards);
          final totalCases = topics.fold(0, (sum, t) => sum + t.totalCases);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_rounded, color: accentColor, size: 24),
              ),
              title: Text(
                chapterName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${topics.length} ana konu · $totalCards kart · $totalCases vaka',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              onTap: () {
                Navigator.push(
                  context,
                  AppRoute.slideRight(
                    SubTopicListScreen(
                      chapterName: chapterName,
                      topics: topics,
                      accentColor: accentColor,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SubTopicListScreen extends StatelessWidget {
  final String chapterName;
  final List<Topic> topics;
  final Color accentColor;

  const SubTopicListScreen({
    super.key,
    required this.chapterName,
    required this.topics,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // subTopic name -> List<Topic> (Genelde her subTopic tek bir Topic nesnesidir)
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(chapterName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                topic.subTopic,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${topic.totalFlashcards} kart · ${topic.totalCases} vaka',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
              onTap: () {
                Navigator.push(
                  context,
                  AppRoute.slideUp(TopicDetailScreen(topic: topic)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
