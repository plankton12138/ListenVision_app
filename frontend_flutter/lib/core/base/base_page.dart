import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 登录要求行为
enum LoginRequiredBehavior {
  /// 重定向到登录页
  redirectToLogin,
  /// 仅显示提示
  showPromptOnly,
  /// 不做任何处理
  none,
}

/// Page基类Mixin
///
/// 提供页面的通用功能：
/// - 登录状态检查
/// - 错误提示
/// - 确认对话框
mixin BasePageState<T extends StatefulWidget> on State<T> {
  /// 检查登录状态
  ///
  /// [behavior] 未登录时的行为
  /// [message] 提示消息
  /// 返回用户是否已登录
  @protected
  bool checkLogin({
    LoginRequiredBehavior behavior = LoginRequiredBehavior.redirectToLogin,
    String? message,
  }) {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      switch (behavior) {
        case LoginRequiredBehavior.redirectToLogin:
          showMySnackBar(
            context,
            message ?? '请先登录',
            Colors.orange,
            1500,
          );
          context.go('/login');
          break;
        case LoginRequiredBehavior.showPromptOnly:
          showMySnackBar(
            context,
            message ?? '请先登录',
            Colors.orange,
            1500,
          );
          break;
        case LoginRequiredBehavior.none:
          break;
      }
      return false;
    }
    return true;
  }

  /// 显示错误SnackBar
  @protected
  void showError(String message) {
    showMySnackBar(context, message, Colors.red, 2000);
  }

  /// 显示成功SnackBar
  @protected
  void showSuccess(String message) {
    showMySnackBar(context, message, Colors.green, 1500);
  }

  /// 显示提示SnackBar
  @protected
  void showInfo(String message) {
    showMySnackBar(context, message, Colors.blue, 1500);
  }

  /// 显示确认对话框
  ///
  /// 返回用户选择，true表示确认
  @protected
  Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 显示输入对话框
  @protected
  Future<String?> showInputDialog({
    required String title,
    String? hintText,
    String? initialValue,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          maxLines: maxLines,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    ).then((value) {
      controller.dispose();
      return value;
    });
  }

  /// 显示加载对话框
  @protected
  void showLoadingDialog({String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  /// 隐藏当前对话框
  @protected
  void hideDialog() {
    Navigator.of(context).pop();
  }

  /// 安全执行setState（检查mounted）
  @protected
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// 延迟执行（在build完成后）
  @protected
  void postFrameCallback(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        callback();
      }
    });
  }
}

/// 自动检查登录的Page State
///
/// 在initState时自动检查登录状态
mixin AutoCheckLoginState<T extends StatefulWidget> on BasePageState<T> {
  @override
  void initState() {
    super.initState();
    postFrameCallback(() {
      if (checkLogin()) {
        onLoginVerified();
      }
    });
  }

  /// 登录验证成功后的回调
  @protected
  void onLoginVerified();
}
