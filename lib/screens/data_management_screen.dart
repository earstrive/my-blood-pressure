import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_blood_pressure/models/blood_pressure_record.dart';
import 'package:my_blood_pressure/providers/record_provider.dart';
import 'package:my_blood_pressure/services/database_helper.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _showSearch = false;
  String _keyword = '';
  DateTimeRange? _range;

  static const int _daysPerPage = 7;
  int _dayOffset = 0;
  int? _selectedTagId;
  List<Tag> _tags = [];

  late Future<_PagedRecordsResult> _pageFuture;

  @override
  void initState() {
    super.initState();
    _loadTags();
    _pageFuture = _fetchPage();
  }

  Future<void> _loadTags() async {
    final tags = await DatabaseHelper.instance.getAllTags();
    if (!mounted) return;
    setState(() {
      _tags = tags;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadPage({bool resetOffset = false}) {
    setState(() {
      if (resetOffset) {
        _dayOffset = 0;
      }
      _pageFuture = _fetchPage();
    });
  }

  DateTimeRange _effectiveRange() {
    final now = DateTime.now();
    if (_range != null) return _range!;
    return DateTimeRange(
      start: DateTime(2020, 1, 1),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  Future<_PagedRecordsResult> _fetchPage() async {
    final range = _effectiveRange();
    final startMs = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    ).millisecondsSinceEpoch;
    final endMs = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;

    final keyword = _keyword.trim();

    final totalDays = await DatabaseHelper.instance.countDistinctRecordDays(
      startMs: startMs,
      endMs: endMs,
      tagId: _selectedTagId,
      keyword: keyword,
    );

    final dayStrings = await DatabaseHelper.instance
        .readDistinctRecordDayStringsPaged(
          startMs: startMs,
          endMs: endMs,
          tagId: _selectedTagId,
          keyword: keyword,
          limit: _daysPerPage,
          offset: _dayOffset,
        );

    final groups = <_DayGroup>[];
    for (final day in dayStrings) {
      final parsed = DateTime.tryParse(day);
      if (parsed == null) continue;
      final dayStart = DateTime(parsed.year, parsed.month, parsed.day);
      final dayStartMs = dayStart.millisecondsSinceEpoch;
      final dayEndMs = DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        23,
        59,
        59,
        999,
      ).millisecondsSinceEpoch;

      final records = await DatabaseHelper.instance.readRecordsInRange(
        startMs: dayStartMs,
        endMs: dayEndMs,
        tagId: _selectedTagId,
        keyword: keyword,
      );

      if (records.isEmpty) {
        continue;
      }

      groups.add(_DayGroup(day: dayStart, records: records));
    }

    return _PagedRecordsResult(totalDays: totalDays, groups: groups);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial =
        _range ??
        DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6)),
          end: DateTime(now.year, now.month, now.day),
        );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
      });
      _reloadPage(resetOffset: true);
    }
  }

  Future<void> _showDetails(BloodPressureRecord record) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final dt = DateTime.fromMillisecondsSinceEpoch(record.measureTimeMs);
        final createdAt = DateTime.fromMillisecondsSinceEpoch(
          record.createdAtMs,
        );
        final updatedAt = DateTime.fromMillisecondsSinceEpoch(
          record.updatedAtMs,
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: FutureBuilder<List<Tag>>(
              future: record.id == null
                  ? Future.value(<Tag>[])
                  : DatabaseHelper.instance.getTagsForRecord(record.id!),
              builder: (context, snapshot) {
                final tags = snapshot.data ?? const <Tag>[];
                final hasNote = (record.note ?? '').trim().isNotEmpty;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '记录详情',
                        style: GoogleFonts.notoSans(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _kv('收缩压', '${record.systolic} mmHg'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kv('舒张压', '${record.diastolic} mmHg'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _kv(
                              '心率',
                              record.heartRate == null
                                  ? '-'
                                  : '${record.heartRate} bpm',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kv(
                              '时间',
                              DateFormat('yyyy-MM-dd HH:mm').format(dt),
                            ),
                          ),
                        ],
                      ),
                      if (hasNote) ...[
                        const SizedBox(height: 12),
                        _kv('备注', record.note!.trim()),
                      ],
                      const SizedBox(height: 12),
                      _kv('标签', tags.isEmpty ? '-' : ''),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags.map((t) {
                            final color = t.color != null
                                ? Color(t.color!)
                                : Colors.blue;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                t.name,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _kv(
                              '创建',
                              DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kv(
                              '更新',
                              DateFormat('yyyy-MM-dd HH:mm').format(updatedAt),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _showEditDialog(record);
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('编辑'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await _confirmDelete(record);
                                if (confirmed != true) return;
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                await _deleteRecord(record);
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                '删除',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: GoogleFonts.notoSans(
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            v,
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BloodPressureRecord record) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定要删除这条记录吗？（ID: ${record.id ?? '-'}）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(BloodPressureRecord record) async {
    if (record.id == null) return;
    await DatabaseHelper.instance.deleteRecord(record.id!);
    ref.invalidate(recordsProvider);
    ref.invalidate(dailyAverageProvider);
    _reloadPage();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已删除'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Future<void> _showEditDialog(BloodPressureRecord record) async {
    if (record.id == null) return;

    final initialDt = DateTime.fromMillisecondsSinceEpoch(record.measureTimeMs);
    DateTime selectedDate = DateTime(
      initialDt.year,
      initialDt.month,
      initialDt.day,
    );
    TimeOfDay selectedTime = TimeOfDay(
      hour: initialDt.hour,
      minute: initialDt.minute,
    );

    final sysController = TextEditingController(
      text: record.systolic.toString(),
    );
    final diaController = TextEditingController(
      text: record.diastolic.toString(),
    );
    final hrController = TextEditingController(
      text: record.heartRate?.toString() ?? '',
    );
    final noteController = TextEditingController(text: record.note ?? '');

    final allTags = await DatabaseHelper.instance.getAllTags();
    final existingTags = await DatabaseHelper.instance.getTagsForRecord(
      record.id!,
    );
    final Set<int> selectedTagIds = existingTags
        .map((t) => t.id)
        .whereType<int>()
        .toSet();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                selectedDate = picked;
              });
            }
          }

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: selectedTime,
            );
            if (picked != null) {
              setState(() {
                selectedTime = picked;
              });
            }
          }

          return AlertDialog(
            title: const Text('编辑记录'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pickDate,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(selectedDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pickTime,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '收缩压'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: diaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '舒张压'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hrController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '心率（可选）'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: '备注（可选）'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '标签（可选）',
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags.map((tag) {
                      final tagId = tag.id;
                      final isSelected =
                          tagId != null && selectedTagIds.contains(tagId);
                      final color = tag.color != null
                          ? Color(tag.color!)
                          : Colors.blue;
                      return FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        selectedColor: color.withValues(alpha: 0.18),
                        checkmarkColor: color,
                        onSelected: tagId == null
                            ? null
                            : (v) {
                                setState(() {
                                  if (v) {
                                    selectedTagIds.add(tagId);
                                  } else {
                                    selectedTagIds.remove(tagId);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(this.context);
                  final navigator = Navigator.of(context);

                  final int? systolic = int.tryParse(sysController.text);
                  final int? diastolic = int.tryParse(diaController.text);
                  final int? heartRate = hrController.text.trim().isEmpty
                      ? null
                      : int.tryParse(hrController.text);

                  if (systolic == null || diastolic == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的收缩压和舒张压')),
                    );
                    return;
                  }

                  if (systolic < 50 || systolic > 300) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('收缩压数值异常 (50-300)，请检查输入')),
                    );
                    return;
                  }

                  if (diastolic < 30 || diastolic > 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('舒张压数值异常 (30-200)，请检查输入')),
                    );
                    return;
                  }

                  if (systolic <= diastolic) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('收缩压必须大于舒张压')));
                    return;
                  }

                  final measureTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  ).millisecondsSinceEpoch;

                  final updated = record.copyWith(
                    systolic: systolic,
                    diastolic: diastolic,
                    heartRate: heartRate,
                    measureTimeMs: measureTime,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
                  );

                  await DatabaseHelper.instance.updateRecord(updated);
                  await DatabaseHelper.instance.setTagsForRecord(
                    record.id!,
                    selectedTagIds.toList(),
                  );

                  ref.invalidate(recordsProvider);
                  ref.invalidate(dailyAverageProvider);
                  _reloadPage();

                  if (!mounted) return;

                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('已保存修改'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  );
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );

    sysController.dispose();
    diaController.dispose();
    hrController.dispose();
    noteController.dispose();
  }

  String _formatDayTitle(DateTime day) {
    return DateFormat('yyyy年M月d日').format(day);
  }

  Future<int?> _showTagPicker(List<Tag> tags) {
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择标签',
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(FontAwesomeIcons.tags, size: 18),
                  title: const Text('全部标签'),
                  trailing: _selectedTagId == null
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () => Navigator.pop(context, -1),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tags.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      final tagId = tag.id;
                      final color = tag.color != null
                          ? Color(tag.color!)
                          : Colors.blue;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withValues(alpha: 0.14),
                          child: Icon(
                            FontAwesomeIcons.tag,
                            size: 12,
                            color: color,
                          ),
                        ),
                        title: Text(tag.name),
                        trailing: tagId != null && tagId == _selectedTagId
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: tagId == null
                            ? null
                            : () => Navigator.pop(context, tagId),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    final chips = <Widget>[];

    if (_range != null) {
      final rangeText =
          '${DateFormat('yyyy-MM-dd').format(_range!.start)} ~ ${DateFormat('yyyy-MM-dd').format(_range!.end)}';
      chips.add(
        _filterPill(
          icon: FontAwesomeIcons.calendarDays,
          iconColor: Colors.blue[600]!,
          text: rangeText,
          onTap: _pickRange,
          onClear: () {
            setState(() {
              _range = null;
            });
            _reloadPage(resetOffset: true);
          },
        ),
      );
    }

    if (_selectedTagId != null) {
      Tag? selectedTag;
      for (final t in _tags) {
        if (t.id == _selectedTagId) {
          selectedTag = t;
          break;
        }
      }
      final tagText = selectedTag?.name ?? '标签';
      chips.add(
        _filterPill(
          icon: FontAwesomeIcons.tag,
          iconColor: Colors.indigo[600]!,
          text: tagText,
          onTap: () async {
            final tags = _tags.isEmpty
                ? await DatabaseHelper.instance.getAllTags()
                : _tags;
            if (!mounted) return;
            final picked = await _showTagPicker(tags);
            if (!mounted) return;
            if (picked == null) return;
            setState(() {
              _selectedTagId = picked == -1 ? null : picked;
            });
            _reloadPage(resetOffset: true);
          },
          onClear: () {
            setState(() {
              _selectedTagId = null;
            });
            _reloadPage(resetOffset: true);
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Wrap(spacing: 10, runSpacing: 10, children: chips),
    );
  }

  Widget _filterPill({
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayHeader(_DayGroup group) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _formatDayTitle(group.day),
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            '${group.records.length} 条',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(BloodPressureRecord record) {
    final dt = DateTime.fromMillisecondsSinceEpoch(record.measureTimeMs);
    final title = '${record.systolic}/${record.diastolic} mmHg';
    final subtitleParts = <String>[
      DateFormat('HH:mm').format(dt),
      if (record.heartRate != null) '心率 ${record.heartRate} bpm',
      if ((record.note ?? '').trim().isNotEmpty)
        '备注 ${(record.note ?? '').trim()}',
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => _showDetails(record),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Text(
            record.id?.toString() ?? '-',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSans(
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        subtitle: Text(
          subtitleParts.join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
              onPressed: () => _showEditDialog(record),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
              onPressed: () async {
                final confirmed = await _confirmDelete(record);
                if (confirmed == true) {
                  await _deleteRecord(record);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPager({required int currentPage, required int totalPages}) {
    final canPrev = _dayOffset > 0;
    final canNext = currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canPrev
                  ? () {
                      _dayOffset = _dayOffset >= _daysPerPage
                          ? _dayOffset - _daysPerPage
                          : 0;
                      _reloadPage();
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('上一页'),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currentPage / $totalPages',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canNext
                  ? () {
                      _dayOffset += _daysPerPage;
                      _reloadPage();
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('下一页'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '管理数据',
          style: GoogleFonts.notoSans(
            textStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: '筛选时间范围',
            onPressed: _pickRange,
            icon: const Icon(
              FontAwesomeIcons.calendarDays,
              size: 18,
              color: Colors.black,
            ),
          ),
          if (_range != null)
            IconButton(
              tooltip: '清除筛选',
              onPressed: () {
                setState(() {
                  _range = null;
                });
                _reloadPage(resetOffset: true);
              },
              icon: const Icon(Icons.filter_alt_off, color: Colors.black),
            ),
          IconButton(
            tooltip: '标签筛选',
            onPressed: () async {
              final tags = _tags.isEmpty
                  ? await DatabaseHelper.instance.getAllTags()
                  : _tags;
              if (!mounted) return;
              final picked = await _showTagPicker(tags);
              if (!mounted) return;
              if (picked == null) return;
              setState(() {
                _selectedTagId = picked == -1 ? null : picked;
              });
              _reloadPage(resetOffset: true);
            },
            icon: const Icon(
              FontAwesomeIcons.tag,
              size: 18,
              color: Colors.black,
            ),
          ),
          IconButton(
            tooltip: '搜索',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _keyword = '';
                  _reloadPage(resetOffset: true);
                }
              });
            },
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  setState(() => _keyword = v);
                  _reloadPage(resetOffset: true);
                },
                decoration: InputDecoration(
                  hintText: '按备注/ID 搜索',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
            ),
          if (_range != null || _selectedTagId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: _buildFilterBar(),
            ),
          Expanded(
            child: FutureBuilder<_PagedRecordsResult>(
              future: _pageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('加载失败: ${snapshot.error}'));
                }
                final data = snapshot.data;
                if (data == null || data.totalDays == 0) {
                  return const Center(child: Text('暂无数据'));
                }

                final totalPages =
                    (data.totalDays + _daysPerPage - 1) ~/ _daysPerPage;
                final currentPage = (_dayOffset ~/ _daysPerPage) + 1;

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        children: [
                          for (final g in data.groups) ...[
                            _buildDayHeader(g),
                            const SizedBox(height: 8),
                            for (final r in g.records) ...[
                              _buildRecordCard(r),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    _buildPager(
                      currentPage: currentPage,
                      totalPages: totalPages,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGroup {
  final DateTime day;
  final List<BloodPressureRecord> records;

  _DayGroup({required this.day, required this.records});
}

class _PagedRecordsResult {
  final int totalDays;
  final List<_DayGroup> groups;

  _PagedRecordsResult({required this.totalDays, required this.groups});
}
