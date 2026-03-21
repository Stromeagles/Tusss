import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Lokal bildirim servisi — çalışma hatırlatıcıları için.
/// Web platformunda sessizce devre dışı kalır.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

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

  // ── Günlük hatırlatıcı zamanla ────────────────────────────────────────────

  /// [hour] ve [minute] ile her gün tekrarlayan hatırlatıcı kurar.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'TUS Asistani',
    String body = 'Bugunluk calisma hedefini tamamlamayi unutma!',
  }) async {
    if (kIsWeb || !_initialized) return;

    await _plugin.zonedSchedule(
      0, // bildirim ID
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

  /// Belirli bir kart/vaka için tek seferlik hatırlatıcı.
  Future<void> scheduleCardReminder({
    required String cardId,
    required Duration delay,
    String title = 'Tekrar Zamani',
    String? body,
  }) async {
    if (kIsWeb || !_initialized) return;

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
    final id = cardId.hashCode.abs() % 100000; // unique int id

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
    await _plugin.cancel(0);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // ── Yardımcı ──────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
