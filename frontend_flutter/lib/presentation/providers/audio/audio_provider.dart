import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/core/constants/api_constants.dart';
import 'package:demo/core/constants/storage_constants.dart';
import 'package:demo/data/managers/playlist_manager.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';

/// 音频播放状态管理
///
/// Phase 2A: 新增播放进度持久化功能
/// Phase 2: 新增在线音频播放支持
/// Phase 5: 从 audioplayers 迁移到 just_audio（2026-01-22）
/// 迁移原因：just_audio 有专门的 ProcessingState.buffering 状态，精确检测无需推断
class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  // Phase 2 遗留问题: PlayHistoryProvider 用于记录播放历史
  PlayHistoryProvider? _historyProvider;

  // 本地播放列表（向后兼容）
  List<LocalAudio> _playlist = [];

  // Phase 2: 统一播放列表（支持本地和在线混合播放）
  List<PlayableAudio> _unifiedPlaylist = [];
  int _currentIndex = -1;

  // 播放状态
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  String _title = "未知标题";
  String _artist = "未知艺术家";
  Uint8List? _albumArt;

  // Phase 2: 在线播放相关状态
  Audio? _currentOnlineAudio;
  bool _isCurrentOnline = false;

  // P0 修复: 播放启动标志（防止 stream 事件覆盖正在启动的播放状态）
  bool _isStartingPlayback = false;
  DateTime? _playbackStartTime; // 记录播放启动时间

  // Phase 2: 音频流能力（从后端获取）
  bool _isSeekable = true; // 默认支持 seek（本地音频）
  String? _currentContentType; // 当前音频的 Content-Type

  // P0 修复: 保存防抖（防止短时间内多次保存）
  Timer? _saveDebounceTimer;
  static const Duration _saveDebounceDelay = Duration(milliseconds: 500);
  bool _isSaving = false; // P0 修复: 防止重复保存

  // Phase 5: just_audio 状态（不再需要手动推断缓冲）
  // just_audio 的 ProcessingState 直接提供精确的缓冲状态

  // 订阅
  late StreamSubscription _positionSub;
  late StreamSubscription _durationSub;
  late StreamSubscription _playerStateSub;

  // Phase 2A: 播放状态持久化
  Timer? _savePositionTimer;
  static const Duration _saveInterval = Duration(seconds: 5);

  // 防止销毁后回调执行
  bool _disposed = false;

  // 播放操作锁（防止快速点击导致的并发播放）
  bool _isPlayingOperation = false;
  Completer? _playOperationCompleter;

  // Phase 5 修复: 播放操作去抖（防止极短时间内重复触发）
  DateTime? _lastOperationTime;
  static const Duration _minOperationInterval = Duration(milliseconds: 300);

  // Phase 3B: 播放控制状态（音量/倍速）
  /// 播放音量（0.0 - 1.0）
  double _volume = 1.0;  // 默认音量 100%
  double _speed = 1.0;   // 默认倍速 1.0x

  // ✅ 新增：缓冲状态（用于 m4s 转换时显示进度）
  bool _isBuffering = false;  // 是否正在缓冲/转换中
  double _bufferingProgress = 0.0; // 缓冲进度（0-100）

  /// 播放音量（0.0 - 1.0）
  double get volume => _volume;

  /// 播放倍速（0.5x - 2.0x）
  double get speed => _speed;

  /// 缓冲进度（0-100）
  double get bufferingProgress => _bufferingProgress;

  AudioProvider() {
    _init();
  }

  // ==================== 初始化 ====================

  Future<void> _init() async {
    // 配置音频会话
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    // Phase 3B: 加载用户播放设置（音量/倍速）
    await _loadPlaybackSettings();

    // 初始化监听器
    _initListeners();

    // 加载播放列表
    await _loadPlaylist();

    // Phase 2 遗留问题: 恢复统一播放列表状态
    await _restoreUnifiedPlaylist();
  }

  void _initListeners() {
    // 位置变化
    _positionSub = _player.positionStream.listen(
      (p) {
        if (_disposed) return;
        _position = p;
        notifyListeners();
      },
      onError: (e) {
        if (!_disposed) debugPrint('【AudioProvider】位置监听错误: $e');
      },
    );

    // 时长变化
    _durationSub = _player.durationStream.listen(
      (d) {
        if (_disposed) return;
        _duration = d ?? Duration.zero;
        notifyListeners();
      },
      onError: (e) {
        if (!_disposed) debugPrint('【AudioProvider】时长监听错误: $e');
      },
    );

    // 处理播放状态变化（合并订阅：同时处理 playing 和 completed 状态）
    // P0 修复: 在播放启动期间，不覆盖手动设置的 _isPlaying 状态
    _playerStateSub = _player.playerStateStream.listen(
      (state) {
        if (_disposed) return;

        // P0 修复: 播放启动保护窗口（2秒内不覆盖手动设置的播放状态）
        if (_isStartingPlayback && !state.playing) {
          final elapsed = _playbackStartTime != null
              ? DateTime.now().difference(_playbackStartTime!)
              : Duration.zero;

          if (elapsed.inSeconds < 2) {
            debugPrint('【AudioProvider】播放启动保护中，跳过 stream 状态更新（已过 ${elapsed.inMilliseconds}ms，状态: ${state.playing}, 处理: ${state.processingState}）');
            return;
          } else {
            // 保护窗口已过，关闭保护
            _isStartingPlayback = false;
            _playbackStartTime = null;
            debugPrint('【AudioProvider】播放启动保护窗口已结束');
          }
        }

        _isPlaying = state.playing;
        // 播放完成时更新状态
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
        notifyListeners();
      },
      onError: (e) {
        if (!_disposed) debugPrint('【AudioProvider】播放状态监听错误: $e');
      },
    );
  }

  /// 加载播放列表（从数据库）
  Future<void> _loadPlaylist() async {
    final db = PlaylistManager();
    _playlist = await db.getAllAudios();
    _syncUnifiedPlaylist();  // 同步统一播放列表
    notifyListeners();
  }

  /// 同步统一播放列表
  /// 确保本地音频在两个列表中保持一致
  void _syncUnifiedPlaylist() {
    // 移除统一列表中所有的本地音频
    _unifiedPlaylist.removeWhere((p) => p is LocalPlayable);
    // 重新添加所有本地音频
    for (final audio in _playlist) {
      _unifiedPlaylist.add(LocalPlayable(audio));
    }
    debugPrint('【AudioProvider】统一播放列表已同步，总数: ${_unifiedPlaylist.length}');
  }

  /// 公开方法：重新加载播放列表
  /// Phase 2A: 用于拖拽排序后刷新
  /// Phase 5 修复: 清空列表时重置播放器状态
  Future<void> loadPlaylist() async {
    await _loadPlaylist();

    // 如果播放列表为空，重置播放器状态
    if (_playlist.isEmpty) {
      await _player.stop();
      _title = "无歌曲";
      _artist = "请添加本地音频开始播放";
      _albumArt = null;
      _currentIndex = -1;
      _isPlaying = false;
      _isCurrentOnline = false;
      _currentOnlineAudio = null;
      _stopPositionSaveTimer();
      notifyListeners();
      debugPrint('【AudioProvider】播放列表已清空，播放器状态已重置');
    }
  }

  // ==================== Phase 2A: 播放状态持久化 ====================

  /// 启动播放位置定时保存
  void _startPositionSaveTimer() {
    _savePositionTimer?.cancel();
    _savePositionTimer = Timer.periodic(_saveInterval, (_) {
      if (_currentIndex >= 0 && _isPlaying) {
        _savePlaybackState();
      }
    });
    debugPrint('【AudioProvider】播放位置定时保存已启动');
  }

  /// 停止定时保存
  void _stopPositionSaveTimer() {
    _savePositionTimer?.cancel();
    _savePositionTimer = null;
    debugPrint('【AudioProvider】播放位置定时保存已停止');
  }

  /// 保存播放状态到数据库
  ///
  /// Phase 2 遗留问题: 修复 - 使用 _unifiedPlaylist 而不是 _playlist
  /// 对于本地音频保存到数据库，对于在线音频通过 _saveUnifiedPlaylist() 保存
  Future<void> _savePlaybackState() async {
    if (_currentIndex < 0 || _unifiedPlaylist.isEmpty) return;

    final playable = _unifiedPlaylist[_currentIndex];

    // 对于本地音频，保存到数据库（向后兼容）
    if (playable is LocalPlayable) {
      final audio = playable.original;
      if (audio.id == null) {
        debugPrint('【AudioProvider】音频ID为空，无法保存播放状态');
        return;
      }
      final db = PlaylistManager();
      await db.savePlaybackState(
        audioId: audio.id!,
        position: _position.inSeconds,
        currentIndex: _currentIndex,
      );
    }

    // 对于在线音频或统一播放列表，使用 _saveUnifiedPlaylist()
    await _saveUnifiedPlaylist();
  }

  /// 恢复播放状态（应用启动时调用）

  // ==================== Phase 2 遗留问题: 统一播放列表持久化 ====================

  /// 保存统一播放列表到 SharedPreferences
  ///
  /// 保存内容包括：
  /// - 统一播放列表（包含本地和在线音频）
  /// - 当前播放索引
  /// - 当前播放位置
  /// - 是否为在线音频
  ///
  /// P0 修复: 添加防抖机制，避免短时间内多次保存
  /// P0 修复: 使用 _isSaving 标志防止重复保存
  Future<void> _saveUnifiedPlaylist() async {
    // 如果正在保存，取消之前的保存计划
    _saveDebounceTimer?.cancel();

    // 延迟执行保存，合并短时间内的多次调用
    _saveDebounceTimer = Timer(_saveDebounceDelay, () async {
      if (_disposed || _isSaving) return;

      _isSaving = true;
      try {
        final prefs = await SharedPreferences.getInstance();

        // 序列化播放列表
        final playlistJson = jsonEncode(
          _unifiedPlaylist.map((a) => a.toMap()).toList(),
        );
        await prefs.setString(StorageKeys.unifiedPlaylist, playlistJson);
        await prefs.setInt(StorageKeys.currentPlaylistIndex, _currentIndex);
        await prefs.setInt(StorageKeys.currentPlaybackPosition, _position.inSeconds);
        await prefs.setBool(StorageKeys.isCurrentOnline, _isCurrentOnline);

        debugPrint('【AudioProvider】统一播放列表已保存: ${_unifiedPlaylist.length} 首, 索引: $_currentIndex');
      } catch (e) {
        debugPrint('【AudioProvider】保存统一播放列表失败: $e');
      } finally {
        _isSaving = false;
      }
    });
  }

  /// 从 SharedPreferences 恢复统一播放列表
  ///
  /// 恢复内容包括：
  /// - 统一播放列表（重建 LocalPlayable 和 OnlinePlayable）
  /// - 当前播放索引和位置
  /// - 在线/本地播放状态
  Future<void> _restoreUnifiedPlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistJson = prefs.getString(StorageKeys.unifiedPlaylist);

      if (playlistJson == null || playlistJson.isEmpty) {
        debugPrint('【AudioProvider】没有保存的统一播放列表');
        return;
      }

      // 反序列化播放列表
      final data = jsonDecode(playlistJson) as List;
      final restoredPlaylist = <PlayableAudio>[];

      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final playableType = map['playableType'] as String?;

        if (playableType == 'online') {
          restoredPlaylist.add(OnlinePlayable.fromMap(map));
        } else {
          // 默认为本地音频
          restoredPlaylist.add(LocalPlayable.fromMap(map));
        }
      }

      // 获取保存的状态
      final savedIndex = prefs.getInt(StorageKeys.currentPlaylistIndex) ?? -1;
      final wasOnline = prefs.getBool(StorageKeys.isCurrentOnline) ?? false;

      // 验证索引有效性
      if (savedIndex >= 0 && savedIndex < restoredPlaylist.length) {
        _unifiedPlaylist = restoredPlaylist;
        _currentIndex = savedIndex;
        _isCurrentOnline = wasOnline;

        final playable = _unifiedPlaylist[_currentIndex];

        // 更新元数据
        _title = playable.title;
        _artist = playable.artist ?? '未知艺术家';
        _albumArt = playable.coverData;

        // 设置在线状态
        if (playable.isOnline && playable is OnlinePlayable) {
          _currentOnlineAudio = playable.original;
        } else {
          _currentOnlineAudio = null;
        }

      } else {
        // 索引无效，只恢复播放列表
        _unifiedPlaylist = restoredPlaylist;
        _currentIndex = -1;
        debugPrint('【AudioProvider】统一播放列表已恢复，但索引无效: $savedIndex');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('【AudioProvider】恢复统一播放列表失败: $e');
    }
  }

  // ==================== Phase 5: just_audio 精确状态检测 ====================

  /// 是否正在加载（ProcessingState.loading）
  bool get isLoading {
    return _player.processingState == ProcessingState.loading;
  }

  /// 是否正在缓冲（ProcessingState.buffering）
  /// ✅ just_audio 直接提供精确的缓冲状态，无需推断
  bool get isBuffering {
    return _player.processingState == ProcessingState.buffering;
  }

  /// 是否已就绪（可播放）
  bool get isReady {
    return _player.processingState == ProcessingState.ready;
  }

  /// 是否空闲（ProcessingState.idle）
  bool get isIdle {
    return _player.processingState == ProcessingState.idle;
  }

  /// 是否完成（ProcessingState.completed）
  bool get isCompleted {
    return _player.processingState == ProcessingState.completed;
  }

  /// 是否正在跳转（根据状态判断）
  bool get isSeeking {
    // just_audio 没有专门的 seeking 状态，我们通过用户操作来判断
    return false;
  }

  /// 是否正在加载（缓冲或跳转）
  /// ✅ 精确状态：加载或缓冲中
  bool get isLoadingOrBuffering {
    return isLoading || isBuffering;
  }

  // ==================== Getters ====================

  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  String get title => _title;
  String get artist => _artist;
  Uint8List? get albumArt => _albumArt;
  List<LocalAudio> get playlist => _playlist;

  // Phase 2: 统一播放列表访问器
  List<PlayableAudio> get unifiedPlaylist => _unifiedPlaylist;

  int get currentIndex => _currentIndex;

  // 兼容旧代码：本地音频
  LocalAudio? get currentAudio => _isCurrentOnline ? null : (_currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null);

  // Phase 2: 当前可播放音频（统一接口）
  PlayableAudio? get currentPlayable => _currentIndex >= 0 && _currentIndex < _unifiedPlaylist.length ? _unifiedPlaylist[_currentIndex] : null;

  // Phase 2: 是否正在播放在线音频
  bool get isCurrentOnline => _isCurrentOnline;

  // Phase 2: 当前在线音频实体
  Audio? get currentOnlineAudio => _currentOnlineAudio;

  // Phase 2: 当前音频是否支持 seek/断点续传
  bool get isSeekable => _isSeekable;

  // Phase 2: 当前音频的 Content-Type
  String? get currentContentType => _currentContentType;

  // Phase 2: 当前音频的 BVid（如果是在线音频）
  String? get currentBvid {
    if (_isCurrentOnline && _currentOnlineAudio != null) {
      return _currentOnlineAudio!.id;
    }
    return null;
  }

  // 当前音频的封面 URL（在线音频）
  String? get coverUrl {
    if (_isCurrentOnline && _currentOnlineAudio != null) {
      return _currentOnlineAudio!.coverUrl;
    }
    return null;
  }

  // Phase 2 遗留问题: PlayHistoryProvider setter
  /// 设置播放历史 Provider（用于记录播放历史）
  void setHistoryProvider(PlayHistoryProvider? provider) {
    _historyProvider = provider;
    debugPrint('【AudioProvider】PlayHistoryProvider 已${provider == null ? '清除' : '设置'}');
  }

  // ==================== 播放控制 ====================

  /// 检查操作是否过于频繁（去抖）
  /// 返回 true 表示可以继续执行，false 表示应该忽略此次操作
  bool _checkOperationInterval() {
    final now = DateTime.now();
    if (_lastOperationTime != null &&
        now.difference(_lastOperationTime!) < _minOperationInterval) {
      debugPrint('【AudioProvider】操作过于频繁，已忽略');
      return false;
    }
    _lastOperationTime = now;
    return true;
  }

  /// 加载音频文件并设置元数据
  ///
  /// 元数据优先级: 文件内嵌元数据 > 数据库 > 文件名提取
  Future<void> loadAudio(String filePath) async {
    // 等待之前的播放操作完成
    if (_isPlayingOperation) {
      debugPrint('【loadAudio】等待上一次播放操作完成...');
      await _playOperationCompleter?.future;
    }

    // 设置播放操作锁
    _isPlayingOperation = true;
    _playOperationCompleter = Completer();

    try {
      // 重置状态（本地音频不需要缓冲，默认支持 seek）
      _isCurrentOnline = false;
      _currentOnlineAudio = null;
      _isSeekable = true; // 本地音频默认支持 seek
      _currentContentType = null;

      debugPrint('【loadAudio】开始加载: $filePath');

      // 直接设置新音频源（不再先 stop，让 MPV 自动处理状态切换）
      // 这比先 stop 再设置更可靠，避免了 idle 状态等待超时问题
      debugPrint('【loadAudio】直接设置本地音频源');
      try {
        await _player.setAudioSource(AudioSource.file(filePath));
      } catch (e) {
        // 如果设置失败，先 stop 再重试
        debugPrint('【loadAudio】首次设置失败，尝试先 stop: $e');
        await _player.stop();
        await Future.delayed(const Duration(milliseconds: 200));
        await _player.setAudioSource(AudioSource.file(filePath));
      }

      String? titleFromDb;
      String? artistFromDb;
      Uint8List? artFromDb;
      String fileTitle = '';
      String fileArtist = '';
      String fileAlbum = '';
      Uint8List? fileCover;

      // 检查数据库中是否已有此文件的元数据
      final existingIndex = _playlist.indexWhere((a) => a.filePath == filePath);
      if (existingIndex != -1) {
        final existingAudio = _playlist[existingIndex];
        titleFromDb = existingAudio.title;
        artistFromDb = existingAudio.artist;
        artFromDb = existingAudio.albumArt;
        debugPrint('【loadAudio】数据库中找到: $titleFromDb - $artistFromDb');
      }

       // ✅ 从文件解析元数据（使用 compute() 移到后台线程）
       try {
         // 快速文件存在性检查（保持同步，因为很快）
         if (!File(filePath).existsSync()) {
           debugPrint('【loadAudio】文件不存在: $filePath');
           throw Exception('文件不存在');
         }

         // ✅ 使用 compute() 在 isolate 中提取元数据（避免阻塞 UI）
         final metadataResult = await compute(_extractMetadataIsolate, filePath);

         // ✅ 安全的类型转换
         fileTitle = (metadataResult['title'] as String?) ?? '';
         fileArtist = (metadataResult['artist'] as String?) ?? '';
         fileAlbum = (metadataResult['album'] as String?) ?? '';
         fileCover = metadataResult['cover'] as Uint8List?;

         if (fileCover != null && fileCover!.isNotEmpty) {
           debugPrint('【loadAudio】找到封面: ${fileCover.length} 字节');
         }
       } catch (e, s) {
         debugPrint('【loadAudio】元数据解析失败: $e\n$s');
       }

      // 合并策略: 文件元数据 > 数据库 > 文件名
      final dbHasValidTitle = titleFromDb != null &&
          titleFromDb != '未知标题' &&
          titleFromDb.isNotEmpty;
      final dbHasValidArtist = artistFromDb != null &&
          artistFromDb != '未知艺术家' &&
          artistFromDb.isNotEmpty;

      final pathMetadata = _extractMetadataFromPath(filePath);

      _title = (fileTitle.isNotEmpty ? fileTitle : null) ??
               (dbHasValidTitle ? titleFromDb : null) ??
               pathMetadata['title']!;
      _artist = (fileArtist.isNotEmpty ? fileArtist : null) ??
                (dbHasValidArtist ? artistFromDb : null) ??
                pathMetadata['artist']!;
      _albumArt = fileCover ?? artFromDb;

      debugPrint('【loadAudio】最终元数据: $_title - $_artist');

      // 验证文件存在
      final file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('【loadAudio】文件不存在: $filePath');
        throw Exception('文件不存在: ${filePath.split(RegExp(r'[\\/]')).last}');
      }

      // 设置音频源并播放
      if (_disposed) return;
      _position = Duration.zero;
      _duration = Duration.zero;

      debugPrint('【loadAudio】开始播放: $filePath');

      // 使用 AudioSource.file() 播放本地文件（更好地处理中文路径）
      await _player.setAudioSource(AudioSource.file(filePath));
      await _player.play();

      // 更新或添加到播放列表
      if (_disposed) return;
      if (existingIndex != -1) {
        _playlist[existingIndex] = _playlist[existingIndex].copyWith(
          title: _title,
          artist: _artist,
          url: fileAlbum.isNotEmpty ? fileAlbum : "",
          albumArt: _albumArt,
        );
        _currentIndex = existingIndex;
      } else {
        final audio = LocalAudio(
          filePath: filePath,
          title: _title,
          artist: _artist,
          duration: 0,
          albumArt: _albumArt,
          url: fileAlbum,
        );
        await addToPlaylist(audio);
        _currentIndex = _playlist.length - 1;
      }

      // 启动定时保存
      _startPositionSaveTimer();

      // 记录本地音频播放历史
      _recordPlaybackStart(LocalPlayable(_playlist[_currentIndex]));

      notifyListeners();
    } catch (e) {
      debugPrint('【loadAudio】加载失败: $e');
      rethrow;
    } finally {
      // 释放播放操作锁
      _isPlayingOperation = false;
      _playOperationCompleter?.complete();
    }
  }

  /// 播放/暂停
  /// Phase 2A: 添加播放状态保存和定时器控制
  /// Phase5 修复: 立即更新状态避免快速点击时的延迟 + 去抖
  /// Phase5 修复: 在线音频流不支持 seek，避免 MPV 错误
  /// 修复: 如果播放器 idle 且有当前曲目，先加载音频源再播放
  Future<void> togglePlayPause() async {
    if (_disposed) return;
    if (!_checkOperationInterval()) return; // 去抖检查

    try {
      if (_isPlaying) {
        await _player.pause();
        _isPlaying = false; // 立即更新状态
        _stopPositionSaveTimer(); // 暂停时停止定时器
        await _savePlaybackState(); // 暂停时立即保存
        notifyListeners();
      } else {
        // 检查播放器是否已设置音频源
        if (_player.processingState == ProcessingState.idle && 
            _currentIndex >= 0 && 
            _currentIndex < _unifiedPlaylist.length) {
          // 播放器没有设置音频源，需要先加载当前曲目
          final playable = _unifiedPlaylist[_currentIndex];
          debugPrint('【AudioProvider】播放器 idle，加载当前曲目: ${playable.title}');
          await _playPlayable(playable);
        } else {
          // 播放器已就绪，直接播放
          // 仅本地音频支持 seek，在线流媒体会失败
          final currentIsOnline = _currentIndex >= 0 &&
                                 _currentIndex < _unifiedPlaylist.length &&
                                 _unifiedPlaylist[_currentIndex].isOnline;
          if (_player.processingState == ProcessingState.completed && !currentIsOnline) {
            await _player.seek(Duration.zero);
          }
          await _player.play();
        }
        _isPlaying = true; // 立即更新状态
        _startPositionSaveTimer(); // 播放时启动定时器
        notifyListeners();
      }
    } catch (e) {
      debugPrint('【AudioProvider】togglePlayPause 错误: $e');
      rethrow;
    }
  }
  /// Phase 5 修复: 立即更新状态避免快速点击时的延迟 + 去抖
  /// Phase 5 修复: 在线音频流不支持 seek，避免 MPV 错误
  Future<void> pause() async {
    if (_disposed) return;
    await _player.pause();
    _isPlaying = false; // 立即更新状态
    _stopPositionSaveTimer();
    _stopProgressUpdateTimer(); // Phase 2 遗留问题: 停止进度更新
    await _savePlaybackState();
    notifyListeners();
  }

  /// 恢复播放
  /// Phase 5 修复: 在线音频流不支持 seek，避免 MPV 错误
  Future<void> resume() async {
    if (_disposed) return;
    // 仅本地音频支持 seek，在线流媒体会失败
    final currentIsOnline = _currentIndex >= 0 &&
                           _currentIndex < _unifiedPlaylist.length &&
                           _unifiedPlaylist[_currentIndex].isOnline;
    if (_player.processingState == ProcessingState.completed && !currentIsOnline) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
    _isPlaying = true; // 立即更新状态（与 pause() 保持一致）
    _startPositionSaveTimer();
    _startProgressUpdateTimer(); // Phase 2 遗留问题: 启动进度更新
    notifyListeners();
  }

  /// 跳转到指定位置
  /// Phase 5 修复: 在线音频流不支持 seek，避免 MPV 错误
  /// Phase 6 优化: 根据后端返回的 seekable 能力动态决定是否执行 seek
  /// Phase 7 修复: 不抛出异常，改为静默返回，避免 UI 崩溃
  Future<void> seek(Duration position) async {
    if (_disposed) return;

    // 检查当前音频是否支持 seek
    if (!_isSeekable) {
      debugPrint('【AudioProvider】当前音频不支持 seek（转码流或缓存流），跳过跳转操作');
      return; // 静默返回，不抛出异常
    }

    try {
      debugPrint('【AudioProvider】开始跳转到: ${position.inSeconds}秒');

      await _player.seek(position);
      // just_audio 会自动处理状态恢复
    } catch (e) {
      debugPrint('【AudioProvider】跳转失败: $e');
      // 不抛出异常，静默处理
    }
  }

  /// 播放指定索引的音频
  /// Phase 2A: 添加定时保存启动
  /// Phase 5 修复: 添加去抖检查
  /// 注意: loadAudio 内部已处理播放历史记录，此处不再重复调用
  Future<void> playAudio(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _playlist.length) return;
    if (!_checkOperationInterval()) return; // 去抖检查

    final audio = _playlist[index];
    await loadAudio(audio.filePath); // loadAudio 已经处理了播放锁、定时器和历史记录
    _currentIndex = _playlist.indexWhere((a) => a.filePath == audio.filePath);

    notifyListeners();
  }

  // ==================== Phase 2 遗留问题: 播放历史记录 ====================

  /// 记录播放开始（播放时调用）
  ///
  /// 记录当前播放的音频到播放历史
  Future<void> _recordPlaybackStart(PlayableAudio playable) async {
    if (_historyProvider == null) {
      debugPrint('【AudioProvider】PlayHistoryProvider 未设置，跳过播放历史记录');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.keyToken);

      if (playable.isOnline && playable is OnlinePlayable) {
        // 记录在线音频
        await _historyProvider!.recordPlay(
          token: token,
          bvid: playable.id,
          title: playable.title,
          artist: playable.artist,
          duration: playable.duration,
          coverUrl: playable.coverUrl,
          progress: 0,
        );
        debugPrint('【AudioProvider】已记录在线音频播放历史: ${playable.title}');
      } else if (playable is LocalPlayable) {
        // 记录本地音频
        final local = playable.original;
        await _historyProvider!.recordPlay(
          token: token,
          bvid: null, // 本地音频没有 bvid
          title: local.title,
          artist: local.artist,
          duration: local.duration,
          coverUrl: null,
          progress: 0,
          localPath: local.filePath, // 使用 localPath 参数
        );
        debugPrint('【AudioProvider】已记录本地音频播放历史: ${local.title}');
      }
    } catch (e) {
      debugPrint('【AudioProvider】记录播放历史失败: $e');
    }
  }

  /// 更新播放进度（定期调用，每30秒）
  ///
  /// 更新播放历史中的播放进度
  Future<void> _updatePlaybackProgress() async {
    if (_historyProvider == null || _currentIndex < 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.keyToken);
      if (token == null || token.isEmpty) return; // 游客模式不更新进度

      final playable = _unifiedPlaylist[_currentIndex];
      final progress = _position.inSeconds;

      if (playable.isOnline && playable is OnlinePlayable) {
        await _historyProvider!.recordPlay(
          token: token,
          bvid: playable.id,
          title: playable.title,
          artist: playable.artist,
          duration: playable.duration,
          coverUrl: playable.coverUrl,
          progress: progress,
        );
      } else if (playable is LocalPlayable) {
        final local = playable.original;
        await _historyProvider!.recordPlay(
          token: token,
          localPath: local.filePath,
          title: local.title,
          artist: local.artist,
          duration: local.duration,
          progress: progress,
        );
      }
    } catch (e) {
      debugPrint('【AudioProvider】更新播放进度失败: $e');
    }
  }

  /// 播放进度更新定时器（每30秒）
  Timer? _progressUpdateTimer;
  static const Duration _progressUpdateInterval = Duration(seconds: 30);

  /// 启动播放进度更新定时器
  void _startProgressUpdateTimer() {
    _stopProgressUpdateTimer();
    _progressUpdateTimer = Timer.periodic(_progressUpdateInterval, (_) {
      if (_currentIndex >= 0 && _isPlaying) {
        _updatePlaybackProgress();
      }
    });
  }

  /// 停止播放进度更新定时器
  void _stopProgressUpdateTimer() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = null;
  }

  /// 播放下一首
  ///
  /// 修复：支持本地和在线混合播放列表，重启后也能正常工作
  /// Phase 5 修复: 添加去抖检查
  Future<void> playNext() async {
    if (_disposed) return;
    if (!_checkOperationInterval()) return; // 去抖检查

    // 如果统一播放列表为空，尝试从本地播放列表恢复
    if (_unifiedPlaylist.isEmpty) {
      if (_playlist.isEmpty) {
        debugPrint('【AudioProvider】播放列表为空，无法播放下一首');
        return;
      }
      // 从本地播放列表构建统一播放列表
      _unifiedPlaylist = _playlist.map((audio) {
        return LocalPlayable(audio);
      }).toList();
      debugPrint('【AudioProvider】已从本地播放列表恢复统一播放列表，数量: ${_unifiedPlaylist.length}');
    }

    final nextIndex = (_currentIndex + 1) % _unifiedPlaylist.length;
    await _playUnifiedAtIndex(nextIndex);
  }

  /// 播放上一首
  ///
  /// 修复：支持本地和在线混合播放列表，重启后也能正常工作
  /// Phase 5 修复: 添加去抖检查
  Future<void> playPrevious() async {
    if (_disposed) return;
    if (!_checkOperationInterval()) return; // 去抖检查

    // 如果统一播放列表为空，尝试从本地播放列表恢复
    if (_unifiedPlaylist.isEmpty) {
      if (_playlist.isEmpty) {
        debugPrint('【AudioProvider】播放列表为空，无法播放上一首');
        return;
      }
      // 从本地播放列表构建统一播放列表
      _unifiedPlaylist = _playlist.map((audio) {
        return LocalPlayable(audio);
      }).toList();
      debugPrint('【AudioProvider】已从本地播放列表恢复统一播放列表，数量: ${_unifiedPlaylist.length}');
    }

    final previousIndex = (_currentIndex - 1 + _unifiedPlaylist.length) % _unifiedPlaylist.length;
    await _playUnifiedAtIndex(previousIndex);
  }

  // ==================== Phase 2: 在线播放 ====================

  /// 播放在线音频
  ///
  /// [audio] Audio 实体（包含元数据）
  /// [streamUrl] 音频流URL（从后端获取，已废弃）
  /// [proxyUrl] 后端代理URL（可选，如果提供则使用代理）
  /// [preferredFormat] 首选格式（'auto'、'm4s'、'mp3'）
  /// [autoFallback] 是否自动降级（默认 true）
  Future<void> playOnlineAudio({
    required Audio audio,
    String? streamUrl,
    String? proxyUrl,
    String? preferredFormat,  // ✅ 新增：客户端格式偏好
    bool autoFallback = true,  // ✅ 新增：自动降级
  }) async {
    // 检查相同音频是否已在播放
    if (_isCurrentOnline &&
        _currentOnlineAudio?.id == audio.id &&
        _isPlaying) {
      debugPrint('【AudioProvider】音频已在播放中，跳过重复请求: ${audio.title}');
      return;
    }

    // 检查相同音频是否正在加载
    if (_isPlayingOperation &&
        _currentOnlineAudio?.id == audio.id) {
      debugPrint('【AudioProvider】音频正在加载中，跳过重复请求: ${audio.title}');
      return;
    }

    try {
      debugPrint('【AudioProvider】准备播放在线音频: ${audio.title}, 偏好格式: ${preferredFormat ?? "auto"}');

      // 获取音频流能力信息
      await _fetchAudioCapabilities(audio.id);

      // ✅ 构建代理 URL（支持客户端指定格式）
      proxyUrl ??= _buildProxyUrl(audio.id, preferredFormat ?? 'auto');

      // 设置在线音频状态
      _isCurrentOnline = true;
      _currentOnlineAudio = audio;

      // 创建在线可播放对象
      final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

      // 添加到统一播放列表
      await _addPlayableToPlaylist(playable, playImmediately: true);

      // 设置音频源并播放
      await _playPlayable(playable);
      debugPrint('【AudioProvider】在线播放开始: ${audio.title}, 格式: ${preferredFormat ?? "auto"}, seekable: $_isSeekable');
      notifyListeners();
    } catch (e) {
      debugPrint('【AudioProvider】在线播放失败: $e');

      // ✅ 自动降级机制
      if (autoFallback && preferredFormat == 'm4s') {
        debugPrint('【AudioProvider】m4s 播放失败，自动降级到 mp3: $e');

        // 降级到 mp3
        proxyUrl = _buildProxyUrl(audio.id, 'mp3');
        final fallbackPlayable = OnlinePlayable.fromAudio(audio, proxyUrl);

        await _addPlayableToPlaylist(fallbackPlayable, playImmediately: true);
        await _playPlayable(fallbackPlayable);
        debugPrint('【AudioProvider】mp3 降级播放成功: ${audio.title}');
        return;
      }

      rethrow;
    }
  }

  /// 获取音频流能力信息
  ///
  /// 从后端 API 获取音频流的能力声明，包括是否支持 seek/断点续传
  Future<void> _fetchAudioCapabilities(String bvid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.keyToken);

      final dio = Dio();
      final response = await dio.get(
        '${ApiConstants.fullBaseUrl}/bilibili/audio/$bvid',
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        _isSeekable = data['seekable'] ?? true;
        _currentContentType = data['content_type'];
        debugPrint('【AudioProvider】音频流能力: seekable=$_isSeekable, contentType=$_currentContentType');
      } else {
        // API 调用失败，使用默认值（支持 seek）
        _isSeekable = true;
        _currentContentType = null;
        debugPrint('【AudioProvider】获取音频流能力失败，使用默认值');
      }
    } catch (e) {
      // 网络错误或其他异常，使用默认值（支持 seek）
      _isSeekable = true;
      _currentContentType = null;
      debugPrint('【AudioProvider】获取音频流能力异常: $e');
    }
  }

  /// 构建后端代理URL（使用BVID，短URL）
  ///
  /// 新的代理端点格式: /api/bilibili/proxy/audio/:bvid?format=auto|m4s|mp3
  /// P0 修复: Windows 上使用 127.0.0.1 替代 localhost（MPV兼容性）
  ///
  /// [format] 格式选择：'auto'（默认）、'm4s'（最高效）、'mp3'（最兼容）
  String _buildProxyUrl(String bvid, [String format = 'auto']) {
    // P0 修复: Windows 上 MPV 无法解析 localhost，使用 127.0.0.1
    final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
    return '$baseUrl/api/bilibili/proxy/audio/$bvid?format=$format';
  }

  /// 添加 PlayableAudio 到统一播放列表
  Future<void> _addPlayableToPlaylist(
    PlayableAudio playable, {
    bool playImmediately = true,
  }) async {
    // 检查是否已存在相同的音频
    final existingIndex = _unifiedPlaylist.indexWhere((p) => p.id == playable.id);

    if (playImmediately) {
      if (existingIndex != -1) {
        // 已存在，直接设置当前索引
        _currentIndex = existingIndex;
      } else {
        // 不存在，添加到列表末尾
        _unifiedPlaylist.add(playable);
        _currentIndex = _unifiedPlaylist.length - 1;
      }
    } else {
      // 不立即播放，添加到列表末尾
      if (existingIndex == -1) {
        _unifiedPlaylist.add(playable);
      }
    }

    // 同步到本地播放列表（如果是本地音频）
    if (playable is LocalPlayable) {
      final local = playable.original;
      final localExistingIndex = _playlist.indexWhere((a) => a.filePath == local.filePath);
      if (localExistingIndex == -1) {
        _playlist.add(local);
      }
    }

    // Phase 2 遗留问题: 保存统一播放列表
    await _saveUnifiedPlaylist();

    debugPrint('【AudioProvider】统一播放列表: ${_unifiedPlaylist.length} 首, 当前索引: $_currentIndex');
  }

  /// 加载在线封面图片
  ///
  /// 从 coverUrl 下载封面图片并返回图片数据
  Future<Uint8List?> _loadOnlineCover(String coverUrl) async {
    if (coverUrl.isEmpty) return null;

    try {
      debugPrint('【AudioProvider】加载在线封面: $coverUrl');
      final dio = Dio();
      final response = await dio.get(
        coverUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data is List<int>) {
        final imageData = Uint8List.fromList(response.data as List<int>);
        debugPrint('【AudioProvider】封面加载成功，大小: ${imageData.length} bytes');
        return imageData;
      }
    } catch (e) {
      debugPrint('【AudioProvider】加载在线封面失败: $e');
    }

    return null;
  }

  /// 播放 PlayableAudio
  Future<void> _playPlayable(PlayableAudio playable) async {
    if (_disposed) return;

    // 等待之前的播放操作完成（防止并发）
    if (_isPlayingOperation) {
      debugPrint('【AudioProvider】等待上一次播放操作完成...');
      await _playOperationCompleter?.future;
    }

    // 设置播放操作锁
    _isPlayingOperation = true;
    _playOperationCompleter = Completer();

    try {
      // 更新元数据（在设置音频源之前更新，避免 UI 闪烁）
      _title = playable.title;
      _artist = playable.artist ?? '未知艺术家';

      if (_isCurrentOnline) {
        // 在线音频：异步加载封面
        _albumArt = null;
        final coverUrl = playable.coverUrl;
        debugPrint('【AudioProvider】在线封面URL: $coverUrl');
        if (coverUrl != null && coverUrl.isNotEmpty) {
          // 异步加载封面，不阻塞播放
          _loadOnlineCover(coverUrl).then((coverData) {
            if (coverData != null && !_disposed) {
              _albumArt = coverData;
              debugPrint('【AudioProvider】封面加载成功并更新');
              notifyListeners();
            }
          });
        } else {
          debugPrint('【AudioProvider】封面URL为空，跳过封面加载');
        }
      } else {
        // 本地音频
        _albumArt = playable.coverData;
      }

      debugPrint('【AudioProvider】播放: ${playable.url}');

      // 尝试直接设置新音频源（让 MPV 自动处理状态切换）
      try {
        await _setAudioSourceAndPlay(playable);
        debugPrint('【AudioProvider】音频源设置成功');
      } catch (e) {
        // 如果直接设置失败，先停止再重试
        debugPrint('【AudioProvider】首次设置失败，尝试先 stop: $e');
        await _player.stop();
        await Future.delayed(const Duration(milliseconds: 300));
        await _setAudioSourceAndPlay(playable);
      }

      // 启动定时保存（本地音频才保存状态）
      if (!_disposed && !_isCurrentOnline) {
        _startPositionSaveTimer();
      }
    } catch (e) {
      debugPrint('【AudioProvider】播放失败: $e');
      rethrow;
    } finally {
      // 释放播放操作锁
      _isPlayingOperation = false;
      _playOperationCompleter?.complete();
    }
  }

  /// 设置音频源并播放（辅助方法）
  /// P0 修复: 播放后立即更新状态，不等待 stream 事件
  Future<void> _setAudioSourceAndPlay(PlayableAudio playable) async {
    debugPrint('【AudioProvider】设置音频源: ${playable.url}');

    // P0 修复: 设置播放启动标志和时间，防止 stream 事件覆盖状态
    _isStartingPlayback = true;
    _playbackStartTime = DateTime.now();
    debugPrint('【AudioProvider】播放启动保护已开启（2秒窗口）');

    try {
      // 设置音频源并播放（根据类型选择不同方式）
      if (playable.isOnline) {
        // 在线音频：添加重试逻辑
        int retryCount = 0;
        const maxRetries = 2;

        while (retryCount <= maxRetries) {
          try {
            debugPrint('【AudioProvider】播放在线音频 (尝试 ${retryCount + 1}/${maxRetries + 1}): ${playable.url}');

            await _player.setUrl(playable.url);
            debugPrint('【AudioProvider】音频源已设置: ${playable.url}');

            await _player.play();
            // P0 修复: 立即更新播放状态，避免 UI 状态不同步
            _isPlaying = true;
            notifyListeners();

            // 如果成功，中断重试循环
            break;
          } catch (e) {
            retryCount++;
            if (retryCount <= maxRetries) {
              debugPrint('【AudioProvider】播放失败，重试中...: $e');
              await Future.delayed(const Duration(seconds: 1)); // 重试前等待
            } else {
              rethrow; // 达到最大重试次数后放弃
            }
          }
        }
      } else {
        // 本地音频：使用 AudioSource.file()（更好地处理中文路径）
        await _player.setAudioSource(AudioSource.file(playable.url));
        await _player.play();
        // P0 修复: 立即更新播放状态
        _isPlaying = true;
        notifyListeners();
      }
    } finally {
      // P0 修复: 延迟清除播放启动标志，给足够时间让播放器真正开始播放
      // 使用 2.5 秒延迟，比保护窗口（2秒）稍长，确保保护窗口结束后再清除
      Future.delayed(const Duration(milliseconds: 2500), () {
        _isStartingPlayback = false;
        _playbackStartTime = null;
        debugPrint('【AudioProvider】播放启动完成，解除状态保护');
      });
    }
  }

  /// 播放统一播放列表中指定索引的音频（公开方法）
  /// Phase 2: 供播放列表页面使用
  Future<void> playUnifiedAt(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _unifiedPlaylist.length) return;

    // 如果点击的是当前曲目，切换播放/暂停状态
    if (_currentIndex == index) {
      await togglePlayPause();
      return;
    }

    await _playUnifiedAtIndex(index);
  }

  /// 播放统一播放列表中指定索引的音频（内部方法）
  Future<void> _playUnifiedAtIndex(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _unifiedPlaylist.length) return;

    final playable = _unifiedPlaylist[index];

    // 先设置在线状态
    _isCurrentOnline = playable.isOnline;
    if (playable.isOnline && playable is OnlinePlayable) {
      _currentOnlineAudio = playable.original;
      _isSeekable = false; // 默认不支持，稍后通过 API 获取实际能力
    } else {
      _currentOnlineAudio = null;
      _isSeekable = true; // 本地音频默认支持 seek
      _currentContentType = null;
    }

    await _playPlayable(playable);
    _currentIndex = index;

    // Phase 2 遗留问题: 保存统一播放列表
    await _saveUnifiedPlaylist();

    // Phase 2 遗留问题: 记录播放历史
    await _recordPlaybackStart(playable);

    // Phase 2 遗留问题: 启动进度更新定时器
    _startProgressUpdateTimer();

    notifyListeners();
  }

  // ==================== 播放列表管理 ====================

  /// 添加到播放列表
  Future<void> addToPlaylist(LocalAudio audio) async {
    final db = PlaylistManager();
    final id = await db.insertAudio(audio);
    if (id != -1) {
      await _loadPlaylist();
      notifyListeners();
    }
  }

  /// 从播放列表移除（本地音频）
  Future<void> removeFromPlaylist(int id) async {
    final db = PlaylistManager();
    await db.deleteAudio(id);
    _playlist.removeWhere((audio) => audio.id == id);
    _syncUnifiedPlaylist();  // 同步统一播放列表
    notifyListeners();
  }

  /// 从统一播放列表移除指定索引的项
  /// Phase 2: 支持本地和在线音频混合列表
  Future<void> removeFromUnifiedPlaylist(int index) async {
    if (index < 0 || index >= _unifiedPlaylist.length) return;

    final playable = _unifiedPlaylist[index];

    // 如果是本地音频，从数据库删除
    if (playable is LocalPlayable) {
      final local = playable.original;
      if (local.id != null) {
        await removeFromPlaylist(local.id!);
        return;
      }
    }

    // 在线音频或没有 ID 的本地音频：直接从列表移除
    _unifiedPlaylist.removeAt(index);

    // 调整当前索引
    if (_currentIndex == index) {
      // 删除的是当前播放项，重置状态
      await _player.stop();
      _title = "无歌曲";
      _artist = "请添加音频开始播放";
      _albumArt = null;
      _currentIndex = -1;
      _isPlaying = false;
      _isCurrentOnline = false;
      _currentOnlineAudio = null;
      _stopPositionSaveTimer();
    } else if (_currentIndex > index) {
      // 删除项在当前播放项之前，索引减一
      _currentIndex--;
    }

    notifyListeners();
    debugPrint('【AudioProvider】已从统一播放列表移除索引 $index');
  }

  /// 清空统一播放列表
  /// Phase 2: 清空所有本地和在线音频
  Future<void> clearUnifiedPlaylist() async {
    // 清空本地播放列表（数据库）
    final db = PlaylistManager();
    await db.clearPlaylist();

    // 清空统一播放列表
    _unifiedPlaylist.clear();
    _playlist.clear();

    // 重置播放器状态
    await _player.stop();
    _title = "无歌曲";
    _artist = "请添加音频开始播放";
    _albumArt = null;
    _currentIndex = -1;
    _isPlaying = false;
    _isCurrentOnline = false;
    _currentOnlineAudio = null;
    _stopPositionSaveTimer();

    notifyListeners();
    debugPrint('【AudioProvider】统一播放列表已清空');
  }

  // ==================== 工具方法 ====================

  /// 从文件路径提取标题和艺术家
  ///
  /// 返回: {'title': 标题, 'artist': 艺术家}
  Map<String, String> _extractMetadataFromPath(String filePath) {
    try {
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      var nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      // 移除常见标签
      nameWithoutExt = nameWithoutExt
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll(RegExp(r'【.*?】'), '')
          .replaceAll(RegExp(r'\(Official.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'（Official.*?）', caseSensitive: false), '')
          .trim();

      String artist = '';
      String title = nameWithoutExt;

      // 格式1: "艺术家 - 标题"
      if (nameWithoutExt.contains(' - ')) {
        final parts = nameWithoutExt.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      }
      // 格式2: "艺术家 标题"（首字母大写）
      else if (RegExp(r'^[A-Z][a-z]+\s+[A-Z][a-z]+').hasMatch(nameWithoutExt)) {
        final words = nameWithoutExt.split(' ');
        if (words.length >= 2 &&
            RegExp(r'^[A-Z][a-z]+$').hasMatch(words[0]) &&
            RegExp(r'^[A-Z][a-z]+$').hasMatch(words[1])) {
          artist = '${words[0]} ${words[1]}';
          title = words.skip(2).join(' ');
          if (title.isEmpty) title = nameWithoutExt;
        }
      }
      // 格式3: 带中文括号的注释
      else if (nameWithoutExt.contains('（') && nameWithoutExt.contains('）')) {
        final match = RegExp(r'^([^(（]+)[（(].*?[）)](.*)$').firstMatch(nameWithoutExt);
        if (match != null) {
          final beforeComment = match.group(1)!.trim();
          final afterComment = match.group(2)!.trim();
          final words = beforeComment.split(' ');
          if (words.length >= 2 &&
              words.every((w) => RegExp(r'^[A-Z][a-z]+$').hasMatch(w))) {
            artist = beforeComment;
            title = afterComment.isNotEmpty ? afterComment : beforeComment;
          } else if (words.isNotEmpty &&
              RegExp(r'^[A-Z][a-z]+$').hasMatch(words[0])) {
            artist = words[0].trim();
            title = afterComment.isNotEmpty ? afterComment : words.skip(1).join(' ');
            if (title.isEmpty) title = beforeComment;
          } else {
            title = nameWithoutExt.replaceAll(RegExp(r'[（(].*?[）)]'), '').trim();
          }
        }
      }

      artist = artist.replaceAll(RegExp(r'\s+'), ' ').trim();
      title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

      return {
        'title': title.isNotEmpty ? title : nameWithoutExt,
        'artist': artist.isNotEmpty ? artist : '未知艺术家',
      };
    } catch (e) {
      debugPrint('【loadAudio】路径解析失败: $e');
      return {
        'title': filePath.split(RegExp(r'[\\/]')).last,
        'artist': '未知艺术家',
      };
    }
  }

  /// ✅ 新增：在隔离线程中提取元数据（静态函数）
  ///
  /// 使用 Flutter 的 compute() 将阻塞操作移到后台线程
  /// 避免在线播放过程中点击上传按钮时进程卡死
  ///
  /// 返回: {
  ///   'title': String,
  ///   'artist': String,
  ///   'album': String,
  ///   'cover': Uint8List?
  /// }
  static Future<Map<String, dynamic>> _extractMetadataIsolate(String filePath) async {
    try {
      // 异步获取元数据
      final metadata = await MetadataGod.readMetadata(file: filePath);

      Uint8List? cover;
      if (metadata.picture != null) {
        cover = metadata.picture!.data;
      }

      return {
        'title': metadata.title?.trim() ?? '',
        'artist': metadata.artist?.trim() ?? '',
        'album': metadata.album?.trim() ?? '',
        'cover': cover,
      };
    } catch (e) {
      debugPrint('【AudioProvider】元数据解析失败: $e');
      return {
        'title': '',
        'artist': '',
        'album': '',
        'cover': null,
      };
    }
  }

  // ==================== Phase 3B: 播放控制方法 ====================

  /// 设置播放音量（0.0 - 1.0）
  ///
  /// 参数 value: 音量值，范围 0.0（静音）到 1.0（最大音量）
  Future<void> setVolume(double value) async {
    if (_disposed) return;
    _volume = value.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    await _savePlaybackSettings();
    notifyListeners();
    debugPrint('【AudioProvider】音量已设置为: ${(_volume * 100).toInt()}%');
  }

  /// 设置播放倍速（0.5x - 2.0x）
  ///
  /// 参数 value: 倍速值，范围 0.5（半速）到 2.0（双倍速）
  Future<void> setSpeed(double value) async {
    if (_disposed) return;
    _speed = value.clamp(0.5, 2.0);
    await _player.setSpeed(_speed);
    await _savePlaybackSettings();
    notifyListeners();
    debugPrint('【AudioProvider】倍速已设置为: ${_speed}x');
  }

  /// 保存播放设置到 SharedPreferences
  ///
  /// 包括音量和倍速偏好设置
  Future<void> _savePlaybackSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(StorageKeys.playbackVolume, _volume);
      await prefs.setDouble(StorageKeys.playbackSpeed, _speed);
      debugPrint('【AudioProvider】播放设置已保存: 音量=${_volume} 倍速=${_speed}');
    } catch (e) {
      debugPrint('【AudioProvider】保存播放设置失败: $e');
    }
  }

  /// 从 SharedPreferences 加载播放设置
  ///
  /// 在初始化时调用，恢复用户的音量和倍速偏好
  Future<void> _loadPlaybackSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble(StorageKeys.playbackVolume) ?? 1.0;
      _speed = prefs.getDouble(StorageKeys.playbackSpeed) ?? 1.0;

      // 应用到播放器
      if (!_disposed) {
        await _player.setVolume(_volume);
        await _player.setSpeed(_speed);
        debugPrint('【AudioProvider】播放设置已加载: 音量=${(_volume * 100).toInt()}% 倍速=${_speed}x');
      }
    } catch (e) {
      debugPrint('【AudioProvider】加载播放设置失败: $e');
      // 使用默认值
      _volume = 1.0;
      _speed = 1.0;
    }
  }

  @override
  void dispose() {
    // P0 修复: 先取消防抖定时器，不设置 _disposed 标志
    // 这样 _saveUnifiedPlaylistSync() 可以正常执行
    _saveDebounceTimer?.cancel();

    // P0 修复: 同步保存统一播放列表（在设置 _disposed 之前）
    // 注意：由于 dispose 不能是 async，保存可能不会立即完成
    // 但至少确保保存操作被触发
    _saveUnifiedPlaylistSync();

    // 现在设置标志，防止回调在销毁过程中执行
    _disposed = true;

    // 停止定时器
    _stopPositionSaveTimer();
    _stopProgressUpdateTimer(); // Phase 2 遗留问题: 停止进度更新定时器

    // 取消所有订阅
    _positionSub.cancel();
    _durationSub.cancel();
    _playerStateSub.cancel();

    // 销毁播放器
    _player.dispose();
    super.dispose();
  }

  /// 同步保存统一播放列表（dispose 时使用）
  Future<void> _saveUnifiedPlaylistSync() async {
    if (_disposed) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 序列化播放列表
      final playlistJson = jsonEncode(
        _unifiedPlaylist.map((a) => a.toMap()).toList(),
      );
      await prefs.setString(StorageKeys.unifiedPlaylist, playlistJson);
      await prefs.setInt(StorageKeys.currentPlaylistIndex, _currentIndex);
      await prefs.setInt(StorageKeys.currentPlaybackPosition, _position.inSeconds);
      await prefs.setBool(StorageKeys.isCurrentOnline, _isCurrentOnline);

      debugPrint('【AudioProvider】统一播放列表已同步保存');
    } catch (e) {
      debugPrint('【AudioProvider】同步保存统一播放列表失败: $e');
    }
  }
}
