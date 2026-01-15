import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String _debugLog = '';
  String get debugInfo => 'Loc:${tz.local.name} | $_debugLog';

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      _debugLog += 'TZ init success; ';
    } catch (e) {
      _debugLog += 'TZ init fail: $e; ';
    }

    String timeZoneName;
    try {
      timeZoneName = await FlutterTimezone.getLocalTimezone();
      _debugLog += 'GetTZ: $timeZoneName; ';
    } catch (e) {
      // If the plugin fails (e.g. on Windows or if not rebuilt), fallback to Asia/Shanghai
      debugPrint('Could not get local timezone: $e');
      timeZoneName = 'Asia/Shanghai';
      _debugLog += 'GetTZ fail($e), fallback SH; ';
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _debugLog += 'SetLoc success; ';
    } catch (e) {
      // If the location name is invalid, fallback to UTC
      debugPrint('Could not set local location: $e');
      tz.setLocalLocation(tz.UTC);
      _debugLog += 'SetLoc fail($e), fallback UTC; ';
    }

    // Double check time consistency
    try {
      final now = DateTime.now();
      final tzNow = tz.TZDateTime.now(tz.local);
      final diff = now.hour - tzNow.hour;
      if (diff != 0) {
        _debugLog += 'TimeMismatch(Sys:${now.hour},TZ:${tzNow.hour}); ';
        // Simple heuristic fix for China users (+8)
        if (now.timeZoneOffset.inHours == 8) {
          try {
            tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
            _debugLog += 'Force fix to Asia/Shanghai; ';
          } catch (e) {
            _debugLog += 'Force fix fail; ';
          }
        }
      }
    } catch (e) {
      _debugLog += 'Check fail: $e; ';
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            // Handle notification tap
          },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_reminder_channel',
          '每日提醒',
          channelDescription: '提醒您测量血压',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> requestPermissions() async {
    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestNotificationsPermission();
      // Explicitly request exact alarm permission (Android 12+)
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  Future<bool> checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // Check if exact alarms are permitted
      return await androidPlugin?.requestExactAlarmsPermission() ?? false;
    }
    return true; // iOS usually allows
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
      // Ensure we have permission before scheduling
      await checkExactAlarmPermission();

      // Cancel previous schedules for this ID range (assuming 7 days)
      for (int i = 0; i < 7; i++) {
        await cancelNotification(id + i);
      }

      tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

      _debugLog += 'SchedBase: $scheduledDate; ';

      // Schedule for the next 7 days to avoid relying on repeating alarms which are unreliable on some ROMs
      for (int i = 0; i < 7; i++) {
        final nextDate = scheduledDate.add(Duration(days: i));

        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + i,
          title,
          body,
          nextDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_reminder_channel',
              '每日提醒',
              channelDescription: '提醒您测量血压',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          // Removed matchDateTimeComponents to use independent alarms
        );
      }
      _debugLog += 'Sched 7 days OK; ';
    } catch (e) {
      _debugLog += 'Sched Fail: $e; ';
      debugPrint('Error scheduling notification: $e');
      rethrow;
    }
  }

  Future<void> rescheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    bool skipToday = false,
  }) async {
    // Cancel existing
    for (int i = 0; i < 7; i++) {
      await cancelNotification(id + i);
    }

    var scheduledDate = _nextInstanceOfTime(time);

    if (skipToday) {
      final now = tz.TZDateTime.now(tz.local);
      // If the scheduled time is today, move it to tomorrow
      if (scheduledDate.year == now.year &&
          scheduledDate.month == now.month &&
          scheduledDate.day == now.day) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    _debugLog += 'ReSchedBase: $scheduledDate; ';

    // Schedule for 7 days
    for (int i = 0; i < 7; i++) {
      final nextDate = scheduledDate.add(Duration(days: i));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id + i,
        title,
        body,
        nextDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            '每日提醒',
            channelDescription: '提醒您测量血压',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    _debugLog += 'ReSched 7 days OK; ';
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        time.hour,
        time.minute,
      );
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<String> getPermissionDebugInfo() async {
    if (!Platform.isAndroid) return 'Platform: ${Platform.operatingSystem}';

    String info = 'Android: ';
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final bool? exactAlarm = await androidPlugin
          .requestExactAlarmsPermission();
      info += 'ExactAlarm=$exactAlarm; ';

      final bool? notifications = await androidPlugin.areNotificationsEnabled();
      info += 'NotifEnabled=$notifications; ';
    }

    return info;
  }
}
