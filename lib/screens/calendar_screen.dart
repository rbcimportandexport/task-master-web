import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_illustrations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _showThreeMonths = false;

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final selectedDate = taskProvider.selectedCalendarDate;
    final tasksForSelectedDay = taskProvider.tasksForDate(selectedDate);
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF8FAFC) : Colors.white,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: isDesktop ? const EdgeInsets.all(20) : EdgeInsets.zero,
                    decoration: isDesktop
                        ? BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          )
                        : null,
                    padding: isDesktop ? const EdgeInsets.all(20) : EdgeInsets.zero,
                    child: Column(
                      children: [
                        // Calendar Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isDesktop) ...[
                                      IconButton(
                                        icon: const Icon(Icons.menu, color: AppTheme.textPrimary, size: 24),
                                        onPressed: () => Scaffold.of(context).openDrawer(),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B), size: 24),
                                      onPressed: _previousMonth,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          DateFormat('MMMM yyyy').format(_currentMonth),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 24),
                                      onPressed: _nextMonth,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.filter_alt_outlined, color: Color(0xFF64748B), size: 22),
                                    onPressed: () {
                                      _showFilterDialog(context, taskProvider);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _showThreeMonths ? Icons.calendar_today_outlined : Icons.calendar_view_month_outlined,
                                      color: _showThreeMonths ? AppTheme.primaryBlue : const Color(0xFF64748B),
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() => _showThreeMonths = !_showThreeMonths);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 22),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onSelected: (val) {
                                      if (val == 'clear') {
                                        taskProvider.setFilterStatus('all');
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'clear',
                                        child: Text('Clear Filters'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Weekdays Row (Sun - Sat)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _WeekdayLabel('Sun'),
                              _WeekdayLabel('Mon'),
                              _WeekdayLabel('Tue'),
                              _WeekdayLabel('Wed'),
                              _WeekdayLabel('Thu'),
                              _WeekdayLabel('Fri'),
                              _WeekdayLabel('Sat'),
                            ],
                          ),
                        ),

                        // Calendar Grids
                        ...(_showThreeMonths
                                ? [
                                    DateTime(_currentMonth.year, _currentMonth.month - 1, 1),
                                    _currentMonth,
                                    DateTime(_currentMonth.year, _currentMonth.month + 1, 1),
                                  ]
                                : [_currentMonth])
                            .map((monthDate) {
                          final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
                          final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday % 7;
                          final prevMonthLastDay = DateTime(monthDate.year, monthDate.month, 0).day;

                          return Column(
                            children: [
                              if (_showThreeMonths)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(monthDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final totalWidth = constraints.maxWidth;
                                    final cellWidth = totalWidth / 7;
                                    final cellHeight = isDesktop ? 50.0 : (cellWidth / 1.15);

                                    return Wrap(
                                      children: List.generate(42, (index) {
                                        int dayNumber;
                                        bool isCurrentMonth = true;
                                        DateTime dateForCell;

                                        if (index < firstWeekday) {
                                          dayNumber = prevMonthLastDay - (firstWeekday - index - 1);
                                          isCurrentMonth = false;
                                          dateForCell = DateTime(monthDate.year, monthDate.month - 1, dayNumber);
                                        } else if (index < firstWeekday + daysInMonth) {
                                          dayNumber = index - firstWeekday + 1;
                                          dateForCell = DateTime(monthDate.year, monthDate.month, dayNumber);
                                        } else {
                                          dayNumber = index - (firstWeekday + daysInMonth) + 1;
                                          isCurrentMonth = false;
                                          dateForCell = DateTime(monthDate.year, monthDate.month + 1, dayNumber);
                                        }

                                        final isSelected = dateForCell.year == selectedDate.year &&
                                            dateForCell.month == selectedDate.month &&
                                            dateForCell.day == selectedDate.day;

                                        final hasTasks = taskProvider.tasksForDate(dateForCell).isNotEmpty;

                                        return SizedBox(
                                          width: cellWidth,
                                          height: cellHeight,
                                          child: InkWell(
                                            onTap: () {
                                              taskProvider.setSelectedCalendarDate(dateForCell);
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Center(
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: isSelected ? const Color(0xFF60A5FA) : Colors.transparent,
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Text(
                                                      '$dayNumber',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : (isCurrentMonth
                                                                ? const Color(0xFF0F172A)
                                                                : const Color(0xFF94A3B8)),
                                                      ),
                                                    ),
                                                    if (hasTasks && !isSelected)
                                                      Positioned(
                                                        bottom: 2,
                                                        child: Container(
                                                          width: 5,
                                                          height: 5,
                                                          decoration: const BoxDecoration(
                                                            color: AppTheme.primaryBlue,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ),
                              if (_showThreeMonths) const SizedBox(height: 16),
                            ],
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Tasks List for Selected Date
                SliverPadding(
                  padding: isDesktop
                      ? const EdgeInsets.symmetric(horizontal: 20, vertical: 8)
                      : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          "Tasks for ${DateFormat('EEE, MMM d').format(selectedDate)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tasksForSelectedDay.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: isDesktop
                      ? const EdgeInsets.fromLTRB(20, 8, 20, 40)
                      : const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  sliver: tasksForSelectedDay.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available_rounded, size: 48, color: Color(0xFF94A3B8)),
                                SizedBox(height: 12),
                                Text(
                                  'No tasks scheduled for this date',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Create a new task and set the due date to organize your day.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final task = tasksForSelectedDay[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: task.isCompleted,
                                    activeColor: AppTheme.primaryBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (_) => taskProvider.toggleTaskCompletion(task.id),
                                  ),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      color: task.isCompleted ? const Color(0xFF94A3B8) : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          task.category,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                      if (task.priority > 0) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          task.priority == 3 ? '• HIGH' : (task.priority == 2 ? '• MEDIUM' : '• LOW'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: task.priority == 3 ? Colors.red : (task.priority == 2 ? Colors.orange : Colors.blue),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      task.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: task.isStarred ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
                                    ),
                                    onPressed: () => taskProvider.toggleTaskStar(task.id),
                                  ),
                                ),
                              );
                            },
                            childCount: tasksForSelectedDay.length,
                          ),
                        ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: isDesktop ? 32 : 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(ctx, provider, 'All Tasks', 'all', Icons.all_inbox_rounded),
            _buildFilterOption(ctx, provider, 'Pending Only', 'pending', Icons.pending_actions_rounded),
            _buildFilterOption(ctx, provider, 'Completed Only', 'completed', Icons.check_circle_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
      BuildContext dialogContext, TaskProvider provider, String title, String value, IconData icon) {
    final isSelected = provider.filterStatus == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryBlue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
      onTap: () {
        provider.setFilterStatus(value);
        Navigator.pop(dialogContext);
      },
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}