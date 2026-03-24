import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PomodoroPhase { focus, breakTime }

class PomodoroService extends ChangeNotifier {
  // ── Singleton ───────────────────────────────────────────────────────────────
  static final PomodoroService _instance = PomodoroService._internal();
  factory PomodoroService() => _instance;
  PomodoroService._internal() {
    _loadTodayMinutes();
  }

  // ── Sabitler ────────────────────────────────────────────────────────────────
  static const int focusDurationSec = 25 * 60;   // 25 dakika
  static const int breakDurationSec = 5 * 60;    // 5 dakika

  // ── State ───────────────────────────────────────────────────────────────────
  Timer? _timer;
  PomodoroPhase _phase = PomodoroPhase.focus;
  int _secondsRemaining = focusDurationSec;
  bool _isRunning = false;
  int _todayFocusSeconds = 0;       // Bugünkü toplam çalışma (saniye)
  int _completedPomodoros = 0;       // Tamamlanan pomodoro sayısı

  // ── Getters ─────────────────────────────────────────────────────────────────
  PomodoroPhase get phase => _phase;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  int get todayFocusSeconds => _todayFocusSeconds;
  int get completedPomodoros => _completedPomodoros;

  bool get isFocusPhase => _phase == PomodoroPhase.focus;

  int get _totalDuration =>
      _phase == PomodoroPhase.focus ? focusDurationSec : breakDurationSec;

  /// 0.0 → 1.0 arası ilerleme (geçen süre oranı)
  double get progress => 1.0 - (_secondsRemaining / _totalDuration);

  /// "24:59" formatında kalan süre
  String get timerString {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Bugünkü toplam çalışma — okunabilir format
  String get todayFocusFormatted {
    final h = _todayFocusSeconds ~/ 3600;
    final m = (_todayFocusSeconds % 3600) ~/ 60;
    if (h > 0) return '$h Saat $m Dakika';
    return '$m Dakika';
  }

  // ── Kontroller ──────────────────────────────────────────────────────────────

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  /// Mevcut döngüyü sıfırla (aynı fazda kalır)
  void reset() {
    _isRunning = false;
    _timer?.cancel();
    _secondsRemaining = _totalDuration;
    notifyListeners();
  }

  /// Mevcut fazı atla — çalışmadaysa molaya, moladaysa çalışmaya geç
  void skip() {
    _timer?.cancel();
    _isRunning = false;
    _switchPhase();
  }

  // ── Timer Tick ──────────────────────────────────────────────────────────────

  void _tick(Timer timer) {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;

      // Sadece odaklanma fazında toplam süreye ekle
      if (_phase == PomodoroPhase.focus) {
        _todayFocusSeconds++;
        // Her 60 saniyede bir persist et (performans için)
        if (_todayFocusSeconds % 60 == 0) {
          _persistTodayMinutes();
        }
      }

      notifyListeners();
    } else {
      // Süre doldu — faz geçişi
      timer.cancel();
      _isRunning = false;

      if (_phase == PomodoroPhase.focus) {
        _completedPomodoros++;
        _persistTodayMinutes();
      }

      _switchPhase();
    }
  }

  void _switchPhase() {
    _phase = _phase == PomodoroPhase.focus
        ? PomodoroPhase.breakTime
        : PomodoroPhase.focus;
    _secondsRemaining = _totalDuration;
    notifyListeners();
  }

  // ── Persistence (SharedPreferences) ─────────────────────────────────────────

  String get _todayKey => 'pomodoro_focus_${DateTime.now().toIso8601String().substring(0, 10)}';

  Future<void> _loadTodayMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    _todayFocusSeconds = (prefs.getInt(_todayKey) ?? 0) * 60;
    // Eski günleri temizlemiyoruz — sadece bugünü okuyoruz
    notifyListeners();
  }

  Future<void> _persistTodayMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_todayKey, _todayFocusSeconds ~/ 60);
  }

  // ── Dispose ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
