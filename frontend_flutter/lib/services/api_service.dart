import 'dart:async';
import 'dart:convert';

import 'package:demo/exceptions/api_exception.dart';
import 'package:demo/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// API 服务类
///
/// 负责与后端服务器通信，处理用户认证相关操作
class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:3000/api'; // 本地开发
  // static const String _baseUrl = 'http://117.72.126.201:3000/api'; // 生产服务器

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// 用户登录
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
          // 后端返回结构: { success: true, data: { token, user } }
          final data = responseBody['data'];
          if (data == null || data['user'] == null) {
            throw ApiException('登录响应数据无效', 500);
          }
          // 合并 token 和 user 数据
          final userData = Map<String, dynamic>.from(data['user']);
          userData['token'] = data['token'];
          return User.fromJson(userData);
        } else {
          throw ApiException(
            responseBody['message'] ?? '登录失败',
            response.statusCode,
          );
        }
      } else {
        throw ApiException(
          responseBody['message'] ?? '登录失败',
          response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('服务器响应格式无效', 500);
    } catch (e) {
      debugPrint('登录异常: $e');
      rethrow;
    }
  }

  /// 用户注册
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
          // 注册成功返回 { token, user } 格式（与登录一致）
          final data = responseBody['data'];
          return User.fromJson({
            ...data['user'],
            'token': data['token'],
          });
        } else {
          throw ApiException(
            responseBody['message'] ?? '注册失败',
            response.statusCode,
          );
        }
      } else {
        throw ApiException(
          responseBody['message'] ?? '注册失败',
          response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('服务器响应格式无效', 500);
    } catch (e) {
      debugPrint('注册异常: $e');
      rethrow;
    }
  }

  /// 发送邮箱验证码
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
            responseBody['message'] ?? '发送验证码失败',
            response.statusCode,
          );
        }
      } else {
        throw ApiException(
          responseBody['message'] ?? '发送验证码失败',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('发送验证码异常: $e');
      rethrow;
    }
  }

  /// 验证邮箱验证码并重置密码
  Future<void> resetPassword(String username, String code, String newPassword) async {
    try {
      debugPrint('用户名: $username, 验证码: $code, 新密码: $newPassword');

      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        body: jsonEncode({
          'username': username,
          'code': code,
          'newPassword': newPassword
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('响应状态码: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      final responseBody = _parseResponse(response);

      if (response.statusCode == 200) {
        if (responseBody['success'] == true) {
          return;
        } else {
          throw Exception(
            '${responseBody['error'] ?? '重置密码失败'}\n状态码: ${response.statusCode}'
          );
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('重置密码异常: $e');
      rethrow;
    }
  }

  /// 通用 GET 请求
  Future<Map<String, dynamic>> get({
    required String endpoint,
    String? token,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _buildUri(endpoint, query);
      final headers = _buildHeaders(token);

      final response = await _client
          .get(uri, headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('请求超时，请检查网络连接'),
          );

      final responseBody = _parseResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw ApiException(
          responseBody['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on TimeoutException {
      debugPrint('GET 请求超时 ($endpoint)');
      rethrow;
    } catch (e) {
      debugPrint('GET 请求异常 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 POST 请求
  Future<Map<String, dynamic>> post({
    required String endpoint,
    String? token,
    Map<String, dynamic>? data,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = _buildHeaders(token);

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('请求超时，请检查网络连接'),
          );

      final responseBody = _parseResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw ApiException(
          responseBody['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on TimeoutException {
      debugPrint('POST 请求超时 ($endpoint)');
      rethrow;
    } catch (e) {
      debugPrint('POST 请求异常 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 PUT 请求
  Future<Map<String, dynamic>> put({
    required String endpoint,
    String? token,
    Map<String, dynamic>? data,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = _buildHeaders(token);

      final response = await _client
          .put(
            uri,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('请求超时，请检查网络连接'),
          );

      final responseBody = _parseResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw ApiException(
          responseBody['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on TimeoutException {
      debugPrint('PUT 请求超时 ($endpoint)');
      rethrow;
    } catch (e) {
      debugPrint('PUT 请求异常 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 DELETE 请求
  Future<Map<String, dynamic>> delete({
    required String endpoint,
    String? token,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = _buildHeaders(token);

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('请求超时，请检查网络连接'),
          );

      final responseBody = _parseResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw ApiException(
          responseBody['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on TimeoutException {
      debugPrint('DELETE 请求超时 ($endpoint)');
      rethrow;
    } catch (e) {
      debugPrint('DELETE 请求异常 ($endpoint): $e');
      rethrow;
    }
  }

  /// 构建完整的 URI（包含 query 参数）
  Uri _buildUri(String endpoint, [Map<String, String>? query]) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$_baseUrl$path';

    if (query != null && query.isNotEmpty) {
      final queryString = query.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      return Uri.parse('$url?$queryString');
    }
    return Uri.parse(url);
  }

  /// 构建请求头（包含认证 token）
  Map<String, String> _buildHeaders([String? token]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// 解析响应体为JSON
  dynamic _parseResponse(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      debugPrint('JSON解析异常: $e');
      throw FormatException('服务器响应格式无效');
    }
  }
}
