import 'package:flutter/foundation.dart';

class HeaderProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [];
  bool _showNotifications =
      true; // Default to true to ensure notifications are enabled

  // Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get showNotifications => _showNotifications;

  // Get count of unread notifications
  int get unreadCount => _notifications.where((n) => n['read'] == false).length;

  // Add a new notification
  void addNotification(Map<String, dynamic> notification) {
    _notifications.add(notification);
    notifyListeners();
  }

  // Toggle notifications on/off
  void toggleNotifications() {
    _showNotifications = !_showNotifications;
    notifyListeners();
    if (kDebugMode) {
      print('Notifications toggled: $_showNotifications');
    }
  }

  // Mark a specific notification as read
  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['read'] = true;
      notifyListeners();
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['read'] = true;
    }
    notifyListeners();
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Get greeting based on time of day
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
