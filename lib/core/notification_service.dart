import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/header_provider.dart';
import 'global.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Firestore reference for users and notifications
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference _notificationsCollection = FirebaseFirestore
      .instance
      .collection('notifications');
  final CollectionReference _userNotifyCollection = FirebaseFirestore.instance
      .collection('user_notify');
  final CollectionReference _notificationGroupsCollection = FirebaseFirestore
      .instance
      .collection('notification_groups');

  NotificationService._internal();

  Future<void> initialize() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _setupFCM();

    // Listen for notifications intended for this user
    _listenForNotifications();

    // Start checking for scheduled notifications
    startScheduledNotificationChecker();
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
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
        } catch (e) {
          print('Error adding notification to provider: $e');
        }
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        _handleNotificationTap(response);
      },
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // Convert millis back to DateTime where needed
        final processedData = _convertMillisToDates(data);
        print('new payload ${processedData.toString()}');

        if (processedData['type'] == 'task_assignment') {
          navigatorKey.currentState?.pushNamed(
            '/task',
            arguments: {
              'projectId': processedData['projectId'],
              'taskId': processedData['taskId'],
            },
          );
        }
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  Map<String, dynamic> _convertMillisToDates(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (key == 'createdAt' || key == 'deliveredAt' || key == 'readAt') {
        return MapEntry(key, DateTime.fromMillisecondsSinceEpoch(value));
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _convertMillisToDates(value));
      }
      return MapEntry(key, value);
    });
  }

  Future<void> _setupFCM() async {
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
              await Future.delayed(const Duration(seconds: 2));
              apnsAttempts++;
            }
          } catch (e) {
            await Future.delayed(const Duration(seconds: 2));
            apnsAttempts++;
          }
        }

        // Wait a bit more to ensure APNS token is properly registered
        await Future.delayed(const Duration(seconds: 1));
      }

      // Now try to get FCM token with retry mechanism
      String? token;
      int fcmAttempts = 0;

      while (token == null && fcmAttempts < 3) {
        try {
          token = await _firebaseMessaging.getToken();

          if (token == null) {
            await Future.delayed(const Duration(seconds: 2));
            fcmAttempts++;
          } else {
            // Save token to Firestore
            await _saveTokenToFirestore(token);
          }
        } catch (e) {
          await Future.delayed(const Duration(seconds: 2));
          fcmAttempts++;
        }
      }

      // Set up token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Handle notification when app is opened from background
        if (message.data.containsKey('type')) {
          final type = message.data['type'];
          if (type == 'task_assignment') {
            // Navigate to task detail
          } else if (type == 'project_update') {
            // Navigate to project
          }
        }
      });

      // Handle initial message if app was terminated
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        // Handle the initial message
        if (initialMessage.data.containsKey('type')) {
          final type = initialMessage.data['type'];
          if (type == 'task_assignment') {
            // Navigate to task detail
          } else if (type == 'project_update') {
            // Navigate to project
          }
        }
      }
    } catch (e) {
      print('Error setting up FCM: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Store token in both collections for redundancy
      await _usersCollection.doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _userNotifyCollection.doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'devices': FieldValue.arrayUnion([
          {
            'token': token,
            'platform': Platform.operatingSystem,
            'lastActive': FieldValue.serverTimestamp(),
          },
        ]),
      }, SetOptions(merge: true));

      print('FCM token saved for user ${user.uid}');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Improved notification listener with pagination and ordering
  void _listenForNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      if (userData == null) return;

      final currentUserId = jsonDecode(userData)[0]['id'].toString();

      _notificationsCollection
          .where('recipientId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
            for (final doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;

              // Convert Timestamps to millisecondsSinceEpoch
              final serializableData = _convertTimestamps(data);

              _showLocalNotification(
                data['title'] ?? 'New Notification',
                data['body'] ?? 'You have a new notification',
                payload: jsonEncode(serializableData),
              );

              addNotificationToProvider(
                data['title'] ?? 'New Notification',
                data['body'] ?? 'You have a new notification',
              );

              doc.reference.update({
                'status': 'delivered',
                'deliveredAt': FieldValue.serverTimestamp(),
              });
            }
          });
    } catch (e) {
      print('Error setting up notification listener: $e');
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    // Get user preferences
    final prefs = await getNotificationPreferences();
    final allowSound = prefs['allowSound'] ?? true;
    final allowVibration = prefs['allowVibration'] ?? true;

    // Generate a smaller ID (using seconds since epoch instead of milliseconds)
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Android-specific settings
    const String sound = 'notification_sound';

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'smart_task_channel',
      'Smart Task Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: allowVibration,
      enableLights: true,
      color: const Color.fromARGB(255, 255, 0, 0),
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: allowSound,
      sound:
          allowSound ? const RawResourceAndroidNotificationSound(sound) : null,
    );

    // iOS-specific settings
    final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: allowSound,
      sound: allowSound ? 'default' : null,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id, // Use the smaller ID here
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // ENHANCED USER NOTIFICATION PREFERENCES

  Future<Map<String, dynamic>> getUserNotificationPreferences(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData == null) return {};

    final currentUserId = jsonDecode(userData)[0]['id'].toString();

    final userDoc =
        await _firestore.collection('user_notify').doc(currentUserId).get();

    return userDoc.data() ?? {};
  }

  Future<void> updateNotificationPreferences(
    Map<String, dynamic> preferences, {
    bool? allowPush,
    bool? allowEmail,
    bool? allowSound,
    bool? allowVibration,
  }) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) return;

      final updateData = <String, dynamic>{
        'notificationPreferences': {
          if (allowPush != null) 'allowPush': allowPush,
          if (allowEmail != null) 'allowEmail': allowEmail,
          if (allowSound != null) 'allowSound': allowSound,
          if (allowVibration != null) 'allowVibration': allowVibration,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Update Firestore
      await _userNotifyCollection
          .doc(currentUserId)
          .set(updateData, SetOptions(merge: true));

      // Update local preferences
      final prefs = await SharedPreferences.getInstance();
      if (allowPush != null) await prefs.setBool('allowPush', allowPush);
      if (allowEmail != null) await prefs.setBool('allowEmail', allowEmail);
      if (allowSound != null) await prefs.setBool('allowSound', allowSound);
      if (allowVibration != null) {
        await prefs.setBool('allowVibration', allowVibration);
      }

      print('Notification preferences updated for user $currentUserId');
    } catch (e) {
      print('Error updating notification preferences: $e');
    }

    /*  await _firestore
        .collection('user_notify')
        .doc(currentUserId)
        .set(updateData, SetOptions(merge: true)); */
  }

  /// Check if a specific notification type is muted
  Future<bool> isNotificationTypeMuted(String type) async {
    try {
      // First check local preferences
      final prefs = await SharedPreferences.getInstance();
      final localMutedTypes =
          prefs.getStringList('muted_notification_types') ?? [];
      if (localMutedTypes.contains(type)) return true;

      // Check Firestore if not found locally
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) return false;

      final doc = await _userNotifyCollection.doc(currentUserId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      final mutedTypes = List<String>.from(
        data?['notificationPreferences']?['mutedTypes'] ?? [],
      );

      // Update local preferences
      await prefs.setStringList('muted_notification_types', mutedTypes);

      return mutedTypes.contains(type);
    } catch (e) {
      print('Error checking muted notification types: $e');
      return false;
    }
  }

  /// Mute a specific notification type
  Future<void> muteNotificationType(String type) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) return;

      await _userNotifyCollection.doc(currentUserId).set({
        'notificationPreferences.mutedTypes': FieldValue.arrayUnion([type]),
      }, SetOptions(merge: true));

      // Update local preferences
      final prefs = await SharedPreferences.getInstance();
      final currentMuted =
          prefs.getStringList('muted_notification_types') ?? [];
      await prefs.setStringList('muted_notification_types', [
        ...currentMuted,
        type,
      ]);
    } catch (e) {
      print('Error muting notification type: $e');
    }
  }

  /// Unmute a specific notification type
  Future<void> unmuteNotificationType(String type) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) return;

      await _userNotifyCollection.doc(currentUserId).update({
        'notificationPreferences.mutedTypes': FieldValue.arrayRemove([type]),
      });

      // Update local preferences
      final prefs = await SharedPreferences.getInstance();
      final currentMuted =
          prefs.getStringList('muted_notification_types') ?? [];
      await prefs.setStringList(
        'muted_notification_types',
        currentMuted.where((t) => t != type).toList(),
      );
    } catch (e) {
      print('Error unmuting notification type: $e');
    }
  }

  Future<void> removeMutedProjects(List<String> projectIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      if (userData == null) return;
      final currentUserId = jsonDecode(userData)[0]['id'].toString();

      await _userNotifyCollection.doc(currentUserId).update({
        'mutedProjects': FieldValue.arrayRemove(projectIds),
      });
    } catch (e) {
      print('Error removing muted projects: $e');
    }
  }

  // NOTIFICATION GROUP MANAGEMENT

  Future<void> createNotificationGroup(
    String groupName,
    List<String> userIds,
  ) async {
    await _firestore.collection('notification_groups').add({
      'name': groupName,
      'members': userIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendNotificationToGroup(
    String groupId,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    // Get group members
    final groupDoc =
        await _firestore.collection('notification_groups').doc(groupId).get();

    if (!groupDoc.exists) return;

    final members = List<String>.from(groupDoc.data()?['members'] ?? []);

    // Send to all members
    await sendNotificationToUsers(members, title, body, data: data);
  }

  Future<void> addUsersToGroup(String groupId, List<String> userIds) async {
    try {
      await _notificationGroupsCollection.doc(groupId).update({
        'members': FieldValue.arrayUnion(userIds),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding users to group: $e');
    }
  }

  Future<void> removeUsersFromGroup(
    String groupId,
    List<String> userIds,
  ) async {
    try {
      await _notificationGroupsCollection.doc(groupId).update({
        'members': FieldValue.arrayRemove(userIds),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing users from group: $e');
    }
  }

  // NOTIFICATION MANAGEMENT

  Future<void> sendNotificationToUser(
    String userId,
    String title,
    String body, {
    Map<String, dynamic>? data,
    String? projectId,
    String? notificationType,
  }) async {
    try {
      // Check if user has muted all notifications
      if (userId == await _getCurrentUserId()) {
        final isMuted = await areAllNotificationsMuted();
        if (isMuted) {
          print('All notifications are muted - not sending to user $userId');
          return;
        }
      }

      // Check if this notification type is muted
      if (notificationType != null) {
        final isTypeMuted = await isNotificationTypeMuted(notificationType);
        if (isTypeMuted) {
          print('Notification type $notificationType is muted - not sending');
          return;
        }
      }

      // Check if this project is muted
      if (projectId != null) {
        final isMuted = await isProjectMutedForUser(userId, projectId);
        if (isMuted) {
          print('User $userId has muted project $projectId');
          return;
        }
      }

      // Get user preferences
      final prefs = await getUserNotificationPreferences(userId);
      final allowPush = prefs['allowPush'] ?? true;

      if (!allowPush) {
        print('User $userId has disabled push notifications');
        return;
      }

      // Rest of your existing send logic...
      await _notificationsCollection.add({
        'recipientId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'projectId': projectId,
        'type': notificationType,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'senderId': await _getCurrentUserId(),
      });

      print('Notification queued for user $userId');
    } catch (e) {
      print('Error sending notification to user $userId: $e');
    }
  }

  Future<bool> isProjectMutedForUser(String userId, String projectId) async {
    try {
      final userDoc = await _userNotifyCollection.doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>?;
      final mutedProjects =
          (userData?['mutedProjects'] as List<dynamic>?)?.cast<String>() ?? [];

      return mutedProjects.contains(projectId);
    } catch (e) {
      print('Error checking muted projects for user $userId: $e');
      return false;
    }
  }

  Future<void> sendNotificationWithRetry(
    String userId,
    String title,
    String body, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    bool success = false;

    while (!success && attempts < maxRetries) {
      try {
        await sendNotificationToUser(userId, title, body);
        success = true;
      } catch (e) {
        attempts++;
        print('Notification send attempt $attempts failed: $e');
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }

    if (!success) {
      // Log or handle final failure
      print('Failed to send notification after $maxRetries attempts');
    }
  }

  Future<void> sendNotificationToUsers(
    List<String> userIds,
    String title,
    String body, {
    Map<String, dynamic>? data,
    String? projectId,
  }) async {
    try {
      // Get current user ID to exclude from notifications
      // After login process
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) {
        print('Cannot send notifications - no sender ID available');
        return;
      }
      // Filter out the current user from recipients
      final filteredUserIds = userIds;
      print(filteredUserIds);
      if (filteredUserIds.isEmpty) return;

      // Get users who have muted the project
      final Set<String> usersWithMutedProject = {};
      if (projectId != null) {
        final querySnapshot =
            await _userNotifyCollection
                .where('mutedProjects', arrayContains: projectId)
                .get();

        for (final doc in querySnapshot.docs) {
          usersWithMutedProject.add(doc.id);
        }
      }

      // Create a batch to add multiple notifications efficiently
      var batch = _firestore.batch();
      int processedCount = 0;

      for (final userId in filteredUserIds) {
        // Skip users who have muted this project
        if (projectId != null && usersWithMutedProject.contains(userId)) {
          continue;
        }

        // Commit batch in groups of 500 to avoid Firestore limits
        if (processedCount > 0 && processedCount % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch(); // Create a new batch
        }

        final docRef = _notificationsCollection.doc();
        batch.set(docRef, {
          'recipientId': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
          'projectId': projectId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'senderId': currentUserId,
        });

        processedCount++;
      }

      // Commit any remaining operations
      if (processedCount % 500 != 0) {
        await batch.commit();
      }

      print('Notifications added to Firestore for ${processedCount} users');
    } catch (e, stackTrace) {
      print('Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      // Consider adding crash analytics here
    }
  }

  Future<void> sendNotificationToBatch(
    List<String> userIds,
    String title,
    String body, {
    Map<String, dynamic>? data,
    int batchSize = 500,
  }) async {
    // Process in batches to avoid Firestore limitations
    for (int i = 0; i < userIds.length; i += batchSize) {
      final end =
          (i + batchSize < userIds.length) ? i + batchSize : userIds.length;
      final batchUserIds = userIds.sublist(i, end);

      await sendNotificationToUsers(batchUserIds, title, body, data: data);
    }
  }

  // NOTIFICATION STATUS MANAGEMENT

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({
      'status': 'read',
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllNotificationsAsRead() async {
    final currentUserId = await _getCurrentUserId();
    DocumentSnapshot? lastDoc;

    do {
      final query = _notificationsCollection
          .where('recipientId', isEqualTo: currentUserId)
          .where('status', whereIn: ['pending', 'delivered'])
          .orderBy('createdAt')
          .limit(500);

      if (lastDoc != null) {
        query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      lastDoc = snapshot.docs.last;
    } while (true);
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final currentUserId = await _getCurrentUserId();

      // Get all notifications for this user
      final querySnapshot =
          await _notificationsCollection
              .where('recipientId', isEqualTo: currentUserId)
              .limit(500) // Firestore has limits on batch operations
              .get();

      if (querySnapshot.docs.isEmpty) return;

      // Create a batch operation to delete all notifications
      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // If there are more than 500 notifications, we need to process them in batches
      if (querySnapshot.docs.length == 500) {
        await deleteAllNotifications(); // Recursive call to handle remaining notifications
      }
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // NOTIFICATION RETRIEVAL

  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData == null) return [];

    final currentUserId = jsonDecode(userData)[0]['id'].toString();

    final snapshot =
        await _notificationsCollection
            .where('recipientId', isEqualTo: currentUserId)
            .where('status', whereIn: ['pending', 'delivered'])
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final currentUserId = await _getCurrentUserId();

      Query query = _notificationsCollection
          .where('recipientId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<int?> getUnreadNotificationCount() async {
    try {
      final currentUserId = await _getCurrentUserId();

      final snapshot =
          await _notificationsCollection
              .where('recipientId', isEqualTo: currentUserId)
              .where('status', whereIn: ['pending', 'delivered'])
              .count()
              .get();

      return snapshot.count;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // PROJECT MUTING

  Future<void> muteProjectNotifications(String projectId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) {
        print('Cannot mute - no user ID available');
        throw Exception('User not authenticated');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mute_project_$projectId', true);

      await _userNotifyCollection.doc(currentUserId).set({
        'mutedProjects': FieldValue.arrayUnion([projectId]),
      }, SetOptions(merge: true));

      print('Successfully muted project $projectId for user $currentUserId');
    } catch (e) {
      print('Error muting project notifications: $e');
      rethrow; // Consider rethrowing or handling differently
    }
  }

  Future<void> unmuteProjectNotifications(String projectId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) {
        print('Cannot unmute - no user ID available');
        return;
      }

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mute_project_$projectId', false);

      // Update Firestore
      await _userNotifyCollection.doc(currentUserId).update({
        'mutedProjects': FieldValue.arrayRemove([projectId]),
      });
    } catch (e) {
      print('Error unmuting project notifications: $e');
      // Consider throwing or handling the error differently
    }
  }

  Future<bool> isProjectMuted(String projectId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) {
        print('No user ID available - project notifications remain unmuted');
        return false;
      }

      // First check local storage
      final prefs = await SharedPreferences.getInstance();
      final localMuted = prefs.getBool('mute_project_$projectId');
      if (localMuted != null) return localMuted;

      // Check Firestore if local storage has no data
      final userDoc = await _userNotifyCollection.doc(currentUserId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>?;
      final mutedProjects = List<String>.from(userData?['mutedProjects'] ?? []);

      // Update local storage for future checks
      await prefs.setBool(
        'mute_project_$projectId',
        mutedProjects.contains(projectId),
      );

      return mutedProjects.contains(projectId);
    } catch (e) {
      print('Error checking if project is muted: $e');
      return false; // Default to not muted if there's an error
    }
  }

  // SPECIFIC NOTIFICATION TYPES

  Future<void> showProjectCreatedNotification(
    String projectName,
    String projectId,
  ) async {
    try {
      final isMuted = await isProjectMuted(projectId);
      if (isMuted) return;

      await _showLocalNotification(
        'New Project Created',
        'Project "$projectName" has been successfully created',
      );

      addNotificationToProvider(
        'New Project Created',
        'Project "$projectName" has been successfully created',
      );
    } catch (e) {
      print('Error showing project created notification: $e');
    }
  }

  Future<void> showTaskCreatedNotification(
    String action,
    String projectName,
    String projectId,
    String title,
    List<String> recipientIds,
  ) async {
    try {
      print(recipientIds);
      // Use our new method to send to specific users
      await sendNotificationToUsers(
        recipientIds,
        'Task $action in $projectName',
        'You have been assigned to task "$title"',
        projectId: projectId,
        data: {
          'type': 'task_assignment',
          'projectId': projectId,
          'taskTitle': title,
          'action': action,
        },
      );
    } catch (e) {
      print('Error showing task created notification: $e');
    }
  }

  Future<void> showProjectDeadlineNotification(
    String title,
    String projectName,
    DateTime deadline,
    String projectId,
  ) async {
    try {
      final isMuted = await isProjectMuted(projectId);
      if (isMuted) return;

      await _showLocalNotification(
        title,
        'Project "$projectName" deadline on $deadline',
        payload: jsonEncode({
          'type': 'project_deadline',
          'projectId': projectId,
          'deadline': deadline,
        }),
      );

      addNotificationToProvider(
        projectName,
        'approaching deadline on "$deadline" - needs to be completed',
      );
    } catch (e) {
      print('Error showing project deadline notification: $e');
    }
  }

  // HELPER METHODS

  Future<String> _getCurrentUserId() async {
    try {
      // First try Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) return firebaseUser.uid;

      // Fall back to SharedPreferences for non-Firebase auth
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      if (userData != null) {
        final userJson = jsonDecode(userData);
        if (userJson is List && userJson.isNotEmpty) {
          return userJson[0]['id'].toString();
        }
      }

      return ''; // Return empty string if no user ID found
    } catch (e) {
      print('Error getting current user ID: $e');
      return '';
    }
  }

  // Test method for debugging
  void testNotification() {
    _showLocalNotification(
      'Test Notification',
      'This is a test notification sent at ${DateTime.now().toString().substring(11, 19)}',
    );
  }

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.millisecondsSinceEpoch);
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _convertTimestamps(value));
      } else if (value is List) {
        return MapEntry(
          key,
          value.map((e) {
            if (e is Map<String, dynamic>) {
              return _convertTimestamps(e);
            } else if (e is Timestamp) {
              return e.millisecondsSinceEpoch;
            }
            return e;
          }).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }

  // Add this method to NotificationService class
  Future<void> scheduleTaskDeadlineReminder(
    String taskId,
    String taskTitle,
    String projectName,
    String projectId,
    DateTime deadline,
    String assignedUserId,
  ) async {
    try {
      // Calculate reminder times (e.g., 1 day before, 1 hour before)
      final oneDayBefore = deadline.subtract(const Duration(days: 1));
      final oneHourBefore = deadline.subtract(const Duration(hours: 1));

      // Get current time to determine which reminders to send

      // Store the reminder in Firestore for future processing
      await _notificationsCollection.add({
        'recipientId': assignedUserId,
        'title': 'Task Deadline Reminder',
        'body': 'Task "$taskTitle" in project "$projectName" is due soon',
        'data': {
          'type': 'task_deadline',
          'taskId': taskId,
          'projectId': projectId,
          'deadline': deadline.millisecondsSinceEpoch,
        },
        'projectId': projectId,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'scheduledFor': oneDayBefore.millisecondsSinceEpoch,
        'senderId': await _getCurrentUserId(),
      });

      // Add another reminder for one hour before
      await _notificationsCollection.add({
        'recipientId': assignedUserId,
        'title': 'Urgent Task Deadline Reminder',
        'body':
            'Task "$taskTitle" in project "$projectName" is due in one hour',
        'data': {
          'type': 'task_deadline',
          'taskId': taskId,
          'projectId': projectId,
          'deadline': deadline.millisecondsSinceEpoch,
        },
        'projectId': projectId,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'scheduledFor': oneHourBefore.millisecondsSinceEpoch,
        'senderId': await _getCurrentUserId(),
      });

      print('Task deadline reminders scheduled for task $taskId');
    } catch (e) {
      print('Error scheduling task deadline reminder: $e');
    }
  }

  // Add this method to NotificationService class
  void startScheduledNotificationChecker() {
    // Check every minute for notifications that need to be sent
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndSendScheduledNotifications();
    });
  }

  Future<void> _checkAndSendScheduledNotifications() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Find notifications that should be sent (scheduled time has passed)
      final querySnapshot =
          await _notificationsCollection
              .where('status', isEqualTo: 'scheduled')
              .where('scheduledFor', isLessThanOrEqualTo: now)
              .limit(20)
              .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Send the notification
        _showLocalNotification(
          data['title'] ?? 'Reminder',
          data['body'] ?? 'You have a reminder',
          payload: jsonEncode(_convertTimestamps(data)),
        );

        // Add to provider for in-app display
        addNotificationToProvider(
          data['title'] ?? 'Reminder',
          data['body'] ?? 'You have a reminder',
        );

        // Update status to delivered
        await doc.reference.update({
          'status': 'delivered',
          'deliveredAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error checking scheduled notifications: $e');
    }
  }

  // Add to NotificationService class
  Future<void> showTaskDeadlineNotification(
    String taskId,
    String taskTitle,
    String projectName,
    String projectId,
    List<String> recipientIds,
    String timeframe,
  ) async {
    try {
      // Use our method to send to specific users
      await sendNotificationToUsers(
        recipientIds,
        'Task Deadline Reminder',
        'Task "$taskTitle" in project "$projectName" is due $timeframe',
        projectId: projectId,
        data: {
          'type': 'task_deadline',
          'projectId': projectId,
          'taskId': taskId,
          'timeframe': timeframe,
        },
      );
    } catch (e) {
      print('Error showing task deadline notification: $e');
    }
  }

  // Add to NotificationService class
  Future<void> cancelExistingTaskReminders(String taskId) async {
    try {
      // Find any existing reminders for this task
      final querySnapshot =
          await _notificationsCollection
              .where('status', isEqualTo: 'scheduled')
              .where('data.taskId', isEqualTo: taskId)
              .get();

      // Create a batch to delete all reminders
      if (querySnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('Cancelled existing reminders for task $taskId');
      }
    } catch (e) {
      print('Error cancelling existing task reminders: $e');
    }
  }

  // Enhanced mute functionality
  Future<void> muteAllNotifications() async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) return;

      // Store in local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mute_all_notifications', true);

      // Update Firestore
      await _userNotifyCollection.doc(currentUserId).set({
        'notificationPreferences': {
          'allowPush': false,
          'allowEmail': false,
          'mutedAll': true,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('All notifications muted for user $currentUserId');
    } catch (e) {
      print('Error muting all notifications: $e');
    }
  }

  Future<void> unmuteAllNotifications() async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) return;

      // Store in local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mute_all_notifications', false);

      // Update Firestore
      await _userNotifyCollection.doc(currentUserId).set({
        'notificationPreferences': {
          'allowPush': true,
          'allowEmail': true,
          'mutedAll': false,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('All notifications unmuted for user $currentUserId');
    } catch (e) {
      print('Error unmuting all notifications: $e');
    }
  }

  Future<bool> areAllNotificationsMuted() async {
    try {
      // Check local preferences first
      final prefs = await SharedPreferences.getInstance();
      final localMuted = prefs.getBool('mute_all_notifications');
      if (localMuted != null) return localMuted;

      // Check Firestore if local preference not set
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isEmpty) return false;

      final userDoc = await _userNotifyCollection.doc(currentUserId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>?;
      final preferences =
          userData?['notificationPreferences'] as Map<String, dynamic>?;

      // Update local preference for future checks
      final isMuted = preferences?['mutedAll'] ?? false;
      await prefs.setBool('mute_all_notifications', isMuted);

      return isMuted;
    } catch (e) {
      print('Error checking mute status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      // First check local preferences
      final prefs = await SharedPreferences.getInstance();
      final localPreferences = {
        'allowPush': prefs.getBool('allowPush') ?? true,
        'allowEmail': prefs.getBool('allowEmail') ?? false,
        'allowSound': prefs.getBool('allowSound') ?? true,
        'allowVibration': prefs.getBool('allowVibration') ?? true,
      };

      // Check Firestore for any updates
      final currentUserId = await _getCurrentUserId();
      if (currentUserId.isNotEmpty) {
        final doc = await _userNotifyCollection.doc(currentUserId).get();
        if (doc.exists) {
          final serverPreferences =
              (doc.data() as Map<String, dynamic>?)?['notificationPreferences']
                  as Map<String, dynamic>? ??
              {};
          return {...localPreferences, ...serverPreferences};
        }
      }

      return localPreferences;
    } catch (e) {
      print('Error getting notification preferences: $e');
      return {
        'allowPush': true,
        'allowEmail': false,
        'allowSound': true,
        'allowVibration': true,
      };
    }
  }
}
