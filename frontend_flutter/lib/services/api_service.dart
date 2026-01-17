import 'dart:convert';
import 'package:demo/exceptions/api_exception.dart';
import 'package:demo/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:3000/api'; // aliyun
  // static const String _baseUrl = 'http://117.72.126.201:3000/api'; // jdyun

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<User> login(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        body: jsonEncode({'username': username, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final responseBody = _parseResponse(response);

      if (response.statusCode == 200) {
        if (responseBody['success'] == true) {
          return User.fromJson(responseBody['user']);
        } else {
          throw ApiException(
            responseBody['message'] ?? 'Login failed',
            response.statusCode,
          );
        }
      } else {
        throw ApiException(
          responseBody['message'] ?? 'Login failed',
          response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('Invalid server response format', 500);
    } catch (e) {
      debugPrint('login exception: $e');
      rethrow;
    }
  }

  Future<User> register(String username, String password, String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final responseBody = _parseResponse(response);

      if (response.statusCode == 201) {
        if (responseBody['success'] == true) {
          return User.fromJson(responseBody['user']);
        } else {
          throw ApiException(
            responseBody['message'] ?? 'Registration failed',
            response.statusCode,
          );
        }
      } else {
        throw ApiException(
          responseBody['message'] ?? 'Registration failed',
          response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('Invalid server response format', 500);
    } catch (e) {
      debugPrint('register exception: $e');
      rethrow;
    }
  }

  // Send a email verification code to the user's email
  Future<void> sendCode(String username) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/send-code'),
        body: jsonEncode({'username': username}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final responseBody = _parseResponse(response);

      if (response.statusCode == 200) {
        if (responseBody['success'] == true) {
          return;
        } else {
          throw ApiException(
            responseBody['message'] ?? 'Failed to send code',
            response.statusCode,
          );
        }
      } else {
        throw ApiException(
          responseBody['message'] ?? 'Failed to send code',
          response.statusCode,
        ); 
        // Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('sendCode exception: $e');

      rethrow;
    }
  }

  // Verify the email verification code and reset the user's password
  Future<void> resetPassword(String username, String code, String newPassword) async {
    try {
      debugPrint('username: $username, code: $code, newPassword: $newPassword');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        body: jsonEncode({
          'username': username,
          'code': code,
          'newPassword': newPassword
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('response status code: ${response.statusCode}');
      debugPrint('response body: ${response.body}');


      final responseBody = _parseResponse(response);

      if (response.statusCode == 200) {
        if (responseBody['success'] == true) {
          return;
        } else {
          throw Exception(
            '${responseBody['error'] ?? 'Failed to reset password'}\nStatus code: ${response.statusCode}'
          );
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('resetPassword exception: $e');
      rethrow;
    }
  }



  // parse response body to json
  dynamic _parseResponse(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      debugPrint('parse json exception: $e');
      throw FormatException('invalid server response format');
    }
  }
}