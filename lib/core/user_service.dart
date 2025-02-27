import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, Stream<bool>> _onlineStatusStreams = {};

  // Cached stream to prevent multiple listeners for the same user
  static Stream<bool> getUserOnlineStatus(String userId) {
    if (!_onlineStatusStreams.containsKey(userId)) {
      _onlineStatusStreams[userId] =
          _firestore
              .collection('users')
              .doc(userId)
              .snapshots()
              .map<bool>((snapshot) {
                if (snapshot.exists && snapshot.data() != null) {
                  return snapshot.data()?['online'] ?? false;
                }
                return false;
              })
              .distinct() // Only emit when values change
              .asBroadcastStream(); // Allow multiple listeners
    }
    return _onlineStatusStreams[userId]!;
  }
}
