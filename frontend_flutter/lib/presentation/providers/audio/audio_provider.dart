import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/core/constants/api_constants.dart';
import 'package:demo/core/constants/playback_config.dart';
import 'package:demo/core/utils/error_handler.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/core/utils/debounce_utils.dart';
import 'package:demo/core/network/adaptive_network_manager.dart';
import 'package:demo/presentation/providers/audio/playback_controller.dart';
import 'package:demo/presentation/providers/audio/playback_queue_manager.dart';
import 'package:demo/presentation/providers/audio/playback_state_manager.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_loader.dart';

/// 音频播放状态管理（重构版）
///
/// 使用委托模式，将职责分离到专门组件
///
/// 架构：
/// - PlaybackController: 核心播放控制
/// - PlaybackQueueManager: 播放队列管理
/// - PlaybackStateManager: 状态持久化
/// - AudioMetadataLoader: 元数据加载
///
/// 向后兼容：保留所有原有的公共接口
class AudioProvider extends ChangeNotifier {
  // ==================== 委托组件 ====================

  /// 播放控制器
  final PlaybackController _playbackController;

  /// 播放队列管理器
  final PlaybackQueueManager _queueManager;

  /// 播放状态管理器
  final PlaybackStateManager _stateManager;

  
  /// 元数据 Provider
  AudioMetadataProvider? _audioMetadataProvider;

  // ==================== 向后兼容状态 ====================

  /// 当前元数据
  String _title = "未知标题";
  String _artist = "未知艺术家";
  Uint8List? _albumArt;

  /// 在线播放相关状态（冗余状态已改为 getter）
  bool _isSeekable = true;
  String? _currentContentType;

  /// 当前播放的文件路径（用于异步元数据验证）
  String? _currentFilePath;

  /// 播放器状态消息
  String _playerStatusMessage = '';
  bool _hasPlaybackError = false;

  /// 防止销毁后回调执行
  bool _disposed = false;

  /// 位置订阅
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  /// 播放历史进度更新定时器（每30秒）
  
  // ==================== 播放队列 ====================
  // 注意：播放队列已统一由 PlaybackQueueManager 管理

  // ==================== 防抖与节流控制 ====================

  /// 播放操作防抖器
  final Debouncer _playDebouncer = Debouncer(delay: PlaybackConfig.playDebounceDelay);

  /// 切歌操作节流器
  final Throttler _skipThrottler = Throttler(delay: PlaybackConfig.skipThrottleDelay);

  /// 操作锁（防止并发）
  final OperationLock _operationLock = OperationLock();

  // ==================== 构造函数 ====================

  AudioProvider()
      : _playbackController = PlaybackController(),
        _queueManager = PlaybackQueueManager(),
        _stateManager = PlaybackStateManager() {
    _init();
  }

  // ==================== 初始化 ====================

  Future<void> _init() async {
    // 配置音频会话
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    // P0修复：暂停网络质量监测（按需求全局停用）
    AdaptiveNetworkManager().pauseMonitoring(reason: 'global pause for maintenance');

    // 设置组件之间的回调
    _setupCallbacks();

    // 加载播放设置
    await _loadPlaybackSettings();

    // 初始化监听器
    _initListeners();

    // 加载播放队列
    await _loadQueue();

    // 恢复播放状态
    await _restorePlaybackState();
  }

  /// 设置组件之间的回调
  void _setupCallbacks() {
    // 播放控制器回调
    _playbackController.setCallbacks(
      onPlayingChanged: (isPlaying) {
        if (!_disposed) {
          if (isPlaying) {
            _playerStatusMessage = '';
          }
          notifyListeners();
        }
      },
      onPlayerStateChanged: (state) {
        if (!_disposed) {
          if (state == PlayerState.playing) {
            _playerStatusMessage = '';
          }
          notifyListeners();
        }
      },
      onPlaybackComplete: () {
        if (!_disposed) {
          AppLogger.info('AudioProvider', '播放完成，准备播放下一首');
          _handlePlaybackComplete();
        }
      },
      onPlaybackWarning: (message) {
        if (!_disposed && !_hasPlaybackError) {
          _playerStatusMessage = message;
          notifyListeners();
        }
      },
    );

    // 播放队列管理器回调
    _queueManager.setOnQueueChanged(() {
      if (!_disposed) {
        notifyListeners();
      }
    });

    // 状态管理器回调
    _stateManager.setStateCallbacks(
      getCurrentIndex: () async => _queueManager.currentIndex,
      getCurrentPlayable: () async => _queueManager.currentPlayable,
      getCurrentPosition: () async => _playbackController.position,
      getIsPlaying: () async => _playbackController.isPlaying,
    );
  }

