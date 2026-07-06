import 'package:listenvision/presentation/views/discovery/explore_page.dart';
import 'package:listenvision/presentation/views/discovery/search_page.dart';
import 'package:listenvision/presentation/views/library/local_music_playlist_page.dart';
import 'package:listenvision/presentation/views/library/playlist_library_page.dart';
import 'package:listenvision/presentation/views/library/playlist_detail_page.dart';
import 'package:listenvision/presentation/views/library/play_history_page.dart';
import 'package:listenvision/presentation/views/player/home_page.dart';
import 'package:listenvision/presentation/views/player/play_list_page.dart';
import 'package:listenvision/presentation/views/system/backend_download_page.dart';
import 'package:listenvision/presentation/views/system/not_found_page.dart';
import 'package:listenvision/presentation/views/system/settings_page.dart';
import 'package:listenvision/presentation/widgets/player/floating_player_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// 路由名称常量
class AppRoutes {
  AppRoutes._();

  static const String homeName = 'home';
  static const String settingsName = 'settings';
  static const String searchName = 'search';
  static const String exploreName = 'explore';
  static const String playlistName = 'playlist';
  static const String downloadsName = 'downloads';
  static const String playlistsName = 'playlists';
  static const String playlistDetailName = 'playlist_detail';
  static const String historyName = 'history';

  static const String home = '/';
  static const String search = '/search';
  static const String explore = '/explore';
  static const String playlist = '/playlist';
  static const String downloads = '/downloads';
  static const String playlists = '/playlists';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String playlistDetail = '/playlists/:id';
}

/// 应用路由配置
///
/// 纯前端架构：无需登录，所有页面公开访问。
/// B站绑定为可选功能，不影响应用使用。
final GoRouter routerConfig = GoRouter(
  errorBuilder: (context, state) => const NotFoundPage(),

  routes: [
    // HomePage — 独立路由，显示完整播放器，不显示浮动条
    GoRoute(
      name: AppRoutes.homeName,
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),

    // ShellRoute — 其他页面统一包裹浮动播放条
    ShellRoute(
      builder: (context, state, child) {
        return Stack(
          children: [
            child,
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingPlayerBar(),
            ),
          ],
        );
      },
      routes: [
        GoRoute(
          name: AppRoutes.searchName,
          path: AppRoutes.search,
          builder: (context, state) => const SearchPage(),
        ),

        GoRoute(
          name: AppRoutes.exploreName,
          path: AppRoutes.explore,
          builder: (context, state) => const ExplorePage(),
        ),

        GoRoute(
          name: AppRoutes.playlistName,
          path: AppRoutes.playlist,
          builder: (context, state) => const PlaylistPage(),
        ),

        GoRoute(
          name: AppRoutes.downloadsName,
          path: AppRoutes.downloads,
          builder: (context, state) => const BackendDownloadPage(),
        ),

        GoRoute(
          name: AppRoutes.playlistsName,
          path: AppRoutes.playlists,
          builder: (context, state) => const PlaylistLibraryPage(),
          routes: [
            GoRoute(
              path: 'local',
              builder: (context, state) => const LocalMusicPlaylistPage(),
            ),
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

        GoRoute(
          name: AppRoutes.settingsName,
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsPage(),
        ),

        GoRoute(
          name: AppRoutes.historyName,
          path: AppRoutes.history,
          builder: (context, state) => const PlayHistoryPage(),
        ),
      ],
    ),
  ],
);

@Deprecated('Use routerConfig instead. Will be removed in future.')
GoRouter get router => routerConfig;
