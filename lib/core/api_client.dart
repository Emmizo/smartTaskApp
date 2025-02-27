import 'package:dio/dio.dart';
import 'package:smart_task_app/core/url.dart';

class ApiClient {
  final Dio _dio = Dio();

  Future<dynamic> login(String email, String password) async {
    try {
      FormData formData = FormData.fromMap({
        'email': email,
        'password': password,
      });
      Response response = await _dio.post(
        '${Url.urlData}/login',
        data: formData,
      );

      // Ensure response is always returned as expected
      if (response.data is List) {
        return response.data;
      } else if (response.data is Map<String, dynamic>) {
        return [response.data]; // Convert map to a list for consistency
      } else {
        throw Exception("Unexpected response format");
      }
    } on DioException catch (e) {
      print("Dio Error: ${e.response?.data}");
      return [
        {
          "status": 500,
          "message": e.response?.data ?? "Error: No response data",
        },
      ]; // Ensure it's always a list of maps
    }
  }

  Future<dynamic> googleLogin(String idToken) async {
    try {
      _dio.options.connectTimeout = Duration(seconds: 30);
      _dio.options.receiveTimeout = Duration(seconds: 30);

      Map<String, dynamic> data = {'idtoken': idToken};

      Response response = await _dio.post(
        '${Url.urlData}/auth/google/callback',
        data: data,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(
          "Login failed with status code: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      return [
        {
          "status": e.response?.statusCode ?? 500,
          "message": e.response?.data?['message'] ?? "Google login failed",
        },
      ];
    } catch (e) {
      return [
        {"status": 500, "message": "An unexpected error occurred: $e"},
      ];
    }
  }

  Future<List<Map<String, dynamic>>> userInfo(String token) async {
    try {
      Response response = await _dio.get(
        '${Url.urlData}/users',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // print("Response Data: ${response.data}"); // Debugging

      if (response.statusCode == 200) {
        if (response.data is List) {
          // Ensure it's a List of Maps
          List<Map<String, dynamic>> userList = [];
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
      Response response = await _dio.get(
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
      print("Failed to load projects: ${e.message}");
      return []; // Return an empty list on error
    }
  }

  Future<List<dynamic>> getAllProjects(String token) async {
    try {
      Response response = await _dio.get(
        '${Url.urlData}/listProjects',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Ensure the response data is a List
      if (response.data is List) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Unexpected response format: Expected a List');
      }
    } on DioException catch (e) {
      print("Failed to load projects: ${e.message}");
      return []; // Return an empty list on error
    }
  }

  Future<List<dynamic>> tasks(String token) async {
    try {
      Response response = await _dio.get(
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
      print("Failed to load tasks: ${e.message}");
      return []; // Return an empty list on error
    }
  }

  Future<List<dynamic>> allTasks(String token) async {
    try {
      Response response = await _dio.get(
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
      print("Failed to load tasks: ${e.message}");
      return []; // Return an empty list on error
    }
  }

  Future<List<dynamic>> allUsers() async {
    try {
      Response response = await _dio.get('${Url.urlData}/getAllUsers');
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
      print("Failed to load users: ${e.message}");
      return []; // Return an empty list on error
    }
  }

  Future<List<dynamic>> allTags() async {
    try {
      Response response = await _dio.get('${Url.urlData}/getAllTags');
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
      print("Failed to load users: ${e.message}");
      return []; // Return an empty list on error
    }
  }

  Future<bool> deleteTask(task_id) async {
    try {
      FormData formData = FormData.fromMap({'task_id': task_id});

      Response response = await _dio.post(
        '${Url.urlData}/deleteTask',
        data: formData,
      );

      // Handle Map response instead of List
      if (response.data != null && response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;

        // Check if message indicates success
        if (responseData.containsKey('message') &&
            responseData['message'] == 'Task deleted successfully') {
          return true;
        } else {
          print("Failed response: $responseData");
          return false;
        }
      } else {
        throw Exception(
          'Unexpected response format: ${response.data.runtimeType}',
        );
      }
    } on DioException catch (e) {
      print("Failed to delete task: ${e.message}");
      return false; // Return false on error
    } catch (e) {
      print("Error deleting task: $e");
      return false;
    }
  }

  Future<List<dynamic>> taskTags() async {
    try {
      Response response = await _dio.get('${Url.urlData}/getTaskTags');
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
      print("Failed to load users: ${e.message}");
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
      FormData formData = FormData.fromMap({
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "password_confirmation": passwordConfirmation,
      });
      Response response = await _dio.post(
        '${Url.urlData}/signup',
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  }

  Future<dynamic> CreateProject(
    String name,
    String description,
    DateTime deadline,
    List<int> user_id,
    List<int> tag_id,
    String token,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        "name": name,
        "description": description,
        "deadline": deadline,
        "user_id[]": user_id,
        "tag_id[]": tag_id,
      });
      Response response = await _dio.post(
        '${Url.urlData}/create_projects',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  }

  Future<dynamic> updateTask(
    String taskId,
    String title,
    String description,
    DateTime deadline,
    List<int> user_id,
    List<int> tag_id,
    int project_id,
    int status_id,
    String token,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'task_id': taskId,
        "title": title,
        "description": description,
        "due_date": deadline.toIso8601String(), // Ensure correct format
        "user_id": user_id,
        "tag_id[]": tag_id,
        "project_id": project_id,
        "status_id": status_id,
      });
      Response response = await _dio.post(
        '${Url.urlData}/updateTask',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  }

  Future<bool> createTask(
    String title,
    String description,
    DateTime deadline,
    List<int> user_id,
    List<int> tag_id,
    int project_id,
    int status_id,
    String token,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        "title": title,
        "description": description,
        "due_date": deadline.toIso8601String(), // Ensure correct format
        "user_id": user_id,
        "tag_id[]": tag_id,
        "project_id": project_id,
        "status_id": status_id,
      });

      Response response = await _dio.post(
        '${Url.urlData}/createTask',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: formData,
      );
      print(formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['success'] == true;
      }
      return false; // Return false on failure
    } on DioException catch (e) {
      return false; // Handle errors gracefully
    }
  }
}
