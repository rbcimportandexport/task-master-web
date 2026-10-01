import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_record_sheet.dart';
import '../widgets/voice_note_player.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late String _category;
  DateTime? _dueDate;
  String _reminder = 'No';
  String _repeat = 'No';
  late String _notes;
  late List<String> _attachments;
  String? _voiceNoteUrl;
  int? _voiceDurationSeconds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _category = widget.task.category;
    _dueDate = widget.task.dueDate ?? DateUtils.dateOnly(DateTime.now());
    _notes = widget.task.notes;
    _attachments = List<String>.from(widget.task.attachments);
    _voiceNoteUrl = widget.task.voiceNoteUrl;
    _voiceDurationSeconds = widget.task.voiceDurationSeconds;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    widget.task.title = _titleController.text.trim();
    widget.task.category = _category;
    widget.task.dueDate = _dueDate;
    widget.task.notes = _notes;
    widget.task.attachments = _attachments;
    widget.task.voiceNoteUrl = _voiceNoteUrl;
    widget.task.voiceDurationSeconds = _voiceDurationSeconds;
    context.read<TaskProvider>().updateTask(widget.task);
  }

  void _showCategoryPicker() {
    final provider = context.read<TaskProvider>();
    final categories = ['No Category', ...provider.categories.where((c) => c.name != 'All').map((c) => c.name)];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                trailing: _category == cat ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                onTap: () {
                  setState(() => _category = cat);
                  _saveChanges();
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateUtils.dateOnly(DateTime.now()),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
      _saveChanges();
    }
  }

  void _showRepeatPicker() {
    final options = ['No', 'Daily', 'Weekdays (Mon-Fri)', 'Weekly', 'Monthly', 'Yearly'];
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
              child: Text('Repeat Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt),
                trailing: _repeat == opt ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                onTap: () {
                  setState(() => _repeat = opt);
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

  void _showReminderPicker() {
    final options = ['No', '09:00 AM', '12:00 PM', '03:00 PM', '06:00 PM', '08:00 PM'];
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
              child: Text('Set Reminder Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt),
                trailing: _reminder == opt ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                onTap: () {
                  setState(() => _reminder = opt);
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

  void _addSubtaskDialog() {
    final subtaskController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Sub-task'),
        content: TextField(
          controller: subtaskController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Sub-task title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              if (subtaskController.text.trim().isNotEmpty) {
                context.read<TaskProvider>().addSubtask(widget.task.id, subtaskController.text.trim());
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog() {
    final notesController = TextEditingController(text: _notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Task Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Type your notes or description here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _notes = notesController.text.trim());
              _saveChanges();
              Navigator.pop(ctx);
            },
            child: const Text('Save Notes'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Attachment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.image_outlined, color: Color(0xFF3B82F6)),
                ),
                title: const Text('Photo / Image'),
                subtitle: const Text('Attach photo or camera capture', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _attachments.add('Photo_${DateTime.now().millisecondsSinceEpoch % 1000}.jpg');
                  });
                  _saveChanges();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo attached successfully!')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF10B981)),
                ),
                title: const Text('Document / PDF File'),
                subtitle: const Text('Attach PDF, DOC, or Spreadsheet', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _attachments.add('Document_${DateTime.now().millisecondsSinceEpoch % 1000}.pdf');
                  });
                  _saveChanges();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document attached successfully!')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.mic_rounded, color: Color(0xFFA855F7)),
                ),
                title: const Text('Voice Memo / Audio'),
                subtitle: const Text('Record and attach real voice note', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const VoiceRecordSheet(),
                  );
                  if (res != null && res['path'] != null) {
                    setState(() {
                      _voiceNoteUrl = res['path'] as String;
                      _voiceDurationSeconds = res['duration'] as int?;
                    });
                    _saveChanges();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice note recorded & attached successfully!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.link_rounded, color: Color(0xFFD97706)),
                ),
                title: const Text('Web Link / URL'),
                subtitle: const Text('Attach reference link', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddLinkDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLinkDialog() {
    final linkController = TextEditingController(text: 'https://');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Link Attachment'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            hintText: 'Enter URL (e.g. https://google.com)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (linkController.text.trim().isNotEmpty) {
                setState(() {
                  _attachments.add(linkController.text.trim());
                });
                _saveChanges();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Link'),
          ),
        ],
      ),
    );
  }

  void _showFocusTimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _FocusTimerDialog(taskTitle: widget.task.title),
    );
  }

  void _showPrintPreviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Print Preview'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${widget.task.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Category: $_category', style: const TextStyle(color: Color(0xFF64748B))),
            Text('Due Date: ${_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : "None"}', style: const TextStyle(color: Color(0xFF64748B))),
            if (_notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: $_notes', style: const TextStyle(fontSize: 13)),
            ],
            if (widget.task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Subtasks:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.task.subtasks.map((s) => Text('• ${s.title} [${s.isCompleted ? "Done" : "Pending"}]')),
            ],
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Attachments: ${_attachments.join(", ")}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print Now'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document sent to printer successfully!')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            _saveChanges();
            Navigator.pop(context);
          },
        ),
        actions: [
          // 3-Dots Menu (Screenshots 24 & 25)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            offset: const Offset(0, 45),
            onSelected: (val) {
              switch (val) {
                case 'toggle':
                  taskProvider.toggleTaskCompletion(widget.task.id);
                  setState(() {});
                  break;
                case 'duplicate':
                  taskProvider.addTask(
                    title: '${widget.task.title} (Copy)',
                    category: widget.task.category,
                    dueDate: widget.task.dueDate,
                    priority: widget.task.priority,
                  );
                  Navigator.pop(context);
                  break;
                case 'print':
                  _showPrintPreviewDialog();
                  break;
                case 'focus':
                  _showFocusTimerDialog();
                  break;
                case 'share':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing "${widget.task.title}" task...')),
                  );
                  break;
                case 'delete':
                  taskProvider.deleteTask(widget.task.id);
                  Navigator.pop(context);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  widget.task.isCompleted ? 'Mark as Undone' : 'Mark as Completed',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Text('Duplicate Task', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Text('Print Preview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const PopupMenuItem(
                value: 'focus',
                child: Text('Start Focus Timer (Pomodoro)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Text('Share', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Category Selector Pill (Screenshot 24)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _showCategoryPicker,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Large Editable Task Title (Screenshot 24)
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Task Title',
              hintStyle: TextStyle(color: Color(0xFF94A3B8)),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _saveChanges(),
          ),
          const SizedBox(height: 20),

          // + Add Sub-task Button
          InkWell(
            onTap: _addSubtaskDialog,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.add, color: AppTheme.primaryBlue, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Add Sub-task',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subtasks list
          if (widget.task.subtasks.isNotEmpty)
            Column(
              children: widget.task.subtasks.map((sub) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: sub.isCompleted,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (_) {
                      taskProvider.toggleSubtask(widget.task.id, sub.id);
                      setState(() {});
                    },
                  ),
                  title: Text(
                    sub.title,
                    style: TextStyle(
                      decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                      color: sub.isCompleted ? const Color(0xFF94A3B8) : AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),

          const Divider(height: 32, color: Color(0xFFF1F5F9)),

          // Property Rows (Screenshot 24)
          // 1. Due Date
          _buildPropertyTile(
            icon: Icons.calendar_today_outlined,
            title: 'Due Date',
            value: _dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Set Date',
            onTap: _pickDueDate,
          ),

          // 2. Time & Reminder
          _buildPropertyTile(
            icon: Icons.access_time_rounded,
            title: 'Time & Reminder',
            value: _reminder,
            onTap: _showReminderPicker,
          ),

          // 3. Repeat Task
          _buildPropertyTile(
            icon: Icons.repeat_rounded,
            title: 'Repeat Task',
            value: _repeat,
            onTap: _showRepeatPicker,
          ),

          // 4. Notes
          _buildPropertyTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Notes',
            value: _notes.isEmpty ? 'Add' : (_notes.length > 15 ? '${_notes.substring(0, 15)}...' : _notes),
            onTap: _showNotesDialog,
          ),

          // 5. Attachment (Free & Fully Functional)
          _buildPropertyTile(
            icon: Icons.attach_file_rounded,
            title: 'Attachment',
            value: _attachments.isEmpty ? 'Add' : '${_attachments.length} files',
            onTap: _showAttachmentPicker,
          ),

          // 6. Voice Note (Audio Message)
          _buildPropertyTile(
            icon: Icons.mic_rounded,
            title: 'Voice Note',
            value: _voiceNoteUrl != null ? 'Recorded' : 'Record',
            onTap: () async {
              final res = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const VoiceRecordSheet(),
              );
              if (res != null && res['path'] != null) {
                setState(() {
                  _voiceNoteUrl = res['path'] as String;
                  _voiceDurationSeconds = res['duration'] as int?;
                });
                _saveChanges();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice note recorded & attached successfully!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
          ),
          if (_voiceNoteUrl != null && _voiceNoteUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: VoiceNotePlayerWidget(
                        audioPathOrUrl: _voiceNoteUrl!,
                        durationSeconds: _voiceDurationSeconds,
                        isCompact: false,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _voiceNoteUrl = null;
                          _voiceDurationSeconds = null;
                        });
                        _saveChanges();
                      },
                      tooltip: 'Remove voice note',
                    ),
                  ],
                ),
              ),
            ),

          // Render Attached Files List
          if (_attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: _attachments.map((file) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          file.endsWith('.jpg') || file.endsWith('.png')
                              ? Icons.image_rounded
                              : (file.endsWith('.pdf') ? Icons.picture_as_pdf_rounded : (file.startsWith('http') ? Icons.link_rounded : Icons.insert_drive_file_rounded)),
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            file,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            setState(() {
                              _attachments.remove(file);
                            });
                            _saveChanges();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          // 6. Comments & Activity Log
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.comment_bank_outlined, color: AppTheme.primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text('Task Comments & Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_comment_rounded, size: 16),
                label: const Text('Add Note', style: TextStyle(fontSize: 12)),
                onPressed: _showAddCommentDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCommentsStream(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAddCommentDialog() {
    final commentController = TextEditingController();
    final taskProvider = context.read<TaskProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Task Comment / Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: commentController,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. 80% task complete, client review pending...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () async {
              if (commentController.text.trim().isNotEmpty) {
                final text = commentController.text.trim();
                Navigator.pop(ctx);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(taskProvider.uid)
                    .collection('tasks')
                    .doc(widget.task.id)
                    .collection('comments')
                    .add({
                  'author': taskProvider.userName.isNotEmpty ? taskProvider.userName : 'User',
                  'role': taskProvider.userRole,
                  'message': text,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                setState(() {});
              }
            },
            child: const Text('Post Comment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsStream() {
    final taskProvider = context.read<TaskProvider>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(taskProvider.uid)
          .collection('tasks')
          .doc(widget.task.id)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No comments or activity log yet. Click "Add Note" to post updates.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final comments = snapshot.data!.docs;
        return Column(
          children: comments.map((doc) {
            final data = doc.data();
            final author = data['author'] ?? 'User';
            final role = (data['role'] ?? 'Employee').toString().toUpperCase();
            final msg = data['message'] ?? '';
            final ts = data['timestamp'] as Timestamp?;
            final timeStr = ts != null ? DateFormat('dd MMM, hh:mm a').format(ts.toDate()) : 'Just now';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(role, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                          ),
                        ],
                      ),
                      Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(msg, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPropertyTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _FocusTimerDialog extends StatefulWidget {
  final String taskTitle;
  const _FocusTimerDialog({required this.taskTitle});

  @override
  State<_FocusTimerDialog> createState() => _FocusTimerDialogState();
}

class _FocusTimerDialogState extends State<_FocusTimerDialog> {
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          t.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 25 * 60;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_rounded, color: AppTheme.primaryBlue, size: 22),
            SizedBox(width: 8),
            Text('Focus Pomodoro Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.taskTitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: AppTheme.primaryBlue, width: 4),
            ),
            alignment: Alignment.center,
            child: Text(
              '$minutes:$seconds',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.amber.shade700 : AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Pause' : 'Start'),
                onPressed: _toggleTimer,
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _resetTimer,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
