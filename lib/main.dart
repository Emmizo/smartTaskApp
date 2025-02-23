import 'package:flutter/material.dart';
import 'package:smart_task_app/core/splash_screen.dart';
import 'package:smart_task_app/provider/search_provider.dart';
import 'package:smart_task_app/provider/login_data.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(
    const Duration(seconds: 2),
  ); // Simulating a splash screen delay
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SearchProvider(),
        ), // Provide the SearchProvider
        ChangeNotifierProvider(create: (context) => LoginData()),
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
    return MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen());
  }
}
