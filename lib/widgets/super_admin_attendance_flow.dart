import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class SuperAdminAttendanceFlow extends StatefulWidget {
  const SuperAdminAttendanceFlow({super.key});

  @override
  State<SuperAdminAttendanceFlow> createState() => _SuperAdminAttendanceFlowState();
}

class _SuperAdminAttendanceFlowState extends State<SuperAdminAttendanceFlow> {
  String? selectedDepartment;
  Map<String, dynamic>? selectedManager;
  String? currentViewType; // 'manager', 'team', 'team_member', or 'all_employees'
  Map<String, dynamic>? selectedTeamMember;

  @override
  Widget build(BuildContext context) {
    if (currentViewType == 'all_employees') {
      return _buildAllEmployeesList();
    } else if (selectedDepartment == null) {
      return _buildDepartmentsList();
    } else if (selectedManager == null) {
      return _buildManagersList();
    } else if (currentViewType == 'team') {
      return _buildTeamMembersList();
    } else if (currentViewType == 'manager' || currentViewType == 'team_member') {
      return _buildAttendanceView();
    }
    return const SizedBox.shrink();
  }


  Widget _buildAllEmployeesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    currentViewType = null;
                  });
                },
              ),
              const Expanded(
                child: Text('All Employees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'employee').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No employees found.'));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final email = data['email'] ?? '';
                  final profilePic = data['profilePic'] as String?;
                  final dept = data['department'] ?? 'Unassigned';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                            ? MemoryImage(const Base64Decoder().convert(profilePic.split(',').last))
                            : null,
                        child: (profilePic == null || profilePic.isEmpty)
                            ? const Icon(Icons.person, color: Color(0xFF94A3B8))
                            : null,
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('Dept: $dept', style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
                      onTap: () {
                        _showAssignDepartmentDialog(doc.id, data);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAssignDepartmentDialog(String uid, Map<String, dynamic> userData) {
    final TextEditingController deptController = TextEditingController(text: userData['department'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Assign Department for ${userData['name']}'),
          content: TextField(
            controller: deptController,
            decoration: InputDecoration(
              labelText: 'Department Name',
              hintText: 'e.g. IT, Sales, Support',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newDept = deptController.text.trim();
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'department': newDept,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department updated!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDepartmentsList() {
    final taskProvider = context.watch<TaskProvider>();
    return FutureBuilder<List<String>>(
      future: taskProvider.getDepartments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No departments found.'));
        }

        final depts = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                          const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Department', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF6366F1), // Indigo
                      child: Icon(Icons.people_alt, color: Colors.white),
                    ),
                    title: const Text('All Employees', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('View and assign departments'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      setState(() {
                        currentViewType = 'all_employees';
                      });
                    },
                  ),
                ),
              ),
              Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: depts.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.chipActiveBg,
                        child: Icon(Icons.business, color: Colors.white),
                      ),
                      title: Text(depts[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        setState(() {
                          selectedDepartment = depts[index];
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagersList() {
    final taskProvider = context.watch<TaskProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedDepartment = null;
                  });
                },
              ),
              Expanded(
                child: Text('Managers in $selectedDepartment', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: taskProvider.getManagersByDepartment(selectedDepartment!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No managers found in this department.'));
              }

              final managers = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: managers.length,
                itemBuilder: (context, index) {
                  final mgr = managers[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF10B981),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(mgr['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(mgr['email'] ?? ''),
                      onTap: () => _showManagerOptions(mgr),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  

  Widget _buildTeamMembersList() {
    final taskProvider = context.watch<TaskProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    currentViewType = null;
                  });
                },
              ),
              Expanded(
                child: Text('${selectedManager!['name']}\'s Team Members', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: taskProvider.getEmployeesByManager(selectedManager!['uid']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No team members found for this manager.'));
              }

              final members = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final profilePic = member['profilePic'] as String?;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF3B82F6),
                        backgroundImage: (profilePic != null && profilePic.isNotEmpty) 
                            ? MemoryImage(const Base64Decoder().convert(profilePic.split(',').last)) 
                            : null,
                        child: (profilePic == null || profilePic.isEmpty) 
                            ? const Icon(Icons.person, color: Colors.white) 
                            : null,
                      ),
                      title: Text(member['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(member['email'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        setState(() {
                          selectedTeamMember = member;
                          currentViewType = 'team_member';
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
void _showManagerOptions(Map<String, dynamic> mgr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View Attendance for ${mgr['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person, color: AppTheme.primaryBlue),
                title: const Text('View Manager Attendance'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    selectedManager = mgr;
                    currentViewType = 'manager';
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups, color: AppTheme.primaryBlue),
                title: const Text('View Team Attendance'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    selectedManager = mgr;
                    currentViewType = 'team';
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceView() {
    final taskProvider = context.read<TaskProvider>();
    
    // Determine whose attendance to show
    final targetUid = currentViewType == 'manager' ? selectedManager!['uid'] : selectedTeamMember!['uid'];
    final targetName = currentViewType == 'manager' ? selectedManager!['name'] : selectedTeamMember!['name'];
    
    final stream = taskProvider.getSpecificUserAttendanceStream(targetUid);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (currentViewType == 'team_member') {
                      currentViewType = 'team'; // go back to team list
                      selectedTeamMember = null;
                    } else {
                      selectedManager = null;
                      currentViewType = null;
                    }
                  });
                },
              ),
              Expanded(
                child: Text(
                  "$targetName's Attendance",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildAttendanceListInline(stream),
        ),
      ],
    );
  }

  Widget _buildAttendanceListInline(Stream<List<Map<String, dynamic>>> stream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading attendance.\n${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No attendance records found.', style: TextStyle(color: Color(0xFF64748B))),
            ),
          );
        }

        final records = snapshot.data!;

        int totalDaysPresent = records.length;
        double totalHours = 0.0;

        Duration computeWorkDuration(Timestamp? inTs, Timestamp? outTs) {
          if (inTs == null || outTs == null) return Duration.zero;
          final inDt = inTs.toDate();
          final outDt = outTs.toDate();
          
          // First attempt exact datetime difference
          int seconds = outDt.difference(inDt).inSeconds;
          if (seconds <= 0) {
            // Calculate by time of day on 24-hr clock
            final inSec = inDt.hour * 3600 + inDt.minute * 60 + inDt.second;
            final outSec = outDt.hour * 3600 + outDt.minute * 60 + outDt.second;
            seconds = outSec - inSec;
            if (seconds < 0) seconds += 24 * 3600; // wrapped past midnight
          }
          return Duration(seconds: seconds < 0 ? 0 : seconds);
        }

        for (var rec in records) {
          final inTs = rec['checkIn'] as Timestamp?;
          final outTs = rec['checkOut'] as Timestamp?;
          if (inTs != null && outTs != null) {
            final dur = computeWorkDuration(inTs, outTs);
            if (dur.inMinutes > 0) {
              totalHours += dur.inMinutes / 60.0;
            }
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: records.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Days', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('$totalDaysPresent Days', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        const Text('Total Hours', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${totalHours.toStringAsFixed(1)} hrs', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        const Text('Monthly Ratio', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${((totalDaysPresent / 30.0) * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            }

            final data = records[index - 1];
            final checkInTs = data['checkIn'] as Timestamp?;
            final checkOutTs = data['checkOut'] as Timestamp?;
            final photoBase64 = data['photo'] as String?;
            final dateStr = data['date'] ?? '';
            final nameStr = data['userName'] ?? '';
            final statusStr = data['status'] ?? 'Present';

            String checkInStr = '--:--';
            String checkOutStr = '--:--';
            String durationStr = '';
            
            try {
              if (checkInTs != null) {
                checkInStr = DateFormat('hh:mm a').format(checkInTs.toDate());
              }
              if (checkOutTs != null) {
                checkOutStr = DateFormat('hh:mm a').format(checkOutTs.toDate());
              }
              if (checkInTs != null && checkOutTs != null) {
                final dur = computeWorkDuration(checkInTs, checkOutTs);
                final hours = dur.inHours;
                final minutes = dur.inMinutes.remainder(60);
                durationStr = '⏱️ ${hours}h ${minutes}m worked';
              } else if (checkInTs != null) {
                durationStr = '🟡 In office (Punch Out pending)';
              }
            } catch (_) {}

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        image: (photoBase64 != null && photoBase64.isNotEmpty)
                            ? DecorationImage(
                                image: MemoryImage(
                                  const Base64Decoder().convert(photoBase64.split(',').last),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (photoBase64 == null || photoBase64.isEmpty)
                          ? const Icon(Icons.person, color: Color(0x8894A3B8), size: 30)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameStr.isNotEmpty ? '$dateStr ($nameStr)' : dateStr,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.login_rounded, color: Color(0xFF10B981), size: 15),
                              const SizedBox(width: 4),
                              Text(checkInStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(width: 12),
                              const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 15),
                              const SizedBox(width: 4),
                              Text(checkOutStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          if (durationStr.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(durationStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ]
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusStr, style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
