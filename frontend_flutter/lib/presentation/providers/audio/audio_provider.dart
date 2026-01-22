import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/data/managers/playlist_manager.dart';
import 'package:flutter/foundation.dart';

/// 音频播放状态管理
///
/// Phase 2A: 新增播放进度持久化功能
class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  // 播放列表
  List<LocalAudio> _playlist = [];
  int _currentIndex = -1;

  // 播放状态
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  String _title = "未知标题";
  String _artist = "未知艺术家";
  Uint8List? _albumArt;

  // 订阅
  late StreamSubscription _positionSub;
  late StreamSubscription _durationSub;
  late StreamSubscription _stateSub;

  // Phase 2A: 播放状态持久化
  Timer? _savePositionTimer;
  static const Duration _saveInterval = Duration(seconds: 5);

  AudioProvider() {
    _loadPlaylist();
    _initListeners();
  }

  // ==================== 初始化 ====================

  void _initListeners() {
    _positionSub = _player.onPositionChanged.listen(_updatePosition);
    _durationSub = _player.onDurationChanged.listen(_updateDuration);
    _stateSub = _player.onPlayerStateChanged.listen(_updatePlayState);
    _player.onPlayerComplete.listen((_) => playNext());
  }

  /// 加载播放列表（从数据库）
  Future<void> _loadPlaylist() async {
    final db = PlaylistManager();
    _playlist = await db.getAllAudios();
    notifyListeners();
  }

  /// 公开方法：重新加载播放列表
  /// Phase 2A: 用于拖拽排序后刷新
  Future<void> loadPlaylist() async {
    await _loadPlaylist();
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
  Future<void> _savePlaybackState() async {
    if (_currentIndex < 0 || _playlist.isEmpty) return;
    final audio = _playlist[_currentIndex];
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

  /// 恢复播放状态（应用启动时调用）
  Future<void> restorePlaybackState() async {
    final db = PlaylistManager();
    final state = await db.getPlaybackState();
    if (state != null) {
      final savedIndex = state['current_index'] as int;
      final savedPosition = Duration(seconds: state['position'] as int);
      if (savedIndex >= 0 && savedIndex < _playlist.length) {
        _currentIndex = savedIndex;
        final audio = _playlist[savedIndex];
        // 只设置音频源，不自动播放
        try {
          await _player.setSource(DeviceFileSource(audio.filePath));
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

  // ==================== 状态更新 ====================

  void _updatePosition(Duration p) {
    _position = p;
    notifyListeners();
  }

  void _updateDuration(Duration d) {
    _duration = d;
    notifyListeners();
  }

  void _updatePlayState(PlayerState state) {
    _isPlaying = state == PlayerState.playing;
    notifyListeners();
  }

  // ==================== Getters ====================

  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  String get title => _title;
  String get artist => _artist;
  Uint8List? get albumArt => _albumArt;
  List<LocalAudio> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  LocalAudio? get currentAudio => _currentIndex >= 0 ? _playlist[_currentIndex] : null;

  // ==================== 播放控制 ====================

  /// 加载音频文件并设置元数据
  ///
  /// 元数据优先级: 文件内嵌元数据 > 数据库 > 文件名提取
  Future<void> loadAudio(String filePath) async {
    try {
      debugPrint('【loadAudio】开始加载: $filePath');

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

      // 设置音频源并播放
      _position = Duration.zero;
      _duration = Duration.zero;
      await _player.setSource(DeviceFileSource(filePath));
      await _player.resume();

      // 更新或添加到播放列表
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
      notifyListeners();
    } catch (e) {
      debugPrint('【loadAudio】加载失败: $e');
      rethrow;
    }
  }

  /// 播放/暂停
  /// Phase 2A: 添加播放状态保存和定时器控制
  void togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        _stopPositionSaveTimer(); // 暂停时停止定时器
        await _savePlaybackState(); // 暂停时立即保存
      } else {
        if (_player.state == PlayerState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.resume();
        _startPositionSaveTimer(); // 播放时启动定时器
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 跳转到指定位置
  void seek(Duration position) => _player.seek(position);

  /// 播放指定索引的音频
  /// Phase 2A: 添加定时保存启动
  Future<void> playAudio(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.stop();
    final audio = _playlist[index];
    await loadAudio(audio.filePath);
    _currentIndex = _playlist.indexWhere((a) => a.filePath == audio.filePath);
    _startPositionSaveTimer(); // 启动定时保存
    notifyListeners();
  }

  /// 播放下一首
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    await playAudio(nextIndex);
  }

  /// 播放上一首
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    final previousIndex = (_currentIndex - 1) % _playlist.length;
    await playAudio(previousIndex);
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

  /// 从播放列表移除
  Future<void> removeFromPlaylist(int id) async {
    final db = PlaylistManager();
    await db.deleteAudio(id);
    _playlist.removeWhere((audio) => audio.id == id);
    notifyListeners();
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
    // Phase 2A: 释放前停止定时器并保存播放状态
    _stopPositionSaveTimer();
    // 注意: dispose 是同步方法，不能直接调用 async 的 _savePlaybackState
    // 如果需要在 dispose 时保存，应该使用同步方式或标记
    _positionSub.cancel();
    _durationSub.cancel();
    _stateSub.cancel();
    _player.dispose();
    super.dispose();
  }
}
