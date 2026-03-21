import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tüm kullanıcı verisini JSON olarak dışa/içe aktarır.
/// SharedPreferences silinse bile bu yedekten geri yüklenebilir.
class BackupService {
  static const _backupKeys = [
    'user_profile',
    'flashcards_studied',
    'cases_attempted',
    'correct_answers',
    'completed_cards',
    'daily_goal',
    'today_studied',
    'current_streak',
    'longest_streak',
    'last_study_date',
    'weekly_stats',
    'weekday_goal_hours',
    'weekend_goal_hours',
    'target_tus_date',
    'selected_subjects',
    'base_score',
    'target_score',
    'focus_minutes',
    'sm2_card_data',
    'auth_logged_in',
    'auth_email',
    'auth_name',
  ];

  /// Tüm veriyi JSON string olarak döndürür.
  static Future<String> exportToJson() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      '_backup_version': 1,
      '_backup_date': DateTime.now().toIso8601String(),
    };

    for (final key in _backupKeys) {
      final value = prefs.get(key);
      if (value != null) {
        data[key] = value;
      }
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// JSON string'den veriyi geri yükler.
  static Future<int> importFromJson(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    int restored = 0;

    for (final key in _backupKeys) {
      if (!data.containsKey(key)) continue;
      final value = data[key];

      if (value is int) {
        await prefs.setInt(key, value);
        restored++;
      } else if (value is double) {
        await prefs.setDouble(key, value);
        restored++;
      } else if (value is bool) {
        await prefs.setBool(key, value);
        restored++;
      } else if (value is String) {
        await prefs.setString(key, value);
        restored++;
      } else if (value is List) {
        await prefs.setStringList(
          key,
          value.map((e) => e.toString()).toList(),
        );
        restored++;
      }
    }

    return restored;
  }
}
