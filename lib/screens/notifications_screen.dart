import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: taskProvider.notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['isRead'] ?? false;
              final timestamp = notif['timestamp'] as Timestamp?;
              final timeString = timestamp != null
                  ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                  : "";

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    taskProvider.markNotificationAsRead(notif['id']);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isRead ? null : Border.all(color: const Color(0xFF60A5FA).withOpacity(0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRead ? AppTheme.surfaceLight : const Color(0xFF60A5FA).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: isRead ? AppTheme.textSecondary : const Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['message'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                color: AppTheme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              timeString,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
