import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../provider/online_status_provider.dart';

class AppOnlineStatusListener extends StatefulWidget {
  final Widget child;
  const AppOnlineStatusListener({super.key, required this.child});

  @override
  State<AppOnlineStatusListener> createState() =>
      _AppOnlineStatusListenerState();
}

class _AppOnlineStatusListenerState extends State<AppOnlineStatusListener>
    with WidgetsBindingObserver {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        final provider = Provider.of<OnlineStatusProvider>(
          context,
          listen: false,
        );
        provider.startListeningToAuthChanges();
        provider.updateOnlineStatus(true);
        _isInitialized = true;
      }
    });
  }

  @override
  void dispose() {
    // Set offline status before disposing
    if (mounted) {
      Provider.of<OnlineStatusProvider>(
        context,
        listen: false,
      ).updateOnlineStatus(false);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    final onlineStatusProvider = Provider.of<OnlineStatusProvider>(
      context,
      listen: false,
    );

    if (state == AppLifecycleState.resumed) {
      onlineStatusProvider.updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onlineStatusProvider.updateOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
