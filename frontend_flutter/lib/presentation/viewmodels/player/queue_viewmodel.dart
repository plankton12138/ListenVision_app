import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/local_audio.dart';
import '../../../models/playable_audio.dart';
import '../../../models/local_playable.dart';
import '../../../models/play_queue.dart';
import '../../../models/play_mode.dart';
import '../../../models/queue_source.dart';
import '../library/playlist_viewmodel.dart' show sharedStorageServiceProvider;
import 'playback_viewmodel.dart';

part 'queue_viewmodel.freezed.dart';
part 'queue_viewmodel.g.dart';

/// 播放队列状态
@freezed
abstract class QueueState with _$QueueState {
  const factory QueueState({
    /// 播放队列
    PlayQueue? queue,
    /// 本地音频列表
    @Default([]) List<LocalAudio> localAudios,
    /// 是否正在加载
    @Default(false) bool isLoading,
    /// 错误消息
    String? errorMessage,
  }) = _QueueState;
}

/// 播放队列 ViewModel（Riverpod 3.0 Notifier 模式）
///
/// 职责：
/// 1. 播放队列管理（添加、删除、清空）
/// 2. 当前播放索引管理
/// 3. 播放模式管理
/// 4. 持久化播放队列
///
/// 注意：播放控制逻辑已移至 PlaybackViewModel
@Riverpod(keepAlive: true)
class QueueViewModel extends _$QueueViewModel {
  SharedStorageService? _storage;
  bool _isRestoringFromStorage = false;
  bool _didFinishInitialRestore = false;
  bool _skipInitialRestore = false;

  /// 恢复版本号，用于取消过期的自动恢复回调
  /// 当用户主动操作时递增，使旧的回调失效
  int _restoreVersion = 0;

  /// 队列恢复完成回调列表
  final List<void Function()> _onQueueRestoredCallbacks = [];

  @override
  QueueState build() {
    _storage = ref.watch(sharedStorageServiceProvider);

    // 延迟初始化
    Future.microtask(_init);

    return const QueueState();
  }

  /// 初始化
  Future<void> _init() async {
    try {
      await _loadFromStorage();
      AppLogger.info('QueueViewModel', '初始化完成，队列长度: ${state.queue?.tracks.length ?? 0}');
    } catch (e) {
      AppLogger.error('QueueViewModel', '初始化失败: $e');
    }
  }

  /// 注册队列恢复完成回调
  ///
  /// 如果队列已恢复完成，回调会立即执行
  /// 否则回调会在队列恢复完成后执行
  void onQueueRestored(void Function() callback) {
    if (_didFinishInitialRestore) {
      callback();
    } else {
      _onQueueRestoredCallbacks.add(callback);
    }
  }

  // ==================== Getters ====================

  /// 当前可播放音频
  PlayableAudio? get currentPlayable {
    final q = state.queue;
    if (q == null) return null;
    if (q.currentIndex >= 0 && q.currentIndex < q.tracks.length) {
      return q.tracks[q.currentIndex];
    }
    return null;
  }

  /// 队列是否为空
  bool get isEmpty => state.queue?.tracks.isEmpty ?? true;

  /// 队列长度
  int get length => state.queue?.tracks.length ?? 0;

  /// 是否有下一首
  bool get hasNext =>
      state.queue != null && state.queue!.currentIndex < state.queue!.tracks.length - 1;

  /// 是否有上一首
  bool get hasPrevious => state.queue != null && state.queue!.currentIndex > 0;

  /// 下一首索引
  int get nextIndex => hasNext ? state.queue!.currentIndex + 1 : 0;

  /// 上一首索引
  int get previousIndex =>
      hasPrevious ? state.queue!.currentIndex - 1 : (state.queue!.tracks.length - 1);

  // ==================== 队列操作 ====================

  /// 设置播放队列
  Future<void> setQueue(
    List<PlayableAudio> queue, {
    int initialIndex = -1,
  }) async {
    _markQueueMutated();
    state = state.copyWith(
      queue: PlayQueue(
        tracks: queue,
        currentIndex: initialIndex,
        playMode: state.queue?.playMode ?? PlayMode.sequence,
        source: state.queue?.source,
      ),
    );

    await _saveToStorage();
    AppLogger.debug('QueueViewModel', '设置播放队列，长度: ${queue.length}');
  }

