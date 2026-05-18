import 'dart:io';

// ========== Core Imports ==========
import 'package:listenvision/core/network/dio_provider.dart';
import 'package:listenvision/core/storage/shared_storage_service.dart';
import 'package:listenvision/core/utils/permission_helper.dart';
import 'package:listenvision/core/utils/app_logger.dart';

// ========== Framework Imports ==========
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

/// 应用入口
///
/// 初始化顺序：
/// 1. WidgetsFlutterBinding
/// 2. 日志系统
/// 3. 首次启动权限处理
/// 4. 桌面数据库工厂
/// 5. 共享存储服务初始化
/// 6. 恢复认证 Token
/// 7. runApp (ProviderScope 包裹)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 修复：设置全局错误处理
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Main', '未捕获的错误', error: error, stackTrace: stack);
    return true; // 已处理
  };

  // ========== 1. 日志系统（最先初始化）==========
  await AppLogger.instance.initialize();

  // ========== 2. 首次启动权限处理 ==========
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  if (isFirstLaunch) {
    final hasPermission = await requestManageStoragePermission();
    if (hasPermission) {
      AppLogger.info('Main', '存储权限请求成功');
    } else {
      AppLogger.warn('Main', '用户拒绝存储权限');
    }
    await prefs.setBool('isFirstLaunch', false);
  }

  // ========== 3. 桌面平台数据库工厂 ==========
  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    databaseFactory = databaseFactoryFfi;
  }

  // ========== 3.5. 初始化共享存储服务 ==========
  await SharedStorageService.init();

  // ========== 4. 恢复认证 Token ==========
  final savedToken = prefs.getString('auth_token');
  if (savedToken != null) {
    // 设置全局 Dio token
    DioProvider.instance.updateToken(savedToken);
    AppLogger.info('Main', 'Token restored from storage');
  }

  // ========== 5. 启动应用 ==========
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
