import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_first_app/models/blood_pressure_record.dart';
import 'package:my_first_app/providers/record_provider.dart';
import 'package:my_first_app/providers/settings_provider.dart';
import 'package:my_first_app/services/database_helper.dart';
import 'package:my_first_app/services/notification_service.dart';

class AddRecordScreen extends ConsumerStatefulWidget {
  const AddRecordScreen({super.key});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final TextEditingController _systolicController = TextEditingController(
    text: '120',
  );
  final TextEditingController _diastolicController = TextEditingController(
    text: '80',
  );
  final TextEditingController _heartRateController = TextEditingController(
    text: '72',
  );
  final TextEditingController _noteController = TextEditingController();

  // Mock tags for UI
  List<Map<String, dynamic>> _tags = [];

  Future<void> _saveRecord() async {
    final int? systolic = int.tryParse(_systolicController.text);
    final int? diastolic = int.tryParse(_diastolicController.text);
    final int? heartRate = int.tryParse(_heartRateController.text);

    if (systolic == null || diastolic == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的收缩压和舒张压')));
      return;
    }

    // Validation for realistic values
    if (systolic < 50 || systolic > 300) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('收缩压数值异常 (50-300)，请检查输入')));
      return;
    }

    if (diastolic < 30 || diastolic > 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('舒张压数值异常 (30-200)，请检查输入')));
      return;
    }

    if (systolic <= diastolic) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('收缩压必须大于舒张压')));
      return;
    }

    final DateTime measureTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final record = BloodPressureRecord(
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate,
      measureTimeMs: measureTime.millisecondsSinceEpoch,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    final dbHelper = DatabaseHelper.instance;
    final recordId = await dbHelper.createRecord(record);

    // Save tags
    for (var tagMap in _tags) {
      if (tagMap['selected'] as bool) {
        final tagId = tagMap['id'] as int?;
        if (tagId != null) {
          await dbHelper.addTagToRecord(recordId, tagId);
        }
      }
    }

    // Smart Reminder: If record is for today, skip today's reminder
    final settings = ref.read(settingsProvider);
    if (settings.reminderEnabled) {
      final now = DateTime.now();
      if (_selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day) {
        await NotificationService().rescheduleDailyReminder(
          id: 1,
          title: '记得测量血压',
          body: '晚上好！现在是测量血压的最佳时间。',
          time: settings.reminderTime,
          skipToday: true,
        );
      }
    }

    if (mounted) {
      ref.invalidate(recordsProvider);
      ref.invalidate(dailyAverageProvider);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _loadTags();
  }

  Future<void> _loadTags({Set<int>? selectedIds}) async {
    final dbHelper = DatabaseHelper.instance;
    final tags = await dbHelper.getAllTags();

    // Preserve selection
    final idsToSelect =
        selectedIds ??
        _tags
            .where((t) => t['selected'] as bool)
            .map((t) => t['id'] as int)
            .toSet();

    if (mounted) {
      setState(() {
        _tags = tags.map((tag) {
          IconData icon;
          // Map tag name to icon
          switch (tag.name) {
            case '咖啡':
              icon = FontAwesomeIcons.mugHot;
              break;
            case '运动':
              icon = FontAwesomeIcons.personRunning;
              break;
            case '服药':
              icon = FontAwesomeIcons.pills;
              break;
            case '熬夜':
              icon = FontAwesomeIcons.bed;
              break;
            default:
              icon = FontAwesomeIcons.tag;
          }

          return {
            'id': tag.id,
            'name': tag.name,
            'icon': icon,
            'selected': idsToSelect.contains(tag.id),
            'color': tag.color,
          };
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
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
            // Main Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDateTimePicker(),
                    const SizedBox(height: 24),
                    _buildReadingsInputs(),
                    const SizedBox(height: 24),
                    _buildHeartRateInput(),
                    const SizedBox(height: 24),
                    _buildTagsSection(),
                    const SizedBox(height: 24),
                    _buildNoteSection(),
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: GoogleFonts.notoSans(
                textStyle: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
          Text(
            '新增记录',
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: _saveRecord,
            child: Text(
              '保存',
              style: GoogleFonts.notoSans(
                textStyle: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    final dateFormat = DateFormat('MM月dd日', 'zh_CN');

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.calendar,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(_selectedDate),
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _pickTime,
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.clock,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedTime.format(context),
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsInputs() {
    return Row(
      children: [
        Expanded(
          child: _buildPressureInput(
            label: '收缩压',
            controller: _systolicController,
            color: Colors.green, // Gradient simulated with bottom border color
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPressureInput(
            label: '舒张压',
            controller: _diastolicController,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPressureInput({
    required String label,
    required TextEditingController controller,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            label,
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'mmHg',
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color[300]!, color[500]!]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateInput() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    FontAwesomeIcons.heartPulse,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '心率',
                style: GoogleFonts.notoSans(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _heartRateController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'BPM',
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

  Widget _buildTagsSection() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '标签',
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map((tag) {
                final isSelected = tag['selected'] as bool;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      tag['selected'] = !isSelected;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue[200]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tag['icon'] as IconData,
                          size: 14,
                          color: isSelected
                              ? Colors.blue[600]
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag['name'] as String,
                          style: GoogleFonts.notoSans(
                            textStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.blue[600]
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '备注',
          style: GoogleFonts.notoSans(
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '添加备注...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
          style: GoogleFonts.notoSans(textStyle: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
