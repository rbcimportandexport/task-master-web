import '../screens/calendar_screen.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 1. Completed Tasks Donut Card (Screenshot 5)
class CompletedTasksOverviewCard extends StatefulWidget {
  final int completedCount;
  final int pendingCount;
  const CompletedTasksOverviewCard({super.key, this.completedCount = 0, this.pendingCount = 0});

  @override
  State<CompletedTasksOverviewCard> createState() => _CompletedTasksOverviewCardState();
}

class _CompletedTasksOverviewCardState extends State<CompletedTasksOverviewCard> {
  String _timeRange = 'In 30 days';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
      ),
      constraints: const BoxConstraints(minHeight: 380),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Completed Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _timeRange,
                  isDense: true,
                  items: ['In 7 days', 'In 30 days', 'In 1 year'].map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(
                        t,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _timeRange = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 290;
              final isCompact = constraints.maxWidth < 380;
              final donutSize = isVeryNarrow ? 110.0 : (isCompact ? 130.0 : 160.0);
              final spacing = isVeryNarrow ? 12.0 : (isCompact ? 16.0 : 28.0);

              if (isVeryNarrow) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: donutSize,
                        height: donutSize,
                        child: CustomPaint(
                          painter: _DonutChartPainter(
                            completed: widget.completedCount,
                            total: widget.completedCount + widget.pendingCount,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.pendingCount == 0 ? 'No Pending Tasks' : '${widget.completedCount} Completed',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.pendingCount == 0 ? 'All scheduled tasks are done!' : '${widget.pendingCount} Tasks Still Pending',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  SizedBox(
                    width: donutSize,
                    height: donutSize,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        completed: widget.completedCount,
                        total: widget.completedCount + widget.pendingCount,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.pendingCount == 0 ? 'No Pending Tasks' : '${widget.completedCount} Completed',
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontSize: isCompact ? 18 : 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.pendingCount == 0 ? 'All scheduled tasks are done!' : '${widget.pendingCount} Tasks Still Pending',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: isCompact ? 13 : 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int completed;
  final int total;
  _DonutChartPainter({required this.completed, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = size.width > 140 ? 18.0 : 13.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (total > 0 && completed > 0) {
      final progressPaint = Paint()
        ..color = AppTheme.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = (completed / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 2. Daily Completed Weekly Bar Chart (Screenshot 6)
class DailyCompletedCard extends StatefulWidget {
  final int taskCount;
  const DailyCompletedCard({super.key, this.taskCount = 0});

  @override
  State<DailyCompletedCard> createState() => _DailyCompletedCardState();
}

class _DailyCompletedCardState extends State<DailyCompletedCard> {
  int _weekOffset = 0;

  String get _dateRange {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1 - (_weekOffset * 7)));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
      ),
      constraints: const BoxConstraints(minHeight: 380),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Week Navigator
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 330;
              final navRow = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _weekOffset--),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(3.0),
                      child: Icon(Icons.arrow_left_rounded, color: Color(0xFF94A3B8), size: 22),
                    ),
                  ),
                  Text(
                    _dateRange,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  InkWell(
                    onTap: _weekOffset < 0 ? () => setState(() => _weekOffset++) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Icon(
                        Icons.arrow_right_rounded, 
                        color: _weekOffset < 0 ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0), 
                        size: 22,
                      ),
                    ),
                  ),
                ],
              );

              if (isVeryNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Completed',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'A quiet schedule this week.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: navRow,
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Daily Completed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      navRow,
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A quiet schedule this week.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Bar Chart with overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  // Chart area (Enlarged Height 260px)
                  SizedBox(
                    height: 260,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Y axis labels
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('16', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('12', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('8', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('4', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('0', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // 7 Day bars
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, barConstraints) {
                              final barWidth = ((barConstraints.maxWidth - 28) / 7).clamp(8.0, 28.0);
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(7, (i) {
                                  return Container(
                                    width: barWidth,
                                    height: 230,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(barWidth > 16 ? 12 : 6),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Weekday labels
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Mon ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Tue ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Wed ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Thu ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Fri ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Sat ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Sun', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Overlay pill
              if (widget.taskCount == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'No Task Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Completion Rate & Most Productive Day
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tasks Completion Rate',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text('--', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF60A5FA))),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Most Productive Day',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text('--', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF60A5FA))),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3. Focus Weekly Tracker Card (Screenshot 6)
class FocusTrackerCard extends StatefulWidget {
  const FocusTrackerCard({super.key});

  @override
  State<FocusTrackerCard> createState() => _FocusTrackerCardState();
}

class _FocusTrackerCardState extends State<FocusTrackerCard> {
  int _weekOffset = 0;

  String get _dateRange {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1 - (_weekOffset * 7)));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(minHeight: 400),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 330;
              final navRow = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _weekOffset--),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(3.0),
                      child: Icon(Icons.arrow_left_rounded, color: Color(0xFF94A3B8), size: 22),
                    ),
                  ),
                  Text(
                    _dateRange,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  InkWell(
                    onTap: _weekOffset < 0 ? () => setState(() => _weekOffset++) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Icon(Icons.arrow_right_rounded, color: _weekOffset < 0 ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1), size: 22),
                    ),
                  ),
                ],
              );

              if (isVeryNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Focus',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '0 min this week',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.55),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: navRow,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Focus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      navRow,
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Total focus time this week ',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('0 min', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Chart with overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 270,
                    child: Row(
                      children: [
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('12', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('9', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('6', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('3', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('0', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              5,
                              (index) => Container(
                                height: 1.5,
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Sun ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Mon ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Tue ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Wed ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Thu ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Fri ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text('Sat', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Overlay pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'No Focus Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 4. Tasks in Next 7 Days Card (Screenshot 6)
class TasksNext7DaysCard extends StatelessWidget {
  const TasksNext7DaysCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue, size: 26),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tasks in Next 7 Days',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryBlue, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Clean weekly roadmap preview placeholder (Extra Large Height)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                final isCompact = boxConstraints.maxWidth < 280;
                if (isCompact) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.event_note_rounded, color: AppTheme.primaryBlue, size: 30),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upcoming Roadmap',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Plan ahead and organize deadlines for the week',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.event_note_rounded, color: AppTheme.primaryBlue, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Upcoming Roadmap',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Plan ahead and organize deadlines for the week',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text(
                'Open Full Calendar Schedule',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
