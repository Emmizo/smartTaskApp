import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // ignore: constant_identifier_names
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

  // New method to get adaptive text color
  Color getAdaptiveTextColor(BuildContext context, {Color? defaultColor}) {
    if (defaultColor != null) {
      // Calculate luminance of the provided default color
      return defaultColor.computeLuminance() > 0.5
          ? Colors.black
          : Colors.white;
    }

    // Use theme's background color for luminance calculation
    final backgroundColor =
        _isDarkMode
            ? darkTheme.colorScheme.surface
            : lightTheme.colorScheme.surface;

    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  // New method to get adaptive card color
  Color getAdaptiveCardColor(BuildContext context) {
    return _isDarkMode
        ? Colors.grey[850]! // Dark mode card color
        : Colors.white; // Light mode card color
  }

  // New method to get adaptive card text color
  Color getAdaptiveCardTextColor(BuildContext context) {
    return _isDarkMode
        ? Colors
            .white // White text for dark mode
        : Colors.black; // Black text for light mode
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: Colors.grey[900]),
    textTheme: TextTheme(
      headlineMedium: TextStyle(color: Colors.grey[900]),
      titleLarge: TextStyle(color: Colors.grey[900]),
      bodyLarge: TextStyle(color: Colors.grey[900]),
      bodyMedium: TextStyle(color: Colors.grey[900]),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[300]!,
      secondary: Colors.blueAccent[100]!,
      surface: Colors.grey[900]!,
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
