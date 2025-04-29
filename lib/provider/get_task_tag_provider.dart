import 'package:flutter/material.dart';
import '../core/api_client.dart';

class GetTaskTagProvider with ChangeNotifier {
  List<dynamic> _tags = [];
  bool _isLoading = false;
  // final ApiClient apiClient;

  GetTaskTagProvider();

  List<dynamic> get tags => _tags;
  bool get isLoading => _isLoading;

  Future<void> fetchTags() async {
    _isLoading = true;
    notifyListeners();
    final ApiClient apiClient = ApiClient();

    final response = await apiClient.taskTags();
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
