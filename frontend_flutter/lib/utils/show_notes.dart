import 'package:flutter/material.dart';

/// 显示对话框
///
/// 显示一个带有标题和消息的对话框
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

/// 显示提示消息
///
/// 在屏幕底部显示一个短暂的提示消息
/// [message] 消息内容
/// [color] 背景颜色
/// [duration] 显示时长（毫秒）
showMySnackBar(BuildContext context, String message, Color color, int duration) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(milliseconds: duration),
      content: Text(message),
      backgroundColor: color,
    ),
  );
}
