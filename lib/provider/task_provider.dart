import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/core/api_client.dart';

class TaskProvider with ChangeNotifier {
  List<dynamic> _tasks = [];
  bool _isLoading = false;

  TaskProvider();

  List<dynamic> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        List<dynamic> userDataMap = jsonDecode(userData);

        String? token = userDataMap[0]['token'];

        if (token != null) {
          try {
            ApiClient apiClient = ApiClient();
            final response = await apiClient.tasks(token);
            // print("API Response: $response"); // See what you're getting back

            if (response.isEmpty) {
              _tasks = [];
            } else {
              // Format according to the structure you need
              _tasks = [
                {'data': response, 'status': 200},
              ];
            }
          } catch (e) {
            print("Error fetching tasks: $e");
            _tasks = [];
          }
        } else {
          _tasks = [];
        }

        _isLoading = false;
        notifyListeners();
      } catch (e) {
        print("Error decoding JSON here: $e");
      }
    }
  }
}
