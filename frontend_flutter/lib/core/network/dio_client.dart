import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../utils/app_logger.dart';
import 'adaptive_network_manager.dart';

/// Dio 网络客户端
///
/// 单例 Dio 客户端
class DioClient {
  /// 单例实例
  static DioClient? _instance;

  /// Dio 实例
  Dio? _dio;

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
        final errorSummary = _getErrorSummary(error);
        AppLogger.error('DioClient', '请求失败: ${error.requestOptions.method} ${error.requestOptions.uri} - $errorSummary');

        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          await _networkManager.refreshQuality();
        }

        return handler.next(error);
      },
    ));

    return dio;
  }

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
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final data = error.response?.data;

        // 尝试从响应中解析错误信息
        String errorMessage = '请求失败';
        String? errorCode;

        if (data is Map<String, dynamic>) {
          // FastAPI 422 错误使用 "detail" 字段
          if (data['detail'] != null) {
            if (data['detail'] is List) {
              final details = data['detail'] as List;
              if (details.isNotEmpty && details.first is Map) {
                final first = details.first as Map<String, dynamic>;
                errorMessage = first['msg'] as String? ?? '参数验证失败';
                final loc = first['loc'] as List?;
                if (loc != null && loc.length > 1) {
                  errorMessage = '${loc.last}: $errorMessage';
                }
              }
            } else if (data['detail'] is String) {
              errorMessage = data['detail'] as String;
            }
            errorCode = 'VALIDATION_ERROR';
          } else {
            errorMessage = data['error'] as String?
                        ?? data['message'] as String?
                        ?? '请求失败';
            errorCode = data['code'] as String?;
          }
        }

        // 返回 ApiServerException
        return ApiServerException.fromResponse(
          error: errorMessage,
          statusCode: statusCode,
          code: errorCode,
        );
      case DioExceptionType.cancel:
        return const TaskCanceledException();
      case DioExceptionType.connectionError:
        return  NetworkException.noConnection();
      case DioExceptionType.badCertificate:
        return const NetworkException('证书错误', 'BAD_CERTIFICATE');
      case DioExceptionType.unknown:
      default:
        // 检查是否是网络错误
        if (error.error is SocketException) {
          return NetworkException.noConnection();
        }
        return  NetworkException.requestFailed();
    }
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

  /// 关闭 Dio 实例
  void close() {
    _dio?.close();
    _dio = null;
  }
}
