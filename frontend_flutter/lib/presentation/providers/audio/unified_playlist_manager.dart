import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/core/constants/storage_constants.dart';
import 'package:demo/data/managers/playlist_manager.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 统一播放列表管理器
///
/// 职责：
/// 1. 管理统一播放列表（本地 + 在线混合）
/// 2. 当前播放索引管理
/// 3. 播放列表持久化
/// 4. 与本地播放列表同步
class UnifiedPlaylistManager {
  // ==================== 状态变量 ====================

  /// 统一播放列表（本地和在线混合）
  final List<PlayableAudio> _playlist = [];

  /// 当前播放索引
  int _currentIndex = -1;

  /// 本地播放列表（向后兼容，用于数据库同步）
  final List<LocalAudio> _localPlaylist = [];

  /// 状态变化回调
  Function()? _onPlaylistChanged;

  // ==================== 构造函数 ====================

  UnifiedPlaylistManager();

  // ==================== Getters ====================

  /// 播放列表
  List<PlayableAudio> get playlist => List.unmodifiable(_playlist);

  /// 本地播放列表
  List<LocalAudio> get localPlaylist => List.unmodifiable(_localPlaylist);

  /// 当前索引
  int get currentIndex => _currentIndex;

  /// 当前可播放音频
  PlayableAudio? get currentPlayable {
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      return _playlist[_currentIndex];
    }
    return null;
  }

  /// 播放列表是否为空
  bool get isEmpty => _playlist.isEmpty;

  /// 播放列表长度
  int get length => _playlist.length;

  // ==================== 回调设置 ====================

  /// 设置播放列表变化回调
  void setOnPlaylistChanged(Function()? callback) {
    _onPlaylistChanged = callback;
  }

  /// 通知播放列表已变化
  void _notifyChanged() {
    _onPlaylistChanged?.call();
  }

  // ==================== 播放列表操作 ====================

  /// 设置播放列表
  ///
  /// [playlist] 新的播放列表
  /// [initialIndex] 初始播放索引（默认 -1，表示不自动播放）
  /// [syncLocal] 是否同步到本地播放列表
  void setPlaylist(
    List<PlayableAudio> playlist, {
    int initialIndex = -1,
    bool syncLocal = true,
  }) {
    _playlist.clear();
    _playlist.addAll(playlist);
    _currentIndex = initialIndex;

    if (syncLocal) {
      _syncToLocal();
    }

    _notifyChanged();
    AppLogger.debug('UnifiedPlaylistManager', '设置播放列表，长度: ${playlist.length}');
  }

  /// 添加到播放列表 - P0修复：确保数据库同步完成
  ///
  /// [playable] 要添加的音频
  /// [playImmediately] 是否立即播放（设置为当前音频）
  /// [syncLocal] 是否同步到本地播放列表
  Future<void> add(
    PlayableAudio playable, {
    bool playImmediately = false,
    bool syncLocal = true,
  }) async {
    // 检查是否已存在
    final existingIndex = _playlist.indexWhere((p) => p.id == playable.id);

    if (playImmediately) {
      if (existingIndex != -1) {
        // 已存在，直接设置为当前
        _currentIndex = existingIndex;
      } else {
        // 不存在，添加并设置为当前
        _playlist.add(playable);
        _currentIndex = _playlist.length - 1;
      }
    } else {
      // 不立即播放，添加到末尾（如果不存在）
      if (existingIndex == -1) {
        _playlist.add(playable);
      }
    }

    // P0修复：先同步数据库，确认成功后再通知UI
    if (syncLocal && playable is LocalPlayable) {
      final success = await _addLocalToDatabase(playable.original);
      if (!success) {
        // 数据库写入失败，回滚内存操作
        if (existingIndex == -1) {
          _playlist.removeWhere((p) => p.id == playable.id);
        }
        if (_currentIndex >= _playlist.length) {
          _currentIndex = _playlist.isEmpty ? -1 : _playlist.length - 1;
        }
        AppLogger.error('UnifiedPlaylistManager', '数据库写入失败，回滚添加操作');
        return;
      }
    }

    _notifyChanged();
    AppLogger.info('UnifiedPlaylistManager', '添加音频: ${playable.title}, 总数: ${_playlist.length}');
  }

  /// 批量添加到播放列表
  ///
  /// [playables] 要添加的音频列表
  /// [syncLocal] 是否同步到本地播放列表
  Future<void> addAll(
    List<PlayableAudio> playables, {
    bool syncLocal = true,
  }) async {
    for (final playable in playables) {
      // 检查是否已存在
      if (!_playlist.any((p) => p.id == playable.id)) {
        _playlist.add(playable);

        if (syncLocal && playable is LocalPlayable) {
          await _addLocalToDatabase(playable.original);
        }
      }
    }

    _notifyChanged();
    AppLogger.info('UnifiedPlaylistManager', '批量添加 ${playables.length} 首音频');
  }

  /// 从播放列表移除指定索引的项
  ///
  /// [index] 要移除的索引
  /// [syncLocal] 是否同步到本地播放列表
  Future<void> removeAt(int index, {bool syncLocal = true}) async {
    if (index < 0 || index >= _playlist.length) return;

    final playable = _playlist[index];

    // 如果是本地音频，从数据库删除
    if (syncLocal && playable is LocalPlayable) {
      await _removeLocalFromDatabase(playable.original);
    }

    // 移除
    _playlist.removeAt(index);

    // 调整当前索引
    if (_currentIndex == index) {
      // 删除的是当前播放项，重置索引
      _currentIndex = -1;
    } else if (_currentIndex > index) {
      // 删除项在当前播放项之前，索引减一
      _currentIndex--;
    }

    _notifyChanged();
    AppLogger.debug('UnifiedPlaylistManager', '移除索引 $index: ${playable.title}');
  }

  /// 从播放列表移除指定 ID 的项
  ///
  /// [id] 要移除的音频 ID
  /// [syncLocal] 是否同步到本地播放列表
  Future<void> removeById(String id, {bool syncLocal = true}) async {
    final index = _playlist.indexWhere((p) => p.id == id);
    if (index != -1) {
      await removeAt(index, syncLocal: syncLocal);
    }
  }

  /// 清空播放列表
  ///
  /// [syncLocal] 是否同步到本地播放列表（清空数据库）
  Future<void> clear({bool syncLocal = true}) async {
    if (syncLocal) {
      await _clearLocalDatabase();
    }

    _playlist.clear();
    _localPlaylist.clear();
    _currentIndex = -1;

    _notifyChanged();
    AppLogger.debug('UnifiedPlaylistManager', '清空播放列表');
  }

  /// 移动音频位置（用于拖拽排序）
  ///
  /// [oldIndex] 原始索引
  /// [newIndex] 目标索引
  void move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _playlist.length) return;
    if (newIndex < 0 || newIndex >= _playlist.length) return;

    if (oldIndex == newIndex) return;

    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);

    // 调整当前索引
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
      _currentIndex--;
    } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
      _currentIndex++;
    }

    _notifyChanged();
    AppLogger.debug('UnifiedPlaylistManager', '移动音频: $oldIndex -> $newIndex');
  }

  /// 设置当前播放索引
  ///
  /// [index] 新的索引
  /// [validate] 是否验证索引有效性
  bool setCurrentIndex(int index, {bool validate = true}) {
    if (validate && (index < 0 || index >= _playlist.length)) {
      AppLogger.debug('UnifiedPlaylistManager', '无效索引: $index');
      return false;
    }

    _currentIndex = index;
    _notifyChanged();
    AppLogger.debug('UnifiedPlaylistManager', '设置当前索引: $index');
    return true;
  }

  /// 是否有下一曲
  bool get hasNext => _playlist.isNotEmpty && _currentIndex < _playlist.length - 1;

  /// 是否有上一曲
  bool get hasPrevious => _playlist.isNotEmpty && _currentIndex > 0;

  /// 下一曲索引（循环播放）
  int get nextIndex {
    if (_playlist.isEmpty) return -1;
    return (_currentIndex + 1) % _playlist.length;
  }

  /// 上一曲索引（循环播放）
  int get previousIndex {
    if (_playlist.isEmpty) return -1;
    return (_currentIndex - 1 + _playlist.length) % _playlist.length;
  }

  // ==================== 本地播放列表同步 ====================

  /// 同步到本地播放列表
  void _syncToLocal() {
    // 提取所有本地音频
    _localPlaylist.clear();
    for (final playable in _playlist) {
      if (playable is LocalPlayable) {
        _localPlaylist.add(playable.original);
      }
    }
    AppLogger.debug('UnifiedPlaylistManager', '同步到本地播放列表: ${_localPlaylist.length} 首');
  }

  /// 从本地播放列表同步 - P0修复：使用增量同步
  Future<void> syncFromLocal() async {
    try {
      final db = PlaylistManager();
      final dbAudios = await db.getAllAudios();

      // P0修复：保存当前播放的音频ID，防止播放状态丢失
      final String? currentId = _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]?.id
          : null;

      // P0修复：增量同步，保留在线音频
      final onlinePlayables = _playlist.whereType<OnlinePlayable>().toList();

      // 更新本地播放列表
      _localPlaylist.clear();
      _localPlaylist.addAll(dbAudios);

      // P0修复：重建播放列表，保留在线音频，更新本地音频
      _playlist.clear();
      _playlist.addAll(onlinePlayables);

      for (final audio in _localPlaylist) {
        final existingIndex = _playlist.indexWhere((p) =>
          p is LocalPlayable && p.original.filePath == audio.filePath);

        if (existingIndex == -1) {
          // 新增音频
          _playlist.add(LocalPlayable(audio));
          AppLogger.debug('UnifiedPlaylistManager', '新增本地音频: ${audio.title}');
        } else {
          // 更新现有音频（保留索引位置）
          _playlist[existingIndex] = LocalPlayable(audio);
          AppLogger.debug('UnifiedPlaylistManager', '更新本地音频: ${audio.title}');
        }
      }

      // P0修复：恢复当前播放索引
      if (currentId != null) {
        final newIndex = _playlist.indexWhere((p) => p.id == currentId);
        if (newIndex != -1) {
          _currentIndex = newIndex;
          AppLogger.debug('UnifiedPlaylistManager', '恢复播放索引: $_currentIndex (音频ID: $currentId)');
        } else {
          // 当前音频不在新播放列表中，重置索引
          _currentIndex = _playlist.isEmpty ? -1 : 0;
          AppLogger.debug('UnifiedPlaylistManager', '当前音频已移除，重置索引至: $_currentIndex');
        }
      } else {
        // 没有当前播放的音频，确保索引有效
        if (_currentIndex >= _playlist.length) {
          _currentIndex = _playlist.isEmpty ? -1 : 0;
          AppLogger.debug('UnifiedPlaylistManager', '索引越界，调整至: $_currentIndex');
        }
      }

      _notifyChanged();
      AppLogger.debug('UnifiedPlaylistManager', '从本地播放列表同步: ${_localPlaylist.length} 首本地 + ${onlinePlayables.length} 首在线');
    } catch (e) {
      AppLogger.error('UnifiedPlaylistManager', '从本地同步失败: $e');
    }
  }

  /// P0修复：增量同步（仅添加新项）
  Future<void> syncIncremental() async {
    try {
      final db = PlaylistManager();
      final dbAudios = await db.getAllAudios();

      int addedCount = 0;
      int updatedCount = 0;

      for (final audio in dbAudios) {
        final existingIndex = _playlist.indexWhere((p) =>
          p is LocalPlayable && p.original.filePath == audio.filePath);

        if (existingIndex == -1) {
          // 新增音频
          _playlist.add(LocalPlayable(audio));
          _localPlaylist.add(audio);
          addedCount++;
        } else {
          // 检查是否需要更新
          final existing = _playlist[existingIndex] as LocalPlayable;
          if (existing.original.title != audio.title ||
              existing.original.artist != audio.artist) {
            _playlist[existingIndex] = LocalPlayable(audio);
            updatedCount++;
          }
        }
      }

      if (addedCount > 0 || updatedCount > 0) {
        _notifyChanged();
        AppLogger.info('UnifiedPlaylistManager', '增量同步: 新增 $addedCount 首, 更新 $updatedCount 首');
      }
    } catch (e) {
      AppLogger.error('UnifiedPlaylistManager', '增量同步失败: $e');
    }
  }

  /// 添加本地音频到数据库 - P0修复：返回操作结果
  Future<bool> _addLocalToDatabase(LocalAudio audio) async {
    try {
      final db = PlaylistManager();
      final id = await db.insertAudio(audio);

      if (id != -1) {
        // P0修复：验证数据库写入成功
        final savedAudio = await db.getAudioById(id);
        if (savedAudio != null) {
          // 更新本地播放列表（使用 copyWith 创建新对象）
          final updatedAudio = audio.copyWith(id: id);
          if (!_localPlaylist.any((a) => a.id == id)) {
            _localPlaylist.add(updatedAudio);
          }
          AppLogger.info('UnifiedPlaylistManager', '成功添加到数据库: ${audio.title}, ID: $id');
          return true;
        } else {
          AppLogger.error('UnifiedPlaylistManager', '数据库写入验证失败: ID $id 不存在');
          return false;
        }
      } else {
        AppLogger.error('UnifiedPlaylistManager', '数据库插入失败: 返回ID为-1');
        return false;
      }
    } catch (e) {
      AppLogger.error('UnifiedPlaylistManager', '添加到数据库失败: $e');
      return false;
    }
  }

  /// 从数据库移除本地音频
  Future<void> _removeLocalFromDatabase(LocalAudio audio) async {
    if (audio.id == null) return;

    try {
      final db = PlaylistManager();
      await db.deleteAudio(audio.id!);
      _localPlaylist.removeWhere((a) => a.id == audio.id);
      AppLogger.debug('UnifiedPlaylistManager', '从数据库移除: ${audio.title}');
    } catch (e) {
      AppLogger.error('UnifiedPlaylistManager', '从数据库移除失败: $e');
    }
  }

  /// 清空本地数据库
  Future<void> _clearLocalDatabase() async {
    try {
      final db = PlaylistManager();
      await db.clearPlaylist();
      _localPlaylist.clear();
      AppLogger.info('UnifiedPlaylistManager', '已清空数据库');
    } catch (e) {
      AppLogger.error('UnifiedPlaylistManager', '清空数据库失败: $e');
    }
  }

  // ==================== 持久化 ====================

  /// 保存播放列表到 SharedPreferences
  Future<void> save({
    Duration? currentPosition,
    bool? isCurrentOnline,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 序列化播放列表
      final playlistJson = jsonEncode(
        _playlist.map((a) => a.toMap()).toList(),
      );
      await prefs.setString(StorageKeys.unifiedPlaylist, playlistJson);
      await prefs.setInt(StorageKeys.currentPlaylistIndex, _currentIndex);

      if (currentPosition != null) {
        await prefs.setInt(StorageKeys.currentPlaybackPosition, currentPosition.inSeconds);
      }
      if (isCurrentOnline != null) {
        await prefs.setBool(StorageKeys.isCurrentOnline, isCurrentOnline);
      }

      AppLogger.info('UnifiedPlaylistManager', '保存播放列表: ${_playlist.length} 首, 索引: $_currentIndex');
    } catch (e) {
      AppLogger.error('UnifiedPlaylistManager', '保存播放列表失败: $e');
    }
  }

  /// 从 SharedPreferences 恢复播放列表
  ///
  /// 返回：保存的播放位置（秒），如果没有则为 null
  Future<int?> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistJson = prefs.getString(StorageKeys.unifiedPlaylist);

      if (playlistJson == null || playlistJson.isEmpty) {
        AppLogger.info('UnifiedPlaylistManager', '没有保存的播放列表');
        return null;
      }

      // 反序列化播放列表
      final data = jsonDecode(playlistJson) as List;
      _playlist.clear();

      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final playableType = map['playableType'] as String?;

        if (playableType == 'online') {
          _playlist.add(OnlinePlayable.fromMap(map));
        } else {
          _playlist.add(LocalPlayable.fromMap(map));
        }
      }

      // 获取保存的索引
      final savedIndex = prefs.getInt(StorageKeys.currentPlaylistIndex) ?? -1;
      final savedPosition = prefs.getInt(StorageKeys.currentPlaybackPosition);

      // 验证索引有效性
      if (savedIndex >= 0 && savedIndex < _playlist.length) {
        _currentIndex = savedIndex;
        AppLogger.debug('UnifiedPlaylistManager', '恢复播放列表: ${_playlist.length} 首, 索引: $savedIndex, 位置: $savedPosition秒');
      } else {
        _currentIndex = -1;
        AppLogger.debug('UnifiedPlaylistManager', '恢复播放列表但索引无效: $savedIndex');
      }

      _notifyChanged();
      return savedPosition;
    } catch (e) {
      AppLogger.error('UnifiedPlaylistManager', '恢复播放列表失败: $e');
      return null;
    }
  }

  /// 获取保存的在线状态
  Future<bool> getSavedOnlineState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(StorageKeys.isCurrentOnline) ?? false;
    } catch (e) {
      AppLogger.debug('UnifiedPlaylistManager', '获取在线状态失败: $e');
      return false;
    }
  }

  /// 查找音频在播放列表中的索引
  int indexOf(String id) {
    return _playlist.indexWhere((p) => p.id == id);
  }

  /// 检查音频是否在播放列表中
  bool contains(String id) {
    return _playlist.any((p) => p.id == id);
  }

  /// 获取指定索引的音频
  PlayableAudio? operator [](int index) {
    if (index >= 0 && index < _playlist.length) {
      return _playlist[index];
    }
    return null;
  }
}
