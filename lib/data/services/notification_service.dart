import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_strings.dart';
import 'hive_service.dart';
import 'notification_planner.dart';

/// OS-scheduled Daily Quiz reminders. No FCM, no OneSignal, no network.
///
/// All public methods are safe to fire-and-forget: they no-op on web /
/// desktop, swallow plugin errors, and must never be `await`ed before
/// `runApp` (see AGENTS.md §3).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'quizbaaz_daily_reminders';

  /// Hive keys — same strings [UserProvider] already persists.
  static const settingNotifications = 'setting_notifications';
  static const settingVibration = 'setting_vibration';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Android + iOS only. Everywhere else the calls below are no-ops.
  static bool get isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  /// After the first frame: init the plugin, ask for permission if the
  /// setting is on, then (re)build the 14-day window.
  Future<void> bootstrap() async {
    if (!isSupported) return;
    try {
      await _ensureReady().timeout(const Duration(seconds: 5));
      await syncFromHive();
    } catch (e) {
      debugPrint('NotificationService: bootstrap failed – $e');
    }
  }

  /// Rebuilds the reminder window from Hive. Language, settings, and a
  /// finished Daily Quiz all land here so we never import [UserProvider]
  /// (that would cycle).
  Future<void> syncFromHive() async {
    if (!isSupported) return;
    final enabled =
        HiveService.getMeta<bool>(settingNotifications) ?? true;
    final vibrate = HiveService.getMeta<bool>(settingVibration) ?? false;
    final user = HiveService.loadUser();
    user?.refreshDailyFlags(DateTime.now());
    await sync(
      enabled: enabled,
      playedToday: user?.playedTodayDailyQuiz ?? false,
      streak: user?.dailyStreak ?? 0,
      vibrate: vibrate,
    );
  }

  Future<void> sync({
    required bool enabled,
    required bool playedToday,
    required int streak,
    required bool vibrate,
  }) async {
    if (!isSupported) return;
    try {
      await _ensureReady();
      if (!enabled) {
        await _plugin.cancelAll();
        return;
      }
      final allowed = await requestPermission();
      if (!allowed) {
        await _plugin.cancelAll();
        return;
      }
      await _plugin.cancelAll();
      await _scheduleWindow(
        playedToday: playedToday,
        streak: streak,
        vibrate: vibrate,
      );
    } catch (e) {
      debugPrint('NotificationService: sync failed – $e');
    }
  }

  /// Android 13+ / iOS runtime prompt. Returns true when we may post.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      await _ensureReady();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService: permission failed – $e');
      return false;
    }
    return false;
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final id = await _localTimezoneId();
    try {
      tz.setLocalLocation(tz.getLocation(id));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    _ready = true;
  }

  Future<String> _localTimezoneId() async {
    try {
      final dynamic result = await FlutterTimezone.getLocalTimezone();
      if (result is String && result.isNotEmpty) return result;
      final id = result.identifier;
      if (id is String && id.isNotEmpty) return id;
    } catch (e) {
      debugPrint('NotificationService: timezone plugin – $e');
    }
    return 'Asia/Kolkata';
  }

  Future<void> _scheduleWindow({
    required bool playedToday,
    required int streak,
    required bool vibrate,
  }) async {
    final fires = NotificationPlanner.upcomingReminders(
      now: DateTime.now(),
      playedToday: playedToday,
    );
    final title =
        streak > 0 ? S.notifStreakTitle : S.notifDailyTitle;
    final body = streak > 0
        ? S.notifStreakBody(n: streak)
        : S.notifDailyBody;

    final android = AndroidNotificationDetails(
      _channelId,
      S.notifChannelName,
      channelDescription: S.notifChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: vibrate,
      icon: '@mipmap/ic_launcher',
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    );
    final details = NotificationDetails(android: android, iOS: darwin);

    for (final when in fires) {
      final scheduled = tz.TZDateTime(
        tz.local,
        when.year,
        when.month,
        when.day,
        when.hour,
        when.minute,
      );
      await _plugin.zonedSchedule(
        id: NotificationPlanner.notificationIdFor(when),
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'daily_quiz',
      );
    }
  }
}
