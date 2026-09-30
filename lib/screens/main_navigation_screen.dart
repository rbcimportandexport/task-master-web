import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_add_sheet.dart';
import 'tasks_screen.dart';
import 'calendar_screen.dart';
import 'mine_screen.dart';
import 'attendance_screen.dart';
import 'leaves_screen.dart';
import 'manager_dashboard_screen.dart';
import 'super_admin_dashboard.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';
import 'profile_screen.dart';
import '../widgets/assign_task_sheet.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _mobileScreens = const [
    TasksScreen(),
    CalendarScreen(),
    MineScreen(),
  ];

  void _openAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskAddSheet(),
    );
  }

  void _openAssignTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AssignTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = kIsWeb ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux ||
        screenWidth >= 768;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }

    return _buildMobileLayout(context);
  }

  // --- DESKTOP WEB / WINDOW MODE LAYOUT ---
  Widget _buildDesktopLayout(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isManagerOrAdmin = taskProvider.userRole.toLowerCase() == 'manager' ||
        taskProvider.userRole.toLowerCase() == 'super admin';
    final screenWidth = MediaQuery.of(context).size.width;
    // Auto-adjust sidebar width dynamically from 360 to 480 for prominent, clear desktop proportions
    final sidebarWidth = (screenWidth * 0.24).clamp(360.0, 480.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Sleek Left Desktop Sidebar (Noticeably Large, Spacious & Bold)
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workspace Brand Header (Large)
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 18),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Master',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.8,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Warehouse Workspace',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Quick Action: Add Task / Assign Task Button (Extra Large & Imposing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                  child: ElevatedButton.icon(
                    onPressed: _openAddTaskModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.40),
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 32),
                    label: const Text(
                      'Create Task',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                ),

                // Main Nav List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: Text(
                          'MAIN NAVIGATION',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.article_rounded,
                        label: 'Tasks & Boards',
                        isSelected: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                        badgeCount: taskProvider.pendingTasksCount,
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.calendar_month_rounded,
                        label: 'Calendar Schedule',
                        isSelected: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.person_rounded,
                        label: 'My Profile & Stats',
                        isSelected: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),

                      const SizedBox(height: 18),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: Text(
                          'OPERATIONS & HR',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.fingerprint_rounded,
                        label: 'Attendance & Punch',
                        iconColor: const Color(0xFF10B981),
                        isSelected: _currentIndex == 3,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.event_busy_rounded,
                        label: 'Leave Requests',
                        iconColor: const Color(0xFFF59E0B),
                        isSelected: _currentIndex == 4,
                        onTap: () => setState(() => _currentIndex = 4),
                      ),

                      if (isManagerOrAdmin) ...[
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
                          child: Text(
                            'MANAGEMENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        _buildDesktopSidebarItem(
                          icon: Icons.assignment_ind_rounded,
                          label: 'Assign Task to Staff',
                          iconColor: const Color(0xFF8B5CF6),
                          isSelected: false,
                          onTap: _openAssignTaskModal,
                        ),
                        if (taskProvider.userRole.toLowerCase() == 'manager')
                          _buildDesktopSidebarItem(
                            icon: Icons.dashboard_customize_rounded,
                            label: 'Manager Dashboard',
                            iconColor: const Color(0xFF3B82F6),
                            isSelected: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ManagerDashboardScreen()),
                              );
                            },
                          ),
                        if (taskProvider.userRole.toLowerCase() == 'super admin')
                          _buildDesktopSidebarItem(
                            icon: Icons.admin_panel_settings_rounded,
                            label: 'Super Admin Portal',
                            iconColor: const Color(0xFFEF4444),
                            isSelected: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
                              );
                            },
                          ),
                      ],

                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
                        child: Text(
                          'PREFERENCES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.notifications_rounded,
                        label: 'Notifications',
                        isSelected: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.palette_outlined,
                        label: 'Themes & Colors',
                        isSelected: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ThemeScreen()),
                          );
                        },
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.account_circle_outlined,
                        label: 'My Account & Profile',
                        isSelected: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        isSelected: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // User profile footer (Noticeably Large & Clickable)
                Material(
                  color: const Color(0xFFF8FAFC),
                  child: InkWell(
                    onTap: () {
                      if (taskProvider.isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      } else {
                        setState(() => _currentIndex = 2); // Switch to Mine & Profile view
                      }
                    },
                    hoverColor: const Color(0xFFEFF6FF),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC7D2FE), width: 2),
                            ),
                            child: taskProvider.isLoggedIn && taskProvider.userProfilePic.isNotEmpty
                                ? ClipOval(
                                    child: Image.memory(
                                      base64Decode(taskProvider.userProfilePic),
                                      fit: BoxFit.cover,
                                      width: 52,
                                      height: 52,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      taskProvider.isLoggedIn && taskProvider.userName.isNotEmpty
                                          ? taskProvider.userName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  taskProvider.isLoggedIn ? taskProvider.userName : 'Guest User',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  taskProvider.isLoggedIn ? taskProvider.userRole.toUpperCase() : 'TAP TO LOG IN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: taskProvider.isLoggedIn ? const Color(0xFF64748B) : AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Full-Screen Expanded View Area (Window Desktop Mode)
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: _buildCurrentDesktopScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDesktopScreen() {
    switch (_currentIndex) {
      case 0:
        return const TasksScreen();
      case 1:
        return const CalendarScreen();
      case 2:
        return const MineScreen();
      case 3:
        return const AttendanceScreen();
      case 4:
        return const LeavesScreen();
      default:
        return const TasksScreen();
    }
  }

  Widget _buildDesktopSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
    int? badgeCount,
  }) {
    final activeColor = AppTheme.primaryBlue;
    final color = isSelected ? activeColor : (iconColor ?? const Color(0xFF475569));
    final bgColor = isSelected ? const Color(0xFFEEF2FF) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: const Color(0xFFF1F5F9),
          splashColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          highlightColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? activeColor : const Color(0xFF1E293B),
                      fontSize: 19,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MOBILE VIEW (EXACT MOBILE ORIGINAL LAYOUT) ---
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      extendBody: true,
      drawer: const AppDrawer(),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: IndexedStack(
            index: _currentIndex.clamp(0, _mobileScreens.length - 1),
            children: _mobileScreens,
          ),
        ),
      ),
      floatingActionButton: _currentIndex != 2
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton(
                onPressed: _openAddTaskModal,
                backgroundColor: AppTheme.fabBlue,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 1. Drawer Trigger
                  InkWell(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF64748B),
                        size: 26,
                      ),
                    ),
                  ),

                  // 2. Tasks Tab
                  _buildNavItem(
                    index: 0,
                    icon: Icons.article_rounded,
                    label: 'Tasks',
                  ),

                  // 3. Calendar Tab
                  _buildNavItem(
                    index: 1,
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendar',
                  ),

                  // 4. Mine Tab
                  _buildNavItem(
                    index: 2,
                    icon: Icons.person_rounded,
                    label: 'Mine',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryBlue : const Color(0xFF94A3B8);
    final bgColor = isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
