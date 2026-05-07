import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/auth/platform_auth_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/settings/scan_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/library/local_music_viewmodel.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'package:listenvision/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../viewmodels/system/theme_viewmodel.dart';
import '../../../core/storage/shared_storage_service.dart';

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
          _buildLocalMusicScanCard(context),
          const SizedBox(height: 16),
          _buildDarkModeCard(context, themeMode: themeMode),
          const SizedBox(height: 16),
          _buildDownloadFormatCard(context),
          const SizedBox(height: 16),
          if (!isLoggedIn) _buildLoginPromptCard(context),
          if (isLoggedIn) ...[
            const SizedBox(height: 16),
            _buildBilibiliBindCard(context, isLoggedIn),
            const SizedBox(height: 16),
            _buildNeteaseBindCard(context, isLoggedIn),
            const SizedBox(height: 16),
            _buildSyncStatusCard(context, isLoggedIn),
            const SizedBox(height: 16),
            _buildAccountActionsCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalMusicScanCard(BuildContext context) {
    final scanState = ref.watch(scanViewModelProvider);

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
              const Icon(Icons.library_music, size: 20),
              const SizedBox(width: 8),
              const Text(
                '本地音乐',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '扫描设备中的音频文件',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: scanState.maybeWhen(
              scanning: (current, total, fileName) {
                final progress = total > 0 ? current / total : 0.0;
                return Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      '正在扫描 ($current/$total): $fileName',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
              requestingPermission: () => const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('请求权限中...'),
                ],
              ),
              orElse: () => ElevatedButton.icon(
                onPressed: () => _startScan(context),
                icon: const Icon(Icons.search),
                label: const Text('扫描本地音乐'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          scanState.maybeWhen(
            completed: (result) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    result.summary,
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
            error: (message) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan(BuildContext context) async {
    await ref.read(scanViewModelProvider.notifier).startScan(minDurationSeconds: 10);

    if (mounted) {
      final result = ref.read(scanViewModelProvider);
      result.maybeWhen(
        completed: (scanResult) {
          if (scanResult.addedCount > 0) {
            ref.read(localMusicViewModelProvider.notifier).refresh();
          }
          DialogHelper.showSnackBar(
            context,
            '扫描完成: ${scanResult.summary}',
            backgroundColor: scanResult.addedCount > 0 ? Colors.green : Colors.grey[700]!,
          );
        },
        error: (message) {
          DialogHelper.showSnackBar(context, message, backgroundColor: Colors.red);
        },
        orElse: () {},
      );
    }
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

  /// 下载音频格式选择卡片
  Widget _buildDownloadFormatCard(BuildContext context) {
    final storage = SharedStorageService.instance;
    final currentFormat = storage.getDownloadFormat();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '下载音质',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                currentFormat == 'mp3' ? 'MP3 格式（跨平台兼容）' : '默认格式（M4A，零转换）',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Switch(
            value: currentFormat == 'mp3',
            onChanged: (isMp3) async {
              final success = await storage.setDownloadFormat(isMp3 ? 'mp3' : 'm4a');
              if (success) {
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  /// 登录提示卡片（未登录用户）
  Widget _buildLoginPromptCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '登录获取更多功能',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '歌单同步、B站推荐、播放历史...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('去登录'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// B站账号绑定卡片
  Widget _buildBilibiliBindCard(BuildContext context, bool isLoggedIn) {
    const bilibiliPink = Color(0xFFFB7299);
    
    if (!isLoggedIn) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bilibiliPink.withValues(alpha: 0.15), bilibiliPink.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: bilibiliPink.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bilibiliPink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_outline, size: 20, color: bilibiliPink),
                ),
                const SizedBox(width: 8),
                const Text(
                  'B站账号绑定',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
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
                  backgroundColor: bilibiliPink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('去登录'),
              ),
            ),
          ],
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        return ref.watch(platformAuthViewModelProvider).when(
          data: (platformAuthState) {
            final isBound = platformAuthState.maybeWhen(
              bound: (_) => true,
              orElse: () => false,
            );
            final userInfo = platformAuthState.maybeWhen(
              bound: (account) => account,
              orElse: () => null,
            );
            final isLoading = platformAuthState.maybeWhen(
              qrLogin: (_, __, ___, ____) => true,
              orElse: () => false,
            );

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isBound 
                      ? [bilibiliPink.withValues(alpha: 0.2), bilibiliPink.withValues(alpha: 0.1)]
                      : [bilibiliPink.withValues(alpha: 0.15), bilibiliPink.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: bilibiliPink.withValues(alpha: isBound ? 0.4 : 0.3)),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: bilibiliPink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_circle_outline, size: 20, color: bilibiliPink),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'B站账号绑定',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isBound ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
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
                  if (isBound && userInfo != null) ...[
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: bilibiliPink, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              userInfo.avatar,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: bilibiliPink.withValues(alpha: 0.2),
                                  child: const Icon(Icons.person, size: 30, color: bilibiliPink),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userInfo.uname,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'UID: ${userInfo.mid}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => _confirmUnbind(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('解绑账号'),
                      ),
                    ),
                  ] else ...[
                    Text(
                      '绑定B站账号后可使用推荐、UP主更新等功能',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _showQRCodeDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bilibiliPink,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('绑定账号'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(15),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(15),
            child: const Text('加载失败'),
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
      final success = await ref.read(platformAuthViewModelProvider.notifier).unbind();
      if (mounted) {
        if (success) {
          DialogHelper.showSnackBar(context, '解绑成功', backgroundColor: Colors.green, duration: 1500);
        } else {
          final errorMsg = ref.read(platformAuthViewModelProvider).when(
            data: (state) => state.maybeWhen(
              error: (msg) => msg,
              orElse: () => '解绑失败',
            ),
            loading: () => '解绑失败',
            error: (err, _) => err.toString(),
          );
          DialogHelper.showSnackBar(context, errorMsg, backgroundColor: Colors.red, duration: 2000);
        }
      }
    }
  }

  /// 网易云账号绑定卡片（待开发）
  Widget _buildNeteaseBindCard(BuildContext context, bool isLoggedIn) {
    const neteaseRed = Color(0xFFC20C0C);

    if (!isLoggedIn) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            neteaseRed.withValues(alpha: 0.08),
            neteaseRed.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: neteaseRed.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: neteaseRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, size: 20, color: neteaseRed),
              ),
              const SizedBox(width: 8),
              const Text(
                '网易云音乐',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '待开发',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '网易云音乐功能正在开发中，敬请期待',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 数据同步状态卡片
  Widget _buildSyncStatusCard(BuildContext context, bool isLoggedIn) {
    if (!isLoggedIn) {
      return const SizedBox.shrink();
    }

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
              const Icon(Icons.cloud_sync, size: 20),
              const SizedBox(width: 8),
              const Text(
                '数据同步',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Icon(Icons.check_circle, size: 18, color: Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '本地数据将自动同步到服务器',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 账号操作卡片
  Widget _buildAccountActionsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                '账号信息',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentUser != null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
              ),
              title: Text(currentUser.username),
              subtitle: Text(currentUser.email ?? ''),
            ),
            const Divider(),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('退出登录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmLogout(context),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever, color: colorScheme.error),
            title: Text(
              '注销账号',
              style: TextStyle(color: colorScheme.error),
            ),
            trailing: Icon(Icons.chevron_right, color: colorScheme.error),
            onTap: () => _confirmDeleteAccount(context),
          ),
        ],
      ),
    );
  }

  /// 确认退出登录
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authViewModelProvider.notifier).logout();
      if (mounted) {
        DialogHelper.showSnackBar(context, '已退出登录', backgroundColor: Colors.green);
        context.go('/');
      }
    }
  }

  /// 确认注销账号
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注销账号'),
        content: const Text(
          '此操作将永久删除您的账号及所有数据，包括：\n'
          '• 歌单和收藏\n'
          '• 播放历史\n'
          '• B站账号绑定\n\n'
          '此操作不可撤销，确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(authViewModelProvider.notifier).deleteAccount();
      if (mounted) {
        if (success) {
          DialogHelper.showSnackBar(context, '账号已注销', backgroundColor: Colors.green);
          context.go('/');
        } else {
          DialogHelper.showSnackBar(context, '注销失败，请稍后重试', backgroundColor: Colors.red);
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
      widget.ref.read(platformAuthViewModelProvider.notifier).startQRLogin();
    });
  }

  @override
  void dispose() {
    // 对话框关闭时取消QR码登录
    final isBound = widget.ref.read(platformAuthViewModelProvider).when(
      data: (state) => state.maybeWhen(
        bound: (_) => true,
        orElse: () => false,
      ),
      loading: () => false,
      error: (_, __) => false,
    );
    if (!isBound) {
      widget.ref.read(platformAuthViewModelProvider.notifier).cancelQRLogin();
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
        return ref.watch(platformAuthViewModelProvider).when(
          data: (platformAuthState) {
            final qrUrl = platformAuthState.maybeWhen(
              qrLogin: (_, url, __, ___) => url,
              orElse: () => null,
            );
            final status = platformAuthState.maybeWhen(
              qrLogin: (status, _, __, ___) => status,
              orElse: () => QRLoginStatus.none,
            );
            final isBound = platformAuthState.maybeWhen(
              bound: (_) => true,
              orElse: () => false,
            );
            final isExpired = status == QRLoginStatus.expired;
            final isSuccess = status == QRLoginStatus.success || isBound;

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
          loading: () => const AlertDialog(
            title: Text('B站账号绑定'),
            content: SizedBox(
              width: 280,
              height: 300,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (err, _) => AlertDialog(
            title: const Text('B站账号绑定'),
            content: Text('加载失败: $err'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      },
    );
  }
}