  /// 设置播放队列（带来源）
  ///
  /// 从歌单、收藏等来源设置播放队列，记录来源信息便于追溯
  Future<void> setQueueFromPlaylist(
    List<PlayableAudio> queue,
    QueueSource source, {
    int initialIndex = -1,
  }) async {
    _markQueueMutated();
    state = state.copyWith(
      queue: PlayQueue(
        tracks: queue,
        currentIndex: initialIndex,
        playMode: state.queue?.playMode ?? PlayMode.sequence,
        source: source,
      ),
    );

    await _saveToStorage();
    AppLogger.info(
      'QueueViewModel',
      '设置播放队列: ${queue.length}首, 来源: ${source.name}',
    );
  }

  /// 切换播放模式
  void togglePlayMode() {
    final q = state.queue;
    if (q == null) return;
    final newMode = q.playMode.next();
    state = state.copyWith(queue: q.copyWith(playMode: newMode));
    AppLogger.info('QueueViewModel', '切换播放模式: ${newMode.displayName}');
  }

  /// 设置播放模式
  void setPlayMode(PlayMode mode) {
    final q = state.queue;
    if (q == null) return;
    state = state.copyWith(queue: q.copyWith(playMode: mode));
    AppLogger.info('QueueViewModel', '设置播放模式: ${mode.displayName}');
  }

  /// 添加到播放队列
  ///
  /// [playable] 要添加的音频
  /// [playImmediately] 是否立即播放（设置为当前音频）
  Future<void> add(
    PlayableAudio playable, {
    bool playImmediately = false,
  }) async {
    _markQueueMutated();

    final q = state.queue ?? PlayQueue(tracks: [], currentIndex: -1);
    final newTracks = List<PlayableAudio>.from(q.tracks);

    // 检查是否已存在
    final existingIndex = newTracks.indexWhere((p) => p.id == playable.id);

    int newIndex = q.currentIndex;

    if (playImmediately) {
      if (existingIndex != -1) {
        // 已存在，直接设置为当前
        newIndex = existingIndex;
      } else {
        // 不存在，添加并设置为当前
        newTracks.add(playable);
        newIndex = newTracks.length - 1;
      }
    } else {
      // 不立即播放，添加到末尾（如果不存在）
      if (existingIndex == -1) {
        newTracks.add(playable);
      }
    }

    state = state.copyWith(queue: q.copyWith(tracks: newTracks, currentIndex: newIndex));

    await _saveToStorage();
    AppLogger.info(
      'QueueViewModel',
      '添加音频: ${playable.title}, 总数: ${newTracks.length}',
    );
  }

