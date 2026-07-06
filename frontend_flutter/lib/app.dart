import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/utils/app_logger.dart';
import 'presentation/providers.dart';
import 'presentation/routes/router.dart';
import 'presentation/theme/light_mode.dart';
import 'presentation/theme/dark_mode.dart';
import 'presentation/viewmodels/system/theme_viewmodel.dart';
import 'presentation/widgets/common/network_status_listener.dart';
import 'presentation/widgets/player/floating_player_bar.dart';
import 'services/download_integrity_service.dart';
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

    // 监听主题变化日志
    ref.listen<AppThemeMode>(themeViewModelProvider, (previous, next) {
      AppLogger.debug('App', 'Theme changed: ${previous?.name} -> ${next.name}');
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
        return Stack(
          children: [
            // GoRouter 页面内容
            NetworkStatusListener(child: child ?? const SizedBox()),
            // 浮动播放条（覆盖在底部）
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingPlayerBar(),
            ),
          ],
        );
      },
    );
  }
}
