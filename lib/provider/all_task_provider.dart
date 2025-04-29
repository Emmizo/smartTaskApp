import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';

class AllTaskProvider with ChangeNotifier {
  List<dynamic> _tasks = [];
  bool _isLoading = false;

  List<dynamic> get tasks => _tasks;
  bool get isLoading => _isLoading;

  void setTasks(List<dynamic> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  Future<void> fetchAllTasks() async {
    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        final List<dynamic> userDataMap = jsonDecode(userData);
        final String? token = userDataMap[0]['token'];

        if (token != null) {
          try {
            final ApiClient apiClient = ApiClient();
            final response = await apiClient.allTasks(token);

            if (response.isEmpty) {
              _tasks = [];
            } else {
              _tasks = [
                {'data': response, 'status': 200},
              ];

              prefs.setString('allTasks', jsonEncode(_tasks));
            }
          } catch (e) {
            _tasks = [];
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

  Future<void> refreshTasks() async {
    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        final List<dynamic> userDataMap = jsonDecode(userData);
        final String? token = userDataMap[0]['token'];

        if (token != null) {
          try {
            final ApiClient apiClient = ApiClient();
            final response = await apiClient.allTasks(token);

            if (response.isEmpty) {
              _tasks = [];
            } else {
              _tasks = [
                {'data': response, 'status': 200},
              ];

              prefs.setString('allTasks', jsonEncode(_tasks));
            }
          } catch (e) {
            _tasks = [];
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

  void clearTasks() {
    _tasks = [];
    notifyListeners();
  }

  /// Get tasks from SharedPreferences
  Future<List<dynamic>> getTasksFromSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedTasks = prefs.getString('allTasks');
    if (storedTasks != null && storedTasks.isNotEmpty) {
      return jsonDecode(storedTasks);
    } else {
      return [];
    }
  }

  /// Update a single task
  void updateTask(int index, dynamic updatedTask) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index] = updatedTask;
      notifyListeners();

      // Save updated tasks to SharedPreferences
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('allTasks', jsonEncode(_tasks));
      });
    }
  }

  /// Delete a task
  void deleteTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      _tasks.removeAt(index);
      notifyListeners();

      // Save updated tasks to SharedPreferences
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('allTasks', jsonEncode(_tasks));
      });
    }
  }
}
