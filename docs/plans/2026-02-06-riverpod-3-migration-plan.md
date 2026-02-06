# Riverpod 3.0 全面迁移计划

> **目标**: 将项目状态管理从 Riverpod 2.x (StateNotifier) 迁移到 Riverpod 3.0 标准  
> **范围**: 所有 ViewModels 和相关 Widgets  
> **预计工期**: 3-5 天  
> **创建日期**: 2026-02-06

---

## 📋 目录

1. [背景与目标](#1-背景与目标)
2. [现状分析](#2-现状分析)
3. [迁移策略](#3-迁移策略)
4. [详细实施计划](#4-详细实施计划)
5. [代码规范](#5-代码规范)
6. [风险与回滚方案](#6-风险与回滚方案)
7. [测试策略](#7-测试策略)

---

## 1. 背景与目标

### 1.1 当前问题

- 使用 `StateNotifier` (Riverpod 3.0 已废弃，需从 `legacy.dart` 导入)
- Widget 监听 ViewModel 实例而非状态，导致 UI 不刷新
- 架构不符合 Riverpod 3.0 推荐标准

### 1.2 迁移目标

| 目标 | 说明 |
|-----|------|
| **标准化** | 使用 Riverpod 3.0 推荐的 `AsyncNotifier` / `Notifier` |
| **实时刷新** | 修复所有 UI 不刷新问题 |
| **副作用管理** | 使用 Mutations 处理异步操作（表单提交、按钮点击等）|
| **类型安全** | 统一使用代码生成，消除类型问题 |
| **可测试性** | 更好的依赖注入和测试支持 |

### 1.3 Riverpod 3.0 关键变化

```dart
// ❌ Riverpod 2.x (废弃)
class MyViewModel extends StateNotifier<MyState> { }

// ✅ Riverpod 3.0 (推荐)
@Riverpod(keepAlive: true)
class MyViewModel extends _$MyViewModel {
  @override
  MyState build() => const MyState();
}
```

---

## 2. 现状分析

### 2.1 受影响的 ViewModel (11个)

| # | ViewModel | 状态类 | 复杂度 | 优先级 |
|---|-----------|--------|--------|--------|
| 1 | `DownloadViewModel` | `DownloadModelState` | 高 | 🔴 P0 |
| 2 | `QueueViewModel` | `QueueState` | 高 | 🔴 P0 |
| 3 | `PlaylistViewModel` | `PlaylistState` | 高 | 🔴 P0 |
| 4 | `AuthViewModel` | `AuthState` | 中 | 🟡 P1 |
| 5 | `PlatformAuthViewModel` | `PlatformAuthState` | 中 | 🟡 P1 |
| 6 | `PlayerViewModel` | `PlayerState` | 高 | 🟡 P1 |
| 7 | `MetadataViewModel` | `MetadataState` | 低 | 🟢 P2 |
| 8 | `LocalMusicViewModel` | `LocalMusicState` | 中 | 🟢 P2 |
| 9 | `HistoryViewModel` | `HistoryState` | 低 | 🟢 P2 |
| 10 | `SearchViewModel` | `SearchState` | 中 | 🟢 P2 |
| 11 | `ThemeViewModel` | `AppThemeMode` | 低 | 🟢 P2 |

### 2.2 受影响的 View 文件

| # | 文件路径 | 问题 | 优先级 |
|---|----------|------|--------|
| 1 | `views/system/backend_download_page.dart` | 监听实例而非状态 | 🔴 P0 |
| 2 | `views/player/play_list_page.dart` | 监听实例而非状态 | 🔴 P0 |
| 3 | `views/library/playlist_library_page.dart` | 监听实例而非状态 | 🔴 P0 |
| 4 | `views/discovery/search_page.dart` | 监听实例而非状态 | 🟡 P1 |
| 5 | `views/library/local_music_playlist_page.dart` | 监听实例而非状态 | 🟢 P2 |
| 6 | `views/system/settings_page.dart` | 监听实例而非状态 | 🟢 P2 |
| 7 | `views/account/login_page.dart` | 使用 authViewModel | 🟢 P2 |
| 8 | `views/account/register_page.dart` | 使用 authViewModel | 🟢 P2 |
| 9 | `views/player/home_page.dart` | 使用多个 ViewModel | 🟢 P2 |

### 2.3 当前架构问题

```dart
// ============ 当前问题架构 ============

// 1. ViewModel 使用 StateNotifier (废弃)
class DownloadViewModel extends StateNotifier<DownloadModelState> {
  DownloadViewModel(this._repository) : super(const DownloadModelState.initial());
  
  DownloadModelState get downloadState => state;  // 多余的 getter
  
  Future<void> pauseDownload(int taskId) async {
    await _repository.pauseDownload(taskId);
    await _loadTasks();  // 手动刷新
  }
}

// 2. Provider 返回实例
@Riverpod(keepAlive: true)
DownloadViewModel downloadViewModel(DownloadViewModelRef ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  return DownloadViewModel(repository);  // 返回实例
}

// 3. Widget 监听实例 (❌ 错误)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(downloadViewModelProvider);  // 监听实例
    final state = viewModel.downloadState;  // 不会触发重建！
  }
}
```

---

## 3. 迁移策略

### 3.1 目标架构

```dart
// ============ Riverpod 3.0 目标架构（官方推荐）===========

// 1. 使用 AsyncNotifier (异步初始化)
@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel {
  DownloadRepository? _repository;

  @override
  Future<DownloadModelState> build() async {
    _repository = ref.watch(downloadRepositoryProvider);

    // 设置清理回调
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _progressSubscription?.cancel();
    });

    // 初始化逻辑
    final tasks = await _repository!.getAllTasks();
    return DownloadModelState.loaded(downloads: tasks);
  }

  // 官方推荐：异步操作后使用 ref.mounted 检查
  Future<void> pauseDownload(int taskId) async {
    await _repository!.pauseDownload(taskId);

    // 检查是否仍然挂载
    if (!ref.mounted) return;

    final tasks = await _repository!.getAllTasks();
    state = AsyncData(DownloadModelState.loaded(downloads: tasks));
  }
}

// 2. Widget 监听 AsyncValue
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 方式 1: 使用 AsyncValue.when 处理异步状态
    final asyncState = ref.watch(downloadViewModelProvider);

    return asyncState.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (state) => _buildList(state.downloads),
    );
  }

  // 方式 2: 使用 select 选择特定字段（性能优化）
  Widget buildWithSelect(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(
      downloadViewModelProvider.select((s) => s.valueOrNull?.downloads ?? []),
    );
    return _buildList(downloads);
  }
}

// 3. 调用 ViewModel 方法
class MyButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // 使用 .notifier 获取实例
        ref.read(downloadViewModelProvider.notifier).pauseDownload(1);
      },
      child: Text('暂停'),
    );
  }
}
```

### 3.2 迁移原则

| 原则 | 说明 |
|-----|------|
| **渐进式迁移** | 按优先级分批迁移，每批完成后测试 |
| **向后兼容** | 提供临时适配层，确保旧代码可用 |
| **单一职责** | 每个 ViewModel 只负责一个业务领域 |
| **不可变状态** | 状态类保持不可变，使用 `copyWith` 更新 |
| **异步优先** | 需要初始化的使用 `AsyncNotifier`，纯内存的使用 `Notifier` |

### 3.3 Provider 类型选择指南

| 场景 | 推荐类型 | 示例 |
|-----|---------|------|
| 需要异步初始化 | `AsyncNotifier` | Download, Playlist, Auth |
| 纯内存状态 | `Notifier` | Queue, Player, Theme |
| 流式数据 | `StreamNotifier` | 播放进度实时流 |
| 副作用管理 | `Mutation` | 表单提交、按钮点击 |

---

## 4. 详细实施计划

### Phase 1: 基础设施准备 (半天)

#### 4.1.1 更新依赖

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0
  
dev_dependencies:
  riverpod_generator: ^3.0.0
  riverpod_lint: ^3.0.0
  build_runner: ^2.4.0
```

#### 4.1.2 创建状态工具（可选）

```dart
// core/state/state_utils.dart

/// AsyncValue 扩展方法（官方推荐模式）
extension AsyncValueX<T> on AsyncValue<T> {
  bool get isLoading => this is AsyncLoading;
  bool get isError => this is AsyncError;
  bool get isData => this is AsyncData;

  /// 获取数据值或 null（Riverpod 3.0: valueOrNull 和 value 均可用，推荐 valueOrNull）
  T? get valueOrNull => whenOrNull(data: (value) => value);
  Object? get errorOrNull => whenOrNull(error: (error, _) => error);
  String? get errorMessageOrNull => whenOrNull(
        error: (error, _) => error.toString(),
      );
}
```

#### 4.1.3 官方推荐：使用 ref.mounted 检查

```dart
// ✅ 官方推荐模式：直接使用 ref.mounted
@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel {
  @override
  Future<DownloadModelState> build() async {
    final repository = ref.watch(downloadRepositoryProvider);

    ref.onDispose(() {
      // 清理资源
    });

    final tasks = await repository.getAllTasks();
    return DownloadModelState.loaded(downloads: tasks);
  }

  Future<void> pauseDownload(int taskId) async {
    await repository.pauseDownload(taskId);

    // 异步操作后检查是否仍然挂载
    if (!ref.mounted) return;

    final tasks = await repository.getAllTasks();
    state = AsyncData(DownloadModelState.loaded(downloads: tasks));
  }
}
```

---

### Phase 2: 核心 ViewModel 迁移 (2天)

#### 4.2.1 DownloadViewModel 迁移

**文件**: `lib/presentation/viewmodels/system/download_viewmodel.dart`

```dart
// ============ 迁移前 ============
class DownloadViewModel extends StateNotifier<DownloadModelState> {
  final DownloadRepository _repository;
  // ...
}

@Riverpod(keepAlive: true)
DownloadViewModel downloadViewModel(DownloadViewModelRef ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  return DownloadViewModel(repository);
}

// ============ 迁移后 ============
@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel {
  DownloadRepository? _repository;
  
  // 进度流订阅
  StreamSubscription<DownloadProgressEvent>? _progressSub;
  StreamSubscription<int>? _queueSub;
  Timer? _debounceTimer;
  
  // 缓存
  final Map<int, int> _taskProgress = {};
  final Map<int, int> _queuePositions = {};

  @override
  Future<DownloadModelState> build() async {
    _repository = ref.watch(downloadRepositoryProvider);
    
    // 设置清理
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _progressSub?.cancel();
      _queueSub?.cancel();
    });
    
    // 监听进度流
    _progressSub = _repository!.progressStream.listen(
      _onProgressUpdate,
      onError: (e) => AppLogger.error('DownloadViewModel', '进度流错误: $e'),
    );
    
    _queueSub = _repository!.queueStream.listen((_) => _updateQueuePositions());
    
    // 加载任务
    final tasks = await _repository!.getAllTasks();
    _updateQueuePositions();
    
    // 自动恢复未完成任务
    await _resumeIncompleteTasks();
    
    return DownloadModelState.loaded(downloads: tasks);
  }

  Future<void> _onProgressUpdate(DownloadProgressEvent event) async {
    _taskProgress[event.taskId] = event.progress;
    
    if (event.progress >= 100) {
      Future.delayed(const Duration(seconds: 2), () {
        _taskProgress.remove(event.taskId);
      });
    }
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final tasks = await _repository!.getAllTasks();
      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
    });
  }

  Future<void> pauseDownload(int taskId) async {
    state = const AsyncLoading();
    
    try {
      await _repository!.pauseDownload(taskId);
      _taskProgress.remove(taskId);
      
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();
      
      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '已暂停任务: $taskId');
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteDownload(int taskId, {bool deleteFile = false}) async {
    try {
      await _repository!.deleteDownloadTask(taskId, deleteFile: deleteFile);
      _taskProgress.remove(taskId);
      _queuePositions.remove(taskId);
      
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();
      
      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '已删除任务: $taskId');
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> clearCompleted() async {
    try {
      await _repository!.clearCompleted();
      final tasks = await _repository!.getAllTasks();
      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '清空已完成任务');
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // Getters 保持不变
  int getTaskProgress(int taskId) => _taskProgress[taskId] ?? 0;
  int? getQueuePosition(int taskId) => _queuePositions[taskId];
  bool isInQueue(int taskId) => _repository?.isInQueue(taskId) ?? false;
  
  Future<void> _updateQueuePositions() async { /* ... */ }
  Future<void> _resumeIncompleteTasks() async { /* ... */ }
}
```

**对应的 Widget 更新**:

```dart
// views/system/backend_download_page.dart

class BackendDownloadPage extends ConsumerWidget {
  const BackendDownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 监听 AsyncNotifier 的 state
    final asyncState = ref.watch(downloadViewModelProvider);
    
    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('错误: $err')),
      ),
      data: (state) => _buildContent(context, ref, state),
    );
  }
  
  Widget _buildContent(BuildContext context, WidgetRef ref, DownloadModelState state) {
    final downloads = state.downloads;
    
    return Scaffold(
      // ...
      body: downloads.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final task = downloads[index];
              return _DownloadTaskTile(taskId: task.id!);
            },
          ),
    );
  }
}