  /// 初始化监听器
  void _initListeners() {
    // 位置变化
    _positionSub = _playbackController.positionStream.listen(
      (position) {
        if (!_disposed) {
          _syncMetadataProvider();
          notifyListeners();
        }
      },
      onError: (e) {
        if (!_disposed) ErrorHandler.logError(e, tag: 'AudioProvider.position');
      },
    );

    // 时长变化
    _durationSub = _playbackController.durationStream.listen(
      (duration) {
        if (!_disposed) {
          _syncMetadataProvider();
          notifyListeners();
        }
      },
      onError: (e) {
        if (!_disposed) ErrorHandler.logError(e, tag: 'AudioProvider.duration');
      },
    );
  }

  /// 加载播放设置
  Future<void> _loadPlaybackSettings() async {
    // 从状态管理器获取保存的设置
    _playbackController.setVolume(_stateManager.volume);
    _playbackController.setSpeed(_stateManager.speed);
  }

  /// 加载播放队列（从数据库同步到 PlaybackQueueManager）
  Future<void> _loadQueue() async {
    await _queueManager.syncFromLocal();
    notifyListeners();
  }

  /// 恢复播放状态
  Future<void> _restorePlaybackState() async {
    final savedPosition = await _queueManager.restore();
    await _queueManager.getSavedOnlineState(); // 恢复在线状态标记

    final currentPlayable = _queueManager.currentPlayable;
    if (currentPlayable != null) {
      // 更新元数据
      _title = currentPlayable.title;
      _artist = currentPlayable.artist ?? '未知艺术家';
      _albumArt = currentPlayable.coverData;

      // 在线音频支持 seek（HTTP Range 请求）
      if (currentPlayable.isOnline && currentPlayable is OnlinePlayable) {
        _isSeekable = true;
      }

      // 准备音频源（不自动播放）
      if (savedPosition != null && savedPosition > 0) {
        await _playbackController.prepareSource(
          currentPlayable,
          startPosition: savedPosition,
        );
      }
    }

    notifyListeners();
    _syncMetadataProvider();
    AppLogger.debug('AudioProvider', '播放状态已恢复');
  }

  // ==================== Getters（向后兼容）====================

  Duration get position => _playbackController.position;
  Duration get duration => _playbackController.duration ?? Duration.zero;
  bool get isPlaying => _playbackController.isPlaying;
  String get title => _title;
  String get artist => _artist;
  Uint8List? get albumArt => _albumArt;
  /// 本地音频列表（从 PlaybackQueueManager 获取）
  List<LocalAudio> get localPlaylist => _queueManager.localAudios;
  /// 统一播放队列
  List<PlayableAudio> get unifiedPlaylist => _queueManager.queue;
  int get currentIndex => _queueManager.currentIndex;
  /// 当前本地音频（向后兼容）
  /// LocalPlayable 是包装类，需要通过 .original 获取原始 LocalAudio
  LocalAudio? get currentAudio {
    if (isCurrentOnline) return null;
    final playable = _queueManager.currentPlayable;
    return playable is LocalPlayable ? playable.original : null;
  }
  PlayableAudio? get currentPlayable => _queueManager.currentPlayable;

  /// 当前是否为在线音频（从 PlaybackQueueManager 获取）
  bool get isCurrentOnline {
    final playable = _queueManager.currentPlayable;
    return playable?.isOnline ?? false;
  }

  /// 当前在线音频（从 PlaybackQueueManager 获取）
  Audio? get currentOnlineAudio {
    final playable = _queueManager.currentPlayable;
    return (playable is OnlinePlayable) ? playable.original : null;
  }

  bool get isSeekable => _isSeekable;
  String? get currentContentType => _currentContentType;
  String? get currentBvid => isCurrentOnline && currentOnlineAudio != null ? currentOnlineAudio!.id : null;
  String? get coverUrl => isCurrentOnline && currentOnlineAudio != null ? currentOnlineAudio!.coverUrl : null;

