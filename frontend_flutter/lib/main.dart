import 'dart:io';

// ========== Core Imports ==========
import 'package:demo/core/di/provider_config.dart';
import 'package:demo/core/di/service_factory.dart';
import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/core/utils/permission_helper.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/presentation/providers/theme/theme_provider.dart';
import 'package:demo/presentation/routes/router.dart';

// ========== Framework Imports ==========
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 应用入口
///
/// 初始化顺序：
/// 1. WidgetsFlutterBinding
/// 2. 日志系统
/// 3. ServiceFactory (Repositories + Dio)
/// 4. 恢复 Token
/// 5. 权限处理
/// 6. 桌面数据库工厂
/// 7. runApp (Provider 配置在 ProviderConfig 中)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ========== 1. 日志系统（最先初始化）==========
  await AppLogger.instance.initialize();

  // ========== 2. ServiceFactory 初始化 ==========
  // 必须在 runApp 之前完成，确保 Repositories 和 Dio 可用
  await ServiceFactory.init();

  // ========== 3. 恢复认证 Token ==========
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('auth_token');
  if (savedToken != null) {
    DioProvider.instance.updateToken(savedToken);
    AppLogger.info('Main', 'Token restored from storage');
  }

  // ========== 4. 首次启动权限处理 ==========
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  if (isFirstLaunch) {
    final hasPermission = await requestManageStoragePermission();
    if (hasPermission) {
      AppLogger.info('Main', '存储权限请求成功');
    } else {
      AppLogger.warn('Main', '用户拒绝存储权限');
      // openAppSettings(); // 已在 permission_helper 中处理
    }
    await prefs.setBool('isFirstLaunch', false);
  }

  // ========== 5. 桌面平台数据库工厂 ==========
  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    databaseFactory = databaseFactoryFfi;
  }

  // ========== 6. 启动应用 ==========
  runApp(
    MultiProvider(
      providers: ProviderConfig.getProviders().cast<SingleChildWidget>(),
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