class _DownloadTaskTile extends ConsumerWidget {
  final int taskId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 使用 select 选择特定字段，避免不必要的重建
    final task = ref.watch(
      downloadViewModelProvider.select(
        (s) => s.valueOrNull?.downloads.firstWhere(
          (t) => t.id == taskId,
          orElse: () => DownloadTask(/* 默认值 */),
        ),
      ),
    );
    
    // 读取实例用于调用方法
    final viewModel = ref.read(downloadViewModelProvider.notifier);
    final progress = viewModel.getTaskProgress(taskId);
    final queuePosition = viewModel.getQueuePosition(taskId);
    
    return Card(/* ... */);
  }
}
```

#### 4.2.2 QueueViewModel 迁移

**文件**: `lib/presentation/viewmodels/player/queue_viewmodel.dart`

```dart
// ============ 迁移后 ============
@Riverpod(keepAlive: true)
class QueueViewModel extends _$QueueViewModel {
  SharedStorageService? _storage;

  @override
  QueueState build() {
    _storage = ref.watch(sharedStorageServiceProvider);
    
    // 初始化时加载
    _init();
    
    return const QueueState(); // 初始空状态
  }
  
  Future<void> _init() async {
    try {
      await _loadFromStorage();
      AppLogger.info('QueueViewModel', '初始化完成');
    } catch (e) {
      AppLogger.error('QueueViewModel', '初始化失败: $e');
    }
  }

