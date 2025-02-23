import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/core/api_client.dart';

class LoginData with ChangeNotifier, DiagnosticableTreeMixin {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late List<Map<String, dynamic>> _userData = [];
  List<Map<String, dynamic>> get getUserData => _userData;

  Future setUserInfo(String token) async {
    final SharedPreferences prefs = await _prefs;

    ApiClient apiClient = ApiClient();
    Map<String, dynamic> _userData = await apiClient.userInfo(token);
    // Add token to each map in the list
    _userData['token'] = token;

    String userDataString = jsonEncode(_userData);
    print("provider $userDataString");
    prefs.setString("userData", userDataString.toString());
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('userData', json.encode(_userData)));
  }
}
