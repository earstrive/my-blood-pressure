import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:my_first_app/services/database_helper.dart';
import 'package:my_first_app/services/notification_service.dart';

class SettingsState {
  final bool reminderEnabled;
  final TimeOfDay reminderTime;

  SettingsState({required this.reminderEnabled, required this.reminderTime});

  SettingsState copyWith({bool? reminderEnabled, TimeOfDay? reminderTime}) {
    return SettingsState(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
    : super(
        SettingsState(
          reminderEnabled: true,
          reminderTime: const TimeOfDay(hour: 21, minute: 0),
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    final enabledResult = await db.query(
      'app_kv',
      where: 'key = ?',
      whereArgs: ['reminder_enabled'],
    );
    final timeResult = await db.query(
      'app_kv',
      where: 'key = ?',
      whereArgs: ['reminder_time'],
    );

    bool enabled = true;
    TimeOfDay time = const TimeOfDay(hour: 21, minute: 0);

    if (enabledResult.isNotEmpty) {
      enabled = enabledResult.first['value'] == '1';
    }

    if (timeResult.isNotEmpty) {
      final timeStr = timeResult.first['value'] as String;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        time = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    state = SettingsState(reminderEnabled: enabled, reminderTime: time);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    state = state.copyWith(reminderEnabled: enabled);
    await _saveSetting('reminder_enabled', enabled ? '1' : '0');
    _updateNotification();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    await _saveSetting('reminder_time', '${time.hour}:${time.minute}');
    _updateNotification();
  }

  Future<void> _saveSetting(String key, String value) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    await db.insert('app_kv', {
      'key': key,
      'value': value,
      'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _updateNotification() async {
    final notificationService = NotificationService();
    if (state.reminderEnabled) {
      await notificationService.scheduleDailyReminder(
        id: 1,
        title: '记得测量血压',
        body: '晚上好！现在是测量血压的最佳时间。',
        time: state.reminderTime,
      );
    } else {
      await notificationService.cancelNotification(1);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
