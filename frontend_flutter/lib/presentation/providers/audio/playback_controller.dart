import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/core/utils/error_handler.dart';
import 'package:demo/presentation/providers/audio/playback_queue.dart';

/// 播放控制器
///
/// 职责：
/// 1. 核心播放控制（play/pause/stop/seek）
/// 2. 音频源管理
/// 3. 播放状态检测
///
/// Phase 优化: 集成 PlaybackQueue 解决快速点击导致的播放混乱
class PlaybackController {
  final AudioPlayer _player;

  // 播放队列
  final PlaybackQueue _queue = PlaybackQueue();

  // 播放状态
  bool _isPlaying = false;
  bool _disposed = false;

  // 播放启动保护（防止 stream 事件覆盖正在启动的播放状态）
  bool _isStartingPlayback = false;
  DateTime? _playbackStartTime;

  // 状态订阅
  StreamSubscription? _playerStateSub;

  // 状态变化回调
  Function(bool)? _onPlayingChanged;
  Function(ProcessingState)? _onProcessingStateChanged;

  PlaybackController({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _initListeners();
    _setupQueueCallbacks();
  }

  /// 获取底层播放器（供高级操作使用）
  AudioPlayer get player => _player;

  /// 是否正在播放
  bool get isPlaying => _isPlaying;

  /// 是否已销毁
  bool get disposed => _disposed;

  /// 播放队列状态
  PlaybackQueueState get queueState => _queue.state;
  bool get hasPendingCommands => _queue.hasPending;

  /// 取消待处理的播放命令
  void cancelPendingCommands() {
    _queue.cancelPending();
  }

  /// 当前处理状态
  ProcessingState get processingState => _player.processingState;

  /// 当前播放位置
  Duration get position => _player.position;

  /// 当前音频时长
  Duration? get duration => _player.duration;

  /// 是否正在加载
  bool get isLoading => _player.processingState == ProcessingState.loading;

  /// 是否正在缓冲
  bool get isBuffering => _player.processingState == ProcessingState.buffering;

  /// 是否已就绪
  bool get isReady => _player.processingState == ProcessingState.ready;

  /// 是否空闲
  bool get isIdle => _player.processingState == ProcessingState.idle;

  /// 是否完成
  bool get isCompleted => _player.processingState == ProcessingState.completed;

  /// 是否正在加载或缓冲
  bool get isLoadingOrBuffering => isLoading || isBuffering;

  // ==================== 初始化 ====================

  /// 设置队列回调
  void _setupQueueCallbacks() {
    _queue.setOnStateChanged((state) {
      debugPrint('【PlaybackController】队列状态: $state');
    });
  }

  void _initListeners() {
    _playerStateSub = _player.playerStateStream.listen(
      (state) {
        if (_disposed) return;

        // 播放启动保护窗口（2秒内不覆盖手动设置的播放状态）
        if (_isStartingPlayback && !state.playing) {
          final elapsed = _playbackStartTime != null
              ? DateTime.now().difference(_playbackStartTime!)
              : Duration.zero;

          if (elapsed.inSeconds < 2) {
            debugPrint('【PlaybackController】播放启动保护中，跳过 stream 状态更新');
            return;
          } else {
            // 保护窗口已过，关闭保护
            _isStartingPlayback = false;
            _playbackStartTime = null;
            debugPrint('【PlaybackController】播放启动保护窗口已结束');
          }
        }

        // 当正在缓冲或加载时，不覆盖播放状态
        // 因为缓冲是临时状态，播放意图应该保持
        if (state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading) {
          // 保持 _isPlaying 不变，只通知 processingState 变化
          _onProcessingStateChanged?.call(state.processingState);
          debugPrint('【PlaybackController】缓冲/加载中，保持播放状态: _isPlaying=$_isPlaying, processing=${state.processingState}');
          return;
        }

        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }

        _onPlayingChanged?.call(_isPlaying);
        _onProcessingStateChanged?.call(state.processingState);
      },
      onError: (e) {
        if (!_disposed) ErrorHandler.logError(e, tag: 'PlaybackController.playerState');
      },
    );
  }

  /// 设置状态变化回调
  void setCallbacks({
    Function(bool)? onPlayingChanged,
    Function(ProcessingState)? onProcessingStateChanged,
  }) {
    _onPlayingChanged = onPlayingChanged;
    _onProcessingStateChanged = onProcessingStateChanged;
  }

  // ==================== 播放控制 ====================

