import 'package:flutter/material.dart';
import 'package:listenvision/app.dart';

/// SnackBar 辅助类
///
/// 统一项目中的 SnackBar 风格：
/// - 使用 floating 样式 + 半透明背景
/// - 默认 2 秒时长
/// - 统一的颜色语义
/// - 支持通过全局 key（无需 BuildContext）和 Context 两种方式调用
class SnackbarHelper {
  /// 半透明度（0-255，值越小越透明）
  static const int _alpha = 200;

  /// 通过全局 ScaffoldMessengerKey 显示提示（无需 BuildContext）
  ///
  /// 供 ViewModel 等无 Context 的层使用。
  static void showToast(
    String message, {
    Color color = Colors.blue,
    int duration = 2000,
  }) {
    final state = App.scaffoldMessengerKey.currentState;
    if (state == null) return;
    state.showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: duration),
        content: Text(message),
        backgroundColor: color.withAlpha(_alpha),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
    Color color, {
    int duration = 2000,
    SnackBarBehavior? behavior,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: duration),
        content: Text(message),
        backgroundColor: color.withAlpha(_alpha),
        behavior: behavior ?? SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    int duration = 2000,
  }) {
    showSnackBar(context, message, Colors.green, duration: duration);
  }

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    int duration = 2000,
  }) {
    showSnackBar(context, message, Colors.red, duration: duration);
  }

  /// 显示警告提示
  static void showWarning(
    BuildContext context,
    String message, {
    int duration = 2000,
  }) {
    showSnackBar(context, message, Colors.orange, duration: duration);
  }

  /// 显示信息提示
  static void showInfo(
    BuildContext context,
    String message, {
    int duration = 2000,
  }) {
    showSnackBar(context, message, Colors.blue, duration: duration);
  }

  /// 显示播放提示
  ///
  /// 专用于音频播放开始时的提示
  /// [context] 上下文
  /// [title] 音频标题
  /// [artist] 艺术家（可选）
  static void showPlaying(
    BuildContext context,
    String title, {
    String? artist,
    int duration = 2000,
  }) {
    final message = artist != null && artist.isNotEmpty
        ? '正在播放: $title - $artist'
        : '正在播放: $title';
    showSnackBar(context, message, Colors.blue, duration: duration);
  }
}

/// 显示对话框
///
/// 显示一个带有标题和消息的对话框
/// @Deprecated('请使用 showDialog 或 SnackbarHelper')
Future<dynamic> showMyDialog(BuildContext context, String title, String message) async {
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
  SnackbarHelper.showSnackBar(context, message, color, duration: duration);
}
