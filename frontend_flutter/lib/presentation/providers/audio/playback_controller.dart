import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/core/utils/error_handler.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/core/utils/debounce_utils.dart';
import 'package:demo/core/network/adaptive_network_manager.dart';
import 'package:demo/presentation/providers/audio/playback_queue.dart';
import 'package:demo/core/constants/playback_status.dart';

/// 播放控制器（audioplayers 版本）
///
/// 职责：
/// 1. 核心播放控制（play/pause/stop/seek）
/// 2. 音频源管理
/// 3. 播放状态检测
///
/// 迁移说明：从 just_audio 迁移到 audioplayers
/// - ProcessingState 替换为 PlayerState
/// - setSpeed 替换为 setPlaybackRate
/// - AudioSource 替换为 Source 类型
class PlaybackController {
  final AudioPlayer _player;

  // 播放队列
  final PlaybackQueue _queue = PlaybackQueue();

  // 播放状态
  bool _isPlaying = false;
  bool _disposed = false;

  // 播放启动保护（防止 stream 事件覆盖正在启动的播放状态）
  bool _isStartingPlayback = false;

  // 自适应保护窗口（优化切换延迟）
  final AdaptiveProtection _adaptiveProtection = AdaptiveProtection(
    baseDuration: const Duration(milliseconds: 500),
    maxDuration: const Duration(seconds: 1),
  );

  // 音频源切换锁（防止重叠播放）
  bool _isSwitchingSource = false;
  final OperationLock _sourceSwitchLock = OperationLock();

  // 超时常量
  static const Duration _localSourceTimeout = Duration(seconds: 5);
  static const Duration _onlineSourceTimeout = Duration(seconds: 10);
  static const Duration _durationWaitTimeout = Duration(seconds: 5);

  // 状态订阅
  StreamSubscription? _playerStateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;

  // 状态变化回调
  Function(bool)? _onPlayingChanged;
  Function(PlayerState)? _onPlayerStateChanged;
  Function()? _onPlaybackComplete;
  Function(String)? _onPlaybackWarning;

  // 当前音频源信息（用于调试和状态恢复）
  String? _currentSourceUrl;

  // 内部状态追踪
  PlayerState _lastPlayerState = PlayerState.stopped;
  Duration _currentDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  DateTime? _ignoreCompletedUntil;

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

  /// 当前播放状态（audioplayers 的 PlayerState）
  PlayerState get playerState => _lastPlayerState;

  /// 当前播放位置
  Duration get position => _currentPosition;

  /// 当前音频时长
  Duration? get duration => _currentDuration;

  /// 是否空闲（未加载音频）
  bool get isIdle => _lastPlayerState == PlayerState.stopped && _currentSourceUrl == null;

  /// 是否正在播放
  bool get isCurrentlyPlaying => _lastPlayerState == PlayerState.playing;

  /// 是否已暂停
  bool get isPaused => _lastPlayerState == PlayerState.paused;

  /// 是否已完成
  bool get isCompleted => _lastPlayerState == PlayerState.completed;

  /// 是否正在加载（audioplayers 没有明确的 loading 状态）
  ///
  /// 当没有有效时长或正在切换音频源时认为正在加载
  bool get isLoading =>
      _isSwitchingSource ||
      (_currentSourceUrl != null &&
          _currentDuration == Duration.zero &&
          !_isPlaying &&
          _currentPosition == Duration.zero);

  /// 是否正在缓冲（audioplayers 缓冲状态通过 onLog 或特定事件判断）
  bool get isBuffering => false;  // audioplayers 不直接提供缓冲状态

  /// 是否就绪（可以播放）
  bool get isReady => _currentSourceUrl != null && _currentDuration > Duration.zero;

  /// 是否正在加载或缓冲
  bool get isLoadingOrBuffering => isLoading || isBuffering;

