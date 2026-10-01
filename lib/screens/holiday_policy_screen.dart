import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class HolidayPolicyScreen extends StatefulWidget {
  const HolidayPolicyScreen({super.key});

  @override
  State<HolidayPolicyScreen> createState() => _HolidayPolicyScreenState();
}

class _HolidayPolicyScreenState extends State<HolidayPolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoadingSunday = false;
  String _currentSundayPolicy = 'Full Day Off'; // 'Full Day Off', 'Half Day Working', 'Full Day Working'
  String _sundayPolicyNote = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSundayPolicy();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSundayPolicy() async {
    try {
      final doc = await _firestore.collection('company_settings').doc('holiday_policy').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _currentSundayPolicy = data['sundayPolicy'] ?? 'Full Day Off';
          _sundayPolicyNote = data['sundayPolicyNote'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading sunday policy: $e');
    }
  }

  Future<void> _updateSundayPolicy(String newPolicy, String note) async {
    setState(() => _isLoadingSunday = true);
    try {
      await _firestore.collection('company_settings').doc('holiday_policy').set({
        'sundayPolicy': newPolicy,
        'sundayPolicyNote': note,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': context.read<TaskProvider>().userName,
      }, SetOptions(merge: true));

      setState(() {
        _currentSundayPolicy = newPolicy;
        _sundayPolicyNote = note;
      });

      // Broadcast push/in-app notification to all users
      final provider = context.read<TaskProvider>();
      String notifTitle = 'Sunday Policy Updated';
      String notifBody = 'Company Announcement: Sunday is configured as $newPolicy.${note.isNotEmpty ? " Note: $note" : ""}';
      await provider.broadcastNotificationToAllUsers(title: notifTitle, message: notifBody);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sunday Policy updated to "$newPolicy" & Notification sent to all employees!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating policy: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSunday = false);
    }
  }

  void _showAddHolidayDialog([DocumentSnapshot? editDoc]) {
    final titleController = TextEditingController(text: editDoc != null ? editDoc['title'] : '');
    final descriptionController = TextEditingController(text: editDoc != null ? (editDoc['description'] ?? '') : '');
    DateTime startDate = editDoc != null ? DateTime.parse(editDoc['startDate']) : DateTime.now();
    DateTime endDate = editDoc != null ? DateTime.parse(editDoc['endDate']) : DateTime.now();
    String holidayType = editDoc != null ? (editDoc['type'] ?? 'Festival / Public Holiday') : 'Festival / Public Holiday';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(editDoc != null ? Icons.edit_calendar_rounded : Icons.celebration_rounded, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  editDoc != null ? 'Edit Holiday' : 'Add Public Holiday',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Holiday Name / Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Diwali Holiday, Eid, Independence Day',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Holiday Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: holidayType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Festival / Public Holiday', child: Text('Festival / Public Holiday')),
                      DropdownMenuItem(value: 'Company Event / Off', child: Text('Company Event / Off')),
                      DropdownMenuItem(value: 'Emergency / Government Holiday', child: Text('Emergency / Gov Holiday')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => holidayType = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Start Date Picker
                  const Text('Start Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                          if (endDate.isBefore(startDate)) endDate = startDate;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd MMMM yyyy').format(startDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryBlue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // End Date Picker
                  const Text('End Date (Same for single day)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                        firstDate: startDate,
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd MMMM yyyy').format(endDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryBlue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Optional Note / Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Office will remain completely closed during this period.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter holiday title')));
                    return;
                  }

                  final startStr = DateFormat('yyyy-MM-dd').format(startDate);
                  final endStr = DateFormat('yyyy-MM-dd').format(endDate);
                  final daysCount = endDate.difference(startDate).inDays + 1;

                  final payload = {
                    'title': title,
                    'type': holidayType,
                    'startDate': startStr,
                    'endDate': endStr,
                    'daysCount': daysCount,
                    'description': descriptionController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'createdBy': context.read<TaskProvider>().userName,
                  };

                  Navigator.pop(ctx);

                  if (editDoc != null) {
                    await _firestore.collection('public_holidays').doc(editDoc.id).update(payload);
                  } else {
                    await _firestore.collection('public_holidays').add(payload);
                  }

                  // Broadcast notification to all staff
                  final notifMsg = 'Holiday Announcement: "$title" from ${DateFormat('d MMM').format(startDate)} to ${DateFormat('d MMM yyyy').format(endDate)} ($daysCount day${daysCount > 1 ? "s" : ""}).';
                  await context.read<TaskProvider>().broadcastNotificationToAllUsers(
                    title: '🎉 Public Holiday: $title',
                    message: notifMsg,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Holiday "$title" saved & notification broadcasted!'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                child: Text(editDoc != null ? 'Update Holiday' : 'Save Holiday', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Holiday & Sunday Policy', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.wb_sunny_rounded, size: 20), text: 'Sunday Policy'),
            Tab(icon: Icon(Icons.celebration_rounded, size: 20), text: 'Public Holidays'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSundayPolicyTab(),
          _buildPublicHolidaysTab(),
        ],
      ),
    );
  }

  Widget _buildSundayPolicyTab() {
    final policies = [
      {
        'id': 'Full Day Off',
        'title': 'Full Day Off (Weekly Holiday)',
        'subtitle': 'Sunday is a complete weekly off. Attendance is not required.',
        'icon': Icons.beach_access_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'Half Day Working',
        'title': 'Half Day Working (4 Hours Shift)',
        'subtitle': 'Sunday is active as half day. Employees punch in for 4 hours.',
        'icon': Icons.timelapse_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'Full Day Working',
        'title': 'Full Day Working (Normal Duty)',
        'subtitle': 'Sunday is a regular working day with normal hours & duties.',
        'icon': Icons.work_rounded,
        'color': const Color(0xFF10B981),
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-Notify Staff on Policy Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
                    SizedBox(height: 4),
                    Text(
                      'Jab aap Sunday ka status (Off / Half-Day / Full-Day) update karenge, tab har employee ke phone par instant notification bhej diya jayega.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('Select Active Sunday Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),

        ...policies.map((p) {
          final isSelected = _currentSundayPolicy == p['id'];
          final color = p['color'] as Color;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isSelected ? color : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
            ),
            elevation: isSelected ? 2 : 0,
            color: isSelected ? color.withOpacity(0.04) : Colors.white,
            child: InkWell(
              onTap: () {
                _showConfirmSundayDialog(p['id'] as String, p['title'] as String);
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(p['icon'] as IconData, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSelected ? color : const Color(0xFF0F172A),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['subtitle'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? color : const Color(0xFFCBD5E1),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        if (_sundayPolicyNote.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Current Note: "$_sundayPolicyNote"', style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showConfirmSundayDialog(String policyId, String policyTitle) {
    final noteController = TextEditingController(text: _sundayPolicyNote);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Sunday as $policyId?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aapke confirm karte hi saare employees ko notification chala jayega ki Sunday ko "$policyId" rakha gaya hai.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text('Announcement Note / Remark (Optional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: 'e.g. Applicable for this upcoming Sunday only.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateSundayPolicy(policyId, noteController.text.trim());
            },
            child: const Text('Confirm & Notify All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicHolidaysTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Holiday', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddHolidayDialog(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('public_holidays').orderBy('startDate', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.celebration_rounded, color: AppTheme.primaryBlue, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Public Holidays Configured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  const Text('Tap "Add Holiday" to configure Diwali, Eid, or festival leaves.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Holiday';
              final type = data['type'] ?? 'Festival';
              final startStr = data['startDate'] ?? '';
              final endStr = data['endDate'] ?? '';
              final daysCount = data['daysCount'] ?? 1;
              final desc = data['description'] ?? '';

              String formattedDateRange = startStr;
              try {
                final sDt = DateTime.parse(startStr);
                final eDt = DateTime.parse(endStr);
                if (startStr == endStr) {
                  formattedDateRange = DateFormat('EEEE, d MMMM yyyy').format(sDt);
                } else {
                  formattedDateRange = '${DateFormat('d MMM yyyy').format(sDt)}  ➔  ${DateFormat('d MMM yyyy').format(eDt)}';
                }
              } catch (_) {}

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.celebration_rounded, color: Color(0xFFEC4899), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text(type, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$daysCount Day${daysCount > 1 ? "s" : ""}',
                              style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                            onSelected: (val) async {
                              if (val == 'edit') {
                                _showAddHolidayDialog(doc);
                              } else if (val == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Holiday?'),
                                    content: Text('Are you sure you want to delete "$title"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _firestore.collection('public_holidays').doc(doc.id).delete();
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_rounded, color: AppTheme.primaryBlue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(formattedDateRange, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                            ),
                          ],
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
