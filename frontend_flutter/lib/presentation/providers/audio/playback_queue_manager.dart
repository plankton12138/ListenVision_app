import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/core/constants/storage_constants.dart';
import 'package:demo/data/managers/playlist_manager.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 播放队列管理器
///
/// 职责：
/// 1. 管理播放队列（本地 + 在线音频混合）
/// 2. 当前播放索引管理
/// 3. 播放队列状态持久化
/// 4. 与本地音频数据库同步
///
/// 注意：此类属于表现层，负责内存中的播放队列状态管理。
/// 本地音频的持久化存储由 [PlaylistManager]（数据层）处理。
class PlaybackQueueManager {
  // ==================== 状态变量 ====================

  /// 播放队列（本地和在线混合）
  final List<PlayableAudio> _queue = [];

  /// 当前播放索引
  int _currentIndex = -1;

  /// 本地音频列表（用于数据库同步）
  final List<LocalAudio> _localAudios = [];

  /// 状态变化回调
  Function()? _onQueueChanged;

  // ==================== 构造函数 ====================

  PlaybackQueueManager();

  // ==================== Getters ====================

  /// 播放队列
  List<PlayableAudio> get queue => List.unmodifiable(_queue);

  /// 本地音频列表
  List<LocalAudio> get localAudios => List.unmodifiable(_localAudios);

  /// 本地播放列表（别名，用于向后兼容）
  List<LocalAudio> get localPlaylist => List.unmodifiable(_localAudios);

  /// 播放队列（别名，用于向后兼容）
  List<PlayableAudio> get playlist => List.unmodifiable(_queue);

  /// 当前索引
  int get currentIndex => _currentIndex;

