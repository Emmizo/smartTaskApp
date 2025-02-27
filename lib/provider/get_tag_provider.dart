import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/core/api_client.dart';

class GetTagProvider with ChangeNotifier {
  List<dynamic> _tags = [];
  bool _isLoading = false;
  // final ApiClient apiClient;

  GetTagProvider();

  List<dynamic> get tags => _tags;
  bool get isLoading => _isLoading;

  Future<void> fetchTags() async {
    _isLoading = true;
    notifyListeners();
    ApiClient apiClient = ApiClient();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await apiClient.allTags();
    // print("API Response: $response");

    if (response.isEmpty) {
     
      _tags = [];
    } else {
      // Format according to the structure you need
      _tags = [
        {'data': response, 'status': 200},
      ];
    }

    _isLoading = false;
    notifyListeners();
  }
}
