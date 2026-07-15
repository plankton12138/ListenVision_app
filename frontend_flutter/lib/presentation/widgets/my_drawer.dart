import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 应用侧边栏抽屉
///
/// 显示应用信息和主菜单导航
class MyDrawer extends ConsumerWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          _buildMainMenu(context),
        ],
      ),
    );
  }

  /// 构建抽屉头部
  Widget _buildDrawerHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DrawerHeader(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Listen Vision',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '音乐播放器',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主菜单
  Widget _buildMainMenu(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildListTile(
            context: context,
            title: '首页',
            icon: Icons.home,
            route: '/',
          ),
          _buildListTile(
            context: context,
            title: '搜索',
            icon: Icons.search,
            route: '/search',
          ),
          _buildListTile(
            context: context,
            title: '设置',
            icon: Icons.settings,
            route: '/settings',
          ),
          _buildListTile(
            context: context,
            title: '下载',
            icon: Icons.cloud_download,
            route: '/downloads',
          ),
          _buildListTile(
            context: context,
            title: '歌单',
            icon: Icons.playlist_play,
            route: '/playlists',
          ),
          _buildListTile(
            context: context,
            title: '发现',
            icon: Icons.explore,
            route: '/explore',
          ),
          _buildListTile(
            context: context,
            title: '播放历史',
            icon: Icons.history,
            route: '/history',
          ),
        ],
      ),
    );
  }

  /// 构建列表项
  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? route,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 25, top: 5),
      child: ListTile(
        title: Text(title),
        leading: Icon(icon, color: Theme.of(context).iconTheme.color),
        onTap: onTap ?? () => context.go(route!),
        hoverColor: colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
