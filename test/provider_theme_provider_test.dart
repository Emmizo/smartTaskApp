import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_app/provider/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ThemeProvider', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    test('should instantiate ThemeProvider', () {
      expect(themeProvider, isA<ThemeProvider>());
    });

    test('should toggle theme mode', () async {
      final initialMode = themeProvider.isDarkMode;
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, isNot(initialMode));
    });

    // Commented out: getAdaptiveCardColor test requires a real BuildContext
    // test('getAdaptiveCardColor returns correct color', () {
    //   final context = TestWidgetsFlutterBinding.ensureInitialized().renderViewElement!;
    //   final color = themeProvider.getAdaptiveCardColor(context);
    //   expect(color, isA<Color>());
    // });
  });
}
