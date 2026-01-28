import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_first_app/models/blood_pressure_record.dart';
import 'package:my_first_app/services/database_helper.dart';

class TagManagementScreen extends ConsumerStatefulWidget {
  const TagManagementScreen({super.key});

  @override
  ConsumerState<TagManagementScreen> createState() =>
      _TagManagementScreenState();
}

class _TagManagementScreenState extends ConsumerState<TagManagementScreen> {
  List<Tag> _tags = [];
  bool _isLoading = true;

  final List<Color> _presetColors = [
    const Color(0xFF795548), // Brown
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFF44336), // Red
    const Color(0xFFFF9800), // Orange
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFFE91E63), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final tags = await DatabaseHelper.instance.getAllTags();
    if (mounted) {
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确定要删除标签"${tag.name}"吗？这将不会影响已保存的记录。'),
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

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteTag(tag.id!);
      _loadTags();
    }
  }

  Future<void> _showTagDialog({Tag? tag}) async {
    final isEditing = tag != null;
    final controller = TextEditingController(text: tag?.name);
    Color selectedColor =
        tag?.color != null ? Color(tag!.color!) : _presetColors[0];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? '编辑标签' : '新增标签'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '标签名称',
                    hintText: '请输入标签名称',
                  ),
                  autofocus: !isEditing,
                ),
                const SizedBox(height: 16),
                const Text('选择颜色:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                        child: selectedColor == color
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    try {
                      if (isEditing) {
                        final updatedTag = Tag(
                          id: tag.id,
                          name: name,
                          color: selectedColor.toARGB32(),
                          createdAtMs: tag.createdAtMs,
                        );
                        await DatabaseHelper.instance.updateTag(updatedTag);
                      } else {
                        final newTag = Tag(
                          name: name,
                          color: selectedColor.toARGB32(),
                          createdAtMs: DateTime.now().millisecondsSinceEpoch,
                        );
                        await DatabaseHelper.instance.createTag(newTag);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadTags();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('操作失败: 可能标签名已存在')),
                        );
                      }
                    }
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '标签管理',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                final color = tag.color != null
                    ? Color(tag.color!)
                    : Colors.blue;

                IconData icon;
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

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    title: Text(
                      tag.name,
                      style: GoogleFonts.notoSans(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                          onPressed: () => _showTagDialog(tag: tag),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                          onPressed: () => _deleteTag(tag),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
