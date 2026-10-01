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
import 'assign_task_sheet.dart';

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

              return ListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Icons.description_outlined, color: Color(0xFF94A3B8), size: 20),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  '$count',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                dense: true,
                contentPadding: const EdgeInsets.only(left: 24, right: 28),
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
            
          // Super Admin Dashboard
          if (taskProvider.userRole == 'super_admin')
            _buildDrawerItem(
              icon: Icons.admin_panel_settings_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Company Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagerDashboardScreen()), // Routes to same screen, but UI handles role
                );
              },
            ),

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

          // 6. FAQ
          _buildDrawerItem(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF60A5FA),
            title: 'FAQ',
            onTap: () {
              Navigator.pop(context);
              _showFaqDialog(context);
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
          const SizedBox(height: 16),
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

  void _showSaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFFFA000)),
            SizedBox(width: 8),
            Text('Special PRO Offer'),
          ],
        ),
        content: const Text('Get Unlimited Cloud Sync, Widgets, Custom Themes & Subtasks at 60% OFF today!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Claim Offer'),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('FAQ'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Q: How to add a task?\nA: Tap the "+" button at the bottom right.', style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text('Q: How to set due dates?\nA: Tap the calendar icon in task creation sheet.', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Share your thoughts or report a bug...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFollowUsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Follow Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFE1306C), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
                title: const Text('Instagram (@todolist.app)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final url = Uri.parse('https://instagram.com');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
                  child: const Icon(Icons.facebook, color: Colors.white, size: 20),
                ),
                title: const Text('Facebook Page'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final url = Uri.parse('https://facebook.com');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDonateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.coffee_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Support Development'),
          ],
        ),
        content: const Text(
          'If you enjoy using To-Do List, consider buying us a coffee! Your support keeps the app free and updated.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Maybe Later')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you so much for your generosity!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Buy a Coffee (\$3)'),
          ),
        ],
      ),
    );
  }

  void _showFamilyAppsDialog(BuildContext context) {
    final apps = [
      {'name': 'Habit Tracker Pro', 'desc': 'Build good daily routines', 'icon': Icons.track_changes_rounded, 'color': Colors.green},
      {'name': 'Focus Pomodoro Timer', 'desc': 'Boost productivity with timers', 'icon': Icons.timer_rounded, 'color': Colors.orange},
      {'name': 'Daily Journal & Diary', 'desc': 'Keep your private thoughts safe', 'icon': Icons.book_rounded, 'color': Colors.purple},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Family Apps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...apps.map(
                (a) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: (a['color'] as Color).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(a['icon'] as IconData, color: a['color'] as Color),
                  ),
                  title: Text(a['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(a['desc'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening ${a['name']} in Store...')),
                      );
                    },
                    child: const Text('Get'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


