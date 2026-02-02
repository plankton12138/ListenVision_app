import 'dart:async';

import 'package:demo/core/base/base_page.dart';
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/presentation/providers/theme/theme_provider.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 设置页面
///
/// 提供主题切换、B站账号绑定等应用设置选项
/// 使用 AsyncUIHandlerMixin 统一处理异步操作和错误
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with BasePageState, AsyncUIHandlerMixin {
  @override
  void initState() {
    super.initState();
    // 初始化时检查B站绑定状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BilibiliProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '设置',
          style: TextStyle(
            fontSize: UIConstants.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 深色模式开关
          _buildDarkModeCard(context),
          const SizedBox(height: 16),
          // B站账号绑定
          _buildBilibiliBindCard(context),
        ],
      ),
    );
  }

  /// 深色模式开关卡片
  Widget _buildDarkModeCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '深色模式',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          CupertinoSwitch(
            value: Provider.of<ThemeController>(context, listen: false).isDarkMode,
            onChanged: (value) =>
                Provider.of<ThemeController>(context, listen: false).toggleTheme(),
          ),
        ],
      ),
    );
  }

  /// B站账号绑定卡片
  Widget _buildBilibiliBindCard(BuildContext context) {
    // 使用 Selector 只监听 isLoggedIn 属性
    return Selector<AuthProvider, bool>(
      selector: (context, auth) => auth.isLoggedIn,
      builder: (context, isLoggedIn, child) {
        if (!isLoggedIn) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'B站账号绑定',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '需要登录',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '请先登录后才能绑定B站账号',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('去登录'),
                  ),
                ),
              ],
            ),
          );
        }

        // 已登录，显示绑定界面
        return Consumer<BilibiliProvider>(
          builder: (context, bilibiliProvider, child) {
            final isBound = bilibiliProvider.isBound;
            final userInfo = bilibiliProvider.boundUserInfo;
            final isLoading = bilibiliProvider.isLoading;

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    children: [
                      const Icon(Icons.link, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'B站账号绑定',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      // 绑定状态标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isBound ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isBound ? '已绑定' : '未绑定',
                          style: TextStyle(
                            color: isBound ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 已绑定用户信息
                  if (isBound && userInfo != null) ...[
                Row(
                  children: [
                    // 头像
                    ClipOval(
                      child: Image.network(
                        userInfo.avatar,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 30),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 用户信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userInfo.uname,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UID: ${userInfo.uid}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 解绑按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _confirmUnbind(context, bilibiliProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('解绑账号'),
                  ),
                ),
              ] else ...[
                // 未绑定提示
                Text(
                  '绑定B站账号后可使用推荐、UP主更新等功能',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                // 绑定按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _showQRCodeDialog(context, bilibiliProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('绑定账号'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
      },
    );
  }

  /// 显示QR码登录对话框
  void _showQRCodeDialog(BuildContext context, BilibiliProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _QRCodeDialog(provider: provider),
    );
  }

  /// 确认解绑对话框
  ///
  /// 使用 AsyncUIHandlerMixin 的 runAsync 方法
  /// 自动管理加载状态和错误处理
  Future<void> _confirmUnbind(BuildContext context, BilibiliProvider provider) async {
    final confirmed = await showConfirmDialog(
      title: '确认解绑',
      content: '解绑后将无法使用B站推荐、UP主更新等功能，确认解绑？',
      confirmText: '确认解绑',
      isDangerous: true,
    );

    if (confirmed == true && mounted) {
      final success = await provider.unbindAccount();
      if (mounted) {
        if (success) {
          showSuccess('解绑成功');
        } else {
          showError(provider.errorMessage ?? '解绑失败');
        }
      }
    }
  }
}

/// QR码登录对话框
class _QRCodeDialog extends StatefulWidget {
  final BilibiliProvider provider;

  const _QRCodeDialog({required this.provider});

  @override
  _QRCodeDialogState createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<_QRCodeDialog> {
  bool _dialogClosed = false;

  @override
  void initState() {
    super.initState();
    // 开始QR码登录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.startQRLogin();
    });
  }

  @override
  void dispose() {
    // 对话框关闭时取消QR码登录
    // 使用 scheduleMicrotask 避免 widget 树锁定时调用 notifyListeners
    if (!widget.provider.isBound) {
      scheduleMicrotask(() {
        widget.provider.cancelQRLogin();
      });
    }
    super.dispose();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'none':
        return '初始化中...';
      case 'pending':
        return '请使用B站APP扫描二维码';
      case 'scanned':
        return '已扫描，请在手机上确认';
      case 'success':
        return '登录成功！';
      case 'expired':
        return '二维码已过期';
      default:
        return '未知状态';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'scanned':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, child) {
        final qrUrl = widget.provider.qrcodeUrl;
        final status = widget.provider.qrLoginStatus;
        final isExpired = status == 'expired' || !widget.provider.isQrValid;
        final isSuccess = status == 'success' || widget.provider.isBound;

        // 登录成功后自动关闭对话框（只执行一次）
        if (isSuccess && !_dialogClosed) {
          _dialogClosed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              // 延迟显示SnackBar，确保对话框完全关闭后再显示
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  DialogHelper.showSnackBar(context, 'B站账号绑定成功！', backgroundColor: Colors.green, duration: 2000);
                }
              });
            }
          });
        }

        return AlertDialog(
          title: const Text('B站账号绑定'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR码显示
                if (qrUrl != null && !isExpired)
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: qrUrl,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  )
                else
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          isExpired ? Icons.qr_code_2 : Icons.hourglass_empty,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // 状态提示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'pending')
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          status == 'scanned'
                              ? Icons.qr_code_scanner
                              : status == 'success'
                                  ? Icons.check_circle
                                  : status == 'expired'
                                      ? Icons.error
                                      : Icons.info,
                          size: 16,
                          color: _getStatusColor(status),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 说明文字
                Text(
                  '打开B站APP，扫描二维码登录',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }
}
