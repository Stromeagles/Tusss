import 'dart:convert';
import 'package:flutter/services.dart';

class SpecialtyScore {
  final String name;
  final double averageScore;
  final String difficulty;
  final String advice;

  SpecialtyScore({
    required this.name,
    required this.averageScore,
    required this.difficulty,
    required this.advice,
  });

  factory SpecialtyScore.fromJson(Map<String, dynamic> json) {
    return SpecialtyScore(
      name: json['name'],
      averageScore: (json['average_score'] as num).toDouble(),
      difficulty: json['difficulty'],
      advice: json['advice'],
    );
  }
}

class SpecialtyScoreService {
  static final SpecialtyScoreService _instance = SpecialtyScoreService._internal();
  factory SpecialtyScoreService() => _instance;
  SpecialtyScoreService._internal();

  List<SpecialtyScore> _scores = [];
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString('assets/data/specialty_scores.json');
      final data = await json.decode(response);
      final List list = data['specialties'];
      _scores = list.map((e) => SpecialtyScore.fromJson(e)).toList();
      _isLoaded = true;
    } catch (e) {
      print('Specialty scores load error: $e');
    }
  }

  SpecialtyScore? getScoreFor(String specialtyName) {
    try {
      return _scores.firstWhere((s) => s.name.contains(specialtyName) || specialtyName.contains(s.name));
    } catch (_) {
      return null;
    }
  }

  List<SpecialtyScore> get allScores => _scores;
}
