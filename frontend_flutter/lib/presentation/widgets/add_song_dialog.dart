import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';

/// 添加歌曲对话框
///
/// Phase 5: 歌单管理功能扩展
/// 提供三种添加歌曲的方式：
/// 1. 从搜索结果添加（游客可用）
/// 2. 输入BV号添加（游客可用）
/// 3. 从播放历史添加（需要登录）
class AddSongDialog extends StatelessWidget {
  const AddSongDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '添加歌曲到歌单',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(height: 1),

            // 选项列表
            _buildOption(
              context,
              icon: Icons.search,
              title: '从搜索结果添加',
              subtitle: '搜索B站视频或音频',
              onTap: () {
                Navigator.pop(context);
                context.go('/search');
              },
            ),

            _buildOption(
              context,
              icon: Icons.link,
              title: '输入BV号添加',
              subtitle: '直接输入B站视频BV号',
              onTap: () {
                Navigator.pop(context);
                _showBvidInputDialog(context);
              },
            ),

            // 从历史记录添加（需要登录）
            if (isLoggedIn)
              _buildOption(
                context,
                icon: Icons.history,
                title: '从历史记录添加',
                subtitle: '查看播放历史并添加',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/history');
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 构建选项项
  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 显示BV号输入对话框
  void _showBvidInputDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入BV号'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'BV号（例如：BV1xx411c7bW）',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.none,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final bvid = controller.text.trim();
              if (bvid.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入BV号')),
                );
                return;
              }

              // 导航到搜索页面并自动搜索BV号
              Navigator.pop(context);
              // TODO: 将BV号传递给搜索页面
              // 暂时只导航到搜索页面
              context.go('/search');
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}
