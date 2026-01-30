import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_first_app/providers/settings_provider.dart';
import 'package:my_first_app/services/database_helper.dart';
import 'package:my_first_app/services/notification_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:my_first_app/screens/tag_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final List<_AvatarOption> _avatarOptions = const [
    _AvatarOption(
      key: 'default',
      icon: FontAwesomeIcons.user,
      color: Color(0xFF90A4AE),
    ),
    _AvatarOption(
      key: 'heart',
      icon: FontAwesomeIcons.heartPulse,
      color: Color(0xFFE57373),
    ),
    _AvatarOption(
      key: 'stethoscope',
      icon: FontAwesomeIcons.stethoscope,
      color: Color(0xFF64B5F6),
    ),
    _AvatarOption(
      key: 'leaf',
      icon: FontAwesomeIcons.leaf,
      color: Color(0xFF81C784),
    ),
  ];

  Future<void> _testNotification() async {
    try {
      final ns = NotificationService();
      await ns.showNotification(
        id: 999,
        title: '测试通知',
        body: '这是一条测试通知，证明通知功能正常工作。',
      );

      final permInfo = await ns.getPermissionDebugInfo();

      if (mounted) {
        final debugInfo = ns.debugInfo;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试通知已发送\n$permInfo\n$debugInfo'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发送失败: $e')));
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final records = await DatabaseHelper.instance.readAllRecords();

      List<List<dynamic>> rows = [];
      // Header
      rows.add([
        'ID',
        'Date',
        'Time',
        'Systolic (mmHg)',
        'Diastolic (mmHg)',
        'Heart Rate (bpm)',
        'Note',
        'Tags',
        'Created At',
      ]);

      for (var record in records) {
        final date = DateTime.fromMillisecondsSinceEpoch(record.measureTimeMs);
        final tags = await DatabaseHelper.instance.getTagsForRecord(record.id!);
        final tagNames = tags.map((t) => t.name).join(',');
        rows.add([
          record.id,
          DateFormat('yyyy-MM-dd').format(date),
          DateFormat('HH:mm').format(date),
          record.systolic,
          record.diastolic,
          record.heartRate ?? '',
          record.note ?? '',
          tagNames,
          DateTime.fromMillisecondsSinceEpoch(
            record.createdAtMs,
          ).toIso8601String(),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/blood_pressure_data_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: '我的血压记录'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildProfileSection(),
                    _buildRemindersSection(),
                    _buildDataSection(),
                    _buildAppSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Text(
        '设置',
        style: GoogleFonts.notoSans(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final settings = ref.watch(settingsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: InkWell(
        onTap: _showEditProfileDialog,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            _buildProfileAvatar(settings.profileAvatar),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.profileName,
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '编辑资料',
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String avatarKey) {
    final settings = ref.read(settingsProvider);
    final customPath = settings.profileAvatarPath;
    if (avatarKey == 'custom' &&
        customPath != null &&
        customPath.isNotEmpty &&
        File(customPath).existsSync()) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(child: Image.file(File(customPath), fit: BoxFit.cover)),
      );
    }

    if (avatarKey == SettingsNotifier.defaultProfileAvatar) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage('assets/images/avatar.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final option = _avatarOptions.firstWhere(
      (o) => o.key == avatarKey,
      orElse: () => _avatarOptions.first,
    );
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: option.color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(option.icon, color: option.color, size: 24)),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final nameController = TextEditingController(text: settings.profileName);
    String selectedAvatar = settings.profileAvatar;
    String? customAvatarPath = settings.profileAvatarPath;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                '编辑资料',
                style: GoogleFonts.notoSans(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '昵称',
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '头像',
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final pickedPath = await _pickAvatarImage();
                          if (pickedPath == null) {
                            return;
                          }
                          setState(() {
                            customAvatarPath = pickedPath;
                            selectedAvatar = 'custom';
                          });
                        },
                        icon: const Icon(FontAwesomeIcons.image, size: 14),
                        label: const Text('上传图片'),
                      ),
                      const SizedBox(width: 8),
                      if (customAvatarPath != null &&
                          customAvatarPath!.isNotEmpty &&
                          File(customAvatarPath!).existsSync())
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue[500]!,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.file(
                              File(customAvatarPath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _avatarOptions.map((option) {
                      final isSelected = selectedAvatar == option.key;
                      final isDefault =
                          option.key == SettingsNotifier.defaultProfileAvatar;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAvatar = option.key;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDefault
                                ? Colors.grey[200]
                                : option.color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue[500]!
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isDefault
                                ? ClipOval(
                                    child: Image.asset(
                                      'assets/images/avatar.jpg',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    option.icon,
                                    color: option.color,
                                    size: 20,
                                  ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await notifier.resetProfile();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('恢复默认'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final nextName = name.isEmpty
                        ? SettingsNotifier.defaultProfileName
                        : name;
                    await notifier.setProfileName(nextName);
                    if (selectedAvatar == 'custom' &&
                        customAvatarPath != null &&
                        customAvatarPath!.isNotEmpty) {
                      await notifier.setProfileAvatar('custom');
                      await notifier.setProfileAvatarPath(customAvatarPath);
                    } else {
                      await notifier.setProfileAvatar(selectedAvatar);
                      await notifier.setProfileAvatarPath(null);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _pickAvatarImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) {
      return null;
    }
    final directory = await getApplicationDocumentsDirectory();
    final extension = p.extension(picked.path);
    final fileName =
        'profile_avatar_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = p.join(directory.path, fileName);
    final savedFile = await File(picked.path).copy(targetPath);
    return savedFile.path;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 24, 12),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          title,
          style: GoogleFonts.notoSans(
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Column(
      children: [
        _buildSectionTitle('通知提醒'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildListItem(
                  icon: FontAwesomeIcons.bell,
                  iconColor: Colors.blue[500]!,
                  iconBgColor: Colors.blue[50]!,
                  title: '每日提醒',
                  trailing: CupertinoSwitch(
                    value: settings.reminderEnabled,
                    activeTrackColor: Colors.blue[500],
                    onChanged: (value) {
                      settingsNotifier.setReminderEnabled(value);
                    },
                  ),
                  showBorder: true,
                ),
                _buildListItem(
                  icon: FontAwesomeIcons.clock,
                  iconColor: Colors.grey[400]!,
                  iconBgColor: Colors.transparent,
                  title: '提醒时间',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${settings.reminderTime.hour.toString().padLeft(2, '0')}:${settings.reminderTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.notoSans(
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  showBorder: true,
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: settings.reminderTime,
                    );
                    if (picked != null && picked != settings.reminderTime) {
                      await settingsNotifier.setReminderTime(picked);
                      if (!mounted) {
                        return;
                      }
                      final hh = picked.hour.toString().padLeft(2, '0');
                      final mm = picked.minute.toString().padLeft(2, '0');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.blue[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          content: Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.bell,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '提醒时间已更新为 $hh:$mm',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
                if (false)
                  _buildListItem(
                    icon: FontAwesomeIcons.bell,
                    iconColor: Colors.blue[500]!,
                    iconBgColor: Colors.transparent,
                    title: '测试通知',
                    trailing: const Icon(
                      FontAwesomeIcons.chevronRight,
                      size: 14,
                      color: Colors.grey,
                    ),
                    showBorder: false,
                    onTap: _testNotification,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      children: [
        _buildSectionTitle('数据管理'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildListItem(
                  icon: FontAwesomeIcons.tags,
                  iconColor: Colors.blue[500]!,
                  iconBgColor: Colors.blue[50]!,
                  title: '标签管理',
                  trailing: const Icon(
                    FontAwesomeIcons.chevronRight,
                    size: 14,
                    color: Colors.grey,
                  ),
                  showBorder: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TagManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildListItem(
                  icon: FontAwesomeIcons.fileExport,
                  iconColor: Colors.green[500]!,
                  iconBgColor: Colors.green[50]!,
                  title: '导出 CSV',
                  trailing: const Icon(
                    FontAwesomeIcons.chevronRight,
                    size: 14,
                    color: Colors.grey,
                  ),
                  showBorder: true,
                  onTap: _exportData,
                ),
                if (false)
                  _buildListItem(
                    icon: FontAwesomeIcons.cloudArrowUp,
                    iconColor: Colors.purple[500]!,
                    iconBgColor: Colors.purple[50]!,
                    title: '数据备份',
                    trailing: const Icon(
                      FontAwesomeIcons.chevronRight,
                      size: 14,
                      color: Colors.grey,
                    ),
                    showBorder: false,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppSection() {
    return Column(
      children: [
        _buildSectionTitle('更多'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (false)
                  _buildListItem(
                    icon: FontAwesomeIcons.star,
                    iconColor: Colors.orange[500]!,
                    iconBgColor: Colors.orange[50]!,
                    title: '去评分',
                    trailing: const Icon(
                      FontAwesomeIcons.chevronRight,
                      size: 14,
                      color: Colors.grey,
                    ),
                    showBorder: true,
                    onTap: () {},
                  ),
                _buildListItem(
                  icon: FontAwesomeIcons.circleInfo,
                  iconColor: Colors.grey[500]!,
                  iconBgColor: Colors.grey[100]!,
                  title: '关于我们',
                  trailing: Text(
                    'v1.0.0',
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  showBorder: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required Widget trailing,
    required bool showBorder,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ), // Adjusted padding to match HTML feel
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarOption {
  final String key;
  final IconData icon;
  final Color color;

  const _AvatarOption({
    required this.key,
    required this.icon,
    required this.color,
  });
}