  /// 获取统一的播放状态
  PlaybackStatus get playbackStatus {
    if (_lastPlayerState == PlayerState.stopped && _currentSourceUrl == null) {
      return PlaybackStatus.idle;
    }
    if (_isLoadingSource) {
      return PlaybackStatus.loading;
    }
    if (_lastPlayerState == PlayerState.playing) {
      return PlaybackStatus.playing;
    }
    if (_lastPlayerState == PlayerState.paused) {
      return PlaybackStatus.paused;
    }
    if (_lastPlayerState == PlayerState.completed) {
      return PlaybackStatus.completed;
    }
    return PlaybackStatus.ready;
  }

  /// 是否正在加载音频源
  bool _isLoadingSource = false;

  // ==================== 初始化 ====================

  /// 设置队列回调
  void _setupQueueCallbacks() {
    _queue.setOnStateChanged((state) {
      AppLogger.debug('PlaybackController', '队列状态: $state');
    });
  }

  // 状态更新间隔限制（优化UI响应及时性）
  DateTime _lastStateUpdateTime = DateTime.now();
  static const Duration _minStateUpdateInterval = Duration(milliseconds: 50);

  void _initListeners() {
    // 播放状态监听
    _playerStateSub = _player.onPlayerStateChanged.listen(
      (state) {
        if (_disposed) return;

        // 限制状态更新频率，避免平台通道过载
        final now = DateTime.now();
        if (now.difference(_lastStateUpdateTime) < _minStateUpdateInterval) {
          return;
        }
        _lastStateUpdateTime = now;

        // 使用自适应保护窗口，但允许 stopped 状态更新
        if (_isStartingPlayback && state != PlayerState.playing) {
          if (_adaptiveProtection.isInProtectionPeriod) {
            // 允许 stopped 状态更新（用于显示加载状态）
            if (state == PlayerState.stopped) {
              _lastPlayerState = state;
            }
            AppLogger.debug('PlaybackController', '自适应保护中，仅更新 stopped 状态');
            return;
          } else {
            // 保护窗口已过，关闭保护
            _isStartingPlayback = false;
            AppLogger.debug('PlaybackController', '自适应保护窗口已结束');
          }
        }

        // 音频源切换期间允许 stopped 状态更新
        if (_isSwitchingSource && state != PlayerState.playing) {
          if (state == PlayerState.stopped) {
            _lastPlayerState = state;
          }
          AppLogger.debug('PlaybackController', '音频源切换中，仅更新 stopped 状态');
          return;
        }

        // 更新最后状态
        _lastPlayerState = state;

        // 当状态变化时更新播放状态
        if (state == PlayerState.playing) {
          _isPlaying = true;
          _ignoreCompletedUntil = null;
          _isSwitchingSource = false;
          _isStartingPlayback = false;
        } else if (state == PlayerState.paused || state == PlayerState.stopped) {
          _isPlaying = false;
        } else if (state == PlayerState.completed) {
          if (_ignoreCompletedUntil != null &&
              DateTime.now().isBefore(_ignoreCompletedUntil!)) {
            AppLogger.debug('PlaybackController', '忽略切歌后的完成状态');
            return;
          }
          _ignoreCompletedUntil = null;
          _isPlaying = false;
          // 触发播放完成回调
          AppLogger.info('PlaybackController', '播放完成，触发完成回调');
          _onPlaybackComplete?.call();
        }

        _onPlayingChanged?.call(_isPlaying);
        _onPlayerStateChanged?.call(state);
      },
      onError: (e) {
        if (!_disposed) ErrorHandler.logError(e, tag: 'PlaybackController.playerState');
      },
    );

    // 时长监听
    _durationSub = _player.onDurationChanged.listen(
      (duration) {
        if (_disposed) return;
        _currentDuration = duration;
        AppLogger.debug('PlaybackController', '音频时长: ${duration.inSeconds}秒');
      },
      onError: (e) {
        if (!_disposed) ErrorHandler.logError(e, tag: 'PlaybackController.duration');
      },
    );

    // 位置监听 - 修复进度条不更新问题
    _positionSub = _player.onPositionChanged.listen(
      (position) {
        if (_disposed) return;
        _currentPosition = position;
        if (_currentPosition > Duration.zero) {
          _isSwitchingSource = false;
          _isStartingPlayback = false;
        }
      },
      onError: (e) {
        if (!_disposed) ErrorHandler.logError(e, tag: 'PlaybackController.position');
      },
    );
  }

