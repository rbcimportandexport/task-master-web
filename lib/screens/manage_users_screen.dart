import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showRoleManagerSheet(BuildContext context, Map<String, dynamic> userData, String uid) {
    String currentRole = userData['role'] ?? 'employee';
    String currentDepartment = userData['department'] ?? '';
    final departmentController = TextEditingController(text: currentDepartment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage ${userData['name'] ?? 'User'}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text('Role', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: ['employee', 'manager', 'super_admin'].contains(currentRole) ? currentRole : 'employee',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'employee', child: Text('Employee')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                      DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => currentRole = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Department', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: departmentController,
                    decoration: InputDecoration(
                      hintText: 'e.g. IT, Sales, Support',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
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
                            const SnackBar(content: Text('User updated successfully!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating user: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Users & Roles', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
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

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown User';
              final email = data['email'] ?? 'No email';
              final role = data['role'] ?? 'employee';
              final department = data['department'] ?? 'No department';

              Color roleColor = Colors.grey;
              if (role == 'super_admin') roleColor = Colors.purple;
              else if (role == 'manager') roleColor = Colors.blue;
              else if (role == 'employee') roleColor = Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: roleColor),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          if (department.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(department.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: () => _showRoleManagerSheet(context, data, doc.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