  Future<void> add(PlayableAudio playable, {bool playImmediately = false}) async {
    final newQueue = List<PlayableAudio>.from(state.queue);
    final existingIndex = newQueue.indexWhere((p) => p.id == playable.id);
    
    int newIndex = state.currentIndex;
    
    if (playImmediately) {
      if (existingIndex != -1) {
        newIndex = existingIndex;
      } else {
        newQueue.add(playable);
        newIndex = newQueue.length - 1;
      }
    } else {
      if (existingIndex == -1) {
        newQueue.add(playable);
      }
    }
    
    // ✅ 直接修改 state，触发重建
    state = state.copyWith(queue: newQueue, currentIndex: newIndex);
    await _saveToStorage();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    
    final newQueue = List<PlayableAudio>.from(state.queue)..removeAt(index);
    
    int newIndex = state.currentIndex;
    if (state.currentIndex == index) {
      newIndex = -1;
    } else if (state.currentIndex > index) {
      newIndex--;
    }
    
    state = state.copyWith(queue: newQueue, currentIndex: newIndex);
    await _saveToStorage();
  }

  void setCurrentIndex(int index) {
    if (index < 0 || index >= state.queue.length) return;
    state = state.copyWith(currentIndex: index);
  }

  Future<void> clear() async {
    state = const QueueState();
    await _saveToStorage();
  }

