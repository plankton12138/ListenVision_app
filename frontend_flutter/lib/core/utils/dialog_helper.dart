import 'package:flutter/material.dart';

/// 对话框工具类
///
/// 提供通用的对话框和提示消息显示功能
class DialogHelper {
  /// 显示确认对话框
  ///
  /// 显示一个带有标题和消息的对话框
  static Future<String?> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.pop(context, 'OK');
              },
            ),
          ],
        );
      },
    );
  }

  /// 显示提示消息
  ///
  /// 在屏幕底部显示一个短暂的提示消息
  /// [message] 消息内容
  /// [backgroundColor] 背景颜色
  /// [duration] 显示时长（毫秒）
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    int duration = 3000,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: duration),
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// 显示成功提示
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  /// 显示错误提示
  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// 显示信息提示
  static void showInfo(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.blue);
  }

  /// 显示警告提示
  static void showWarning(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.orange);
  }

  /// 显示错误对话框（便捷方法）
  ///
  /// 统一的错误显示方式，自动使用红色样式
  static Future<void> showErrorDialog(
    BuildContext context,
    String message, {
    String title = '操作失败',
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 32,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                onRetry();
                Navigator.of(context).pop();
              },
              child: const Text('重试'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示确认对话框（带取消选项）
  ///
  /// 返回 true 表示用户点击了确定，false 表示取消
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// 兼容旧代码的函数别名
@Deprecated('使用 DialogHelper.showConfirmationDialog 代替')
showMyDialog(BuildContext context, String title, String message) {
  return DialogHelper.showConfirmationDialog(context, title, message);
}

/// 兼容旧代码的函数别名
@Deprecated('使用 DialogHelper.showSnackBar 代替')
showMySnackBar(
  BuildContext context,
  String message,
  Color color,
  int duration,
) {
  return DialogHelper.showSnackBar(
    context,
    message,
    backgroundColor: color,
    duration: duration,
  );
}
