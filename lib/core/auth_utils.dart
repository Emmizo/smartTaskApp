import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthUtils {
  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        final List<dynamic> userDataMap = jsonDecode(userData);
        final String? token = userDataMap[0]['token'];
        return token;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
