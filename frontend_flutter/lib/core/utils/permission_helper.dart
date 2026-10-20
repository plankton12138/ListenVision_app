import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限请求工具类
///
/// 从 utils/request_permission.dart 迁移到 core/utils/
class PermissionHelper {
  /// 请求存储管理权限
  ///
  /// Android 11+ 需要 MANAGE_EXTERNAL_STORAGE 权限才能访问所有文件
  /// Web 平台不需要权限请求
  static Future<bool> requestManageStoragePermission() async {
    // Web 平台不需要权限请求
    if (kIsWeb) {
      return true;
    }

    // Android 和 iOS 需分开处理
    if (Platform.isAndroid) {
      final modern =
          await const MethodChannel(
            'listenvision/background_audio',
          ).invokeMethod<bool>('modernStorage') ??
          true;
      final permission = modern
          ? Permission.manageExternalStorage
          : Permission.storage;
      final status = await permission.status;
      if (status.isGranted) {
        return true;
      } else {
        // 请求权限（会跳转到系统设置页面）
        final result = await permission.request();
        return result.isGranted;
      }
    }
    return true;
  }
}

/// 向后兼容的函数导出
/// @Deprecated('请使用 PermissionHelper.requestManageStoragePermission()')
Future<bool> requestManageStoragePermission() =>
    PermissionHelper.requestManageStoragePermission();
