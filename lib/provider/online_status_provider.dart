import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OnlineStatusProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isListening = false;
  bool _currentStatus = false;
  StreamSubscription? _authSubscription;

  User? get user => _auth.currentUser;
  bool get currentStatus => _currentStatus;

  // Throttled update method to prevent excessive Firestore writes
  Future<void> updateOnlineStatus(bool isOnline) async {
    // Only update if status changed
    if (_currentStatus != isOnline && user != null) {
      _currentStatus = isOnline;

      try {
        await _firestore.collection('users').doc(user!.uid).update({
          'online': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating online status: $e');
      }
    }
  }

  // Start listening to auth changes - call this once in your app initialization
  void startListeningToAuthChanges() {
    if (!_isListening) {
      _isListening = true;
      _authSubscription = _auth.authStateChanges().listen((user) {
        if (user != null) {
          updateOnlineStatus(true);
        }
      });
    }
  }

  // Important - properly clean up subscriptions
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
