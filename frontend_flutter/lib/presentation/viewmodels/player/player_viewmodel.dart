import 'dart:async';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/playback_config.dart';
import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/audio.dart';
import '../../../models/local_audio.dart';
import '../../../models/online_playable.dart';
import '../../../models/playable_audio.dart';
import '../../../services/audio_player_service.dart';

part 'player_viewmodel.freezed.dart';
part 'player_viewmodel.g.dart';

/// 播放器状态
@freezed
class PlayerState with _$PlayerState {
  /// 初始状态
  const factory PlayerState({
    /// 当前可播放音频
    PlayableAudio? currentPlayable,

    /// 当前本地音频（向后兼容）
    LocalAudio? currentAudio,

    /// 当前在线音频（向后兼容）
    Audio? currentOnlineAudio,

    /// 标题
    @Default('未知标题') String title,

    /// 艺术家
    @Default('未知艺术家') String artist,

    /// 专辑封面
    Uint8List? albumArt,

    /// 在线封面 URL
    String? coverUrl,

    /// 是否正在播放
    @Default(false) bool isPlaying,

    /// 是否已暂停
    @Default(false) bool isPaused,

    /// 是否已完成
    @Default(false) bool isCompleted,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 是否正在缓冲
    @Default(false) bool isBuffering,

    /// 是否空闲
    @Default(true) bool isIdle,

    /// 是否就绪
    @Default(false) bool isReady,

    /// 是否可跳转
    @Default(true) bool isSeekable,

    /// 当前播放位置
    @Default(Duration.zero) Duration position,

    /// 音频总时长
    Duration? duration,

    /// 音量（0.0 - 1.0）
    @Default(1.0) double volume,

    /// 播放倍速（0.5x - 2.0x）
    @Default(1.0) double speed,

    /// 播放器状态消息
    @Default('') String statusMessage,

    /// 是否有播放错误
    @Default(false) bool hasError,

    /// 当前是否为在线音频
    @Default(false) bool isCurrentOnline,

    /// 当前 BVID（在线音频）
    String? currentBvid,
  }) = _PlayerState;
}

/// PlayerState 扩展
extension PlayerStateX on PlayerState {
  /// 清除错误
  PlayerState clearError() => copyWith(
    statusMessage: '',
    hasError: false,
  );
}

/// 播放器 ViewModel
///
/// 职责：
/// 1. 播放控制（play/pause/stop/seek）
/// 2. 音频源管理
/// 3. 播放状态管理
/// 4. 播放设置（音量、倍速）
///
/// 依赖：
/// - AudioPlayerService: 底层播放器封装
/// - SharedStorageService: 持久化播放设置
@Riverpod(keepAlive: true)
class PlayerViewModel extends _$PlayerViewModel {
  AudioPlayerService? _audioService;
  SharedStorageService? _storage;

  /// 状态订阅
  final List<StreamSubscription> _subscriptions = [];

  /// 播放位置保存定时器
  Timer? _positionSaveTimer;

  /// 防抖定时器
  Timer? _debounceTimer;

  /// 是否已销毁
  bool _disposed = false;

  /// 是否正在切换音频源
  bool _isSwitchingSource = false;

  /// 播放启动保护窗口
  DateTime? _ignoreCompletedUntil;

  /// 状态更新限流
  DateTime _lastStateUpdateTime = DateTime.now();

  @override
  PlayerState build() {
    _audioService = ref.watch(audioPlayerServiceProvider);
    _storage = ref.watch(sharedStorageServiceProvider);

    // 设置清理回调
    ref.onDispose(() {
      if (!_disposed) {
        _disposed = true;
        _positionSaveTimer?.cancel();
        _debounceTimer?.cancel();
        for (final sub in _subscriptions) {
          sub.cancel();
        }
        _subscriptions.clear();
        _audioService?.dispose();
      }
    });

    // 延迟初始化
    Future.microtask(_init);

    return const PlayerState();
  }

