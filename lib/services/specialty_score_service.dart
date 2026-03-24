import 'dart:convert';
import 'package:flutter/services.dart';

class SpecialtyScore {
  final String name;
  final double averageScore;
  final String difficulty;
  final String advice;
  final String imagePath;

  SpecialtyScore({
    required this.name,
    required this.averageScore,
    required this.difficulty,
    required this.advice,
    String? imagePath,
  }) : imagePath = imagePath ?? SpecialtyScoreService.getImagePath(name);

  factory SpecialtyScore.fromJson(Map<String, dynamic> json) {
    return SpecialtyScore(
      name: json['name'] as String,
      averageScore: (json['average_score'] as num).toDouble(),
      difficulty: json['difficulty'] as String,
      advice: json['advice'] as String,
      imagePath: json['image_path'] as String?,
    );
  }
}

class SpecialtyScoreService {
  static final SpecialtyScoreService _instance = SpecialtyScoreService._internal();
  factory SpecialtyScoreService() => _instance;
  SpecialtyScoreService._internal();

  List<SpecialtyScore> _scores = [];
  bool _isLoaded = false;

  static const String _fallbackImage = 'assets/images/hero_splash.jpg';

  // ── Branş → Görsel eşleme tablosu ─────────────────────────────────────────
  static const Map<String, String> branchImageMap = {
    'İç Hastalıkları (Dahiliye)':                 'assets/images/dahiliye.jpg',
    'Dahiliye':                                    'assets/images/dahiliye.jpg',
    'İç Hastalıkları':                             'assets/images/dahiliye.jpg',
    'Kardiyoloji':                                 'assets/images/kardıyolojı.jpg',
    'Kalp Damar Cerrahisi':                        'assets/images/kardıyolojı.jpg',
    'Radyoloji':                                   'assets/images/radyo.jpg',
    'Nükleer Tıp':                                 'assets/images/radyo.jpg',
    'Çocuk Sağlığı ve Hastalıkları':              'assets/images/pedaitr.jpg',
    'Pediatri':                                    'assets/images/pedaitr.jpg',
    'Çocuk Cerrahisi':                             'assets/images/pedaitr.jpg',
    'Genel Cerrahi':                               'assets/images/genelcerrahı.jpg',
    'Plastik, Rekonstruktif ve Estetik Cerrahi':  'assets/images/genelcerrahı.jpg',
    'Plastik Cerrahi':                             'assets/images/genelcerrahı.jpg',
    'Beyin Cerrahisi':                             'assets/images/genelcerrahı.jpg',
    'Göğüs Cerrahisi':                             'assets/images/genelcerrahı.jpg',
    'Ortopedi':                                    'assets/images/genelcerrahı.jpg',
    'Üroloji':                                     'assets/images/genelcerrahı.jpg',
    'Anatomi':                                     'assets/images/anatomı.jpg',
    'Fiziksel Tıp ve Rehabilitasyon':              'assets/images/anatomı.jpg',
    'Fiziksel Tıp':                                'assets/images/anatomı.jpg',
    'Mikrobiyoloji':                               'assets/images/mıkrobıyolojı.jpg',
    'Enfeksiyon Hastalıkları':                     'assets/images/mıkrobıyolojı.jpg',
    'Patoloji':                                    'assets/images/patolojı.jpg',
    'Histoloji':                                   'assets/images/patolojı.jpg',
    'Farmakoloji':                                 'assets/images/farmakolojı.jpg',
    'Anesteziyoloji ve Reanimasyon':               'assets/images/farmakolojı.jpg',
    'Anesteziyoloji':                              'assets/images/farmakolojı.jpg',
    'Biyokimya':                                   'assets/images/bıyokımya.jpg',
    'Deri ve Zuhrevi Hastalıkları (Dermatoloji)': 'assets/images/sınav.jpg',
    'Dermatoloji':                                 'assets/images/sınav.jpg',
    'Göz Hastalıkları':                            'assets/images/sınav.jpg',
    'Ruh Sağlığı ve Hastalıkları (Psikiyatri)':   'assets/images/Aı_acıklamaları.jpg',
    'Psikiyatri':                                  'assets/images/Aı_acıklamaları.jpg',
    'Nöroloji':                                    'assets/images/Aı_acıklamaları.jpg',
    'Kadın Hastalıkları ve Doğum':                'assets/images/klınık_vakalar.jpg',
    'Kadın Doğum':                                 'assets/images/klınık_vakalar.jpg',
    'Acil Tıp':                                    'assets/images/klınık_vakalar.jpg',
    'KBB':                                         'assets/images/klınık_vakalar.jpg',
    'Kulak Burun Boğaz':                           'assets/images/klınık_vakalar.jpg',
    'Aile Hekimliği':                              'assets/images/gelısım_takıbı.jpg',
    'Göğüs Hastalıkları':                          'assets/images/gelısım_takıbı.jpg',
  };

  /// Branş adından görsel yolunu döndür. Kısmi eşleşme denenir, yoksa fallback.
  static String getImagePath(String branchName) {
    if (branchImageMap.containsKey(branchName)) return branchImageMap[branchName]!;
    final lower = branchName.toLowerCase();
    for (final entry in branchImageMap.entries) {
      if (lower.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(lower)) {
        return entry.value;
      }
    }
    return _fallbackImage;
  }

  // ── Yükleme ───────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final String response =
          await rootBundle.loadString('assets/data/specialty_scores.json');
      final data = json.decode(response) as Map<String, dynamic>;
      final List list = data['specialties'] as List;
      _scores = list
          .map((e) => SpecialtyScore.fromJson(e as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (_) {}
  }

  SpecialtyScore? getScoreFor(String specialtyName) {
    try {
      return _scores.firstWhere(
        (s) => s.name.contains(specialtyName) || specialtyName.contains(s.name),
      );
    } catch (_) {
      return null;
    }
  }

  List<SpecialtyScore> get allScores => _scores;
}