  // Getters
  PlayableAudio? get currentPlayable {
    final index = state.currentIndex;
    if (index >= 0 && index < state.queue.length) {
      return state.queue[index];
    }
    return null;
  }

  bool get isEmpty => state.queue.isEmpty;
  bool get hasNext => state.currentIndex < state.queue.length - 1;
  bool get hasPrevious => state.currentIndex > 0;

  Future<void> _saveToStorage() async { /* ... */ }
  Future<void> _loadFromStorage() async { /* ... */ }
}
```

**对应的 Widget 更新**:

```dart
// views/player/play_list_page.dart

class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 监听 state
    final queueState = ref.watch(queueViewModelProvider);
    final queue = queueState.queue;
    final currentIndex = queueState.currentIndex;
    
    return Scaffold(
      // ...
      body: queue.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final playable = queue[index];
              final isCurrent = currentIndex == index;
              return _buildListTile(context, ref, playable, isCurrent, index);
            },
          ),
    );
  }
  
  Widget _buildListTile(BuildContext context, WidgetRef ref, 
      PlayableAudio playable, bool isCurrent, int index) {
    return ListTile(
      // ...
      onTap: () {
        // ✅ 使用 notifier 调用方法
        ref.read(queueViewModelProvider.notifier).setCurrentIndex(index);
      },
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: () {
          ref.read(queueViewModelProvider.notifier).removeAt(index);
        },
      ),
    );
  }
}
```

#### 4.2.3 PlaylistViewModel 迁移

**文件**: `lib/presentation/viewmodels/library/playlist_viewmodel.dart`

```dart
@Riverpod(keepAlive: true)
class PlaylistViewModel extends _$PlaylistViewModel {
  PlaylistRepository? _repository;
  SharedStorageService? _storage;
  
