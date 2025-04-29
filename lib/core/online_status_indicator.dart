import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/connectivity_provider.dart';
import 'user_service.dart';

class OnlineStatusIndicator {
  static Widget build(String userId) {
    if (userId.isEmpty) {
      return const SizedBox(width: 12, height: 12);
    }

    return StreamBuilder<bool>(
      stream: UserService.getUserOnlineStatus(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 12, height: 12);
        }
        final connectivityProvider = Provider.of<ConnectivityProvider>(context);
        final bool isOnline2 = snapshot.data ?? false;
        final bool connected = connectivityProvider.isOnline ? true : false;
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOnline2 && connected ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        );
      },
    );
  }
}
