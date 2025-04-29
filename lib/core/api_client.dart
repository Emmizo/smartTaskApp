import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'offline_task_manager.dart';
import 'url.dart';
import 'offline_data_manager.dart';

// Add this at the top level of the file
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiClient {
  final Dio _dio = Dio();
  final OfflineTaskManager _offlineManager = OfflineTaskManager();

  Future<dynamic> login(String email, String password) async {
    try {
      final FormData formData = FormData.fromMap({
        'email': email,
        'password': password,
      });
      final Response response = await _dio.post(
        '${Url.urlData}/login',
        data: formData,
      );
      print('Response Data: ${response.data}'); // Debugging
      // Ensure response is always returned as expected
      if (response.data is List) {
        return response.data;
      } else if (response.data is Map<String, dynamic>) {
        return [response.data]; // Convert map to a list for consistency
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      return [
        {
          'status': 500,
          'message': e.response?.data ?? 'Error: No response data',
        },
      ]; // Ensure it's always a list of maps
    }
  }

  // API client method
  Future<dynamic> socialLogin(String provider, String accessToken) async {
    try {
      final FormData formData = FormData.fromMap({
        'provider': provider,
        'access_token': accessToken,
      });

      // Print the data being sent for debugging

      final Response response = await _dio.post(
        '${Url.urlData}/auth/social/callback',
        data: formData,
      );

      // Ensure response is always returned as expected
      if (response.data is List) {
        return response.data;
      } else if (response.data is Map<String, dynamic>) {
        return [response.data]; // Convert map to a list for consistency
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      return [
        {
          'status': 500,
          'message': e.response?.data ?? 'Error: No response data',
        },
      ]; // Ensure it's always a list of maps
    }
  }

  Future<List<Map<String, dynamic>>> userInfo(String token) async {
    try {
      final Response response = await _dio.get(
        '${Url.urlData}/users',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // print("Response Data: ${response.data}"); // Debugging

      if (response.statusCode == 200) {
        if (response.data is List) {
          // Ensure it's a List of Maps
          final List<Map<String, dynamic>> userList = [];
          for (var item in response.data) {
            if (item is Map<String, dynamic> && item.containsKey('user')) {
              userList.add(item['user']);
            }
          }
          return userList; // Return the list of user data
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<dynamic>> projects(String token) async {
    try {
      final Response response = await _dio.get(
        '${Url.urlData}/projects',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Ensure the response data is a List
      if (response.data is List) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Unexpected response format: Expected a List');
      }
    } on DioException catch (e) {
      return []; // Return an empty list on error
    }
  }

  Future<List<dynamic>> getAllProjects(String token) async {
    try {
      final Response response = await _dio.get(
        '${Url.urlData}/listProjects',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data is List) {
        // Cache the projects data
        await OfflineDataManager.cacheProjects(response.data);
        return response.data as List<dynamic>;
      } else {
        throw Exception('Unexpected response format: Expected a List');
      }
    } on DioException {
      // Return cached data if available
      return await OfflineDataManager.getCachedProjects();
    }
  }

  Future<List<dynamic>> tasks(String token) async {
    try {
      final Response response = await _dio.get(
        '${Url.urlData}/tasks',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Check if the response has data and it's the shape we expect
      if (response.data != null && response.data['data'] != null) {
        // Return the 'data' array from the response
        return response.data['data'] as List<dynamic>;
      } else {
        // If response has a different structure, try to adapt
        if (response.data is List) {
          return response.data as List<dynamic>;
        } else {
          throw Exception(
            'Unexpected response format: ${response.data.runtimeType}',
          );
        }
      }
    } on DioException catch (e) {
      return []; // Return an empty list on error
    }
  }

  Future<List<dynamic>> allTasks(String token) async {
    try {
      final Response response = await _dio.get(
        '${Url.urlData}/allTasks',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Check if the response has data and it's the shape we expect
      if (response.data != null && response.data['data'] != null) {
        // Return the 'data' array from the response
        return response.data['data'] as List<dynamic>;
      } else {
        // If response has a different structure, try to adapt
        if (response.data is List) {
          return response.data as List<dynamic>;
        } else {
          throw Exception(
            'Unexpected response format: ${response.data.runtimeType}',
          );
        }
      }
    } on DioException catch (e) {
      return []; // Return an empty list on error
    }
  }

  Future<List<dynamic>> allUsers() async {
    try {
      final Response response = await _dio.get('${Url.urlData}/getAllUsers');

      if (response.data != null && response.data is List) {
        // Cache the users data
        await OfflineDataManager.cacheUsers(response.data);
        return response.data as List<dynamic>;
      } else {
        throw Exception(
          'Unexpected response format: ${response.data.runtimeType}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Failed to load users: ${e.message}');
      }
      // Return cached data if available
      return await OfflineDataManager.getCachedUsers();
    }
  }

  Future<List<dynamic>> allTags() async {
    try {
      final Response response = await _dio.get('${Url.urlData}/getAllTags');

      if (response.data != null && response.data is List) {
        // Cache the tags data
        await OfflineDataManager.cacheTags(response.data);
        return response.data as List<dynamic>;
      } else {
        throw Exception(
          'Unexpected response format: ${response.data.runtimeType}',
        );
      }
    } on DioException catch (e) {
      // Return cached data if available
      return await OfflineDataManager.getCachedTags();
    }
  }

  Future<bool> deleteTask(task_id) async {
    try {
      final FormData formData = FormData.fromMap({'task_id': task_id});

      final Response response = await _dio.post(
        '${Url.urlData}/deleteTask',
        data: formData,
      );

      // Handle Map response instead of List
      if (response.data != null && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;

        // Check if message indicates success
        if (responseData.containsKey('message') &&
            responseData['message'] == 'Task deleted successfully') {
          return true;
        } else {
          return false;
        }
      } else {
        throw Exception(
          'Unexpected response format: ${response.data.runtimeType}',
        );
      }
    } on DioException catch (e) {
      return false; // Return false on error
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> taskTags() async {
    try {
      final Response response = await _dio.get('${Url.urlData}/getTaskTags');
      // print('Response Data: ${response.data}');

      // Check if the response is a list
      if (response.data != null && response.data is List) {
        return response.data as List<dynamic>; // Return the list directly
      } else {
        throw Exception(
          'Unexpected response format: ${response.data.runtimeType}',
        );
      }
    } on DioException catch (e) {
      return []; // Return an empty list on error
    }
  }

  Future<dynamic> addUser(
    String firstName,
    String lastName,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final FormData formData = FormData.fromMap({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      final Response response = await _dio.post(
        '${Url.urlData}/signup',
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  }

  // ignore: non_constant_identifier_names
  Future<dynamic> CreateProject(
    String name,
    String description,
    DateTime deadline,
    List<int> userId,
    List<int> tagId,
    String token,
  ) async {
    try {
      final FormData formData = FormData.fromMap({
        'name': name,
        'description': description,
        'deadline': deadline,
        'user_id[]': userId,
        'tag_id[]': tagId,
      });
      final Response response = await _dio.post(
        '${Url.urlData}/create_projects',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!isOnline) {
        await _offlineManager.saveOfflineTask(taskData);
        return {
          'success': true,
          'message': 'Task saved offline. Will sync when online.',
          'offline': true,
          'projectId': taskData['project_id']?.toString() ?? '',
          'userIds': [taskData['user_id']?.toString() ?? ''],
          'taskId': null,
        };
      }

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('userData');
      String token = '';

      if (userData != null && userData.isNotEmpty) {
        final List<dynamic> userDataMap = jsonDecode(userData);
        token = userDataMap[0]['token']?.toString() ?? '';
      }

      // Convert taskData to FormData
      final formData = FormData.fromMap({
        'title': taskData['title'],
        'description': taskData['description'],
        'due_date': taskData['due_date'],
        'user_id': taskData['user_id'],
        'tag_id[]': taskData['tag_id[]'],
        'project_id': taskData['project_id'],
        'status_id': taskData['status_id'],
      });

      // Use the correct endpoint for task creation with authorization token
      final response = await _dio.post(
        '${Url.urlData}/createTask',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('Create Task Response: ${response.data}');

      // Ensure the response includes the required fields for notifications
      final responseData =
          response.data is Map<String, dynamic>
              ? Map<String, dynamic>.from(response.data)
              : {'success': true};

      // Add required fields if they don't exist
      if (!responseData.containsKey('projectId')) {
        responseData['projectId'] = taskData['project_id']?.toString() ?? '';
      }

      if (!responseData.containsKey('userIds')) {
        responseData['userIds'] = [taskData['user_id']?.toString() ?? ''];
      }

      // If this was an offline task being synced, mark it as synced
      if (taskData['is_offline'] == true) {
        await _offlineManager.removeOfflineTask(taskData);
      }

      return responseData;
    } catch (e) {
      print('Error creating task: $e');
      // If online creation fails, save for offline
      if (e is DioException && e.type != DioExceptionType.connectionError) {
        await _offlineManager.saveOfflineTask(taskData);
        return {
          'success': true,
          'message':
              'Task saved offline due to server error. Will retry later.',
          'offline': true,
          'projectId': taskData['project_id']?.toString() ?? '',
          'userIds': [taskData['user_id']?.toString() ?? ''],
        };
      }
      return {
        'success': false,
        'error': 'Failed to create task: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!isOnline) {
        await _offlineManager.saveOfflineTaskUpdate(taskId, updateData);
        return {
          'success': true,
          'message': 'Task update saved offline. Will sync when online.',
          'offline': true,
        };
      }

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('userData');
      String token = '';

      if (userData != null && userData.isNotEmpty) {
        final List<dynamic> userDataMap = jsonDecode(userData);
        token = userDataMap[0]['token']?.toString() ?? '';
      }

      // Convert updateData to FormData
      final formData = FormData.fromMap({
        'task_id': taskId,
        'title': updateData['title'],
        'description': updateData['description'],
        'due_date': updateData['due_date'],
        'user_id': updateData['user_id'],
        'tag_id[]': updateData['tag_id[]'],
        'project_id': updateData['project_id'],
        'status_id': updateData['status_id'],
      });

      // Use the correct endpoint for task update with authorization token
      final response = await _dio.post(
        '${Url.urlData}/updateTask',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('Update Task Response: ${response.data}');

      // If this was an offline update being synced, mark it as synced
      if (updateData['is_offline'] == true) {
        await _offlineManager.removeOfflineTaskUpdate(updateData);
      }

      return response.data;
    } catch (e) {
      print('Error updating task: $e');
      // If online update fails, save for offline
      if (e is DioException && e.type != DioExceptionType.connectionError) {
        await _offlineManager.saveOfflineTaskUpdate(taskId, updateData);
        return {
          'success': true,
          'message':
              'Task update saved offline due to server error. Will retry later.',
          'offline': true,
        };
      }
      return {
        'success': false,
        'error': 'Failed to update task: ${e.toString()}',
      };
    }
  }

  // Add method to sync offline tasks
  Future<void> syncOfflineTasks() async {
    try {
      // This method is now handled directly by the ConnectivityProvider
      // Keeping it for backward compatibility
      print('syncOfflineTasks is now handled by ConnectivityProvider');
    } catch (e) {
      print('Error syncing offline tasks: $e');
    }
  }

  Future<Map<String, dynamic>> generate2FASecret(String token) async {
    try {
      final Response response = await _dio.post(
        '${Url.urlData}/2fa/generate',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('2FA generation response: ${response.data}');

      // Extract data from the response
      final secretKey = response.data['secret']?.toString() ?? '';
      final qrCodeUrl = response.data['qr_code']?.toString() ?? '';

      // Store the secret key securely if needed (optional)
      if (secretKey.isNotEmpty) {
        const storage = FlutterSecureStorage();
        await storage.write(key: '2fa_secret_key', value: secretKey);
      }

      return {'success': true, 'secret': secretKey, 'qr_code': qrCodeUrl};
    } on DioException catch (e) {
      String errorMessage = 'Failed to generate 2FA secret';
      if (e.response?.data is Map) {
        final errorData = e.response?.data as Map;
        errorMessage = errorData['error']?.toString() ?? errorMessage;
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> verify2FA(String token, String otp) async {
    try {
      // Ensure OTP is 6 digits
      if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
        return {'success': false, 'error': 'OTP must be exactly 6 digits'};
      }

      final Response response = await _dio.post(
        '${Url.urlData}/2fa/verify',
        data: {'otp': otp},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return {
        'success': true,
        'message': response.data['message'] ?? 'Verification successful',
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to verify 2FA code';
      if (e.response?.data is Map) {
        final errorData = e.response?.data as Map;
        errorMessage = errorData['error']?.toString() ?? errorMessage;
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> disable2FA(String authToken) async {
    try {
      final response = await _dio.post(
        '${Url.urlData}/disable-2fa',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': true,
        'message': response.data['message'] ?? '2FA disabled successfully',
      };
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'error':
              e.response?.data['error'] ??
              _getErrorMessageFromStatusCode(e.response?.statusCode),
        };
      } else {
        return {'success': false, 'error': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  String _getErrorMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '2FA is not enabled for this user';
      case 401:
        return 'Authentication failed';
      case 403:
        return 'Permission denied';
      default:
        return 'Failed to disable 2FA';
    }
  }
}
