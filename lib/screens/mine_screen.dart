import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/annual_heatmap.dart';
import '../widgets/analytics_charts.dart';
import 'profile_screen.dart';

class MineScreen extends StatelessWidget {
  const MineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF8FAFC) : Colors.white,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: isDesktop
              ? const EdgeInsets.fromLTRB(36, 32, 36, 36)
              : const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
              // 1. Desktop Profile Header (Full-width banner card with tall height)
              Container(
                constraints: BoxConstraints(minHeight: isDesktop ? 130 : 80),
                padding: isDesktop ? const EdgeInsets.symmetric(horizontal: 32, vertical: 30) : const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: isDesktop ? 84 : 56,
                      height: isDesktop ? 84 : 56,
                      decoration: BoxDecoration(
                        color: taskProvider.isLoggedIn ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(color: taskProvider.isLoggedIn ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0), width: 2.5),
                      ),
                      child: taskProvider.isLoggedIn
                          ? (taskProvider.userProfilePic.isNotEmpty
                              ? ClipOval(
                                  child: Image.memory(
                                    base64Decode(taskProvider.userProfilePic),
                                    fit: BoxFit.cover,
                                    width: isDesktop ? 84 : 56,
                                    height: isDesktop ? 84 : 56,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    taskProvider.userName.isNotEmpty ? taskProvider.userName.substring(0, 1).toUpperCase() : 'U',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 28 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ))
                          : Icon(
                              Icons.person_rounded,
                              size: isDesktop ? 40 : 34,
                              color: const Color(0xFF94A3B8),
                            ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  taskProvider.isLoggedIn ? taskProvider.userName : 'Kept to your plan for 1 day!',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 22 : 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (taskProvider.isLoggedIn && isDesktop) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    taskProvider.userRole.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            taskProvider.isLoggedIn ? taskProvider.userEmail : 'Click to login',
                            style: TextStyle(
                              fontSize: isDesktop ? 15 : 14,
                              fontWeight: FontWeight.w500,
                              color: taskProvider.isLoggedIn ? const Color(0xFF64748B) : AppTheme.primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (taskProvider.isLoggedIn)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF334155),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showLoginDialog(context, taskProvider),
                        child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 2. Task Metric Highlights (Large, Imposing Metric Cards with generous height)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 650;
                  final card1 = Container(
                    constraints: BoxConstraints(minHeight: isCompact ? 120 : 190),
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 24 : 48,
                      horizontal: isCompact ? 24 : 36,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Completed Tasks',
                                style: TextStyle(
                                  fontSize: isCompact ? 16 : 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isCompact ? 8 : 14),
                              Text(
                                '${taskProvider.completedTasksCount}',
                                style: TextStyle(
                                  fontSize: isCompact ? 38 : 54,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(isCompact ? 14 : 22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.task_alt_rounded, color: Colors.white, size: isCompact ? 32 : 46),
                        ),
                      ],
                    ),
                  );

                  final card2 = Container(
                    constraints: BoxConstraints(minHeight: isCompact ? 120 : 190),
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 24 : 48,
                      horizontal: isCompact ? 24 : 36,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pending Tasks',
                                style: TextStyle(
                                  fontSize: isCompact ? 16 : 18,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isCompact ? 8 : 14),
                              Text(
                                '${taskProvider.pendingTasksCount}',
                                style: TextStyle(
                                  fontSize: isCompact ? 38 : 54,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(isCompact ? 14 : 22),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: isCompact ? 32 : 46),
                        ),
                      ],
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        card1,
                        const SizedBox(height: 16),
                        card2,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: 24),
                      Expanded(child: card2),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // 3. Analytics Cards in Responsive Grid Layout for Desktop
              LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 760;
                  if (useTwoColumns) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: CompletedTasksOverviewCard(
                                completedCount: taskProvider.completedTasksCount,
                                pendingCount: taskProvider.pendingTasksCount,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: DailyCompletedCard(taskCount: taskProvider.completedTasksCount),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              flex: 1,
                              child: FocusTrackerCard(),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              flex: 1,
                              child: TasksNext7DaysCard(),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        CompletedTasksOverviewCard(
                          completedCount: taskProvider.completedTasksCount,
                          pendingCount: taskProvider.pendingTasksCount,
                        ),
                        const SizedBox(height: 16),
                        DailyCompletedCard(taskCount: taskProvider.completedTasksCount),
                        const SizedBox(height: 16),
                        const FocusTrackerCard(),
                        const SizedBox(height: 16),
                        const TasksNext7DaysCard(),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context, TaskProvider provider) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Login to Account', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
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
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && emailCtrl.text.trim().isNotEmpty) {
                provider.login(nameCtrl.text.trim(), emailCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Welcome back, ${nameCtrl.text.trim()}!')),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              provider.logout();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully.')),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}




