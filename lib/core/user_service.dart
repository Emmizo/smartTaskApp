import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final Map<String, Stream<bool>> _onlineStatusStreams = {};

  static Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      return snapshot.exists ? (snapshot.data()?['online'] ?? false) : false;
    });
  }

  // Add a method to create/update user document
  static Future<void> ensureUserDocument(
    String userId, {
    required bool online,
  }) async {
    try {
      // Check if user is authenticated with Firebase
      if (FirebaseAuth.instance.currentUser == null) {
        // Consider adding Firebase sign-in here if appropriate
      }

      await _firestore.collection('users').doc(userId).set({
        'online': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow; // Rethrow to handle in calling function
    }
  }

  // Clean up streams when not needed
  static void disposeUserStream(String userId) {
    _onlineStatusStreams.remove(userId);
  }
}
