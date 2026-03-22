import 'dart:async';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/local_playable.dart';
import '../../../models/online_playable.dart';
import '../../../models/playable_audio.dart';
import '../../../models/play_mode.dart';
import '../../../services/audio_player_service.dart';
import '../library/history_viewmodel.dart';
import '../library/playlist_viewmodel.dart' show sharedStorageServiceProvider;
import 'queue_viewmodel.dart';
import 'subtitle_viewmodel.dart';

part 'playback_viewmodel.freezed.dart';
part 'playback_viewmodel.g.dart';

/// 播放状态
@freezed
abstract class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    /// 当前可播放音频
    PlayableAudio? currentPlayable,

    /// 标题
    @Default('未知标题') String title,

    /// 艺术家
    @Default('未知艺术家') String artist,

    /// 封面 URL
    String? coverUrl,

    /// 封面数据（本地音频）
    Uint8List? coverData,

    /// 是否正在播放
    @Default(false) bool isPlaying,

    /// 是否已暂停
    @Default(false) bool isPaused,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 是否已完成
    @Default(false) bool isCompleted,

    /// 当前播放位置
    @Default(Duration.zero) Duration position,

    /// 音频总时长
    Duration? duration,

    /// 音量
    @Default(1.0) double volume,

    /// 播放倍速
    @Default(1.0) double speed,

    /// 错误消息
    String? errorMessage,

    /// 当前播放索引
    @Default(-1) int currentIndex,
  }) = _PlaybackState;
}

/// 播放控制器 ViewModel
///
/// 职责：
/// 1. 统一管理播放状态（播放/暂停/加载/完成）
/// 2. 当前播放音频信息
/// 3. 播放控制（play/pause/stop/seek/next/previous）
/// 4. 音量和倍速设置
///
/// 依赖：
/// - AudioPlayerService: 底层播放器
/// - QueueViewModel: 队列数据（只读取，不修改）
/// - SubtitleViewModel: 字幕管理
@Riverpod(keepAlive: true)
class PlaybackViewModel extends _$PlaybackViewModel {
  AudioPlayerService? _audioService;
  SharedStorageService? _storage;
  Timer? _positionSaveTimer;
  bool _disposed = false;

  /// Stream 订阅列表
  final List<StreamSubscription> _subscriptions = [];

  /// 初始化完成回调列表
  final List<void Function()> _onInitializedCallbacks = [];

  /// 是否初始化完成
  bool _isInitialized = false;

  @override
  PlaybackState build() {
    _audioService = ref.watch(audioPlayerServiceProvider);
    _storage = ref.watch(sharedStorageServiceProvider);

    ref.onDispose(() {
      if (!_disposed) {
        _disposed = true;
        _positionSaveTimer?.cancel();
        // 取消所有 Stream 订阅
        for (final sub in _subscriptions) {
          sub.cancel();
        }
        _subscriptions.clear();
        _audioService?.dispose();
      }
    });

    Future.microtask(_init);

    return const PlaybackState();
  }

  Future<void> _init() async {
    // 加载播放设置
    double volume = 1.0;
    double speed = 1.0;

    try {
      volume = _storage!.getDouble(StorageKeys.playbackVolume) ?? 1.0;
      speed = _storage!.getDouble(StorageKeys.playbackSpeed) ?? 1.0;
    } catch (e) {
      AppLogger.warn('PlaybackViewModel', '加载播放设置失败，使用默认值: $e');
    }

    state = state.copyWith(volume: volume, speed: speed);

    await _audioService!.setVolume(volume);
    await _audioService!.setPlaybackRate(speed);
    _initListeners();

    _isInitialized = true;
    AppLogger.info('PlaybackViewModel', '初始化完成');

    // 执行初始化完成回调
    for (final callback in _onInitializedCallbacks) {
      callback();
    }
    _onInitializedCallbacks.clear();
  }

  /// 注册初始化完成回调
  void onInitialized(void Function() callback) {
    if (_isInitialized) {
      callback();
    } else {
      _onInitializedCallbacks.add(callback);
    }
  }

