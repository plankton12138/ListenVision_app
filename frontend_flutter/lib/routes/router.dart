import 'package:demo/ui/pages/download_list_page.dart';
import 'package:demo/ui/pages/explore_page.dart';
import 'package:demo/ui/pages/home_page.dart';
import 'package:demo/ui/pages/login_page.dart';
import 'package:demo/ui/pages/play_list_page.dart';
import 'package:demo/ui/pages/register_page.dart';
import 'package:demo/ui/pages/reset_password_page.dart';
import 'package:demo/ui/pages/search_page.dart';
import 'package:demo/ui/pages/settings_page.dart';
import 'package:go_router/go_router.dart';

/// 应用路由配置
///
/// 使用 go_router 定义所有页面的路由
final GoRouter router = GoRouter(
  routes: [
    // 首页
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),

    // 设置页
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    // 搜索页
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),

    // 发现页
    GoRoute(
      path: '/explore',
      builder: (context, state) => const ExplorePage(),
    ),

    // 播放列表页
    GoRoute(
      path: '/playlist',
      builder: (context, state) => const PlaylistPage(),
    ),

    // 下载列表页
    GoRoute(
      path: '/download_list',
      builder: (context, state) => const DownloadListPage(),
    ),

    // 登录页
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // 注册页
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // 重置密码页
    GoRoute(
      path: '/reset_password',
      builder: (context, state) => const ResetPasswordPage(),
    ),
  ],
);