  // 播放器状态
  bool get isLoading => _playbackController.isLoading;
  bool get isBuffering => _playbackController.isBuffering;
  bool get isReady => _playbackController.isReady;
  bool get isIdle => _playbackController.isIdle;
  bool get isCompleted => _playbackController.isCompleted;
  bool get isSeeking => false; // just_audio 没有专门的 seeking 状态
  bool get isLoadingOrBuffering => _playbackController.isLoadingOrBuffering;

  // 播放设置
  double get volume => _stateManager.volume;
  double get speed => _stateManager.speed;

  // 状态消息
  String get playerStatusMessage => _playerStatusMessage;
  bool get hasPlaybackError => _hasPlaybackError;

  // 播放队列
  /// 获取播放队列总长度（委托给 PlaybackQueueManager）
  int get queueLength => _queueManager.length;

  // ==================== 播放控制 ====================

  /// 播放/暂停
  Future<void> togglePlayPause() async {
    if (_disposed) return;

    // 清除错误状态
    if (_hasPlaybackError) {
      _hasPlaybackError = false;
      _playerStatusMessage = '';
    }

    try {
      if (_playbackController.isPlaying) {
        await _playbackController.pause();
        _stateManager.stopPositionSaveTimer();
        await _stateManager.saveNow();
      } else {
        // 检查播放器是否需要加载音频源
        if (_playbackController.isIdle && _queueManager.currentPlayable != null) {
          _playerStatusMessage = '正在加载...';
          notifyListeners();

          try {
            await _playPlayable(_queueManager.currentPlayable!);
            _playerStatusMessage = '';
          } catch (e) {
            _playerStatusMessage = '播放失败: $e';
            _hasPlaybackError = true;
            notifyListeners();
            rethrow;
          }
        } else if (_playbackController.isCompleted && !isCurrentOnline) {
          await _playbackController.seek(Duration.zero);
        }

        await _playbackController.play();
        _stateManager.startPositionSaveTimer();
        _playerStatusMessage = '';
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('AudioProvider', 'togglePlayPause 错误: $e');
      _playerStatusMessage = '播放失败';
      _hasPlaybackError = true;
      notifyListeners();
      rethrow;
    }
  }

  /// 暂停
  Future<void> pause() async {
    if (_disposed) return;
    await _playbackController.pause();
    _stateManager.stopPositionSaveTimer();
    await _stateManager.saveNow();
    notifyListeners();
  }

  /// 恢复播放
  Future<void> resume() async {
    if (_disposed) return;
    if (_playbackController.isCompleted && !isCurrentOnline) {
      await _playbackController.seek(Duration.zero);
    }
    await _playbackController.play();
    _stateManager.startPositionSaveTimer();
    notifyListeners();
  }

  /// 跳转
  Future<void> seek(Duration position) async {
    await _playbackController.seek(position, seekable: _isSeekable);
  }

  /// 处理播放完成事件
  /// 自动播放下一首，如果没有下一首则重置当前歌曲到开始位置
  Future<void> _handlePlaybackComplete() async {
    if (_disposed) return;

    AppLogger.info('AudioProvider', '处理播放完成事件');

    // 停止进度保存定时器
    _stateManager.stopPositionSaveTimer();

    // 保存最终状态
    await _stateManager.saveNow();

    // 检查播放队列中是否有下一首
    if (_queueManager.hasNext) {
      AppLogger.info('AudioProvider', '播放队列中有下一首，自动播放');
      await playNext();
    } else {
      AppLogger.info('AudioProvider', '没有下一首，重置到开始位置');
      // 重置到开始位置，方便用户再次点击播放
      await _playbackController.seek(Duration.zero);
      notifyListeners();
    }
  }

  /// 下一首
  Future<void> playNext() async {
    if (_disposed) return;
    if (_queueManager.isEmpty) return;

    final nextIndex = _queueManager.nextIndex;
    await playUnifiedAt(nextIndex);
  }

  /// 上一首
  Future<void> playPrevious() async {
    if (_disposed) return;
    if (_queueManager.isEmpty) return;

    final previousIndex = _queueManager.previousIndex;
    await playUnifiedAt(previousIndex);
  }

  /// 播放指定索引的本地音频
  Future<void> playAudio(int index) async {
    if (_disposed) return;
    final localPlaylist = _queueManager.localPlaylist;
    if (index < 0 || index >= localPlaylist.length) return;

    final audio = localPlaylist[index];
    await loadAudio(audio.filePath);
  }

  // ==================== 在线播放 ====================

  /// 播放在线音频
  Future<void> playOnlineAudio({
    required Audio audio,
    String? streamUrl,
    String? proxyUrl,
    String? preferredFormat,
    bool autoFallback = true,
  }) async {
    // 检查是否已在播放
    final currentOnline = currentOnlineAudio;
    if (isCurrentOnline &&
        currentOnline?.id == audio.id &&
        _playbackController.isPlaying) {
      return;
    }

    // ✅ 修复：清除之前的状态消息
    _playerStatusMessage = '在线音频准备中...';
    _hasPlaybackError = false;
    notifyListeners();

    try {
      AppLogger.info('AudioProvider', '准备播放在线音频: ${audio.title}');

      // 构建代理 URL
      proxyUrl ??= _buildProxyUrl(audio.id, preferredFormat ?? 'auto');

      // 创建在线可播放对象
      final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

      // ⭐ 修复：在线音频也支持 seek
      _isSeekable = true;

      // 添加到播放队列并立即播放（会自动设置索引）
      await _queueManager.add(playable, playImmediately: true);

      // 播放
      await _playPlayable(playable);

      // ⭐ 保存播放队列和索引
      await _queueManager.save();

      // 修复：播放成功后清除状态消息
      _playerStatusMessage = '';

      AppLogger.info('AudioProvider', '在线播放开始: ${audio.title}');
      _syncMetadataProvider();
      notifyListeners();
    } catch (e) {
      AppLogger.error('AudioProvider', '在线播放失败: $e');
      _hasPlaybackError = true;
      _playerStatusMessage = '在线播放失败: $e';
      notifyListeners();
      rethrow;
    }
  }

 /// 构建后端代理URL
  String _buildProxyUrl(String bvid, [String format = 'auto']) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
    return '$baseUrl/api/v1/bilibili/proxy/audio/$bvid?format=$format';
  }

