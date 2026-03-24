import 'dart:convert';
import '../models/topic_model.dart';

/// Sınav konfigürasyonu
class MockExamConfig {
  final int questionCount;        // 10, 20, 50, 100
  final int timeLimitMinutes;     // questionCount * 1.5 dk
  final List<String> subjectIds;  // Hangi branşlardan
  final bool shuffleQuestions;
  final bool showInstantFeedback;

  const MockExamConfig({
    required this.questionCount,
    required this.timeLimitMinutes,
    required this.subjectIds,
    this.shuffleQuestions = true,
    this.showInstantFeedback = false,
  });

  static MockExamConfig create({
    required int questionCount,
    required List<String> subjectIds,
    bool showInstantFeedback = false,
  }) =>
      MockExamConfig(
        questionCount: questionCount,
        timeLimitMinutes: (questionCount * 1.5).ceil(),
        subjectIds: subjectIds,
        shuffleQuestions: true,
        showInstantFeedback: showInstantFeedback,
      );
}

/// Sınavdaki tek soru (ClinicalCase sarmalı)
class ExamQuestion {
  final ClinicalCase clinicalCase;
  final String subject;
  String? selectedAnswer;
  bool isFlagged;

  ExamQuestion({
    required this.clinicalCase,
    required this.subject,
    this.selectedAnswer,
    this.isFlagged = false,
  });

  bool get isAnswered => selectedAnswer != null;
  bool get isCorrect =>
      selectedAnswer != null &&
      selectedAnswer!.trim().toLowerCase() ==
          clinicalCase.correctAnswer.trim().toLowerCase();
}

/// Konu bazlı puan özeti
class SubjectScore {
  final String subjectId;
  final String subjectName;
  final int total;
  final int correct;

  const SubjectScore({
    required this.subjectId,
    required this.subjectName,
    required this.total,
    required this.correct,
  });

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'total': total,
        'correct': correct,
      };

  factory SubjectScore.fromJson(Map<String, dynamic> j) => SubjectScore(
        subjectId: j['subjectId'] as String,
        subjectName: j['subjectName'] as String,
        total: (j['total'] as num).toInt(),
        correct: (j['correct'] as num).toInt(),
      );
}

/// Tamamlanmış sınav kaydı
class MockExamResult {
  final String id;
  final DateTime date;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int unanswered;
  final int timeTakenSeconds;
  final int timeLimitSeconds;
  final Map<String, SubjectScore> subjectBreakdown;

  const MockExamResult({
    required this.id,
    required this.date,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.unanswered,
    required this.timeTakenSeconds,
    required this.timeLimitSeconds,
    required this.subjectBreakdown,
  });

  /// TUS net hesabı: Doğru - (Yanlış × 0.25)
  double get netScore => correctAnswers - (wrongAnswers * 0.25);
  double get accuracy =>
      totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;

  String get formattedTime {
    final m = timeTakenSeconds ~/ 60;
    final s = timeTakenSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'unanswered': unanswered,
        'timeTakenSeconds': timeTakenSeconds,
        'timeLimitSeconds': timeLimitSeconds,
        'subjectBreakdown': subjectBreakdown
            .map((k, v) => MapEntry(k, v.toJson())),
      };

  factory MockExamResult.fromJson(Map<String, dynamic> j) => MockExamResult(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        totalQuestions: (j['totalQuestions'] as num).toInt(),
        correctAnswers: (j['correctAnswers'] as num).toInt(),
        wrongAnswers: (j['wrongAnswers'] as num).toInt(),
        unanswered: (j['unanswered'] as num).toInt(),
        timeTakenSeconds: (j['timeTakenSeconds'] as num).toInt(),
        timeLimitSeconds: (j['timeLimitSeconds'] as num).toInt(),
        subjectBreakdown: (j['subjectBreakdown'] as Map<String, dynamic>)
            .map((k, v) =>
                MapEntry(k, SubjectScore.fromJson(v as Map<String, dynamic>))),
      );

  static String encodeList(List<MockExamResult> list) =>
      json.encode(list.map((r) => r.toJson()).toList());

  static List<MockExamResult> decodeList(String source) {
    final decoded = json.decode(source) as List;
    return decoded
        .map((e) => MockExamResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
