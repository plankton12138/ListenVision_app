import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../errors/exceptions.dart';
import '../../presentation/widgets/error_banner.dart';
import 'dialog_helper.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 统一错误处理器
///
/// 提供统一的错误处理机制，将各种异常转换为用户友好的中文消息
/// 并提供多种显示方式（SnackBar、Dialog、Banner）
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
          return _mapStatusCode(statusCode);
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
  static String _mapStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限访问';
      case 404:
        return '请求的资源不存在';
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

  /// 显示错误（SnackBar）
  ///
  /// 默认使用 SnackBar 显示错误，适合大多数场景
  static void showError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 3),
  }) {
    final message = parseErrorMessage(error);

    if (onRetry != null) {
      // 带重试按钮的 SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: '重试',
            textColor: Colors.white,
            onPressed: onRetry,
          ),
        ),
      );
    } else {
      DialogHelper.showError(context, message);
    }
  }

  /// 显示错误对话框
  ///
  /// 适用于需要用户确认的重要错误
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    final message = parseErrorMessage(error);

    if (!context.mounted) return;
    await ErrorDialog.show(
      context,
      title: title ?? '操作失败',
      message: message,
      onRetry: onRetry,
    );
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

  /// 安全地执行异步操作，自动处理错误
  ///
  /// 返回 true 表示成功，false 表示失败
  static Future<bool> tryAsync(
    Future<void> Function() operation, {
    BuildContext? context,
    String? errorMessage,
    VoidCallback? onError,
  }) async {
    try {
      await operation();
      return true;
    } catch (e, stackTrace) {
      logError(e, stackTrace: stackTrace);

      if (context != null && context.mounted) {
        showError(context, e);
      }

      onError?.call();
      return false;
    }
  }

  /// 安全地执行同步操作，自动处理错误
  ///
  /// 返回 true 表示成功，false 表示失败
  static bool trySync(
    void Function() operation, {
    BuildContext? context,
    String? errorMessage,
    VoidCallback? onError,
  }) {
    try {
      operation();
      return true;
    } catch (e, stackTrace) {
      logError(e, stackTrace: stackTrace);

      if (context != null && context.mounted) {
        showError(context, e);
      }

      onError?.call();
      return false;
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
}

/// SocketException 占位类
///
/// 用于 DioException 错误类型检测
/// 注：dart:io 的 SocketException 在平台间可能有差异
class SocketException implements Exception {
  final String message;
  SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}