  // ==================== 内部播放方法 ====================

  /// 播放 PlayableAudio
  Future<void> _playPlayable(PlayableAudio playable) async {
    if (_disposed) return;

    // 更新元数据
    _title = playable.title;
    _artist = playable.artist ?? '未知艺术家';
    _albumArt = playable.coverData;

    // 使用播放控制器设置音频源并播放
    await _playbackController.setSourceAndPlay(playable);

    // 播放开始后立即清除加载提示并刷新UI
    _playerStatusMessage = '';
    _syncMetadataProvider();
    notifyListeners();

    
    notifyListeners();
  }

  /// 播放统一播放队列中指定索引的音频
  Future<void> _playUnifiedAtIndex(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _queueManager.length) return;

    final playable = _queueManager[index];
    if (playable == null) return;

    // 清除之前的状态消息，避免显示旧的状态
    _playerStatusMessage = '正在加载...';
    _hasPlaybackError = false;
    notifyListeners();

    try {
      // 直接更新索引
      _queueManager.setCurrentIndex(index, validate: false);

      // 设置 seek 状态
      _isSeekable = true;

      await _playPlayable(playable);
      await _queueManager.save();

      // 播放成功后清除状态消息
      _playerStatusMessage = '';

      _syncMetadataProvider();
      notifyListeners();
    } catch (e) {
      AppLogger.error('AudioProvider', '播放失败: $e');
      _hasPlaybackError = true;
      _playerStatusMessage = '播放失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 播放统一播放队列中指定索引的音频（公开方法）
  Future<void> playUnifiedAt(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _queueManager.length) return;

    // 如果点击的是当前曲目，切换播放/暂停
    if (_queueManager.currentIndex == index) {
      await togglePlayPause();
      return;
    }

    // 使用防抖防止快速点击
    if (_playDebouncer.isActive) {
      AppLogger.debug('AudioProvider', '播放操作被防抖忽略');
      return;
    }

    // 使用节流器限制切歌频率
    bool shouldProceed = false;
    _skipThrottler(() {
      shouldProceed = true;
    });

    if (!shouldProceed) {
      AppLogger.debug('AudioProvider', '切歌操作被节流忽略');
      return;
    }

    // 使用操作锁防止并发
    await _operationLock.synchronized(() async {
      await _playUnifiedAtIndex(index);
    });
  }

  // ==================== 加载本地音频 ====================

