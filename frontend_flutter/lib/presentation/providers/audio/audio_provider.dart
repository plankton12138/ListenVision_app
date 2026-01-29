import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/core/constants/storage_constants.dart';
import 'package:demo/core/constants/api_constants.dart';
import 'package:demo/core/utils/error_handler.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/core/utils/debounce_utils.dart';
import 'package:demo/core/network/adaptive_network_manager.dart';
import 'package:demo/presentation/providers/audio/playback_controller.dart';
import 'package:demo/presentation/providers/audio/unified_playlist_manager.dart';
import 'package:demo/presentation/providers/audio/playback_state_manager.dart';
import 'package:demo/presentation/providers/audio/state_transaction.dart';
import 'package:demo/presentation/providers/audio/now_playing_provider.dart';
import 'package:demo/presentation/providers/audio/audio_playlist_provider.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_loader.dart';

/// 音频播放状态管理（重构版）
///
/// Phase 2.1 重构：使用委托模式，将职责分离到专门组件
///
/// 架构：
/// - PlaybackController: 核心播放控制
/// - UnifiedPlaylistManager: 播放列表管理
/// - PlaybackStateManager: 状态持久化
/// - AudioMetadataLoader: 元数据加载
///
/// 向后兼容：保留所有原有的公共接口
class AudioProvider extends ChangeNotifier {
  // ==================== 委托组件 ====================

  /// 播放控制器
  final PlaybackController _playbackController;

  /// 统一播放列表管理器
  final UnifiedPlaylistManager _playlistManager;

  /// 播放状态管理器
  final PlaybackStateManager _stateManager;

  /// 子 Provider 镜像
  NowPlayingProvider? _nowPlayingProvider;
  AudioPlaylistProvider? _audioPlaylistProvider;
  AudioMetadataProvider? _audioMetadataProvider;

  // ==================== 向后兼容状态 ====================

  /// 播放历史记录的 Dio 客户端（15秒超时）
  final Dio _historyDio = Dio(BaseOptions(
    baseUrl: ApiConstants.fullBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ));

  /// 当前元数据
  String _title = "未知标题";
  String _artist = "未知艺术家";
  Uint8List? _albumArt;

  /// 在线播放相关状态
  Audio? _currentOnlineAudio;
  bool _isCurrentOnline = false;
  bool _isSeekable = true;
  String? _currentContentType;

  /// 播放器状态消息
  String _playerStatusMessage = '';
  bool _hasPlaybackError = false;

  /// 防止销毁后回调执行
  bool _disposed = false;

  /// 位置订阅
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  // ==================== P0修复：防抖与版本控制 ====================

  /// 状态版本控制器
  final StateVersionController _versionController = StateVersionController();

  /// 播放操作防抖器（300ms）
  final Debouncer _playDebouncer = Debouncer(delay: const Duration(milliseconds: 300));

  /// 切歌操作节流器（500ms）
  final Throttler _skipThrottler = Throttler(delay: const Duration(milliseconds: 500));

  /// 操作锁（防止并发）
  final OperationLock _operationLock = OperationLock();

  /// 当前进行中的操作版本号
  int? _pendingOperationVersion;

  // ==================== 构造函数 ====================

  AudioProvider()
      : _playbackController = PlaybackController(),
        _playlistManager = UnifiedPlaylistManager(),
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

