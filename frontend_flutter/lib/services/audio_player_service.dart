import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
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

/// 音频播放错误类型
///
/// 用于分类播放过程中可能出现的各种错误，
/// 并提供用户友好的错误提示信息。
enum AudioPlayerErrorType {
  /// 源加载失败
  sourceLoadFailed,

  /// 网络错误
  networkError,

  /// 文件不存在
  fileNotFound,

  /// 格式不支持
  formatNotSupported,

  /// 平台错误
  platformError,

  /// 未知错误
  unknown,
}

/// 根据异常分类错误类型
///
/// [error] 异常对象或错误消息
/// 返回对应的错误类型枚举
AudioPlayerErrorType classifyError(dynamic error) {
  final errorString = error.toString().toLowerCase();

  if (errorString.contains('platformerror') ||
      errorString.contains('platform') ||
      errorString.contains('media_kit') ||
      errorString.contains('mpv')) {
    return AudioPlayerErrorType.platformError;
  }
  if (errorString.contains('network') ||
      errorString.contains('socket') ||
      errorString.contains('timeout') ||
      errorString.contains('connection') ||
      errorString.contains('403') ||
      errorString.contains('404')) {
    return AudioPlayerErrorType.networkError;
  }
  if (errorString.contains('file not found') ||
      errorString.contains('enoent') ||
      errorString.contains('could not find') ||
      errorString.contains('no such file')) {
    return AudioPlayerErrorType.fileNotFound;
  }
  if (errorString.contains('format') ||
      errorString.contains('unsupported') ||
      errorString.contains('invalid audio') ||
      errorString.contains('no audio')) {
    return AudioPlayerErrorType.formatNotSupported;
  }
  if (errorString.contains('source') ||
      errorString.contains('load failed') ||
      errorString.contains('failed to load') ||
      errorString.contains('failed to open')) {
    return AudioPlayerErrorType.sourceLoadFailed;
  }
  return AudioPlayerErrorType.unknown;
}

/// 获取用户友好的错误消息
///
/// [type] 错误类型
/// 返回中文用户友好错误提示
String getUserFriendlyMessage(AudioPlayerErrorType type) {
  return switch (type) {
    AudioPlayerErrorType.sourceLoadFailed => '音频源加载失败，请重试',
    AudioPlayerErrorType.networkError => '网络连接失败，请检查网络',
    AudioPlayerErrorType.fileNotFound => '音频文件不存在或已被删除',
    AudioPlayerErrorType.formatNotSupported => '音频格式不支持',
    AudioPlayerErrorType.platformError => '播放器初始化失败，请重启应用',
    AudioPlayerErrorType.unknown => '播放失败，请重试',
  };
}

/// 音频播放服务
///
/// 封装 media_kit 的 Player 功能，提供统一的播放控制接口。
/// 对外接口与 audioplayers 版本完全兼容。
///
/// 职责：
/// - 播放控制（play/pause/stop/seek）
/// - 音频源管理（本地文件/在线URL + 自定义HTTP请求头）
/// - 播放状态流（position/duration/playerState）
/// - 播放设置（volume/playbackRate）
///
/// 注意：此服务仅封装底层播放器，不包含业务逻辑（队列管理、元数据处理等）。
class AudioPlayerService {
  // ==================== 私有字段 ====================

  final Player _player;

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

  /// 是否已播放完成
  bool _isCompleted = false;

  // ==================== 构造函数 ====================

  AudioPlayerService({Player? player}) : _player = player ?? Player() {
    _initStreams();
    AppLogger.debug('AudioPlayerService', '服务已创建');
  }

  /// 初始化状态流缓存
  void _initStreams() {
    _subscriptions.add(
      _player.stream.position.listen((position) {
        _currentPosition = position;
      }),
    );
    _subscriptions.add(
      _player.stream.duration.listen((duration) {
        if (duration > Duration.zero) {
          _currentDuration = duration;
        }
      }),
    );
    _subscriptions.add(
      _player.stream.completed.listen((completed) {
        _isCompleted = completed;
      }),
    );
  }

  // ==================== 公共属性 ====================

  /// 底层播放器实例（供高级操作使用）
  Player get player => _player;

  /// 是否已销毁
  bool get disposed => _disposed;

  /// 当前播放位置（缓存值）
  Duration get position => _currentPosition;

  /// 当前音频时长（缓存值）
  Duration? get duration => _currentDuration;

  /// 是否正在播放
  bool get isPlaying => _player.state.playing;

