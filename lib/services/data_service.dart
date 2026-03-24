import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/topic_model.dart';
import '../models/subject_registry.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  /// Per-subject cache: subjectId -> topics
  final Map<String, List<Topic>> _cache = {};

  /// Son hata mesajı (UI'dan okunabilir)
  String? lastError;

  // ── Tek modül yükleme (try-catch ile korumalı) ──────────────────────────

  Future<List<Topic>> _loadSingleFile(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return decoded
            .map((e) => Topic.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        return [Topic.fromJson(decoded)];
      }
      return [];
    } on FormatException catch (e) {
      lastError = 'JSON format hatasi: $path ($e)';
      return [];
    } catch (e) {
      lastError = 'Veri yukleme hatasi: $path ($e)';
      return [];
    }
  }

  Future<List<Topic>> loadBySubject(String subjectId) async {
    if (_cache.containsKey(subjectId)) return _cache[subjectId]!;

    final module = SubjectRegistry.findById(subjectId);
    if (module == null) return [];

    lastError = null;

    // Her JSON dosyasını paralel yükle — biri bozuksa diğerleri etkilenmesin
    final results = await Future.wait(
      module.assetPaths.map(_loadSingleFile),
    );
    final allTopics = results.expand((list) => list).toList();

    _cache[subjectId] = allTopics;
    return allTopics;
  }

  // ── Tüm modülleri yükleme ───────────────────────────────────────────────

  Future<List<Topic>> loadAllTopics() async {
    final results = await Future.wait(
      SubjectRegistry.modules.map((m) => loadBySubject(m.id)),
    );
    return results.expand((list) => list).toList();
  }

  // ── Filtered helpers ────────────────────────────────────────────────────

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

  // ── Sayfalama destekli yükleme ──────────────────────────────────────────
  /// Büyük veri setlerinde bellek tasarrufu için offset/limit ile yükleme.

  Future<List<Flashcard>> loadFlashcardsPaginated({
    String? subjectId,
    int offset = 0,
    int limit = 100,
  }) async {
    final all = await loadFlashcards(subjectId: subjectId);
    if (offset >= all.length) return [];
    final end = (offset + limit).clamp(0, all.length);
    return all.sublist(offset, end);
  }

  Future<List<ClinicalCase>> loadCasesPaginated({
    String? subjectId,
    int offset = 0,
    int limit = 100,
  }) async {
    final all = await loadCases(subjectId: subjectId);
    if (offset >= all.length) return [];
    final end = (offset + limit).clamp(0, all.length);
    return all.sublist(offset, end);
  }

  /// Toplam sayı bilgisi (UI'da "45/200" göstermek için)
  Future<int> getFlashcardCount({String? subjectId}) async {
    final topics = await loadTopics(subjectId: subjectId);
    return topics.fold<int>(0, (sum, t) => sum + t.flashcards.length);
  }

  Future<int> getCaseCount({String? subjectId}) async {
    final topics = await loadTopics(subjectId: subjectId);
    return topics.fold<int>(0, (sum, t) => sum + t.clinicalCases.length);
  }

  // ── Geriye dönük uyumluluk ──────────────────────────────────────────────

  Future<List<Flashcard>> loadAllFlashcards() => loadFlashcards();
  Future<List<ClinicalCase>> loadAllCases() => loadCases();

  void clearCache() => _cache.clear();
  void clearSubjectCache(String subjectId) => _cache.remove(subjectId);
}