  /// 执行播放命令
  Future<void> _executeCommand(PlaybackCommand cmd) async {
    switch (cmd.type) {
      case PlaybackCommandType.play:
        await _player.play();
        _isPlaying = true;
        _onPlayingChanged?.call(true);
        debugPrint('【PlaybackController】播放已启动');
        break;

      case PlaybackCommandType.pause:
        await _player.pause();
        _isPlaying = false;
        _onPlayingChanged?.call(false);
        debugPrint('【PlaybackController】已暂停');
        break;

      case PlaybackCommandType.stop:
        await _player.stop();
        _isPlaying = false;
        _onPlayingChanged?.call(false);
        debugPrint('【PlaybackController】已停止');
        break;

      case PlaybackCommandType.seek:
        final position = cmd.getParam<Duration>('position');
        if (position != null) {
          await _player.seek(position);
          debugPrint('【PlaybackController】跳转到: ${position.inSeconds}秒');
        }
        break;

      case PlaybackCommandType.setVolume:
        final volume = cmd.getParam<double>('volume');
        if (volume != null) {
          final clampedVolume = volume.clamp(0.0, 1.0);
          await _player.setVolume(clampedVolume);
          debugPrint('【PlaybackController】音量已设置为: ${(clampedVolume * 100).toInt()}%');
        }
        break;

      case PlaybackCommandType.setSpeed:
        final speed = cmd.getParam<double>('speed');
        if (speed != null) {
          final clampedSpeed = speed.clamp(0.5, 2.0);
          await _player.setSpeed(clampedSpeed);
          debugPrint('【PlaybackController】倍速已设置为: $clampedSpeed');
        }
        break;

      case PlaybackCommandType.changeTrack:
        // 切换曲目由 AudioProvider 处理
        break;
    }
  }

  /// 播放（通过队列）
  Future<void> play() async {
    if (_disposed) return;

    final cmd = PlaybackCommand(
      type: PlaybackCommandType.play,
      params: {},
    );

    await cmd.execute(_executeCommand);
  }

  /// 暂停（通过队列）
  Future<void> pause() async {
    if (_disposed) return;

    final cmd = PlaybackCommand(
      type: PlaybackCommandType.pause,
      params: {},
    );

    await cmd.execute(_executeCommand);
  }

  /// 停止（通过队列）
  Future<void> stop() async {
    if (_disposed) return;

    final cmd = PlaybackCommand(
      type: PlaybackCommandType.stop,
      params: {},
    );

    await cmd.execute(_executeCommand);
  }

  /// 切换播放/暂停（通过队列）
  Future<void> togglePlayPause() async {
    if (_disposed) return;

    final cmd = PlaybackCommand(
      type: _isPlaying ? PlaybackCommandType.pause : PlaybackCommandType.play,
      params: {},
    );

    await cmd.execute(_executeCommand);
  }

  /// 跳转到指定位置（通过队列）
  ///
  /// [position] 目标位置
  /// [seekable] 是否支持 seek（用于条件检查）
  Future<void> seek(Duration position, {bool seekable = true}) async {
    if (_disposed) return;
    if (!seekable) {
      debugPrint('【PlaybackController】当前音频不支持 seek，跳过跳转操作');
      return;
    }

    final cmd = PlaybackCommand(
      type: PlaybackCommandType.seek,
      params: {'position': position},
    );

    await cmd.execute(_executeCommand);
  }

  /// 设置音量（通过队列）
  ///
  /// [volume] 音量值（0.0 - 1.0）
  Future<void> setVolume(double volume) async {
    if (_disposed) return;

    final cmd = PlaybackCommand(
      type: PlaybackCommandType.setVolume,
      params: {'volume': volume},
    );

    await cmd.execute(_executeCommand);
  }

  /// 设置播放倍速（通过队列）
  ///
  /// [speed] 倍速值（0.5x - 2.0x）
  Future<void> setSpeed(double speed) async {
    if (_disposed) return;

    final cmd = PlaybackCommand(
      type: PlaybackCommandType.setSpeed,
      params: {'speed': speed},
    );

    await cmd.execute(_executeCommand);
  }

  // ==================== 音频源管理 ====================

  /// 设置本地音频源
  Future<void> setFileSource(String filePath) async {
    if (_disposed) return;

    debugPrint('【PlaybackController】设置本地音频源: $filePath');
    await _player.setAudioSource(AudioSource.file(filePath));
    debugPrint('【PlaybackController】本地音频源已设置');
  }

  /// 设置在线音频源
  Future<void> setUrlSource(String url) async {
    if (_disposed) return;

    debugPrint('【PlaybackController】设置在线音频源: $url');
    await _player.setUrl(url);
    debugPrint('【PlaybackController】在线音频源已设置');
  }

  /// 设置音频源并播放
  ///
  /// [playable] 可播放音频对象
  /// [timeout] 超时时间（在线音频默认30秒，本地音频5秒）
  Future<void> setSourceAndPlay(
    PlayableAudio playable, {
    Duration? timeout,
  }) async {
    if (_disposed) return;

    // 取消待处理的命令，确保新的播放操作优先
    _queue.cancelPending();

    // 设置播放启动保护
    _isStartingPlayback = true;
    _playbackStartTime = DateTime.now();
    debugPrint('【PlaybackController】播放启动保护已开启（2秒窗口）');

    bool protectionCleared = false;

    try {
      // 设置音频源
      if (playable.isOnline) {
        await _setOnlineSourceAndPlay(playable, timeout ?? const Duration(seconds: 30));
      } else {
        await _setFileSourceAndPlay(playable, timeout ?? const Duration(seconds: 5));
      }

      // 确认播放已开始，清除保护
      _isStartingPlayback = false;
      _playbackStartTime = null;
      protectionCleared = true;
      debugPrint('【PlaybackController】播放已确认，保护已清除');
    } finally {
      // 只有在保护未清除时才延迟清除
      if (!protectionCleared) {
        Future.delayed(const Duration(seconds: 2), () {
          _isStartingPlayback = false;
          _playbackStartTime = null;
          debugPrint('【PlaybackController】播放失败，延迟清除保护');
        });
      }
    }
  }

