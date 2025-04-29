import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import 'connectivity_provider.dart';

class TaskProvider with ChangeNotifier {
  List<dynamic> _tasks = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TaskProvider() {
    _setupFirestoreListener();
  }

  List<dynamic> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        final List<dynamic> userDataMap = jsonDecode(userData);
        final String? token = userDataMap[0]['token'];

        if (token != null) {
          // Check connectivity
          final connectivityProvider = Provider.of<ConnectivityProvider>(
            context,
            listen: false,
          );

          if (connectivityProvider.isOnline) {
            // Fetch tasks from the API
            final ApiClient apiClient = ApiClient();
            final response = await apiClient.tasks(token);

            if (response.isEmpty) {
              _tasks = [];
            } else {
              // Format according to the structure you need
              _tasks = [
                {'data': response, 'status': 200},
              ];

              // Save tasks to SharedPreferences
              prefs.setString('allTasks', jsonEncode(_tasks));
            }
          } else {
            // Load tasks from SharedPreferences
            final String? storedTasks = prefs.getString('allTasks');
            if (storedTasks != null && storedTasks.isNotEmpty) {
              _tasks = jsonDecode(storedTasks);
            } else {
              _tasks = [];
            }
          }
        } else {
          _tasks = [];
        }

        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _setupFirestoreListener() {
    _firestore
        .collection('tasks')
        .snapshots()
        .listen(
          (snapshot) async {
            _tasks = snapshot.docs.map((doc) => doc.data()).toList();
            _isLoading = false;

            // Save updated tasks to SharedPreferences
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            prefs.setString('allTasks', jsonEncode(_tasks));

            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            notifyListeners();
          },
        );
  }
}