  /// 初始化
  Future<void> _init() async {
    try {
      // 配置音频会话
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.music());
      AppLogger.debug('PlayerViewModel', '音频会话已配置');

      // 加载播放设置（安全处理未初始化情况）
      double volume = 1.0;
      double speed = 1.0;

      try {
        volume = _storage!.getDouble(StorageKeys.playbackVolume) ?? 1.0;
        speed = _storage!.getDouble(StorageKeys.playbackSpeed) ?? 1.0;
      } catch (e) {
        AppLogger.warn('PlayerViewModel', '加载播放设置失败，使用默认值: $e');
      }

      state = state.copyWith(
        volume: volume,
        speed: speed,
      );

      // 应用设置到播放器
      await _audioService!.setVolume(volume);
      await _audioService!.setPlaybackRate(speed);

      // 初始化监听器
      _initListeners();

      AppLogger.info('PlayerViewModel', '初始化完成');
    } catch (e) {
      AppLogger.error('PlayerViewModel', '初始化失败: $e');
    }
  }

  /// 初始化监听器
  void _initListeners() {
    // 位置变化监听
    _subscriptions.add(
      _audioService!.positionStream.listen(
        (position) {
          if (_disposed) return;
          state = state.copyWith(position: position);
        },
        onError: (e) {
          AppLogger.error('PlayerViewModel', '位置监听错误: $e');
        },
      ),
    );

    // 时长变化监听
    _subscriptions.add(
      _audioService!.durationStream.listen(
        (duration) {
          if (_disposed) return;
          state = state.copyWith(
            duration: duration,
            isReady: duration != null && duration > Duration.zero,
          );
        },
        onError: (e) {
          AppLogger.error('PlayerViewModel', '时长监听错误: $e');
        },
      ),
    );

    // 播放状态监听
    _subscriptions.add(
      _audioService!.playerStateStream.listen(
        (playerState) {
          if (_disposed) return;
          _onPlayerStateChanged(playerState);
        },
        onError: (e) {
          AppLogger.error('PlayerViewModel', '播放状态监听错误: $e');
        },
      ),
    );

    // 播放完成监听
    _subscriptions.add(
      _audioService!.onPlayerComplete.listen(
        (_) {
          if (_disposed) return;
          _onPlaybackComplete();
        },
      ),
    );
  }

  /// 播放状态变化处理
  void _onPlayerStateChanged(ap.PlayerState playerState) {
    // 限制状态更新频率
    final now = DateTime.now();
    if (now.difference(_lastStateUpdateTime) < PlaybackConfig.minStateUpdateInterval) {
      return;
    }
    _lastStateUpdateTime = now;

    // 忽略切换期间的完成状态
    if (_isSwitchingSource &&
        playerState != ap.PlayerState.playing &&
        playerState != ap.PlayerState.stopped) {
      return;
    }

    // 忽略保护窗口内的完成状态
    if (_ignoreCompletedUntil != null &&
        now.isBefore(_ignoreCompletedUntil!) &&
        playerState == ap.PlayerState.completed) {
      AppLogger.debug('PlayerViewModel', '忽略保护窗口内的完成状态');
      return;
    }

    final isPlaying = playerState == ap.PlayerState.playing;
    final isPaused = playerState == ap.PlayerState.paused;
    final isCompleted = playerState == ap.PlayerState.completed;
    final isStopped = playerState == ap.PlayerState.stopped;

    state = state.copyWith(
      isPlaying: isPlaying,
      isPaused: isPaused,
      isCompleted: isCompleted,
      isIdle: isStopped && state.currentPlayable == null,
      isLoading: _isSwitchingSource ||
          (state.currentPlayable != null &&
              (state.duration == null || state.duration == Duration.zero) &&
              !isPlaying &&
              state.position == Duration.zero),
      statusMessage: isPlaying ? '' : state.statusMessage,
    );

    // 清除保护窗口
    if (isPlaying) {
      _ignoreCompletedUntil = null;
      _isSwitchingSource = false;
    }
  }

  /// 播放完成处理
  void _onPlaybackComplete() {
    AppLogger.info('PlayerViewModel', '播放完成');

    // 停止位置保存定时器
    _stopPositionSaveTimer();

    // 保存最终状态
    _savePlaybackState();

    state = state.copyWith(
      isPlaying: false,
      isCompleted: true,
    );
  }

  // ==================== 播放控制 ====================

  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (_disposed) return;

    // 清除错误状态
    if (state.hasError) {
      state = state.clearError();
    }

    try {
      if (state.isPlaying) {
        await pause();
      } else {
        await resume();
      }
    } catch (e) {
      AppLogger.error('PlayerViewModel', '切换播放/暂停失败: $e');
      state = state.copyWith(
        statusMessage: '播放失败: $e',
        hasError: true,
      );
    }
  }

  /// 播放
  Future<void> play() async {
    if (_disposed) return;

    try {
      await _audioService!.play();
      _startPositionSaveTimer();
      AppLogger.debug('PlayerViewModel', '播放');
    } catch (e) {
      AppLogger.error('PlayerViewModel', '播放失败: $e');
      rethrow;
    }
  }

  /// 暂停
  Future<void> pause() async {
    if (_disposed) return;

    try {
      await _audioService!.pause();
      _stopPositionSaveTimer();
      await _savePlaybackState();
      AppLogger.debug('PlayerViewModel', '暂停');
    } catch (e) {
      AppLogger.error('PlayerViewModel', '暂停失败: $e');
      rethrow;
    }
  }

  /// 恢复播放
  Future<void> resume() async {
    if (_disposed) return;

    // 检查是否需要加载音频源
    if (state.isIdle && state.currentPlayable != null) {
      state = state.copyWith(statusMessage: '正在加载...');
      try {
        await _playPlayable(state.currentPlayable!);
        state = state.copyWith(statusMessage: '');
      } catch (e) {
        state = state.copyWith(
          statusMessage: '播放失败: $e',
          hasError: true,
        );
        rethrow;
      }
    } else if (state.isCompleted && !state.isCurrentOnline) {
      await _audioService!.seek(Duration.zero);
    }

    await _audioService!.play();
    _startPositionSaveTimer();
  }

  /// 停止
  Future<void> stop() async {
    if (_disposed) return;

    await _audioService!.stop();
    _stopPositionSaveTimer();
    AppLogger.debug('PlayerViewModel', '停止');
  }

  /// 跳转
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    if (!state.isSeekable) {
      AppLogger.warn('PlayerViewModel', '当前音频不支持 seek');
      return;
    }

    await _audioService!.seek(position);
    AppLogger.debug('PlayerViewModel', '跳转到: ${position.inSeconds}秒');
  }

  /// 设置音量
  Future<void> setVolume(double value) async {
    if (_disposed) return;

    final clampedValue = value.clamp(0.0, 1.0);
    await _audioService!.setVolume(clampedValue);
    state = state.copyWith(volume: clampedValue);

    // 防抖保存
    _debounceSaveSettings();
    AppLogger.debug('PlayerViewModel', '音量: ${(clampedValue * 100).toInt()}%');
  }

  /// 设置倍速
  Future<void> setSpeed(double value) async {
    if (_disposed) return;

    final clampedValue = value.clamp(0.5, 2.0);
    await _audioService!.setPlaybackRate(clampedValue);
    state = state.copyWith(speed: clampedValue);

    // 防抖保存
    _debounceSaveSettings();
    AppLogger.debug('PlayerViewModel', '倍速: $clampedValue');
  }

  /// 清除错误
  void clearError() {
    state = state.clearError();
  }

  // ==================== 音频源管理 ====================

  /// 播放本地音频
  Future<void> playLocalAudio(String filePath, {
    String? title,
    String? artist,
    Uint8List? albumArt,
  }) async {
    if (_disposed) return;

    try {
      state = state.copyWith(
        statusMessage: '正在加载...',
        hasError: false,
      );

      AppLogger.info('PlayerViewModel', '播放本地音频: $filePath');

      // 更新元数据
      state = state.copyWith(
        title: title ?? '未知标题',
        artist: artist ?? '未知艺术家',
        albumArt: albumArt,
        isCurrentOnline: false,
        isSeekable: true,
      );

      // 设置并播放
      await _audioService!.setSourceAndPlayFile(filePath);

      state = state.copyWith(
        statusMessage: '',
        isPlaying: true,
      );

      _startPositionSaveTimer();
    } catch (e) {
      AppLogger.error('PlayerViewModel', '播放本地音频失败: $e');
      state = state.copyWith(
        statusMessage: '播放失败: $e',
        hasError: true,
      );
      rethrow;
    }
  }

  /// 播放在线音频
  Future<void> playOnlineAudio({
    required Audio audio,
    String? streamUrl,
    String? proxyUrl,
    String? preferredFormat,
  }) async {
    if (_disposed) return;

    // 检查是否已在播放
    if (state.currentOnlineAudio?.id == audio.id && state.isPlaying) {
      AppLogger.debug('PlayerViewModel', '已在播放: ${audio.title}');
      return;
    }

    try {
      state = state.copyWith(
        statusMessage: '在线音频准备中...',
        hasError: false,
      );

      AppLogger.info('PlayerViewModel', '播放在线音频: ${audio.title}');

      // 构建代理 URL
      proxyUrl ??= _buildProxyUrl(audio.id, preferredFormat ?? 'auto');

      // 创建可播放对象
      final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

      // 更新状态
      state = state.copyWith(
        currentPlayable: playable,
        currentOnlineAudio: audio,
        title: audio.title,
        artist: audio.artist ?? '未知艺术家',
        coverUrl: audio.coverUrl,
        isCurrentOnline: true,
        isSeekable: true,
        currentBvid: audio.id,
      );

      // 播放
      await _playPlayable(playable);

      state = state.copyWith(
        statusMessage: '',
        isPlaying: true,
      );

      _startPositionSaveTimer();

      AppLogger.info('PlayerViewModel', '在线播放开始: ${audio.title}');
    } catch (e) {
      AppLogger.error('PlayerViewModel', '在线播放失败: $e');
      state = state.copyWith(
        statusMessage: '在线播放失败: $e',
        hasError: true,
      );
      rethrow;
    }
  }

  /// 播放可播放对象
  Future<void> _playPlayable(PlayableAudio playable) async {
    if (_disposed) return;

    _isSwitchingSource = true;
    _ignoreCompletedUntil = DateTime.now().add(
      const Duration(milliseconds: 500),
    );

    // 更新元数据
    state = state.copyWith(
      currentPlayable: playable,
      title: playable.title,
      artist: playable.artist ?? '未知艺术家',
      albumArt: playable.coverData,
      coverUrl: playable.coverUrl,
      isCurrentOnline: playable.isOnline,
    );

    // 更新特定类型的音频
    if (playable is OnlinePlayable) {
      state = state.copyWith(
        currentOnlineAudio: playable.original,
        currentBvid: playable.original.id,
      );
    }

    // 停止当前播放
    await _audioService!.stop();
    await Future.delayed(const Duration(milliseconds: 100));

    // 设置并播放
    if (playable.isOnline) {
      await _audioService!.playUrl(playable.url);
    } else {
      await _audioService!.playFile(playable.url);
    }

    _isSwitchingSource = false;
    AppLogger.info('PlayerViewModel', '播放: ${playable.title}');
  }

  /// 准备音频源（不自动播放）
  Future<void> prepareSource(PlayableAudio playable, {int startPosition = 0}) async {
    if (_disposed) return;

    try {
      AppLogger.info('PlayerViewModel', '准备音频源: ${playable.title}');

      if (playable.isOnline) {
        await _audioService!.setUrlSource(playable.url);
      } else {
        await _audioService!.setSource(playable.url);
      }

      if (startPosition > 0) {
        await _audioService!.seek(Duration(seconds: startPosition));
      }

      // 更新状态
      state = state.copyWith(
        currentPlayable: playable,
        title: playable.title,
        artist: playable.artist ?? '未知艺术家',
        albumArt: playable.coverData,
        coverUrl: playable.coverUrl,
        isCurrentOnline: playable.isOnline,
      );
    } catch (e) {
      AppLogger.error('PlayerViewModel', '准备音频源失败: $e');
      rethrow;
    }
  }

  /// 构建后端代理 URL
  String _buildProxyUrl(String bvid, [String format = 'auto']) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
    return '$baseUrl/api/v1/bilibili/proxy/audio/$bvid?format=$format';
  }

  // ==================== 持久化 ====================

  /// 启动位置保存定时器
  void _startPositionSaveTimer() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(
      PlaybackConfig.positionSaveInterval,
      (_) => _savePlaybackState(),
    );
    AppLogger.debug('PlayerViewModel', '位置保存定时器已启动');
  }

  /// 停止位置保存定时器
  void _stopPositionSaveTimer() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
    AppLogger.debug('PlayerViewModel', '位置保存定时器已停止');
  }

  /// 保存播放状态
  Future<void> _savePlaybackState() async {
    if (_disposed || state.currentPlayable == null) return;

    try {
      // 保存位置
      await _storage!.setInt(
        StorageKeys.playbackPosition,
        state.position.inSeconds,
      );
    } catch (e) {
      AppLogger.error('PlayerViewModel', '保存播放状态失败: $e');
    }
  }

  /// 防抖保存设置
  void _debounceSaveSettings() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(PlaybackConfig.settingsDebounceDelay, () {
      if (_disposed) return;
      _saveSettings();
    });
  }

  /// 保存播放设置
  Future<void> _saveSettings() async {
    try {
      await _storage!.setDouble(StorageKeys.playbackVolume, state.volume);
      await _storage!.setDouble(StorageKeys.playbackSpeed, state.speed);
      AppLogger.debug('PlayerViewModel', '设置已保存');
    } catch (e) {
      AppLogger.error('PlayerViewModel', '保存设置失败: $e');
    }
  }

  // ==================== 公开状态访问 ====================

  /// 获取当前播放器状态（公开 getter）
  PlayerState get playerState => state;
}

// ==================== Providers ====================

/// AudioPlayerService Provider
@riverpod
AudioPlayerService audioPlayerService(Ref ref) {
  return AudioPlayerService();
}

/// SharedStorageService Provider
@riverpod
SharedStorageService sharedStorageService(Ref ref) {
  return SharedStorageService.instance;
}
