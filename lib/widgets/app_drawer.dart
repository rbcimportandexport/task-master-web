import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';
import '../screens/settings_screen.dart';
import '../screens/theme_screen.dart';
import '../screens/manager_dashboard_screen.dart';
import '../screens/super_admin_dashboard.dart';
import '../screens/widget_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/leaves_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recycle_bin_screen.dart';
import '../screens/holiday_policy_screen.dart';
import '../screens/manage_users_screen.dart';
import '../screens/team_chat_screen.dart';
import '../screens/projects_screen.dart';
import 'assign_task_sheet.dart';
import 'feedback_dialog.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isCategoryExpanded = true; // Open by default or expandable

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    final taskProvider = context.read<TaskProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Category name (e.g. Shopping, Fitness)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                taskProvider.addCategory(
                  controller.text.trim(),
                  Icons.folder_outlined,
                  const Color(0xFF3B82F6),
                );
                taskProvider.setSelectedCategory(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header with Profile and Date
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (taskProvider.isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        ),
                        child: taskProvider.isLoggedIn
                          ? (taskProvider.userProfilePic.isNotEmpty
                              ? ClipOval(
                                  child: Image.memory(
                                    base64Decode(taskProvider.userProfilePic),
                                    fit: BoxFit.cover,
                                    width: 56,
                                    height: 56,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    taskProvider.userName.isNotEmpty ? taskProvider.userName.substring(0, 1).toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ))
                          : const Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ),
                    Row(
                      children: [
                        // Notification Bell
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: taskProvider.notificationsStream,
                          builder: (context, snapshot) {
                            int unreadCount = 0;
                            if (snapshot.hasData) {
                              unreadCount = snapshot.data!.where((n) => !(n['isRead'] ?? false)).length;
                            }
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
                                  onPressed: () {
                                    Navigator.pop(context); // Close drawer
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                    );
                                  },
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    top: 6,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Calendar Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    if (taskProvider.isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          taskProvider.isLoggedIn ? taskProvider.userName : 'Welcome! (Tap to log in)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${DateFormat('EEEE').format(DateTime.now())}, ${DateFormat('MMMM d, yyyy').format(DateTime.now())}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Projects & PDF Workspace
          _buildDrawerItem(
            icon: Icons.folder_special_rounded,
            iconColor: const Color(0xFF4F46E5),
            title: 'Projects & Files',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProjectsScreen()),
              );
            },
          ),

          // Attendance
          _buildDrawerItem(
            icon: Icons.fingerprint,
            iconColor: const Color(0xFF10B981),
            title: 'Attendance',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceScreen()),
              );
            },
          ),

          // Leave Management
          _buildDrawerItem(
            icon: Icons.event_busy_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Leave Requests',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeavesScreen()),
              );
            },
          ),

          // Assign Task (Only for Manager & Super Admin)
          if (taskProvider.userRole == 'manager' || taskProvider.userRole == 'super_admin')
            _buildDrawerItem(
              icon: Icons.assignment_ind_rounded,
              iconColor: AppTheme.primaryBlue,
              title: 'Assign Task',
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AssignTaskSheet(),
                );
              },
            ),
          
          // 2. Starred Tasks
          _buildDrawerItem(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Starred Tasks',
            badgeCount: taskProvider.starredTasks.length,
            onTap: () {
              Navigator.pop(context);
              taskProvider.setSelectedCategory('All');
            },
          ),

          // 3. Category (Expandable - Screenshot 19)
          ListTile(
            leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF3B82F6), size: 22),
            title: const Text(
              'Category',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            ),
            trailing: Icon(
              _isCategoryExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: const Color(0xFF94A3B8),
            ),
            onTap: () {
              setState(() {
                _isCategoryExpanded = !_isCategoryExpanded;
              });
            },
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          ),

          if (_isCategoryExpanded) ...[
            ...taskProvider.categories.map((cat) {
              final count = cat.name.toLowerCase() == 'all'
                  ? taskProvider.tasks.length
                  : taskProvider.tasks.where((t) => t.category.toLowerCase() == cat.name.toLowerCase()).length;

              final isAll = cat.name.toLowerCase() == 'all';

              return ListTile(
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isAll) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                        tooltip: 'Delete "${cat.name}" category',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: Row(
                                children: [
                                  const Icon(Icons.delete_forever_rounded, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('Delete "${cat.name}"?'),
                                ],
                              ),
                              content: Text('Kya aap "${cat.name}" category delete karna chahte hain? Is category ke tasks safe rahenge.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    taskProvider.deleteCategory(cat.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Category "${cat.name}" deleted!')),
                                    );
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                dense: true,
                contentPadding: const EdgeInsets.only(left: 24, right: 16),
                onTap: () {
                  taskProvider.setSelectedCategory(cat.name);
                  Navigator.pop(context);
                },
              );
            }),
            // + Create New (Screenshot 19)
            ListTile(
              leading: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.add, color: AppTheme.primaryBlue, size: 20),
              ),
              title: const Text(
                'Create New',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              dense: true,
              contentPadding: const EdgeInsets.only(left: 24, right: 28),
              onTap: () {
                Navigator.pop(context);
                _showAddCategoryDialog(context);
              },
            ),
          ],

          // Team Discussion & Chat Channel
          _buildDrawerItem(
            icon: Icons.forum_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Team Discussion & Chat',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamChatScreen()),
              );
            },
          ),

          // 3.5. Manager Dashboard (Only for managers)
          if (taskProvider.userRole == 'manager')
            _buildDrawerItem(
              icon: Icons.admin_panel_settings_rounded,
              iconColor: const Color(0xFF60A5FA),
              title: 'Team Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagerDashboardScreen()),
                );
              },
            ),
            
          // Super Admin Dashboard & Controls
          if (taskProvider.userRole == 'super_admin') ...[
            _buildDrawerItem(
              icon: Icons.business_center_rounded,
              iconColor: const Color(0xFF6366F1),
              title: 'All Departments (Edit / Delete)',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.admin_panel_settings_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Company Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagerDashboardScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: 'All Staff & Role Controller',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Holiday & Sunday Policy',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HolidayPolicyScreen()),
                );
              },
            ),
          ],

          // 4. Theme (Screenshot 16)
          _buildDrawerItem(
            icon: Icons.brush_rounded,
            iconColor: const Color(0xFF60A5FA),
            title: 'Theme',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeScreen()),
              );
            },
          ),

          // 5. Widget (Screenshots 17 & 18)
          _buildDrawerItem(
            icon: Icons.widgets_outlined,
            iconColor: const Color(0xFF60A5FA),
            title: 'Widget',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WidgetScreen()),
              );
            },
          ),


          // 7. Recycle Bin (Restore Deleted Tasks)
          _buildDrawerItem(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFEF4444),
            title: 'Recycle Bin',
            badgeCount: taskProvider.deletedTasks.length,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
              );
            },
          ),

          // 11. Settings
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            iconColor: const Color(0xFF60A5FA),
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          // Send Feedback
          _buildDrawerItem(
            icon: Icons.feedback_outlined,
            iconColor: const Color(0xFF6366F1),
            title: 'Send Feedback',
            onTap: () {
              Navigator.pop(context);
              FeedbackDialog.show(context);
            },
          ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // 12. Switch Account / Log Out
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFEF4444),
            title: 'Switch Account (Log Out)',
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: trailing ??
          (badgeCount != null && badgeCount > 0
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              : null),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      onTap: onTap,
    );
  }

}


