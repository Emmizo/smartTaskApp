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

      // Debugging: Print the response
      print("API Response in api: ${response.data}");

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
}
