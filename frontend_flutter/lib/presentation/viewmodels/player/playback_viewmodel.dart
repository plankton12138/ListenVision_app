import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/storage_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/playback_state_validator.dart';
import '../../../models/local_playable.dart';
import '../../../models/online_playable.dart';
import '../../../models/playable_audio.dart';
import '../../../models/play_mode.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/background_audio_service.dart';
import '../../../services/bilibili_api_service.dart';
import '../../../services/bilibili_headers.dart';
import '../library/history_viewmodel.dart';
import '../library/playlist_viewmodel.dart' show sharedStorageServiceProvider;
import '../../widgets/common/snackbar_helper.dart';
import 'queue_viewmodel.dart';

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

    /// 副标题（多P视频的视频标题）
    String? albumTitle,

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
@Riverpod(keepAlive: true)
class PlaybackViewModel extends _$PlaybackViewModel {
  AudioPlayerService? _audioService;
  late BackgroundAudioService _background;
  bool _resumeAfterInterruption = false;
  SharedStorageService? _storage;
  Timer? _positionSaveTimer;
  bool _disposed = false;
  int _requestId = 0;
  CancelToken? _sourceToken;
  String? _loadedPlayableId;
  Future<void> _engineOperations = Future.value();
  late Future<void> _initialization;

  /// 各曲目已播放到的秒数（键为 playable.id），用于切歌/重启后恢复进度
  final Map<String, int> _trackPositions = {};

  /// 曲目位置写入队列，串行落盘避免并发覆盖
  Future<void> _positionPersistChain = Future.value();

  /// Stream 订阅列表
  final List<StreamSubscription> _subscriptions = [];

  /// 初始化完成回调列表
  final List<void Function()> _onInitializedCallbacks = [];

  /// 是否初始化完成
  bool _isInitialized = false;

  @override
  PlaybackState build() {
    _audioService = ref.watch(audioPlayerServiceProvider);
    _background = ref.watch(backgroundAudioServiceProvider);
    _storage = ref.watch(sharedStorageServiceProvider);

    ref.onDispose(() {
      if (!_disposed) {
        _disposed = true;
        _invalidateSource();
        _positionSaveTimer?.cancel();
        // 取消所有 Stream 订阅
        for (final sub in _subscriptions) {
          sub.cancel();
        }
        _subscriptions.clear();
      }
    });

    _initialization = Future.microtask(_init);
    unawaited(
      _initialization.catchError((Object error) {
        AppLogger.error('PlaybackViewModel', '播放器初始化失败: $error');
      }),
    );

    return const PlaybackState();
  }

  Future<void> _init() async {
    if (_disposed) return;
    // 加载播放设置
    double volume = 1.0;
    double speed = 1.0;

    try {
      volume = _storage!.getDouble(StorageKeys.playbackVolume) ?? 1.0;
      speed = _storage!.getDouble(StorageKeys.playbackSpeed) ?? 1.0;
    } catch (e) {
      AppLogger.warn('PlaybackViewModel', '加载播放设置失败，使用默认值: $e');
    }

    _loadTrackPositions();

    state = state.copyWith(volume: volume, speed: speed);

    await _audioService!.setVolume(volume);
    if (_disposed) return;
    await _audioService!.setPlaybackRate(speed);
    if (_disposed) return;
    _initListeners();
    _subscriptions.add(
      _background.commands.listen((command) {
        unawaited(_handleSystemCommand(command));
      }),
    );

    _isInitialized = true;
    AppLogger.info('PlaybackViewModel', '初始化完成');

    // 执行初始化完成回调
    for (final callback in _onInitializedCallbacks) {
      callback();
    }
    _onInitializedCallbacks.clear();
  }

