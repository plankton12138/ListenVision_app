import 'dart:io';

// ========== P2 Clean Architecture Imports ==========
// Core Layer - Network & DI
import 'package:demo/core/di/service_factory.dart';
import 'package:demo/core/network/dio_provider.dart';
// Domain Layer - Repositories
import 'package:demo/domain/repositories/auth_repository.dart';
import 'package:demo/domain/repositories/playlist_repository.dart';
import 'package:demo/domain/repositories/bilibili_repository.dart';
import 'package:demo/domain/repositories/play_history_repository.dart';
import 'package:demo/domain/repositories/search_repository.dart';
// ====================================================

// ========== P3: Providers 已迁移到 presentation/providers/ ==========
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/presentation/providers/bilibili/qr_login_provider.dart';
import 'package:demo/presentation/providers/bilibili/cache_provider.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/search/search_provider.dart';
import 'package:demo/presentation/providers/theme/theme_provider.dart';
// P2: 路由已迁移到 presentation/routes/
import 'package:demo/presentation/routes/router.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/bilibiliApiService.dart';
import 'package:demo/services/download_manager.dart';
import 'package:demo/core/utils/file_picker_helper.dart';
import 'package:demo/core/utils/permission_helper.dart';
// ===============================================

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

  // ========== P2 Clean Architecture: 初始化 ServiceFactory ==========
  // 必须在 runApp 之前完成初始化，确保 Repository 和 Dio 可用
  await ServiceFactory.init();

  // 检查是否首次启动（复用上面的 prefs 实例）
  final prefs = await SharedPreferences.getInstance();
  // 从本地恢复 token 到 DioProvider（如果有）
  // 注意：token 的实际恢复由 AuthProvider._loadUser() 处理
  // 这里只是为了保险起见，在 Provider 初始化前恢复 token
  final savedToken = prefs.getString('auth_token');
  if (savedToken != null) {
    DioProvider.instance.updateToken(savedToken);
    debugPrint('【Main】Token restored from auth_token key');
  }
  // ================================================================

  // 检查是否首次启动（复用上面的 prefs 实例）
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
        // ========== P2 Clean Architecture: Repositories ==========
        // Repositories 必须在 Providers 之前注册，因为 Providers 依赖它们
        Provider<AuthRepository>(
          create: (_) => ServiceFactory.instance.authRepository,
        ),
        Provider<PlaylistRepository>(
          create: (_) => ServiceFactory.instance.playlistRepository,
        ),
        Provider<BilibiliRepository>(
          create: (_) => ServiceFactory.instance.bilibiliRepository,
        ),
        Provider<PlayHistoryRepository>(
          create: (_) => ServiceFactory.instance.playHistoryRepository,
        ),
        Provider<SearchRepository>(
          create: (_) => ServiceFactory.instance.searchRepository,
        ),
        // ==========================================================

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

        // P1.1: 新拆分的Provider（渐进式迁移）
        // QRLoginProvider - QR码登录管理
        ChangeNotifierProxyProvider<AuthProvider, QRLoginProvider>(
          create: (context) => QRLoginProvider(),
          update: (context, authProvider, provider) {
            provider?.updateToken(authProvider.user?.token);
            return provider ?? QRLoginProvider();
          },
        ),

        // BilibiliCacheProvider - 视频信息缓存管理
        ChangeNotifierProxyProvider<AuthProvider, BilibiliCacheProvider>(
          create: (context) => BilibiliCacheProvider(),
          update: (context, authProvider, provider) {
            provider?.updateToken(authProvider.user?.token);
            return provider ?? BilibiliCacheProvider();
          },
        ),
        // 下载管理器（依赖B站API服务）
        ChangeNotifierProxyProvider<AuthProvider, DownloadManager>(
          create: (_) => DownloadManager(),
          update: (context, authProvider, downloadManager) {
            if (downloadManager != null) {
              final apiService = BilibiliApiService();
              downloadManager.setBilibiliApiService(apiService);
            }
            return downloadManager!;
          },
        ),

        Provider(create: (_) => FilePickerService()),
        Provider(create: (_) => ApiService()),

        // Phase 2: 歌单和播放历史管理
        // 使用 ChangeNotifierProxyProvider，因为 DioProvider 是单例，不需要作为 Provider
        ChangeNotifierProxyProvider<AuthProvider, PlaylistProvider>(
          create: (context) => PlaylistProvider(dioProvider: DioProvider.instance),
          update: (context, authProvider, playlistProvider) {
            // 当用户登录时初始化歌单数据和收藏列表
            Future.microtask(() async {
              if (authProvider.isLoggedIn && authProvider.user?.token != null) {
                final token = authProvider.user!.token ?? '';
                if (token.isNotEmpty) {
                  try {
                    await playlistProvider?.initialize(token);
                  } catch (e) {
                    debugPrint('歌单初始化失败: $e');
                  }
                }
              }
            });
            return playlistProvider!;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, PlayHistoryProvider>(
          create: (context) => PlayHistoryProvider(),
          update: (context, authProvider, historyProvider) {
            // 当用户登录时初始化播放历史
            Future.microtask(() {
              if (authProvider.isLoggedIn) {
                historyProvider?.initialize();
              }
            });
            return historyProvider!;
          },
        ),

        // Phase 3: 搜索功能
        ChangeNotifierProxyProvider<AuthProvider, SearchProvider>(
          create: (context) => SearchProvider(),
          update: (context, authProvider, searchProvider) {
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
