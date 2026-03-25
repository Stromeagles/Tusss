import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_model.dart';
import 'auth_service.dart';

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

  // ── Firestore yolu ────────────────────────────────────────────────────────
  DocumentReference? get _firestoreDoc {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('content')
        .doc('collections');
  }

  // ── Load / Save ──────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_loaded) return;
    await _load();
  }

  /// Önbelleği temizler ve sunucudan taze veri çeker (Sync Fix)
  Future<void> clearCacheAndReload() async {
    _loaded = false;
    await _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1) Firestore'dan senkronize et
    final doc = _firestoreDoc;
    if (doc != null) {
      try {
        final snap = await doc.get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 7));
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final remoteRaw = data['data'] as String?;
          if (remoteRaw != null) {
            // Firestore verisi varsa yereli güncelle
            await prefs.setString(_prefsKey, remoteRaw);
          }
        }
      } catch (_) {}
    }

    // 2) Yerelden yükle
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
    final raw = CardCollection.encodeList(_collections);
    await prefs.setString(_prefsKey, raw);

    // Firestore yedekle
    final doc = _firestoreDoc;
    if (doc != null) {
      doc.set({
        'data': raw,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((_) {});
    }
  }

  /// Giriş yapıldığında veya manuel yenilemede kullanılır
  Future<void> syncWithCloud() async {
    _loaded = false;
    await _load();
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
