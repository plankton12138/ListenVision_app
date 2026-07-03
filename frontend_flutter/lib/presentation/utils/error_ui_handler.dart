import 'package:flutter/material.dart';

import '../../core/utils/error_handler.dart';
import '../widgets/error_banner.dart';

/// 错误 UI 处理器
///
/// 统一的错误/提示显示管理器，提供一致的用户体验
/// 所有错误和提示都应该通过此类显示，避免直接使用 ScaffoldMessenger
///
/// 支持多种提示方式：
/// - showError: 错误提示（红色背景）
/// - showSuccess: 成功提示（绿色背景）
/// - showWarning: 警告提示（橙色背景）
/// - showInfo: 信息提示（蓝色背景）
/// - showToast: 轻量级提示（灰色背景，短时间显示）
///
/// 还支持对话框形式：
/// - showErrorDialog: 错误对话框（重要错误）
/// - showConfirmDialog: 确认对话框
///
/// 使用示例：
/// ```dart
/// // 简单错误提示
/// ErrorUIHandler.showError(context, '网络连接失败');
///
/// // 带重试的错误提示
/// ErrorUIHandler.showError(
///   context,
///   '加载失败',
///   onRetry: () => _loadData(),
/// );
///
/// // 成功提示
/// ErrorUIHandler.showSuccess(context, '下载完成');
///
/// // 确认对话框
/// final confirmed = await ErrorUIHandler.showConfirmDialog(
///   context,
///   title: '确认删除',
///   message: '确定要删除这首歌吗？',
/// );
/// ```
class ErrorUIHandler {
  // ==================== SnackBar 提示 ====================

  /// 显示错误 SnackBar
  ///
  /// 适合大多数场景的错误提示，红色背景
  static void showError(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = _extractMessage(error);
    final displayTitle = title ?? _getErrorTitle(error);

    _showSnackBar(
      context,
      content: displayTitle != null ? '$displayTitle: $message' : message,
      backgroundColor: Colors.red.shade700,
      duration: duration,
      icon: Icons.error_outline,
      action: onRetry != null
          ? SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }

  /// 显示成功 SnackBar
  ///
  /// 绿色背景，用于操作成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showSnackBar(
      context,
      content: message,
      backgroundColor: Colors.green.shade700,
      duration: duration,
      icon: Icons.check_circle_outline,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );
  }

  /// 显示警告 SnackBar
  ///
  /// 橙色背景，用于需要注意但不阻断操作的情况
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      content: message,
      backgroundColor: Colors.orange.shade700,
      duration: duration,
      icon: Icons.warning_amber_outlined,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );
  }

  /// 显示信息 SnackBar
  ///
  /// 蓝色背景，用于普通信息提示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      content: message,
      backgroundColor: Colors.blue.shade700,
      duration: duration,
      icon: Icons.info_outline,
    );
  }

  /// 显示轻量级 Toast 提示
  ///
  /// 灰色背景，浮动显示，用于简短提示
  static void showToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        duration: duration,
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== 对话框 ====================

  /// 显示错误对话框
  ///
  /// 适用于需要用户确认的重要错误
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    final message = _extractMessage(error);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
        title: Text(title ?? '出错了'),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('重试'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示确认对话框
  ///
  /// 返回 true 表示确认，false 表示取消
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText ?? '取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText ?? '确定'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 显示输入对话框
  ///
  /// 返回用户输入的字符串，取消则返回 null
  static Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? hintText,
    String? initialValue,
    String? confirmText,
    String? cancelText,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) async {
    if (!context.mounted) return null;

    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hintText),
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(cancelText ?? '取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(confirmText ?? '确定'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  // ==================== 业务封装 ====================

  /// 显示网络错误提示
  ///
  /// 专门用于网络连接错误
  static void showNetworkError(
    BuildContext context, {
    String? message,
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      message ?? '网络连接失败，请检查网络设置',
      title: '网络错误',
      onRetry: onRetry,
    );
  }

  /// 显示权限错误提示
  ///
  /// 专门用于权限不足的情况
  static void showPermissionError(
    BuildContext context, {
    String? message,
  }) {
    showWarning(
      context,
      message ?? '权限不足，无法执行此操作',
    );
  }

  // ==================== 便捷操作封装 ====================

  /// 安全地执行异步操作，自动处理错误并显示
  ///
  /// 返回 true 表示成功，false 表示失败
  static Future<bool> tryAsync(
    BuildContext context,
    Future<void> Function() operation, {
    String? errorMessage,
    VoidCallback? onError,
    VoidCallback? onSuccess,
    bool showDialog = false,
    String? dialogTitle,
    bool showSuccess = false,
    String? successMessage,
  }) async {
    try {
      await operation();

      if (showSuccess && successMessage != null && context.mounted) {
        ErrorUIHandler.showSuccess(context, successMessage);
      }

      onSuccess?.call();
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);

      if (context.mounted) {
        final message = errorMessage ?? _extractMessage(e);

        if (showDialog) {
          await showErrorDialog(
            context,
            message,
            title: dialogTitle,
          );
        } else {
          showError(context, message);
        }
      }

      onError?.call();
      return false;
    }
  }

  /// 安全地执行同步操作，自动处理错误并显示
  ///
  /// 返回 true 表示成功，false 表示失败
  static bool trySync(
    BuildContext context,
    void Function() operation, {
    String? errorMessage,
    VoidCallback? onError,
    VoidCallback? onSuccess,
    bool showSuccess = false,
    String? successMessage,
  }) {
    try {
      operation();

      if (showSuccess && successMessage != null && context.mounted) {
        ErrorUIHandler.showSuccess(context, successMessage);
      }

      onSuccess?.call();
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);

      if (context.mounted) {
        showError(context, errorMessage ?? _extractMessage(e));
      }

      onError?.call();
      return false;
    }
  }

  // ==================== 错误 UI 组件 ====================

  /// 显示错误横幅
  ///
  /// 适用于页面级别的错误显示
  static Widget buildErrorBanner(
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final message = _extractMessage(error);
    return ErrorBanner(
      message: message,
      onRetry: onRetry,
    );
  }

  /// 显示内联错误
  ///
  /// 适用于表单字段等紧凑空间
  static Widget buildInlineError(
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final message = _extractMessage(error);
    return InlineError(
      message: message,
      onRetry: onRetry,
    );
  }

  // ==================== 私有方法 ====================

  /// 显示 SnackBar 的基础方法
  static void _showSnackBar(
    BuildContext context, {
    required String content,
    required Color backgroundColor,
    required Duration duration,
    IconData? icon,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                content,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: duration,
        backgroundColor: backgroundColor.withAlpha(200),
        action: action,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  /// 从错误对象提取消息
  static String _extractMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return ErrorHandler.parseErrorMessage(error);
  }

  /// 获取错误标题
  static String? _getErrorTitle(dynamic error) {
    if (ErrorHandler.isNetworkError(error)) {
      return '网络错误';
    }
    if (ErrorHandler.isValidationError(error)) {
      return '输入错误';
    }
    return null;
  }
}
