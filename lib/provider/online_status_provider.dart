import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnlineStatusProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;
  bool _isOnline = false;

  bool get isOnline => _isOnline;
  String? get userId => _userId;

  // Initialize with user ID from SharedPreferences
  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        final List<dynamic> userDataMap = jsonDecode(userData);
        _userId = userDataMap[0]['id'].toString();

        // Create or update user document with online status field
        if (_userId != null && _userId!.isNotEmpty) {
          await _firestore.collection('users').doc(_userId).set({
            'online': true,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          _isOnline = true;
          notifyListeners();
        }
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  // Start listening to auth changes
  void startListeningToAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User logged out, set offline
        updateOnlineStatus(false);
      } else {
        // User logged in, set online
        updateOnlineStatus(true);
      }
    });
  }

  // Update online status in Firestore
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_auth.currentUser == null || _userId == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(_userId).set({
        'online': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (e is FirebaseException) {}
    }
  }

  // Set user ID manually (e.g., after login)
  Future<void> setUserId(String userId) async {
    _userId = userId;
    await updateOnlineStatus(true);
  }

  // Cleanup on logout
  Future<void> cleanup() async {
    if (_userId != null && _userId!.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(_userId).set({
          'online': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Wait for the operation to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // ignore: empty_catches
      } catch (e) {}
    }
    _userId = null;
    _isOnline = false;
    notifyListeners();
  }
}
