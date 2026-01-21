import 'package:flutter/foundation.dart';
import 'package:demo/models/audio_model.dart';

/// 音频播放列表状态管理
///
/// 职责：
/// 1. 播放列表管理（添加/移除/清空）
/// 2. 当前音频获取
class AudioPlaylistProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================

  /// 播放列表
  List<Audio> _playlist = [];

  /// 当前索引
  int _currentIndex = -1;

  // ==================== 播放列表管理 ====================

  AudioPlaylistProvider();

  // ==================== 播放列表管理 ====================

  /// 设置播放列表
  void setPlaylist(List<Audio> playlist, {int initialIndex = -1}) {
    _playlist = playlist;
    _currentIndex = initialIndex;
    notifyListeners();
    debugPrint('【AudioPlaylistProvider】设置播放列表，长度: ${playlist.length}');
  }

  /// 添加到播放列表
  void addToPlaylist(Audio audio) {
    _playlist.add(audio);
    notifyListeners();
    debugPrint('【AudioPlaylistProvider】添加音频: ${audio.title}');
  }

  /// 从播放列表移除
  void removeFromPlaylist(Audio audio) {
    _playlist.remove(audio);
    if (_currentIndex >= _playlist.length) {
      _currentIndex = _playlist.length - 1;
    }
    notifyListeners();
    debugPrint('【AudioPlaylistProvider】移除音频: ${audio.title}');
  }

  /// 清空播放列表
  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = -1;
    notifyListeners();
    debugPrint('【AudioPlaylistProvider】清空播放列表');
  }

  // ==================== Getters ====================

  List<Audio> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  /// 当前音频
  Audio? get currentAudio =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    super.dispose();
  }
}