  void _initListeners() {
    // 位置变化监听
    _subscriptions.add(
      _audioService!.positionStream.listen((position) {
        if (_disposed) return;
        state = state.copyWith(position: position);
        ref.read(subtitleViewModelProvider.notifier).updatePosition(position);
      }),
    );

    // 时长变化监听
    _subscriptions.add(
      _audioService!.durationStream.listen((duration) {
        if (_disposed) return;
        state = state.copyWith(duration: duration);
      }),
    );

    // 播放状态监听
    _subscriptions.add(
      _audioService!.playbackStateStream.listen((playerState) {
        if (_disposed) return;
        _onPlayerStateChanged(playerState);
      }),
    );

    // 播放完成监听
    _subscriptions.add(
      _audioService!.onPlayerComplete.listen((_) {
        if (_disposed) return;
        _onPlaybackComplete();
      }),
    );
  }

  void _onPlayerStateChanged(AudioPlaybackState playerState) {
    final isPlaying = playerState == AudioPlaybackState.playing;
    final isPaused = playerState == AudioPlaybackState.paused;

    state = state.copyWith(
      isPlaying: isPlaying,
      isPaused: isPaused,
      isLoading: false,
    );
  }

  void _onPlaybackComplete() {
    AppLogger.info('PlaybackViewModel', '播放完成');
    _stopPositionSaveTimer();
    state = state.copyWith(isPlaying: false, isCompleted: true);
    _playNextAutomatically();
  }

  // ==================== 播放控制 ====================

  /// 播放指定音频
  Future<void> play(PlayableAudio playable, {int index = -1}) async {
    if (_disposed) return;

    AppLogger.info('PlaybackViewModel', '播放: ${playable.title}');

    state = state.copyWith(
      currentPlayable: playable,
      title: playable.title,
      artist: playable.artist ?? '未知艺术家',
      coverUrl: playable.coverUrl,
      coverData: playable.coverData,
      currentIndex: index,
      isLoading: true,
      errorMessage: null,
    );

    try {
      if (playable.isOnline && playable is OnlinePlayable) {
        await _playOnline(playable);
      } else if (playable is LocalPlayable) {
        await _playLocal(playable);
      }

      state = state.copyWith(isLoading: false, isPlaying: true);
      _startPositionSaveTimer();
      _recordHistory(playable);
    } catch (e) {
      AppLogger.error('PlaybackViewModel', '播放失败: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '播放失败: $e',
      );
    }
  }

  Future<void> _playOnline(OnlinePlayable playable) async {
    final url = playable.url;
    AppLogger.debug('PlaybackViewModel', '播放在线URL: $url');
    await _audioService!.playUrl(url);

    // 加载字幕
    ref.read(subtitleViewModelProvider.notifier).loadSubtitle(
          playable.original.id,
          cid: playable.original.cid,
        );
  }

  Future<void> _playLocal(LocalPlayable playable) async {
    AppLogger.debug('PlaybackViewModel', '播放本地文件: ${playable.url}');
    await _audioService!.playFile(playable.url);
    ref.read(subtitleViewModelProvider.notifier).clear();
  }

  /// 暂停
  Future<void> pause() async {
    if (_disposed) return;
    await _audioService!.pause();
    _stopPositionSaveTimer();
    state = state.copyWith(isPlaying: false, isPaused: true);
    AppLogger.debug('PlaybackViewModel', '暂停');
  }

  /// 恢复播放
  Future<void> resume() async {
    if (_disposed) return;
    await _audioService!.play();
    _startPositionSaveTimer();
    state = state.copyWith(isPlaying: true, isPaused: false);
    AppLogger.debug('PlaybackViewModel', '恢复播放');
  }

  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// 停止
  Future<void> stop() async {
    if (_disposed) return;
    await _audioService!.stop();
    _stopPositionSaveTimer();
    state = state.copyWith(
      isPlaying: false,
      isPaused: false,
      currentPlayable: null,
      currentIndex: -1,
    );
    AppLogger.debug('PlaybackViewModel', '停止');
  }

