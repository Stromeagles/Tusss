import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final int weeklyCount;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.weeklyCount,
    this.isCurrentUser = false,
  });
}

/// Haftalık sıralama tablosu servisi.
/// Firestore: leaderboard/{weekKey}/users/{uid}
class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._();
  factory LeaderboardService() => _instance;
  LeaderboardService._();

  final _db = FirebaseFirestore.instance;

  /// ISO hafta anahtarı — örn. "2026-W13"
  String _weekKey() {
    final now = DateTime.now();
    final thursday = now.add(Duration(days: 4 - now.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final weekNum =
        1 + thursday.difference(firstThursday).inDays ~/ 7;
    return '${thursday.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  CollectionReference get _weekUsers =>
      _db.collection('leaderboard').doc(_weekKey()).collection('users');

  /// Kullanıcının haftalık sayacını 1 artır (her doğru cevap/kart için).
  Future<void> increment() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    try {
      await _weekUsers.doc(user.uid).set({
        'displayName': user.displayName ?? 'Anonim Doktor',
        'photoUrl': user.photoURL,
        'weeklyCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Haftalık top-N kullanıcıları döndür.
  Future<List<LeaderboardEntry>> getTopUsers({int limit = 10}) async {
    final myUid = AuthService.instance.currentUser?.uid;
    try {
      final snap = await _weekUsers
          .orderBy('weeklyCount', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 8));

      return snap.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return LeaderboardEntry(
          uid: doc.id,
          displayName: d['displayName'] as String? ?? 'Anonim Doktor',
          photoUrl: d['photoUrl'] as String?,
          weeklyCount: (d['weeklyCount'] as num?)?.toInt() ?? 0,
          isCurrentUser: doc.id == myUid,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mevcut kullanıcının bu haftaki sıralamasını döndür (1-indexed).
  Future<int?> getMyRank() async {
    final myUid = AuthService.instance.currentUser?.uid;
    if (myUid == null) return null;
    try {
      final mySnap = await _weekUsers.doc(myUid).get();
      if (!mySnap.exists) return null;
      final myCount =
          ((mySnap.data() as Map)['weeklyCount'] as num?)?.toInt() ?? 0;

      final higherSnap = await _weekUsers
          .where('weeklyCount', isGreaterThan: myCount)
          .count()
          .get();
      return (higherSnap.count ?? 0) + 1;
    } catch (_) {
      return null;
    }
  }
}
