import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/connectivity_manager.dart';
import '../core/offline_task_manager.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  final OfflineTaskManager _offlineManager = OfflineTaskManager();
  Timer? _periodicCheckTimer;
  final ApiClient _apiClient = ApiClient();

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _initConnectivity();
    _setupPeriodicCheck();
  }

  void _setupPeriodicCheck() {
    // Check connectivity every 30 seconds
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      _updateConnectionStatus(connectivityResults);
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }

  Future<void> _initConnectivity() async {
    try {
      await _connectivityManager.initialize();
      _connectivityManager.addListener(_onConnectivityChanged);
      final connectivityResults = await Connectivity().checkConnectivity();
      _updateConnectionStatus(connectivityResults);
    } catch (e) {
      print('Error initializing connectivity: $e');
    }
  }

  void _onConnectivityChanged() {
    _isOnline = _connectivityManager.isOnline;
    if (_isOnline) {
      _syncOfflineTasks();
    }
    notifyListeners();
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (wasOffline && _isOnline) {
      _syncOfflineTasks();
    }

    notifyListeners();
  }

  Future<void> _syncOfflineTasks() async {
    try {
      final offlineTasks = await _offlineManager.getOfflineTasks();
      for (final task in offlineTasks) {
        try {
          final cleanTask =
              Map<String, dynamic>.from(task)
                ..remove('createdAt')
                ..remove('status');

          final response = await _apiClient.createTask(cleanTask);
          if (response['success'] == true) {
            await _offlineManager.removeOfflineTask(task);
          }
        } catch (e) {
          print('Error syncing offline task: $e');
        }
      }

      final offlineUpdates = await _offlineManager.getOfflineTaskUpdates();
      for (final update in offlineUpdates) {
        try {
          final taskId = update['taskId'];
          final cleanUpdate =
              Map<String, dynamic>.from(update)
                ..remove('taskId')
                ..remove('updatedAt')
                ..remove('status');

          final response = await _apiClient.updateTask(taskId, cleanUpdate);
          if (response['success'] == true) {
            await _offlineManager.removeOfflineTaskUpdate(update);
          }
        } catch (e) {
          print('Error syncing offline task update: $e');
        }
      }
    } catch (e) {
      print('Error syncing offline tasks: $e');
    }
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}
