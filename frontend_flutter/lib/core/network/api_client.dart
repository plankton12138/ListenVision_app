import 'package:dio/dio.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 统一的 API 客户端
///
/// 基于 DioProvider，提供统一的 HTTP 请求接口
/// 替代旧的 api_service.dart（使用 http.Client）
class ApiClient {
  final Dio _dio;

  const ApiClient({required Dio dio}) : _dio = dio;

  /// 通用 GET 请求
  Future<Map<String, dynamic>> get({
    required String endpoint,
    Map<String, String>? query,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: query,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          response.data['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('ApiClient', 'GET 请求异常 ($endpoint): $e');
      rethrow;
    } catch (e) {
      AppLogger.error('ApiClient', 'GET 请求异常 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 POST 请求
  Future<Map<String, dynamic>> post({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, String>? query,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: query,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          response.data['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('ApiClient', 'POST 请求异常 ($endpoint): $e');
      rethrow;
    } catch (e) {
      AppLogger.error('ApiClient', 'POST 请求异常 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 PUT 请求
  Future<Map<String, dynamic>> put({
    required String endpoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          response.data['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('ApiClient', 'PUT 请求异常 ($endpoint): $e');
      rethrow;
    } catch (e) {
      AppLogger.error('ApiClient', 'PUT 请求异常 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 DELETE 请求
  Future<Map<String, dynamic>> delete({
    required String endpoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          response.data['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('ApiClient', 'DELETE 请求异常 ($endpoint): $e');
      rethrow;
    } catch (e) {
      AppLogger.error('ApiClient', 'DELETE 请求异常 ($endpoint): $e');
      rethrow;
    }
  }

  /// 通用 PATCH 请求
  Future<Map<String, dynamic>> patch({
    required String endpoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          response.data['message'] ?? '请求失败',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('ApiClient', 'PATCH 请求异常 ($endpoint): $e');
      rethrow;
    } catch (e) {
      AppLogger.error('ApiClient', 'PATCH 请求异常 ($endpoint): $e');
      rethrow;
    }
  }
}

/// API 异常
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
