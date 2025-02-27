import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:provider/provider.dart';
import 'package:smart_task_app/core/global.dart';
import 'package:smart_task_app/provider/header_provider.dart';

// Global navigator key definition

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    await _requestPermission();
    await _initLocalNotifications();
    _setupFCM();
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? 'You have a new notification',
      );

      // Add to provider for in-app display
      addNotificationToProvider(
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? 'You have a new notification',
      );
    }
  }

  void addNotificationToProvider(String title, String body) {
    // Use a delayed callback to ensure the context is available
    Future.delayed(Duration.zero, () {
      if (navigatorKey.currentContext != null) {
        try {
          final headerProvider = Provider.of<HeaderProvider>(
            navigatorKey.currentContext!,
            listen: false,
          );

          headerProvider.addNotification({
            'title': title,
            'body': body,
            'time': DateTime.now().toString().substring(11, 16), // HH:MM format
            'read': false,
          });
        } catch (e) {}
      } else {}
    });
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );
  }

  void _setupFCM() async {
    try {
      if (Platform.isIOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );

        // Try to get APNS token with retry mechanism
        String? apnsToken;
        int apnsAttempts = 0;

        while (apnsToken == null && apnsAttempts < 3) {
          try {
            apnsToken = await _firebaseMessaging.getAPNSToken();

            if (apnsToken == null) {
              // Wait before retrying
              await Future.delayed(Duration(seconds: 2));
              apnsAttempts++;
            }
          } catch (e) {
            print("Error getting APNS token: $e");
            await Future.delayed(Duration(seconds: 2));
            apnsAttempts++;
          }
        }

        // Wait a bit more to ensure APNS token is properly registered
        await Future.delayed(Duration(seconds: 1));
      }

      // Now try to get FCM token with retry mechanism
      String? token;
      int fcmAttempts = 0;

      while (token == null && fcmAttempts < 3) {
        try {
          token = await _firebaseMessaging.getToken();

          if (token == null) {
            await Future.delayed(Duration(seconds: 2));
            fcmAttempts++;
          } else {}
        } catch (e) {
          await Future.delayed(Duration(seconds: 2));
          fcmAttempts++;
        }
      }

      if (token != null) {
        // TODO: Send token to your server
      } else {}

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Navigate to specific page based on the notification if needed
      });
    } catch (e) {}
  }

  Future<void> _showLocalNotification(String title, String body) async {
    print("Showing local notification: $title");
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'smart_task_channel',
          'Smart Task Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Use timestamp for unique ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Method to show a notification when a project is created
  Future<void> showProjectCreatedNotification(String projectName) async {
    print("Project created notification for: $projectName");
    await _showLocalNotification(
      'New Project Created',
      'Project "$projectName" has been successfully created',
    );

    // Also add to in-app notifications
    addNotificationToProvider(
      'New Project Created',
      'Project "$projectName" has been successfully created',
    );
  }

  Future<void> showTaskCreatedNotification(
    String action,
    String projectName,
    String title,
  ) async {
    await _showLocalNotification(
      'Task $action in $projectName',
      'Task in "$projectName" has been successfully "$action"',
    );
    // Also add to in-app notifications
    addNotificationToProvider(
      'New Task for "$projectName"',
      'Task "$title" has been successfully created',
    );
  }

  // Test method for debugging
  void testNotification() {
    print("Triggering test notification");

    // Send a local notification
    _showLocalNotification(
      "Test Notification",
      "This is a test notification sent at ${DateTime.now().toString().substring(11, 19)}",
    );

    // Add to in-app notifications
    addNotificationToProvider(
      "Test Notification",
      "This is a test notification sent at ${DateTime.now().toString().substring(11, 19)}",
    );
  }
}
