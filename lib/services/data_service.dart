import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/topic_model.dart';
import '../models/subject_registry.dart';

// compute() için top-level fonksiyon — class metodu olamaz
List<Map<String, dynamic>> _parseTopicJson(String jsonString) {
  final decoded = json.decode(jsonString);
  if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
  if (decoded is Map<String, dynamic>) return [decoded];
  return [];
}

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
      // Büyük JSON parse işlemini arka plan isolate'e taşı — UI thread'i bloklamaz
      final maps = await compute(_parseTopicJson, jsonString);
      return maps.map((e) => Topic.fromJson(e)).toList();
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

  // ── Kademeli (Progressive) Yükleme ──────────────────────────────────────
  /// Verileri asset dosyalarından okundukça parça parça döner.
  /// İlk 100 card/vakanın hızlıca görünmesini sağlar.

  Stream<List<Flashcard>> loadFlashcardsProgressive({String? subjectId, List<String>? subjectIds}) async* {
    final ids = subjectIds ?? (subjectId != null ? [subjectId] : SubjectRegistry.activeModules.map((m) => m.id).toList());
    
    for (final id in ids) {
      final module = SubjectRegistry.findById(id);
      if (module == null) continue;

      for (final path in module.assetPaths) {
        final topics = await _loadSingleFile(path);
        if (topics.isNotEmpty) {
          final cards = topics.expand((t) => t.flashcards).toList();
          if (cards.isNotEmpty) yield cards;
        }
      }
    }
  }

  Stream<List<ClinicalCase>> loadCasesProgressive({String? subjectId}) async* {
    final module = subjectId != null ? SubjectRegistry.findById(subjectId) : null;
    final paths = module?.assetPaths ?? SubjectRegistry.activeModules.expand((m) => m.assetPaths).toList();

    for (final path in paths) {
      final topics = await _loadSingleFile(path);
      if (topics.isNotEmpty) {
        final cases = topics.expand((t) => t.clinicalCases).toList();
        if (cases.isNotEmpty) yield cases;
      }
    }
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