  /// 当前可播放音频
  PlayableAudio? get currentPlayable {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      return _queue[_currentIndex];
    }
    return null;
  }

  /// 队列是否为空
  bool get isEmpty => _queue.isEmpty;

  /// 队列长度
  int get length => _queue.length;

  /// 是否有下一首
  bool get hasNext => _currentIndex < _queue.length - 1;

  /// 是否有上一首
  bool get hasPrevious => _currentIndex > 0;

  /// 下一首索引
  int get nextIndex => hasNext ? _currentIndex + 1 : 0;

  /// 上一首索引
  int get previousIndex => hasPrevious ? _currentIndex - 1 : _queue.length - 1;

  /// 通过索引获取音频
  PlayableAudio? operator [](int index) {
    if (index >= 0 && index < _queue.length) {
      return _queue[index];
    }
    return null;
  }

  // ==================== 回调设置 ====================

  /// 设置队列变化回调
  void setOnQueueChanged(Function()? callback) {
    _onQueueChanged = callback;
  }

  /// 通知队列已变化
  void _notifyChanged() {
    _onQueueChanged?.call();
  }

  // ==================== 队列操作 ====================

  /// 设置播放队列
  ///
  /// [queue] 新的播放队列
  /// [initialIndex] 初始播放索引（默认 -1，表示不自动播放）
  /// [syncLocal] 是否同步到本地音频数据库
  void setQueue(
    List<PlayableAudio> queue, {
    int initialIndex = -1,
    bool syncLocal = true,
  }) {
    _queue.clear();
    _queue.addAll(queue);
    _currentIndex = initialIndex;

    if (syncLocal) {
      _syncToLocal();
    }

    _notifyChanged();
    AppLogger.debug('PlaybackQueueManager', '设置播放队列，长度: ${queue.length}');
  }

  /// 添加到播放队列
  ///
  /// [playable] 要添加的音频
  /// [playImmediately] 是否立即播放（设置为当前音频）
  /// [syncLocal] 是否同步到本地音频数据库
  Future<void> add(
    PlayableAudio playable, {
    bool playImmediately = false,
    bool syncLocal = true,
  }) async {
    // 检查是否已存在
    final existingIndex = _queue.indexWhere((p) => p.id == playable.id);

    if (playImmediately) {
      if (existingIndex != -1) {
        // 已存在，直接设置为当前
        _currentIndex = existingIndex;
      } else {
        // 不存在，添加并设置为当前
        _queue.add(playable);
        _currentIndex = _queue.length - 1;
      }
    } else {
      // 不立即播放，添加到末尾（如果不存在）
      if (existingIndex == -1) {
        _queue.add(playable);
      }
    }

    // 先同步数据库，确认成功后再通知UI
    if (syncLocal && playable is LocalPlayable) {
      final updatedAudio = await _addLocalToDatabase(playable.original);
      if (updatedAudio == null) {
        // 数据库写入失败，回滚内存操作
        if (existingIndex == -1) {
          _queue.removeWhere((p) => p.id == playable.id);
        }
        if (_currentIndex >= _queue.length) {
          _currentIndex = _queue.isEmpty ? -1 : _queue.length - 1;
        }
        AppLogger.error('PlaybackQueueManager', '数据库写入失败，回滚添加操作');
        return;
      }

      // 更新 _queue 中的 LocalPlayable，使用带数据库ID的 LocalAudio
      // 这样 LocalPlayable.id 会使用正确的数据库ID，而不是filePath.hashCode
      final updatedPlayable = LocalPlayable(updatedAudio);
      final queueIndex = _queue.indexWhere((p) => p.id == playable.id);
      if (queueIndex != -1) {
        _queue[queueIndex] = updatedPlayable;
        AppLogger.debug('PlaybackQueueManager', '更新队列中的本地音频ID: ${playable.id} -> ${updatedPlayable.id}');
      }
    }

    _notifyChanged();
    AppLogger.info('PlaybackQueueManager', '添加音频: ${playable.title}, 总数: ${_queue.length}');
  }

  /// 批量添加到播放队列
  ///
  /// [playables] 要添加的音频列表
  /// [syncLocal] 是否同步到本地音频数据库
  Future<void> addAll(
    List<PlayableAudio> playables, {
    bool syncLocal = true,
  }) async {
    for (final playable in playables) {
      // 检查是否已存在
      if (!_queue.any((p) => p.id == playable.id)) {
        _queue.add(playable);

        if (syncLocal && playable is LocalPlayable) {
          await _addLocalToDatabase(playable.original);
        }
      }
    }

    _notifyChanged();
    AppLogger.info('PlaybackQueueManager', '批量添加 ${playables.length} 首音频');
  }

  /// 从队列移除指定索引的项
  ///
  /// [index] 要移除的索引
  /// [syncLocal] 是否同步到本地音频数据库
  Future<void> removeAt(int index, {bool syncLocal = true}) async {
    if (index < 0 || index >= _queue.length) return;

    final playable = _queue[index];

    // 如果是本地音频，从数据库删除
    if (syncLocal && playable is LocalPlayable) {
      await _removeLocalFromDatabase(playable.original);
    }

    // 移除
    _queue.removeAt(index);

    // 调整当前索引
    if (_currentIndex == index) {
      // 删除的是当前播放项，重置索引
      _currentIndex = -1;
    } else if (_currentIndex > index) {
      // 删除的是当前项之前的项，索引前移
      _currentIndex--;
    }

    _notifyChanged();
    AppLogger.info('PlaybackQueueManager', '移除索引 $index 的音频');
  }

  /// 根据ID从队列移除
  ///
  /// [id] 音频ID
  /// [syncLocal] 是否同步到本地音频数据库
  Future<void> removeById(String id, {bool syncLocal = true}) async {
    final index = _queue.indexWhere((p) => p.id == id);
    if (index != -1) {
      await removeAt(index, syncLocal: syncLocal);
    }
  }

  /// 清空播放队列
  ///
  /// [syncLocal] 是否同步到本地音频数据库
  Future<void> clear({bool syncLocal = true}) async {
    // 如果是本地音频，从数据库删除
    if (syncLocal) {
      for (final playable in _queue) {
        if (playable is LocalPlayable) {
          await _removeLocalFromDatabase(playable.original);
        }
      }
    }

    _queue.clear();
    _currentIndex = -1;

    _notifyChanged();
    AppLogger.info('PlaybackQueueManager', '清空播放队列');
  }

  /// 设置当前索引
  ///
  /// [index] 新的索引
  /// [validate] 是否验证索引有效性
  void setCurrentIndex(int index, {bool validate = true}) {
    if (validate && (index < 0 || index >= _queue.length)) {
      AppLogger.warn('PlaybackQueueManager', '无效的索引: $index, 队列长度: ${_queue.length}');
      return;
    }
    _currentIndex = index;
    _notifyChanged();
    AppLogger.debug('PlaybackQueueManager', '设置当前索引: $index');
  }

  // ==================== 本地数据库同步 ====================

  /// 从本地数据库同步
  ///
  /// 将数据库中的本地音频加载到队列
  Future<void> syncFromLocal() async {
    final dbManager = PlaylistManager();
    final audios = await dbManager.getAllAudios();

    _localAudios.clear();
    _localAudios.addAll(audios);

    // 保留在线音频
    final onlinePlayables = _queue.whereType<OnlinePlayable>().toList();

    _queue.clear();

    // 添加本地音频（转换为 LocalPlayable）
    for (final audio in audios) {
      _queue.add(LocalPlayable(audio));
    }

    // 恢复在线音频
    _queue.addAll(onlinePlayables);

    AppLogger.info('PlaybackQueueManager', '从数据库同步，本地音频: ${audios.length}, 在线音频: ${onlinePlayables.length}');
  }

  /// 同步本地音频到数据库
  void _syncToLocal() {
    // 当前实现中，本地音频通过 add() 方法时已经同步到数据库
    // 此方法保留用于批量同步场景
    AppLogger.debug('PlaybackQueueManager', '同步到本地数据库');
  }

  /// 添加本地音频到数据库
  Future<LocalAudio?> _addLocalToDatabase(LocalAudio audio) async {
    final dbManager = PlaylistManager();
    final id = await dbManager.insertAudio(audio);

    if (id <= 0) {
      // 已存在，获取现有记录
      final existing = await dbManager.getAllAudios();
      final match = existing.firstWhere(
        (a) => a.filePath == audio.filePath,
        orElse: () => audio,
      );
      AppLogger.debug('PlaybackQueueManager', '音频已存在于数据库: ${match.id}');
      return match;
    }

    // 获取插入的记录（包含生成的ID）
    if (id != null) {
      final inserted = await dbManager.getAudioById(id);
      AppLogger.debug('PlaybackQueueManager', '音频已添加到数据库: $id');
      return inserted;
    }
    return null;
  }

  /// 从数据库移除本地音频
  Future<void> _removeLocalFromDatabase(LocalAudio audio) async {
    if (audio.id == null || audio.id! <= 0) return;

    final dbManager = PlaylistManager();
    await dbManager.deleteAudio(audio.id!);
    AppLogger.debug('PlaybackQueueManager', '从数据库移除音频: ${audio.id}');
  }

  // ==================== 持久化 ====================

  /// 保存播放状态
  ///
  /// 保存当前索引和在线状态到 SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    // 保存当前索引
    await prefs.setInt(StorageKeys.keyLastIndex, _currentIndex);

    // 保存当前音频是否是在线音频
    final current = currentPlayable;
    final isOnline = current?.isOnline ?? false;
    await prefs.setBool(StorageKeys.keyWasOnline, isOnline);

    AppLogger.debug('PlaybackQueueManager', '保存播放状态: index=$_currentIndex, isOnline=$isOnline');
  }

  /// 恢复播放状态
  ///
  /// 返回保存的播放位置（毫秒）
  Future<int?> restore() async {
    final prefs = await SharedPreferences.getInstance();

    // 恢复索引
    final savedIndex = prefs.getInt(StorageKeys.keyLastIndex) ?? -1;
    if (savedIndex >= 0 && savedIndex < _queue.length) {
      _currentIndex = savedIndex;
      AppLogger.debug('PlaybackQueueManager', '恢复播放索引: $_currentIndex');
    }

    // 从数据库恢复播放位置
    final dbManager = PlaylistManager();
    final state = await dbManager.getPlaybackState();
    if (state != null) {
      final position = state['position'] as int? ?? 0;
      AppLogger.debug('PlaybackQueueManager', '恢复播放位置: ${position}ms');
      return position;
    }

    return null;
  }

  /// 获取保存的在线状态
  Future<bool> getSavedOnlineState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.keyWasOnline) ?? false;
  }

  /// 保存播放位置到数据库
  Future<void> savePosition(int position) async {
    final current = currentPlayable;
    if (current == null) return;

    int audioId = 0;
    if (current is LocalPlayable) {
      audioId = current.original.id ?? 0;
    } else {
      // 在线音频，使用哈希作为ID
      audioId = current.id.hashCode.abs();
    }

    final dbManager = PlaylistManager();
    await dbManager.savePlaybackState(
      audioId: audioId,
      position: position,
      currentIndex: _currentIndex,
    );
  }
}
