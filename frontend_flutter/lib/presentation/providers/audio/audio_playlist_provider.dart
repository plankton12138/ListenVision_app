import 'package:flutter/foundation.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 音频播放列表状态管理
///
/// 职责：
/// 1. 播放列表管理（添加/移除/清空）
/// 2. 当前音频获取
class AudioPlaylistProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================

  /// 播放列表
  List<PlayableAudio> _playlist = [];

  /// 当前索引
  int _currentIndex = -1;

  // ==================== 播放列表管理 ====================

  AudioPlaylistProvider();

  // ==================== 播放列表管理 ====================

  /// 同步播放列表（来自 AudioProvider）
  void updatePlaylist(List<PlayableAudio> playlist, {int currentIndex = -1}) {
    final isSameLength = _playlist.length == playlist.length;
    final isSameIndex = _currentIndex == currentIndex;
    final isSameItems = isSameLength &&
        List.generate(_playlist.length, (i) => _playlist[i].id == playlist[i].id)
            .every((match) => match);

    if (isSameItems && isSameIndex) {
      return;
    }

    _playlist = List<PlayableAudio>.from(playlist);
    _currentIndex = currentIndex;
    notifyListeners();
    AppLogger.debug('AudioPlaylistProvider', '同步播放列表，长度: ${playlist.length}');
  }

  // ==================== Getters ====================

  List<PlayableAudio> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;

  /// 当前音频
  PlayableAudio? get currentAudio =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    super.dispose();
  }
}