  /// 批量添加到播放队列
  Future<void> addAll(List<PlayableAudio> playables) async {
    _markQueueMutated();

    final q = state.queue ?? PlayQueue(tracks: [], currentIndex: -1);
    final newTracks = List<PlayableAudio>.from(q.tracks);

    for (final playable in playables) {
      // 检查是否已存在
      if (!newTracks.any((p) => p.id == playable.id)) {
        newTracks.add(playable);
      }
    }

    state = state.copyWith(queue: q.copyWith(tracks: newTracks));

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '批量添加 ${playables.length} 首音频');
  }

  /// 从队列移除指定索引的项
  ///
  /// [index] 要移除的索引
  Future<void> removeAt(int index) async {
    final q = state.queue;
    if (q == null) return;
    if (index < 0 || index >= q.tracks.length) return;

    _markQueueMutated();
    final newTracks = List<PlayableAudio>.from(q.tracks);
    newTracks.removeAt(index);

    // 调整当前索引
    int newIndex = q.currentIndex;
    if (q.currentIndex == index) {
      // 删除的是当前播放项，重置索引
      newIndex = -1;
    } else if (q.currentIndex > index) {
      // 删除的是当前项之前的项，索引前移
      newIndex--;
    }

    state = state.copyWith(queue: q.copyWith(tracks: newTracks, currentIndex: newIndex));

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '移除索引 $index 的音频');
  }

  /// 根据ID从队列移除
  ///
  /// [id] 音频ID
  Future<void> removeById(String id) async {
    final q = state.queue;
    if (q == null) return;
    final index = q.tracks.indexWhere((p) => p.id == id);
    if (index != -1) {
      await removeAt(index);
    }
  }

  /// 清空播放队列
  Future<void> clear() async {
    _markQueueMutated();
    state = state.copyWith(queue: null);

    await _saveToStorage();

    // 通知播放器停止，回到无播放内容状态
    ref.read(playbackViewModelProvider.notifier).stop();

    AppLogger.info('QueueViewModel', '清空播放队列');
  }

  /// 设置当前索引
  ///
  /// [index] 新的索引
  void setCurrentIndex(int index) {
    final q = state.queue;
    if (q == null) return;
    if (index < 0 || index >= q.tracks.length) {
      AppLogger.warn(
        'QueueViewModel',
        '无效的索引: $index, 队列长度: ${q.tracks.length}',
      );
      return;
    }

    _markQueueMutated();
    state = state.copyWith(queue: q.copyWith(currentIndex: index));
    AppLogger.debug('QueueViewModel', '设置当前索引: $index');
  }

  /// 拖拽排序
  ///
  /// 将 [oldIndex] 位置的项移动到 [newIndex]
  Future<void> reorder(int oldIndex, int newIndex) async {
    final q = state.queue;
    if (q == null) return;
    if (oldIndex < 0 || oldIndex >= q.tracks.length) return;
    if (newIndex < 0 || newIndex >= q.tracks.length) return;
    if (oldIndex == newIndex) return;

    _markQueueMutated();
    final newTracks = List<PlayableAudio>.from(q.tracks);
    final item = newTracks.removeAt(oldIndex);
    newTracks.insert(newIndex, item);

    // 调整当前播放索引
    int newCurrentIndex = q.currentIndex;
    if (q.currentIndex == oldIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < q.currentIndex && newIndex >= q.currentIndex) {
      newCurrentIndex--;
    } else if (oldIndex > q.currentIndex && newIndex <= q.currentIndex) {
      newCurrentIndex++;
    }

    state = state.copyWith(
      queue: q.copyWith(tracks: newTracks, currentIndex: newCurrentIndex),
    );

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '拖拽排序: $oldIndex -> $newIndex');
  }

  /// 插队播放（下一首播放）
  ///
  /// 将 [playable] 插入到当前播放位置的下一首
  Future<void> insertNext(PlayableAudio playable) async {
    _markQueueMutated();
    if (isEmpty) {
      // 队列为空，直接添加并播放
      await add(playable, playImmediately: true);
      return;
    }

    final q = state.queue!;
    final newTracks = List<PlayableAudio>.from(q.tracks);
    final insertIndex = q.currentIndex + 1;

    // 检查是否已存在
    final existingIndex = newTracks.indexWhere((p) => p.id == playable.id);

    // 边界情况：如果 currentIndex == -1，重置为 0
    int newCurrentIndex = q.currentIndex == -1 ? 0 : q.currentIndex;

    if (existingIndex != -1) {
      // 已存在，需要先移除
      newTracks.removeAt(existingIndex);

      // 调整 currentIndex：如果移除位置在当前播放位置之前，需要 -1
      if (existingIndex < newCurrentIndex) {
        newCurrentIndex--;
      }

      // 重新计算插入位置（因为移除可能改变了索引）
      final adjustedInsertIndex = (existingIndex < insertIndex) ? insertIndex - 1 : insertIndex;

      newTracks.insert(adjustedInsertIndex, playable);

      // 如果插入位置在当前播放位置之前或等于当前位置，需要 +1
      if (adjustedInsertIndex <= newCurrentIndex) {
        newCurrentIndex++;
      }
    } else {
      // 不存在，直接插入
      newTracks.insert(insertIndex, playable);
    }

    state = state.copyWith(
      queue: q.copyWith(tracks: newTracks, currentIndex: newCurrentIndex),
    );

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '插队播放: ${playable.title}');
  }

  // ==================== 本地音频管理 ====================

  /// 添加本地音频到队列
  Future<void> addLocalAudio(
    LocalAudio audio, {
    bool playImmediately = false,
  }) async {
    _markQueueMutated();
    final playable = LocalPlayable(audio);
    await add(playable, playImmediately: playImmediately);

    // 更新本地音频列表
    final newLocalAudios = List<LocalAudio>.from(state.localAudios);
    if (!newLocalAudios.any((a) => a.filePath == audio.filePath)) {
      newLocalAudios.add(audio);
      state = state.copyWith(localAudios: newLocalAudios);
    }

    AppLogger.info('QueueViewModel', '添加本地音频: ${audio.title}');
  }

  /// 移除本地音频
  Future<void> removeLocalAudio(String filePath) async {
    _markQueueMutated();
    final newLocalAudios = state.localAudios.where((a) => a.filePath != filePath).toList();

    // 同时从队列中移除
    final q = state.queue;
    if (q != null) {
      final newTracks = q.tracks.where((p) => p.url != filePath).toList();

      // 重新计算索引
      int newIndex = q.currentIndex;
      if (q.currentIndex >= newTracks.length) {
        newIndex = newTracks.isEmpty ? -1 : newTracks.length - 1;
      }

      state = state.copyWith(
        localAudios: newLocalAudios,
        queue: newTracks.isEmpty ? null : q.copyWith(tracks: newTracks, currentIndex: newIndex),
      );
    } else {
      state = state.copyWith(localAudios: newLocalAudios);
    }

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '移除本地音频: $filePath');
  }

  /// 从本地数据库同步
  Future<void> syncFromLocal() async {
    AppLogger.debug('QueueViewModel', '从本地数据库同步（暂未实现）');
    // 后续可接入 PlaylistManager 统一管理队列来源
  }

  // ==================== 持久化 ====================

  /// 保存到存储（单 JSON key）
  Future<void> _saveToStorage() async {
    try {
      if (state.queue == null) {
        // 队列为空时清除持久化数据
        await _storage!.remove(StorageKeys.unifiedPlaylist);
        return;
      }
      final json = jsonEncode(state.queue!.toJson());
      await _storage!.setString(StorageKeys.unifiedPlaylist, json);

      AppLogger.debug(
        'QueueViewModel',
        '保存播放队列: 索引=${state.queue!.currentIndex}, 长度=${state.queue!.tracks.length}, 模式=${state.queue!.playMode.name}',
      );
    } catch (e) {
      AppLogger.error('QueueViewModel', '保存播放队列失败: $e');
    }
  }

  /// 从存储加载
  Future<void> _loadFromStorage() async {
    _isRestoringFromStorage = true;
    try {
      final json = _storage!.getString(StorageKeys.unifiedPlaylist);
      if (json == null || json.isEmpty) return;

      if (_skipInitialRestore) {
        AppLogger.info('QueueViewModel', '检测到初始化期间已有用户操作，跳过本地队列恢复');
        return;
      }

      try {
        final queue = PlayQueue.fromJson(jsonDecode(json));

        if (_skipInitialRestore) {
          AppLogger.info('QueueViewModel', '本地队列恢复过程中检测到用户操作，取消覆盖当前队列');
          return;
        }

        if (!ref.mounted) return;
        state = state.copyWith(queue: queue);

        AppLogger.info(
          'QueueViewModel',
          '加载播放队列: 索引=${queue.currentIndex}, 长度=${queue.tracks.length}, 模式=${queue.playMode.name}, 来源=${queue.source?.name ?? "无"}',
        );
      } catch (e) {
        AppLogger.error('QueueViewModel', '恢复队列失败: $e');
      }
    } catch (e) {
      AppLogger.error('QueueViewModel', '加载播放队列失败: $e');
    } finally {
      _isRestoringFromStorage = false;
      _didFinishInitialRestore = true;

      // 执行恢复完成回调
      for (final callback in _onQueueRestoredCallbacks) {
        callback();
      }
      _onQueueRestoredCallbacks.clear();
    }
  }

  void _markQueueMutated() {
    if (_isRestoringFromStorage && !_didFinishInitialRestore) {
      _skipInitialRestore = true;
    }
    // 用户主动操作时递增版本号，使旧的自动恢复回调失效
    _restoreVersion++;
    AppLogger.debug('QueueViewModel', '用户操作，恢复版本号递增至: $_restoreVersion');
  }

  /// 保存播放位置
  Future<void> savePosition(int position) async {
    try {
      await _storage!.setInt(StorageKeys.currentPlaybackPosition, position);
      AppLogger.debug('QueueViewModel', '保存播放位置: $position秒');
    } catch (e) {
      AppLogger.error('QueueViewModel', '保存播放位置失败: $e');
    }
  }

  /// 恢复播放位置
  Future<int?> restorePosition() async {
    try {
      final position = _storage!.getInt(StorageKeys.currentPlaybackPosition);
      AppLogger.debug('QueueViewModel', '恢复播放位置: $position秒');
      return position;
    } catch (e) {
      AppLogger.error('QueueViewModel', '恢复播放位置失败: $e');
      return null;
    }
  }
}
