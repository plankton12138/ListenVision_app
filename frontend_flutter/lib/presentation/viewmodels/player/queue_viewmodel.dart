import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/local_audio.dart';
import '../../../models/playable_audio.dart';
import '../../../models/local_playable.dart';
import '../../../models/online_playable.dart';
import 'player_viewmodel.dart' show sharedStorageServiceProvider;

part 'queue_viewmodel.freezed.dart';
part 'queue_viewmodel.g.dart';

/// 播放队列状态
@freezed
class QueueState with _$QueueState {
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
  }) = _QueueState;
}

/// 播放队列 ViewModel
///
/// 职责：
/// 1. 播放队列管理（添加、删除、清空）
/// 2. 当前播放索引
/// 3. 下一首/上一首
/// 4. 持久化播放队列
class QueueViewModel extends StateNotifier<QueueState> {
  final SharedStorageService _storage;

  /// 是否已销毁
  bool _disposed = false;

  QueueViewModel({
    required SharedStorageService storage,
  })  : _storage = storage,
        super(const QueueState()) {
    _init();
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

  // ==================== Getters ====================

  /// 获取当前状态（公开 getter）
  QueueState get queueState => state;

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
  int get previousIndex => hasPrevious ? state.currentIndex - 1 : state.queue.length - 1;

  // ==================== 队列操作 ====================

  /// 设置播放队列
  Future<void> setQueue(
    List<PlayableAudio> queue, {
    int initialIndex = -1,
  }) async {
    state = state.copyWith(
      queue: queue,
      currentIndex: initialIndex,
    );

    await _saveToStorage();
    AppLogger.debug('QueueViewModel', '设置播放队列，长度: ${queue.length}');
  }

  /// 添加到播放队列
  ///
  /// [playable] 要添加的音频
  /// [playImmediately] 是否立即播放（设置为当前音频）
  Future<void> add(
    PlayableAudio playable, {
    bool playImmediately = false,
  }) async {
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

    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
    );

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '添加音频: ${playable.title}, 总数: ${newQueue.length}');
  }

  /// 批量添加到播放队列
  Future<void> addAll(
    List<PlayableAudio> playables,
  ) async {
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

    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
    );

    await _saveToStorage();
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
    state = const QueueState();

    await _saveToStorage();
    AppLogger.info('QueueViewModel', '清空播放队列');
  }

  /// 设置当前索引
  ///
  /// [index] 新的索引
  void setCurrentIndex(int index) {
    if (index < 0 || index >= state.queue.length) {
      AppLogger.warn('QueueViewModel', '无效的索引: $index, 队列长度: ${state.queue.length}');
      return;
    }

    state = state.copyWith(currentIndex: index);
    AppLogger.debug('QueueViewModel', '设置当前索引: $index');
  }

  /// 播放下一首
  ///
  /// 返回下一首的音频，如果没有则返回 null
  PlayableAudio? playNext() {
    if (isEmpty) return null;

    final nextIndex = hasNext ? state.currentIndex + 1 : 0;
    setCurrentIndex(nextIndex);

    AppLogger.info('QueueViewModel', '播放下一首，索引: $nextIndex');
    return currentPlayable;
  }

  /// 播放上一首
  ///
  /// 返回上一首的音频，如果没有则返回 null
  PlayableAudio? playPrevious() {
    if (isEmpty) return null;

    final previousIndex = hasPrevious ? state.currentIndex - 1 : state.queue.length - 1;
    setCurrentIndex(previousIndex);

    AppLogger.info('QueueViewModel', '播放上一首，索引: $previousIndex');
    return currentPlayable;
  }

  // ==================== 本地音频管理 ====================

  /// 添加本地音频到队列
  Future<void> addLocalAudio(LocalAudio audio, {bool playImmediately = false}) async {
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
    final newLocalAudios = state.localAudios.where((a) => a.filePath != filePath).toList();

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
    // TODO: 实现 PlaylistManager 集成
  }

  // ==================== 持久化 ====================

  /// 保存到存储
  Future<void> _saveToStorage() async {
    try {
      // 保存当前索引
      await _storage.setInt(
        StorageKeys.currentPlaylistIndex,
        state.currentIndex,
      );

      // 保存队列（转为 JSON）
      final queueJson = state.queue.map((p) => p.toMap()).toList();
      await _storage.setJsonList(StorageKeys.unifiedPlaylist, queueJson);

      AppLogger.debug('QueueViewModel', '保存播放队列: 索引=${state.currentIndex}, 长度=${state.queue.length}');
    } catch (e) {
      AppLogger.error('QueueViewModel', '保存播放队列失败: $e');
    }
  }

  /// 从存储加载
  Future<void> _loadFromStorage() async {
    try {
      // 加载索引
      final savedIndex = _storage.getInt(StorageKeys.currentPlaylistIndex) ?? -1;

      // 加载队列
      final queueJson = _storage.getJsonList(StorageKeys.unifiedPlaylist);

      if (queueJson != null && queueJson.isNotEmpty) {
        final queue = <PlayableAudio>[];
        for (final item in queueJson) {
          if (item is Map<String, dynamic>) {
            final playableType = item['playableType'] as String?;
            if (playableType == 'online') {
              queue.add(OnlinePlayable.fromMap(item));
            } else if (playableType == 'local') {
              queue.add(LocalPlayable.fromMap(item));
            }
          }
        }

        state = state.copyWith(
          queue: queue,
          currentIndex: savedIndex >= 0 && savedIndex < queue.length ? savedIndex : -1,
        );

        AppLogger.info('QueueViewModel', '加载播放队列: 索引=$savedIndex, 长度=${queue.length}');
      }
    } catch (e) {
      AppLogger.error('QueueViewModel', '加载播放队列失败: $e');
    }
  }

  /// 保存播放位置
  Future<void> savePosition(int position) async {
    try {
      await _storage.setInt(StorageKeys.currentPlaybackPosition, position);
      AppLogger.debug('QueueViewModel', '保存播放位置: $position秒');
    } catch (e) {
      AppLogger.error('QueueViewModel', '保存播放位置失败: $e');
    }
  }

  /// 恢复播放位置
  Future<int?> restorePosition() async {
    try {
      final position = _storage.getInt(StorageKeys.currentPlaybackPosition);
      AppLogger.debug('QueueViewModel', '恢复播放位置: $position秒');
      return position;
    } catch (e) {
      AppLogger.error('QueueViewModel', '恢复播放位置失败: $e');
      return null;
    }
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    AppLogger.debug('QueueViewModel', '已释放');
    super.dispose();
  }
}

// ==================== Providers ====================

/// QueueViewModel Provider
@riverpod
QueueViewModel queueViewModel(QueueViewModelRef ref) {
  final storage = ref.watch(sharedStorageServiceProvider);
  return QueueViewModel(storage: storage);
}
