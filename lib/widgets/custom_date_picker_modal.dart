import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class CustomDatePickerModal extends StatefulWidget {
  final DateTime? initialDate;

  const CustomDatePickerModal({super.key, this.initialDate});

  @override
  State<CustomDatePickerModal> createState() => _CustomDatePickerModalState();
}

class _CustomDatePickerModalState extends State<CustomDatePickerModal> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    final now = DateTime.now();
    _currentMonth = DateTime(_selectedDate?.year ?? now.year, _selectedDate?.month ?? now.month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _selectQuickDate(String type) {
    final now = DateTime.now();
    DateTime? newDate;
    switch (type) {
      case 'Today':
        newDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Tomorrow':
        newDate = DateTime(now.year, now.month, now.day + 1);
        break;
      case '3 Days Later':
        newDate = DateTime(now.year, now.month, now.day + 3);
        break;
      case 'This Sunday':
        int daysToSunday = 7 - now.weekday;
        if (daysToSunday == 0) daysToSunday = 7; // Next Sunday if today is Sunday
        newDate = DateTime(now.year, now.month, now.day + daysToSunday);
        break;
      case 'No Date':
        newDate = null;
        break;
    }
    setState(() {
      _selectedDate = newDate;
      if (newDate != null) {
        _currentMonth = DateTime(newDate.year, newDate.month);
      }
    });
  }

  Widget _buildQuickChip(String label, bool isSelected) {
    return InkWell(
      onTap: () => _selectQuickDate(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOffset = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7; // Sun = 0
    final totalCells = ((daysInMonth + firstDayOffset) / 7).ceil() * 7;
    
    // Using DateUtils for previous month days
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Month/Year and Arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left_rounded, size: 32, color: Color(0xFF64748B)),
                onPressed: _previousMonth,
              ),
              const SizedBox(width: 16),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.arrow_right_rounded, size: 32, color: Color(0xFF64748B)),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Weekdays header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          
          // Calendar Grid
          Wrap(
            spacing: 0,
            runSpacing: 8,
            alignment: WrapAlignment.spaceAround,
            children: List.generate(totalCells, (index) {
              int day;
              bool isCurrentMonth = true;
              DateTime cellDate;

              if (index < firstDayOffset) {
                day = daysInPrevMonth - (firstDayOffset - index - 1);
                isCurrentMonth = false;
                cellDate = DateTime(_currentMonth.year, _currentMonth.month - 1, day);
              } else if (index < firstDayOffset + daysInMonth) {
                day = index - firstDayOffset + 1;
                cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
              } else {
                day = index - (firstDayOffset + daysInMonth) + 1;
                isCurrentMonth = false;
                cellDate = DateTime(_currentMonth.year, _currentMonth.month + 1, day);
              }

              final isSelected = _selectedDate != null &&
                  cellDate.year == _selectedDate!.year &&
                  cellDate.month == _selectedDate!.month &&
                  cellDate.day == _selectedDate!.day;

              return SizedBox(
                width: 40,
                height: 40,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                      _currentMonth = DateTime(cellDate.year, cellDate.month);
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected 
                            ? Colors.white 
                            : (isCurrentMonth ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickChip('Today', _isSameDay(_selectedDate, DateTime.now())),
              _buildQuickChip('Tomorrow', _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)))),
              _buildQuickChip('3 Days Later', _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 3)))),
              _buildQuickChip('This Sunday', _isSameDay(_selectedDate, _getNextSunday())),
              _buildQuickChip('No Date', _selectedDate == null),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          
          // Extra Settings (Visual Only per screenshot)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_rounded, color: Color(0xFF64748B)),
            title: const Text('Time', style: TextStyle(fontSize: 15, color: Color(0xFF475569))),
            trailing: const Text('No', style: TextStyle(color: Color(0xFF94A3B8))),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
            title: const Text('Reminder', style: TextStyle(fontSize: 15, color: Color(0xFF475569))),
            trailing: const Text('No', style: TextStyle(color: Color(0xFF94A3B8))),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.repeat_rounded, color: Color(0xFF64748B)),
            title: const Text('Repeat', style: TextStyle(fontSize: 15, color: Color(0xFF475569))),
            trailing: const Text('No', style: TextStyle(color: Color(0xFF94A3B8))),
            dense: true,
            onTap: () {},
          ),
          
          const SizedBox(height: 16),
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Dismiss without changes
                child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, {'date': _selectedDate}),
                child: const Text('DONE', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  DateTime _getNextSunday() {
    final now = DateTime.now();
    int daysToSunday = 7 - now.weekday;
    if (daysToSunday == 0) daysToSunday = 7;
    return DateTime(now.year, now.month, now.day + daysToSunday);
  }
}
