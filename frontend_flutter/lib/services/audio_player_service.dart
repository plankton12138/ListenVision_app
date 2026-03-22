import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/app_logger.dart';

/// 播放状态枚举（抽象层，不依赖具体库实现）
///
/// 用于 ViewModel 层，屏蔽底层播放库的具体实现细节。
/// 符合 MVVM 分层原则：Service 封装第三方库，ViewModel 只依赖抽象接口。
enum AudioPlaybackState {
  /// 正在播放
  playing,

  /// 已暂停
  paused,

  /// 已停止
  stopped,

  /// 播放完成
  completed,

  /// 未加载音频源
  idle,
}

/// 音频播放服务
///
/// 封装 audioplayers 包的核心功能，提供统一的播放控制接口。
///
/// 职责：
/// - 播放控制（play/pause/stop/seek）
/// - 音频源管理（本地文件/在线URL）
/// - 播放状态流（position/duration/playerState）
/// - 播放设置（volume/playbackRate）
///
/// 注意：此服务仅封装底层播放器，不包含业务逻辑（队列管理、元数据处理等）。
class AudioPlayerService {
  // ==================== 私有字段 ====================

  final AudioPlayer _player;

  /// 是否已销毁
  bool _disposed = false;

  /// 当前音频源URL（用于调试和状态判断）
  String? _currentSourceUrl;

  /// 状态订阅（用于资源清理）
  final List<StreamSubscription> _subscriptions = [];

  /// 缓存的播放位置（通过 stream 更新）
  Duration _currentPosition = Duration.zero;

  /// 缓存的音频时长（通过 stream 更新）
  Duration? _currentDuration;

  // ==================== 构造函数 ====================

  AudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _initStreams();
    AppLogger.debug('AudioPlayerService', '服务已创建');
  }

  /// 初始化状态流缓存
  void _initStreams() {
    _subscriptions.add(
      _player.onPositionChanged.listen((position) {
        _currentPosition = position;
      }),
    );
    _subscriptions.add(
      _player.onDurationChanged.listen((duration) {
        _currentDuration = duration;
      }),
    );
  }

  // ==================== 公共属性 ====================

  /// 底层播放器实例（供高级操作使用）
  AudioPlayer get player => _player;

  /// 是否已销毁
  bool get disposed => _disposed;

  /// 当前播放位置（缓存值）
  Duration get position => _currentPosition;

  /// 当前音频时长（缓存值）
  Duration? get duration => _currentDuration;

  /// 播放器状态
  PlayerState get playerState => _player.state;

  /// 是否正在播放
  bool get isPlaying => _player.state == PlayerState.playing;

  /// 是否已暂停
  bool get isPaused => _player.state == PlayerState.paused;

  /// 是否已停止
  bool get isStopped => _player.state == PlayerState.stopped;

  /// 是否已完成
  bool get isCompleted => _player.state == PlayerState.completed;

  /// 是否空闲（未加载音频）
  bool get isIdle => _player.state == PlayerState.stopped && _currentSourceUrl == null;

  /// 是否正在加载（没有有效时长且未在播放）
  bool get isLoading =>
      _currentSourceUrl != null &&
      (_currentDuration == null || _currentDuration == Duration.zero) &&
      !isPlaying &&
      _currentPosition == Duration.zero;

  /// 是否就绪（可以播放）
  bool get isReady => _currentSourceUrl != null && (_currentDuration ?? Duration.zero) > Duration.zero;

  // ==================== 播放控制 ====================

  /// 播放
  ///
  /// 恢复已暂停的音频或开始播放已加载的音频。
  /// 注意：如果未加载音频源，此方法会抛出异常。
  Future<void> play() async {
    if (_disposed) return;
    // 检查是否已加载音频源
    if (_currentSourceUrl == null) {
      AppLogger.warn('AudioPlayerService', 'play() 调用失败：未加载音频源');
      throw Exception('未加载音频源，请先调用 setSource 或 playFile/playUrl');
    }
    AppLogger.debug('AudioPlayerService', 'play()');
    await _player.resume();
  }

  /// 暂停
  Future<void> pause() async {
    if (_disposed) return;
    AppLogger.debug('AudioPlayerService', 'pause()');
    await _player.pause();
  }

  /// 停止
  Future<void> stop() async {
    if (_disposed) return;
    AppLogger.debug('AudioPlayerService', 'stop()');
    await _player.stop();
    _currentSourceUrl = null;
  }

  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (_disposed) return;
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// 跳转到指定位置
  ///
  /// [position] 目标位置
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    AppLogger.debug('AudioPlayerService', 'seek(${position.inSeconds}秒)');
    await _player.seek(position);
  }

  // ==================== 音频源管理 ====================

  Source _buildLocalSource(String pathOrUrl) {
    // Web 平台无法直接访问本地文件路径，使用 blob URL / http(s) URL
    if (kIsWeb ||
        pathOrUrl.startsWith('blob:') ||
        pathOrUrl.startsWith('http://') ||
        pathOrUrl.startsWith('https://')) {
      return UrlSource(pathOrUrl);
    }
    return DeviceFileSource(pathOrUrl);
  }

  /// 设置本地音频源
  ///
  /// [filePath] 本地音频文件的完整路径（Web 端可传 blob URL）
  Future<void> setSource(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置本地音频源: $filePath');
    await _player.setSource(_buildLocalSource(filePath));
    _currentSourceUrl = filePath;
  }

  /// 设置在线音频源
  ///
  /// [url] 在线音频流的 URL 地址
  Future<void> setUrlSource(String url) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置在线音频源: $url');
    await _player.setSource(UrlSource(url));
    _currentSourceUrl = url;
  }

  /// 播放本地文件
  ///
  /// [filePath] 本地音频文件的完整路径（Web 端可传 blob URL）
  Future<void> playFile(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '播放本地文件: $filePath');
    await _player.play(_buildLocalSource(filePath));
    _currentSourceUrl = filePath;
  }

  /// 播放在线URL
  ///
  /// [url] 在线音频流的 URL 地址
  Future<void> playUrl(String url) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '播放在线URL: $url');
    await _player.play(UrlSource(url));
    _currentSourceUrl = url;
  }

  /// 播放 Asset 资源
  ///
  /// [path] Asset 资源路径
  Future<void> playAsset(String path) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '播放Asset: $path');
    await _player.play(AssetSource(path));
    _currentSourceUrl = 'asset:$path';
  }

  /// 设置音频源并播放（本地文件）
  ///
  /// [filePath] 本地音频文件的完整路径（Web 端可传 blob URL）
  Future<void> setSourceAndPlayFile(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置并播放本地文件: $filePath');
    await _player.play(_buildLocalSource(filePath));
    _currentSourceUrl = filePath;
  }

  /// 设置音频源并播放（在线URL）
  ///
  /// [url] 在线音频流的 URL 地址
  Future<void> setSourceAndPlayUrl(String url) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置并播放在线URL: $url');
    await _player.play(UrlSource(url));
    _currentSourceUrl = url;
  }

  /// 准备音频源（不自动播放）
  ///
  /// [url] 音频源 URL 或文件路径
  /// [isOnline] 是否为在线音频（默认 false）
  Future<void> prepareSource(String url, {bool isOnline = false}) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '准备音频源: $url (在线:$isOnline)');
    if (isOnline) {
      await _player.setSource(UrlSource(url));
    } else {
      await _player.setSource(_buildLocalSource(url));
    }
    _currentSourceUrl = url;
  }

  // ==================== 播放设置 ====================

  /// 设置音量
  ///
  /// [volume] 音量值（0.0 - 1.0）
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(clampedVolume);
    AppLogger.debug('AudioPlayerService', '音量设置为: ${(clampedVolume * 100).toInt()}%');
  }

  /// 获取当前音量
  Future<double> getVolume() async {
    if (_disposed) return 1.0;
    // audioplayers 不直接支持获取音量，使用默认值
    return 1.0;
  }

  /// 设置播放倍速
  ///
  /// [rate] 倍速值（0.5x - 2.0x，默认 1.0x）
  Future<void> setPlaybackRate(double rate) async {
    if (_disposed) return;
    final clampedRate = rate.clamp(0.5, 2.0);
    await _player.setPlaybackRate(clampedRate);
    AppLogger.debug('AudioPlayerService', '倍速设置为: $clampedRate');
  }

  /// 获取当前播放倍速
  Future<double> getPlaybackRate() async {
    if (_disposed) return 1.0;
    // audioplayers 不直接支持获取倍速，使用默认值
    return 1.0;
  }

  /// 释放音频资源（暂停并释放）
  Future<void> release() async {
    if (_disposed) return;
    await _player.stop();
    _currentSourceUrl = null;
    AppLogger.debug('AudioPlayerService', '资源已释放');
  }

  // ==================== 状态流 ====================

  /// 位置变化流
  Stream<Duration> get positionStream => _player.onPositionChanged;

  /// 时长变化流
  Stream<Duration?> get durationStream => _player.onDurationChanged;

  /// 播放状态流（原始类型，供底层操作使用）
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  /// 播放状态流（抽象类型，供 ViewModel 使用）
  ///
  /// 将底层 PlayerState 转换为 AudioPlaybackState，屏蔽库实现细节。
  Stream<AudioPlaybackState> get playbackStateStream =>
      _player.onPlayerStateChanged.map(_convertPlayerState);

  /// 将底层 PlayerState 转换为抽象 AudioPlaybackState
  AudioPlaybackState _convertPlayerState(PlayerState state) {
    return switch (state) {
      PlayerState.playing => AudioPlaybackState.playing,
      PlayerState.paused => AudioPlaybackState.paused,
      PlayerState.stopped => AudioPlaybackState.stopped,
      PlayerState.completed => AudioPlaybackState.completed,
      _ => AudioPlaybackState.idle,
    };
  }

  /// 播放完成事件流
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  /// 日志流（用于调试）
  Stream<void> get onLog => _player.onLog;

  // ==================== 资源释放 ====================

  /// 释放资源
  ///
  /// 调用后对象不可再使用。
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // 取消所有订阅
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // 释放播放器
    _player.dispose();

    AppLogger.debug('AudioPlayerService', '服务已释放');
  }
}