    // 加载播放列表
    await _loadPlaylist();

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
    );

    // 播放列表管理器回调
    _playlistManager.setOnPlaylistChanged(() {
      if (!_disposed) {
        _syncPlaylistProviders();
        notifyListeners();
      }
    });

    // 状态管理器回调
    _stateManager.setStateCallbacks(
      getCurrentIndex: () async => _playlistManager.currentIndex,
      getCurrentPlayable: () async => _playlistManager.currentPlayable,
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

  /// 加载播放列表（从数据库同步到 UnifiedPlaylistManager）
  Future<void> _loadPlaylist() async {
    await _playlistManager.syncFromLocal();
    _syncPlaylistProviders();
    notifyListeners();
  }

  /// 恢复播放状态
  Future<void> _restorePlaybackState() async {
    final savedPosition = await _playlistManager.restore();
    final wasOnline = await _playlistManager.getSavedOnlineState();

    final currentPlayable = _playlistManager.currentPlayable;
    if (currentPlayable != null) {
      // 更新元数据
      _title = currentPlayable.title;
      _artist = currentPlayable.artist ?? '未知艺术家';
      _albumArt = currentPlayable.coverData;

      // 设置在线状态
      _isCurrentOnline = wasOnline;
      if (currentPlayable.isOnline && currentPlayable is OnlinePlayable) {
        _currentOnlineAudio = currentPlayable.original;
        // ⭐ 修复：在线音频支持 seek（HTTP Range 请求）
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
    _syncPlaylistProviders();
    AppLogger.debug('AudioProvider', '播放状态已恢复');
  }

  // ==================== Getters（向后兼容）====================

  Duration get position => _playbackController.position;
  Duration get duration => _playbackController.duration ?? Duration.zero;
  bool get isPlaying => _playbackController.isPlaying;
  String get title => _title;
  String get artist => _artist;
  Uint8List? get albumArt => _albumArt;
  /// 本地播放列表（从 UnifiedPlaylistManager 获取）
  List<LocalAudio> get localPlaylist => _playlistManager.localPlaylist;
  List<PlayableAudio> get unifiedPlaylist => _playlistManager.playlist;
  int get currentIndex => _playlistManager.currentIndex;
  /// 当前本地音频（向后兼容）
  /// LocalPlayable 是包装类，需要通过 .original 获取原始 LocalAudio
  LocalAudio? get currentAudio {
    if (_isCurrentOnline) return null;
    final playable = _playlistManager.currentPlayable;
    return playable is LocalPlayable ? playable.original : null;
  }
  PlayableAudio? get currentPlayable => _playlistManager.currentPlayable;
  bool get isCurrentOnline => _isCurrentOnline;
  Audio? get currentOnlineAudio => _currentOnlineAudio;
  bool get isSeekable => _isSeekable;
  String? get currentContentType => _currentContentType;
  String? get currentBvid => _isCurrentOnline && _currentOnlineAudio != null ? _currentOnlineAudio!.id : null;
  String? get coverUrl => _isCurrentOnline && _currentOnlineAudio != null ? _currentOnlineAudio!.coverUrl : null;

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
        if (_playbackController.isIdle && _playlistManager.currentPlayable != null) {
          _playerStatusMessage = '正在加载...';
          notifyListeners();

          try {
            await _playPlayable(_playlistManager.currentPlayable!);
            _playerStatusMessage = '';
          } catch (e) {
            _playerStatusMessage = '播放失败: $e';
            _hasPlaybackError = true;
            notifyListeners();
            _nowPlayingProvider?.setError(_playerStatusMessage);
            rethrow;
          }
        } else if (_playbackController.isCompleted && !_isCurrentOnline) {
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
      _nowPlayingProvider?.setError(_playerStatusMessage);
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
    if (_playbackController.isCompleted && !_isCurrentOnline) {
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

    // 检查是否有下一首
    if (_playlistManager.hasNext) {
      AppLogger.info('AudioProvider', '有下一首，自动播放');
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
    if (_playlistManager.isEmpty) return;

    final nextIndex = _playlistManager.nextIndex;
    await playUnifiedAt(nextIndex);
  }

  /// 上一首
  Future<void> playPrevious() async {
    if (_disposed) return;
    if (_playlistManager.isEmpty) return;

    final previousIndex = _playlistManager.previousIndex;
    await playUnifiedAt(previousIndex);
  }

  /// 播放指定索引的本地音频
  Future<void> playAudio(int index) async {
    if (_disposed) return;
    final localPlaylist = _playlistManager.localPlaylist;
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
    if (_isCurrentOnline &&
        _currentOnlineAudio?.id == audio.id &&
        _playbackController.isPlaying) {
      return;
    }

    // ✅ 修复：清除之前的状态消息
    _playerStatusMessage = '正在加载...';
    _hasPlaybackError = false;
    _nowPlayingProvider?.clearError();
    notifyListeners();

    try {
      AppLogger.info('AudioProvider', '准备播放在线音频: ${audio.title}');

      // 构建代理 URL
      proxyUrl ??= _buildProxyUrl(audio.id, preferredFormat ?? 'auto');

      // 创建在线可播放对象
      final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

      // 设置在线状态
      _isCurrentOnline = true;
      _currentOnlineAudio = audio;
      // ⭐ 修复：在线音频也支持 seek
      _isSeekable = true;

      // 添加到播放列表并立即播放（会自动设置索引）
      await _playlistManager.add(playable, playImmediately: true);

      // 播放
      await _playPlayable(playable);

      // ⭐ 保存播放列表和索引
      await _playlistManager.save();

      // ✅ 修复：播放成功后清除状态消息
      _playerStatusMessage = '';

      AppLogger.info('AudioProvider', '在线播放开始: ${audio.title}');
      _syncPlaylistProviders();
      _syncMetadataProvider();
      notifyListeners();
    } catch (e) {
      AppLogger.error('AudioProvider', '在线播放失败: $e');
      _nowPlayingProvider?.setError('在线播放失败: $e');
      rethrow;
    }
  }

  /// 构建后端代理URL
  String _buildProxyUrl(String bvid, [String format = 'auto']) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
    return '$baseUrl/api/bilibili/proxy/audio/$bvid?format=$format';
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
    _syncPlaylistProviders();
    _syncMetadataProvider();
    notifyListeners();

    // 记录播放历史
    await _recordPlaybackStart(playable);

    // 启动进度更新定时器
    _startProgressUpdateTimer();

    notifyListeners();
  }

  /// 播放统一播放列表中指定索引的音频 - P0修复：原子状态更新
  Future<void> _playUnifiedAtIndex(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _playlistManager.length) return;

    final playable = _playlistManager[index];
    if (playable == null) return;

    // ✅ 修复：清除之前的状态消息，避免显示旧的状态
    _playerStatusMessage = '正在加载...';
    _hasPlaybackError = false;
    notifyListeners();

    // P0修复：开始新事务
    final transaction = _versionController.beginTransaction();
    _pendingOperationVersion = transaction.version;

    // 保存旧状态用于回滚
    final oldIndex = _playlistManager.currentIndex;
    final oldIsOnline = _isCurrentOnline;
    final oldOnlineAudio = _currentOnlineAudio;

    try {
      // P0修复：原子更新 - 先更新索引
      _playlistManager.setCurrentIndex(index, validate: false);
      transaction.setChange('index', oldIndex, index, () {
        _playlistManager.setCurrentIndex(oldIndex, validate: false);
      });

      // 设置在线状态（在线音频也支持 seek，使用流媒体）
      _isCurrentOnline = playable.isOnline;
      transaction.setChange('isOnline', oldIsOnline, _isCurrentOnline, () {
        _isCurrentOnline = oldIsOnline;
      });

      if (playable.isOnline && playable is OnlinePlayable) {
        _currentOnlineAudio = playable.original;
        _isSeekable = true;
      } else {
        _currentOnlineAudio = null;
        _isSeekable = true;
      }
      transaction.setChange('onlineAudio', oldOnlineAudio, _currentOnlineAudio, () {
        _currentOnlineAudio = oldOnlineAudio;
      });

      // P0修复：验证版本号仍然有效（防止操作过期）
      if (!_versionController.isVersionValid(transaction.version)) {
        AppLogger.warn('AudioProvider', '操作版本已过期，取消播放');
        transaction.rollback();
        return;
      }

      await _playPlayable(playable);

      // P0修复：再次验证版本号
      if (!_versionController.isVersionValid(transaction.version)) {
        AppLogger.warn('AudioProvider', '播放完成后版本已过期');
        transaction.rollback();
        return;
      }

      await _playlistManager.save();

      // ✅ 修复：播放成功后清除状态消息
      _playerStatusMessage = '';

      // 提交事务
      transaction.commit();
      _versionController.commitTransaction();

      _syncPlaylistProviders();
      _syncMetadataProvider();
      notifyListeners();
    } catch (e) {
      AppLogger.error('AudioProvider', '播放失败，回滚状态: $e');
      _nowPlayingProvider?.setError('播放失败: $e');
      transaction.rollback();
      _versionController.rollbackTransaction();
      rethrow;
    } finally {
      if (_pendingOperationVersion == transaction.version) {
        _pendingOperationVersion = null;
      }
    }
  }

  /// 播放统一播放列表中指定索引的音频（公开方法）- P0修复：添加防抖和版本控制
  Future<void> playUnifiedAt(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _playlistManager.length) return;

    // 如果点击的是当前曲目，切换播放/暂停
    if (_playlistManager.currentIndex == index) {
      await togglePlayPause();
      return;
    }

    // P0修复：使用防抖防止快速点击
    if (_playDebouncer.isActive) {
      AppLogger.debug('AudioProvider', '播放操作被防抖忽略');
      return;
    }

    // P0修复：使用节流器限制切歌频率
    bool shouldProceed = false;
    _skipThrottler(() {
      shouldProceed = true;
    });

    if (!shouldProceed) {
      AppLogger.debug('AudioProvider', '切歌操作被节流忽略');
      return;
    }

    // P0修复：使用操作锁防止并发
    await _operationLock.synchronized(() async {
      await _playUnifiedAtIndex(index);
    });
  }

  // ==================== 加载本地音频 ====================

  /// 加载音频文件并设置元数据 - P0修复：使用增量同步
  Future<void> loadAudio(String filePath) async {
    if (_disposed) return;

    try {
      // 设置为本地播放
      _isCurrentOnline = false;
      _currentOnlineAudio = null;
      _isSeekable = true;

      AppLogger.info('AudioProvider', '开始加载: $filePath');

      // 先设置加载状态，避免显示旧的播放信息
      _playerStatusMessage = '正在加载...';
      _hasPlaybackError = false;
      _nowPlayingProvider?.clearError();
      notifyListeners();

      // 提取文件元数据
      final metadata = await AudioMetadataLoader().extractFromFile(filePath);

      // 从本地播放列表查找数据库元数据
      final localPlaylist = _playlistManager.localPlaylist;
      final dbIndex = localPlaylist.indexWhere((a) => a.filePath == filePath);
      final dbMetadata = dbIndex != -1 ? {
        'title': localPlaylist[dbIndex].title,
        'artist': localPlaylist[dbIndex].artist,
        'albumArt': localPlaylist[dbIndex].albumArt,
      } : null;

      // 合并文件和数据库元数据
      final finalMetadata = AudioMetadataLoader().mergeMetadata(
        fileMetadata: metadata,
        dbMetadata: dbMetadata,
      );

      _title = finalMetadata['title'] as String;
      _artist = finalMetadata['artist'] as String;
      _albumArt = finalMetadata['cover'] as Uint8List?;

      // 确保当前播放信息立即更新
      _syncMetadataProvider();
      notifyListeners();

      // 设置音频源并播放
      await _playbackController.setFileSource(filePath);
      await _playbackController.play();

      // P0修复：如果音频不在播放列表中，添加到播放列表并同步
      if (dbIndex == -1) {
        final audio = LocalAudio(
          filePath: filePath,
          title: _title,
          artist: _artist,
          duration: 0,
          albumArt: _albumArt,
          url: finalMetadata['album'] as String? ?? '',
        );
        // 添加到播放列表并同步到数据库
        await _playlistManager.add(LocalPlayable(audio), syncLocal: true);
        // 立即刷新播放列表UI（避免覆盖当前索引）
        await _playlistManager.syncFromLocal();
        AppLogger.info('AudioProvider', '新音频已添加到播放列表: ${_title}');
      }

      // 更新统一播放列表索引到当前音频
      final newIndex = _playlistManager.indexOf('local_${filePath.hashCode}');
      if (newIndex != -1) {
        _playlistManager.setCurrentIndex(newIndex, validate: false);
      }

      // 启动定时保存
      _stateManager.startPositionSaveTimer();

      // 记录本地音频播放历史
      if (dbIndex != -1) {
        await _recordPlaybackStart(LocalPlayable(localPlaylist[dbIndex]));
      }

      // 确保UI更新（包括播放列表和当前播放信息）
      _playerStatusMessage = '';
      _syncPlaylistProviders();
      _syncMetadataProvider();
      notifyListeners();
    } catch (e) {
      AppLogger.error('AudioProvider', '加载失败: $e');
      _nowPlayingProvider?.setError('加载失败: $e');
      rethrow;
    }
  }

  // ==================== 播放列表管理 ====================

  /// 添加到播放列表
  Future<void> addToPlaylist(LocalAudio audio) async {
    await _playlistManager.add(
      LocalPlayable(audio),
      syncLocal: true,
    );
    await _loadPlaylist();
    _syncPlaylistProviders();
    notifyListeners();
  }

  /// 从播放列表移除
  Future<void> removeFromPlaylist(int id) async {
    await _playlistManager.removeById(id.toString(), syncLocal: true);
    await _loadPlaylist();
    _syncPlaylistProviders();
    notifyListeners();
  }

  /// 从统一播放列表移除
  Future<void> removeFromUnifiedPlaylist(int index) async {
    await _playlistManager.removeAt(index, syncLocal: true);

    // 如果删除的是当前播放项，重置状态
    if (_playlistManager.currentIndex == -1) {
      await _playbackController.stop();
      _resetMetadata();
    }

    _syncPlaylistProviders();
    _syncMetadataProvider();
    notifyListeners();
  }

  /// 清空统一播放列表
  Future<void> clearUnifiedPlaylist() async {
    await _playlistManager.clear(syncLocal: true);
    await _playbackController.stop();
    _resetMetadata();
    // 重新同步本地播放列表（因为 _playlist 指向的是不可修改的列表）
    await _loadPlaylist();
    _syncPlaylistProviders();
    _syncMetadataProvider();
    notifyListeners();
  }

  /// 重新加载播放列表
  Future<void> loadPlaylist() async {
    await _loadPlaylist();

    if (_playlistManager.localPlaylist.isEmpty) {
      await _playbackController.stop();
      _resetMetadata();
    }

    _syncPlaylistProviders();
    _syncMetadataProvider();
    notifyListeners();
  }

  /// 重置元数据
  void _resetMetadata() {
    _title = "无歌曲";
    _artist = "请添加音频开始播放";
    _albumArt = null;
    _isCurrentOnline = false;
    _currentOnlineAudio = null;
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
    _nowPlayingProvider?.clearError();
    notifyListeners();
  }

  // ==================== 子 Provider 注入 ====================

  void attachProviders({
    NowPlayingProvider? nowPlayingProvider,
    AudioPlaylistProvider? audioPlaylistProvider,
    AudioMetadataProvider? audioMetadataProvider,
  }) {
    _nowPlayingProvider = nowPlayingProvider;
    _audioPlaylistProvider = audioPlaylistProvider;
    _audioMetadataProvider = audioMetadataProvider;
    _syncPlaylistProviders();
    _syncMetadataProvider();
  }

  void _syncPlaylistProviders() {
    final playlist = _playlistManager.playlist;
    final currentIndex = _playlistManager.currentIndex;
    _nowPlayingProvider?.updateQueue(playlist, currentIndex: currentIndex);
    _audioPlaylistProvider?.updatePlaylist(playlist, currentIndex: currentIndex);
  }

  void _syncMetadataProvider() {
    _audioMetadataProvider?.updateMetadata(
      title: _title,
      artist: _artist,
      albumArt: _albumArt,
      playable: _playlistManager.currentPlayable,
    );
  }

  // ==================== 播放历史记录 ====================

  /// 记录播放开始
  Future<void> _recordPlaybackStart(PlayableAudio playable) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.keyToken);
    if (token == null || token.isEmpty) return;

    await _stateManager.recordPlaybackStart(
      playable,
      token: token,
      record: (data) async {
        // 直接发送 HTTP 请求记录播放历史（不依赖 PlayHistoryProvider）
        _sendHistoryRecord(
          token: data['token'] as String?,
          bvid: data['bvid'] as String?,
          localPath: data['localPath'] as String?,
          title: data['title'] as String,
          artist: data['artist'] as String?,
          duration: data['duration'] as int? ?? 0,
          coverUrl: data['coverUrl'] as String?,
          progress: data['progress'] as int? ?? 0,
        );
      },
    );
  }

  /// 播放进度更新定时器
  void _startProgressUpdateTimer() {
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      final token = prefs.getString(StorageKeys.keyToken);
      _stateManager.startProgressUpdateTimer(
        token: token,
        update: (data) async {
          // 直接发送 HTTP 请求更新播放进度
          _sendHistoryRecord(
            token: data['token'] as String?,
            bvid: _isCurrentOnline ? data['bvid'] as String? : null,
            localPath: _isCurrentOnline ? null : data['localPath'] as String?,
            title: data['title'] as String,
            artist: data['artist'] as String?,
            duration: data['duration'] as int? ?? 0,
            coverUrl: data['coverUrl'] as String?,
            progress: data['progress'] as int? ?? 0,
          );
        },
      );
    });
  }

  /// 发送播放历史记录到服务器
  ///
  /// P1 优化：直接使用 Dio 发送请求，不依赖 PlayHistoryProvider
  /// 降低依赖链深度：4 层 → 2 层
  Future<void> _sendHistoryRecord({
    required String? token,
    String? bvid,
    String? localPath,
    required String title,
    String? artist,
    int? duration,
    String? coverUrl,
    int progress = 0,
  }) async {
    if (token == null || token.isEmpty) return;
    if (bvid == null && localPath == null) return;

    try {
      _historyDio.options.headers['Authorization'] = 'Bearer $token';
      await _historyDio.post(
        '/history',
        data: {
          if (bvid != null) 'bvid': bvid,
          if (localPath != null) 'localPath': localPath,
          'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
          'progress': progress,
        },
      );
      AppLogger.debug('AudioProvider', '播放历史记录成功');
    } catch (e) {
      // 静默失败，不影响播放体验
      AppLogger.debug('AudioProvider', '记录播放失败（不影响播放）: $e');
    }
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
    _stateManager.stopProgressUpdateTimer();
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
