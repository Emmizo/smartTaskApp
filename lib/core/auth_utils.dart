import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthUtils {
  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        List<dynamic> userDataMap = jsonDecode(userData);
        String? token = userDataMap[0]['token'];
        return token;
      } catch (e) {
        print("Error decoding JSON: $e");
        return null;
      }
    }
    return null;
  }
}
