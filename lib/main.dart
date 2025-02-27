import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_task_app/core/app_life_cucle_listener.dart';
import 'package:smart_task_app/core/global.dart';
import 'package:smart_task_app/core/notification_service.dart';
import 'package:smart_task_app/core/splash_screen.dart';
import 'package:smart_task_app/firebase_options.dart';

import 'package:smart_task_app/provider/all_task_provider.dart';
import 'package:smart_task_app/provider/get_tag_provider.dart';
import 'package:smart_task_app/provider/get_task_tag_provider.dart';
import 'package:smart_task_app/provider/get_user_provider.dart';
import 'package:smart_task_app/provider/header_provider.dart';
import 'package:smart_task_app/provider/login_data.dart';
import 'package:smart_task_app/provider/search_provider.dart';
import 'package:smart_task_app/provider/task_provider.dart';
import 'package:smart_task_app/provider/theme_provider.dart';
import 'package:smart_task_app/provider/online_status_provider.dart';

// Define global navigator key here at the top level
// final GlobalKey<NavigatorState> navigatorKeys = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize NotificationService
  await NotificationService().initialize();

  // Simulate a splash screen delay
  await Future.delayed(const Duration(seconds: 2));

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (context) => LoginData()),
        ChangeNotifierProvider(create: (_) => HeaderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => GetUserProvider()),
        ChangeNotifierProvider(create: (_) => GetTagProvider()),
        ChangeNotifierProvider(create: (_) => AllTaskProvider()),
        ChangeNotifierProvider(create: (_) => GetTaskTagProvider()),
        ChangeNotifierProvider(create: (_) => OnlineStatusProvider()),
      ],
      child:  const AppOnlineStatusListener(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          navigatorKey: navigatorKey, // Use the global navigatorKey here
          home: SplashScreen(),
        );
      },
    );
  }
}
