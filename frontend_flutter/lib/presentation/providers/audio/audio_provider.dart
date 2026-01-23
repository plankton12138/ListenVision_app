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

  // Phase 2: 音频流能力（从后端获取）
  bool _isSeekable = true; // 默认支持 seek（本地音频）
  String? _currentContentType; // 当前音频的 Content-Type

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

  AudioProvider() {
    _init();
  }

  // ==================== 初始化 ====================

  Future<void> _init() async {
    // 配置音频会话
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

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
    _playerStateSub = _player.playerStateStream.listen(
      (state) {
        if (_disposed) return;
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
  ///
  /// 修复：同时恢复统一播放列表，确保下一首功能正常工作
  /// Phase 2 遗留问题: 已废弃，改用 _restoreUnifiedPlaylist()
  @Deprecated('Use _restoreUnifiedPlaylist() instead')
  Future<void> restorePlaybackState() async {
    final db = PlaylistManager();
    final state = await db.getPlaybackState();

    // 恢复时同步构建统一播放列表
    if (_playlist.isNotEmpty) {
      _unifiedPlaylist = _playlist.map((audio) {
        return LocalPlayable(audio);
      }).toList();
      debugPrint('【AudioProvider】已构建统一播放列表，数量: ${_unifiedPlaylist.length}');
    }

    if (state != null) {
      final savedIndex = state['current_index'] as int;
      final savedPosition = Duration(seconds: state['position'] as int);
      if (savedIndex >= 0 && savedIndex < _playlist.length) {
        _currentIndex = savedIndex;
        final audio = _playlist[savedIndex];
        // 只设置音频源，不自动播放
        try {
          // 使用 AudioSource.file() 播放本地文件（更好地处理中文路径）
          await _player.setAudioSource(AudioSource.file(audio.filePath));
          await _player.seek(savedPosition);
          _title = audio.title;
          _artist = audio.artist;
          _albumArt = audio.albumArt;
          debugPrint('【AudioProvider】播放状态已恢复: ${audio.title}, 位置: $savedPosition');
          notifyListeners();
        } catch (e) {
          debugPrint('【AudioProvider】恢复播放状态失败: $e');
        }
      } else {
        debugPrint('【AudioProvider】保存的索引 $savedIndex 超出范围，当前列表长度: ${_playlist.length}');
      }
    } else {
      debugPrint('【AudioProvider】没有找到保存的播放状态');
    }
  }

  // ==================== Phase 2 遗留问题: 统一播放列表持久化 ====================

  /// 保存统一播放列表到 SharedPreferences
  ///
  /// 保存内容包括：
  /// - 统一播放列表（包含本地和在线音频）
  /// - 当前播放索引
  /// - 当前播放位置
  /// - 是否为在线音频
  Future<void> _saveUnifiedPlaylist() async {
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
    }
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
      final savedPosition = prefs.getInt(StorageKeys.currentPlaybackPosition) ?? 0;
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

        // 设置音频源并跳转（不自动播放）
        try {
          if (playable.isOnline) {
            // 在线音频流不支持 seek，从头开始播放
            await _player.setUrl(playable.url);
            debugPrint('【AudioProvider】在线音频不支持恢复播放位置，从头开始');
          } else {
            // 本地音频可以恢复播放位置
            await _player.setAudioSource(AudioSource.file(playable.url));
            await _player.seek(Duration(seconds: savedPosition));
          }

          debugPrint('【AudioProvider】统一播放列表已恢复: ${restoredPlaylist.length} 首, 当前: $_title');
        } catch (e) {
          debugPrint('【AudioProvider】恢复播放状态失败: $e');
          // 即使恢复失败，也保留播放列表
          _unifiedPlaylist = restoredPlaylist;
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

  /// 更新当前播放音频的元数据
  ///
  /// 根据 PlayableAudio 更新显示的标题、艺术家和封面
  void _updateMetadata(PlayableAudio playable) {
    _title = playable.title;
    _artist = playable.artist ?? '未知艺术家';
    _albumArt = playable.coverData;

    if (playable.isOnline && playable is OnlinePlayable) {
      _isCurrentOnline = true;
      _currentOnlineAudio = playable.original;
    } else {
      _isCurrentOnline = false;
      _currentOnlineAudio = null;
    }

    notifyListeners();
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

      // 停止当前播放
      await _player.stop();

      // 等待播放器进入 idle 状态（最多等待2秒）
      try {
        await _player.processingStateStream
            .firstWhere((s) => s == ProcessingState.idle)
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () => ProcessingState.idle,
            );
      } catch (e) {
        debugPrint('【loadAudio】等待 idle 状态超时，继续执行: $e');
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

      // 从文件解析元数据（使用 metadata_god 库）
      try {
        if (!File(filePath).existsSync()) {
          debugPrint('【loadAudio】文件不存在: $filePath');
          throw Exception('文件不存在');
        }

        final metadata = await MetadataGod.readMetadata(file: filePath);
        fileTitle = metadata.title?.trim() ?? '';
        fileArtist = metadata.artist?.trim() ?? '';
        fileAlbum = metadata.album?.trim() ?? '';

        if (metadata.picture != null) {
          fileCover = metadata.picture!.data;
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
  /// Phase 5 修复: 立即更新状态避免快速点击时的延迟 + 去抖
  /// Phase 5 修复: 在线音频流不支持 seek，避免 MPV 错误
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
        // 仅本地音频支持 seek，在线流媒体会失败
        final currentIsOnline = _currentIndex >= 0 &&
                               _currentIndex < _unifiedPlaylist.length &&
                               _unifiedPlaylist[_currentIndex].isOnline;
        if (_player.processingState == ProcessingState.completed && !currentIsOnline) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
        _isPlaying = true; // 立即更新状态
        _startPositionSaveTimer(); // 播放时启动定时器
        notifyListeners();
      }
    } catch (e) {
      debugPrint('【AudioProvider】togglePlayPause 错误: $e');
      rethrow;
    }
  }

  /// 暂停
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
  Future<void> seek(Duration position) async {
    if (_disposed) return;

    // 检查当前音频是否支持 seek
    if (!_isSeekable) {
      debugPrint('【AudioProvider】当前音频不支持 seek（转码流或缓存流），跳过跳转操作');
      // 可以考虑抛出一个特定异常，让 UI 层显示提示
      throw UnsupportedError('当前音频格式不支持跳转，请使用原始格式（m4s）');
    }

    try {
      debugPrint('【AudioProvider】开始跳转到: ${position.inSeconds}秒');

      await _player.seek(position);
      // just_audio 会自动处理状态恢复
    } catch (e) {
      debugPrint('【AudioProvider】跳转失败: $e');
      rethrow; // 重新抛出异常，让 UI 层处理
    }
  }

  /// 播放指定索引的音频
  /// Phase 2A: 添加定时保存启动
  /// Phase 5 修复: 添加去抖检查
  Future<void> playAudio(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _playlist.length) return;
    if (!_checkOperationInterval()) return; // 去抖检查

    final audio = _playlist[index];
    await loadAudio(audio.filePath); // loadAudio 已经处理了播放锁和定时器
    _currentIndex = _playlist.indexWhere((a) => a.filePath == audio.filePath);

    // Phase 2 遗留问题: 记录本地音频播放历史
    _recordPlaybackStart(LocalPlayable(audio));

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
  Future<void> playOnlineAudio({
    required Audio audio,
    String? streamUrl,
    String? proxyUrl,
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
      debugPrint('【AudioProvider】准备播放在线音频: ${audio.title}');

      // 获取音频流能力信息
      await _fetchAudioCapabilities(audio.id);

      // 使用新的代理端点：通过BVID获取音频流（URL更短，MPV兼容性更好）
      proxyUrl ??= _buildProxyUrl(audio.id);

      // 设置在线音频状态
      _isCurrentOnline = true;
      _currentOnlineAudio = audio;

      // 创建在线可播放对象
      final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

      // 添加到统一播放列表
      await _addPlayableToPlaylist(playable, playImmediately: true);

      // 设置音频源并播放
      await _playPlayable(playable);

      debugPrint('【AudioProvider】在线播放开始: ${audio.title}, seekable: $_isSeekable');
      notifyListeners();
    } catch (e) {
      debugPrint('【AudioProvider】在线播放失败: $e');
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
  /// 新的代理端点格式: /api/bilibili/proxy/audio/:bvid
  /// 这样URL会短很多，MPV兼容性更好
  String _buildProxyUrl(String bvid) {
    // 使用BVID而不是完整URL，URL更短，MPV兼容性更好
    return '${ApiConstants.fullBaseUrl}/bilibili/proxy/audio/$bvid';
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
      // 显式暂停 → 停止，确保状态平稳过渡
      debugPrint('【AudioProvider】准备停止当前播放...');
      await _player.pause();
      await Future.delayed(const Duration(milliseconds: 100)); // 让 pause 完成

      await _player.stop();
      debugPrint('【AudioProvider】播放器已停止');

      // 等待播放器进入 idle 状态（最多等待5秒，给流媒体足够清理时间）
      try {
        final state = await _player.processingStateStream
            .firstWhere((s) => s == ProcessingState.idle)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('【AudioProvider】等待 idle 状态超时（5秒）');
                return ProcessingState.idle;
              },
            );
        debugPrint('【AudioProvider】播放器状态: $state');
      } catch (e) {
        debugPrint('【AudioProvider】等待 idle 状态失败: $e');
      }

      // 释放在线音频资源
      if (playable.isOnline) {
        debugPrint('【AudioProvider】释放在线音频资源...');
        // 设置空源强制释放之前的流资源
        try {
          await _player.setAudioSource(AudioSource.uri(Uri.parse('')));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('【AudioProvider】释放资源时出错（可忽略）: $e');
        }
      }

      // 验证播放器状态
      if (_player.playing) {
        debugPrint('【AudioProvider】警告：播放器仍在播放中');
        // 强制停止
        await _player.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // 更新元数据
      _title = playable.title;
      _artist = playable.artist ?? '未知艺术家';

      if (_isCurrentOnline) {
        // 在线音频
        _albumArt = null; // 封面需要异步加载
      } else {
        // 本地音频
        _albumArt = playable.coverData;
      }

      debugPrint('【AudioProvider】播放: ${playable.url}');

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

            // 验证设置成功
            if (_player.processingState == ProcessingState.idle) {
              debugPrint('【AudioProvider】播放器准备就绪');
            } else {
              debugPrint('【AudioProvider】警告：播放器状态异常: ${_player.processingState}');
            }

            await _player.play();

            // 如果成功，中断重试循环
            break;
          } catch (e) {
            retryCount++;
            if (retryCount <= maxRetries) {
              debugPrint('【AudioProvider】播放失败，重试中...: $e');
              await Future.delayed(Duration(seconds: 1)); // 重试前等待
            } else {
              rethrow; // 达到最大重试次数后放弃
            }
          }
        }
      } else {
        // 本地音频：使用 AudioSource.file()（更好地处理中文路径）
        await _player.setAudioSource(AudioSource.file(playable.url));
        await _player.play();
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

  @override
  void dispose() {
    // 先设置标志，防止回调在销毁过程中执行
    _disposed = true;

    // 停止定时器
    _stopPositionSaveTimer();
    _stopProgressUpdateTimer(); // Phase 2 遗留问题: 停止进度更新定时器

    // Phase 2 遗留问题: 销毁前保存统一播放列表
    _saveUnifiedPlaylist();

    // 取消所有订阅
    _positionSub.cancel();
    _durationSub.cancel();
    _playerStateSub.cancel();

    // 销毁播放器
    _player.dispose();
    super.dispose();
  }
}
