import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/views/account/login_page.dart';
import 'package:demo/presentation/views/account/register_page.dart';
import 'package:demo/presentation/views/account/reset_password_page.dart';
import 'package:demo/presentation/views/discovery/explore_page.dart';
import 'package:demo/presentation/views/discovery/search_page.dart';
import 'package:demo/presentation/views/library/local_music_playlist_page.dart';
import 'package:demo/presentation/views/library/playlist_library_page.dart';
import 'package:demo/presentation/views/library/playlist_detail_page.dart';
import 'package:demo/presentation/views/library/play_history_page.dart';
import 'package:demo/presentation/views/player/home_page.dart';
import 'package:demo/presentation/views/player/play_list_page.dart';
import 'package:demo/presentation/views/system/backend_download_page.dart';
import 'package:demo/presentation/views/system/not_found_page.dart';
import 'package:demo/presentation/views/system/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 路由名称常量
///
/// 统一路由管理，避免硬编码字符串
class AppRoutes {
  AppRoutes._(); // 私有构造，防止实例化

  // 路由名称（用于 namedLocation）
  static const String homeName = 'home';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String resetPasswordName = 'reset_password';
  static const String settingsName = 'settings';
  static const String searchName = 'search';
  static const String exploreName = 'explore';
  static const String playlistName = 'playlist';
  static const String downloadsName = 'downloads';
  static const String playlistsName = 'playlists';
  static const String playlistDetailName = 'playlist_detail';
  static const String historyName = 'history';

  // 公开页面（无需登录）
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset_password';

  // 公开页面（游客模式可用）
  static const String search = '/search';
  static const String explore = '/explore';
  static const String playlist = '/playlist';
  static const String downloads = '/downloads';
  static const String playlists = '/playlists';

  // 需要登录的页面
  static const String settings = '/settings';
  static const String history = '/history';

  // 带参数的路由
  static const String playlistDetail = '/playlists/:id';
}

/// 应用路由配置
///
/// - 添加登录守卫（redirect）
/// - 添加路由参数支持
/// - 添加 404 错误处理
/// - 路由名称常量化
///
/// MVVM + Riverpod:
/// - 路由配置属于 Presentation 层
/// - 定义页面间的导航关系
/// - 页面组件位于 presentation/views/
/// - 使用 ProviderScope 包裹应用
final GoRouter routerConfig = GoRouter(
  // 错误页面（404）
  errorBuilder: (context, state) => const NotFoundPage(),

  // 全局重定向（登录守卫）
  //
  // 游客模式支持：
  // - 游客可以访问：搜索、下载、本地播放列表
  // - 游客不能访问：探索页面、设置、播放历史
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final isLoggedIn = container.read(isLoggedInProvider);
    final loginLocation = state.namedLocation(AppRoutes.loginName);

    // 需要登录的路由列表（游客模式不可访问）
    final protectedRoutes = [
      AppRoutes.explore,      // 探索页面需要登录
      AppRoutes.settings,
      AppRoutes.history,
    ];

    final currentPath = state.uri.path;

    // 如果访问登录页且已登录，重定向到首页
    if (currentPath == AppRoutes.login && isLoggedIn) {
      return state.namedLocation(AppRoutes.homeName);
    }

    // 如果访问受保护页面且未登录，重定向到登录页
    if (!isLoggedIn) {
      // 检查是否是受保护的路由
      for (final route in protectedRoutes) {
        if (currentPath == route || currentPath.startsWith(route)) {
          return loginLocation;
        }
      }
    }

    // 无重定向
    return null;
  },

  routes: [
    // ==================== 公开页面 ====================

    // 首页
    GoRoute(
      name: AppRoutes.homeName,
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),

    // 登录页
    GoRoute(
      name: AppRoutes.loginName,
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    // 注册页
    GoRoute(
      name: AppRoutes.registerName,
      path: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),

    // 重置密码页
    GoRoute(
      name: AppRoutes.resetPasswordName,
      path: AppRoutes.resetPassword,
      builder: (context, state) => const ResetPasswordPage(),
    ),

    // ==================== 公开页面（游客模式可用） ====================

    // 搜索页
    GoRoute(
      name: AppRoutes.searchName,
      path: AppRoutes.search,
      builder: (context, state) => const SearchPage(),
    ),

    // 发现页
    GoRoute(
      name: AppRoutes.exploreName,
      path: AppRoutes.explore,
      builder: (context, state) => const ExplorePage(),
    ),

    // 播放列表页（本地播放列表，游客可用）
    GoRoute(
      name: AppRoutes.playlistName,
      path: AppRoutes.playlist,
      builder: (context, state) => const PlaylistPage(),
    ),

    // 下载任务管理页
    GoRoute(
      name: AppRoutes.downloadsName,
      path: AppRoutes.downloads,
      builder: (context, state) => const BackendDownloadPage(),
    ),

    // 歌单库页面
    GoRoute(
      name: AppRoutes.playlistsName,
      path: AppRoutes.playlists,
      builder: (context, state) => const PlaylistLibraryPage(),
      routes: [
        // 本地音乐歌单页（嵌套路由）
        GoRoute(
          path: 'local',
          builder: (context, state) => const LocalMusicPlaylistPage(),
        ),
        // 歌单详情页（嵌套路由，带参数）
        GoRoute(
          name: AppRoutes.playlistDetailName,
          path: ':id',
          builder: (context, state) {
            final playlistId = state.pathParameters['id'] ?? '0';
            return PlaylistDetailPage(playlistId: playlistId);
          },
        ),
      ],
    ),

    // ==================== 需要登录的页面 ====================

    // 设置页
    GoRoute(
      name: AppRoutes.settingsName,
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),

    // 播放历史页面
    GoRoute(
      name: AppRoutes.historyName,
      path: AppRoutes.history,
      builder: (context, state) => const PlayHistoryPage(),
    ),
  ],
);

/// 兼容旧代码的 router 变量
@Deprecated('Use routerConfig instead. Will be removed in future.')
GoRouter get router => routerConfig;
