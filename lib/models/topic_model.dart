class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String difficulty;
  final List<String> tags;

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.difficulty,
    required this.tags,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      tags: List<String>.from(json['tags'] ?? []),
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

  factory ClinicalCase.fromJson(Map<String, dynamic> json) {
    return ClinicalCase(
      id: json['id'] as String? ?? '',
      caseText: json['case'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'] ?? '',
      explanation: json['explanation'] ?? '',
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
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      chapter: json['chapter'] ?? '',
      topic: json['topic'] ?? '',
      subTopic: json['sub_topic'] ?? '',
      contentSummary: json['content_summary'] ?? '',
      flashcards: (json['flashcards'] as List<dynamic>? ?? [])
          .map((fc) => Flashcard.fromJson(fc as Map<String, dynamic>))
          .toList(),
      tusSpots: List<String>.from(json['tus_spots'] ?? []),
      clinicalCases: (json['clinical_cases'] as List<dynamic>? ?? [])
          .map((cc) => ClinicalCase.fromJson(cc as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalFlashcards => flashcards.length;
  int get totalCases => clinicalCases.length;
}
