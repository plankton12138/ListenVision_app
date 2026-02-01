/// Provider 依赖注入配置
///
/// 封装所有 Provider 的创建和依赖关系配置
/// 简化 main.dart，提高可维护性
///
/// 使用方式：
/// ```dart
/// MultiProvider(
///   providers: ProviderConfig.getProviders(),
///   child: MyApp(),
/// )
/// ```
library;

import 'package:demo/core/di/service_factory.dart';
import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/core/utils/file_picker_helper.dart';
import 'package:demo/domain/repositories/auth_repository.dart';
import 'package:demo/domain/repositories/bilibili_repository.dart';
import 'package:demo/domain/repositories/play_history_repository.dart';
import 'package:demo/domain/repositories/playlist_repository.dart';
import 'package:demo/domain/repositories/search_repository.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/audio/now_playing_provider.dart';
import 'package:demo/presentation/providers/audio/audio_playlist_provider.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/presentation/providers/bilibili/cache_provider.dart';
import 'package:demo/presentation/providers/bilibili/qr_login_provider.dart';
import 'package:demo/presentation/providers/download/download_manager.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/search/search_provider.dart';
import 'package:demo/presentation/providers/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Provider 配置类
///
/// 职责：
/// 1. 集中管理所有 Provider 的创建
/// 2. 定义 Provider 之间的依赖关系
/// 3. 隐藏初始化细节
class ProviderConfig {
  ProviderConfig._(); // 私有构造，防止实例化

  /// 获取所有 Provider 配置
  ///
  /// 返回顺序很重要：
  /// 1. Repositories (无依赖)
  /// 2. 独立 Providers (ThemeController, AudioProvider)
  /// 3. 基础 Providers (AuthProvider)
  /// 4. 依赖 AuthProvider 的 Providers
  static List<Object> getProviders() {
    return [
      // ========== Repositories (P2 Clean Architecture) ==========
      // 必须在最前面，因为其他 Providers 依赖它们
      ..._repositories(),

      // ========== 独立 Providers ==========
      ..._independentProviders(),

      // ========== Audio Providers (P1: 无依赖，直接使用 HTTP 记录历史) ==========
      _audioProvider(),
      ChangeNotifierProvider<NowPlayingProvider>(create: (_) => NowPlayingProvider()),
      ChangeNotifierProvider<AudioPlaylistProvider>(create: (_) => AudioPlaylistProvider()),
      _audioProvidersLink(),

      // ========== Bilibili-Dependent Providers ==========
      _bilibiliProvider(),
      _qrLoginProvider(),
      _cacheProvider(),

      // ========== Other Providers ==========
      _downloadManager(),
      _filePickerService(),

      // ========== Auth & Search Providers ==========
      _playHistoryProvider(),
      _playlistProvider(),
      _searchProvider(),
    ];
  }

  // ========== Repositories ==========
  static List<Object> _repositories() {
    return [
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
    ];
  }

  // ========== 独立 Providers ==========
  static List<Object> _independentProviders() {
    return [
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ];
  }

  // ========== PlayHistory Provider ==========
  static Object _playHistoryProvider() {
    return ChangeNotifierProxyProvider<AuthProvider, PlayHistoryProvider>(
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
    );
  }

  // ========== Audio Provider (P1: 无依赖) ==========
  static Object _audioProvider() {
    // P1 优化：AudioProvider 不再依赖 PlayHistoryProvider
    // 依赖链深度：4 层 → 2 层
    return ChangeNotifierProvider<AudioProvider>(
      create: (_) => AudioProvider(),
    );
  }

  static Object _audioProvidersLink() {
    return ChangeNotifierProxyProvider3<AudioProvider, NowPlayingProvider, AudioPlaylistProvider, AudioMetadataProvider>(
      create: (context) => AudioMetadataProvider(),
      update: (context, audioProvider, nowPlayingProvider, playlistProvider, metadataProvider) {
        audioProvider.attachProviders(
          nowPlayingProvider: nowPlayingProvider,
          audioPlaylistProvider: playlistProvider,
          audioMetadataProvider: metadataProvider,
        );
        return metadataProvider!;
      },
    );
  }

  // ========== Bilibili Provider ==========
  static Object _bilibiliProvider() {
    return ChangeNotifierProvider<BilibiliProvider>(
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

        // 处理已登录用户初始化
        Future.delayed(Duration.zero, () {
          if (authProvider.isLoggedIn) {
            provider.updateToken(authProvider.user?.token);
            provider.initialize();
          }
        });

        return provider;
      },
    );
  }

  // ========== QR Login Provider ==========
  static Object _qrLoginProvider() {
    return ChangeNotifierProxyProvider<AuthProvider, QRLoginProvider>(
      create: (context) => QRLoginProvider(),
      update: (context, authProvider, provider) {
        provider?.updateToken(authProvider.user?.token);
        return provider ?? QRLoginProvider();
      },
    );
  }

  // ========== Bilibili Cache Provider ==========
  static Object _cacheProvider() {
    return ChangeNotifierProxyProvider<AuthProvider, BilibiliCacheProvider>(
      create: (context) => BilibiliCacheProvider(),
      update: (context, authProvider, provider) {
        provider?.updateToken(authProvider.user?.token);
        return provider ?? BilibiliCacheProvider();
      },
    );
  }

  // ========== Download Manager ==========
  static Object _downloadManager() {
    return ChangeNotifierProxyProvider<AuthProvider, DownloadManager>(
      create: (_) => DownloadManager(),
      update: (context, authProvider, downloadManager) {
        return downloadManager!;
      },
    );
  }

  // ========== File Picker Service ==========
  static Object _filePickerService() {
    return Provider(create: (_) => FilePickerService());
  }

  // ========== Playlist Provider ==========
  static Object _playlistProvider() {
    return ChangeNotifierProxyProvider<AuthProvider, PlaylistProvider>(
      create: (context) => PlaylistProvider(dioProvider: DioProvider.instance),
      update: (context, authProvider, playlistProvider) {
        Future.microtask(() async {
          if (authProvider.isLoggedIn && authProvider.user?.token != null) {
            final token = authProvider.user!.token ?? '';
            if (token.isNotEmpty) {
              try {
                await playlistProvider?.initialize(token);
              } catch (e) {
                AppLogger.debug('ProviderConfig', '歌单初始化失败（静默）: $e');
              }
            }
          }
        });
        return playlistProvider!;
      },
    );
  }

  // ========== Search Provider ==========
  static Object _searchProvider() {
    return ChangeNotifierProxyProvider<AuthProvider, SearchProvider>(
      create: (context) => SearchProvider(),
      update: (context, authProvider, searchProvider) {
        searchProvider?.updateToken(authProvider.user?.token);
        Future.microtask(() {
          searchProvider?.initialize();
        });
        return searchProvider!;
      },
    );
  }
}
