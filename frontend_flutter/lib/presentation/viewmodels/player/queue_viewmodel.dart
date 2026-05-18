import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/local_audio.dart';
import '../../../models/playable_audio.dart';
import '../../../models/local_playable.dart';
import '../../../models/online_playable.dart';
import '../../../models/queue_source.dart';
import '../../../models/play_mode.dart';
import '../auth/auth_provider.dart' show isLoggedInProvider;
import '../library/playlist_viewmodel.dart' show playlistViewModelProvider, sharedStorageServiceProvider;

part 'queue_viewmodel.freezed.dart';
part 'queue_viewmodel.g.dart';

/// 播放队列状态
@freezed
abstract class QueueState with _$QueueState {
  /// 初始状态
  const factory QueueState({
    /// 播放队列（本地和在线混合）
    @Default([]) List<PlayableAudio> queue,

    /// 本地音频列表
    @Default([]) List<LocalAudio> localAudios,

    /// 当前播放索引
    @Default(-1) int currentIndex,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 错误消息
    String? errorMessage,

    /// 播放模式
    @Default(PlayMode.sequence) PlayMode playMode,

    /// 队列来源
    QueueSource? source,
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
  Timer? _syncDebounceTimer;
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
      AppLogger.info('QueueViewModel', '初始化完成，队列长度: ${state.queue.length}');
    } catch (e) {
      AppLogger.error('QueueViewModel', '初始化失败: $e');
    }
  }

