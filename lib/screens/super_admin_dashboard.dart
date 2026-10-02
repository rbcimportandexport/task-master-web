import '../services/export_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'employee_detail_screen.dart';
import 'manage_users_screen.dart';
import 'manager_dashboard_screen.dart';
import 'holiday_policy_screen.dart';
import '../widgets/assign_task_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _showEditDepartmentDialog(String oldDept) async {
    final controller = TextEditingController(text: oldDept);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Edit Department Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Renaming "$oldDept" will automatically update all staff and team members belonging to this department.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Department Name',
                  hintText: 'e.g. Technology / HR',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.business_center_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a department name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newName = controller.text.trim();
                Navigator.pop(context);
                if (newName == oldDept) return;

                setState(() => _isLoading = true);
                final provider = context.read<TaskProvider>();
                final success = await provider.updateDepartmentName(oldDept, newName);
                await _loadDepartments();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Department "$oldDept" renamed to "$newName" successfully!' : 'Failed to update department name.'),
                      backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
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
                childAspectRatio: 1.05,
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
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.business_center_rounded, size: 36, color: AppTheme.primaryBlue),
                                const SizedBox(height: 10),
                                Text(
                                  dept,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF94A3B8)),
                            tooltip: 'Rename Department',
                            splashRadius: 18,
                            onPressed: () => _showEditDepartmentDialog(dept),
                          ),
                        ),
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

  void _showStaffOptions(BuildContext context, Map<String, dynamic> staffData) {
    final String staffId = staffData['uid'] ?? '';
    final String staffName = staffData['name'] ?? 'Staff Member';
    final String staffEmail = staffData['email'] ?? '';
    final String profilePic = staffData['profilePic'] ?? '';
    final String role = (staffData['role'] ?? 'employee').toString().toLowerCase();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staffName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text(staffEmail, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 1. Assign Task / Work Directly
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.add_task_rounded, color: Color(0xFF2563EB))),
              title: const Text('Assign Work / Task', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              subtitle: const Text('Directly assign task to this person'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => AssignTaskSheet(employeeId: staffId),
                );
              },
            ),

            // 2. View Work & Progress
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF0FDF4), child: Icon(Icons.assignment_outlined, color: Color(0xFF16A34A))),
              title: const Text('View Work & Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              subtitle: const Text('Check completed & pending tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employeeId: staffId, employeeName: staffName, employeeEmail: staffEmail, profilePicBase64: profilePic)));
              },
            ),

            // 3. If Manager or Admin, View Team
            if (role == 'manager' || role == 'super_admin')
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFAF5FF), child: Icon(Icons.groups_rounded, color: Color(0xFF9333EA))),
                title: const Text('View Assigned Team', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                subtitle: const Text('Check employees reporting to this manager'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ManagerTeamScreen(managerId: staffId, title: "$staffName's Team")));
                },
              ),

            // 4. Change Role or Move Department
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFFFBEB), child: Icon(Icons.manage_accounts_rounded, color: Color(0xFFD97706))),
              title: const Text('Change Role & Department', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              subtitle: const Text('Promote to Manager / change team'),
              onTap: () {
                Navigator.pop(context);
                _showRoleManagerSheet(context, staffData, staffId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleManagerSheet(BuildContext context, Map<String, dynamic> userData, String uid) async {
    String currentRole = (userData['role'] ?? 'employee').toString().toLowerCase();
    String currentDepartment = (userData['department'] ?? widget.department).toString().trim();
    String currentManagerId = (userData['managerId'] ?? '').toString().trim();

    final taskProvider = context.read<TaskProvider>();
    final List<String> availableDepts = await taskProvider.getDepartments();
    final List<Map<String, dynamic>> allUsers = await taskProvider.getEmployees();
    final List<Map<String, dynamic>> potentialManagers = allUsers.where((u) {
      final r = (u['role'] ?? '').toString().toLowerCase();
      return (r == 'manager' || r == 'super_admin') && u['uid'] != uid;
    }).toList();

    if (!context.mounted) return;

    final departmentController = TextEditingController(text: currentDepartment);
    bool isCustomDept = currentDepartment.isNotEmpty && !availableDepts.contains(currentDepartment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage Role, Department & Team: ${userData['name'] ?? 'Staff'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Role', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: ['employee', 'manager', 'super_admin'].contains(currentRole) ? currentRole : 'employee',
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'employee', child: Text('Employee')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                      DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => currentRole = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Department / Team', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: availableDepts.contains(currentDepartment) ? currentDepartment : (isCustomDept ? '__custom__' : (availableDepts.isNotEmpty ? availableDepts.first : null)),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.business_center_rounded),
                    ),
                    items: [
                      ...availableDepts.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))),
                      const DropdownMenuItem(value: '__custom__', child: Text('+ Type New Department...')),
                    ],
                    onChanged: (val) {
                      if (val == '__custom__') {
                        setModalState(() {
                          isCustomDept = true;
                          currentDepartment = '';
                          departmentController.clear();
                        });
                      } else if (val != null) {
                        setModalState(() {
                          isCustomDept = false;
                          currentDepartment = val;
                          departmentController.text = val;
                        });
                      }
                    },
                  ),
                  if (isCustomDept) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: departmentController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter new department name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.edit_outlined),
                      ),
                      onChanged: (v) => currentDepartment = v.trim(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Assign to Manager / Team Leader', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: currentManagerId.isEmpty ? '' : (potentialManagers.any((m) => m['uid'] == currentManagerId) ? currentManagerId : ''),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.groups_rounded),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('No Manager Assigned (Direct)')),
                      ...potentialManagers.map((mgr) => DropdownMenuItem(
                        value: mgr['uid'] as String,
                        child: Text('${mgr['name'] ?? 'Manager'} (${mgr['department'] ?? 'General'})'),
                      )),
                    ],
                    onChanged: (val) {
                      setModalState(() => currentManagerId = val ?? '');
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () async {
                        final finalDept = isCustomDept ? departmentController.text.trim() : currentDepartment.trim();
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({
                          'role': currentRole,
                          'department': finalDept,
                          'managerId': currentManagerId,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadManagers();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff role, department & manager updated!'), backgroundColor: Color(0xFF10B981)));
                        }
                      },
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
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
        title: Text('${widget.department} Staff & Team', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Add Member to ${widget.department}',
            onPressed: () async {
              final added = await showDialog<bool>(
                context: context,
                builder: (_) => AddEmployeeDialog(initialDepartment: widget.department),
              );
              if (added == true) {
                _loadManagers();
              }
            },
          ),
        ],
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
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                        label: Text('Add Member to ${widget.department}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final added = await showDialog<bool>(
                            context: context,
                            builder: (_) => AddEmployeeDialog(initialDepartment: widget.department),
                          );
                          if (added == true) {
                            _loadManagers();
                          }
                        },
                      ),
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
                        onTap: () => _showStaffOptions(context, staff),
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
    final cleanTitle = widget.title.trim().startsWith('\'') ? 'Team Members' : widget.title;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(cleanTitle, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No employees assigned to this manager yet.',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'You can assign employees to this team from the "All Employees & Role Controller" screen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
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
