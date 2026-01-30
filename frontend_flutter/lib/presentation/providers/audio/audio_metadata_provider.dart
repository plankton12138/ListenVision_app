import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_loader.dart';
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

  /// 当前可播放音频
  PlayableAudio? _currentPlayable;

  /// 元数据加载器
  final AudioMetadataLoader _metadataLoader = AudioMetadataLoader();

  // ==================== 方法 ====================

  /// 同步元数据（来自 AudioProvider）
  void updateMetadata({
    required String title,
    required String artist,
    required Uint8List? albumArt,
    required PlayableAudio? playable,
  }) {
    final isSameTitle = _title == title;
    final isSameArtist = _artist == artist;
    final isSameArt = _currentAlbumArt == albumArt;
    final isSamePlayable = _currentPlayable?.id == playable?.id;

    if (isSameTitle && isSameArtist && isSameArt && isSamePlayable) {
      return;
    }

    _title = title;
    _artist = artist;
    _currentAlbumArt = albumArt;
    _currentPlayable = playable;
    notifyListeners();

    if (_currentAlbumArt == null && playable?.coverUrl != null) {
      _loadOnlineCover(playable!.coverUrl!);
    }
  }

  /// 加载在线封面
  Future<Uint8List?> loadOnlineCover(String coverUrl) async {
    if (coverUrl.isEmpty) return null;
    return _metadataLoader.loadOnlineCover(coverUrl);
  }

  Future<void> _loadOnlineCover(String coverUrl) async {
    try {
      if (!coverUrl.startsWith('http')) {
        AppLogger.warn('AudioMetadataProvider', '封面URL非法，跳过加载: $coverUrl');
        return;
      }
      final coverData = await loadOnlineCover(coverUrl);
      if (coverData != null) {
        _currentAlbumArt = coverData;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('AudioMetadataProvider', '封面加载失败: $e');
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
  PlayableAudio? get currentPlayable => _currentPlayable;

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    _currentAlbumArt = null;
    super.dispose();
  }
}
