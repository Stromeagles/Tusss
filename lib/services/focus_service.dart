import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'progress_service.dart';

enum FocusSound {
  none('Kapalı', null),
  lofi('Lofi Beats', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3'),
  whiteNoise('Beyaz Gürültü', 'https://actions.google.com/sounds/v1/ambiences/white_noise.ogg'),
  rain('Yağmur', 'https://actions.google.com/sounds/v1/weather/rain_on_roof.ogg'),
  hospital('Hastane Ambiyansı', 'https://actions.google.com/sounds/v1/ambiences/hospital_room.ogg');

  final String label;
  final String? url;
  const FocusSound(this.label, this.url);
}

class FocusService extends ChangeNotifier {
  // Singleton
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  
  int _secondsRemaining = 25 * 60; // Default 25 mins
  bool _isRunning = false;
  FocusSound _currentSound = FocusSound.none;
  int _totalFocusMinutes = 0;

  // Getters
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  FocusSound get currentSound => _currentSound;
  int get totalFocusMinutes => _totalFocusMinutes;
  bool get isAudioPlaying => _currentSound != FocusSound.none;

  String get timerString {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void setDuration(int minutes) {
    if (_isRunning) return;
    _secondsRemaining = minutes * 60;
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        if (_secondsRemaining % 60 == 0) {
          _totalFocusMinutes++;
          ProgressService().recordFocusMinutes(1);
        }
        notifyListeners();
      } else {
        stopTimer();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void stopTimer() {
    _isRunning = false;
    _timer?.cancel();
    _secondsRemaining = 25 * 60; // Reset to default
    notifyListeners();
  }

  Future<void> setSound(FocusSound sound) async {
    if (_currentSound == sound) return;

    _currentSound = sound;
    if (sound == FocusSound.none) {
      await _audioPlayer.stop();
    } else if (sound.url != null) {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource(sound.url!));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