  /// 设置状态变化回调
  void setCallbacks({
    Function(bool)? onPlayingChanged,
    Function(PlayerState)? onPlayerStateChanged,
    Function()? onPlaybackComplete,
    Function(String)? onPlaybackWarning,
  }) {
    _onPlayingChanged = onPlayingChanged;
    _onPlayerStateChanged = onPlayerStateChanged;
    _onPlaybackComplete = onPlaybackComplete;
    _onPlaybackWarning = onPlaybackWarning;
  }

  // ==================== 播放控制 ====================

  /// 执行播放命令
  Future<void> _executeCommand(PlaybackCommand cmd) async {
    switch (cmd.type) {
      case PlaybackCommandType.play:
        await _player.resume();
        _isPlaying = true;
        _onPlayingChanged?.call(true);
        AppLogger.info('PlaybackController', '播放已启动');
        break;

      case PlaybackCommandType.pause:
        await _player.pause();
        _isPlaying = false;
        _onPlayingChanged?.call(false);
        AppLogger.info('PlaybackController', '已暂停');
        break;

      case PlaybackCommandType.stop:
        await _player.stop();
        _isPlaying = false;
        _currentSourceUrl = null;
        _onPlayingChanged?.call(false);
        AppLogger.info('PlaybackController', '已停止');
        break;

      case PlaybackCommandType.seek:
        final position = cmd.getParam<Duration>('position');
        if (position != null) {
          await _player.seek(position);
          AppLogger.debug('PlaybackController', '跳转到: ${position.inSeconds}秒');
        }
        break;

      case PlaybackCommandType.setVolume:
        final volume = cmd.getParam<double>('volume');
        if (volume != null) {
          final clampedVolume = volume.clamp(0.0, 1.0);
          await _player.setVolume(clampedVolume);
          AppLogger.debug('PlaybackController', '音量已设置为: ${(clampedVolume * 100).toInt()}%');
        }
        break;

      case PlaybackCommandType.setSpeed:
        final speed = cmd.getParam<double>('speed');
        if (speed != null) {
          final clampedSpeed = speed.clamp(0.5, 2.0);
          await _player.setPlaybackRate(clampedSpeed);
          AppLogger.debug('PlaybackController', '倍速已设置为: $clampedSpeed');
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
      AppLogger.warn('PlaybackController', '当前音频不支持 seek，跳过跳转操作');
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

    AppLogger.info('PlaybackController', '设置本地音频源: $filePath');
    _isLoadingSource = true;
    _onPlayerStateChanged?.call(_lastPlayerState);
    try {
      await _player
          .setSource(DeviceFileSource(filePath))
          .timeout(_localSourceTimeout);
      _currentSourceUrl = filePath;
    } finally {
      _isLoadingSource = false;
      _onPlayerStateChanged?.call(_lastPlayerState);
    }
  }

  /// 设置在线音频源
  Future<void> setUrlSource(String url) async {
    if (_disposed) return;

    AppLogger.info('PlaybackController', '设置在线音频源: $url');
    _isLoadingSource = true;
    _onPlayerStateChanged?.call(_lastPlayerState);
    try {
      await _player.setSource(UrlSource(url)).timeout(_onlineSourceTimeout);
      _currentSourceUrl = url;
    } finally {
      _isLoadingSource = false;
      _onPlayerStateChanged?.call(_lastPlayerState);
    }
  }

  /// 设置音频源并播放
  ///
  /// 防止音频重叠，使用锁确保同一时间只有一个音频源切换操作。
  ///
  /// [playable] 可播放音频对象
  /// [timeout] 超时时间（在线音频默认10秒，本地音频5秒）
  Future<void> setSourceAndPlay(
    PlayableAudio playable, {
    Duration? timeout,
  }) async {
    if (_disposed) return;

    // 使用锁防止并发音频源切换
    await _sourceSwitchLock.synchronized(() async {
      await _setSourceAndPlayInternal(playable, timeout);
    });
  }

  /// 内部音频源设置方法
  Future<void> _setSourceAndPlayInternal(
    PlayableAudio playable,
    Duration? timeout,
  ) async {
    // 标记正在切换音频源
    _isSwitchingSource = true;
    _ignoreCompletedUntil = DateTime.now().add(_adaptiveProtection.protectionDuration);

    // 重置播放器状态，避免上一首的"已完成"状态残留
    _lastPlayerState = PlayerState.stopped;
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;
    AppLogger.debug('PlaybackController', '重置播放器状态');

    // 取消待处理的命令，确保新的播放操作优先
    _queue.cancelPending();

    // 确保播放器完全停止
    try {
      await _player.stop();
      AppLogger.debug('PlaybackController', '播放器已停止，准备切换音频源');
    } catch (e) {
      AppLogger.warn('PlaybackController', '停止播放器时出错（可忽略）: $e');
    }

    // 等待一小段时间确保资源释放
    await Future.delayed(const Duration(milliseconds: 100));

    // 设置播放启动保护（切歌时允许更快释放）
    _isStartingPlayback = true;
    _adaptiveProtection.recordOperationStart();
    AppLogger.debug('PlaybackController', '播放启动保护已开启（自适应窗口）');

    bool protectionCleared = false;

    try {
      // 设置音频源
      if (playable.isOnline) {
        await _setOnlineSourceAndPlay(playable, timeout ?? const Duration(seconds: 10));
      } else {
        await _setFileSourceAndPlay(playable, timeout ?? const Duration(seconds: 3));
      }

      // 确认播放已开始，清除保护
      _isStartingPlayback = false;
      _adaptiveProtection.recordOperationEnd();
      protectionCleared = true;
      AppLogger.debug('PlaybackController', '播放已确认，保护已清除');
    } finally {
      // 清除切换标记（延迟一个事件循环，确保状态流先处理播放开始）
      Future.microtask(() {
        _isSwitchingSource = false;
      });

      // 只有在保护未清除时才延迟清除
      if (!protectionCleared) {
        Future.delayed(_adaptiveProtection.protectionDuration, () {
          _isStartingPlayback = false;
          AppLogger.warn('PlaybackController', '播放失败，延迟清除保护');
        });
      }
    }
  }

  /// 设置本地文件音频源并播放
  Future<void> _setFileSourceAndPlay(
    PlayableAudio playable,
    Duration timeout,
  ) async {
    AppLogger.info('PlaybackController', '设置本地音频源: ${playable.url}');

    // 设置音频源并播放
    await _player.play(DeviceFileSource(playable.url));
    _currentSourceUrl = playable.url;

    // 等待就绪（通过时长变化判断）
    await _waitForDuration(timeout);

    // 确保时长已加载后才标记为就绪
    if (_currentDuration > Duration.zero) {
      AppLogger.info('PlaybackController', '本地音频源已就绪，时长: ${_currentDuration.inSeconds}秒');
    } else {
      AppLogger.warn('PlaybackController', '本地音频源时长未加载，使用默认时长');
      // 尝试从播放器获取时长（某些情况下可能需要额外处理）
    }

    _isPlaying = true;
    _onPlayingChanged?.call(true);
  }

  /// 设置在线音频源并播放（带自适应重试）
  ///
  /// 使用网络感知的智能重试策略。
  Future<void> _setOnlineSourceAndPlay(
    PlayableAudio playable,
    Duration baseTimeout,
  ) async {
    final networkManager = AdaptiveNetworkManager();

    // 使用网络感知的智能重试
    await networkManager.executeWithRetry(
      () async {
        AppLogger.info('PlaybackController', '播放在线音频: ${playable.url}');

        // 设置音频源并播放
        // 根据网络质量设置预加载（通过HTTP headers）
        final headers = networkManager.shouldPreload()
            ? {'Range': 'bytes=0-${networkManager.getPreloadBytes()}'}
            : null;
        
        if (headers != null) {
          // audioplayers 不直接支持 headers，需要额外处理
          // 这里简化处理，直接使用 URL
          await _player.play(UrlSource(playable.url));
        } else {
          await _player.play(UrlSource(playable.url));
        }
        
        _currentSourceUrl = playable.url;

        AppLogger.info('PlaybackController', '音频源已设置，等待就绪...');

        // 等待就绪
        await _waitForDuration(_durationWaitTimeout);

        // 确保时长已加载后才标记为播放开始
        if (_currentDuration > Duration.zero) {
          AppLogger.info('PlaybackController', '在线音频已就绪，时长: ${_currentDuration.inSeconds}秒，播放开始');
        } else {
          AppLogger.warn('PlaybackController', '在线音频时长未加载，但播放已开始');
          _onPlaybackWarning?.call('在线音频正在缓冲，等待时长信息...');
        }

        _isPlaying = true;
        _onPlayingChanged?.call(true);
      },
      operationName: '在线音频播放',
      onRetry: (message, attempt, delay) {
        _onPlaybackWarning?.call(message);
      },
    );
  }

  /// 等待音频时长加载（用于判断音频是否就绪）
  ///
  /// 添加快速超时机制，播放开始后不等待时长。
  Future<void> _waitForDuration(Duration timeout) async {
    final completer = Completer<void>();
    late StreamSubscription sub;

    // 快速超时：如果500ms内没有时长信息，先允许继续（不阻塞播放）
    final quickTimeout = const Duration(milliseconds: 500);
    bool quickTimeoutHit = false;
    Timer? quickTimer;

    quickTimer = Timer(quickTimeout, () {
      if (!completer.isCompleted) {
        quickTimeoutHit = true;
        AppLogger.debug('PlaybackController', '时长加载延迟，播放将立即开始');
        // 不完成，继续等待完整超时以获取时长信息
      }
    });

    sub = _player.onDurationChanged.listen((duration) {
      if (duration > Duration.zero && !completer.isCompleted) {
        completer.complete();
        sub.cancel();
        quickTimer?.cancel();
      }
    });

    // 超时处理
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete();
        sub.cancel();
        quickTimer?.cancel();
      }
    });

