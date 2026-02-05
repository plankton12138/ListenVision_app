import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../utils/app_logger.dart';
import 'adaptive_network_manager.dart';

/// Dio 网络客户端
///
/// 单例 Dio 客户端，支持动态 token 更新
class DioClient {
  /// 单例实例
  static DioClient? _instance;

  /// Dio 实例
  Dio? _dio;

  /// 当前 token
  String? _token;

  /// 网络管理器
  late final AdaptiveNetworkManager _networkManager;

  /// 私有构造函数
  DioClient._internal() {
    _networkManager = AdaptiveNetworkManager();
    _dio = _createDio();
  }

  /// 获取单例
  static DioClient get instance {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  /// 获取 Dio 实例
  Dio get dio {
    if (_dio == null) {
      _dio = _createDio();
    }
    return _dio!;
  }

  /// 创建 Dio 实例
  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.fullBaseUrl,
      connectTimeout: _networkManager.getConnectTimeout(),
      receiveTimeout: _networkManager.getReceiveTimeout(),
      sendTimeout: _networkManager.getConnectTimeout(),
      headers: {
        HttpHeaders.contentType: HttpHeaders.json,
      },
    ));

    // 监听网络质量变化
    _networkManager.addQualityListener((quality) {
      dio.options.connectTimeout = _networkManager.getConnectTimeout();
      dio.options.receiveTimeout = _networkManager.getReceiveTimeout();
      dio.options.sendTimeout = _networkManager.getConnectTimeout();
      AppLogger.info('DioClient', '网络质量变化，更新超时配置: $quality');
    });

    // 添加请求拦截器
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.debug('DioClient', '请求: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.debug('DioClient', '响应: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        // 简化错误信息（避免冗长的 Dio 堆栈）
        final errorSummary = _getErrorSummary(error);
        AppLogger.error('DioClient', '请求失败: ${error.requestOptions.method} ${error.requestOptions.uri} - $errorSummary');

        // 网络错误时刷新网络质量
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          await _networkManager.refreshQuality();
        }

        return handler.next(error);
      },
    ));

    return dio;
  }

  /// 更新认证 Token
  ///
  /// 当用户登录/登出时调用，全局更新 Authorization header
  void updateToken(String? token) {
    _token = token;
    if (token != null && token.isNotEmpty) {
      dio.options.headers[HttpHeaders.authorization] = '${HttpHeaders.bearer}$token';
      AppLogger.info('DioClient', 'Token 已更新');
    } else {
      dio.options.headers.remove(HttpHeaders.authorization);
      AppLogger.info('DioClient', 'Token 已清除');
    }
  }

  /// 获取当前 Token
  String? get currentToken => _token;

  // ==================== 通用请求方法 ====================

  /// GET 请求
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST 请求
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT 请求
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE 请求
  Future<Map<String, dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 下载文件
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
      AppLogger.info('DioClient', '文件下载成功: $savePath');
    } on DioException catch (e) {
      AppLogger.error('DioClient', '文件下载失败: ${e.message}');
      throw _handleDioError(e);
    }
  }

  // ==================== 响应处理 ====================

  /// 处理响应
  Map<String, dynamic> _handleResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'data': data};
  }

  /// 处理 Dio 错误
  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      // 优先使用服务器返回的错误消息
      String? message;
      if (responseData is Map<String, dynamic>) {
        message = responseData['message']?.toString() ??
            responseData['error']?.toString();
      }

      // 使用简化的错误消息（服务器消息或摘要）
      final errorSummary = message ?? _getErrorSummary(e);
      return ApiException(_parseValidationError(errorSummary), statusCode ?? 500);
    }
    // 无响应的情况（网络错误）
    final errorSummary = _getErrorSummary(e);
    return ApiException('网络错误: $errorSummary', 500);
  }

  /// 获取简化的错误摘要
  String _getErrorSummary(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return 'HTTP $statusCode';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '连接错误';
      case DioExceptionType.badCertificate:
        return '证书错误';
      case DioExceptionType.unknown:
        // 只取错误消息的第一行，避免冗长堆栈
        final msg = error.message ?? '未知错误';
        final lines = msg.split('\n');
        return lines.first.trim();
    }
  }

  /// 解析验证错误信息
  String _parseValidationError(String message) {
    if (!message.contains('参数验证失败') && !message.contains('验证失败')) {
      return message;
    }

    try {
      final startIndex = message.indexOf('[');
      final endIndex = message.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonStr = message.substring(startIndex, endIndex + 1);
        final errors = jsonDecode(jsonStr) as List<dynamic>;

        if (errors.isNotEmpty) {
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

      final colonIndex = message.indexOf(':');
      if (colonIndex != -1 && colonIndex < message.length - 1) {
        return message.substring(colonIndex + 1).trim();
      }
    } catch (_) {
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
