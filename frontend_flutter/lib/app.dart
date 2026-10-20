import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/utils/app_logger.dart';
import 'presentation/routes/router.dart';
import 'presentation/theme/light_mode.dart';
import 'presentation/theme/dark_mode.dart';
import 'presentation/viewmodels/system/theme_viewmodel.dart';
import 'presentation/widgets/common/network_status_listener.dart';
import 'services/download_integrity_service.dart';
import 'services/background_audio_service.dart';
import 'presentation/viewmodels/player/playback_viewmodel.dart';
import 'data/database/app_database.dart';
import 'data/database/track_dao.dart';

/// App 入口，由 ProviderScope 包裹
class App extends ConsumerStatefulWidget {
  const App({super.key});

  /// 全局 ScaffoldMessenger Key，供 ViewModel 等无 Context 的层显示 SnackBar
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  DownloadIntegrityService? _downloadIntegrityService;

  @override
  void initState() {
    super.initState();
    // 启动下载完整性服务（本地优先播放策略的基础）
    // Web 平台不支持本地文件系统下载目录校验，跳过避免启动报错。
    if (!kIsWeb) {
      _downloadIntegrityService = DownloadIntegrityService(
        TrackDao(AppDatabase.instance),
      );
      _downloadIntegrityService!.start();
      AppLogger.info('App', 'DownloadIntegrityService 已启动');
    }
  }

  @override
  void dispose() {
    _downloadIntegrityService?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeViewModelProvider);
    final background = ref.watch(backgroundAudioServiceProvider);
    // 只同步整秒进度，系统通知更新不触发 App 或播放器 UI 重建。
    ref.listen(
      playbackViewModelProvider.select(
        (s) => (
          id: s.currentPlayable?.id,
          title: s.title,
          artist: s.artist,
          album: s.albumTitle,
          playing: s.isPlaying,
          loading: s.isLoading,
          position: s.position.inSeconds,
          duration: s.duration?.inMilliseconds ?? 0,
          speed: s.speed,
          error: s.errorMessage,
        ),
      ),
      (_, state) {
        background.update({
          'hasContent': state.id != null,
          'title': state.title,
          'artist': state.artist,
          'album': state.album,
          'playing': state.playing,
          'loading': state.loading,
          'position': state.position * 1000,
          'duration': state.duration,
          'speed': state.speed,
        });
      },
    );

    // 监听主题变化日志
    ref.listen<AppThemeMode>(themeViewModelProvider, (previous, next) {
      AppLogger.debug(
        'App',
        'Theme changed: ${previous?.name} -> ${next.name}',
      );
    });

    return MaterialApp.router(
      title: 'ListenVision',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: App.scaffoldMessengerKey,
      themeMode: themeMode.flutterThemeMode,
      theme: lightMode,
      darkTheme: darkMode,
      routerConfig: routerConfig,
      builder: (context, child) {
        return NetworkStatusListener(child: child ?? const SizedBox());
      },
    );
  }
}
