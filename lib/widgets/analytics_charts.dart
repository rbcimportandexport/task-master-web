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
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Completed Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                ],
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _timeRange,
                  isDense: true,
                  items: ['In 7 days', 'In 30 days', 'In 1 year'].map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(
                        t,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
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
          const SizedBox(height: 48),
          Row(
            children: [
              // Donut Ring (Extra Large 190x190 for prominent visibility)
              SizedBox(
                width: 190,
                height: 190,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    completed: widget.completedCount,
                    total: widget.completedCount + widget.pendingCount,
                  ),
                ),
              ),
              const SizedBox(width: 36),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.pendingCount == 0 ? 'No Pending Tasks' : '${widget.completedCount} Completed',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.pendingCount == 0 ? 'All scheduled tasks are done!' : '${widget.pendingCount} Tasks Still Pending',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final strokeWidth = 18.0;

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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Week Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Completed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _weekOffset--),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.arrow_left_rounded, color: Color(0xFF94A3B8), size: 24),
                    ),
                  ),
                  Text(
                    _dateRange,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  InkWell(
                    onTap: _weekOffset < 0 ? () => setState(() => _weekOffset++) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.arrow_right_rounded, 
                        color: _weekOffset < 0 ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0), 
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'A quiet schedule this week.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

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
                            Text('16', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('12', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('8', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('4', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('0', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // 7 Day bars
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (i) {
                              return Container(
                                width: 28,
                                height: 230,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Weekday labels
                  const Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Mon', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Tue', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Wed', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Thu', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Fri', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Sat', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Sun', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),

              // Overlay pill
              if (widget.taskCount == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Completion Rate & Most Productive Day
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tasks Completion Rate', style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Text('--', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF60A5FA))),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Most Productive Day', style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Focus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _weekOffset--),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.arrow_left_rounded, color: Color(0xFF94A3B8), size: 24),
                    ),
                  ),
                  Text(
                    _dateRange,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  InkWell(
                    onTap: _weekOffset < 0 ? () => setState(() => _weekOffset++) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.arrow_right_rounded, color: _weekOffset < 0 ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1), size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Text('Total focus time this week ', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Text('0 min', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 24),

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
                            Text('12', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('9', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('6', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('3', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text('0', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 16),
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
                    padding: EdgeInsets.only(left: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Sun', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Mon', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Tue', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Wed', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Thu', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Fri', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Sat', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),

              // Overlay pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
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
                    fontSize: 14,
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue, size: 28),
                  SizedBox(width: 14),
                  Text(
                    'Tasks in Next 7 Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryBlue, size: 26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Clean weekly roadmap preview placeholder (Extra Large Height)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.event_note_rounded, color: AppTheme.primaryBlue, size: 36),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Upcoming Roadmap',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Plan ahead and organize deadlines for the week',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 20),
              label: const Text(
                'Open Full Calendar Schedule',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