  Future<void> _handleSystemCommand(Map<String, dynamic> command) async {
    if (_disposed) return;
    try {
      switch (command['action']) {
        case 'play':
          await resume();
        case 'pause':
          await pause();
        case 'stop':
          await stop();
        case 'next':
          await next();
        case 'previous':
          await previous();
        case 'seek':
          await seek(
            Duration(milliseconds: (command['position'] as num).toInt()),
          );
        case 'pauseForInterruption':
          if (state.isPlaying) _resumeAfterInterruption = true;
          await pause(fromInterruption: true);
        case 'resumeAfterInterruption':
          if (_resumeAfterInterruption) {
            _resumeAfterInterruption = false;
            await resume();
          }
      }
    } catch (error) {
      AppLogger.warn('PlaybackViewModel', '系统媒体操作失败: $error');
    }
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
        if (!_acceptEngineEvent) return;
        state = state.copyWith(position: position);
      }),
    );

    // 时长变化监听
    _subscriptions.add(
      _audioService!.durationStream.listen((duration) {
        if (!_acceptEngineEvent) return;
        state = state.copyWith(duration: duration);
      }),
    );

    // 播放状态监听
    _subscriptions.add(
      _audioService!.playbackStateStream.listen((playerState) {
        if (!_acceptEngineEvent) return;
        _onPlayerStateChanged(playerState);
      }),
    );

    // 播放完成监听
    _subscriptions.add(
      _audioService!.onPlayerComplete.listen((_) {
        if (!_acceptEngineEvent) return;
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
    _validateState();
  }

  void _onPlaybackComplete() {
    AppLogger.info('PlaybackViewModel', '播放完成');
    _stopPositionSaveTimer();
    // 播放完成后清除进度，重播时从头开始
    final playable = state.currentPlayable;
    if (playable != null) {
      _forgetPosition(playable.id);
      unawaited(_storage!.setInt(StorageKeys.currentPlaybackPosition, 0));
    }
    state = state.copyWith(isPlaying: false, isCompleted: true);
    _validateState();
    _playNextAutomatically();
  }

  // ==================== 播放控制 ====================

  /// 更新当前播放项的状态
  ///
  /// 统一设置元数据字段，确保 play() 和 prepareSource() 的一致性。
  /// 包括：currentPlayable、title、artist、coverUrl、coverData、currentIndex，
  /// 并清除 errorMessage。
  ///
  /// 切换歌曲时重置位置和时长，避免 UI 短暂显示旧歌的进度。
  void _updatePlayableState(PlayableAudio playable, {int index = -1}) {
    state = state.copyWith(
      currentPlayable: playable,
      title: playable.title,
      albumTitle: playable.albumTitle,
      artist: playable.artist ?? '未知艺术家',
      coverUrl: playable.coverUrl,
      coverData: playable.coverData,
      currentIndex: index,
      errorMessage: null,
      position: Duration.zero,
      duration: null,
    );
  }

  bool _isCurrent(int id) => !_disposed && ref.mounted && id == _requestId;

  bool get _acceptEngineEvent =>
      !_disposed &&
      ref.mounted &&
      !state.isLoading &&
      state.currentPlayable != null &&
      _loadedPlayableId == state.currentPlayable!.id;

  int _invalidateSource() {
    _sourceToken?.cancel();
    _sourceToken = null;
    _stopPositionSaveTimer();
    return ++_requestId;
  }

  /// 所有会改变音源/播放意图的命令串行执行，过期命令在进入引擎前跳过。
  Future<void> _withEngine(int id, Future<void> Function() action) {
    final operation = _engineOperations.then((_) async {
      if (!_isCurrent(id)) return;
      await _initialization;
      if (_isCurrent(id)) await action();
    });
    _engineOperations = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<void> play(PlayableAudio playable, {int index = -1}) =>
      _activateSource(playable, index: index, autoPlay: true);

  Future<void> _activateSource(
    PlayableAudio playable, {
    int index = -1,
    bool autoPlay = false,
    int startPosition = 0,
  }) async {
    if (_disposed) return;
    // 切歌前先记住当前曲目的进度，避免切换后进度丢失
    _rememberCurrentPosition();
    // 优先使用调用方指定的起始位置，否则使用该曲目上次的进度
    final resumeSeconds =
        startPosition > 0 ? startPosition : _rememberedPosition(playable.id);
    AppLogger.info(
      'PlaybackViewModel',
      '${autoPlay ? '播放' : '准备音源'}: ${playable.title}'
      '${resumeSeconds > 0 ? '（从 $resumeSeconds 秒继续）' : ''}',
    );
    _resumeAfterInterruption = false;
    final id = _invalidateSource();
    final token = _sourceToken = CancelToken();
    _updatePlayableState(playable, index: index);
    state = state.copyWith(
      isLoading: true,
      isPlaying: false,
      isPaused: false,
      isCompleted: false,
    );
    try {
      final url = playable is OnlinePlayable
          ? await _resolveOnlineStreamUrl(playable, cancelToken: token)
          : playable.url;
      if (!_isCurrent(id)) return;
      await _withEngine(id, () async {
        if (autoPlay) {
          final ready = await _background.prepare();
          if (!_isCurrent(id)) return;
          if (!ready) throw StateError('无法取得音频焦点');
        }
        _loadedPlayableId = null;
        // 准备音源不自动播放；只有仍为当前请求时才允许开始播放。
        if (playable is OnlinePlayable) {
          await _audioService!.setUrlSource(
            url,
            httpHeaders: playable.httpHeaders ?? bilibiliHeaders,
          );
        } else if (playable is LocalPlayable) {
          await _audioService!.setSource(url);
        } else {
          throw StateError('不支持的音频类型');
        }
        if (!_isCurrent(id)) return;
        _loadedPlayableId = playable.id;
        if (resumeSeconds > 0) {
          // media_kit 的 open() 在媒体加载完成前就返回，此时 seek 会被随后的
          // 加载过程覆盖（播放仍从 0 开始），必须先等时长就绪再 seek
          final seekable = await _audioService!.waitUntilSeekable();
          if (!_isCurrent(id)) return;
          if (seekable) {
            try {
              await _audioService!.seek(Duration(seconds: resumeSeconds));
            } catch (e) {
              AppLogger.warn('PlaybackViewModel', '恢复播放位置失败，从头播放: $e');
            }
          } else {
            AppLogger.warn(
              'PlaybackViewModel',
              '音频源未就绪，跳过恢复 $resumeSeconds 秒进度',
            );
          }
        }
        if (!_isCurrent(id)) return;
        if (autoPlay) await _audioService!.play();
        if (!_isCurrent(id)) return;
        state = state.copyWith(
          isLoading: false,
          isPlaying: autoPlay,
          isPaused: !autoPlay,
          position: Duration(seconds: resumeSeconds),
          duration: _audioService!.duration,
        );
        if (autoPlay) {
          _startPositionSaveTimer();
          _recordHistory(playable);
        }
        _validateState();
      });
    } catch (error) {
      if (!_isCurrent(id) ||
          token.isCancelled ||
          error is TaskCanceledException) {
        return;
      }
      AppLogger.error('PlaybackViewModel', '加载音频失败: $error');
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: getUserFriendlyMessage(classifyError(error)),
      );
      if (!autoPlay) rethrow;
    }
  }

  Future<String> _resolveOnlineStreamUrl(
    OnlinePlayable playable, {
    CancelToken? cancelToken,
  }) async {
    if (playable.url.isNotEmpty) return playable.url;
    final streams = await ref
        .read(bilibiliApiServiceProvider)
        .getAudioStreams(
          playable.original.id,
          cid: playable.original.cid,
          cancelToken: cancelToken,
        );
    if (streams.streams.isEmpty) throw Exception('无法获取音频流');
    return streams.streams.first.url;
  }

  Future<void> pause({bool fromInterruption = false}) async {
    if (_disposed) return;
    if (!fromInterruption) _resumeAfterInterruption = false;
    final id = _invalidateSource();
    await _withEngine(id, () async {
      await _savePosition();
      await _audioService!.pause();
      if (!fromInterruption) await _background.abandonFocus();
      if (!_isCurrent(id)) return;
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        isPaused: true,
      );
    });
  }

  Future<void> resume() async {
    if (_disposed || state.currentPlayable == null) return;
    final playable = state.currentPlayable!;
    if (state.isLoading || _loadedPlayableId != playable.id) {
      await play(playable, index: state.currentIndex);
      return;
    }
    final id = _invalidateSource();
    try {
      await _withEngine(id, () async {
        final ready = await _background.prepare();
        if (!_isCurrent(id)) return;
        if (!ready) throw StateError('无法取得音频焦点');
        await _audioService!.play();
        if (!_isCurrent(id)) return;
        state = state.copyWith(
          isPlaying: true,
          isPaused: false,
          isCompleted: false,
          errorMessage: null,
        );
        _startPositionSaveTimer();
      });
    } catch (error) {
      if (_isCurrent(id)) {
        state = state.copyWith(
          errorMessage: getUserFriendlyMessage(classifyError(error)),
        );
      }
    }
  }

  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (state.currentPlayable == null) {
      AppLogger.warn('PlaybackViewModel', '无可播放内容，忽略播放操作');
      return;
    }
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// 停止会立即使尚未完成的解析/准备请求失效。
  Future<void> stop() async {
    if (_disposed) return;
    _rememberCurrentPosition();
    _resumeAfterInterruption = false;
    final id = _invalidateSource();
    state = PlaybackState(
      volume: state.volume,
      speed: state.speed,
      title: '',
      artist: '',
    );
    await _withEngine(id, () async {
      await _audioService!.stop();
      await _background.stop();
      _loadedPlayableId = null;
    });
  }

  /// 跳转
  Future<void> seek(Duration position) async {
    if (_disposed ||
        state.currentPlayable == null ||
        state.isLoading ||
        _loadedPlayableId != state.currentPlayable?.id) {
      return;
    }
    final id = _requestId;
    await _withEngine(id, () => _audioService!.seek(position));
    AppLogger.debug('PlaybackViewModel', '跳转到: ${position.inSeconds}秒');
  }

  /// 播放下一首
  ///
  /// 如果已是列表最后一首，则循环到第一首开始播放并弹出提示。
  Future<void> next() async {
    final queueNotifier = ref.read(queueViewModelProvider.notifier);
    final queueState = ref.read(queueViewModelProvider);

    if (queueState.queue?.tracks.isEmpty ?? true) return;

    final nextIndex = queueNotifier.hasNext
        ? (queueState.queue!.currentIndex + 1)
        : 0;

    // 循环到第一首时弹出提示
    if (!queueNotifier.hasNext) {
      SnackbarHelper.showToast('列表播放完，从列表第一首开始播放');
      AppLogger.info('PlaybackViewModel', '列表循环：最后一首 → 第一首');
    }

    final nextPlayable = queueState.queue!.tracks[nextIndex];
    queueNotifier.setCurrentIndex(nextIndex);

    await play(nextPlayable, index: nextIndex);
    AppLogger.info('PlaybackViewModel', '播放下一首: ${nextPlayable.title}');
  }

  /// 播放上一首
  ///
  /// 如果已是列表第一首，则循环到最后一首并弹出提示。
  Future<void> previous() async {
    final queueNotifier = ref.read(queueViewModelProvider.notifier);
    final queueState = ref.read(queueViewModelProvider);

    if (queueState.queue?.tracks.isEmpty ?? true) return;

    final prevIndex = queueNotifier.hasPrevious
        ? (queueState.queue!.currentIndex - 1)
        : (queueState.queue!.tracks.length - 1);

    // 循环到最后一首时弹出提示
    if (!queueNotifier.hasPrevious) {
      SnackbarHelper.showToast('列表播到头，从列表最后一首开始播放');
      AppLogger.info('PlaybackViewModel', '列表循环：第一首 → 最后一首');
    }

    final prevPlayable = queueState.queue!.tracks[prevIndex];
    queueNotifier.setCurrentIndex(prevIndex);

    await play(prevPlayable, index: prevIndex);
    AppLogger.info('PlaybackViewModel', '播放上一首: ${prevPlayable.title}');
  }

  void _playNextAutomatically() async {
    try {
      final queueState = ref.read(queueViewModelProvider);

      if (queueState.queue?.playMode == PlayMode.loopOne) {
        // 单曲循环
        final current = state.currentPlayable;
        if (current != null) {
          await play(current, index: queueState.queue?.currentIndex ?? -1);
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

  /// 从队列准备当前音频（不自动播放）
  ///
  /// 用于应用启动时恢复上次播放位置。
  /// 依赖 QueueViewModel 已恢复完成。
  ///
  /// 如果当前音频源已就绪（相同 ID 且播放器已加载有效时长），
  /// 则跳过重复准备，仅恢复到保存的播放位置。
  Future<void> prepareCurrentFromQueue() async {
    if (_disposed) return;

    final queueNotifier = ref.read(queueViewModelProvider.notifier);
    final queueState = ref.read(queueViewModelProvider);
    final currentIndex = queueState.queue?.currentIndex ?? -1;

    // 验证索引有效性
    if (currentIndex < 0 ||
        currentIndex >= (queueState.queue?.tracks.length ?? 0)) {
      AppLogger.debug('PlaybackViewModel', '队列索引无效，跳过恢复');
      return;
    }

    final playable = queueState.queue!.tracks[currentIndex];

    // 如果当前音频源已就绪且为同一音频项，无需重复准备
    // isReady: _currentSourceUrl != null && duration > 0
    if (state.currentPlayable?.id == playable.id &&
        _audioService != null &&
        _audioService!.isReady) {
      AppLogger.info('PlaybackViewModel', '音频源已就绪，无需恢复');
      return;
    }

    final recoveryId = _requestId;
    final savedPosition = await queueNotifier.restorePosition() ?? 0;
    if (!_isCurrent(recoveryId)) return;

    AppLogger.info(
      'PlaybackViewModel',
      '恢复队列项: ${playable.title}, 位置: ${savedPosition}s',
    );

    await prepareSource(playable, startPosition: savedPosition);
  }

  /// 准备音频源（不自动播放）
  ///
  /// 用于恢复播放时准备音频源并设置起始位置
  Future<void> prepareSource(PlayableAudio playable, {int startPosition = 0}) =>
      _activateSource(playable, startPosition: startPosition);

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

  /// 从本地存储加载各曲目的播放位置
  void _loadTrackPositions() {
    try {
      final raw = _storage!.getString(StorageKeys.trackPositions);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        if (value is num) _trackPositions[key.toString()] = value.toInt();
      });
      AppLogger.debug(
        'PlaybackViewModel',
        '加载曲目播放位置: ${_trackPositions.length}条',
      );
    } catch (e) {
      AppLogger.warn('PlaybackViewModel', '加载曲目播放位置失败: $e');
    }
  }

  /// 持久化各曲目的播放位置（串行写入，避免并发覆盖）
  Future<void> _persistTrackPositions() {
    final snapshot = jsonEncode(_trackPositions);
    final next = _positionPersistChain.then((_) async {
      await _storage!.setString(StorageKeys.trackPositions, snapshot);
    });
    _positionPersistChain = next.catchError((Object error) {
      AppLogger.warn('PlaybackViewModel', '保存曲目播放位置失败: $error');
    });
    return _positionPersistChain;
  }

  /// 记录某曲目已播放到的秒数（秒数变化时才落盘）
  void _rememberPosition(String id, int seconds) {
    if (_disposed || seconds < 0 || _trackPositions[id] == seconds) return;
    _trackPositions[id] = seconds;
    unawaited(_persistTrackPositions());
  }

  /// 读取某曲目已保存的播放位置（秒）
  int _rememberedPosition(String id) => _trackPositions[id] ?? 0;

  /// 清除某曲目的播放位置（播放完成后重播应从头开始）
  void _forgetPosition(String id) {
    if (_trackPositions.remove(id) == null) return;
    unawaited(_persistTrackPositions());
  }

  /// 记录当前曲目的播放位置
  ///
  /// 仅在当前曲目已加载完成且未播放完成时记录，
  /// 避免加载过程中的 0 秒覆盖已保存的进度。
  void _rememberCurrentPosition() {
    final playable = state.currentPlayable;
    if (_disposed || playable == null) return;
    if (state.isCompleted || state.isLoading) return;
    if (_loadedPlayableId != playable.id) return;
    _rememberPosition(playable.id, state.position.inSeconds);
  }

  Future<void> _savePosition() async {
    if (_disposed || state.currentPlayable == null) return;
    final playable = state.currentPlayable!;
    if (state.isCompleted) {
      _forgetPosition(playable.id);
    } else {
      _rememberPosition(playable.id, state.position.inSeconds);
    }
    await _storage!.setInt(
      StorageKeys.currentPlaybackPosition,
      state.isCompleted ? 0 : state.position.inSeconds,
    );
  }

  void _recordHistory(PlayableAudio playable) {
    if (playable is! OnlinePlayable) return;

    try {
      ref
          .read(historyViewModelProvider.notifier)
          .recordPlay(
            bvid: playable.original.id,
            title: playable.title,
            artist: playable.artist,
            albumTitle: playable.albumTitle,
            duration: playable.original.duration,
            coverUrl: playable.coverUrl,
            progress: 0,
            sourceType: 'manual',
          );
    } catch (e) {
      AppLogger.debug('PlaybackViewModel', '记录历史失败: $e');
    }
  }

  /// 验证状态完整性（仅 DEBUG 模式）
  ///
  /// 在关键操作后检查状态是否存在不一致问题，如：
  /// - isPlaying=true 但 currentPlayable=null
  /// - isLoading 和 isPlaying 同时为 true
  /// - isPlaying 和 isPaused 同时为 true
  void _validateState() {
    assert(() {
      final result = PlaybackStateValidator.validate(state);
      if (!result.isValid) {
        AppLogger.warn('PlaybackViewModel', '状态不一致: ${result.issues}');
      }
      return true;
    }());
  }
}

// ==================== Providers ====================

@riverpod
AudioPlayerService audioPlayerService(Ref ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
}

/// 低频控制状态与高频进度隔离，避免封面和按钮跟随每次 position 更新。
final playbackControlsProvider = Provider<PlaybackState>(
  (ref) => ref.watch(
    playbackViewModelProvider.select(
      (s) => s.copyWith(position: Duration.zero, duration: null),
    ),
  ),
);
