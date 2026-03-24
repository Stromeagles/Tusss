import 'dart:math';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Lokal bildirim servisi — çalışma hatırlatıcıları + akıllı kişiselleştirme.
/// Web platformunda sessizce devre dışı kalır.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Bildirim ID'leri ───────────────────────────────────────────────────────
  static const int _idDailyReminder = 0;
  static const int _idStreakWarning = 1;
  static const int _idWeeklyMotivation = 2;

  // ── Başlatma ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  // ── Temel günlük hatırlatıcı ──────────────────────────────────────────────

  /// [hour] ve [minute] ile her gün tekrarlayan hatırlatıcı kurar.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'AsisTus',
    String body = 'Bugunluk calisma hedefini tamamlamayi unutma!',
  }) async {
    if (kIsWeb || !_initialized) return;

    await _plugin.zonedSchedule(
      _idDailyReminder,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Gunluk Hatirlatici',
          channelDescription: 'Gunluk calisma hatirlaticisi',
          importance: Importance.high,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Kişiselleştirilmiş hatırlatıcı ───────────────────────────────────────

  /// Kullanıcının adı, streak ve zayıf konularına göre akıllı bildirim planlar.
  /// Her gün 20:00'de tetiklenir.
  Future<void> schedulePersonalizedReminder({
    required String userName,
    required int streakDays,
    List<String> weakSubjects = const [],
    int hour = 20,
    int minute = 0,
  }) async {
    if (kIsWeb || !_initialized) return;

    final firstName = userName.split(' ').first;
    final title = _buildTitle(firstName, streakDays);
    final body = _buildBody(streakDays, weakSubjects);

    await _plugin.zonedSchedule(
      _idDailyReminder,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Gunluk Hatirlatici',
          channelDescription: 'Kisisellestirilmis gunluk calisma hatirlaticisi',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Seri tehlikede bildirimi — kullanıcı bugün çalışmadıysa gönderilir.
  /// Öğleden sonra (14:00) planlanır.
  Future<void> scheduleStreakWarning({
    required int streakDays,
    int hour = 14,
    int minute = 0,
  }) async {
    if (kIsWeb || !_initialized || streakDays < 2) return;

    await _plugin.zonedSchedule(
      _idStreakWarning,
      '🔥 $streakDays günlük serin tehlikede!',
      'Bugün çalışmazsan serinizi kaybedeceksin. Hızlı bir tekrar yeter!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_warning',
          'Seri Uyarisi',
          channelDescription: 'Gunluk seri kaybetme uyarisi',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFF78166),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Haftalık motivasyon — Pazartesi sabahı 09:00'da gönderilir.
  Future<void> scheduleWeeklyMotivation({
    required int totalStudied,
    required int currentStreak,
  }) async {
    if (kIsWeb || !_initialized) return;

    final messages = [
      'Yeni hafta, yeni başarılar! Bu hafta $totalStudied soruyu geride bırak.',
      'TUS yolculuğun devam ediyor. Bu hafta bir adım daha öne çık!',
      'Geçen haftaki emeğin seni buraya getirdi. Bu hafta daha da iyi!',
    ];
    final body = messages[totalStudied % messages.length];

    await _plugin.zonedSchedule(
      _idWeeklyMotivation,
      'Haftaya Hazır mısın?',
      body,
      _nextMonday(9, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_motivation',
          'Haftalik Motivasyon',
          channelDescription: 'Haftalik ilerleme ve motivasyon bildirimi',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ── Kart hatırlatıcı ──────────────────────────────────────────────────────

  /// Belirli bir kart/vaka için tek seferlik hatırlatıcı.
  Future<void> scheduleCardReminder({
    required String cardId,
    required Duration delay,
    String title = 'Tekrar Zamani',
    String? body,
  }) async {
    if (kIsWeb || !_initialized) return;

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
    final id = cardId.hashCode.abs() % 100000;

    await _plugin.zonedSchedule(
      id,
      title,
      body ?? 'Isaretledigin karti tekrar etme zamani geldi!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'card_reminder',
          'Kart Hatirlatici',
          channelDescription: 'Isaretlenen kart tekrar hatirlaticisi',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── İptal ─────────────────────────────────────────────────────────────────

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_idDailyReminder);
  }

  Future<void> cancelStreakWarning() async {
    if (kIsWeb) return;
    await _plugin.cancel(_idStreakWarning);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // ── Mesaj üreticiler ──────────────────────────────────────────────────────

  String _buildTitle(String firstName, int streak) {
    if (streak == 0) {
      return 'Merhaba $firstName, seni özledik!';
    } else if (streak == 1) {
      return 'İyi başlangıç $firstName!';
    } else if (streak < 7) {
      return '$firstName — $streak günlük seri devam ediyor!';
    } else if (streak < 30) {
      return '🔥 $firstName, $streak günlük süper seri!';
    } else {
      return '🏆 $firstName, $streak günlük efsane seri!';
    }
  }

  String _buildBody(int streak, List<String> weakSubjects) {
    final rng = Random();

    if (streak == 0) {
      final messages = [
        'Yeniden başlamak için en iyi zaman şimdi. Birkaç kart çevir!',
        'Her büyük başarı küçük bir adımla başlar. Bugün ilk adımını at!',
        'TUS sana bekliyor. Hadi 5 dakika ayır!',
      ];
      return messages[rng.nextInt(messages.length)];
    }

    if (weakSubjects.isNotEmpty) {
      final subject = weakSubjects[rng.nextInt(weakSubjects.length)];
      return '$subject konusunda biraz çalışma seni bekliyor. Şimdi tam zamanı!';
    }

    final streakMessages = [
      'Günlük hedefe az kaldı. Birkaç kart daha!',
      'Düzenli çalışma TUS başarısının sırrı. Serinle devam et!',
      'Bugünkü tekrarları tamamla, yarın daha hazır hissedersin!',
    ];
    return streakMessages[rng.nextInt(streakMessages.length)];
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextMonday(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var day = now;
    while (day.weekday != DateTime.monday) {
      day = day.add(const Duration(days: 1));
    }
    return tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
  }
}

