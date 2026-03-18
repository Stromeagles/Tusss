import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/topic_model.dart';
import '../models/subject_registry.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  /// Per-subject cache: subjectId → topics (tüm dosyalar birleştirilmiş)
  final Map<String, List<Topic>> _cache = {};

  // ── Tek modül yükleme ─────────────────────────────────────────────────────

  Future<List<Topic>> loadBySubject(String subjectId) async {
    if (_cache.containsKey(subjectId)) return _cache[subjectId]!;

    final module = SubjectRegistry.findById(subjectId);
    if (module == null) return [];

    // Modüle ait tüm JSON dosyalarını paralel yükle ve birleştir
    final futures = module.assetPaths.map((path) async {
      final jsonString = await rootBundle.loadString(path);
      final list = json.decode(jsonString) as List<dynamic>;
      return list
          .map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    final results = await Future.wait(futures);
    final topics = results.expand((list) => list).toList();

    _cache[subjectId] = topics;
    return topics;
  }

  // ── Tüm modülleri yükleme ─────────────────────────────────────────────────

  Future<List<Topic>> loadAllTopics() async {
    final results = await Future.wait(
      SubjectRegistry.modules.map((m) => loadBySubject(m.id)),
    );
    return results.expand((list) => list).toList();
  }

  // ── Filtered helpers ──────────────────────────────────────────────────────

  Future<List<Topic>> loadTopics({String? subjectId}) async {
    if (subjectId == null) return loadAllTopics();
    return loadBySubject(subjectId);
  }

  Future<List<Flashcard>> loadFlashcards({String? subjectId}) async {
    final topics = await loadTopics(subjectId: subjectId);
    return topics.expand((t) => t.flashcards).toList();
  }

  Future<List<ClinicalCase>> loadCases({String? subjectId}) async {
    final topics = await loadTopics(subjectId: subjectId);
    return topics.expand((t) => t.clinicalCases).toList();
  }

  // ── Geriye dönük uyumluluk ────────────────────────────────────────────────

  Future<List<Flashcard>> loadAllFlashcards() => loadFlashcards();
  Future<List<ClinicalCase>> loadAllCases() => loadCases();

  void clearCache() => _cache.clear();
  void clearSubjectCache(String subjectId) => _cache.remove(subjectId);
}
