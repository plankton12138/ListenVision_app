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