  /// 跳转
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    await _audioService!.seek(position);
    AppLogger.debug('PlaybackViewModel', '跳转到: ${position.inSeconds}秒');
  }

  /// 播放下一首
  Future<void> next() async {
    final queueNotifier = ref.read(queueViewModelProvider.notifier);
    if (!queueNotifier.hasNext) return;

    final queueState = ref.read(queueViewModelProvider);
    final nextIndex = queueState.currentIndex + 1;
    final nextPlayable = queueState.queue[nextIndex];

    // 更新队列索引
    queueNotifier.setCurrentIndex(nextIndex);

    await play(nextPlayable, index: nextIndex);
    AppLogger.info('PlaybackViewModel', '播放下一首: ${nextPlayable.title}');
  }

  /// 播放上一首
  Future<void> previous() async {
    final queueNotifier = ref.read(queueViewModelProvider.notifier);
    if (!queueNotifier.hasPrevious) return;

    final queueState = ref.read(queueViewModelProvider);
    final prevIndex = queueState.currentIndex - 1;
    final prevPlayable = queueState.queue[prevIndex];

    queueNotifier.setCurrentIndex(prevIndex);

    await play(prevPlayable, index: prevIndex);
    AppLogger.info('PlaybackViewModel', '播放上一首: ${prevPlayable.title}');
  }

  void _playNextAutomatically() async {
    try {
      final queueNotifier = ref.read(queueViewModelProvider.notifier);
      final queueState = ref.read(queueViewModelProvider);
      if (queueState.playMode == PlayMode.sequence && !queueNotifier.hasNext) {
        AppLogger.debug('PlaybackViewModel', '已是最后一首，停止');
        return;
      }

      if (queueState.playMode == PlayMode.loopOne) {
        // 单曲循环
        final current = state.currentPlayable;
        if (current != null) {
          await play(current, index: queueState.currentIndex);
        }
        return;
      }

      await next();
    } catch (e) {
      AppLogger.error('PlaybackViewModel', '自动播放下一首失败: $e');
    }
  }

  // ==================== 音量/倍速 ====================

  Future<void> setVolume(double value) async {
    if (_disposed) return;
    final clamped = value.clamp(0.0, 1.0);
    await _audioService!.setVolume(clamped);
    state = state.copyWith(volume: clamped);
    await _storage!.setDouble(StorageKeys.playbackVolume, clamped);
  }

  Future<void> setSpeed(double value) async {
    if (_disposed) return;
    final clamped = value.clamp(0.5, 2.0);
    await _audioService!.setPlaybackRate(clamped);
    state = state.copyWith(speed: clamped);
    await _storage!.setDouble(StorageKeys.playbackSpeed, clamped);
  }

  // ==================== 辅助方法 ====================

  /// 准备音频源（不自动播放）
  ///
  /// 用于恢复播放时准备音频源并设置起始位置
  Future<void> prepareSource(PlayableAudio playable, {int startPosition = 0}) async {
    if (_disposed) return;

    AppLogger.info('PlaybackViewModel', '准备音频源: ${playable.title}');

    state = state.copyWith(
      currentPlayable: playable,
      title: playable.title,
      artist: playable.artist ?? '未知艺术家',
      coverUrl: playable.coverUrl,
      isLoading: true,
    );

    try {
      if (playable.isOnline && playable is OnlinePlayable) {
        await _audioService!.setUrlSource(playable.url);
        // 加载字幕
        ref.read(subtitleViewModelProvider.notifier).loadSubtitle(
              playable.original.id,
              cid: playable.original.cid,
              initialPosition: Duration(seconds: startPosition),
            );
      } else if (playable is LocalPlayable) {
        await _audioService!.setSource(playable.url);
        ref.read(subtitleViewModelProvider.notifier).clear();
      }

      if (startPosition > 0) {
        await _audioService!.seek(Duration(seconds: startPosition));
      }

      state = state.copyWith(isLoading: false);
      AppLogger.info('PlaybackViewModel', '音频源准备完成');
    } catch (e) {
      AppLogger.error('PlaybackViewModel', '准备音频源失败: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载失败',
      );
      rethrow;
    }
  }

  void _startPositionSaveTimer() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _savePosition(),
    );
  }

  void _stopPositionSaveTimer() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
  }

  Future<void> _savePosition() async {
    if (_disposed || state.currentPlayable == null) return;
    await _storage!.setInt(StorageKeys.playbackPosition, state.position.inSeconds);
  }

  void _recordHistory(PlayableAudio playable) {
    if (playable is! OnlinePlayable) return;

    try {
      ref.read(historyViewModelProvider.notifier).recordPlay(
            bvid: playable.original.id,
            title: playable.title,
            artist: playable.artist,
            duration: playable.original.duration,
            coverUrl: playable.coverUrl,
            progress: 0,
          );
    } catch (e) {
      AppLogger.debug('PlaybackViewModel', '记录历史失败: $e');
    }
  }
}

// ==================== Providers ====================

@riverpod
AudioPlayerService audioPlayerService(Ref ref) {
  return AudioPlayerService();
}