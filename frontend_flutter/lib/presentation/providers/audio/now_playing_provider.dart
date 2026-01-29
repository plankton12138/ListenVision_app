import 'package:demo/domain/entities/playable_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 播放队列状态管理
///
/// 负责：
/// 1. 播放队列管理（添加/移除/清空）
/// 2. 当前播放音频
class NowPlayingProvider extends ChangeNotifier {

  // ==================== 状态变量 ====================

  /// 当前播放队列
  List<PlayableAudio> _nowPlayingQueue = [];

  /// 当前播放索引
  int _currentIndex = -1;

  /// 错误信息
  String? _errorMessage;

  // ==================== Getters ====================

  List<PlayableAudio> get nowPlayingQueue => List.unmodifiable(_nowPlayingQueue);
  int get currentIndex => _currentIndex;
  PlayableAudio? get currentPlayable =>
      _currentIndex >= 0 && _currentIndex < _nowPlayingQueue.length
      ? _nowPlayingQueue[_currentIndex]
      : null;
  String? get errorMessage => _errorMessage;
  bool get hasQueue => _nowPlayingQueue.isNotEmpty;

  /// ==================== 方法 ====================

  /// 同步播放队列（来自 AudioProvider）
  void updateQueue(List<PlayableAudio> queue, {int currentIndex = -1}) {
    final isSameLength = _nowPlayingQueue.length == queue.length;
    final isSameIndex = _currentIndex == currentIndex;
    final isSameItems = isSameLength &&
        List.generate(_nowPlayingQueue.length, (i) => _nowPlayingQueue[i].id == queue[i].id)
            .every((match) => match);

    if (isSameItems && isSameIndex) {
      return;
    }

    _nowPlayingQueue = List<PlayableAudio>.from(queue);
    _currentIndex = currentIndex;
    notifyListeners();
    AppLogger.debug('NowPlayingProvider', '同步播放队列，长度: ${queue.length}');
  }

  /// 设置错误信息
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// 清空错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    super.dispose();
  }
}
