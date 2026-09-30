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
    String leaveType = 'Casual Leave';
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 20,
            vertical: 24,
          ),
          child: Container(
            width: isDesktop ? 650 : double.infinity,
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.beach_access_rounded, color: AppTheme.primaryBlue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Text('Apply for Leave', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 8),
                  const Text('Leave Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: leaveType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: ['Casual Leave', 'Sick Leave', 'Emergency Leave', 'Vacation']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => leaveType = val);
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text('Leave Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            backgroundColor: const Color(0xFFF8FAFC),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryBlue),
                          label: Text(DateFormat('dd MMM yyyy').format(startDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
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
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('to', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 14)),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            backgroundColor: const Color(0xFFF8FAFC),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryBlue),
                          label: Text(DateFormat('dd MMM yyyy').format(endDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                  const SizedBox(height: 18),
                  const Text('Reason for Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: 'Please describe the reason for your leave request in detail...',
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                          await taskProvider.applyLeave(
                            leaveType: leaveType,
                            startDate: DateFormat('yyyy-MM-dd').format(startDate),
                            endDate: DateFormat('yyyy-MM-dd').format(endDate),
                            reason: reason,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Leave Application submitted successfully!'),
                              backgroundColor: Color(0xFF10B981),
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
        ),
      ),
    );
  }

  void _showLeaveActionDialog(String docId, String action) {
    final remarkController = TextEditingController();
    final isReject = action == 'Rejected';
    final isDesktop = MediaQuery.of(context).size.width >= 850;

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
    final isDesktop = MediaQuery.of(context).size.width >= 850;
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
    final isDesktop = MediaQuery.of(context).size.width >= 850;

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
                    Text('$leaveType ($start to $end)', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue, fontSize: 13)),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 180,
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
