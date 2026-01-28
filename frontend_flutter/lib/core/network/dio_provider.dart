import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:demo/core/utils/app_logger.dart';

import '../constants/api_constants.dart';
// import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Dio 单例管理
///
/// 功能：
/// 1. 统一管理 Dio 实例，避免创建多个 HTTP 客户端
/// 2. 动态设置 Authorization header
/// 3. 提供请求/响应拦截器
/// 4. 提供通用请求方法
class DioProvider {
  DioProvider._internal();

  static DioProvider? _instance;
  static Dio? _dio;

  /// 获取单例
  static DioProvider get instance {
    _instance ??= DioProvider._internal();
    return _instance!;
  }

  /// 获取 Dio 实例
  Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  /// 创建 Dio 实例
  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.fullBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 添加请求拦截器
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.debug('Dio', '请求: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.debug('Dio', '响应: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.error('Dio', '错误: ${error.message} ${error.requestOptions.uri}');
        return handler.next(error);
      },
    ));

    return dio;
  }

  /// 更新认证 Token
  ///
  /// 当用户登录/登出时调用，全局更新 Authorization header
  void updateToken(String? token) {
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
      AppLogger.info('Dio', 'Token 已更新');
    } else {
      dio.options.headers.remove('Authorization');
      AppLogger.info('Dio', 'Token 已清除');
    }
  }

  /// 获取当前 Token
  String? get currentToken {
    return dio.options.headers['Authorization']?.toString().replaceFirst('Bearer ', '');
  }

  /// 通用 GET 请求
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 通用 POST 请求
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await dio.post(
        endpoint,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 通用 PUT 请求
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await dio.put(
        endpoint,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 通用 DELETE 请求
  Future<Map<String, dynamic>> delete(
    String endpoint,
  ) async {
    try {
      final response = await dio.delete(endpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 下载文件
  ///
  /// [url] 完整的下载URL
  /// [savePath] 保存路径
  /// [onReceiveProgress] 接收进度回调
  Future<void> download(
    String url,
    String savePath, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      await dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
      AppLogger.info('DioProvider', '文件下载成功: $savePath');
    } on DioException catch (e) {
      AppLogger.error('DioProvider', '文件下载失败: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// 错误处理
  ///
  /// 支持解析多种后端错误格式：
  /// - 标准格式: {"message": "错误信息"}
  /// - 错误格式: {"error": "错误信息"}
  /// - 验证错误: {"error": "参数验证失败: [...]"}
  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      final message = (() {
        if (responseData is Map<String, dynamic>) {
          // 优先使用 message 字段，其次使用 error 字段
          return responseData['message']?.toString() 
                ?? responseData['error']?.toString() 
                ?? e.message 
                ?? '未知错误';
        } else {
          return e.message ?? '未知错误';
        }
      })();

      // 解析验证错误，提取具体字段错误
      final parsedMessage = _parseValidationError(message);

      return ApiException(parsedMessage, statusCode ?? 500);
    }
    return ApiException('网络错误: ${e.message}', 500);
  }

  /// 解析验证错误信息
  ///
  /// 从 "参数验证失败: [{...}]" 格式中提取具体错误
  String _parseValidationError(String message) {
    // 检查是否是验证错误
    if (!message.contains('参数验证失败') && !message.contains('验证失败')) {
      return message;
    }

    try {
      // 提取方括号内的 JSON 数组
      final startIndex = message.indexOf('[');
      final endIndex = message.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonStr = message.substring(startIndex, endIndex + 1);
        final errors = jsonDecode(jsonStr) as List<dynamic>;

        if (errors.isNotEmpty) {
          // 取第一个错误，格式化为用户友好的消息
          final firstError = errors.first as Map<String, dynamic>;
          final field = firstError['field']?.toString() ?? '';
          final errorMsg = firstError['message']?.toString() ?? '';

          if (field.isNotEmpty && errorMsg.isNotEmpty) {
            return '$field: $errorMsg';
          } else if (errorMsg.isNotEmpty) {
            return errorMsg;
          }
        }
      }

      // 如果无法解析 JSON，尝试提取冒号后的部分
      final colonIndex = message.indexOf(':');
      if (colonIndex != -1 && colonIndex < message.length - 1) {
        return message.substring(colonIndex + 1).trim();
      }
    } catch (e) {
      // 解析失败，返回原始消息
    }

    return message;
  }

  /// 关闭 Dio 实例
  void close() {
    _dio?.close();
    _dio = null;
  }
}
