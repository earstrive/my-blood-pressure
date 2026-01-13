import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_first_app/providers/settings_provider.dart';
import 'package:my_first_app/services/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
        'Created At',
      ]);

      for (var record in records) {
        final date = DateTime.fromMillisecondsSinceEpoch(record.measureTimeMs);
        rows.add([
          record.id,
          DateFormat('yyyy-MM-dd').format(date),
          DateFormat('HH:mm').format(date),
          record.systolic,
          record.diastolic,
          record.heartRate ?? '',
          record.note ?? '',
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

      await Share.shareXFiles([XFile(path)], text: '我的血压记录');
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/avatar.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '耳朵Strive',
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
                  textStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                    activeColor: Colors.blue[500],
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
                  showBorder: false,
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: settings.reminderTime,
                    );
                    if (picked != null && picked != settings.reminderTime) {
                      settingsNotifier.setReminderTime(picked);
                    }
                  },
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
