import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/exceptions.dart';
import 'app_logger.dart';

/// 统一错误处理器
///
/// 提供统一的错误处理机制，将各种异常转换为用户友好的中文消息
///
/// 【架构说明】
/// 此类位于 Core 层，只包含纯逻辑（错误解析、判断等），不涉及 UI
/// 如需显示错误到 UI，请使用 presentation/utils/error_ui_handler.dart 中的 ErrorUIHandler
///
/// 【使用方式】
/// ```dart
/// // 1. 解析错误消息
/// final message = ErrorHandler.parseErrorMessage(error);
///
/// // 2. 判断是否可重试
/// if (ErrorHandler.isRetryable(error)) { ... }
///
/// // 3. 记录错误日志
/// ErrorHandler.logError(error, stackTrace: stackTrace);
///
/// // 4. 显示错误（在 UI 层）
/// ErrorUIHandler.showError(context, error); // 在 View/ViewModel 中调用
/// ```
class ErrorHandler {
  /// 解析异常并返回用户友好的错误消息
  ///
  /// 支持的异常类型：
  /// - AppException 及其子类（自定义异常）
  /// - DioException（网络请求异常）
  /// - Exception（通用异常）
  static String parseErrorMessage(dynamic error) {
    // 自定义异常（优先级最高）
    if (error is AppException) {
      return _mapAppException(error);
    }

    // Dio 网络异常
    if (error is DioException) {
      return _mapDioException(error);
    }

    // 其他异常
    return _mapGenericException(error);
  }

  /// 映射自定义异常到中文消息
  static String _mapAppException(AppException e) {
    // 所有 AppException 子类都有 message 属性，直接返回
    return e.message;
  }

  /// 映射 DioException 到中文消息
  static String _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '请求超时，请检查网络连接';

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null) {
          final responseData = e.response?.data;
          return _mapStatusCode(statusCode, responseData);
        }
        return '服务器响应异常';

      case DioExceptionType.cancel:
        return '请求已取消';

      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';

      case DioExceptionType.badCertificate:
        return '证书验证失败';

      case DioExceptionType.unknown:
        // 尝试从错误信息中提取有用的信息
        if (e.error is SocketException) {
          return '无法连接到服务器';
        }
        if (e.message != null) {
          return '网络请求失败: ${e.message}';
        }
        return '网络请求失败，请稍后重试';
    }
  }

  /// 映射 HTTP 状态码到中文消息
  ///
  /// [responseData] 服务器响应数据，用于提取具体错误信息
  static String _mapStatusCode(int statusCode, [dynamic responseData]) {
    // 尝试从响应数据中提取具体错误信息
    if (responseData != null) {
      final errorMessage = _extractErrorMessage(responseData);
      if (errorMessage != null) {
        return errorMessage;
      }
    }

    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限访问';
      case 404:
        return '请求的资源不存在';
      case 409:
        return '资源冲突，请检查是否重复提交';
      case 500:
        return '服务器内部错误';
      case 502:
      case 503:
      case 504:
        return '服务暂时不可用，请稍后重试';
      default:
        return '服务器错误 ($statusCode)';
    }
  }

  /// 从响应数据中提取错误信息
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    // 优先使用 message 字段
    if (responseData['message'] != null) {
      final message = responseData['message'].toString();
      // 解析验证错误数组
      if (message.contains('参数验证失败') || message.contains('验证失败')) {
        return _parseValidationError(message);
      }
      return message;
    }

    // 其次使用 error 字段
    if (responseData['error'] != null) {
      final message = responseData['error'].toString();
      // 解析验证错误数组
      if (message.contains('参数验证失败') || message.contains('验证失败')) {
        return _parseValidationError(message);
      }
      return message;
    }

    return null;
  }

  /// 解析验证错误信息
  ///
  /// 从 "参数验证失败: [{...}]" 格式中提取具体错误
  static String _parseValidationError(String message) {
    try {
      // 提取方括号内的 JSON 数组
      final startIndex = message.indexOf('[');
      final endIndex = message.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonStr = message.substring(startIndex, endIndex + 1);
        final errors = List.from(jsonDecode(jsonStr));

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

  /// 映射通用异常到中文消息
  static String _mapGenericException(dynamic error) {
    if (error is Exception) {
      final message = error.toString();

      // 常见异常模式匹配
      if (message.contains('SocketException')) {
        return '网络连接失败';
      }
      if (message.contains('FormatException')) {
        return '数据格式错误';
      }
      if (message.contains('TimeoutException')) {
        return '操作超时';
      }
      if (message.contains('FileSystemException')) {
        return '文件操作失败';
      }

      // 返回原始消息（去除类名前缀）
      if (message.contains(': ')) {
        return message.split(': ').last;
      }
      return message;
    }

    return error.toString();
  }

  /// 在开发模式下打印详细错误日志
  ///
  /// 用于调试，生产环境下只打印简要信息
  static void logError(
    dynamic error, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    final prefix = tag != null ? '[$tag] ' : '';

    if (kDebugMode) {
      // 开发模式：打印完整错误信息
      AppLogger.error('ErrorHandler', '$prefix错误类型: ${error.runtimeType}');
      AppLogger.error('ErrorHandler', '$prefix错误信息: $error');
      if (stackTrace != null) {
        AppLogger.debug('ErrorHandler', '$prefix堆栈跟踪:\n$stackTrace');
      }
    } else {
      // 生产模式：只打印简要信息
      AppLogger.error('ErrorHandler', '$prefix${parseErrorMessage(error)}');
    }
  }

  /// 判断错误是否可重试
  ///
  /// 某些错误（如网络超时、服务器错误）可以重试
  /// 某些错误（如认证失败、参数错误）不应重试
  static bool isRetryable(dynamic error) {
    if (error is AppException) {
      return error is NetworkException ||
          (error is ServerException &&
              error.statusCode != null &&
              error.statusCode! >= 500);
    }

    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError ||
          (error.response?.statusCode != null &&
              error.response!.statusCode! >= 500);
    }

    return false;
  }

  /// 判断是否需要重新登录
  ///
  /// 某些错误（如 token 过期）需要引导用户重新登录
  static bool requiresReauth(dynamic error) {
    if (error is AuthException) {
      return error.code == 'TOKEN_EXPIRED' ||
          error.code == 'TOKEN_INVALID' ||
          error.code == 'UNAUTHORIZED';
    }

    if (error is DioException) {
      return error.response?.statusCode == 401;
    }

    if (error is ServerException) {
      return error.statusCode == 401;
    }

    return false;
  }

  /// 判断是否为网络错误
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException) {
      return true;
    }

    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
    }

    return false;
  }

  /// 判断是否为验证错误
  static bool isValidationError(dynamic error) {
    if (error is ValidationException) {
      return true;
    }

    if (error is DioException) {
      return error.response?.statusCode == 400 ||
          error.response?.statusCode == 422;
    }

    return false;
  }
}
