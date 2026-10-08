import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  //  FIX: Pre-load welcome screen flag BEFORE app starts
  // Isse Welcome Screen sirf pehli baar dikhegi, baar baar nahi
  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_welcome_screen') ?? false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(TodoApp(hasSeenWelcome: hasSeenWelcome));
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
  final bool hasSeenWelcome;
  const TodoApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: Selector<TaskProvider, Color>(
        selector: (_, provider) => provider.selectedThemeColor,
        builder: (context, themeColor, _) {
          return MaterialApp(
            title: 'RM',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const SmoothAppScrollBehavior(),
            theme: AppTheme.dynamicTheme(themeColor),
            builder: (context, child) {
              return child!;
            },
            home: AppAuthGate(hasSeenWelcome: hasSeenWelcome),
          );
        },
      ),
    );
  }
}

class AppAuthGate extends StatelessWidget {
  final bool hasSeenWelcome;
  const AppAuthGate({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          //  FIX: Pehle pre-loaded flag use karo, phir provider ka state bhi check karo
          // Dono mein se agar kisi ne bhi 'seen' mark kiya hai to Welcome Screen nahi dikhegi
          final providerFirstLaunch = context.select<TaskProvider, bool>((p) => p.isFirstLaunch);
          final showWelcome = !hasSeenWelcome && providerFirstLaunch;
          return showWelcome
              ? const WelcomeScreen()
              : const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
