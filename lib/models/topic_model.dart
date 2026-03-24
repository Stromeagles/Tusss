class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String difficulty;
  final String? storyHint;
  final List<String> tags;

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.difficulty,
    this.storyHint,
    required this.tags,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      storyHint: json['story_hint']?.toString(),
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
    );
  }
}

class ClinicalCase {
  final String id;
  final String caseText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  const ClinicalCase({
    required this.id,
    required this.caseText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  /// Soru metninden konu bilgisini cikarir.
  /// "Soru:(Genel Mikrobiyoloji) Bakteri..." -> "Genel Mikrobiyoloji"
  String get topic {
    final match = RegExp(r'Soru:\(([^)]+)\)').firstMatch(caseText);
    return match?.group(1) ?? '';
  }

  /// Konu prefix'i cikarilmis saf soru metni.
  /// "Soru:(Genel Mikrobiyoloji) Bakteri..." -> "Bakteri..."
  String get cleanText {
    return caseText
        .replaceFirst(RegExp(r'Soru:\([^)]+\)\s*'), '')
        .trim();
  }

  factory ClinicalCase.fromJson(Map<String, dynamic> json) {
    return ClinicalCase(
      id: json['id']?.toString() ?? '',
      caseText: (json['case'] ?? json['question'] ?? '').toString(),
      options: json['options'] is List ? List<String>.from(json['options']) : [],
      correctAnswer: json['correct_answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class Topic {
  final String id;
  final String subject;
  final String chapter;
  final String topic;
  final String subTopic;
  final String contentSummary;
  final List<Flashcard> flashcards;
  final List<String> tusSpots;
  final List<ClinicalCase> clinicalCases;

  const Topic({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.subTopic,
    required this.contentSummary,
    required this.flashcards,
    required this.tusSpots,
    required this.clinicalCases,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      chapter: json['chapter']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      subTopic: json['sub_topic']?.toString() ?? '',
      contentSummary: json['content_summary']?.toString() ?? '',
      flashcards: json['flashcards'] is List
          ? (json['flashcards'] as List)
              .map((fc) => Flashcard.fromJson(fc as Map<String, dynamic>))
              .toList()
          : [],
      tusSpots: json['tus_spots'] is List ? List<String>.from(json['tus_spots']) : [],
      clinicalCases: json['clinical_cases'] is List
          ? (json['clinical_cases'] as List)
              .map((cc) => ClinicalCase.fromJson(cc as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  int get totalFlashcards => flashcards.length;
  int get totalCases => clinicalCases.length;
}
