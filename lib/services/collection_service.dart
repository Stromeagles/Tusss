import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_model.dart';

class CollectionService extends ChangeNotifier {
  static final CollectionService _instance = CollectionService._internal();
  factory CollectionService() => _instance;
  CollectionService._internal() {
    _load();
  }

  static const _prefsKey = 'user_collections_v1';

  List<CardCollection> _collections = [];
  bool _loaded = false;

  List<CardCollection> get collections => List.unmodifiable(_collections);
  bool get isLoaded => _loaded;

  // ── Load / Save ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _collections = CardCollection.decodeList(raw);
      } catch (_) {
        _collections = [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, CardCollection.encodeList(_collections));
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<CardCollection> createCollection(
      String name, String emoji, int colorValue) async {
    final now = DateTime.now();
    final col = CardCollection(
      id: '${now.millisecondsSinceEpoch}',
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      cardIds: [],
      createdAt: now,
      updatedAt: now,
    );
    _collections.insert(0, col);
    await _save();
    notifyListeners();
    return col;
  }

  Future<void> renameCollection(
      String id, String newName, String newEmoji, int newColor) async {
    final idx = _collections.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _collections[idx] = _collections[idx].copyWith(
      name: newName,
      emoji: newEmoji,
      colorValue: newColor,
      updatedAt: DateTime.now(),
    );
    await _save();
    notifyListeners();
  }

  Future<void> deleteCollection(String id) async {
    _collections.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  // ── Kart İşlemleri ───────────────────────────────────────────────────────

  Future<void> addCard(String collectionId, String cardId) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;
    final col = _collections[idx];
    if (col.cardIds.contains(cardId)) return;
    final newIds = [...col.cardIds, cardId];
    _collections[idx] = col.copyWith(cardIds: newIds, updatedAt: DateTime.now());
    await _save();
    notifyListeners();
  }

  Future<void> removeCard(String collectionId, String cardId) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;
    final col = _collections[idx];
    final newIds = col.cardIds.where((id) => id != cardId).toList();
    _collections[idx] = col.copyWith(cardIds: newIds, updatedAt: DateTime.now());
    await _save();
    notifyListeners();
  }

  Future<void> toggleCard(String collectionId, String cardId) async {
    final col = getById(collectionId);
    if (col == null) return;
    if (col.cardIds.contains(cardId)) {
      await removeCard(collectionId, cardId);
    } else {
      await addCard(collectionId, cardId);
    }
  }

  // ── Sorgular ─────────────────────────────────────────────────────────────

  CardCollection? getById(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CardCollection> getCollectionsForCard(String cardId) =>
      _collections.where((c) => c.cardIds.contains(cardId)).toList();

  bool isCardInAnyCollection(String cardId) =>
      _collections.any((c) => c.cardIds.contains(cardId));

  bool isCardInCollection(String collectionId, String cardId) =>
      getById(collectionId)?.cardIds.contains(cardId) ?? false;

  int get totalCards {
    final ids = <String>{};
    for (final col in _collections) {
      ids.addAll(col.cardIds);
    }
    return ids.length;
  }
}