  /// 是否已暂停
  bool get isPaused =>
      !_player.state.playing && _currentSourceUrl != null && !_isCompleted;

  /// 是否已停止
  bool get isStopped => _currentSourceUrl == null;

  /// 是否已完成
  bool get isCompleted => _isCompleted;

  /// 是否空闲（未加载音频）
  bool get isIdle => _currentSourceUrl == null;

  /// 是否正在加载（没有有效时长且未在播放）
  bool get isLoading =>
      _currentSourceUrl != null &&
      (_currentDuration == null || _currentDuration == Duration.zero) &&
      !isPlaying &&
      _currentPosition == Duration.zero;

  /// 是否就绪（可以播放）
  bool get isReady =>
      _currentSourceUrl != null &&
      (_currentDuration ?? Duration.zero) > Duration.zero;

  // ==================== 播放控制 ====================

  /// 播放
  ///
  /// 恢复已暂停的音频或开始播放已加载的音频。
  /// 注意：如果未加载音频源，此方法会抛出异常。
  Future<void> play() async {
    if (_disposed) return;
    if (_currentSourceUrl == null) {
      AppLogger.warn('AudioPlayerService', 'play() 调用失败：未加载音频源');
      throw Exception('未加载音频源，请先调用 setSource 或 playFile/playUrl');
    }
    AppLogger.debug('AudioPlayerService', 'play()');
    await _player.play();
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
    _isCompleted = false;
  }

  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (_disposed) return;
    await _player.playOrPause();
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

  /// 根据路径判断是本地文件还是URL
  bool _isUrl(String pathOrUrl) {
    return kIsWeb ||
        pathOrUrl.startsWith('blob:') ||
        pathOrUrl.startsWith('http://') ||
        pathOrUrl.startsWith('https://');
  }

  /// 设置本地音频源
  ///
  /// [filePath] 本地音频文件的完整路径（Web 端可传 blob URL）
  Future<void> setSource(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置本地音频源: $filePath');
    if (_isUrl(filePath)) {
      await _player.open(Media(filePath));
    } else {
      await _player.open(Media(filePath));
    }
    _currentSourceUrl = filePath;
    _isCompleted = false;
  }

  /// 设置在线音频源
  ///
  /// [url] 在线音频流的 URL 地址
  /// [httpHeaders] 可选的自定义 HTTP 请求头（用于解决 CDN 防盗链问题）
  Future<void> setUrlSource(String url, {Map<String, String>? httpHeaders}) async {
    if (_disposed) return;
    if (url.isEmpty) {
      AppLogger.warn('AudioPlayerService', 'setUrlSource() 失败：URL 为空');
      throw Exception('在线音频 URL 为空，请刷新后重试');
    }
    AppLogger.info('AudioPlayerService', '设置在线音频源: $url');
    final media = httpHeaders != null && httpHeaders.isNotEmpty
        ? Media(url, httpHeaders: httpHeaders)
        : Media(url);
    await _player.open(media);
    _currentSourceUrl = url;
    _isCompleted = false;
  }

