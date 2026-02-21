import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/dio_client.dart';
import 'core/utils/app_logger.dart';
import 'data/sync/download_integrity_provider.dart';
import 'presentation/providers.dart';
import 'presentation/routes/router.dart';
import 'presentation/theme/light_mode.dart';
import 'presentation/theme/dark_mode.dart';
import 'presentation/viewmodels/system/theme_viewmodel.dart';
import 'presentation/widgets/common/network_status_listener.dart';

/// App 入口，由 ProviderScope 包裹
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeViewModelProvider);

    // 启动下载完整性服务（本地优先播放策略的基础）
    // Web 平台不支持本地文件系统下载目录校验，且 IndexedDB/worker 资源可能未配置，跳过避免启动报错。
    if (!kIsWeb) {
      ref.watch(downloadIntegrityServiceProvider);
    }

    // 监听 token 变化，同步到 DioClient
    ref.listen<String?>(
      authTokenProvider,
      (previous, next) {
        DioClient.instance.updateToken(next);
        AppLogger.debug('App', 'Token 同步到 DioClient: ${next != null ? "已设置" : "已清除"}');
      },
    );

    // 监听主题变化日志
    ref.listen<AppThemeMode>(themeViewModelProvider, (previous, next) {
      AppLogger.debug('App', 'Theme changed: ${previous?.name} -> ${next.name}');
    });

    return MaterialApp.router(
      title: 'ListenVision',
      debugShowCheckedModeBanner: false,
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
