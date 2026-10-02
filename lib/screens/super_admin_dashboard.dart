import '../services/export_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'employee_detail_screen.dart';
import 'manage_users_screen.dart';
import 'holiday_policy_screen.dart';

import 'dart:convert';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  List<String> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final provider = context.read<TaskProvider>();
    final depts = await provider.getDepartments();
    // Add default ones if empty for demonstration
    if (depts.isEmpty) depts.addAll(['Marketing', 'IT', 'Sales']);
    if (mounted) {
      setState(() {
        _departments = depts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Super Admin Dashboard', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Export Reports',
            onSelected: (value) async {
              try {
                if (value == 'attendance') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Attendance Report...')));
                  await ExportService.exportMonthlyReport();
                } else if (value == 'tasks') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Tasks Report...')));
                  await ExportService.exportTasksReport();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'attendance',
                child: Row(
                  children: [
                    Icon(Icons.how_to_reg, color: AppTheme.primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text('Export Attendance Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tasks',
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: AppTheme.primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text('Export Tasks Report'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B)),
            tooltip: 'Holiday & Sunday Policy',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidayPolicyScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: AppTheme.primaryBlue),
            tooltip: 'All Employees & Role Controller',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final dept = _departments[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DepartmentManagersScreen(department: dept)));
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.business_center_rounded, size: 40, color: AppTheme.primaryBlue),
                        const SizedBox(height: 12),
                        Text(dept, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class DepartmentManagersScreen extends StatefulWidget {
  final String department;
  const DepartmentManagersScreen({super.key, required this.department});

  @override
  State<DepartmentManagersScreen> createState() => _DepartmentManagersScreenState();
}

class _DepartmentManagersScreenState extends State<DepartmentManagersScreen> {
  List<Map<String, dynamic>> _managers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    final provider = context.read<TaskProvider>();
    final managers = await provider.getManagersByDepartment(widget.department);
    if (mounted) {
      setState(() {
        _managers = managers;
        _isLoading = false;
      });
    }
  }

  void _showManagerOptions(BuildContext context, String managerId, String managerName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Options for $managerName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.assignment, color: AppTheme.primaryBlue)),
              title: const Text('View Manager Work'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employeeId: managerId, employeeName: managerName, employeeEmail: '', profilePicBase64: '')));
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.groups, color: AppTheme.primaryBlue)),
              title: const Text('View Manager Team'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManagerTeamScreen(managerId: managerId, title: "$managerName's Team")));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.department} Staff & Team', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _managers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text('No staff found in ${widget.department} department.', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _managers.length,
                  itemBuilder: (context, index) {
                    final staff = _managers[index];
                    final role = (staff['role'] ?? 'employee').toString().toLowerCase();
                    Color roleColor = const Color(0xFF10B981);
                    if (role == 'super_admin') roleColor = const Color(0xFF8B5CF6);
                    else if (role == 'manager') roleColor = const Color(0xFF3B82F6);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: roleColor.withOpacity(0.12),
                          backgroundImage: (staff['profilePic'] != null && staff['profilePic'].isNotEmpty) ? MemoryImage(base64Decode(staff['profilePic'])) : null,
                          child: (staff['profilePic'] == null || staff['profilePic'].isEmpty) ? Text(staff['name'] != null && staff['name'].isNotEmpty ? staff['name'][0].toUpperCase() : 'U', style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)) : null,
                        ),
                        title: Text(staff['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff['email'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text((staff['role'] ?? 'Employee').toString().toUpperCase(), style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.more_vert),
                        onTap: () => _showManagerOptions(context, staff['uid'], staff['name'] ?? 'Staff'),
                      ),
                    );
                  },
                ),
    );
  }
}

class ManagerTeamScreen extends StatefulWidget {
  final String managerId;
  final String title;
  const ManagerTeamScreen({super.key, required this.managerId, required this.title});

  @override
  State<ManagerTeamScreen> createState() => _ManagerTeamScreenState();
}

class _ManagerTeamScreenState extends State<ManagerTeamScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final provider = context.read<TaskProvider>();
    final employees = await provider.getEmployeesByManager(widget.managerId);
    if (mounted) {
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const Center(child: Text('No employees found in this team.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final emp = _employees[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE2E8F0),
                          backgroundImage: (emp['profilePic'] != null && emp['profilePic'].isNotEmpty) ? MemoryImage(base64Decode(emp['profilePic'])) : null,
                          child: (emp['profilePic'] == null || emp['profilePic'].isEmpty) ? const Icon(Icons.person, color: Color(0xFF94A3B8)) : null,
                        ),
                        title: Text(emp['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp['email'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text((emp['role'] ?? 'Employee').toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employeeId: emp['uid'], employeeName: emp['name'] ?? 'Unknown', employeeEmail: emp['email'] ?? '', profilePicBase64: emp['profilePic'])));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