  /// 注册队列恢复完成回调
  ///
  /// 如果队列已恢复完成，回调会立即执行
  /// 否则回调会在队列恢复完成后执行
  ///
  /// ## 为什么不需要取消注册机制
  ///
  /// 虽然看起来可以多次注册回调，但以下设计保证不会产生问题：
  ///
  /// 1. **Provider 生命周期**：`QueueViewModel` 和 `PlaybackViewModel` 都是
  ///    `keepAlive: true`，在整个 App 生命周期内只存在一个实例，不会因页面
  ///    重建而重新创建。
  ///
  /// 2. **回调自动清理**：恢复完成后，`_onQueueRestoredCallbacks` 会被清空
  ///    （见 `_loadFromStorage` 的 finally 块）。
  ///
  /// 3. **回调幂等性**：`prepareCurrentFromQueue()` 会验证队列索引有效性，
  ///    多次调用不会产生副作用。
  ///
  /// 4. **唯一注册时机**：回调仅在 `HomePage.initState` 中注册，该页面是
  ///    主页面，通常不会被多次创建。即使被重建（如热重载），回调也会在
  ///    恢复完成后被立即执行并清空，不会累积。
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
    final index = state.currentIndex;
    if (index >= 0 && index < state.queue.length) {
      return state.queue[index];
    }
    return null;
  }

  /// 队列是否为空
  bool get isEmpty => state.queue.isEmpty;

  /// 队列长度
  int get length => state.queue.length;

  /// 是否有下一首
  bool get hasNext => state.currentIndex < state.queue.length - 1;

  /// 是否有上一首
  bool get hasPrevious => state.currentIndex > 0;

  /// 下一首索引
  int get nextIndex => hasNext ? state.currentIndex + 1 : 0;

  /// 上一首索引
  int get previousIndex =>
      hasPrevious ? state.currentIndex - 1 : state.queue.length - 1;

  // ==================== 队列操作 ====================

  /// 设置播放队列
  Future<void> setQueue(
    List<PlayableAudio> queue, {
    int initialIndex = -1,
  }) async {
    _markQueueMutated();
    state = state.copyWith(queue: queue, currentIndex: initialIndex);

    await _saveToStorage();
    _scheduleSyncToServer(); // 同步到后端
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
      queue: queue,
      currentIndex: initialIndex,
      source: source,
    );

    await _saveToStorage();
    _scheduleSyncToServer(); // 同步到后端
    AppLogger.info(
      'QueueViewModel',
      '设置播放队列: ${queue.length}首, 来源: ${source.name}',
    );
  }

  /// 切换播放模式
  void togglePlayMode() {
    final newMode = state.playMode.next();
    state = state.copyWith(playMode: newMode);
    AppLogger.info('QueueViewModel', '切换播放模式: ${newMode.displayName}');
  }

  /// 设置播放模式
  void setPlayMode(PlayMode mode) {
    state = state.copyWith(playMode: mode);
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
    final newQueue = List<PlayableAudio>.from(state.queue);

    // 检查是否已存在
    final existingIndex = newQueue.indexWhere((p) => p.id == playable.id);

    int newIndex = state.currentIndex;

    if (playImmediately) {
      if (existingIndex != -1) {
        // 已存在，直接设置为当前
        newIndex = existingIndex;
      } else {
        // 不存在，添加并设置为当前
        newQueue.add(playable);
        newIndex = newQueue.length - 1;
      }
    } else {
      // 不立即播放，添加到末尾（如果不存在）
      if (existingIndex == -1) {
        newQueue.add(playable);
      }
    }

    state = state.copyWith(queue: newQueue, currentIndex: newIndex);

    await _saveToStorage();
    _scheduleSyncToServer(); // 同步到后端
    AppLogger.info(
      'QueueViewModel',
      '添加音频: ${playable.title}, 总数: ${newQueue.length}',
    );
  }

  /// 批量添加到播放队列
  Future<void> addAll(List<PlayableAudio> playables) async {
    _markQueueMutated();
    final newQueue = List<PlayableAudio>.from(state.queue);

    for (final playable in playables) {
      // 检查是否已存在
      if (!newQueue.any((p) => p.id == playable.id)) {
        newQueue.add(playable);
      }
    }

    state = state.copyWith(queue: newQueue);

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '批量添加 ${playables.length} 首音频');
  }

  /// 从队列移除指定索引的项
  ///
  /// [index] 要移除的索引
  Future<void> removeAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    _markQueueMutated();
    final newQueue = List<PlayableAudio>.from(state.queue);
    newQueue.removeAt(index);

    // 调整当前索引
    int newIndex = state.currentIndex;
    if (state.currentIndex == index) {
      // 删除的是当前播放项，重置索引
      newIndex = -1;
    } else if (state.currentIndex > index) {
      // 删除的是当前项之前的项，索引前移
      newIndex--;
    }

    state = state.copyWith(queue: newQueue, currentIndex: newIndex);

    await _saveToStorage();
    _scheduleSyncToServer(); // 同步到后端
    AppLogger.info('QueueViewModel', '移除索引 $index 的音频');
  }

  /// 根据ID从队列移除
  ///
  /// [id] 音频ID
  Future<void> removeById(String id) async {
    final index = state.queue.indexWhere((p) => p.id == id);
    if (index != -1) {
      await removeAt(index);
    }
  }

  /// 清空播放队列
  Future<void> clear() async {
    _markQueueMutated();
    state = const QueueState();

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '清空播放队列');
  }

  /// 设置当前索引
  ///
  /// [index] 新的索引
  void setCurrentIndex(int index) {
    if (index < 0 || index >= state.queue.length) {
      AppLogger.warn(
        'QueueViewModel',
        '无效的索引: $index, 队列长度: ${state.queue.length}',
      );
      return;
    }

    _markQueueMutated();
    state = state.copyWith(currentIndex: index);
    AppLogger.debug('QueueViewModel', '设置当前索引: $index');
  }

