import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'employee_detail_screen.dart';
import 'super_admin_dashboard.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String _selectedDepartment = 'All';
  List<String> _departments = ['All'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<TaskProvider>();
    final users = await provider.getEmployees();
    
    Set<String> depts = {'All'};
    for (var u in users) {
      if ((u['role'] == 'manager' || u['role'] == 'super_admin') && u['department'] != null && u['department'].toString().isNotEmpty) {
        depts.add(u['department']);
      }
    }
    
    if (mounted) {
      setState(() {
        _allUsers = users; 
        _departments = depts.toList();
        _isLoading = false;
      });
    }
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEmployeeDialog(),
    ).then((_) => _loadData());                
  }
  
  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<TaskProvider>().userRole;
    final myUid = context.watch<TaskProvider>().uid;
    
    List<Map<String, dynamic>> displayList = [];
    
    if (userRole == 'super_admin') {
      displayList = _allUsers.where((u) => u['role'] == 'manager' || u['role'] == 'super_admin').toList();
      if (_selectedDepartment != 'All') {
        displayList = displayList.where((u) => (u['department'] ?? 'Unassigned') == _selectedDepartment).toList();
      }
    } else {
      displayList = _allUsers.where((u) => u['managerId'] == myUid || (context.read<TaskProvider>().userEmail.toLowerCase().contains('inquiry') && u['email'] == 'rbcsaurabhyadav@gmail.com')).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(userRole == 'super_admin' ? 'Company Managers' : 'My Team', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryBlue),
            onPressed: _showAddEmployeeDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (userRole == 'super_admin')
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _departments.map((dept) {
                  final isSelected = _selectedDepartment == dept;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(dept),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDepartment = dept;
                        });
                      },
                      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryBlue : const Color(0xFF475569),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? Center(child: Text(userRole == 'super_admin' ? 'No managers found.' : 'No employees in your team yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final emp = displayList[index];
                          final name = emp['name'] ?? 'Unknown';
                          final email = emp['email'] ?? '';
                          final profilePic = emp['profilePic'] ?? '';
                          final department = emp['department'] ?? 'Unassigned';
                          final role = (emp['role'] ?? 'EMPLOYEE').toString().toUpperCase();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE2E8F0),
                                backgroundImage: profilePic.isNotEmpty ? MemoryImage(base64Decode(profilePic)) : null,
                                child: profilePic.isEmpty ? const Icon(Icons.person, color: Color(0xFF94A3B8)) : null,
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text(department, style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: (role == 'MANAGER' || role == 'SUPER_ADMIN') ? const Color(0xFFF59E0B).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text(role, style: TextStyle(fontSize: 10, color: (role == 'MANAGER' || role == 'SUPER_ADMIN') ? const Color(0xFFF59E0B) : const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                              onTap: () {
                                if (userRole == 'super_admin') {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                    builder: (context) => Container(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Options for ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 20),
                                          ListTile(          
                                            leading: const CircleAvatar(backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.assignment, color: AppTheme.primaryBlue)),
                                            title: const Text('View Manager Work'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employeeId: emp['uid'], employeeName: name, employeeEmail: email, profilePicBase64: profilePic)));
                                            },
                                          ),
                                          ListTile(
                                            leading: const CircleAvatar(backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.groups, color: AppTheme.primaryBlue)),
                                            title: const Text('View Manager Team'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => ManagerTeamScreen(managerId: emp['uid'], title: "'s Team")));
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employeeId: emp['uid'], employeeName: name, employeeEmail: email, profilePicBase64: profilePic)));
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class AddEmployeeDialog extends StatefulWidget {
  final String? initialDepartment;
  const AddEmployeeDialog({super.key, this.initialDepartment});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedDept = 'Marketing';
  bool _isLoading = false;
  List<String> _departments = ['Marketing', 'Sales', 'IT', 'HR', 'Finance', 'Operations'];

  @override
  void initState() {
    super.initState();
    if (widget.initialDepartment != null && widget.initialDepartment!.trim().isNotEmpty) {
      _selectedDept = widget.initialDepartment!.trim();
      if (!_departments.contains(_selectedDept)) {
        _departments.add(_selectedDept);
      }
    }
    _loadDepts();
  }

  Future<void> _loadDepts() async {
    final depts = await context.read<TaskProvider>().getDepartments();
    if (mounted) {
      setState(() {
        final combined = {..._departments, ...depts}.toList();
        _departments = combined;
        if (!_departments.contains(_selectedDept)) {
          _selectedDept = _departments.first;
        }
      });
    }
  }

  Future<void> _add() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
       return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<TaskProvider>().addEmployee(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedDept,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Employee added successfully to $_selectedDept!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding employee: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add New Employee', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Temporary Password', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDept,
              decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDept = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _add,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Employee'),
        ),
      ],
    );
  }
}


