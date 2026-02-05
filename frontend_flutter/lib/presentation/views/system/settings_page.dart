import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../viewmodels/system/theme_viewmodel.dart';

/// 设置页面
///
/// 提供主题切换、B站账号绑定等应用设置选项
/// 使用 Riverpod 的 ThemeViewModel 和 PlatformAuthViewModel
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeViewModelProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

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
          _buildDarkModeCard(context, themeMode: themeMode),
          const SizedBox(height: 16),
          // B站账号绑定
          _buildBilibiliBindCard(context, isLoggedIn),
        ],
      ),
    );
  }

  /// 深色模式开关卡片
  Widget _buildDarkModeCard(BuildContext context, {required AppThemeMode themeMode}) {
    final isDarkMode = themeMode == AppThemeMode.dark;
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
          Switch(
            value: isDarkMode,
            onChanged: (_) => ref.read(themeViewModelProvider.notifier).toggleTheme(),
          ),
        ],
      ),
    );
  }

  /// B站账号绑定卡片
  Widget _buildBilibiliBindCard(BuildContext context, bool isLoggedIn) {
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
    return Consumer(
      builder: (context, ref, child) {
        final platformAuthViewModel = ref.watch(platformAuthViewModelProvider);
        final isBound = platformAuthViewModel.isBound;
        final userInfo = platformAuthViewModel.getBoundAccount();
        final isLoading = platformAuthViewModel.platformAuthState.maybeWhen(
          qrLogin: (_, __, ___, ____) => true,
          orElse: () => false,
        );

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
                            'UID: ${userInfo.mid}',
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
                        : () => _confirmUnbind(context),
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
                        : () => _showQRCodeDialog(context),
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
  }

  /// 显示QR码登录对话框
  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _QRCodeDialog(
        ref: ref,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 确认解绑对话框
  Future<void> _confirmUnbind(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认解绑'),
        content: const Text('解绑后将无法使用B站推荐、UP主更新等功能，确认解绑？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认解绑'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(platformAuthViewModelProvider).unbind();
      if (mounted) {
        if (success) {
          DialogHelper.showSnackBar(context, '解绑成功', backgroundColor: Colors.green, duration: 1500);
        } else {
          final state = ref.read(platformAuthViewModelProvider).platformAuthState;
          final errorMsg = state.maybeWhen(
            error: (msg) => msg,
            orElse: () => '解绑失败',
          );
          DialogHelper.showSnackBar(context, errorMsg, backgroundColor: Colors.red, duration: 2000);
        }
      }
    }
  }
}

/// QR码登录对话框
class _QRCodeDialog extends StatefulWidget {
  final WidgetRef ref;
  final VoidCallback onClose;

  const _QRCodeDialog({
    required this.ref,
    required this.onClose,
  });

  @override
  State<_QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<_QRCodeDialog> {
  bool _dialogClosed = false;

  @override
  void initState() {
    super.initState();
    // 开始QR码登录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.ref.read(platformAuthViewModelProvider).startQRLogin();
    });
  }

  @override
  void dispose() {
    // 对话框关闭时取消QR码登录
    final provider = widget.ref.read(platformAuthViewModelProvider);
    if (!provider.isBound) {
      provider.cancelQRLogin();
    }
    super.dispose();
  }

  String _getStatusText(QRLoginStatus status) {
    switch (status) {
      case QRLoginStatus.none:
        return '初始化中...';
      case QRLoginStatus.pending:
        return '请使用B站APP扫描二维码';
      case QRLoginStatus.scanned:
        return '已扫描，请在手机上确认';
      case QRLoginStatus.success:
        return '登录成功！';
      case QRLoginStatus.expired:
        return '二维码已过期';
      case QRLoginStatus.failed:
        return '登录失败';
    }
  }

  Color _getStatusColor(QRLoginStatus status) {
    switch (status) {
      case QRLoginStatus.pending:
        return Colors.blue;
      case QRLoginStatus.scanned:
        return Colors.orange;
      case QRLoginStatus.success:
        return Colors.green;
      case QRLoginStatus.expired:
        return Colors.red;
      case QRLoginStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final platformAuthViewModel = ref.watch(platformAuthViewModelProvider);

        final qrUrl = platformAuthViewModel.platformAuthState.maybeWhen(
          qrLogin: (_, url, __, ___) => url,
          orElse: () => null,
        );
        final status = platformAuthViewModel.platformAuthState.maybeWhen(
          qrLogin: (status, _, __, ___) => status,
          orElse: () => QRLoginStatus.none,
        );
        final isExpired = status == QRLoginStatus.expired;
        final isSuccess = status == QRLoginStatus.success || platformAuthViewModel.isBound;

        // 登录成功后自动关闭对话框（只执行一次）
        if (isSuccess && !_dialogClosed) {
          _dialogClosed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              widget.onClose();
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
                      if (status == QRLoginStatus.pending)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          status == QRLoginStatus.scanned
                              ? Icons.qr_code_scanner
                              : status == QRLoginStatus.success
                                  ? Icons.check_circle
                                  : status == QRLoginStatus.expired || status == QRLoginStatus.failed
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
