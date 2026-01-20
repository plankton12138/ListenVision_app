import 'dart:io';

import 'package:demo/providers/audio_provider.dart';
import 'package:demo/providers/auth_provider.dart';
import 'package:demo/providers/bilibili_provider.dart';
import 'package:demo/providers/play_history_provider.dart';
import 'package:demo/providers/playlist_provider.dart';
import 'package:demo/providers/search_provider.dart';
import 'package:demo/providers/theme_provider.dart';
import 'package:demo/routes/router.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/bilibiliApiService.dart';
import 'package:demo/services/download_manager.dart';
import 'package:demo/services/file_picker.dart';
import 'package:demo/utils/request_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 metadata_god（用于读取/写入音频元数据）
  MetadataGod.initialize();

  // 检查是否首次启动
  final prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  if (isFirstLaunch) {
    // 首次启动，请求存储权限
    bool hasPermission = await requestManageStoragePermission();
    if (hasPermission) {
      debugPrint('权限请求成功');
    } else {
      debugPrint('用户拒绝权限');
      openAppSettings();
    }
    await prefs.setBool('isFirstLaunch', false);
  }

  // 桌面平台初始化数据库工厂
  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        // Phase 2A: AudioProvider 创建后延迟恢复播放状态
        ChangeNotifierProvider<AudioProvider>(
          create: (_) {
            final provider = AudioProvider();
            // 延迟恢复播放状态，确保播放列表已加载
            Future.delayed(const Duration(milliseconds: 500), () {
              provider.restorePlaybackState();
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // B站状态管理
        ChangeNotifierProvider<BilibiliProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final provider = BilibiliProvider();
            provider.updateToken(authProvider.user?.token);

            // 监听登录状态变化
            VoidCallback? listener;
            listener = () {
              provider.updateToken(authProvider.user?.token);
              if (authProvider.isLoggedIn) {
                provider.initialize();
              } else {
                provider.cancelQRLogin();
              }
            };
            authProvider.addListener(listener);

            // 处理已登录用户初始化：AuthProvider._loadUser() 是异步的，
            // 需要等待其完成后再初始化 BilibiliProvider
            Future.delayed(Duration.zero, () {
              if (authProvider.isLoggedIn) {
                provider.updateToken(authProvider.user?.token);
                provider.initialize();
              }
            });

            return provider;
          },
        ),
        // 下载管理器（依赖B站API服务）
        ChangeNotifierProxyProvider<AuthProvider, DownloadManager>(
          create: (_) => DownloadManager(),
          update: (context, authProvider, downloadManager) {
            if (downloadManager != null) {
              final apiService =
                  BilibiliApiService(token: authProvider.user?.token);
              downloadManager.setBilibiliApiService(apiService);
            }
            return downloadManager!;
          },
        ),

        Provider(create: (_) => FilePickerService()),
        Provider(create: (_) => ApiService()),

        // Phase 2: 歌单和播放历史管理
        ChangeNotifierProxyProvider2<AuthProvider, ApiService, PlaylistProvider>(
          create: (context) => PlaylistProvider(context.read<ApiService>()),
          update: (context, authProvider, apiService, playlistProvider) {
            // 当用户登录时初始化歌单数据和收藏列表
            Future.microtask(() async {
              if (authProvider.isLoggedIn && authProvider.user?.token != null) {
                final token = authProvider.user!.token;
                try {
                  await playlistProvider?.initialize(token);
                  await playlistProvider?.loadFavorites(token);
                } catch (e) {
                  debugPrint('歌单初始化失败: $e');
                }
              }
            });
            return playlistProvider!;
          },
        ),

        ChangeNotifierProxyProvider2<AuthProvider, ApiService, PlayHistoryProvider>(
          create: (context) => PlayHistoryProvider(context.read<ApiService>()),
          update: (context, authProvider, apiService, historyProvider) {
            // 当用户登录时加载播放历史
            Future.microtask(() {
              if (authProvider.isLoggedIn && authProvider.user?.token != null) {
                historyProvider?.loadHistory(authProvider.user!.token);
              }
            });
            return historyProvider!;
          },
        ),

        // Phase 3: 搜索功能
        ChangeNotifierProxyProvider2<AuthProvider, ApiService, SearchProvider>(
          create: (context) => SearchProvider(context.read<ApiService>()),
          update: (context, authProvider, apiService, searchProvider) {
            // 当 Token 变化时更新
            searchProvider?.updateToken(authProvider.user?.token);
            // 初始化热门关键词和搜索历史
            Future.microtask(() {
              searchProvider?.initialize();
            });
            return searchProvider!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: Provider.of<ThemeController>(context).themeData,
    );
  }
}
