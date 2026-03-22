import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_service.dart';

enum FocusSound {
  none('Sessiz', null),
  rain('Yağmur', 'assets/sounds/rain.mp3'),
  library('Kütüphane', 'assets/sounds/library.mp3'),
  cafe('Kafe', 'assets/sounds/cafe.mp3'),
  whiteNoise('Beyaz Gürültü', 'assets/sounds/white_noise.mp3');

  final String label;
  final String? assetPath;
  const FocusSound(this.label, this.assetPath);
}

class FocusService extends ChangeNotifier {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal() {
    _loadTodayStats();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;

  // Stopwatch — ileri sayan
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  FocusSound _currentSound = FocusSound.none;

  // Pomodoro
  bool _isBreak = false;
  int _pomodoroTarget = 0; // hedef saniye (focus veya break)
  int _pomodoroFocusMin = 25;
  int _pomodoroBreakMin = 5;
  VoidCallback? _onPhaseEnd;

  // İstatistikler
  int _todayFocusSeconds = 0;
  int _todayBreakSeconds = 0;

  // Getters
  int get elapsedSeconds => _elapsedSeconds;
  bool get isRunning => _isRunning;
  bool get isBreak => _isBreak;
  FocusSound get currentSound => _currentSound;
  int get todayFocusSeconds => _todayFocusSeconds;
  int get todayBreakSeconds => _todayBreakSeconds;
  bool get isAudioPlaying => _currentSound != FocusSound.none;

  /// Stopwatch formatı "00:45:12"
  String get timerString {
    final h = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Pomodoro geri sayım formatı "24:59"
  String pomodoroString(int focusMinutes) {
    final target = _isBreak ? (_pomodoroBreakMin * 60) : (focusMinutes * 60);
    final remaining = (target - _elapsedSeconds).clamp(0, target);
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Pomodoro progress 0.0 → 1.0
  double pomodoroProgress(int focusMinutes) {
    final target = _isBreak ? (_pomodoroBreakMin * 60) : (focusMinutes * 60);
    if (target == 0) return 0;
    return (_elapsedSeconds / target).clamp(0.0, 1.0);
  }

  /// Stopwatch progress (her 60 saniyede bir tur)
  double get stopwatchProgress {
    if (_elapsedSeconds == 0) return 0;
    return (_elapsedSeconds % 60) / 60.0;
  }

  String get todayFocusFormatted {
    final h = _todayFocusSeconds ~/ 3600;
    final m = (_todayFocusSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}s ${m}dk';
    return '${m}dk';
  }

  String get todayBreakFormatted {
    final h = _todayBreakSeconds ~/ 3600;
    final m = (_todayBreakSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}s ${m}dk';
    return '${m}dk';
  }

  // ── Stopwatch (Serbest mod) ─────────────────────────────────────────────

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _isBreak = false;
    _pomodoroTarget = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      _todayFocusSeconds++;
      if (_elapsedSeconds % 60 == 0) {
        ProgressService().recordFocusMinutes(1);
        _persistTodayStats();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  // ── Pomodoro ────────────────────────────────────────────────────────────

  void startPomodoro(int focusMin, int breakMin, {VoidCallback? onPhaseEnd}) {
    if (_isRunning) return;
    _pomodoroFocusMin = focusMin;
    _pomodoroBreakMin = breakMin;
    _onPhaseEnd = onPhaseEnd;
    _pomodoroTarget = _isBreak ? (breakMin * 60) : (focusMin * 60);
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;

      if (_isBreak) {
        _todayBreakSeconds++;
      } else {
        _todayFocusSeconds++;
        if (_elapsedSeconds % 60 == 0) {
          ProgressService().recordFocusMinutes(1);
        }
      }

      // Süre doldu — faz geçişi
      if (_elapsedSeconds >= _pomodoroTarget) {
        _timer?.cancel();
        _isRunning = false;
        _elapsedSeconds = 0;
        _isBreak = !_isBreak;
        _pomodoroTarget = _isBreak ? (_pomodoroBreakMin * 60) : (_pomodoroFocusMin * 60);
        _persistTodayStats();
        _onPhaseEnd?.call();
        // Otomatik başlat
        Future.delayed(const Duration(milliseconds: 500), () {
          startPomodoro(_pomodoroFocusMin, _pomodoroBreakMin, onPhaseEnd: _onPhaseEnd);
        });
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

  /// Oturumu bitir — geçen süreyi döndür ve sıfırla
  int endSession() {
    _isRunning = false;
    _timer?.cancel();
    final elapsed = _elapsedSeconds;
    _persistTodayStats();
    _elapsedSeconds = 0;
    _isBreak = false;
    _pomodoroTarget = 0;
    notifyListeners();
    return elapsed;
  }

  // ── Ses ─────────────────────────────────────────────────────────────────

  Future<void> setSound(FocusSound sound) async {
    if (_currentSound == sound) return;
    _currentSound = sound;
    if (sound == FocusSound.none) {
      await _audioPlayer.stop();
    } else if (sound.assetPath != null) {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(sound.assetPath!.replaceFirst('assets/', '')));
    }
    notifyListeners();
  }

  Future<void> stopSound() async {
    _currentSound = FocusSound.none;
    await _audioPlayer.stop();
    notifyListeners();
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  String get _todayKey => 'focus_total_${DateTime.now().toIso8601String().substring(0, 10)}';
  String get _todayBreakKey => 'focus_break_${DateTime.now().toIso8601String().substring(0, 10)}';

  Future<void> _loadTodayStats() async {
    final prefs = await SharedPreferences.getInstance();
    _todayFocusSeconds = (prefs.getInt(_todayKey) ?? 0) * 60;
    _todayBreakSeconds = (prefs.getInt(_todayBreakKey) ?? 0) * 60;
    notifyListeners();
  }

  Future<void> _persistTodayStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_todayKey, _todayFocusSeconds ~/ 60);
    await prefs.setInt(_todayBreakKey, _todayBreakSeconds ~/ 60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
