import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../models/task.dart';
import '../widgets/pie_progress_indicator.dart';
import '../widgets/task_add_sheet.dart';
import 'dart:convert';
import '../widgets/assign_task_sheet.dart';
import '../widgets/voice_note_player.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String? profilePicBase64;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    this.profilePicBase64,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
                actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: AppTheme.primaryBlue),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                isDismissible: true,
                enableDrag: true,
                builder: (context) => AssignTaskSheet(employeeId: widget.employeeId),
              );
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Employee Details',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: widget.profilePicBase64 != null && widget.profilePicBase64!.isNotEmpty
                        ? MemoryImage(base64Decode(widget.profilePicBase64!))
                        : null,
                    child: widget.profilePicBase64 == null || widget.profilePicBase64!.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Color(0xFF94A3B8))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.employeeName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.employeeEmail,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: const Text(
                'Assigned Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ),
          StreamBuilder<List<Task>>(
            stream: provider.getEmployeeTasksStream(widget.employeeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error loading tasks: ${snapshot.error}')),
                );
              }

              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No tasks assigned to this employee yet.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    return _buildEmployeeTaskItem(task);
                  },
                  childCount: tasks.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            isDismissible: true,
            enableDrag: true,
            builder: (context) => TaskAddSheet(targetEmployeeId: widget.employeeId),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.isCompleted ? AppTheme.primaryBlue : const Color(0xFF94A3B8),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (val) {
            if (val == 'transfer') {
              _showTransferTaskDialog(task);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'transfer',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text('Transfer / Re-assign Task', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: task.isCompleted ? const Color(0xFF94A3B8) : AppTheme.textPrimary,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (task.category != 'No Category')
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                child: Text(task.category, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              ),
            if (task.dueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy').format(task.dueDate!), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            if (task.priority > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 4),
                child: Icon(
                  Icons.flag_rounded,
                  size: 14,
                  color: task.priority == 3 ? const Color(0xFFEF4444) : (task.priority == 2 ? const Color(0xFFF97316) : const Color(0xFF10B981)),
                ),
              ),
            if (task.flagColor > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 4),
                child: Icon(
                  Icons.flag_rounded,
                  size: 14,
                  color: task.flagColor == 1 ? const Color(0xFFF43F5E) : task.flagColor == 2 ? const Color(0xFFF59E0B) : task.flagColor == 3 ? const Color(0xFFC084FC) : task.flagColor == 4 ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                ),
              ),
            if (task.progress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PieProgressIndicator(
                      value: task.progress / 100,
                      size: 14,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text('${task.progress}%', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (task.assignedBy != null && task.assignedBy!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6, right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 12, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 4),
                    Text('By: ${task.assignedBy}', style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (task.estimatedTime != null && task.estimatedTime!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6, right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(task.estimatedTime!, style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (task.attachments.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6, right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 2),
                    Text('${task.attachments.length} files', style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if (task.voiceNoteUrl != null && task.voiceNoteUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: VoiceNotePlayerWidget(
                  audioPathOrUrl: task.voiceNoteUrl!,
                  durationSeconds: task.voiceDurationSeconds,
                  isCompact: true,
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  void _showTransferTaskDialog(Task task) async {
    final provider = context.read<TaskProvider>();
    final users = await provider.getEmployees();
    // Exclude current employee from target transfer candidates
    final targetCandidates = users.where((u) => u['uid'] != widget.employeeId).toList();

    if (!mounted) return;

    if (targetCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other employee available to transfer task.')),
      );
      return;
    }

    String? selectedTargetUserId = targetCandidates.first['uid'];
    final reasonController = TextEditingController(text: 'Employee is absent / unavailable');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text('Transfer / Re-assign Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task: "${task.title}"',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Currently assigned to: ${widget.employeeName}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                const Text('Transfer To Employee / Manager:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTargetUserId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: targetCandidates.map((u) {
                    final name = u['name'] ?? 'Unknown';
                    final dept = u['department'] ?? 'General';
                    final role = (u['role'] ?? 'employee').toString().toUpperCase();
                    return DropdownMenuItem<String>(
                      value: u['uid'],
                      child: Text('$name ($dept - $role)', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedTargetUserId = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Reason / Note (Optional):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Employee is on leave/absent...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (selectedTargetUserId == null) return;
                Navigator.pop(ctx);
                try {
                  await provider.transferTask(
                    fromEmployeeId: widget.employeeId,
                    toEmployeeId: selectedTargetUserId!,
                    task: task,
                    reason: reasonController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task transferred and re-assigned successfully!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error transferring task: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Transfer Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
