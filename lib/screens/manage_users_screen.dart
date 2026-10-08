import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/assign_task_sheet.dart';
import 'employee_detail_screen.dart';
import 'manager_dashboard_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  String _selectedDeptFilter = 'All';

  void _showRoleManagerSheet(BuildContext context, Map<String, dynamic> userData, String uid) async {
    String currentRole = (userData['role'] ?? 'employee').toString().toLowerCase();
    String currentDepartment = (userData['department'] ?? '').toString().trim();
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

    DateTime? currentJoiningDate;
    if (userData.containsKey('joiningDate') && userData['joiningDate'] != null) {
      final jd = userData['joiningDate'];
      if (jd is Timestamp) {
        currentJoiningDate = jd.toDate();
      } else if (jd is String && jd.trim().isNotEmpty) {
        currentJoiningDate = DateTime.tryParse(jd);
      }
    } else if (userData.containsKey('createdAt') && userData['createdAt'] != null) {
      final ca = userData['createdAt'];
      if (ca is Timestamp) {
        currentJoiningDate = ca.toDate();
      } else if (ca is String && ca.trim().isNotEmpty) {
        currentJoiningDate = DateTime.tryParse(ca);
      }
    }
    currentJoiningDate ??= DateTime.now();

    DateTime? currentDob;
    if (userData.containsKey('dob') && userData['dob'] != null) {
      final db = userData['dob'];
      if (db is Timestamp) {
        currentDob = db.toDate();
      } else if (db is String && db.trim().isNotEmpty) {
        currentDob = DateTime.tryParse(db);
      }
    } else if (userData.containsKey('dobTimestamp') && userData['dobTimestamp'] != null) {
      final dbTs = userData['dobTimestamp'];
      if (dbTs is Timestamp) {
        currentDob = dbTs.toDate();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.manage_accounts_rounded, color: AppTheme.primaryBlue, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage: ${userData['name'] ?? 'Staff'}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                userData['email'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Role selector with card options
                    const Text('Assign User Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRoleOptionChip('employee', 'Employee', Icons.badge_outlined, const Color(0xFF10B981), currentRole, (v) => setModalState(() => currentRole = v)),
                        const SizedBox(width: 8),
                        _buildRoleOptionChip('manager', 'Manager', Icons.supervisor_account_rounded, const Color(0xFF3B82F6), currentRole, (v) => setModalState(() => currentRole = v)),
                        const SizedBox(width: 8),
                        _buildRoleOptionChip('super_admin', 'Admin', Icons.verified_user_rounded, const Color(0xFF8B5CF6), currentRole, (v) => setModalState(() => currentRole = v)),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Text('Department / Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: availableDepts.contains(currentDepartment) ? currentDepartment : (isCustomDept ? '__custom__' : (availableDepts.isNotEmpty ? availableDepts.first : null)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.edit_outlined),
                        ),
                        onChanged: (v) => currentDepartment = v.trim(),
                      ),
                    ],

                    const SizedBox(height: 18),
                    const Text('Assign to Manager / Team Leader', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: currentManagerId.isEmpty ? '' : (potentialManagers.any((m) => m['uid'] == currentManagerId) ? currentManagerId : ''),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

                    const SizedBox(height: 18),
                    // Joining Date Picker for SuperAdmin
                    const Text('Company Joining Date (Edit / Fix)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: currentJoiningDate ?? DateTime.now(),
                          firstDate: DateTime(2015),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                          helpText: 'Select Official Joining Date',
                        );
                        if (picked != null) {
                          setModalState(() {
                            currentJoiningDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentJoiningDate != null
                                    ? DateFormat('d MMMM yyyy').format(currentJoiningDate!)
                                    : 'Select Joining Date',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_rounded, color: Color(0xFF64748B), size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    // Birthday (Date of Birth) Picker for SuperAdmin
                    const Text('Birthday / Date of Birth (Edit / Fix)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: currentDob ?? DateTime(now.year - 22, now.month, now.day),
                          firstDate: DateTime(1960),
                          lastDate: DateTime(now.year - 10, now.month, now.day),
                          helpText: 'Select Employee Birthday',
                        );
                        if (picked != null) {
                          setModalState(() {
                            currentDob = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_rounded, color: Color(0xFFEC4899), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentDob != null
                                    ? DateFormat('d MMMM yyyy').format(currentDob!)
                                    : 'Select Birthday (DOB)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_rounded, color: Color(0xFF64748B), size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final finalDept = isCustomDept ? departmentController.text.trim() : currentDepartment.trim();
                            final updatePayload = <String, dynamic>{
                              'role': currentRole,
                              'department': finalDept,
                              'managerId': currentManagerId,
                            };
                            if (currentJoiningDate != null) {
                              updatePayload['joiningDate'] = Timestamp.fromDate(currentJoiningDate!);
                              updatePayload['createdAt'] = Timestamp.fromDate(currentJoiningDate!);
                            }
                            if (currentDob != null) {
                              updatePayload['dob'] = DateFormat('yyyy-MM-dd').format(currentDob!);
                              updatePayload['dobTimestamp'] = Timestamp.fromDate(currentDob!);
                            }
                            await _firestore.collection('users').doc(uid).update(updatePayload);
                            if (ctx.mounted) Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${userData['name']} updated: $finalDept / ${currentRole.toUpperCase()}!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating user: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleOptionChip(String roleValue, String label, IconData icon, Color color, String activeRole, ValueChanged<String> onSelect) {
    final isSelected = activeRole == roleValue;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(roleValue),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF64748B), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : const Color(0xFF475569),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteEmployee(BuildContext context, Map<String, dynamic> userData, String uid) {
    final name = userData['name'] ?? 'Employee';
    final email = userData['email'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Employee?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove "$name" ($email)?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'All tasks, data and manager mappings associated with this employee will be deleted. This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<TaskProvider>().deleteEmployee(uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '$name deleted successfully!' : 'Failed to delete employee.'),
                    backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete Employee'),
          ),
        ],
      ),
    );
  }

  void _showAssignWorkSheet(BuildContext context, Map<String, dynamic> userData, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssignTaskSheet(
        employeeId: uid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('All Employees & Role Controller', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Add New Employee',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddEmployeeDialog(),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading users'));
          }

          final allDocs = snapshot.data?.docs ?? [];
          final Set<String> allDepts = {'All'};
          for (var d in allDocs) {
            final data = d.data() as Map<String, dynamic>;
            final dept = data['department'];
            if (dept != null && dept.toString().trim().isNotEmpty) {
              allDepts.add(dept.toString().trim());
            }
          }

          // Filter by search query, role filter, dept filter
          final filteredUsers = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final role = (data['role'] ?? 'employee').toString().toLowerCase();
            final dept = (data['department'] ?? '').toString();

            final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || email.contains(_searchQuery);
            final matchesRole = _selectedRoleFilter == 'All' || role == _selectedRoleFilter.toLowerCase();
            final matchesDept = _selectedDeptFilter == 'All' || dept == _selectedDeptFilter;

            return matchesSearch && matchesRole && matchesDept;
          }).toList();

          return Column(
            children: [
              // Search & Filter header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search employee by name or email...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quick Filter Chips (All, Employees, Managers, Admins)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Roles', _selectedRoleFilter == 'All', () => setState(() => _selectedRoleFilter = 'All')),
                          const SizedBox(width: 8),
                          _buildFilterChip('Employees', _selectedRoleFilter == 'employee', () => setState(() => _selectedRoleFilter = 'employee')),
                          const SizedBox(width: 8),
                          _buildFilterChip('Managers', _selectedRoleFilter == 'manager', () => setState(() => _selectedRoleFilter = 'manager')),
                          const SizedBox(width: 8),
                          _buildFilterChip('Super Admins', _selectedRoleFilter == 'super_admin', () => setState(() => _selectedRoleFilter = 'super_admin')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Staff count stats bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: const Color(0xFFF1F5F9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL STAFF: ${filteredUsers.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569), letterSpacing: 0.5),
                    ),
                    const Text(
                      'Tap  for Quick Work / Role change',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.group_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            const Text('No staff found matching filters.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final doc = filteredUsers[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unknown User';
                          final email = data['email'] ?? 'No email';
                          final role = data['role'] ?? 'employee';
                          final department = data['department'] ?? 'Unassigned';
                          final profilePic = data['profilePic'] ?? '';

                          Color roleColor = const Color(0xFF10B981);
                          IconData roleIcon = Icons.badge_outlined;
                          if (role == 'super_admin') {
                            roleColor = const Color(0xFF8B5CF6);
                            roleIcon = Icons.verified_user_rounded;
                          } else if (role == 'manager') {
                            roleColor = const Color(0xFF3B82F6);
                            roleIcon = Icons.supervisor_account_rounded;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Profile Picture
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: roleColor.withOpacity(0.12),
                                    backgroundImage: profilePic.isNotEmpty ? MemoryImage(base64Decode(profilePic)) : null,
                                    child: profilePic.isEmpty
                                        ? Text(
                                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 18),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                        const SizedBox(height: 2),
                                        Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: roleColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(roleIcon, size: 12, color: roleColor),
                                                  const SizedBox(width: 4),
                                                  Text(role.toUpperCase(), style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            if (department.toString().isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  department.toString().toUpperCase(),
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Quick Buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Assign Task Button
                                      IconButton(
                                        icon: const Icon(Icons.add_task_rounded, color: AppTheme.primaryBlue, size: 20),
                                        tooltip: 'Assign Work/Task',
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showAssignWorkSheet(context, data, doc.id),
                                      ),
                                      const SizedBox(width: 4),
                                      // View Work / Details Button
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, color: Color(0xFF64748B), size: 19),
                                        tooltip: 'View Work & Tasks',
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EmployeeDetailScreen(
                                                employeeId: doc.id,
                                                employeeName: name,
                                                employeeEmail: email,
                                                profilePicBase64: profilePic,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      // Change Role Button
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 22),
                                        tooltip: 'Change Role / Department',
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showRoleManagerSheet(context, data, doc.id),
                                      ),
                                      const SizedBox(width: 4),
                                      // Delete Employee Button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        tooltip: 'Delete Employee',
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _confirmDeleteEmployee(context, data, doc.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
