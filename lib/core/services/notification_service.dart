import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // ── Timezone fix: detect device timezone rather than defaulting to UTC ──
    // On Android, tz.local is always UTC unless explicitly set.
    // flutter_timezone reads the Android/iOS platform timezone (IANA name).
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      // If timezone lookup fails (e.g., permission denied or offline),
      // fall back gracefully — notifications will use UTC but won't crash.
      debugPrint('[NotificationService] Timezone lookup failed: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
    _initialized = true;
  }

  Future<void> scheduleSessionExpiryNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await init();

    // Guard: don't try to schedule a notification in the past.
    if (scheduledDate.isBefore(DateTime.now())) return;

    // ── Android 12+ exact alarm permission guard ──
    // AndroidScheduleMode.exactAllowWhileIdle requires SCHEDULE_EXACT_ALARM
    // permission on Android 12+. If it hasn't been granted, fall back to
    // inexactAllowWhileIdle which doesn't need the permission and works on
    // all Android versions including very old ones.
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? canScheduleExact =
            await androidPlugin.canScheduleExactNotifications();
        if (canScheduleExact == true) {
          scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        }
      }
    } catch (_) {
      // Older Flutter Local Notifications versions may not have this API.
      // Safe to ignore — we already default to inexact.
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'session_recovery_channel',
            'Session Recovery',
            channelDescription: 'Alerts for expiring exam sessions',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: scheduleMode,
      );
    } catch (e) {
      // Swallow scheduling errors silently — the exam still works without
      // the notification (it's a convenience feature, not critical path).
      debugPrint('[NotificationService] Failed to schedule notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) return; // Can't cancel if never initialized
    try {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (_) {
      // Ignore cancel errors — the notification may have already fired.
    }
  }
}
