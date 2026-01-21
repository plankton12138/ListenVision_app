import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:metadata_god/metadata_god.dart';

/// 音频元数据管理
///
/// 职责：
/// 1. 从音频文件提取元数据（使用 metadata_god）
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
      debugPrint('【AudioMetadataProvider】开始加载: $filePath');

      if (!File(filePath).existsSync()) {
        debugPrint('【AudioMetadataProvider】文件不存在: $filePath');
        throw Exception('文件不存在');
      }

      // 使用 metadata_god 读取元数据
      final metadata = await MetadataGod.readMetadata(file: filePath);

      // 更新状态
      _title = metadata.title?.trim() ?? _title;
      _artist = metadata.artist?.trim() ?? _artist;
      _currentAlbumArt = metadata.picture?.data;

      debugPrint('【AudioMetadataProvider】加载完成: $_title - $_artist');
      notifyListeners();
    } catch (e) {
      debugPrint('【AudioMetadataProvider】加载失败: $e');
      rethrow;
    }
  }

  /// 获取专辑封面
  Uint8List? get albumArt => _currentAlbumArt;

  /// 设置专辑封面
  void setAlbumArt(Uint8List? albumArt) {
    _currentAlbumArt = albumArt;
    notifyListeners();
    debugPrint('【AudioMetadataProvider】设置专辑封面');
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