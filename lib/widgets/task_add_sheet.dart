import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'smart_voice_create_dialog.dart';
import 'custom_date_picker_modal.dart';
import 'pie_progress_indicator.dart';
import 'voice_record_sheet.dart';
import 'voice_note_player.dart';

class TaskAddSheet extends StatefulWidget {
  final String? targetEmployeeId;
  const TaskAddSheet({super.key, this.targetEmployeeId});

  @override
  State<TaskAddSheet> createState() => _TaskAddSheetState();
}

class _TaskAddSheetState extends State<TaskAddSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedCategory = 'No Category';
  DateTime? _selectedDate = DateTime.now();
  int _priority = 0;
  int _progress = 0;
  int _flagColor = 0;
  final List<String> _subtasks = [];
  String? _voiceNotePath;
  int? _voiceNoteDuration;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openVoiceRecorder() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceRecordSheet(),
    );
    if (result != null && result['path'] != null) {
      setState(() {
        _voiceNotePath = result['path'] as String;
        _voiceNoteDuration = result['duration'] as int?;
        if (_controller.text.trim().isEmpty) {
          _controller.text = 'Voice Note (${DateFormat('dd MMM, h:mm a').format(DateTime.now())})';
        }
      });
    }
  }

  void _showVoiceOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Voice Message Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Record actual audio or transcribe speech to text',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: const Color(0xFFEFF6FF),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                ),
                title: const Text(
                  'Record Voice Message (Audio)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                ),
                subtitle: const Text(
                  'Record your voice note directly (no typing needed)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryBlue, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _openVoiceRecorder();
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF475569), size: 22),
                ),
                title: const Text(
                  'Voice to Text (AI Transcribe)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                subtitle: const Text(
                  'Speak words to auto-fill title, date & category',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => const SmartVoiceCreateDialog(),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _submitTask() {
    final text = _controller.text.trim();
    if (text.isEmpty && _voiceNotePath == null) return;

    final finalTitle = text.isNotEmpty
        ? text
        : 'Voice Note (${DateFormat('dd MMM, h:mm a').format(DateTime.now())})';

    final provider = context.read<TaskProvider>();
    final List<Subtask> subtaskModels = _subtasks
        .map((s) => Subtask(id: DateTime.now().millisecondsSinceEpoch.toString() + s, title: s))
        .toList();

    if (widget.targetEmployeeId != null) {
      provider.assignTaskToEmployee(
        widget.targetEmployeeId!,
        title: finalTitle,
        category: _selectedCategory,
        dueDate: _selectedDate,
        priority: _priority,
        progress: _progress,
        flagColor: _flagColor,
        subtasks: subtaskModels,
        voiceNoteUrl: _voiceNotePath,
        voiceDurationSeconds: _voiceNoteDuration,
      );
    } else {
      provider.addTask(
        title: finalTitle,
        category: _selectedCategory,
        dueDate: _selectedDate,
        priority: _priority,
        progress: _progress,
        flagColor: _flagColor,
        subtasks: subtaskModels,
        voiceNoteUrl: _voiceNotePath,
        voiceDurationSeconds: _voiceNoteDuration,
      );
    }

    Navigator.pop(context);
  }

  void _showCategoryPicker() {
    final provider = context.read<TaskProvider>();
    final categories = ['No Category', ...provider.categories.where((c) => c.name != 'All').map((c) => c.name)];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Select Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...categories.map(
                        (cat) => ListTile(
                          title: Text(cat),
                          trailing: _selectedCategory == cat ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.pop(ctx);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue),
                title: const Text('Create New Category', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateCategoryDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Category Name (e.g. Work)',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = catController.text.trim();
              if (val.isNotEmpty) {
                final provider = context.read<TaskProvider>();
                provider.addCategory(val, Icons.folder_rounded, AppTheme.primaryBlue);
                setState(() => _selectedCategory = val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomDatePickerModal(initialDate: _selectedDate),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked['date'] as DateTime?);
    }
  }

  void _showDetailsPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Task Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 24),
                  
                  const Text('Progress', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [0, 25, 50, 75, 100].map((val) {
                        final isSelected = _progress == val;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => _progress = val);
                            setState(() => _progress = val);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.transparent, width: 2),
                            ),
                            child: PieProgressIndicator(
                              value: val / 100,
                              size: 32,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Flag', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'id': 1, 'color': const Color(0xFFF43F5E)},
                        {'id': 2, 'color': const Color(0xFFF59E0B)},
                        {'id': 3, 'color': const Color(0xFFC084FC)},
                        {'id': 4, 'color': const Color(0xFF3B82F6)},
                        {'id': 5, 'color': const Color(0xFF10B981)},
                      ].map((c) {
                        final id = c['id'] as int;
                        final color = c['color'] as Color;
                        final isSelected = _flagColor == id;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => _flagColor = isSelected ? 0 : id);
                            setState(() => _flagColor = isSelected ? 0 : id);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 20),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                            ),
                            child: Icon(Icons.flag_rounded, color: color, size: 28),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildPriorityOption(BuildContext ctx, int level, String title, IconData icon, Color color, Color bgColor) {
    final isSelected = _priority == level;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () {
          setState(() => _priority = level);
          Navigator.pop(ctx);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : bgColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? color : const Color(0xFF334155),
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubtasksSheet() {
    final subtaskController = TextEditingController();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(top: 16, left: 20, right: 20, bottom: bottomInset + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.checklist_rounded, color: AppTheme.primaryBlue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Sub-tasks Checklist',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_subtasks.isNotEmpty) ...[
                  ..._subtasks.asMap().entries.map((entry) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outline_blank_rounded, color: Color(0xFF94A3B8), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(entry.value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _subtasks.removeAt(entry.key));
                            setSheetState(() {});
                          },
                          child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subtaskController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Type subtask step...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() => _subtasks.add(val.trim()));
                            setSheetState(() {});
                            subtaskController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        if (subtaskController.text.trim().isNotEmpty) {
                          setState(() => _subtasks.add(subtaskController.text.trim()));
                          setSheetState(() {});
                          subtaskController.clear();
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    final sheetContent = Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 680 : double.infinity),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      padding: EdgeInsets.only(
        top: isDesktop ? 24 : 20,
        left: isDesktop ? 28 : 20,
        right: isDesktop ? 28 : 20,
        bottom: bottomInset + (isDesktop ? 24 : 16),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Box with rounded background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FD),
                borderRadius: BorderRadius.circular(16),
              ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    cursorColor: const Color(0xFF38BDF8),
                    cursorWidth: 2,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Yoga class at 6 tonight',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _submitTask(),
                  ),
                ),
                // Mic + Sparkle Icon
                IconButton(
                  icon: Icon(
                    _voiceNotePath != null ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _voiceNotePath != null ? AppTheme.primaryBlue : const Color(0xFF64748B),
                    size: 24,
                  ),
                  onPressed: _showVoiceOptionsModal,
                  tooltip: 'Voice Message or Speech to Text',
                ),
              ],
            ),
          ),
          if (_voiceNotePath != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: VoiceNotePlayerWidget(
                      audioPathOrUrl: _voiceNotePath!,
                      durationSeconds: _voiceNoteDuration,
                      isCompact: false,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _voiceNotePath = null;
                        _voiceNoteDuration = null;
                      });
                    },
                    tooltip: 'Remove voice note',
                  ),
                ],
              ),
            ),
          ],
          if (_subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _subtasks
                  .map(
                    (s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => setState(() => _subtasks.remove(s)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFDBEAFE))),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),

          // Action Toolbar Row
          Row(
            children: [
              // 1. Category Chip
              InkWell(
                onTap: _showCategoryPicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedCategory,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Calendar Date Picker Button (Shows current day)
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryBlue, size: 22),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _selectedDate != null ? DateFormat('d').format(_selectedDate!) : '-',
                          style: TextStyle(
                            color: _selectedDate != null ? AppTheme.primaryBlue : const Color(0xFF94A3B8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Priority / Flag Button (Interactive 1-Tap Picker)
              InkWell(
                onTap: _showDetailsPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: _priority > 0 ? 8 : 4, vertical: 4),
                  decoration: _priority > 0
                      ? BoxDecoration(
                          color: _priority == 3
                              ? const Color(0xFFFEE2E2)
                              : (_priority == 2 ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5)),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _priority == 0 ? Icons.flag_outlined : Icons.flag_rounded,
                        color: _priority == 0
                            ? const Color(0xFF64748B)
                            : (_priority == 1
                                ? const Color(0xFF10B981)
                                : (_priority == 2 ? const Color(0xFFF97316) : const Color(0xFFDC2626))),
                        size: 22,
                      ),
                      if (_priority > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          _priority == 3 ? 'High' : (_priority == 2 ? 'Med' : 'Low'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _priority == 3
                                ? const Color(0xFFDC2626)
                                : (_priority == 2 ? const Color(0xFFD97706) : const Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 4. Checklist / Subtasks Button (Interactive Checklist Builder)
              InkWell(
                onTap: _showSubtasksSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: _subtasks.isNotEmpty ? 8 : 4, vertical: 4),
                  decoration: _subtasks.isNotEmpty
                      ? BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        color: _subtasks.isNotEmpty ? AppTheme.primaryBlue : const Color(0xFF64748B),
                        size: 22,
                      ),
                      if (_subtasks.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${_subtasks.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 5. Voice Note Button (Direct Record Voice Note)
              InkWell(
                onTap: _openVoiceRecorder,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: _voiceNotePath != null ? 8 : 4, vertical: 4),
                  decoration: _voiceNotePath != null
                      ? BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _voiceNotePath != null ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _voiceNotePath != null ? AppTheme.primaryBlue : const Color(0xFF64748B),
                        size: 22,
                      ),
                      if (_voiceNotePath != null) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'Voice',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 6. Send / Submit Button
              Builder(
                builder: (context) {
                  final hasContent = _controller.text.trim().isNotEmpty || _voiceNotePath != null;
                  return InkWell(
                    onTap: _submitTask,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasContent ? AppTheme.primaryBlue : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                        boxShadow: hasContent
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );

  if (isDesktop) {
    return Center(child: sheetContent);
  }

  return Align(
    alignment: Alignment.bottomCenter,
    child: sheetContent,
  );
  }
}