  /// 播放本地文件
  ///
  /// [filePath] 本地音频文件的完整路径（Web 端可传 blob URL）
  Future<void> playFile(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '播放本地文件: $filePath');
    await _player.open(Media(filePath));
    _currentSourceUrl = filePath;
    _isCompleted = false;
  }

  /// 播放在线URL（带重试）
  ///
  /// [url] 在线音频流的 URL 地址
  /// [maxRetries] 最大重试次数（默认 2）
  /// [httpHeaders] 可选的自定义 HTTP 请求头（用于解决 CDN 防盗链问题）
  Future<void> playUrl(String url,
      {int maxRetries = 2, Map<String, String>? httpHeaders}) async {
    if (_disposed) return;
    if (url.isEmpty) {
      AppLogger.warn('AudioPlayerService', 'playUrl() 失败：URL 为空');
      throw Exception('在线音频 URL 为空，请刷新后重试');
    }

    int attempt = 0;
    while (attempt <= maxRetries) {
      try {
        AppLogger.info(
            'AudioPlayerService', '播放在线URL (尝试 ${attempt + 1}): $url');
        final media = httpHeaders != null && httpHeaders.isNotEmpty
            ? Media(url, httpHeaders: httpHeaders)
            : Media(url);
        await _player.open(media);
        _currentSourceUrl = url;
        _isCompleted = false;
        return;
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) {
          AppLogger.error(
              'AudioPlayerService', '播放失败，已重试 $maxRetries 次: $e');
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
        AppLogger.warn(
            'AudioPlayerService', '播放失败，准备重试 ($attempt/$maxRetries): $e');
      }
    }
  }

  /// 播放 Asset 资源（media_kit 不支持，保留接口兼容性）
  Future<void> playAsset(String path) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '播放Asset: $path');
    throw UnimplementedError('media_kit 不支持 Asset 播放，请使用本地文件或在线URL');
  }

  /// 设置音频源并播放（本地文件）
  ///
  /// [filePath] 本地音频文件的完整路径（Web 端可传 blob URL）
  Future<void> setSourceAndPlayFile(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置并播放本地文件: $filePath');
    await _player.open(Media(filePath));
    _currentSourceUrl = filePath;
    _isCompleted = false;
  }

  /// 设置音频源并播放（在线URL）
  ///
  /// [url] 在线音频流的 URL 地址
  /// [httpHeaders] 可选的自定义 HTTP 请求头
  Future<void> setSourceAndPlayUrl(String url,
      {Map<String, String>? httpHeaders}) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置并播放在线URL: $url');
    final media = httpHeaders != null && httpHeaders.isNotEmpty
        ? Media(url, httpHeaders: httpHeaders)
        : Media(url);
    await _player.open(media);
    _currentSourceUrl = url;
    _isCompleted = false;
  }

  /// 准备音频源（不自动播放）
  ///
  /// [url] 音频源 URL 或文件路径
  /// [isOnline] 是否为在线音频（默认 false）
  /// [httpHeaders] 可选的自定义 HTTP 请求头
  Future<void> prepareSource(String url,
      {bool isOnline = false, Map<String, String>? httpHeaders}) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '准备音频源: $url (在线:$isOnline)');
    if (isOnline) {
      final media = httpHeaders != null && httpHeaders.isNotEmpty
          ? Media(url, httpHeaders: httpHeaders)
          : Media(url);
      await _player.open(media, play: false);
    } else {
      await _player.open(Media(url), play: false);
    }
    _currentSourceUrl = url;
    _isCompleted = false;
  }

  // ==================== 播放设置 ====================

  /// 设置音量
  ///
  /// [volume] 音量值（0.0 - 1.0，内部映射到 media_kit 的 0.0 - 100.0）
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(clampedVolume * 100.0);
    AppLogger.debug(
        'AudioPlayerService', '音量设置为: ${(clampedVolume * 100).toInt()}%');
  }

  /// 获取当前音量
  Future<double> getVolume() async {
    if (_disposed) return 1.0;
    return _player.state.volume / 100.0;
  }

  /// 设置播放倍速
  ///
  /// [rate] 倍速值（0.5x - 2.0x，默认 1.0x）
  Future<void> setPlaybackRate(double rate) async {
    if (_disposed) return;
    final clampedRate = rate.clamp(0.5, 2.0);
    await _player.setRate(clampedRate);
    AppLogger.debug('AudioPlayerService', '倍速设置为: $clampedRate');
  }

  /// 获取当前播放倍速
  Future<double> getPlaybackRate() async {
    if (_disposed) return 1.0;
    return _player.state.rate;
  }

  /// 释放音频资源（暂停并释放）
  Future<void> release() async {
    if (_disposed) return;
    await _player.stop();
    _currentSourceUrl = null;
    _isCompleted = false;
    AppLogger.debug('AudioPlayerService', '资源已释放');
  }

  // ==================== 状态流 ====================

  /// 位置变化流
  Stream<Duration> get positionStream => _player.stream.position;

  /// 时长变化流
  Stream<Duration?> get durationStream => _player.stream.duration;

  /// 播放状态流（抽象类型，供 ViewModel 使用）
  ///
  /// 将 media_kit Player 的 playing 状态转换为 AudioPlaybackState
  Stream<AudioPlaybackState> get playbackStateStream =>
      _player.stream.playing.map((playing) {
        if (playing) return AudioPlaybackState.playing;
        if (_isCompleted) return AudioPlaybackState.completed;
        if (_currentSourceUrl == null) return AudioPlaybackState.idle;
        return AudioPlaybackState.paused;
      });

  /// 播放完成事件流
  Stream<void> get onPlayerComplete =>
      _player.stream.completed.where((completed) => completed);

  // ==================== 资源释放 ====================

  /// 释放资源
  ///
  /// 调用后对象不可再使用。
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    _player.dispose();

    AppLogger.debug('AudioPlayerService', '服务已释放');
  }
}