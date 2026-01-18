import 'package:demo/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 应用侧边栏抽屉
///
/// 显示用户信息、主菜单导航和登录/登出按钮
class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildDrawerHeader(authProvider),
          _buildMainMenu(context),
          _buildAuthSection(context, authProvider),
        ],
      ),
    );
  }

  /// 构建抽屉头部（用户信息）
  Widget _buildDrawerHeader(AuthProvider auth) {
    return auth.isLoggedIn
        ? UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
            ),
            accountName: Text(
              auth.user?.username ?? '未登录用户',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            accountEmail: Text(
              auth.user?.email ?? '',
              style: const TextStyle(color: Colors.blue),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.blue[800],
              ),
            ),
          )
        : const DrawerHeader(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person_outline,
                size: 50,
                color: Colors.white,
              ),
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
          // Phase 2: 新增页面入口
          _buildListTile(
            context: context,
            title: '发现',
            icon: Icons.explore,
            route: '/explore',
          ),
          _buildListTile(
            context: context,
            title: '歌单',
            icon: Icons.playlist_play,
            route: '/playlists',
          ),
          _buildListTile(
            context: context,
            title: '播放历史',
            icon: Icons.history,
            route: '/history',
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
            icon: Icons.download_rounded,
            route: '/download_list',
          ),
        ],
      ),
    );
  }

  /// 构建认证区域（登录/登出）
  Widget _buildAuthSection(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        const Divider(height: 1),
        if (auth.isLoggedIn)
          _buildListTile(
            context: context,
            title: '退出登录',
            icon: Icons.exit_to_app,
            onTap: () {
              auth.logout();
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
    return Padding(
      padding: const EdgeInsets.only(left: 25, top: 5),
      child: ListTile(
        title: Text(title),
        leading: Icon(icon, color: Theme.of(context).iconTheme.color),
        onTap: onTap ?? () => context.go(route!),
        hoverColor: Colors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
