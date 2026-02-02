import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/core/utils/dialog_helper.dart';
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
          DialogHelper.showSnackBar(
            context,
            message ?? '请先登录',
            backgroundColor: Colors.orange,
            duration: 1500,
          );
          context.go('/login');
          break;
        case LoginRequiredBehavior.showPromptOnly:
          DialogHelper.showSnackBar(
            context,
            message ?? '请先登录',
            backgroundColor: Colors.orange,
            duration: 1500,
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
    DialogHelper.showSnackBar(context, message, backgroundColor: Colors.red, duration: 2000);
  }

  /// 显示成功SnackBar
  @protected
  void showSuccess(String message) {
    DialogHelper.showSnackBar(context, message, backgroundColor: Colors.green, duration: 1500);
  }

  /// 显示提示SnackBar
  @protected
  void showInfo(String message) {
    DialogHelper.showSnackBar(context, message, backgroundColor: Colors.blue, duration: 1500);
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

/// 异步UI处理Mixin
///
/// 提供统一的异步操作错误处理，自动管理加载状态和错误显示
/// 集成 ErrorHandler 进行错误解析和显示
///
/// 使用示例：
/// ```dart
/// class _MyPageState extends State<MyPage> with BasePageState, AsyncUIHandlerMixin {
///   Future<void> _loadData() async {
///     await runAsync(
///       operation: () => apiService.fetchData(),
///       loadingMessage: '加载中...',
///       onSuccess: () => showSuccess('加载成功'),
///     );
///   }
/// }
/// ```
mixin AsyncUIHandlerMixin<T extends StatefulWidget> on BasePageState<T> {
  /// 安全执行异步操作（带Loading状态管理）
  ///
  /// [operation] 异步操作
  /// [isLoadingSetter] Loading状态设置器
  /// [successMessage] 成功提示消息
  /// [onError] 错误回调
  @protected
  Future<void> runAsyncWithState({
    required Future<void> Function() operation,
    required void Function(bool) isLoadingSetter,
    String? successMessage,
    VoidCallback? onError,
  }) async {
    isLoadingSetter(true);
    try {
      await operation();
      if (mounted) {
        if (successMessage != null) {
          showSuccess(successMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        final message = _parseError(e);
        showError(message);
        onError?.call();
      }
    } finally {
      if (mounted) {
        isLoadingSetter(false);
      }
    }
  }

  /// 安全执行异步操作（无返回值）
  ///
  /// 自动处理：
  /// - 显示/隐藏加载对话框
  /// - 错误捕获和显示
  /// - mounted 状态检查
  @protected
  Future<void> runAsync({
    required Future<void> Function() operation,
    String? loadingMessage,
    String? successMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    if (loadingMessage != null && mounted) {
      showLoadingDialog(message: loadingMessage);
    }

    try {
      await operation();

      if (loadingMessage != null && mounted) {
        hideDialog();
      }

      if (mounted) {
        if (successMessage != null) {
          showSuccess(successMessage);
        }
        onSuccess?.call();
      }
    } catch (e, stackTrace) {
      // 使用 AppLogger 记录错误
      if (mounted) {
        final message = _parseError(e);
        showError(message);
        onError?.call();
      }
    }
  }

  /// 解析错误消息
  String _parseError(dynamic error) {
    if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('SocketException')) return '网络连接失败';
      if (msg.contains('TimeoutException')) return '操作超时';
      if (msg.contains(': ')) return msg.split(': ').last;
      return msg;
    }
    return error.toString();
  }
}
