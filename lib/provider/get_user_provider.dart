import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/core/api_client.dart';

class GetUserProvider with ChangeNotifier {
  List<dynamic> _users = [];
  bool _isLoading = false;
  // final ApiClient apiClient;

  GetUserProvider();

  List<dynamic> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    ApiClient apiClient = ApiClient();
    // SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await apiClient.allUsers();
    // print("API Response: $response");

    if (response.isEmpty) {
     
      _users = [];
    } else {
      // Format according to the structure you need
      _users = [
        {'data': response, 'status': 200},
      ];
    }

    _isLoading = false;
    notifyListeners();
  }
}
