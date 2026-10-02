import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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

  void _showRoleManagerSheet(BuildContext context, Map<String, dynamic> userData, String uid) {
    String currentRole = userData['role'] ?? 'employee';
    String currentDepartment = userData['department'] ?? '';
    final departmentController = TextEditingController(text: currentDepartment);
    final nameController = TextEditingController(text: userData['name'] ?? '');

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
                              'Edit ${userData['name'] ?? 'User'}',
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
                  const Text('Department / Designation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: departmentController,
                    decoration: InputDecoration(
                      hintText: 'e.g. IT, Sales, Logistics, Support, HR',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _firestore.collection('users').doc(uid).update({
                            'role': currentRole,
                            'department': departmentController.text.trim(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${userData['name']} is now set to ${currentRole.toUpperCase()}!'),
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
                      child: const Text('Save Role & Department', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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
                      'Tap ⚡ for Quick Work / Role change',
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
                                        icon: const Icon(Icons.add_task_rounded, color: AppTheme.primaryBlue, size: 22),
                                        tooltip: 'Assign Work/Task',
                                        onPressed: () => _showAssignWorkSheet(context, data, doc.id),
                                      ),
                                      // View Work / Details Button
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, color: Color(0xFF64748B), size: 20),
                                        tooltip: 'View Work & Tasks',
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
                                      // Change Role Button
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 24),
                                        tooltip: 'Change Role / Department',
                                        onPressed: () => _showRoleManagerSheet(context, data, doc.id),
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
