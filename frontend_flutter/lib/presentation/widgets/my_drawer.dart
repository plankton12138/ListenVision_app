import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listenvision/presentation/providers.dart';

/// 应用侧边栏抽屉
///
/// 显示用户信息、主菜单导航和登录/登出按钮
class MyDrawer extends ConsumerWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildDrawerHeader(context, user, isLoggedIn),
          _buildMainMenu(context, isLoggedIn),
          _buildAuthSection(context, ref, isLoggedIn),
        ],
      ),
    );
  }

  /// 构建抽屉头部（用户信息）
  Widget _buildDrawerHeader(BuildContext context, user, bool isLoggedIn) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return isLoggedIn
        ? UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            accountName: Text(
              user?.username ?? '未登录用户',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          )
        : DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.person_outline,
                  size: 40,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
  }

  /// 构建主菜单
  ///
  /// 游客模式支持：
  /// - 游客可以访问：首页、搜索、设置、下载任务
  /// - 游客不能访问：歌单、发现、播放历史
  Widget _buildMainMenu(BuildContext context, bool isLoggedIn) {
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
          // 设置对所有用户可见
          _buildListTile(
            context: context,
            title: '设置',
            icon: Icons.settings,
            route: '/settings',
          ),
          // 下载任务管理（游客可用）
          _buildListTile(
            context: context,
            title: '下载任务',
            icon: Icons.cloud_download,
            route: '/downloads',
          ),
          // 歌单（所有用户可见，未登录用户只能看到本地音乐）
          _buildListTile(
            context: context,
            title: '歌单',
            icon: Icons.playlist_play,
            route: '/playlists',
          ),
          // 需要登录的页面
          if (isLoggedIn) ...[
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
        ],
      ),
    );
  }

  /// 构建认证区域（登录/登出）
  Widget _buildAuthSection(BuildContext context, WidgetRef ref, bool isLoggedIn) {
    return Column(
      children: [
        const Divider(height: 1),
        if (isLoggedIn)
          _buildListTile(
            context: context,
            title: '退出登录',
            icon: Icons.exit_to_app,
            onTap: () {
              ref.read(authViewModelProvider.notifier).logout();
              Navigator.pop(context);
              context.go('/');
            },
          )
        else
          _buildListTile(
            context: context,
            title: '登录',
            icon: Icons.login,
            onTap: () {
              Navigator.pop(context);
              context.go('/login');
            },
          ),
      ],
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
        hoverColor: colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
