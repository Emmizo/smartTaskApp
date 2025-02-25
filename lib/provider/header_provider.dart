import 'package:flutter/material.dart';

class HeaderProvider extends ChangeNotifier {
  String _greeting;
  bool _showNotifications = true;

  HeaderProvider() : _greeting = _getGreetingBasedOnTime();

  String get greeting => _greeting;
  bool get showNotifications => _showNotifications;

  static String _getGreetingBasedOnTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void updateGreeting() {
    _greeting = _getGreetingBasedOnTime();
    notifyListeners();
  }

  void toggleNotifications() {
    _showNotifications = !_showNotifications;
    notifyListeners();
  }
}