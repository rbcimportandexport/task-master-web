import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    tz.initializeTimeZones();
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      // Default to Asia/Kolkata for IST (+5:30) or matching offset
      if (offset.inMinutes == 330) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } else {
        // Find matching location or fallback
        final locations = tz.timeZoneDatabase.locations;
        bool found = false;
        for (var loc in locations.values) {
          if (loc.currentTimeZone.offset == offset.inMilliseconds) {
            tz.setLocalLocation(loc);
            found = true;
            break;
          }
        }
        if (!found) {
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        }
      }
    } catch (e) {
      debugPrint('Timezone config error: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {}
    }

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ' + (response.payload ?? ''));
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return; 
    
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Notifications for assigned tasks',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> scheduleDailyReminders() async {
    if (kIsWeb) return; 
    await _notificationsPlugin.cancelAll(); 

    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Notifications to remind you to write your tasks',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 1. Morning Reminder: 09:00 AM
    await _scheduleDailyAtTime(
      0,
      '🌅 Good Morning!',
      'Aaj ka kaam likho aur apna din plan karo!',
      9, 0,
      notificationDetails,
    );

    // 2. Manager Daily Attendance Alert: 10:30 AM
    await _scheduleDailyAtTime(
      1030,
      '📊 Daily Team Attendance Alert (10:30 AM)',
      'Manager Alert: Team attendance status check karein aur pending tasks assign/re-assign karein!',
      10, 30,
      notificationDetails,
    );

    // 3. Afternoon Reminder: 02:00 PM (14:00)
    await _scheduleDailyAtTime(
      1,
      '☀️ Afternoon Check-in!',
      'Kya aaj ke tasks update kiye? Check karo!',
      14, 0,
      notificationDetails,
    );

    // 4. Evening Reminder: 07:00 PM (19:00)
    await _scheduleDailyAtTime(
      2,
      '🌙 Evening Wrap-up!',
      'Apne aaj ke pending tasks review karein aur kal ke liye plan karein!',
      19, 0,
      notificationDetails,
    );
  }

  Future<void> scheduleManagerAttendanceAlert({required int totalTeam, required int presentCount}) async {
    if (kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      'manager_attendance_alert',
      'Manager Attendance Alerts',
      channelDescription: 'Daily 10:30 AM Team Attendance Summary for Managers',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _scheduleDailyAtTime(
      1030,
      '👥 Team Attendance Alert (10:30 AM)',
      'Aaj aapki team ke $totalTeam me se $presentCount log present hain.',
      10, 30,
      notificationDetails,
    );
  }

  Future<void> _scheduleDailyAtTime(
      int id, String title, String body, int hour, int minute, NotificationDetails details) async {
    
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute, 0);
      
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
