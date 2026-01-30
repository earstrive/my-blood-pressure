import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:my_first_app/services/database_helper.dart';
import 'package:my_first_app/services/notification_service.dart';

class SettingsState {
  final bool reminderEnabled;
  final TimeOfDay reminderTime;
  final String profileName;
  final String profileAvatar;
  final String? profileAvatarPath;

  SettingsState({
    required this.reminderEnabled,
    required this.reminderTime,
    required this.profileName,
    required this.profileAvatar,
    required this.profileAvatarPath,
  });

  SettingsState copyWith({
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    String? profileName,
    String? profileAvatar,
    String? profileAvatarPath,
  }) {
    return SettingsState(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      profileName: profileName ?? this.profileName,
      profileAvatar: profileAvatar ?? this.profileAvatar,
      profileAvatarPath: profileAvatarPath ?? this.profileAvatarPath,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const defaultProfileName = '耳朵Strive';
  static const defaultProfileAvatar = 'default';

  SettingsNotifier()
    : super(
        SettingsState(
          reminderEnabled: true,
          reminderTime: const TimeOfDay(hour: 21, minute: 0),
          profileName: defaultProfileName,
          profileAvatar: defaultProfileAvatar,
          profileAvatarPath: null,
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
    final nameResult = await db.query(
      'app_kv',
      where: 'key = ?',
      whereArgs: ['profile_name'],
    );
    final avatarResult = await db.query(
      'app_kv',
      where: 'key = ?',
      whereArgs: ['profile_avatar'],
    );
    final avatarPathResult = await db.query(
      'app_kv',
      where: 'key = ?',
      whereArgs: ['profile_avatar_path'],
    );

    bool enabled = true;
    TimeOfDay time = const TimeOfDay(hour: 21, minute: 0);
    String profileName = defaultProfileName;
    String profileAvatar = defaultProfileAvatar;
    String? profileAvatarPath;

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

    if (nameResult.isNotEmpty) {
      profileName = nameResult.first['value'] as String;
    }

    if (avatarResult.isNotEmpty) {
      profileAvatar = avatarResult.first['value'] as String;
    }

    if (avatarPathResult.isNotEmpty) {
      profileAvatarPath = avatarPathResult.first['value'] as String;
    }

    state = SettingsState(
      reminderEnabled: enabled,
      reminderTime: time,
      profileName: profileName,
      profileAvatar: profileAvatar,
      profileAvatarPath: profileAvatarPath,
    );
  }

  Future<void> setReminderEnabled(bool enabled) async {
    state = state.copyWith(reminderEnabled: enabled);
    await _saveSetting('reminder_enabled', enabled ? '1' : '0');
    _updateNotification();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    await _saveSetting('reminder_time', '${time.hour}:${time.minute}');
    await _updateNotification();
  }

  Future<void> setProfileName(String name) async {
    state = state.copyWith(profileName: name);
    await _saveSetting('profile_name', name);
  }

  Future<void> setProfileAvatar(String avatarKey) async {
    state = state.copyWith(profileAvatar: avatarKey);
    await _saveSetting('profile_avatar', avatarKey);
  }

  Future<void> setProfileAvatarPath(String? path) async {
    state = state.copyWith(profileAvatarPath: path);
    await _saveSetting('profile_avatar_path', path ?? '');
  }

  Future<void> resetProfile() async {
    state = state.copyWith(
      profileName: defaultProfileName,
      profileAvatar: defaultProfileAvatar,
      profileAvatarPath: null,
    );
    await _saveSetting('profile_name', defaultProfileName);
    await _saveSetting('profile_avatar', defaultProfileAvatar);
    await _saveSetting('profile_avatar_path', '');
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
