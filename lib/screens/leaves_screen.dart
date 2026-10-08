import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  void _showApplyLeaveDialog() {
    final reasonController = TextEditingController();
    String durationMode = 'Full Day'; // 'Full Day', 'Half Day', 'Hourly'
    String leaveType = 'Casual Leave';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    String halfDayType = 'First Half'; // 'First Half', 'Second Half'
    int hourlyHours = 2; // 1, 2, 3, 4
    TimeOfDay hourlyStartTime = const TimeOfDay(hour: 14, minute: 0);
    TimeOfDay hourlyEndTime = const TimeOfDay(hour: 16, minute: 0);

    final isDesktop = MediaQuery.of(context).size.width >= 950;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          String formatTimeOfDay(TimeOfDay tod) {
            final now = DateTime.now();
            final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
            return DateFormat('hh:mm a').format(dt);
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 16,
              vertical: 24,
            ),
            child: Container(
              width: isDesktop ? 680 : double.infinity,
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.beach_access_rounded, color: AppTheme.primaryBlue, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Apply for Leave',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Leave Duration Mode Selector (Full Day / Half Day / Hourly)
                    const Text('Leave Duration Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() {
                                durationMode = 'Full Day';
                                leaveType = 'Casual Leave';
                              }),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: durationMode == 'Full Day' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: durationMode == 'Full Day'
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  ' Full Day',
                                  style: TextStyle(
                                    fontWeight: durationMode == 'Full Day' ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                    color: durationMode == 'Full Day' ? AppTheme.primaryBlue : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() {
                                durationMode = 'Half Day';
                                leaveType = 'Half Day Leave';
                              }),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: durationMode == 'Half Day' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: durationMode == 'Half Day'
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  ' Half Day',
                                  style: TextStyle(
                                    fontWeight: durationMode == 'Half Day' ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                    color: durationMode == 'Half Day' ? AppTheme.primaryBlue : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() {
                                durationMode = 'Hourly';
                                leaveType = 'Hourly Leave / Short Pass';
                              }),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: durationMode == 'Hourly' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: durationMode == 'Hourly'
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  ' Hourly',
                                  style: TextStyle(
                                    fontWeight: durationMode == 'Hourly' ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                    color: durationMode == 'Hourly' ? AppTheme.primaryBlue : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Specific Duration Fields Based On Mode
                    if (durationMode == 'Full Day') ...[
                      const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                backgroundColor: const Color(0xFFF8FAFC),
                              ),
                              icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryBlue),
                              label: Text(DateFormat('dd MMM yyyy').format(startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    startDate = picked;
                                    if (endDate.isBefore(startDate)) endDate = startDate;
                                  });
                                }
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text('to', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13)),
                          ),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                backgroundColor: const Color(0xFFF8FAFC),
                              ),
                              icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryBlue),
                              label: Text(DateFormat('dd MMM yyyy').format(endDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (picked != null) {
                                  setDialogState(() => endDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else if (durationMode == 'Half Day') ...[
                      const Text('Date & Half Selection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          backgroundColor: const Color(0xFFF8FAFC),
                        ),
                        icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryBlue),
                        label: Text(DateFormat('EEEE, dd MMM yyyy').format(startDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                              endDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('First Half (Morning)\n09:30 AM – 01:30 PM', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                              selected: halfDayType == 'First Half',
                              selectedColor: const Color(0xFFFEF3C7),
                              labelStyle: TextStyle(color: halfDayType == 'First Half' ? const Color(0xFFD97706) : const Color(0xFF475569)),
                              onSelected: (_) => setDialogState(() => halfDayType = 'First Half'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Second Half (Afternoon)\n02:00 PM – 06:30 PM', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                              selected: halfDayType == 'Second Half',
                              selectedColor: const Color(0xFFFEF3C7),
                              labelStyle: TextStyle(color: halfDayType == 'Second Half' ? const Color(0xFFD97706) : const Color(0xFF475569)),
                              onSelected: (_) => setDialogState(() => halfDayType = 'Second Half'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Hourly Mode
                      const Text('Date & Leave Hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          backgroundColor: const Color(0xFFF8FAFC),
                        ),
                        icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryBlue),
                        label: Text(DateFormat('EEEE, dd MMM yyyy').format(startDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                              endDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [1, 2, 3, 4].map((hrs) {
                          final isSel = hourlyHours == hrs;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: ChoiceChip(
                                label: Center(child: Text('$hrs hr${hrs > 1 ? "s" : ""}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                                selected: isSel,
                                selectedColor: const Color(0xFFEEF2FF),
                                labelStyle: TextStyle(color: isSel ? AppTheme.primaryBlue : const Color(0xFF475569)),
                                onSelected: (_) => setDialogState(() {
                                  hourlyHours = hrs;
                                  hourlyEndTime = TimeOfDay(
                                    hour: (hourlyStartTime.hour + hrs) % 24,
                                    minute: hourlyStartTime.minute,
                                  );
                                }),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              icon: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF4F46E5)),
                              label: Text('From: ${formatTimeOfDay(hourlyStartTime)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () async {
                                final picked = await showTimePicker(context: context, initialTime: hourlyStartTime);
                                if (picked != null) {
                                  setDialogState(() {
                                    hourlyStartTime = picked;
                                    hourlyEndTime = TimeOfDay(
                                      hour: (picked.hour + hourlyHours) % 24,
                                      minute: picked.minute,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              icon: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF4F46E5)),
                              label: Text('To: ${formatTimeOfDay(hourlyEndTime)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () async {
                                final picked = await showTimePicker(context: context, initialTime: hourlyEndTime);
                                if (picked != null) {
                                  setDialogState(() => hourlyEndTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 3. Leave Type Category
                    const Text('Leave Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: leaveType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        'Casual Leave',
                        'Sick Leave',
                        'Emergency Leave',
                        'Hourly Leave / Short Pass',
                        'Half Day Leave',
                        'Vacation',
                      ]
                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => leaveType = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Reason
                    const Text('Reason for Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        hintText: durationMode == 'Hourly'
                            ? 'Explain reason for short permission / hourly pass...'
                            : 'Please describe the reason for your leave request in detail...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Submit Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.send_rounded, size: 17),
                          label: Text(
                            durationMode == 'Hourly' ? 'Submit Hourly Pass' : (durationMode == 'Half Day' ? 'Submit Half Day' : 'Submit Application'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () async {
                            final reason = reasonController.text.trim();
                            if (reason.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter reason for leave')),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            final taskProvider = context.read<TaskProvider>();
                            final timeSlotStr = '${formatTimeOfDay(hourlyStartTime)} - ${formatTimeOfDay(hourlyEndTime)}';

                            await taskProvider.applyLeave(
                              leaveType: leaveType,
                              startDate: DateFormat('yyyy-MM-dd').format(startDate),
                              endDate: DateFormat('yyyy-MM-dd').format(durationMode == 'Full Day' ? endDate : startDate),
                              reason: reason,
                              durationMode: durationMode,
                              halfDayType: durationMode == 'Half Day' ? halfDayType : null,
                              hourlyHours: durationMode == 'Hourly' ? hourlyHours : null,
                              hourlyTimeSlot: durationMode == 'Hourly' ? timeSlotStr : null,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(durationMode == 'Hourly'
                                    ? 'Hourly Leave Pass submitted successfully!'
                                    : (durationMode == 'Half Day'
                                        ? 'Half Day Leave request submitted successfully!'
                                        : 'Leave Application submitted successfully!')),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLeaveActionDialog(String docId, String action) {
    final remarkController = TextEditingController();
    final isReject = action == 'Rejected';
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 20,
          vertical: 24,
        ),
        child: Container(
          width: isDesktop ? 580 : double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isReject ? Icons.cancel_rounded : Icons.check_circle_rounded, color: isReject ? Colors.red : const Color(0xFF10B981), size: 30),
                  const SizedBox(width: 14),
                  Text(
                    isReject ? 'Reject Leave Application' : 'Approve Leave Application',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: isReject ? Colors.red : const Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isReject
                    ? 'Please provide a reason / remark for rejecting this leave application:'
                    : 'Optional remark / confirmation message for the employee:',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarkController,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  hintText: isReject ? 'Enter rejection reason (e.g. Critical project deadline)...' : 'Enter remarks (optional)...',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReject ? Colors.red : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final remark = remarkController.text.trim();
                      if (isReject && remark.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter reason for rejection')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
                        'status': action,
                        'remark': remark,
                        'reviewedAt': FieldValue.serverTimestamp(),
                      });

                      // Sync with today's attendance if approved
                      if (action == 'Approved') {
                        final leaveSnap = await FirebaseFirestore.instance.collection('leaves').doc(docId).get();
                        final leaveData = leaveSnap.data();
                        if (leaveData != null) {
                          final applicantUid = leaveData['uid'];
                          final start = leaveData['startDate'];
                          final durationMode = leaveData['durationMode'] ?? 'Full Day';
                          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                          if (start == today && applicantUid != null) {
                            final attDocId = '${applicantUid}_$today';
                            await FirebaseFirestore.instance.collection('attendance').doc(attDocId).set({
                              'leaveStatus': 'Approved',
                              'durationMode': durationMode,
                              if (leaveData['halfDayType'] != null) 'halfDayType': leaveData['halfDayType'],
                              if (leaveData['hourlyHours'] != null) 'hourlyHours': leaveData['hourlyHours'],
                              if (leaveData['hourlyTimeSlot'] != null) 'hourlyTimeSlot': leaveData['hourlyTimeSlot'],
                              if (durationMode == 'Half Day') 'status': 'Half Day Present',
                              if (durationMode == 'Hourly') 'status': 'Present (${leaveData['hourlyHours'] ?? 2}h Leave)',
                            }, SetOptions(merge: true));
                          }
                        }
                      }

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Leave Application marked as $action!'),
                          backgroundColor: isReject ? Colors.red : const Color(0xFF10B981),
                        ),
                      );
                    },
                    child: Text(isReject ? 'Confirm Reject' : 'Confirm Approve', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 950;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 540 : double.infinity),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.beach_access_rounded,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Leave Applications Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You haven\'t submitted any leave requests, or all historical applications are archived. Need time off?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Apply for Leave',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _showApplyLeaveDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final role = taskProvider.userRole;
    final isManagerOrAdmin = role == 'manager' || role == 'super_admin';
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Leave Management Portal',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isDesktop ? 22 : 18,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: isDesktop ? 1 : 0,
        centerTitle: !isDesktop,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Apply Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showApplyLeaveDialog,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('leaves').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(context);
              }

              var docs = snapshot.data!.docs;
              if (!isManagerOrAdmin) {
                // Employee only sees their own leaves
                docs = docs.where((d) => (d.data() as Map<String, dynamic>)['uid'] == taskProvider.uid).toList();
              } else if (role == 'manager') {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['managerId'] == taskProvider.uid || data['uid'] == taskProvider.uid;
                }).toList();
              }

              if (docs.isEmpty) {
                return _buildEmptyState(context);
              }

          Widget buildLeaveCard(QueryDocumentSnapshot doc) {
            final data = doc.data() as Map<String, dynamic>;
            final applicantName = data['userName'] ?? 'Employee';
            final leaveType = data['leaveType'] ?? 'Leave';
            final start = data['startDate'] ?? '';
            final end = data['endDate'] ?? '';
            final reason = data['reason'] ?? '';
            final remark = data['remark'] as String?;
            final status = data['status'] ?? 'Pending'; // 'Pending', 'Approved', 'Rejected'
            final durationMode = data['durationMode'] ?? 'Full Day';
            final halfDayType = data['halfDayType'];
            final hourlyHours = data['hourlyHours'];
            final hourlyTimeSlot = data['hourlyTimeSlot'];

            Color statusColor = const Color(0xFFF59E0B);
            if (status == 'Approved') statusColor = const Color(0xFF10B981);
            if (status == 'Rejected') statusColor = const Color(0xFFEF4444);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(applicantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          durationMode == 'Hourly'
                              ? '$leaveType ($start)'
                              : (durationMode == 'Half Day' ? '$leaveType ($start)' : '$leaveType ($start to $end)'),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue, fontSize: 13),
                        ),
                        if (durationMode == 'Hourly')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 4),
                                Text(
                                  ' Hourly: ${hourlyHours ?? 1}h ${hourlyTimeSlot != null ? "($hourlyTimeSlot)" : ""}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                ),
                              ],
                            ),
                          )
                        else if (durationMode == 'Half Day')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tonality_rounded, size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  ' Half Day (${halfDayType ?? "First Half"})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Reason: $reason', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                    if (remark != null && remark.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: status == 'Rejected' ? Colors.red.withOpacity(0.08) : const Color(0xFF10B981).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              status == 'Rejected' ? Icons.info_outline : Icons.check_circle_outline,
                              size: 16,
                              color: status == 'Rejected' ? Colors.red : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Manager Remark: $remark',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: status == 'Rejected' ? Colors.red.shade800 : const Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isManagerOrAdmin && status == 'Pending' && data['uid'] != taskProvider.uid) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red, size: 18),
                            label: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            onPressed: () => _showLeaveActionDialog(doc.id, 'Rejected'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                            onPressed: () => _showLeaveActionDialog(doc.id, 'Approved'),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 850;

              if (isDesktop) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    mainAxisExtent: isManagerOrAdmin ? 250 : 210,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => buildLeaveCard(docs[index]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) => buildLeaveCard(docs[index]),
              );
            },
          );
        },
      ),
        ),
      ),
    );
  }
}
