import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final TextEditingController _systolicController = TextEditingController(text: '120');
  final TextEditingController _diastolicController = TextEditingController(text: '80');
  final TextEditingController _heartRateController = TextEditingController(text: '72');
  final TextEditingController _noteController = TextEditingController();

  // Mock tags for UI
  final List<Map<String, dynamic>> _tags = [
    {'name': '咖啡', 'icon': FontAwesomeIcons.mugHot, 'selected': true},
    {'name': '运动', 'icon': FontAwesomeIcons.personRunning, 'selected': false},
    {'name': '服药', 'icon': FontAwesomeIcons.pills, 'selected': false},
    {'name': '熬夜', 'icon': FontAwesomeIcons.bed, 'selected': false},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
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
                textStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
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
            onPressed: () {
              // TODO: Implement save logic
              Navigator.pop(context);
            },
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
                const Icon(FontAwesomeIcons.calendar, color: Colors.blue, size: 20),
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
                const Icon(FontAwesomeIcons.clock, color: Colors.blue, size: 20),
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
              textStyle: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color[300]!, color[500]!],
              ),
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
                  child: Icon(FontAwesomeIcons.heartPulse, color: Colors.red, size: 18),
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
    );
  }

  Widget _buildTagsSection() {
    return Column(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.blue[200]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tag['icon'] as IconData,
                        size: 14,
                        color: isSelected ? Colors.blue[600] : Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag['name'] as String,
                        style: GoogleFonts.notoSans(
                          textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.blue[600] : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid, // Dashed border is tricky without custom painter, using solid for now or specialized package
                ),
              ),
              child: const Center(
                child: Icon(FontAwesomeIcons.plus, size: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
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
          style: GoogleFonts.notoSans(
            textStyle: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
