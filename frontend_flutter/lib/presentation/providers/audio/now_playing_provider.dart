import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/models/audio_model.dart';
import 'package:flutter/foundation.dart';

/// 播放队列状态管理
///
/// 负责：
/// 1. 播放队列管理（添加/移除/清空）
/// 2. 当前播放音频
class NowPlayingProvider extends ChangeNotifier {
  final DioProvider _dioProvider;

  // ==================== 状态变量 ====================

  /// 当前播放队列
  final List<Audio> _nowPlayingQueue = [];

  /// 当前播放索引
  int _currentIndex = -1;

  /// 加载状态
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  // ==================== Getters ====================

  List<Audio> get nowPlayingQueue => _nowPlayingQueue;
  int get currentIndex => _currentIndex;
  Audio? get currentAudio => _currentIndex >= 0 && _currentIndex < _nowPlayingQueue.length
      ? _nowPlayingQueue[_currentIndex]
      : null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasQueue => _nowPlayingQueue.isNotEmpty;

  /// ==================== 方法 ====================

  NowPlayingProvider({DioProvider? dioProvider})
      : _dioProvider = dioProvider ?? DioProvider.instance;

  // ==================== 初始化 ====================

  void _initListeners() {
    // 状态监听器（如果需要）
    // _dioProvider.onPlayerComplete...
  }

  /// ==================== 播放队列管理 ====================

  /// 设置播放队列
  void setQueue(List<Audio> queue, {int initialIndex = -1}) {
    _nowPlayingQueue.clear();
    _nowPlayingQueue.addAll(queue);
    _currentIndex = initialIndex;
    notifyListeners();
    debugPrint('【NowPlayingProvider】设置播放队列，长度: ${queue.length}');
  }

  /// 添加到队列
  void addToQueue(Audio audio) {
    _nowPlayingQueue.add(audio);
    notifyListeners();
    debugPrint('【NowPlayingProvider】添加音频: ${audio.title}');
  }

  /// 从队列移除
  void removeFromQueue(Audio audio) {
    final index = _nowPlayingQueue.indexOf(audio);
    if (index != -1) {
      _nowPlayingQueue.removeAt(index);
      if (index <= _currentIndex) {
        _currentIndex = _currentIndex > 0 ? _currentIndex - 1 : 0;
      }
      notifyListeners();
      debugPrint('【NowPlayingProvider】移除音频: ${audio.title}');
    }
  }

  /// 清空队列
  void clearQueue() {
    _nowPlayingQueue.clear();
    _currentIndex = -1;
    notifyListeners();
    debugPrint('【NowPlayingProvider】清空播放队列');
  }

  /// 下一曲
  void next() {
    if (_currentIndex < _nowPlayingQueue.length - 1) {
      _currentIndex++;
      notifyListeners();
      debugPrint('【NowPlayingProvider】下一曲: ${_nowPlayingQueue[_currentIndex].title}');
    }
  }

  /// 上一曲
  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
      debugPrint('【NowPlayingProvider】上一曲: ${_nowPlayingQueue[_currentIndex].title}');
    }
  }

  /// 跳转到指定索引
  void seekToIndex(int index) {
    if (index >= 0 && index < _nowPlayingQueue.length) {
      _currentIndex = index;
      notifyListeners();
      debugPrint('【NowPlayingProvider】跳转到: ${_nowPlayingQueue[index].title}');
    }
  }

  /// 设置当前音频
  void setCurrentAudio(Audio audio) {
    final index = _nowPlayingQueue.indexOf(audio);
    if (index != -1) {
      _currentIndex = index;
      notifyListeners();
      debugPrint('【NowPlayingProvider】设置当前音频: ${audio.title}');
    }
  }

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    super.dispose();
  }
}