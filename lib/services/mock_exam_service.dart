import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mock_exam_model.dart';
import '../models/topic_model.dart';
import '../services/data_service.dart';

class MockExamService extends ChangeNotifier {
  static final MockExamService _instance = MockExamService._internal();
  factory MockExamService() => _instance;
  MockExamService._internal();

  static const _historyKey = 'mock_exam_history_v1';

  // ── Aktif Sınav Durumu ───────────────────────────────────────────────────

  MockExamConfig? _config;
  List<ExamQuestion> _questions = [];
  int _currentIndex = 0;
  bool _isRunning = false;
  bool _isFinished = false;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _timeLimitSeconds = 0;

  // History
  List<MockExamResult> _history = [];
  bool _historyLoaded = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  MockExamConfig? get config => _config;
  List<ExamQuestion> get questions => List.unmodifiable(_questions);
  int get currentIndex => _currentIndex;
  bool get isRunning => _isRunning;
  bool get isFinished => _isFinished;
  int get elapsedSeconds => _elapsedSeconds;
  int get remainingSeconds =>
      (_timeLimitSeconds - _elapsedSeconds).clamp(0, _timeLimitSeconds);
  List<MockExamResult> get history => List.unmodifiable(_history);

  ExamQuestion? get currentQuestion =>
      _currentIndex < _questions.length ? _questions[_currentIndex] : null;

  int get answeredCount => _questions.where((q) => q.isAnswered).length;
  int get flaggedCount => _questions.where((q) => q.isFlagged).length;

  /// 0.0 → 1.0 geri sayım progress
  double get timeProgress {
    if (_timeLimitSeconds == 0) return 0;
    return (_elapsedSeconds / _timeLimitSeconds).clamp(0.0, 1.0);
  }

  /// Kalan süre formatı "24:59"
  String get formattedRemaining {
    final rem = remainingSeconds;
    final m = (rem ~/ 60).toString().padLeft(2, '0');
    final s = (rem % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get isTimeWarning => remainingSeconds <= 120; // Son 2 dakika

  // ── Sınav Oluşturma ──────────────────────────────────────────────────────

  Future<bool> generateExam(MockExamConfig config) async {
    _config = config;
    _questions = [];
    _currentIndex = 0;
    _isFinished = false;
    _elapsedSeconds = 0;
    _timeLimitSeconds = config.timeLimitMinutes * 60;

    try {
      final dataService = DataService();
      List<ClinicalCase> allCases = [];

      for (final subjectId in config.subjectIds) {
        final topics = await dataService.loadTopics(subjectId: subjectId);
        for (final topic in topics) {
          for (final cc in topic.clinicalCases) {
            if (cc.options.length >= 4 && cc.correctAnswer.isNotEmpty) {
              allCases.add(cc);
            }
          }
        }
      }

      if (allCases.isEmpty) return false;

      // Karıştır
      if (config.shuffleQuestions) {
        // Hile onleme: Sadece alfabetik/sabit sira veya premium degilse karistirma?
        // Simdilik gercek rastgelelik kalsin ama UI tarafında limit kontrolü yapacağız.
        allCases.shuffle(Random(42)); // Sabit seed (42) ile herkes ayni "rastgele" sirayi gorur
      }

      // Konu dağılımı: subjectId'ye göre proportional seçim
      final needed = config.questionCount.clamp(1, allCases.length);
      final selected = allCases.take(needed).toList();

      _questions = selected.map((cc) {
        final subjectId = _extractSubject(cc.caseText);
        return ExamQuestion(
          clinicalCase: cc,
          subject: subjectId,
        );
      }).toList();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('MockExam generate error: $e');
      return false;
    }
  }

  String _extractSubject(String caseText) {
    final match = RegExp(r'Soru:\(([^)]+)\)').firstMatch(caseText);
    return match?.group(1) ?? 'Genel';
  }

  // ── Timer ────────────────────────────────────────────────────────────────

  void startTimer({VoidCallback? onTimeUp}) {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (_elapsedSeconds >= _timeLimitSeconds) {
        _timer?.cancel();
        _isRunning = false;
        onTimeUp?.call();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resumeTimer({VoidCallback? onTimeUp}) {
    startTimer(onTimeUp: onTimeUp);
  }

  // ── Navigasyon ───────────────────────────────────────────────────────────

  void goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    _currentIndex = index;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void answerQuestion(int index, String answer) {
    if (index < 0 || index >= _questions.length) return;
    _questions[index].selectedAnswer = answer;
    notifyListeners();
  }

  void toggleFlag(int index) {
    if (index < 0 || index >= _questions.length) return;
    _questions[index].isFlagged = !_questions[index].isFlagged;
    notifyListeners();
  }

  // ── Sınav Tamamlama ──────────────────────────────────────────────────────

  Future<MockExamResult> finishExam() async {
    _timer?.cancel();
    _isRunning = false;
    _isFinished = true;

    int correct = 0;
    int wrong = 0;
    int unanswered = 0;
    final Map<String, Map<String, int>> subjectData = {};

    for (final q in _questions) {
      final subject = q.subject;
      subjectData.putIfAbsent(subject, () => {'total': 0, 'correct': 0});
      subjectData[subject]!['total'] = subjectData[subject]!['total']! + 1;

      if (!q.isAnswered) {
        unanswered++;
      } else if (q.isCorrect) {
        correct++;
        subjectData[subject]!['correct'] =
            subjectData[subject]!['correct']! + 1;
      } else {
        wrong++;
      }
    }

    final breakdown = subjectData.map(
      (k, v) => MapEntry(
        k,
        SubjectScore(
          subjectId: k,
          subjectName: k,
          total: v['total']!,
          correct: v['correct']!,
        ),
      ),
    );

    final result = MockExamResult(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      totalQuestions: _questions.length,
      correctAnswers: correct,
      wrongAnswers: wrong,
      unanswered: unanswered,
      timeTakenSeconds: _elapsedSeconds,
      timeLimitSeconds: _timeLimitSeconds,
      subjectBreakdown: breakdown,
    );

    await _saveResult(result);
    notifyListeners();
    return result;
  }

  void resetExam() {
    _timer?.cancel();
    _isRunning = false;
    _isFinished = false;
    _questions = [];
    _currentIndex = 0;
    _elapsedSeconds = 0;
    _config = null;
    notifyListeners();
  }

  // ── History ──────────────────────────────────────────────────────────────

  Future<void> loadHistory() async {
    if (_historyLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw != null) {
      try {
        _history = MockExamResult.decodeList(raw);
      } catch (_) {
        _history = [];
      }
    }
    _historyLoaded = true;
    notifyListeners();
  }

  Future<void> _saveResult(MockExamResult result) async {
    _history.insert(0, result);
    // En fazla 50 sınav tut
    if (_history.length > 50) _history = _history.sublist(0, 50);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _historyKey, MockExamResult.encodeList(_history));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
