import 'dart:async';

import 'package:audio_session/audio_session.dart';
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
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:demo/presentation/providers/audio/playback_controller.dart';
import 'package:demo/presentation/providers/audio/unified_playlist_manager.dart';
import 'package:demo/presentation/providers/audio/playback_state_manager.dart';
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

  /// 元数据加载器
  final AudioMetadataLoader _metadataLoader;

  // ==================== 向后兼容状态 ====================

  /// PlayHistoryProvider 用于记录播放历史
  PlayHistoryProvider? _historyProvider;

  /// 本地播放列表（向后兼容）
  List<LocalAudio> _playlist = [];

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

  // ==================== 构造函数 ====================

  AudioProvider()
      : _playbackController = PlaybackController(),
        _playlistManager = UnifiedPlaylistManager(),
        _stateManager = PlaybackStateManager(),
        _metadataLoader = AudioMetadataLoader() {
    _init();
  }

  // ==================== 初始化 ====================

  Future<void> _init() async {
    // 配置音频会话
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

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
          notifyListeners();
        }
      },
      onProcessingStateChanged: (state) {
        if (!_disposed) {
          notifyListeners();
        }
      },
    );

    // 播放列表管理器回调
    _playlistManager.setOnPlaylistChanged(() {
      if (!_disposed) {
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

  /// 加载播放列表
  Future<void> _loadPlaylist() async {
    await _playlistManager.syncFromLocal();
    _playlist = _playlistManager.localPlaylist;
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
        _isSeekable = false;
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
    debugPrint('【AudioProvider】播放状态已恢复');
  }

  // ==================== Getters（向后兼容）====================

  Duration get position => _playbackController.position;
  Duration get duration => _playbackController.duration ?? Duration.zero;
  bool get isPlaying => _playbackController.isPlaying;
  String get title => _title;
  String get artist => _artist;
  Uint8List? get albumArt => _albumArt;
  List<LocalAudio> get playlist => _playlist;
  List<PlayableAudio> get unifiedPlaylist => _playlistManager.playlist;
  int get currentIndex => _playlistManager.currentIndex;
  LocalAudio? get currentAudio => _isCurrentOnline ? null : _playlistManager.currentPlayable as LocalAudio?;
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

  // ==================== 播放历史设置 ====================

  void setHistoryProvider(PlayHistoryProvider? provider) {
    _historyProvider = provider;
    debugPrint('【AudioProvider】PlayHistoryProvider 已${provider == null ? '清除' : '设置'}');
  }

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
      debugPrint('【AudioProvider】togglePlayPause 错误: $e');
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
    if (index < 0 || index >= _playlist.length) return;

    final audio = _playlist[index];
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

    try {
      debugPrint('【AudioProvider】准备播放在线音频: ${audio.title}');

      // 构建代理 URL
      proxyUrl ??= _buildProxyUrl(audio.id, preferredFormat ?? 'auto');

      // 创建在线可播放对象
      final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

      // 设置在线状态
      _isCurrentOnline = true;
      _currentOnlineAudio = audio;

      // 添加到播放列表并立即播放
      await _playlistManager.add(playable, playImmediately: true);

      // 播放
      await _playPlayable(playable);

      debugPrint('【AudioProvider】在线播放开始: ${audio.title}');
      notifyListeners();
    } catch (e) {
      debugPrint('【AudioProvider】在线播放失败: $e');
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

    if (_isCurrentOnline && playable.coverUrl != null) {
      _albumArt = null;
      // 异步加载封面
      _metadataLoader.preloadCover(playable.coverUrl!, (coverData) {
        if (coverData != null && !_disposed) {
          _albumArt = coverData;
          notifyListeners();
        }
      });
    } else {
      _albumArt = playable.coverData;
    }

    // 使用播放控制器设置音频源并播放
    await _playbackController.setSourceAndPlay(playable);

    // 记录播放历史
    await _recordPlaybackStart(playable);

    // 启动进度更新定时器
    _startProgressUpdateTimer();

    notifyListeners();
  }

  /// 播放统一播放列表中指定索引的音频
  Future<void> _playUnifiedAtIndex(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _playlistManager.length) return;

    final playable = _playlistManager[index];
    if (playable == null) return;

    // 设置在线状态
    _isCurrentOnline = playable.isOnline;
    if (playable.isOnline && playable is OnlinePlayable) {
      _currentOnlineAudio = playable.original;
      _isSeekable = false;
    } else {
      _currentOnlineAudio = null;
      _isSeekable = true;
    }

    await _playPlayable(playable);
    await _playlistManager.save();

    notifyListeners();
  }

  /// 播放统一播放列表中指定索引的音频（公开方法）
  Future<void> playUnifiedAt(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _playlistManager.length) return;

    // 如果点击的是当前曲目，切换播放/暂停
    if (_playlistManager.currentIndex == index) {
      await togglePlayPause();
      return;
    }

    await _playUnifiedAtIndex(index);
  }

  // ==================== 加载本地音频 ====================

  /// 加载音频文件并设置元数据
  Future<void> loadAudio(String filePath) async {
    if (_disposed) return;

    try {
      // 设置为本地播放
      _isCurrentOnline = false;
      _currentOnlineAudio = null;
      _isSeekable = true;

      debugPrint('【AudioProvider】开始加载: $filePath');

      // 提取元数据
      final metadata = await _metadataLoader.extractFromFile(filePath);

      // 合并元数据
      final dbIndex = _playlist.indexWhere((a) => a.filePath == filePath);
      final dbMetadata = dbIndex != -1 ? {
        'title': _playlist[dbIndex].title,
        'artist': _playlist[dbIndex].artist,
        'albumArt': _playlist[dbIndex].albumArt,
      } : null;

      final finalMetadata = _metadataLoader.mergeMetadata(
        fileMetadata: metadata,
        dbMetadata: dbMetadata,
      );

      _title = finalMetadata['title'] as String;
      _artist = finalMetadata['artist'] as String;
      _albumArt = finalMetadata['cover'] as Uint8List?;

      // 设置音频源并播放
      await _playbackController.setFileSource(filePath);
      await _playbackController.play();

      // 更新或添加到播放列表
      if (dbIndex != -1) {
        _playlist[dbIndex] = _playlist[dbIndex].copyWith(
          title: _title,
          artist: _artist,
          url: finalMetadata['album'] as String? ?? '',
          albumArt: _albumArt,
        );
      } else {
        final audio = LocalAudio(
          filePath: filePath,
          title: _title,
          artist: _artist,
          duration: 0,
          albumArt: _albumArt,
          url: finalMetadata['album'] as String? ?? '',
        );
        await addToPlaylist(audio);
      }

      // 启动定时保存
      _stateManager.startPositionSaveTimer();

      // 记录本地音频播放历史
      final playable = LocalPlayable(
        dbIndex != -1 ? _playlist[dbIndex] : _playlist.last,
      );
      await _recordPlaybackStart(playable);

      notifyListeners();
    } catch (e) {
      debugPrint('【AudioProvider】加载失败: $e');
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
    notifyListeners();
  }

  /// 从播放列表移除
  Future<void> removeFromPlaylist(int id) async {
    await _playlistManager.removeById(id.toString(), syncLocal: true);
    await _loadPlaylist();
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

    notifyListeners();
  }

  /// 清空统一播放列表
  Future<void> clearUnifiedPlaylist() async {
    await _playlistManager.clear(syncLocal: true);
    await _playbackController.stop();
    _resetMetadata();
    _playlist.clear();
    notifyListeners();
  }

  /// 重新加载播放列表
  Future<void> loadPlaylist() async {
    await _loadPlaylist();

    if (_playlist.isEmpty) {
      await _playbackController.stop();
      _resetMetadata();
    }

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
    notifyListeners();
  }

  // ==================== 播放历史记录 ====================

  /// 记录播放开始
  Future<void> _recordPlaybackStart(PlayableAudio playable) async {
    if (_historyProvider == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.keyToken);

    await _stateManager.recordPlaybackStart(
      playable,
      token: token,
      record: (data) async {
        // 调用 PlayHistoryProvider
        if (_historyProvider != null) {
          if (playable.isOnline) {
            await _historyProvider!.recordPlay(
              token: data['token'] as String?,
              bvid: data['bvid'] as String?,
              title: data['title'] as String,
              artist: data['artist'] as String?,
              duration: data['duration'] as int? ?? 0,
              coverUrl: data['coverUrl'] as String?,
              progress: data['progress'] as int? ?? 0,
            );
          } else {
            await _historyProvider!.recordPlay(
              token: data['token'] as String?,
              bvid: null,
              title: data['title'] as String,
              artist: data['artist'] as String?,
              duration: data['duration'] as int? ?? 0,
              coverUrl: null,
              progress: data['progress'] as int? ?? 0,
              localPath: data['localPath'] as String?,
            );
          }
        }
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
          // 调用 PlayHistoryProvider 更新进度
          if (_historyProvider != null) {
            if (_isCurrentOnline && _currentOnlineAudio != null) {
              await _historyProvider!.recordPlay(
                token: data['token'] as String?,
                bvid: data['bvid'] as String?,
                title: data['title'] as String,
                artist: data['artist'] as String?,
                duration: data['duration'] as int? ?? 0,
                coverUrl: data['coverUrl'] as String?,
                progress: data['progress'] as int? ?? 0,
              );
            } else {
              await _historyProvider!.recordPlay(
                token: data['token'] as String?,
                localPath: data['localPath'] as String?,
                title: data['title'] as String,
                artist: data['artist'] as String?,
                duration: data['duration'] as int? ?? 0,
                progress: data['progress'] as int? ?? 0,
              );
            }
          }
        },
      );
    });
  }

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // 停止定时器
    _stateManager.stopPositionSaveTimer();
    _stateManager.stopProgressUpdateTimer();
    _stateManager.dispose();

    // 取消订阅
    _positionSub?.cancel();
    _durationSub?.cancel();

    // 销毁播放控制器
    _playbackController.dispose();

    // 销毁元数据加载器
    _metadataLoader.dispose();

    super.dispose();
  }

  // ==================== 停止方法 ====================

  /// 停止播放
  Future<void> stop() async {
    await _playbackController.stop();
    _stateManager.stopPositionSaveTimer();
  }
}