  /// 加载音频文件并设置元数据 - 优化：异步元数据加载，不阻塞播放
  Future<void> loadAudio(String filePath) async {
    if (_disposed) return;

    // 保存当前文件路径用于异步验证
    final currentFilePath = filePath;

    try {
      _isSeekable = true;
      _currentFilePath = filePath;

      AppLogger.info('AudioProvider', '开始加载: $filePath');

      // 先设置加载状态，避免显示旧的播放信息
      _playerStatusMessage = '正在加载...';
      _hasPlaybackError = false;
      notifyListeners();

      // ✅ 修复：直接从文件读取元数据（不依赖数据库缓存）
      final metadataLoader = AudioMetadataLoader();

      // 先用路径提取默认元数据（快速显示）
      final defaultMetadata = metadataLoader.extractMetadataFromPath(filePath);

      _title = defaultMetadata['title'] as String;
      _artist = defaultMetadata['artist'] as String;
      _albumArt = defaultMetadata['cover'] as Uint8List?;

      // 立即更新UI
      _syncMetadataProvider();
      notifyListeners();

      // 立即启动播放
      await _playbackController.setFileSource(filePath);
      await _playbackController.play();
      _playerStatusMessage = '';  // 清除加载状态
      notifyListeners();

      // 后台异步加载完整元数据（从文件，包含封面）
      metadataLoader.extractFromFile(filePath).then((fullMetadata) {
        if (_disposed || _currentFilePath != currentFilePath) return;  // 确保还是同一首歌

        final oldTitle = _title;
        final oldArtist = _artist;
        final oldAlbumArt = _albumArt;

        _title = fullMetadata['title'] as String;
        _artist = fullMetadata['artist'] as String;
        _albumArt = fullMetadata['cover'] as Uint8List?;

        // 只有元数据真正变化时才通知
        if (_title != oldTitle || _artist != oldArtist || _albumArt != oldAlbumArt) {
          AppLogger.debug('AudioProvider', '元数据已更新: $_title - $_artist');
          _syncMetadataProvider();
          notifyListeners();
        }
      });

      // P0修复：如果音频不在播放队列中，添加到播放队列并同步
      final localPlaylist = _queueManager.localPlaylist;
      final dbIndex = localPlaylist.indexWhere((a) => a.filePath == filePath);

      if (dbIndex == -1) {
        final audio = LocalAudio(
          filePath: filePath,
          title: _title,
          artist: _artist,
          duration: 0,
          albumArt: _albumArt,
          url: '',  // 本地音频没有URL
        );
        // 添加到播放队列并同步到数据库
        await _queueManager.add(LocalPlayable(audio), syncLocal: true);
        // 立即刷新播放队列UI（避免覆盖当前索引）
        await _queueManager.syncFromLocal();
        AppLogger.info('AudioProvider', '新音频已添加到播放队列: $_title');
      }

      // 更新统一播放队列索引到当前音频
      // P0修复：使用文件路径查找，因为数据库同步后ID会改变（local_hashCode -> local_64）
      final newIndex = _queueManager.playlist.indexWhere((p) =>
        p is LocalPlayable && p.original.filePath == filePath);
      if (newIndex != -1) {
        _queueManager.setCurrentIndex(newIndex, validate: false);
        AppLogger.debug('AudioProvider', '设置当前索引: $newIndex (文件: $filePath)');
      } else {
        // P0修复：如果找不到，说明是新音频，等待 add() 完成后再次查找
        AppLogger.warn('AudioProvider', '未在播放队列中找到音频: $filePath');
      }

      // 启动定时保存
      _stateManager.startPositionSaveTimer();

      // 修复：确保UI更新（包括播放队列和当前播放信息）
      // 必须在 setCurrentIndex 之后调用，以更新 AudioMetadataProvider.currentPlayable
      _syncMetadataProvider();  // 更新 currentPlayable.id
      notifyListeners();
    } catch (e) {
      AppLogger.error('AudioProvider', '加载失败: $e');
      _hasPlaybackError = true;
      _playerStatusMessage = '加载失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ==================== 播放队列管理 ====================

  /// 添加到播放队列（统一接口）
  ///
  /// [playable] 要添加的可播放音频
  /// [playImmediately] 是否立即播放（默认 false）
  Future<void> addToQueue(PlayableAudio playable, {bool playImmediately = false}) async {
    await _queueManager.add(playable, playImmediately: playImmediately);
    notifyListeners();
  }

  /// 添加在线音频到统一播放列表（不立即播放）
  ///
  /// 将在线音频添加到播放列表末尾，但不立即播放。
  ///
  /// 参数:
  /// - [audio] 要添加的在线音频
  Future<void> addToPlaylistOnline(Audio audio) async {
    AppLogger.info('AudioProvider', '添加在线音频到播放列表: ${audio.title}');

    // 构建代理 URL
    final proxyUrl = _buildProxyUrl(audio.id);

    // 创建在线可播放对象
    final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

    // 添加到播放队列（不立即播放）
    await _queueManager.add(playable, playImmediately: false);

    // 同步状态
    await _queueManager.save();
    notifyListeners();
  }

  /// 清空所有播放队列（委托给 PlaybackQueueManager）
  ///
  /// 清空统一播放队列中的所有待播放项目。
  /// 此操作不会影响当前正在播放的音频，也不会中断当前播放。
  ///
  /// 注意:
  /// - 此操作不可撤销
  /// - 当前正在播放的音频不受影响
  Future<void> clearQueue() async {
    AppLogger.info('AudioProvider', '清空播放队列');
    await _queueManager.clear();
    notifyListeners();
  }

  // ==================== 播放队列管理（原有）====================

  /// 添加到播放队列
  Future<void> addToPlaylist(LocalAudio audio) async {
    await _queueManager.add(
      LocalPlayable(audio),
      syncLocal: true,
    );
    await _loadQueue();
    notifyListeners();
  }

  /// 从播放队列移除
  Future<void> removeFromPlaylist(int id) async {
    await _queueManager.removeById(id.toString(), syncLocal: true);
    await _loadQueue();
    notifyListeners();
  }

  /// 从统一播放队列移除
  Future<void> removeFromUnifiedPlaylist(int index) async {
    await _queueManager.removeAt(index, syncLocal: true);

    // 如果删除的是当前播放项，重置状态
    if (_queueManager.currentIndex == -1) {
      await _playbackController.stop();
      _resetMetadata();
    }

    _syncMetadataProvider();
    notifyListeners();
  }

  /// 清空统一播放队列
  Future<void> clearUnifiedPlaylist() async {
    await _queueManager.clear(syncLocal: true);
    await _playbackController.stop();
    _resetMetadata();
    // 重新同步本地播放队列
    await _loadQueue();
    _syncMetadataProvider();
    notifyListeners();
  }

  /// 重新加载播放队列
  Future<void> loadPlaylist() async {
    await _loadQueue();

    if (_queueManager.localPlaylist.isEmpty) {
      await _playbackController.stop();
      _resetMetadata();
    }

    _syncMetadataProvider();
    notifyListeners();
  }

  /// 重置元数据
  void _resetMetadata() {
    _title = "无歌曲";
    _artist = "请添加音频开始播放";
    _albumArt = null;
    _stateManager.stopPositionSaveTimer();
  }

  // ==================== 播放控制设置 ====================

  /// 设置音量
  Future<void> setVolume(double value) async {
    await _playbackController.setVolume(value);
    await _stateManager.setVolume(value);
    notifyListeners();
  }

  /// 设置倍速
  Future<void> setSpeed(double value) async {
    await _playbackController.setSpeed(value);
    await _stateManager.setSpeed(value);
    notifyListeners();
  }

  /// 清除播放错误
  void clearPlaybackError() {
    _hasPlaybackError = false;
    _playerStatusMessage = '';
    notifyListeners();
  }

  // ==================== 元数据 Provider 注入 ====================

  void attachMetadataProvider({
    AudioMetadataProvider? audioMetadataProvider,
  }) {
    _audioMetadataProvider = audioMetadataProvider;
    _syncMetadataProvider();
  }

  void _syncMetadataProvider() {
    _audioMetadataProvider?.updateMetadata(
      title: _title,
      artist: _artist,
      albumArt: _albumArt,
      playable: _queueManager.currentPlayable,
    );
  }

  
  // ==================== 释放资源 ====================

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // P0修复：释放防抖和节流器
    _playDebouncer.dispose();
    _skipThrottler.dispose();
    _operationLock.dispose();

    // P0修复：停止网络监测
    AdaptiveNetworkManager().stopMonitoring();

    // 停止定时器
    _stateManager.stopPositionSaveTimer();
    _stateManager.dispose();

    // 取消订阅
    _positionSub?.cancel();
    _durationSub?.cancel();

    // 销毁播放控制器
    _playbackController.dispose();

    super.dispose();
  }

  // ==================== 停止方法 ====================

  /// 停止播放
  Future<void> stop() async {
    await _playbackController.stop();
    _stateManager.stopPositionSaveTimer();
  }
}