/// 拖拽排序
  ///
  /// 将 [oldIndex] 位置的项移动到 [newIndex]
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.queue.length) return;
    if (newIndex < 0 || newIndex >= state.queue.length) return;
    if (oldIndex == newIndex) return;

    _markQueueMutated();
    final newQueue = List<PlayableAudio>.from(state.queue);
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);

    // 调整当前播放索引
    int newCurrentIndex = state.currentIndex;
    if (state.currentIndex == oldIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentIndex &&
        newIndex >= state.currentIndex) {
      newCurrentIndex--;
    } else if (oldIndex > state.currentIndex &&
        newIndex <= state.currentIndex) {
      newCurrentIndex++;
    }

    state = state.copyWith(queue: newQueue, currentIndex: newCurrentIndex);

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

    final newQueue = List<PlayableAudio>.from(state.queue);
    final insertIndex = state.currentIndex + 1;

    // 检查是否已存在
    final existingIndex = newQueue.indexWhere((p) => p.id == playable.id);

    // 边界情况：如果 currentIndex == -1，重置为 0
    int newCurrentIndex = state.currentIndex == -1 ? 0 : state.currentIndex;

    if (existingIndex != -1) {
      // 已存在，需要先移除
      newQueue.removeAt(existingIndex);

      // 调整 currentIndex：如果移除位置在当前播放位置之前，需要 -1
      if (existingIndex < newCurrentIndex) {
        newCurrentIndex--;
      }

      // 重新计算插入位置（因为移除可能改变了索引）
      final adjustedInsertIndex = (existingIndex < insertIndex)
          ? insertIndex - 1
          : insertIndex;

      newQueue.insert(adjustedInsertIndex, playable);

      // 如果插入位置在当前播放位置之前或等于当前位置，需要 +1
      if (adjustedInsertIndex <= newCurrentIndex) {
        newCurrentIndex++;
      }
    } else {
      // 不存在，直接插入
      newQueue.insert(insertIndex, playable);
    }

    state = state.copyWith(queue: newQueue, currentIndex: newCurrentIndex);

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
    final newLocalAudios = state.localAudios
        .where((a) => a.filePath != filePath)
        .toList();

    // 同时从队列中移除
    final newQueue = state.queue.where((p) => p.url != filePath).toList();

    // 重新计算索引
    int newIndex = state.currentIndex;
    if (state.currentIndex >= newQueue.length) {
      newIndex = newQueue.isEmpty ? -1 : newQueue.length - 1;
    }

    state = state.copyWith(
      localAudios: newLocalAudios,
      queue: newQueue,
      currentIndex: newIndex,
    );

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '移除本地音频: $filePath');
  }

  /// 从本地数据库同步
  Future<void> syncFromLocal() async {
    AppLogger.debug('QueueViewModel', '从本地数据库同步（暂未实现）');
    // 后续可接入 PlaylistManager 统一管理队列来源
  }

  // ==================== 持久化 ====================

  /// 保存到存储
  Future<void> _saveToStorage() async {
    try {
      // 保存当前索引
      await _storage!.setInt(
        StorageKeys.currentPlaylistIndex,
        state.currentIndex,
      );

      // 保存队列（转为 JSON）
      final queueJson = state.queue.map((p) => p.toMap()).toList();
      await _storage!.setJsonList(StorageKeys.unifiedPlaylist, queueJson);

      // 保存播放模式
      await _storage!.setString(StorageKeys.playMode, state.playMode.name);

      // 保存队列来源
      if (state.source != null) {
        await _storage!.setJson(
          StorageKeys.queueSource,
          state.source!.toJson(),
        );
      } else {
        await _storage!.remove(StorageKeys.queueSource);
      }

      AppLogger.debug(
        'QueueViewModel',
        '保存播放队列: 索引=${state.currentIndex}, 长度=${state.queue.length}, 模式=${state.playMode.name}',
      );
    } catch (e) {
      AppLogger.error('QueueViewModel', '保存播放队列失败: $e');
    }
  }

  /// 从存储加载
  Future<void> _loadFromStorage() async {
    _isRestoringFromStorage = true;
    try {
      // 加载索引
      final savedIndex =
          _storage!.getInt(StorageKeys.currentPlaylistIndex) ?? -1;

      // 加载播放模式
      final playModeName = _storage!.getString(StorageKeys.playMode);
      final playMode = playModeName != null
          ? PlayMode.values.firstWhere(
              (e) => e.name == playModeName,
              orElse: () => PlayMode.sequence,
            )
          : PlayMode.sequence;

      // 加载队列来源
      QueueSource? source;
      final sourceJson = _storage!.getJson(StorageKeys.queueSource);
      if (sourceJson != null) {
        try {
          source = QueueSource.fromJson(sourceJson);
        } catch (e) {
          AppLogger.warn('QueueViewModel', '加载队列来源失败: $e');
        }
      }

      // 加载队列
      final queueJson = _storage!.getJsonList(StorageKeys.unifiedPlaylist);

      if (queueJson != null && queueJson.isNotEmpty) {
        if (_skipInitialRestore) {
          AppLogger.info('QueueViewModel', '检测到初始化期间已有用户操作，跳过本地队列恢复');
          return;
        }

        final queue = <PlayableAudio>[];
        for (final item in queueJson) {
          if (item is Map<String, dynamic>) {
            final playableType = item['playableType'] as String?;
            if (playableType == 'online') {
              final id = (item['bvid'] ?? item['id'])?.toString() ?? '';
              final localPath = (item['filePath'] ?? item['localPath'])
                  ?.toString();
              // 兼容历史脏数据：本地音频被错误序列化为 online
              if (id.startsWith('local_')) {
                if (localPath != null && localPath.isNotEmpty) {
                  final duration = item['duration'];
                  final localAudio = LocalAudio(
                    filePath: localPath,
                    title: (item['title'] as String?) ?? '未知标题',
                    artist: (item['artist'] as String?) ?? '未知艺术家',
                    duration: duration is int
                        ? duration
                        : int.tryParse('$duration') ?? 0,
                  );
                  queue.add(LocalPlayable(localAudio));
                  AppLogger.warn(
                    'QueueViewModel',
                    '检测到历史本地队列数据，已按本地音频恢复: $localPath',
                  );
                } else {
                  AppLogger.warn('QueueViewModel', '跳过无本地路径的历史队列项: $id');
                }
              } else {
                queue.add(OnlinePlayable.fromMap(item));
              }
            } else if (playableType == 'local') {
              queue.add(LocalPlayable.fromMap(item));
            }
          }
        }

        if (_skipInitialRestore) {
          AppLogger.info('QueueViewModel', '本地队列恢复过程中检测到用户操作，取消覆盖当前队列');
          return;
        }

        if (!ref.mounted) return;
        state = state.copyWith(
          queue: queue,
          currentIndex: savedIndex >= 0 && savedIndex < queue.length
              ? savedIndex
              : -1,
          playMode: playMode,
          source: source,
        );

        AppLogger.info(
          'QueueViewModel',
          '加载播放队列: 索引=$savedIndex, 长度=${queue.length}, 模式=${playMode.name}, 来源=${source?.name ?? "无"}',
        );

        // 如果队列不为空，确保索引有效
        if (queue.isNotEmpty) {
          if (state.currentIndex < 0 || state.currentIndex >= queue.length) {
            state = state.copyWith(currentIndex: 0);
          }
          AppLogger.info('QueueViewModel', '队列恢复完成，索引: ${state.currentIndex}');
        }
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

  // ==================== 播放队列同步 ====================

  /// 安排同步到服务器（防抖 500ms）
  void _scheduleSyncToServer() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _syncNowPlayingToServer();
    });
  }

  /// 同步播放队列到后端
  Future<void> _syncNowPlayingToServer() async {
    // 未登录时不同步
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      AppLogger.debug('QueueViewModel', '未登录，跳过播放队列同步');
      return;
    }

    if (state.queue.isEmpty) return;

    try {
      // 需要导入 PlaylistItem 模型
      final items = <Map<String, dynamic>>[];

      for (final playable in state.queue) {
        if (playable is OnlinePlayable) {
          items.add({
            'bvid': playable.original.id,
            'title': playable.title,
            'artist': playable.artist,
            'duration': playable.original.duration,
            'coverUrl': playable.original.coverUrl,
          });
        }
      }

      if (items.isEmpty) return;

      // 调用 PlaylistViewModel 的 saveNowPlayingQueue 方法
      final playlistViewModel = ref.read(playlistViewModelProvider.notifier);
      await playlistViewModel.saveNowPlayingQueueFromItems(items);

      AppLogger.info('QueueViewModel', '播放队列已同步到后端: ${items.length}个');
    } catch (e) {
      AppLogger.error('QueueViewModel', '同步播放队列失败: $e');
    }
  }
}