    await completer.future;
    quickTimer.cancel();

    if (quickTimeoutHit) {
      AppLogger.debug('PlaybackController', '播放已开始，等待时长信息加载...');
    }
  }

  /// 准备音频源（不自动播放）
  ///
  /// 用于恢复播放状态时设置音频源，用户点击播放时可以立即开始
  Future<void> prepareSource(PlayableAudio playable, {int startPosition = 0}) async {
    if (_disposed) return;

    try {
      AppLogger.info('PlaybackController', '准备音频源: ${playable.title}, 起始位置: $startPosition秒');

      if (playable.isOnline) {
        await _player.setSource(UrlSource(playable.url));
        _currentSourceUrl = playable.url;
      } else {
        await _player.setSource(DeviceFileSource(playable.url));
        _currentSourceUrl = playable.url;
      }

      // 如果有起始位置，跳转
      if (startPosition > 0) {
        await _player.seek(Duration(seconds: startPosition));
      }

      AppLogger.info('PlaybackController', '音频源已准备就绪');
    } catch (e) {
      AppLogger.error('PlaybackController', '准备音频源失败: $e');
      rethrow;
    }
  }

  // ==================== 位置监听 ====================

  /// 位置变化流
  Stream<Duration> get positionStream => _player.onPositionChanged;

  /// 时长变化流
  Stream<Duration> get durationStream => _player.onDurationChanged;

  /// 播放状态流
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  /// 缓冲位置流（audioplayers 不直接支持，返回空流）
  Stream<Duration> get bufferedPositionStream => Stream.empty();

  // ==================== 释放资源 ====================

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // 释放锁资源
    _sourceSwitchLock.dispose();

    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    _queue.dispose();

    AppLogger.debug('PlaybackController', '已释放');
  }
}
