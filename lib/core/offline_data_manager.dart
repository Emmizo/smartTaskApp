import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OfflineDataManager {
  static const String _usersKey = 'cached_users';
  static const String _projectsKey = 'cached_projects';
  static const String _tagsKey = 'cached_tags';

  // Cache users data
  static Future<void> cacheUsers(List<dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  // Get cached users
  static Future<List<dynamic>> getCachedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_usersKey);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return [];
  }

  // Cache projects data
  static Future<void> cacheProjects(List<dynamic> projects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_projectsKey, jsonEncode(projects));
  }

  // Get cached projects
  static Future<List<dynamic>> getCachedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_projectsKey);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return [];
  }

  // Cache tags data
  static Future<void> cacheTags(List<dynamic> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tagsKey, jsonEncode(tags));
  }

  // Get cached tags
  static Future<List<dynamic>> getCachedTags() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_tagsKey);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return [];
  }

  // Clear all cached data
  static Future<void> clearAllCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_projectsKey);
    await prefs.remove(_tagsKey);
  }
}
