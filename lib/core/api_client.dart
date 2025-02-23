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

      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? "Error: No response data";
    }
  }

  Future<Map<String, dynamic>> userInfo(String token) async {
    try {
      Response response = await _dio.get(
        '${Url.urlData}/users',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print(
        "Response Data: ${response.data}",
      ); // Debugging: Print response to check structure

      if (response.statusCode == 200) {
        if (response.data is List) {
          // Assuming the user data is inside the first object in the list
          var userData = (response.data as List).firstWhere(
            (item) => item['user'] != null,
            orElse: () => null,
          );

          if (userData != null) {
            return userData['user'] as Map<String, dynamic>;
          } else {
            throw Exception('User data not found in response');
          }
        } else if (response.data is Map) {
          // If the response is a Map, check if 'user' exists
          if (response.data.containsKey('user')) {
            return response.data['user'] as Map<String, dynamic>;
          } else {
            throw Exception('User data not found in response map');
          }
        } else {
          throw Exception('Response data is neither a List nor a Map');
        }
      } else {
        throw Exception(
          'Failed to load user info with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio errors or network errors
      if (e.response?.statusCode == 405) {
        // Specific handling for 405 errors
        throw Exception(
          'Method Not Allowed: Check the HTTP method and endpoint URL',
        );
      }
      throw Exception('Failed to connect to server: ${e.message}');
    } catch (e) {
      // Handle JSON decoding or type errors
      throw Exception('Error processing user info: $e');
    }
  }

  Future<dynamic> dashboard(String token) async {
    try {
      Response response = await _dio.get(
        '${Url.urlData}/dashboard',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // print(response);
      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  }

  /* Future<dynamic> listOfMember(String token) async {
    try {
      Response response = await _dio.get(
        '${Url.urlData}/list-members',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // print(response);
      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  }

  Future<dynamic> listOfCategory() async {
    try {
      Response response = await _dio.get('${Url.urlData}/list-category');

      // print(response);
      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  } */

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

  /* Future<dynamic> forgotPassword(String email) async {
    try {
      FormData formData = FormData.fromMap({"email": email});
      Response response = await _dio.post(
        '${Url.urlData}/forget-password-api',
        data: formData,
      );

      // print(response);
      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  } */
}
