import 'package:flutter/material.dart';
import 'package:smart_task_app/core/api_client.dart';
import 'package:smart_task_app/core/splash_screen.dart';
import 'package:smart_task_app/provider/get_tag_provider.dart';
import 'package:smart_task_app/provider/get_user_provider.dart';
import 'package:smart_task_app/provider/header_provider.dart';
import 'package:smart_task_app/provider/search_provider.dart';
import 'package:smart_task_app/provider/login_data.dart';
import 'package:provider/provider.dart';
import 'package:smart_task_app/provider/task_provider.dart';
import 'package:smart_task_app/provider/theme_provider.dart';
import 'package:smart_task_app/widget/projects/project_modal_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(
    const Duration(seconds: 2),
  ); // Simulating a splash screen delay
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (context) => LoginData()),
        ChangeNotifierProvider(create: (_) => HeaderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => HeaderProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => GetUserProvider()),
        ChangeNotifierProvider(create: (_) => GetTagProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          navigatorKey: navigatorKey,
          home: SplashScreen(),
        );
      },
    );
  }
}
