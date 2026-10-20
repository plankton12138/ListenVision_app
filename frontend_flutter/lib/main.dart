import 'dart:io';

// ========== Core Imports ==========
import 'package:listenvision/core/storage/shared_storage_service.dart';
import 'package:listenvision/core/utils/app_logger.dart';

// ========== Framework Imports ==========
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:media_kit/media_kit.dart';
import 'app.dart';

/// 应用入口
///
/// 初始化顺序：
/// 1. WidgetsFlutterBinding
/// 2. MediaKit 初始化（音频播放库底层引擎）
/// 3. 日志系统
/// 4. 桌面数据库工厂
/// 5. 共享存储服务初始化
/// 6. runApp (ProviderScope 包裹)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Main', '未捕获的错误', error: error, stackTrace: stack);
    return true;
  };

  // ========== 1. 日志系统（最先初始化）==========
  await AppLogger.instance.initialize();

  // ========== 3. 桌面平台数据库工厂 ==========
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    databaseFactory = databaseFactoryFfi;
  }

  // ========== 4. 初始化共享存储服务 ==========
  await SharedStorageService.init();

  // ========== 5. 启动应用 ==========
  runApp(const ProviderScope(child: App()));
}
