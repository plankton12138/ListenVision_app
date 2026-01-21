import 'package:flutter/material.dart';

/// SnackBar 辅助类
///
/// 从 utils/show_notes.dart 迁移到 presentation/widgets/common/
class SnackbarHelper {
  /// 显示提示消息
  ///
  /// 在屏幕底部显示一个短暂的提示消息
  /// [context] 上下文
  /// [message] 消息内容
  /// [color] 背景颜色
  /// [duration] 显示时长（毫秒）
  static void showSnackBar(
    BuildContext context,
    String message,
    Color color,
    int duration,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: duration),
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    int duration = 2000,
  }) {
    showSnackBar(context, message, Colors.green, duration);
  }

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    int duration = 2000,
  }) {
    showSnackBar(context, message, Colors.red, duration);
  }

  /// 显示警告提示
  static void showWarning(
    BuildContext context,
    String message, {
    int duration = 2000,
  }) {
    showSnackBar(context, message, Colors.orange, duration);
  }

  /// 显示信息提示
  static void showInfo(
    BuildContext context,
    String message, {
    int duration = 2000,
  }) {
    showSnackBar(context, message, Colors.blue, duration);
  }
}

/// 显示对话框
///
/// 显示一个带有标题和消息的对话框
/// @Deprecated('请使用 showDialog 或 SnackbarHelper')
showMyDialog(BuildContext context, String title, String message) async {
  var result = await showDialog(
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
  return result;
}

/// 向后兼容的函数导出
/// @Deprecated('请使用 SnackbarHelper.showSnackBar()')
void showMySnackBar(
  BuildContext context,
  String message,
  Color color,
  int duration,
) {
  SnackbarHelper.showSnackBar(context, message, color, duration);
}
