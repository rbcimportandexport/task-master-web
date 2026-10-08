import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
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
import 'team_chat_screen.dart';
import 'projects_screen.dart';
import '../widgets/assign_task_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static int _persistedCurrentIndex = 0;
  late int _currentIndex;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static bool _hasShownHolidayPopupToday = false;
  static bool _hasShownBirthdayPopupToday = false;
  static bool _hasShownAnniversaryPopupToday = false;

  void _changeTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _persistedCurrentIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _persistedCurrentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().scheduleDailyReminders();
      await _checkAndShowHolidayAlert();
      await _checkAndShowBirthdayAlert();
      await _checkAndShowWorkAnniversaryAlert();
    });
  }

  Future<void> _checkAndShowBirthdayAlert() async {
    if (_hasShownBirthdayPopupToday) return;
    try {
      final today = DateTime.now();
      final todayMonth = today.month;
      final todayDay = today.day;
      final List<Map<String, dynamic>> birthdayUsers = [];

      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in usersSnap.docs) {
        final data = doc.data();
        DateTime? dob;
        if (data.containsKey('dob') && data['dob'] != null) {
          final rawDob = data['dob'];
          if (rawDob is Timestamp) {
            dob = rawDob.toDate();
          } else if (rawDob is String && rawDob.trim().isNotEmpty) {
            dob = DateTime.tryParse(rawDob);
          }
        }

        if (dob != null && dob.month == todayMonth && dob.day == todayDay) {
          birthdayUsers.add({
            'name': data['name'] ?? 'Teammate',
            'role': data['role'] ?? 'employee',
            'profilePic': data['profilePic'] ?? '',
          });
        }
      }

      if (birthdayUsers.isNotEmpty && mounted) {
        _hasShownBirthdayPopupToday = true;
        _showBirthdayPopup(birthdayUsers);
      }
    } catch (e) {
      debugPrint('Error checking birthday alert: $e');
    }
  }

  void _showBirthdayPopup(List<Map<String, dynamic>> birthdayUsers) {
    final names = birthdayUsers.map((u) => u['name'].toString()).join(', ');
    final isMultiple = birthdayUsers.length > 1;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFBCFE8), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDB2777).withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.cake_rounded, color: Color(0xFFDB2777), size: 54),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFBCFE8)),
                ),
                child: const Text(
                  'TODAY\'S BIRTHDAY CELEBRATION',
                  style: TextStyle(color: Color(0xFFBE185D), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Happy Birthday',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                'Aaj hamare ${isMultiple ? "saathiyon" : "bhai"} $names ka Birthday hai!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDB2777), height: 1.3),
              ),
              const SizedBox(height: 10),
              const Text(
                'Wishing you great health, massive success, and lots of happiness from the whole team!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                  label: const Text('Wish Happy Birthday!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB2777),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndShowWorkAnniversaryAlert() async {
    if (_hasShownAnniversaryPopupToday) return;
    try {
      final taskProvider = context.read<TaskProvider>();
      final createdAt = taskProvider.userCreatedAt;
      if (createdAt == null) return;

      final now = DateTime.now();
      final diffDays = now.difference(createdAt).inDays;
      if (diffDays < 0) return;

      String? milestoneTitle;
      String? milestoneSubtitle;
      String? milestoneBadge;

      // Check milestones: 1 Year (365 days / date match), 6 Months (180-183 days), 1 Month (30-31 days)
      final sameDay = now.day == createdAt.day;
      final monthsDiff = (now.year - createdAt.year) * 12 + (now.month - createdAt.month);

      if (now.year > createdAt.year && now.month == createdAt.month && sameDay) {
        final years = now.year - createdAt.year;
        milestoneBadge = '$years YEAR WORK ANNIVERSARY';
        milestoneTitle = 'Congratulations on Completing $years Year${years > 1 ? "s" : ""}!';
        milestoneSubtitle = 'Aapne company me shandaar $years saal pure kar liye hain! Thank you for your dedication, loyalty, and hard work.';
      } else if (monthsDiff == 6 && sameDay) {
        milestoneBadge = '6 MONTHS MILESTONE';
        milestoneTitle = 'Congratulations on Completing 6 Months!';
        milestoneSubtitle = 'Aapne company me safalta-purvak 6 mahine pure kar liye hain! Your contribution and dedication are truly valued.';
      } else if (monthsDiff == 1 && sameDay) {
        milestoneBadge = '1 MONTH MILESTONE';
        milestoneTitle = 'Congratulations on Completing 1 Month!';
        milestoneSubtitle = 'Aapka company me 1 mahina pura ho chuka hai! We are glad to have you in the team. Keep shining!';
      } else if (diffDays == 30) {
        milestoneBadge = '1 MONTH MILESTONE';
        milestoneTitle = 'Congratulations on Completing 1 Month!';
        milestoneSubtitle = 'Aapne company me successfully 1 month complete kiya hai! Keep up the awesome momentum!';
      } else if (diffDays == 180) {
        milestoneBadge = '6 MONTHS MILESTONE';
        milestoneTitle = 'Congratulations on Completing 6 Months!';
        milestoneSubtitle = 'Aapne company me 6 months successfully complete kar liye hain! Keep rocking!';
      } else if (diffDays == 365) {
        milestoneBadge = '1 YEAR WORK ANNIVERSARY';
        milestoneTitle = 'Congratulations on Completing 1 Year!';
        milestoneSubtitle = 'Aapne company me shandaar 1 year complete kiya hai! Proud to have you with us.';
      }

      if (milestoneTitle != null && mounted) {
        _hasShownAnniversaryPopupToday = true;
        _showWorkAnniversaryPopup(
          badge: milestoneBadge ?? 'COMPANY MILESTONE',
          title: milestoneTitle,
          subtitle: milestoneSubtitle ?? 'Keep up the great work!',
        );
      }
    } catch (e) {
      debugPrint('Error checking work anniversary alert: $e');
    }
  }

  void _showWorkAnniversaryPopup({
    required String badge,
    required String title,
    required String subtitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFB45309), size: 56),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.25),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.45),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                  label: const Text('Thank You! Proud to be Here', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndShowHolidayAlert() async {
    if (_hasShownHolidayPopupToday) return;
    try {
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      String? holidayTitle;
      String? holidayDesc;

      // 1. Check Public Holidays in Firestore
      final snap = await FirebaseFirestore.instance.collection('public_holidays').get();
      for (var doc in snap.docs) {
        final data = doc.data();
        DateTime? sDate;
        DateTime? eDate;

        // Parse startDate
        final startRaw = data['startDate'];
        if (startRaw is Timestamp) {
          sDate = DateTime(startRaw.toDate().year, startRaw.toDate().month, startRaw.toDate().day);
        } else if (startRaw is String && startRaw.trim().isNotEmpty) {
          final sStr = startRaw.trim();
          sDate = DateTime.tryParse(sStr.length >= 10 ? sStr.substring(0, 10) : sStr);
        }

        // Parse endDate
        final endRaw = data['endDate'];
        if (endRaw is Timestamp) {
          eDate = DateTime(endRaw.toDate().year, endRaw.toDate().month, endRaw.toDate().day);
        } else if (endRaw is String && endRaw.trim().isNotEmpty) {
          final eStr = endRaw.trim();
          eDate = DateTime.tryParse(eStr.length >= 10 ? eStr.substring(0, 10) : eStr);
        }

        eDate ??= sDate;

        if (sDate != null && eDate != null) {
          if (!todayDateOnly.isBefore(sDate) && !todayDateOnly.isAfter(eDate)) {
            holidayTitle = (data['title'] ?? 'Company Holiday').toString();
            final desc = (data['description'] ?? '').toString().trim();
            holidayDesc = desc.isNotEmpty ? desc : 'Aaj company ki taraf se public holiday / chutti ghoshit ki gayi hai.';
            break;
          }
        }
      }

      // 2. Check Sunday Policy
      if (holidayTitle == null && today.weekday == DateTime.sunday) {
        try {
          final policyDoc = await FirebaseFirestore.instance.collection('company_settings').doc('holiday_policy').get();
          final policy = policyDoc.data()?['sundayPolicy'] ?? 'Full Day Off';
          if (policy != 'Normal Working Day') {
            holidayTitle = 'Sunday Off ($policy)';
            holidayDesc = 'Aaj Ravivar (Sunday) hai. Company policy ke anusaar aaj $policy hai.';
          }
        } catch (_) {}
      }

      if (holidayTitle != null && mounted) {
        _hasShownHolidayPopupToday = true;
        _showHolidayPopup(holidayTitle, holidayDesc ?? 'Enjoy your day off!');
      }
    } catch (e) {
      debugPrint('Error checking holiday in MainNavigation: $e');
    }
  }

  void _showHolidayPopup(String title, String description) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must press button to close
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.celebration_rounded, color: Color(0xFFD97706), size: 54),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'AAJ CHUTTI / HOLIDAY HAI',
                  style: TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.2),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  label: const Text('OK, Samajh Gaya (Got It)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddTaskModal() {
    final taskProvider = context.read<TaskProvider>();
    final initialDate = _currentIndex == 1 ? taskProvider.selectedCalendarDate : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => TaskAddSheet(initialDate: initialDate),
    );
  }

  void _openAssignTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => const AssignTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive desktop breakpoint: If screen width >= 950, render desktop sidebar layout.
    // On phones / mobile browsers / resized narrow windows (width < 950), always render clean native mobile layout.
    final isDesktop = screenWidth >= 950;

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
    
    // Auto-adjust sidebar width: 72px when collapsed, 260-300px when expanded
    final sidebarWidth = _isSidebarCollapsed ? 72.0 : (screenWidth * 0.20).clamp(260.0, 300.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Sleek Left Desktop Sidebar (Clean, Collapsible & Modern)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workspace Brand Header with Collapse/Expand Toggle
                Container(
                  padding: EdgeInsets.fromLTRB(
                    _isSidebarCollapsed ? 12 : 16,
                    20,
                    _isSidebarCollapsed ? 12 : 16,
                    16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                      ),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Task Master',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Warehouse Workspace',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                          _isSidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                          color: const Color(0xFF64748B),
                          size: 22,
                        ),
                        tooltip: _isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Quick Action: Add Task / Assign Task Button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _isSidebarCollapsed ? 10 : 16,
                    14,
                    _isSidebarCollapsed ? 10 : 16,
                    10,
                  ),
                  child: _isSidebarCollapsed
                      ? Center(
                          child: IconButton.filled(
                            onPressed: _openAddTaskModal,
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.all(12),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 24),
                            tooltip: 'Create Task',
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _openAddTaskModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.35),
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text(
                            'Create Task',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                ),

                // Main Nav List
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isSidebarCollapsed ? 6 : 10,
                      vertical: 8,
                    ),
                    children: [
                      if (!_isSidebarCollapsed)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(10, 8, 10, 4),
                          child: Text(
                            'MAIN NAVIGATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      _buildDesktopSidebarItem(
                        icon: Icons.article_rounded,
                        label: 'Tasks & Boards',
                        isSelected: _currentIndex == 0,
                        onTap: () => _changeTab(0),
                        badgeCount: taskProvider.pendingTasksCount,
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.calendar_month_rounded,
                        label: 'Calendar Schedule',
                        isSelected: _currentIndex == 1,
                        onTap: () => _changeTab(1),
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.folder_special_rounded,
                        label: 'Projects & Workspaces',
                        iconColor: const Color(0xFF4F46E5),
                        isSelected: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                          );
                        },
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.person_rounded,
                        label: 'My Profile & Stats',
                        isSelected: _currentIndex == 2,
                        onTap: () => _changeTab(2),
                      ),

                      const SizedBox(height: 12),
                      if (!_isSidebarCollapsed)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(10, 8, 10, 4),
                          child: Text(
                            'OPERATIONS & HR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      _buildDesktopSidebarItem(
                        icon: Icons.fingerprint_rounded,
                        label: 'Attendance & Punch',
                        iconColor: const Color(0xFF10B981),
                        isSelected: _currentIndex == 3,
                        onTap: () => _changeTab(3),
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.event_busy_rounded,
                        label: 'Leave Requests',
                        iconColor: const Color(0xFFF59E0B),
                        isSelected: _currentIndex == 4,
                        onTap: () => _changeTab(4),
                      ),
                      _buildDesktopSidebarItem(
                        icon: Icons.forum_rounded,
                        label: 'Team Discussion & Chat',
                        iconColor: const Color(0xFF6366F1),
                        isSelected: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TeamChatScreen()),
                          );
                        },
                      ),

                      if (isManagerOrAdmin) ...[
                        const SizedBox(height: 12),
                        if (!_isSidebarCollapsed)
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
                      if (!_isSidebarCollapsed)
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

                // User profile footer (Compact & Sleek)
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
                        _changeTab(2); // Switch to Mine & Profile view
                      }
                    },
                    hoverColor: const Color(0xFFEFF6FF),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isSidebarCollapsed ? 10 : 14,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
                            ),
                            child: taskProvider.isLoggedIn && taskProvider.userProfilePic.isNotEmpty
                                ? ClipOval(
                                    child: Image.memory(
                                      base64Decode(taskProvider.userProfilePic),
                                      fit: BoxFit.cover,
                                      width: 38,
                                      height: 38,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      taskProvider.isLoggedIn && taskProvider.userName.isNotEmpty
                                          ? taskProvider.userName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                          ),
                          if (!_isSidebarCollapsed) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    taskProvider.isLoggedIn ? taskProvider.userName : 'Guest User',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    taskProvider.isLoggedIn ? taskProvider.userRole.toUpperCase() : 'TAP TO LOG IN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: taskProvider.isLoggedIn ? const Color(0xFF64748B) : AppTheme.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
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
    return IndexedStack(
      index: _currentIndex.clamp(0, 4),
      children: const [
        TasksScreen(),
        CalendarScreen(),
        MineScreen(),
        AttendanceScreen(),
        LeavesScreen(),
      ],
    );
  }

  Widget _buildCurrentMobileScreen() {
    return IndexedStack(
      index: _currentIndex.clamp(0, 4),
      children: const [
        TasksScreen(),
        CalendarScreen(),
        MineScreen(),
        AttendanceScreen(),
        LeavesScreen(),
      ],
    );
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

    final itemWidget = Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFFF1F5F9),
          splashColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          highlightColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 12 : 14,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? activeColor : const Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (_isSidebarCollapsed) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        child: itemWidget,
      );
    }

    return itemWidget;
  }

  // --- MOBILE VIEW (EXACT MOBILE ORIGINAL LAYOUT) ---
  Widget _buildMobileLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: _buildCurrentMobileScreen(),
      floatingActionButton: _currentIndex != 2
          ? Padding(
              padding: EdgeInsets.only(bottom: screenWidth < 360 ? 6 : 16),
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
          heightFactor: 1.0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            margin: EdgeInsets.fromLTRB(
              screenWidth < 360 ? 10 : 24,
              0,
              screenWidth < 360 ? 10 : 24,
              screenWidth < 360 ? 10 : 20,
            ),
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
      onTap: () => _changeTab(index),
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
