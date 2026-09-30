import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'providers/task_provider.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.notification != null) {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.showNotification(
      id: message.hashCode,
      title: message.notification!.title ?? 'New Notification',
      body: message.notification!.body ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Enable offline cache persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  await notificationService.scheduleDailyReminders();

  // Setup Firebase Cloud Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      notificationService.showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
      );
    }
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const TodoApp());
}

class SmoothAppScrollBehavior extends MaterialScrollBehavior {
  const SmoothAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: Consumer2<AuthProvider, TaskProvider>(
        builder: (context, authProvider, taskProvider, child) {
          return MaterialApp(
            title: 'RM',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const SmoothAppScrollBehavior(),
            theme: AppTheme.dynamicTheme(taskProvider.selectedThemeColor),
            builder: (context, child) {
              return child!;
            },
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasData) {
                  return taskProvider.isFirstLaunch
                      ? const WelcomeScreen()
                      : const MainNavigationScreen();
                }
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
