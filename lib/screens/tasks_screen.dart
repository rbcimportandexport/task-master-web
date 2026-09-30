import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_illustrations.dart';
import '../widgets/speech_bubble_tooltip.dart';
import '../widgets/pie_progress_indicator.dart';
import '../widgets/task_add_sheet.dart';
import '../widgets/task_coachmark_overlay.dart';
import '../widgets/celebration_dialog.dart';
import 'search_screen.dart';
import 'task_detail_screen.dart';
import 'notifications_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  
  bool _showCoachmark = false;
  bool _isPreviousExpanded = true;
  bool _isTodayExpanded = true;
  bool _isFutureExpanded = true;
  bool _isNoDateExpanded = true;
  bool _isCompletedExpanded = true;
  void _openAddTaskModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskAddSheet(),
    );
  }

  void _showSortDialog() {
    final taskProvider = context.read<TaskProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sort by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Default (Creation Time)'),
              leading: Icon(
                taskProvider.sortBy == 'default' ? Icons.radio_button_checked : Icons.radio_button_off,
                color: AppTheme.primaryBlue,
              ),
              onTap: () {
                taskProvider.setSortBy('default');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Due Date'),
              leading: Icon(
                taskProvider.sortBy == 'date' ? Icons.radio_button_checked : Icons.radio_button_off,
                color: AppTheme.primaryBlue,
              ),
              onTap: () {
                taskProvider.setSortBy('date');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Priority'),
              leading: Icon(
                taskProvider.sortBy == 'priority' ? Icons.radio_button_checked : Icons.radio_button_off,
                color: AppTheme.primaryBlue,
              ),
              onTap: () {
                taskProvider.setSortBy('priority');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Alphabetical'),
              leading: Icon(
                taskProvider.sortBy == 'alphabetical' ? Icons.radio_button_checked : Icons.radio_button_off,
                color: AppTheme.primaryBlue,
              ),
              onTap: () {
                taskProvider.setSortBy('alphabetical');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showManageCategoriesDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final taskProvider = context.watch<TaskProvider>();
            final customCategories = taskProvider.categories.where((c) => !CategoryItem.defaultCategories.any((dc) => dc.id == c.id)).toList();
            
            return AlertDialog(
              title: const Text('Manage Categories'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'New category name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (customCategories.isNotEmpty)
                      const Text('Custom Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (customCategories.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: customCategories.length,
                          itemBuilder: (context, index) {
                            final cat = customCategories[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(cat.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  context.read<TaskProvider>().deleteCategory(cat.id);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      context.read<TaskProvider>().addCategory(
                        controller.text.trim(),
                        Icons.folder_outlined,
                        const Color(0xFF6366F1),
                      );
                      controller.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTodayReviewDialog() {
    final taskProvider = context.read<TaskProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.insights_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Today Review'),
          ],
        ),
        content: Text(
          'You have ${taskProvider.pendingTasksCount} pending tasks and ${taskProvider.completedTasksCount} completed tasks today. Keep it up!',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showPrintAllTasksDialog(List<Task> tasks) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Print Task List'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Tasks to Print: ${tasks.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...tasks.take(6).map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• [ ${t.isCompleted ? "X" : " "} ] ${t.title} (${t.category})', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print Now'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checklist sent to printer successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Send Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Share feedback or feature suggestions...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you! Your feedback has been received.')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Filter Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(provider, 'All Tasks', 'all', Icons.all_inbox_rounded),
            _buildFilterOption(provider, 'Pending Only', 'pending', Icons.pending_actions_rounded),
            _buildFilterOption(provider, 'Completed Only', 'completed', Icons.check_circle_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(TaskProvider provider, String title, String value, IconData icon) {
    final isSelected = provider.filterStatus == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryBlue : const Color(0xFF64748B)),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.primaryBlue) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
      onTap: () {
        provider.setFilterStatus(value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTaskList(List<Task> taskList, bool isMultiSelect, TaskProvider taskProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        if (isDesktop || taskProvider.isGridView) {
          final columns = isDesktop ? (constraints.maxWidth >= 1200 ? 3 : 2) : 2;
          final itemWidth = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
          return Wrap(
            spacing: 14,
            runSpacing: 12,
            children: taskList.map((t) => SizedBox(
              width: itemWidth,
              child: _buildTaskItem(t, isMultiSelect, taskProvider),
            )).toList(),
          );
        }

        return Column(
          children: taskList.map((t) => _buildTaskItem(t, isMultiSelect, taskProvider)).toList(),
        );
      },
    );
  }

  void _showFreeProUnlockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 40),
              SizedBox(height: 8),
              Text('PRO Features Unlocked!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        content: const Text(
          'All premium features including AI Voice Task Creation, Custom Themes, Widgets, Subtasks, Cloud Backup, and Attachments are 100% FREE for you forever!',
          style: TextStyle(color: Color(0xFF64748B), height: 1.4),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Enjoy VIP Free Access', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final currentCategory = taskProvider.selectedCategory;
    final tasks = taskProvider.filteredTasks;
    final isMultiSelect = taskProvider.isMultiSelectMode;
    final isAll = currentCategory.toLowerCase() == 'all';

    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF8FAFC) : Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: isDesktop ? const EdgeInsets.fromLTRB(28, 20, 28, 20) : EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    // Desktop Header Bar (Extra Large & Imposing)
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAll ? 'All Tasks' : currentCategory,
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${taskProvider.pendingTasksCount} pending tasks • ${taskProvider.completedTasksCount} completed',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Search Button
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                          ),
                          icon: const Icon(Icons.search, size: 24, color: Color(0xFF475569)),
                          label: const Text('Search tasks...', style: TextStyle(color: Color(0xFF475569), fontSize: 17, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 16),
                        // Filter button
                        OutlinedButton.icon(
                          onPressed: () => _showFilterDialog(taskProvider),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                          ),
                          icon: const Icon(Icons.filter_list_rounded, size: 24, color: Color(0xFF475569)),
                          label: Text(
                            taskProvider.filterStatus.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Sort Button
                        IconButton(
                          icon: const Icon(Icons.sort_rounded, color: Color(0xFF475569), size: 30),
                          tooltip: 'Sort tasks',
                          onPressed: _showSortDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Desktop Metric Cards (Dashboard Web Feel)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.assignment_rounded, color: Color(0xFF4F46E5), size: 28),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Tasks', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('${tasks.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 28),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pending Tasks', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('${taskProvider.pendingTasksCount}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Completed Tasks', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('${taskProvider.completedTasksCount}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
            // Top Bar: Categories horizontally scrollable + 3-dots popup menu
            if (isMultiSelect)
              Container(
                color: const Color(0xFFEEF2FF),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => taskProvider.toggleMultiSelectMode(),
                    ),
                    Text(
                      '${taskProvider.selectedTaskIds.length} Selected',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => taskProvider.selectAllTasks(),
                      child: const Text('Select All', style: TextStyle(fontSize: 15)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                      onPressed: taskProvider.selectedTaskIds.isEmpty
                          ? null
                          : () => taskProvider.deleteSelectedTasks(),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(4, isDesktop ? 12 : 8, 4, isDesktop ? 22 : 16),
                child: Row(
                  children: [
                    
                    // Categories Scrollable List (Extra Large Pills)
                    Expanded(
                      child: SizedBox(
                        height: isDesktop ? 60 : 44,
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: taskProvider.categories.length,
                          separatorBuilder: (context, index) => SizedBox(width: isDesktop ? 16 : 10),
                          itemBuilder: (context, index) {
                            final cat = taskProvider.categories[index];
                            final isSelected = cat.name.toLowerCase() == currentCategory.toLowerCase();

                            return InkWell(
                              onTap: () {
                                taskProvider.setSelectedCategory(cat.name);
                              },
                              borderRadius: BorderRadius.circular(30),
                              mouseCursor: SystemMouseCursors.click,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 34 : 24,
                                  vertical: isDesktop ? 14 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.chipActiveBg : AppTheme.chipInactiveBg,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: isSelected && isDesktop
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5),
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.chipInactiveText,
                                    fontSize: isDesktop ? 20 : 15,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 3-Dots Menu matching Screenshot
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: const Color(0xFF64748B), size: isDesktop ? 30 : 26),
                      color: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      offset: const Offset(0, 45),
                      onSelected: (val) {
                        switch (val) {
                          case 'select':
                            taskProvider.toggleMultiSelectMode();
                            break;
                          case 'categories':
                            _showManageCategoriesDialog();
                            break;
                          case 'review':
                            _showTodayReviewDialog();
                            break;
                          case 'search':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchScreen()),
                            );
                            break;
                          case 'sort':
                            _showSortDialog();
                            break;
                          case 'print':
                            _showPrintAllTasksDialog(tasks);
                            break;
                          case 'feedback':
                            _showFeedbackDialog();
                            break;
                          case 'pro':
                            _showFreeProUnlockedDialog();
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'select',
                          child: Text('Select Tasks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const PopupMenuItem(
                          value: 'categories',
                          child: Text('Manage Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const PopupMenuItem(
                          value: 'today_review',
                          child: Text('Today Review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const PopupMenuItem(
                          value: 'search',
                          child: Text('Search', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const PopupMenuItem(
                          value: 'sort',
                          child: Text('Sort by', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const PopupMenuItem(
                          value: 'print',
                          child: Text('Print', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        PopupMenuItem(
                          enabled: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Show Subtask',
                                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                              ),
                              StatefulBuilder(
                                builder: (context, setMenuState) {
                                  return Switch(
                                    value: taskProvider.showSubtasks,
                                    activeTrackColor: AppTheme.primaryBlue,
                                    onChanged: (val) {
                                      taskProvider.setShowSubtasks(val);
                                      setMenuState(() {});
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'feedback',
                          child: Text('Feedback', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Body: Empty State or Grouped Task List
            Expanded(
              child: tasks.isEmpty
                  ? _buildEmptyState(currentCategory)
                  : Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);

                        final List<Task> previousTasks = [];
                        final List<Task> todayTasks = [];
                        final List<Task> futureTasks = [];
                        final List<Task> noDateTasks = [];
                        final List<Task> completedTasks = [];

                        for (final task in tasks) {
                          if (task.isCompleted) {
                            completedTasks.add(task);
                          } else if (task.dueDate == null) {
                            noDateTasks.add(task);
                          } else {
                            final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
                            if (taskDate.isBefore(today)) {
                              previousTasks.add(task);
                            } else if (taskDate.isAfter(today)) {
                              futureTasks.add(task);
                            } else {
                              todayTasks.add(task);
                            }
                          }
                        }

                        final isDesktop = MediaQuery.of(context).size.width >= 850;

                        Widget buildTaskListSection(List<Task> sectionTasks) {
                          if (isDesktop) {
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                                final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;
                                return Wrap(
                                  spacing: 16,
                                  runSpacing: 14,
                                  children: sectionTasks.map((t) => SizedBox(
                                    width: itemWidth,
                                    child: _buildTaskItem(t, isMultiSelect, taskProvider),
                                  )).toList(),
                                );
                              },
                            );
                          }
                          return Column(
                            children: sectionTasks.map((t) => _buildTaskItem(t, isMultiSelect, taskProvider)).toList(),
                          );
                        }

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 4 : 16, vertical: 4),
                          children: [
                            // 1. Previous Section (Overdue / Past tasks)
                            if (previousTasks.isNotEmpty) ...[
                              _buildDateSectionHeader(
                                title: 'Previous',
                                count: previousTasks.length,
                                isExpanded: _isPreviousExpanded,
                                color: const Color(0xFFEF4444),
                                onToggle: () => setState(() => _isPreviousExpanded = !_isPreviousExpanded),
                              ),
                              if (_isPreviousExpanded)
                                buildTaskListSection(previousTasks),
                              const SizedBox(height: 6),
                            ],

                            // 2. Today Section
                            if (todayTasks.isNotEmpty) ...[
                              _buildDateSectionHeader(
                                title: 'Today',
                                count: todayTasks.length,
                                isExpanded: _isTodayExpanded,
                                color: const Color(0xFF0F172A),
                                onToggle: () => setState(() => _isTodayExpanded = !_isTodayExpanded),
                              ),
                              if (_isTodayExpanded)
                                buildTaskListSection(todayTasks),
                              const SizedBox(height: 6),
                            ],

                            // 3. Future Section
                            if (futureTasks.isNotEmpty) ...[
                              _buildDateSectionHeader(
                                title: 'Future',
                                count: futureTasks.length,
                                isExpanded: _isFutureExpanded,
                                color: const Color(0xFF3B82F6),
                                onToggle: () => setState(() => _isFutureExpanded = !_isFutureExpanded),
                              ),
                              if (_isFutureExpanded)
                                buildTaskListSection(futureTasks),
                              const SizedBox(height: 6),
                            ],

                            // 4. No Date Section
                            if (noDateTasks.isNotEmpty) ...[
                              _buildDateSectionHeader(
                                title: 'No Due Date',
                                count: noDateTasks.length,
                                isExpanded: _isNoDateExpanded,
                                color: const Color(0xFF64748B),
                                onToggle: () => setState(() => _isNoDateExpanded = !_isNoDateExpanded),
                              ),
                              if (_isNoDateExpanded)
                                buildTaskListSection(noDateTasks),
                            ],
                            

                            // 5. Completed Section
                            if (completedTasks.isNotEmpty) ...[
                              _buildDateSectionHeader(
                                title: 'Done',
                                count: completedTasks.length,
                                isExpanded: _isCompletedExpanded,
                                color: const Color(0xFF10B981),
                                onToggle: () => setState(() => _isCompletedExpanded = !_isCompletedExpanded),
                              ),
                              if (_isCompletedExpanded)
                                buildTaskListSection(completedTasks),
                            ],
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
      if (_showCoachmark && tasks.isNotEmpty)
        TaskCoachmarkOverlay(
          task: tasks.first,
          onDismiss: () {
            setState(() => _showCoachmark = false);
          },
        ),

      // Yellow Speech Tooltip pointing directly down towards the FAB (Only on Mobile)
      if (tasks.isEmpty && isAll && !isDesktop)
        Positioned(
          bottom: 190,
          right: 16,
          child: SpeechBubbleTooltip(
            text: 'Click here to create your first task.',
            onTap: () => _openAddTaskModal(context),
          ),
        ),
    ],
  ),
);
  }

  Widget _buildDateSectionHeader({
    required String title,
    required int count,
    required bool isExpanded,
    required Color color,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              '$title ($count)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color == const Color(0xFFEF4444) ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String currentCategory) {
    final isAll = currentCategory.toLowerCase() == 'all';
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final illustrationSize = isDesktop
            ? (screenHeight * 0.40).clamp(340.0, 520.0)
            : (screenHeight * 0.32).clamp(240.0, 380.0);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 700),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 48 : 32,
                  vertical: isDesktop ? 60 : 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dynamic Auto-Scaling Illustration (Bigger Scale)
                    if (isAll)
                      PersonWithPhoneIllustration(size: illustrationSize)
                    else
                      GirlWithLaptopIllustration(size: illustrationSize),

                    SizedBox(height: isDesktop ? 36 : 28),

                    Text(
                      isAll ? 'No Tasks in Workspace' : 'No tasks in "$currentCategory"',
                      style: TextStyle(
                        fontSize: isDesktop ? 34 : 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 16 : 12),
                    Text(
                      isAll
                          ? 'Your workspace is all clear! Create your first task to plan, track, and manage your day effortlessly.'
                          : 'Add tasks to this category or select "All" from the categories above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 17,
                        color: const Color(0xFF64748B),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 40 : 32),
                    ElevatedButton.icon(
                      onPressed: () => _openAddTaskModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 48 : 36,
                          vertical: isDesktop ? 24 : 20,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 8,
                        shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.45),
                      ),
                      icon: Icon(Icons.add_rounded, size: isDesktop ? 32 : 28),
                      label: Text(
                        'Create New Task',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isDesktop ? 22 : 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(Task task, bool isMultiSelect, TaskProvider provider) {
    final isSelected = provider.selectedTaskIds.contains(task.id);
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        provider.deleteTask(task.id);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isDesktop ? 14 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isDesktop ? 18 : 20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : (isDesktop ? const Color(0xFFE2E8F0) : Colors.transparent),
            width: isSelected ? 2 : (isDesktop ? 1.2 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: isDesktop ? 0.06 : 0.08),
              blurRadius: isDesktop ? 12 : 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 18 : 12,
                vertical: isDesktop ? 10 : 4,
              ),
              onTap: () {
                if (isMultiSelect) {
                  provider.toggleTaskSelection(task.id);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(task: task),
                    ),
                  );
                }
              },
              leading: isMultiSelect
                  ? Checkbox(
                      value: isSelected,
                      activeColor: AppTheme.primaryBlue,
                      shape: const CircleBorder(),
                      onChanged: (_) => provider.toggleTaskSelection(task.id),
                    )
                  : (task.subtasks.isNotEmpty
                      ? InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                            );
                          },
                          child: Container(
                            width: isDesktop ? 36 : 32,
                            height: isDesktop ? 36 : 32,
                            margin: const EdgeInsets.only(right: 8, left: 4),
                            child: PieProgressIndicator(
                              value: task.subtasks.where((s) => s.isCompleted).length / task.subtasks.length,
                              size: isDesktop ? 30 : 26,
                              backgroundColor: const Color(0xFFDBEAFE),
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        )
                      : Checkbox(
                          value: task.isCompleted,
                          activeColor: AppTheme.primaryBlue,
                          shape: const CircleBorder(),
                          onChanged: (_) {
                            if (!task.isCompleted && !provider.hasCompletedFirstTask) {
                              provider.markFirstTaskCompleted();
                              showDialog(
                                context: context,
                                builder: (_) => const CelebrationDialog(),
                              );
                            }
                            provider.toggleTaskCompletion(task.id);
                          },
                        )),
              title: Text(
                task.title,
                style: TextStyle(
                  fontSize: isDesktop ? 17 : 15,
                  fontWeight: isDesktop ? FontWeight.w700 : FontWeight.w500,
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
                      margin: const EdgeInsets.only(right: 8, top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        task.category,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ),
                  if (task.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(task.dueDate!),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  if (task.priority > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 14,
                        color: task.priority == 3
                            ? const Color(0xFFEF4444)
                            : (task.priority == 2 ? const Color(0xFFF97316) : const Color(0xFF10B981)),
                      ),
                    ),
                  if (task.flagColor > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 14,
                        color: task.flagColor == 1 ? const Color(0xFFF43F5E) :
                               task.flagColor == 2 ? const Color(0xFFF59E0B) :
                               task.flagColor == 3 ? const Color(0xFFC084FC) :
                               task.flagColor == 4 ? const Color(0xFF3B82F6) :
                                                     const Color(0xFF10B981),
                      ),
                    ),
                  if (task.assignedBy != null && task.assignedBy!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 12, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Text(
                            'Assigned by: ${task.assignedBy}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  if (task.progress > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
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
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  task.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                  color: task.isStarred ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
                  size: 22,
                ),
                onPressed: () => provider.toggleTaskStar(task.id),
              ),
            ),

            // Subtasks list if visible
            if (provider.showSubtasks && task.subtasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 16, 10),
                child: Column(
                  children: task.subtasks.map((sub) {
                    return Row(
                      children: [
                        InkWell(
                          onTap: () => provider.toggleSubtask(task.id, sub.id),
                          child: Icon(
                            sub.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: sub.isCompleted ? AppTheme.primaryBlue : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: sub.isCompleted ? const Color(0xFF94A3B8) : AppTheme.textPrimary,
                              decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


