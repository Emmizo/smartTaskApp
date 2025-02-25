import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ThemeProvider extends ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(THEME_KEY) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Colors.white,
      background: Colors.grey[100]!,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: Colors.grey[800]),
    textTheme: TextTheme(
      headlineMedium: TextStyle(color: Colors.grey[900]),
      titleLarge: TextStyle(color: Colors.grey[800]),
      bodyLarge: TextStyle(color: Colors.grey[800]),
      bodyMedium: TextStyle(color: Colors.grey[800]),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[300]!,
      secondary: Colors.blueAccent[100]!,
      surface: Colors.grey[900]!,
      background: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: Colors.grey[300]),
    textTheme: TextTheme(
      headlineMedium: TextStyle(color: Colors.grey[100]),
      titleLarge: TextStyle(color: Colors.grey[200]),
      bodyLarge: TextStyle(color: Colors.grey[200]),
      bodyMedium: TextStyle(color: Colors.grey[300]),
    ),
  );

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
}