  /// 设置本地文件音频源并播放
  Future<void> _setFileSourceAndPlay(
    PlayableAudio playable,
    Duration timeout,
  ) async {
    debugPrint('【PlaybackController】设置本地音频源: ${playable.url}');

    await _player.setAudioSource(AudioSource.file(playable.url));

    // 等待就绪
    await _player.playerStateStream
        .firstWhere((state) => state.processingState == ProcessingState.ready)
        .timeout(
          timeout,
          onTimeout: () {
            debugPrint('【PlaybackController】本地音频加载超时');
            throw TimeoutException('本地音频加载超时: ${playable.url}');
          },
        );

    debugPrint('【PlaybackController】本地音频源已就绪，请求播放');
    await _player.play();

    // 等待真正的播放状态
    await _waitForPlayingState(timeout);
    _isPlaying = true;
    _onPlayingChanged?.call(true);

    debugPrint('【PlaybackController】本地音频播放已开始');
  }

  /// 设置在线音频源并播放（带重试）
  Future<void> _setOnlineSourceAndPlay(
    PlayableAudio playable,
    Duration timeout,
  ) async {
    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        debugPrint('【PlaybackController】播放在线音频 (尝试 ${retryCount + 1}/${maxRetries + 1}): ${playable.url}');

        // 设置音频源
        await _player.setUrl(playable.url);
        debugPrint('【PlaybackController】音频源已设置');

        // 等待就绪
        await _player.playerStateStream
            .firstWhere((state) => state.processingState == ProcessingState.ready)
            .timeout(
              timeout,
              onTimeout: () {
                debugPrint('【PlaybackController】音频源就绪超时');
                throw TimeoutException('音频源就绪超时: ${playable.url}');
              },
            );

        debugPrint('【PlaybackController】音频源已就绪，请求播放');

        // 调用 play()
        await _player.play();

        // 等待播放真正开始
        await _waitForPlayingState(const Duration(seconds: 5));
        _isPlaying = true;
        _onPlayingChanged?.call(true);

        debugPrint('【PlaybackController】在线音频播放已开始');
        break; // 成功，中断重试循环
      } catch (e) {
        retryCount++;
        if (retryCount <= maxRetries) {
          debugPrint('【PlaybackController】播放失败，重试中...: $e');
          await Future.delayed(const Duration(seconds: 1));
        } else {
          rethrow;
        }
      }
    }
  }

  /// 等待播放真正开始
  Future<void> _waitForPlayingState(Duration timeout) async {
    // 先检查当前状态（可能已经播放了）
    if (_player.playing) {
      debugPrint('【PlaybackController】播放已开始（检查当前状态）');
      return;
    }

    // 等待 playing 状态变化
    try {
      await _player.playerStateStream
          .firstWhere((state) => state.playing == true)
          .timeout(
            timeout,
            onTimeout: () => throw TimeoutException('播放启动超时'),
          );
      debugPrint('【PlaybackController】播放已开始（等待状态变化）');
    } on TimeoutException {
      // 超时后再次检查
      if (_player.playing) {
        debugPrint('【PlaybackController】实际上已在播放（超时后检查）');
      } else {
        debugPrint('【PlaybackController】播放启动失败，当前状态: playing=${_player.playing}, processing=${_player.processingState}');
        rethrow;
      }
    }
  }

  /// 准备音频源（不自动播放）
  ///
  /// 用于恢复播放状态时设置音频源，用户点击播放时可以立即开始
  Future<void> prepareSource(PlayableAudio playable, {int startPosition = 0}) async {
    if (_disposed) return;

    try {
      debugPrint('【PlaybackController】准备音频源: ${playable.title}, 起始位置: $startPosition秒');

      if (playable.isOnline) {
        await _player.setUrl(playable.url);
      } else {
        await _player.setAudioSource(AudioSource.file(playable.url));
      }

      // 如果有起始位置，跳转
      if (startPosition > 0) {
        await _player.seek(Duration(seconds: startPosition));
      }

      debugPrint('【PlaybackController】音频源已准备就绪');
    } catch (e) {
      debugPrint('【PlaybackController】准备音频源失败: $e');
      rethrow;
    }
  }

  // ==================== 位置监听 ====================

  /// 位置变化流
  Stream<Duration> get positionStream => _player.positionStream;

  /// 时长变化流
  Stream<Duration?> get durationStream => _player.durationStream;

  /// 播放状态流
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// 缓冲位置流
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  // ==================== 释放资源 ====================

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _playerStateSub?.cancel();
    _player.dispose();
    _queue.dispose();

    debugPrint('【PlaybackController】已释放');
  }
}