  final Set<String> _favoritedBvids = {};
  String? _currentPlaylistId;

  @override
  Future<PlaylistState> build() async {
    _repository = ref.watch(playlistRepositoryProvider);
    _storage = ref.watch(sharedStorageServiceProvider);
    
    final token = await _storage!.getString('auth_token');
    if (token != null) {
      return _initialize(token);
    }
    
    return const PlaylistState.initial();
  }

  Future<PlaylistState> _initialize(String token) async {
    try {
      await loadPlaylists(token);
      await _loadFavoritesFromLocal();
      
      final nowPlayingId = state.valueOrNull?.nowPlayingPlaylist?.id;
      if (nowPlayingId != null) {
        await loadNowPlaying(token);
      }
      
      return state.valueOrNull ?? const PlaylistState.initial();
    } catch (e) {
      return PlaylistState.error(message: e.toString());
    }
  }

  Future<void> loadPlaylists(String token) async {
    state = const AsyncLoading();
    
    try {
      final playlists = await _repository!.getUserPlaylists();
      final systemPlaylists = playlists.where((p) => p.isSystem).toList();
      final userPlaylists = playlists.where((p) => p.isUserPlaylist).toList();
      
      state = AsyncData(PlaylistState.loaded(
        playlists: playlists,
        userPlaylists: userPlaylists,
        systemPlaylists: systemPlaylists,
        // ...
      ));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<bool> createPlaylist(String token, {
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      final newPlaylist = await _repository!.createPlaylist(
        name: name,
        description: description,
        coverUrl: coverUrl,
      );
      
      final currentState = state.valueOrNull;
      if (currentState is PlaylistStateLoaded) {
        state = AsyncData(currentState.copyWith(
          playlists: [...currentState.playlists, newPlaylist],
          userPlaylists: [...currentState.userPlaylists, newPlaylist],
        ));
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePlaylist(String token, String id) async {
    try {
      await _repository!.deletePlaylist(id);
      
      final currentState = state.valueOrNull;
      if (currentState is PlaylistStateLoaded) {
        state = AsyncData(currentState.copyWith(
          playlists: currentState.playlists.where((p) => p.id != id).toList(),
          userPlaylists: currentState.userPlaylists.where((p) => p.id != id).toList(),
        ));
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // ... 其他方法
}
```

---

### Phase 3: UI 反馈优化（稳定特性）

> **⚠️ 重要变更（2026-02-06）**：经 Riverpod 官方文档分析，[Mutations](https://riverpod.dev/docs/whats_new) 为**实验性特性**，API 可能破坏性变化。
> 本阶段改用**稳定特性**实现相同效果：
> - ViewModel 内部状态追踪（操作中的 loading 状态）
> - `ref.listen` 处理副作用（错误提示、Toast）
> - `ref.watch(select(...))` 性能优化

#### 4.3.1 为什么不使用 Mutations

| 原因 | 说明 |
|-----|------|
| **实验性** | 官方文档明确标注 "experimental"，API 可能无主版本升级变化 |
| **过度设计** | 下载场景每个任务独立状态，全局 Mutations 反而复杂 |
| **稳定性** | 生产项目应优先使用稳定 API |

#### 4.3.2 稳定特性替代方案：ViewModel 内部状态追踪

```dart
// viewmodels/system/download_viewmodel.dart

@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel {
  // 操作状态：taskId -> isLoading
  final Map<int, bool> _operationStates = {};

  /// 检查任务是否正在操作（供 Widget 查询）
  bool isOperating(int taskId) => _operationStates[taskId] ?? false;

  Future<void> pauseDownload(int taskId) async {
    _operationStates[taskId] = true;  // 开始操作
    try {
      await _repository!.pauseDownload(taskId);
      _taskProgress.remove(taskId);

      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '已暂停任务: $taskId');
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    } finally {
      if (ref.mounted) {
        _operationStates[taskId] = false;  // 结束操作
      }
    }
  }

  // resumeDownload、deleteDownload 等方法类似...
}
```

#### 4.3.3 Widget 使用 select 优化性能

```dart
// views/system/backend_download_page.dart

class _DownloadTaskTile extends ConsumerWidget {
  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 使用 select 只监听特定任务的下载状态
    final task = ref.watch(
      downloadViewModelProvider.select(
        (s) => s.valueOrNull?.downloads.firstWhere(
          (t) => t.id == taskId,
          orElse: () => DownloadTask.placeholder(taskId),
        ),
      ),
    );

    // ✅ 使用 select 只监听操作状态（避免整 ViewModel 重建）
    final isOperating = ref.watch(
      downloadViewModelProvider.notifier
    ).select((n) => n.isOperating(taskId));

    return ListTile(
      title: Text(task.title ?? task.bvid ?? '未知'),
      trailing: _buildTrailing(context, ref, task, isOperating),
    );
  }

  Widget _buildTrailing(BuildContext context, WidgetRef ref,
      DownloadTask task, bool isOperating) {
    if (isOperating) {
      return const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (task.status == DownloadStatus.downloading) {
      return IconButton(
        icon: const Icon(Icons.pause),
        onPressed: () => _handlePause(ref, task.id!),
      );
    }

    return IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _handleDelete(ref, task.id!),
    );
  }

  void _handlePause(WidgetRef ref, int taskId) {
    ref.read(downloadViewModelProvider.notifier).pauseDownload(taskId);
  }
}
```

#### 4.3.4 使用 ref.listen 处理错误提示

```dart
// views/system/backend_download_page.dart

class BackendDownloadPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 监听错误状态，显示 SnackBar
    ref.listen(
      downloadViewModelProvider,
      (previous, next) {
        next.when(
          loading: () => null,
          data: (_) => null,
          error: (err, stack) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('操作失败: $err'),
                action: SnackBarAction(
                  label: '关闭',
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
              ),
            );
          },
        );
      },
    );

    final asyncState = ref.watch(downloadViewModelProvider);
    return asyncState.when(
      loading: () => /* ... */,
      error: (err, stack) => /* ... */,
      data: (state) => _buildContent(context, ref, state),
    );
  }
}
```

#### 4.3.5 方案对比总结

| 方案 | 优点 | 缺点 | 状态 |
|-----|------|------|------|
| **内部状态追踪** | 简单、稳定、类型安全 | 状态与 ViewModel 耦合 | ✅ 推荐 |
| **全局 Mutations** | UI 状态分离 | 实验性、API 不稳定 | ⚠️ 跳过 |
| **ref.listen** | 官方模式、适合副作用 | 需要额外处理 | ✅ 配合使用 |

---

### Phase 4: 其他 ViewModel 迁移 (1天)

按照优先级顺序迁移剩余 ViewModel：

| 顺序 | ViewModel | 类型 | 预计时间 |
|-----|-----------|------|---------|
| 1 | AuthViewModel | AsyncNotifier | 2h |
| 2 | PlatformAuthViewModel | AsyncNotifier | 2h |
| 3 | PlayerViewModel | Notifier | 2h |
| 4 | SearchViewModel | AsyncNotifier | 1h |
| 5 | LocalMusicViewModel | AsyncNotifier | 1h |
| 6 | HistoryViewModel | AsyncNotifier | 1h |
| 7 | MetadataViewModel | AsyncNotifier | 30min |
| 8 | ThemeViewModel | Notifier | 30min |

---

### Phase 5: Widget 全面更新 (1天)

#### 4.5.1 批量替换脚本

```bash
# 替换规则（用于 IDE 全局替换）

# 规则 1: 监听 state -> 监听 AsyncValue
# 查找: final (\w+) = ref\.watch(\((\w+)ViewModelProvider\))\.(\w+)State;
# 替换: final $1 = ref.watch($3ViewModelProvider);

# 规则 2: 访问属性 -> 使用 when 或 select
# 查找: (\w+)ViewModel\.(\w+)State\.(\w+)
# 替换: 需要手动处理

# 规则 3: 调用方法 -> 使用 notifier
# 查找: ref\.read\((\w+)ViewModelProvider\)\.(\w+)\(
# 替换: ref.read($1ViewModelProvider.notifier).$2(
```

#### 4.5.2 Widget 更新清单

| 文件 | 修改内容 |
|------|----------|
| `backend_download_page.dart` | 使用 AsyncValue.when |
| `play_list_page.dart` | 直接监听 state |
| `playlist_library_page.dart` | 使用 select |
| `search_page.dart` | 使用 AsyncValue.when |
| `local_music_playlist_page.dart` | 使用 select |
| `settings_page.dart` | 使用 select |
| `login_page.dart` | 使用 AsyncValue.when |
| `register_page.dart` | 使用 AsyncValue.when |
| `home_page.dart` | 使用多个 select |

---

## 5. 代码规范

### 5.1 ViewModel 命名规范

```dart
// ✅ 正确
@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel { }

@riverpod
class ThemeViewModel extends _$ThemeViewModel { }

// ❌ 错误
@Riverpod(keepAlive: true)
class DownloadNotifier extends _$DownloadNotifier { }
```

### 5.2 State 类规范

```dart
// ✅ 使用 freezed
@freezed
class DownloadModelState with _$DownloadModelState {
  const factory DownloadModelState.initial() = DownloadModelStateInitial;
  const factory DownloadModelState.loaded({
    required List<DownloadTask> downloads,
  }) = DownloadModelStateLoaded;
  const factory DownloadModelState.error({
    required String message,
  }) = DownloadModelStateError;
}
```

### 5.3 Widget 监听规范

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 方式 1: 使用 AsyncValue.when 处理异步状态
    final asyncState = ref.watch(downloadViewModelProvider);
    return asyncState.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
      data: (state) => _buildContent(state),
    );

    // ✅ 方式 2: 使用 select 选择特定字段（Riverpod 3.0: 推荐使用 valueOrNull）
    final downloads = ref.watch(
      downloadViewModelProvider.select((s) => s.valueOrNull?.downloads ?? []),
    );

    // ✅ 方式 3: 调用方法使用 notifier
    final notifier = ref.read(downloadViewModelProvider.notifier);
  }
}
```

### 5.4 异步操作规范（官方推荐）

```dart
// ✅ 官方推荐：使用 ref.mounted 检查
Future<void> pauseDownload(int taskId) async {
  await repository.pauseDownload(taskId);

  // 异步操作后检查是否仍然挂载
  if (!ref.mounted) return;

  final tasks = await repository.getAllTasks();
  state = AsyncData(DownloadModelState.loaded(downloads: tasks));
}

// ✅ 或者使用 AsyncValue.guard
Future<void> pauseDownload(int taskId) async {
  state = await AsyncValue.guard(() async {
    await repository.pauseDownload(taskId);
    final tasks = await repository.getAllTasks();
    return DownloadModelState.loaded(downloads: tasks);
  });
}
```

### 5.4 UI 反馈规范（替代 Mutation）

```dart
// ✅ 方案 1：ViewModel 内部操作状态 + Widget select
class MyViewModel extends _$MyViewModel {
  final Map<String, bool> _loadingStates = {};

  bool isLoading(String key) => _loadingStates[key] ?? false;

  Future<void> performAction(String key) async {
    _loadingStates[key] = true;
    try {
      // ... 执行操作
    } finally {
      if (ref.mounted) _loadingStates[key] = false;
    }
  }
}

// Widget 使用 select 只监听需要的状态
final isOperating = ref.watch(
  myProvider.notifier
).select((n) => n.isLoading('some-key'));

// ✅ 方案 2：使用 ref.listen 处理错误提示
ref.listen(myProvider, (previous, next) {
  next.when(
    loading: () => null,
    data: (_) => null,
    error: (err, stack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $err')),
      );
    },
  );
});
```

---

## 6. 风险与回滚方案

### 6.1 风险评估

| 风险 | 可能性 | 影响 | 缓解措施 |
|-----|-------|------|---------|
| 功能回归 | 中 | 高 | 每阶段完成后全面测试 |
| 性能下降 | 低 | 中 | 使用 select 优化，基准测试 |
| 编译错误 | 高 | 低 | 代码生成，编译时检查 |
| 状态丢失 | 低 | 高 | 保持 keepAlive，测试生命周期 |

### 6.2 回滚方案

```bash
# 回滚策略
1. 每个 Phase 单独提交到独立分支
2. 使用 git tag 标记稳定版本
3. 保留原始 StateNotifier 实现作为注释（临时）
4. 准备快速回滚脚本

# 回滚命令示例
git checkout tags/before-riverpod3-migration -- frontend_flutter/lib/presentation/viewmodels
git checkout tags/before-riverpod3-migration -- frontend_flutter/lib/presentation/views
```

### 6.3 兼容层（临时）

```dart
// 迁移期间提供兼容层
extension ViewModelCompat on DownloadViewModel {
  @Deprecated('使用 AsyncValue 的 when 方法')
  DownloadModelState get downloadState {
    return state.valueOrNull ?? const DownloadModelState.initial();
  }
}
```

---

## 7. 测试策略

### 7.1 单元测试更新

```dart
// 使用 ProviderContainer.test()
test('DownloadViewModel 暂停下载', () async {
  final container = ProviderContainer.test(
    overrides: [
      downloadRepositoryProvider.overrideWithValue(mockRepository),
    ],
  );
  
  addTearDown(container.dispose);
  
  // 监听状态
  final listener = Listener<AsyncValue<DownloadModelState>>();
  container.listen(
    downloadViewModelProvider,
    listener.call,
    fireImmediately: true,
  );
  
  // 验证初始状态
  verify(() => listener(null, const AsyncLoading()));
  
  // 执行操作
  await container.read(downloadViewModelProvider.notifier).pauseDownload(1);
  
  // 验证状态变化
  verify(() => listener(
    any(that: isA<AsyncData<DownloadModelState>>()),
    any(that: isA<AsyncLoading>()),
  ));
});
```

### 7.2 Widget 测试更新

```dart
testWidgets('下载页面显示任务列表', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        downloadViewModelProvider.overrideWithValue(
          AsyncValue.data(DownloadModelState.loaded(
            downloads: [testTask1, testTask2],
          )),
        ),
      ],
      child: MaterialApp(home: BackendDownloadPage()),
    ),
  );
  
  expect(find.text('下载任务'), findsOneWidget);
  expect(find.text('Test Title 1'), findsOneWidget);
  expect(find.text('Test Title 2'), findsOneWidget);
});
```

### 7.3 集成测试

```dart
// 测试完整用户流程
testWidgets('添加下载并查看进度', (tester) async {
  // 1. 导航到下载页面
  // 2. 添加下载任务
  // 3. 验证进度条显示
  // 4. 验证暂停/恢复功能
});
```

---

## 附录

### A. 迁移检查清单

- [ ] 更新 pubspec.yaml 依赖
- [ ] 创建基础类 (BaseAsyncNotifier, BaseNotifier)
- [ ] 迁移 DownloadViewModel
- [ ] 更新 backend_download_page.dart
- [ ] 迁移 QueueViewModel
- [ ] 更新 play_list_page.dart
- [ ] 迁移 PlaylistViewModel
- [ ] 更新 playlist_library_page.dart
- [ ] 添加 Mutations
- [ ] 迁移剩余 ViewModels
- [ ] 更新所有 Widgets
- [ ] 运行所有测试
- [ ] 手动功能测试

### B. 参考文档

- [Riverpod 3.0 迁移指南](https://riverpod.dev/docs/migration/3.0.0)
- [Riverpod 3.0 新特性](https://riverpod.dev/docs/whats_new)
- [Mutations 文档](https://riverpod.dev/docs/concepts/mutations)

### C. 相关文件

| 类型 | 路径 |
|-----|------|
| ViewModels | `lib/presentation/viewmodels/**/*.dart` |
| Views | `lib/presentation/views/**/*.dart` |
| 生成的代码 | `lib/presentation/viewmodels/**/*.g.dart` |
| 测试 | `test/**/*_test.dart` |
