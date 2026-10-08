import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'custom_date_picker_modal.dart';

class TaskEditSheet extends StatefulWidget {
  final Task task;

  const TaskEditSheet({super.key, required this.task});

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _newSubtaskController;

  late String _selectedCategory;
  DateTime? _selectedDate;
  late int _priority;
  String? _estimatedTime;
  late bool _isCompleted;
  late List<Subtask> _subtasks;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(text: widget.task.notes);
    _newSubtaskController = TextEditingController();

    _selectedCategory = widget.task.category;
    _selectedDate = widget.task.dueDate;
    _priority = widget.task.priority;
    _estimatedTime = widget.task.estimatedTime;
    _isCompleted = widget.task.isCompleted;
    _subtasks = widget.task.subtasks
        .map((s) => Subtask(id: s.id, title: s.title, isCompleted: s.isCompleted))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty) {
      widget.task.title = newTitle;
    }
    widget.task.notes = _notesController.text.trim();
    widget.task.category = _selectedCategory;
    widget.task.dueDate = _selectedDate;
    widget.task.priority = _priority;
    widget.task.estimatedTime = _estimatedTime;
    widget.task.isCompleted = _isCompleted;
    if (_isCompleted && widget.task.completedAt == null) {
      widget.task.completedAt = DateTime.now();
    } else if (!_isCompleted) {
      widget.task.completedAt = null;
    }
    widget.task.subtasks = _subtasks;

    context.read<TaskProvider>().updateTask(widget.task);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task updated successfully'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${widget.task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              context.read<TaskProvider>().deleteTask(widget.task.id);
              Navigator.pop(context); // Close bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted'),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
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

  void _showCategoryPicker() {
    final provider = context.read<TaskProvider>();
    final categories = ['No Category', ...provider.categories.where((c) => c.name != 'All').map((c) => c.name)];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Select Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showPriorityPicker() {
    final options = [
      {'val': 0, 'label': 'No Priority', 'color': Colors.grey, 'icon': Icons.flag_outlined},
      {'val': 1, 'label': 'Low Priority', 'color': Colors.blue, 'icon': Icons.flag_rounded},
      {'val': 2, 'label': 'Medium Priority', 'color': Colors.orange, 'icon': Icons.flag_rounded},
      {'val': 3, 'label': 'High Priority', 'color': Colors.red, 'icon': Icons.flag_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Select Priority', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...options.map((opt) {
              final val = opt['val'] as int;
              final isSel = _priority == val;
              return ListTile(
                leading: Icon(opt['icon'] as IconData, color: opt['color'] as Color),
                title: Text(opt['label'] as String, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                trailing: isSel ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                onTap: () {
                  setState(() => _priority = val);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEstimatedTimePicker() {
    final quickOptions = ['30 mins', '1 hour', '2 hours', '4 hours', '1 day', '2 days'];
    final timeCtrl = TextEditingController(text: _estimatedTime ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Estimated Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. 1 hour, 45 mins',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: quickOptions.map((opt) {
                return InkWell(
                  onTap: () => timeCtrl.text = opt,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(opt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _estimatedTime = null);
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _estimatedTime = timeCtrl.text.trim().isNotEmpty ? timeCtrl.text.trim() : null);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(Subtask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
          isCompleted: false,
        ));
        _newSubtaskController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 600 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Edit Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    // Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                      tooltip: 'Delete Task',
                      onPressed: _confirmDelete,
                    ),
                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 3. Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title Input
                      const Text(
                        'Task Title',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Enter task title...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Toggle (Complete / Pending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCompleted ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: _isCompleted ? const Color(0xFF059669) : const Color(0xFFD97706),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isCompleted ? 'Status: Completed' : 'Status: Pending',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _isCompleted ? const Color(0xFF059669) : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _isCompleted,
                              activeTrackColor: const Color(0xFF10B981),
                              onChanged: (val) => setState(() => _isCompleted = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Properties (Category, Due Date, Priority, Duration)
                      const Text(
                        'Details',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Category Chip
                          InkWell(
                            onTap: _showCategoryPicker,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF475569)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedCategory,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),

                          // Due Date Chip
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 15, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedDate != null
                                        ? DateFormat('EEE, d MMM yyyy').format(_selectedDate!)
                                        : 'No Due Date',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Priority Chip
                          InkWell(
                            onTap: _showPriorityPicker,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _priority == 3
                                    ? const Color(0xFFFEE2E2)
                                    : (_priority == 2
                                        ? const Color(0xFFFEF3C7)
                                        : (_priority == 1 ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9))),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _priority == 3
                                      ? Colors.redAccent
                                      : (_priority == 2 ? Colors.orangeAccent : Colors.blue.withValues(alpha: 0.3)),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    size: 15,
                                    color: _priority == 3
                                        ? Colors.red
                                        : (_priority == 2 ? Colors.orange : (_priority == 1 ? Colors.blue : Colors.grey)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _priority == 3
                                        ? 'High'
                                        : (_priority == 2 ? 'Medium' : (_priority == 1 ? 'Low' : 'No Priority')),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _priority == 3
                                          ? Colors.red
                                          : (_priority == 2 ? Colors.orange : (_priority == 1 ? Colors.blue : Colors.grey)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Duration / Estimated Time
                          InkWell(
                            onTap: _showEstimatedTimePicker,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 15, color: Color(0xFF475569)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _estimatedTime ?? 'Set Duration',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Subtasks Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtasks (${_subtasks.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Existing Subtasks List
                      if (_subtasks.isNotEmpty) ...[
                        ..._subtasks.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final sub = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: sub.isCompleted,
                                  activeColor: AppTheme.primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setState(() {
                                      sub.isCompleted = val ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    sub.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                                      color: sub.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _subtasks.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      // Add new Subtask Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newSubtaskController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Add a subtask...',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              onSubmitted: (_) => _addSubtask(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _addSubtask,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Notes / Description
                      const Text(
                        'Notes & Instructions',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'Add any details or notes here...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Bottom Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
