import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 请求存储管理权限
///
/// Android 11+ 需要 MANAGE_EXTERNAL_STORAGE 权限才能访问所有文件
/// Web 平台不需要权限请求
Future<bool> requestManageStoragePermission() async {
  // Web 平台不需要权限请求
  if (kIsWeb) {
    return true;
  }

  // Android 和 iOS 需分开处理
  if (Platform.isAndroid) {
    // Android 11+ 需要 MANAGE_EXTERNAL_STORAGE
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) {
      return true;
    } else {
      // 请求权限（会跳转到系统设置页面）
      final result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    }
  }
  return true;
}
