import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/permission_helper.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:demo/core/utils/audio_metadata_helper.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 音频元数据管理
///
/// 职责：
/// 1. 从音频文件提取元数据（使用 AudioMetadataHelper）
/// 2. 管理专辑封面
class AudioMetadataProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================

  /// 当前标题
  String _title = "未知标题";

  /// 当前艺术家
  String _artist = "未知艺术家";

  /// 当前专辑封面
  Uint8List? _currentAlbumArt;

  /// 当前音频
  Audio? _currentAudio;

  // ==================== 方法 ====================

  /// 从音频文件提取元数据
  Future<void> loadMetadataFromPath(String filePath) async {
    try {
      AppLogger.info('AudioMetadataProvider', '开始加载: $filePath');

      // Android 11+ 需要先请求 MANAGE_EXTERNAL_STORAGE 权限
      if (!kIsWeb && Platform.isAndroid) {
        final hasPermission = await PermissionHelper.requestManageStoragePermission();
        if (!hasPermission) {
          AppLogger.debug('AudioMetadataProvider', '存储权限被拒绝');
          throw Exception('需要存储权限才能读取音频文件');
        }
      }

      if (!File(filePath).existsSync()) {
        AppLogger.debug('AudioMetadataProvider', '文件不存在: $filePath');
        throw Exception('文件不存在');
      }

      // 使用 AudioMetadataHelper 读取元数据
      final helper = AudioMetadataHelper();
      final result = await helper.readMetadataAsync(filePath: filePath, fetchCover: true);

      // 更新状态
      _title = result.title.isNotEmpty ? result.title : _title;
      _artist = result.artist.isNotEmpty ? result.artist : _artist;
      _currentAlbumArt = result.cover;

      AppLogger.info('AudioMetadataProvider', '加载完成: $_title - $_artist');
      notifyListeners();
    } catch (e) {
      AppLogger.error('AudioMetadataProvider', '加载失败: $e');
      rethrow;
    }
  }

  /// 获取专辑封面
  Uint8List? get albumArt => _currentAlbumArt;

  /// 设置专辑封面
  void setAlbumArt(Uint8List? albumArt) {
    _currentAlbumArt = albumArt;
    notifyListeners();
    AppLogger.debug('AudioMetadataProvider', '设置专辑封面');
  }

  // ==================== Getters ====================

  String get title => _title;
  String get artist => _artist;
  Audio? get currentAudio => _currentAudio;

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    _currentAlbumArt = null;
    super.dispose();
  }
}