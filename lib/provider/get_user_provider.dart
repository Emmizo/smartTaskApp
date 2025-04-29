import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../provider/connectivity_provider.dart';

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

    try {
      final ApiClient apiClient = ApiClient();
      final response = await apiClient.allUsers();

      if (response.isEmpty) {
        _users = [];
      } else {
        _users = [
          {'data': response, 'status': 200},
        ];

        // Cache users for offline use
        await _cacheUsers(response);
      }
    } catch (e) {
      print('Error fetching users: $e');
      await _loadUsersFromPrefs();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _cacheUsers(List<dynamic> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_users', jsonEncode(users));
    } catch (e) {
      print('Error caching users: $e');
    }
  }

  Future<void> _loadUsersFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('cached_users');

      if (usersJson != null) {
        final List<dynamic> usersList = jsonDecode(usersJson);
        _users = [
          {'data': usersList, 'status': 200},
        ];
      } else {
        _users = [];
      }
    } catch (e) {
      print('Error loading users from SharedPreferences: $e');
      _users = [];
    }
  }
}
