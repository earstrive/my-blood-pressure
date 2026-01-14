import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermissions() async {
    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          '每日提醒',
          channelDescription: '提醒您测量血压',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> rescheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    bool skipToday = false,
  }) async {
    // Cancel existing
    await cancelNotification(id);

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

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          '每日提醒',
          channelDescription: '提醒您测量血压',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
