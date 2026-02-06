# Riverpod 3.0 迁移代码示例

> 本文档提供详细的迁移前后代码对比  
> 创建日期: 2026-02-06

---

## 目录

1. [DownloadViewModel 完整迁移](#1-downloadviewmodel-完整迁移)
2. [QueueViewModel 完整迁移](#2-queueviewmodel-完整迁移)
3. [PlaylistViewModel 完整迁移](#3-playlistviewmodel-完整迁移)
4. [AuthViewModel 完整迁移](#4-authviewmodel-完整迁移)
5. [Widget 更新示例](#5-widget-更新示例)

---

## 1. DownloadViewModel 完整迁移

### 1.1 迁移前 (StateNotifier)

```dart
// lib/presentation/viewmodels/system/download_viewmodel.dart

import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/download_repository.dart';
import '../../../models/download_task.dart';

part 'download_viewmodel.freezed.dart';
part 'download_viewmodel.g.dart';

@freezed
class DownloadModelState with _$DownloadModelState {
  const factory DownloadModelState.initial() = DownloadModelStateInitial;
  const factory DownloadModelState.loading() = DownloadModelStateLoading;
  const factory DownloadModelState.loaded({
    required List<DownloadTask> downloads,
    @Deprecated('使用 getTaskProgress() 获取单任务进度')
    @Default('') String downloadStage,
    @Deprecated('使用 getTaskProgress() 获取单任务进度')
    @Default(0) int downloadProgress,
    @Deprecated('不再使用')
    DownloadTask? activeTask,
  }) = DownloadModelStateLoaded;
  const factory DownloadModelState.error({
    required String message,
  }) = DownloadModelStateError;
}

class DownloadViewModel extends StateNotifier<DownloadModelState> {
  final DownloadRepository _repository;
  StreamSubscription<DownloadProgressEvent>? _progressSubscription;
  StreamSubscription<int>? _queueSubscription;
  final Map<int, int> _taskProgress = {};
  final Map<int, int> _queuePositions = {};
  Timer? _debounceTimer;

  DownloadViewModel(this._repository)
      : super(const DownloadModelState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = const DownloadModelState.loading();

    _progressSubscription = _repository.progressStream.listen(
      _onProgressUpdate,
      onError: (error) {
        AppLogger.error('DownloadViewModel', '进度流错误: $error');
      },
    );

    _queueSubscription = _repository.queueStream.listen(
      (_) => _updateQueuePositions(),
      onError: (error) {
        AppLogger.error('DownloadViewModel', '队列流错误: $error');
      },
    );

    await _loadTasks();
    _updateQueuePositions();
    await _resumeIncompleteTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _repository.getAllTasks();
      state = DownloadModelState.loaded(downloads: tasks);
    } catch (e) {
      state = DownloadModelState.error(message: e.toString());
    }
  }

  void _onProgressUpdate(DownloadProgressEvent event) {
    _taskProgress[event.taskId] = event.progress;
    if (event.progress >= 100) {
      Future.delayed(const Duration(seconds: 2), () {
        _taskProgress.remove(event.taskId);
      });
    }
    _scheduleUpdate();
  }

  void _scheduleUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _refreshAndNotify();
    });
  }

  Future<void> _refreshAndNotify() async {
    if (state is! DownloadModelStateLoaded) return;
    try {
      final tasks = await _repository.getAllTasks();
      state = DownloadModelState.loaded(downloads: tasks);
    } catch (e) {
      AppLogger.error('DownloadViewModel', '刷新失败: $e');
    }
  }

  Future<void> pauseDownload(int taskId) async {
    try {
      await _repository.pauseDownload(taskId);
      _taskProgress.remove(taskId);
      await _loadTasks();
      _updateQueuePositions();
    } catch (e) {
      AppLogger.error('DownloadViewModel', '暂停失败: $e');
    }
  }

  Future<void> deleteDownload(int taskId, {bool deleteFile = false}) async {
    try {
      await _repository.deleteDownloadTask(taskId, deleteFile: deleteFile);
      _taskProgress.remove(taskId);
      _queuePositions.remove(taskId);
      await _loadTasks();
      _updateQueuePositions();
    } catch (e) {
      AppLogger.error('DownloadViewModel', '删除失败: $e');
    }
  }

  Future<void> clearCompleted() async {
    try {
      await _repository.clearCompleted();
      await _loadTasks();
    } catch (e) {
      AppLogger.error('DownloadViewModel', '清空失败: $e');
    }
  }

  int getTaskProgress(int taskId) => _taskProgress[taskId] ?? 0;
  int? getQueuePosition(int taskId) => _queuePositions[taskId];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _progressSubscription?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }
}

@riverpod
DownloadRepository downloadRepository(DownloadRepositoryRef ref) {
  return DownloadRepository();
}

@riverpod
DownloadViewModel downloadViewModel(DownloadViewModelRef ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  return DownloadViewModel(repository);
}
```

### 1.2 迁移后 (AsyncNotifier)

```dart
// lib/presentation/viewmodels/system/download_viewmodel.dart

import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/download_repository.dart';
import '../../../models/download_task.dart';

part 'download_viewmodel.freezed.dart';
part 'download_viewmodel.g.dart';

@freezed
class DownloadModelState with _$DownloadModelState {
  const factory DownloadModelState.initial() = DownloadModelStateInitial;
  const factory DownloadModelState.loading() = DownloadModelStateLoading;
  const factory DownloadModelState.loaded({
    required List<DownloadTask> downloads,
  }) = DownloadModelStateLoaded;
  const factory DownloadModelState.error({
    required String message,
  }) = DownloadModelStateError;
}

@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel {
  DownloadRepository? _repository;
  StreamSubscription<DownloadProgressEvent>? _progressSub;
  StreamSubscription<int>? _queueSub;
  Timer? _debounceTimer;
  final Map<int, int> _taskProgress = {};
  final Map<int, int> _queuePositions = {};

  @override
  Future<DownloadModelState> build() async {
    _repository = ref.watch(downloadRepositoryProvider);

    // 设置清理回调
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

    _queueSub = _repository!.queueStream.listen(
      (_) => _updateQueuePositions(),
      onError: (e) => AppLogger.error('DownloadViewModel', '队列流错误: $e'),
    );

    // 加载任务
    final tasks = await _repository!.getAllTasks();
    _updateQueuePositions();
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
      if (!ref.mounted) return;
      final tasks = await _repository!.getAllTasks();
      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
    });
  }

  Future<void> pauseDownload(int taskId) async {
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

  Future<void> resumeDownload(int taskId) async {
    try {
      await _repository!.resumeDownload(taskId);
      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      AppLogger.info('DownloadViewModel', '已恢复任务: $taskId');
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

  Future<DownloadTask?> addDownload({
    required String bvid,
    required String savePath,
    String? title,
    String? artist,
    String? coverUrl,
  }) async {
    try {
      final existingTask = await _repository!.getTaskByBvid(bvid);
      if (existingTask != null) {
        if (existingTask.isCompleted) {
          throw Exception('任务已完成');
        } else if (existingTask.isActive) {
          throw Exception('任务已在队列中');
        } else if (existingTask.isFailed) {
          await _repository!.deleteDownloadTask(existingTask.id!);
        }
      }

      final taskId = await _repository!.addDownloadTask(
        bvid: bvid,
        url: _repository!.getDownloadUrl(bvid),
        savePath: savePath,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
      );

      final tasks = await _repository!.getAllTasks();
      _updateQueuePositions();
      await _repository!.startDownload(taskId);

      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
      return await _repository!.getTaskByBvid(bvid);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // Getters 保持不变
  int getTaskProgress(int taskId) => _taskProgress[taskId] ?? 0;
  int? getQueuePosition(int taskId) => _queuePositions[taskId];
  bool isInQueue(int taskId) => _repository?.isInQueue(taskId) ?? false;

  // Private methods
  void _updateQueuePositions() {
    _queuePositions.clear();
    final queuedIds = _repository?.getQueuedTaskIds() ?? [];
    for (int i = 0; i < queuedIds.length; i++) {
      _queuePositions[queuedIds[i]] = i + 1;
    }
  }

  Future<void> _resumeIncompleteTasks() async {
    final pendingTasks = await _repository!.getPendingTasks();
    for (final task in pendingTasks) {
      if (task.id != null) {
        await _repository!.startDownload(task.id!);
      }
    }
  }
}

@riverpod
DownloadRepository downloadRepository(DownloadRepositoryRef ref) {
  return DownloadRepository();
}
```

---

## 2. QueueViewModel 完整迁移

### 2.1 迁移前

```dart
class QueueViewModel extends StateNotifier<QueueState> {
  final SharedStorageService _storage;
  bool _disposed = false;

  QueueViewModel({required SharedStorageService storage})
      : _storage = storage,
        super(const QueueState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _loadFromStorage();
    } catch (e) {
      AppLogger.error('QueueViewModel', '初始化失败: $e');
    }
  }

  QueueState get queueState => state;

  Future<void> add(PlayableAudio playable, {bool playImmediately = false}) async {
    final newQueue = List<PlayableAudio>.from(state.queue);
    // ... 逻辑
    state = state.copyWith(queue: newQueue, currentIndex: newIndex);
    await _saveToStorage();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

@riverpod
QueueViewModel queueViewModel(QueueViewModelRef ref) {
  final storage = ref.watch(sharedStorageServiceProvider);
  return QueueViewModel(storage: storage);
}
```

### 2.2 迁移后

```dart
@Riverpod(keepAlive: true)
class QueueViewModel extends _$QueueViewModel {
  SharedStorageService? _storage;

  @override
  QueueState build() {
    _storage = ref.watch(sharedStorageServiceProvider);
    
    // 延迟初始化
    Future.microtask(_init);
    
    return const QueueState();
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
    
    state = state.copyWith(queue: newQueue, currentIndex: newIndex);
    await _saveToStorage();
    
    AppLogger.info('QueueViewModel', '添加音频: ${playable.title}');
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

  PlayableAudio? playNext() {
    if (state.queue.isEmpty) return null;
    final nextIndex = hasNext ? state.currentIndex + 1 : 0;
    setCurrentIndex(nextIndex);
    return currentPlayable;
  }

  PlayableAudio? playPrevious() {
    if (state.queue.isEmpty) return null;
    final previousIndex = hasPrevious ? state.currentIndex - 1 : state.queue.length - 1;
    setCurrentIndex(previousIndex);
    return currentPlayable;
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

---

## 3. PlaylistViewModel 完整迁移

### 3.1 迁移前

```dart
class PlaylistViewModel extends StateNotifier<PlaylistState> {
  final PlaylistRepository _repository;
  final SharedStorageService _storage;
  final Set<String> _favoritedBvids = {};

  PlaylistViewModel(this._repository, this._storage)
      : super(const PlaylistState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final token = await _storage.getString('auth_token');
    if (token != null) {
      await initialize(token);
    }
  }

  Future<void> initialize(String token) async {
    state = const PlaylistState.loading();
    await loadPlaylists(token);
    await _loadFavoritesFromLocal();
  }

  PlaylistState get playlistState => state;

  Future<void> loadPlaylists(String token) async {
    try {
      final playlists = await _repository.getUserPlaylists();
      // ... 更新 state
    } catch (e) {
      state = PlaylistState.error(message: e.toString());
    }
  }
}
```

### 3.2 迁移后

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

      final favoritesPlaylist = systemPlaylists.firstWhere(
        (p) => p.isFavorites,
        orElse: () => Playlist.favorites,
      );

      final nowPlayingPlaylist = systemPlaylists.firstWhere(
        (p) => p.isNowPlaying,
        orElse: () => Playlist.nowPlaying,
      );

      state = AsyncData(PlaylistState.loaded(
        playlists: playlists,
        userPlaylists: userPlaylists,
        systemPlaylists: systemPlaylists,
        favoritesPlaylist: favoritesPlaylist,
        nowPlayingPlaylist: nowPlayingPlaylist,
        favoritesItems: state.valueOrNull?.favoritesItems ?? [],
        nowPlayingItems: state.valueOrNull?.nowPlayingItems ?? [],
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

      final current = state.valueOrNull;
      if (current is PlaylistStateLoaded) {
        state = AsyncData(current.copyWith(
          playlists: [...current.playlists, newPlaylist],
          userPlaylists: [...current.userPlaylists, newPlaylist],
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

      final current = state.valueOrNull;
      if (current is PlaylistStateLoaded) {
        state = AsyncData(current.copyWith(
          playlists: current.playlists.where((p) => p.id != id).toList(),
          userPlaylists: current.userPlaylists.where((p) => p.id != id).toList(),
        ));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String token, String bvid, {...}) async {
    try {
      final added = await _repository!.toggleFavorite(bvid);

      if (added) {
        _favoritedBvids.add(bvid);
        await loadFavorites(token);
      } else {
        _favoritedBvids.remove(bvid);
        final current = state.valueOrNull;
        if (current is PlaylistStateLoaded) {
          state = AsyncData(current.copyWith(
            favoritesItems: current.favoritesItems.where((i) => i.bvid != bvid).toList(),
          ));
        }
      }

      await _saveFavoritesToLocal();
      return added;
    } catch (e) {
      return false;
    }
  }

  bool isFavorited(String bvid) {
    return _favoritedBvids.contains(bvid) ||
        (state.valueOrNull?.favoritesItems.any((i) => i.bvid == bvid) ?? false);
  }

  Future<void> clear() async {
    _favoritedBvids.clear();
    state = const AsyncData(PlaylistState.initial());
    await _storage?.remove('playlists_cache');
    await _storage?.remove('favorites_cache');
  }

  Future<void> _loadFavoritesFromLocal() async { /* ... */ }
  Future<void> _saveFavoritesToLocal() async { /* ... */ }
}
```

---

## 4. AuthViewModel 完整迁移

### 4.1 迁移前

```dart
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(const AuthState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await _repository.checkLoginStatus();
    if (user != null && !user.isGuest) {
      state = AuthState.authenticated(user: user, token: user.token);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  AuthState get authState => state;
  User? get currentUser => whenOrNull(...);
  bool get isLoggedIn => state.maybeWhen(...);

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.login(...);
      state = AuthState.authenticated(user: user, token: user.token);
      return true;
    } catch (e) {
      state = AuthState.error(message: e.toString());
      return false;
    }
  }
}

@riverpod
AuthViewModel authViewModel(AuthViewModelRef ref) {
  return AuthViewModel(ref.watch(authRepositoryProvider));
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authViewModelProvider).currentUser;
}

@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  return ref.watch(authViewModelProvider).isLoggedIn;
}
```

### 4.2 迁移后

```dart
@Riverpod(keepAlive: true)
class AuthViewModel extends _$AuthViewModel {
  AuthRepository? _repository;

  @override
  Future<AuthState> build() async {
    _repository = ref.watch(authRepositoryProvider);

    final user = await _repository!.checkLoginStatus();
    if (user != null && !user.isGuest) {
      return AuthState.authenticated(user: user, token: user.token);
    }
    return const AuthState.unauthenticated();
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      final user = await _repository!.login(
        LoginRequest(email: email, password: password),
      );

      state = AsyncData(AuthState.authenticated(user: user, token: user.token));
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> register({...}) async {
    state = const AsyncLoading();
    // ... 类似 login
  }

  Future<void> logout() async {
    await _repository!.logout();
    state = const AsyncData(AuthState.unauthenticated());
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current is AuthStateError) {
      state = const AsyncData(AuthState.unauthenticated());
    }
  }
}

// 派生 Providers
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authViewModelProvider).valueOrNull?.whenOrNull(
    authenticated: (user, token) => user,
  );
}

@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  return ref.watch(authViewModelProvider).valueOrNull?.maybeWhen(
    authenticated: (_, __) => true,
    orElse: () => false,
  ) ?? false;
}

@riverpod
String? authToken(AuthTokenRef ref) {
  return ref.watch(authViewModelProvider).valueOrNull?.maybeWhen(
    authenticated: (user, token) => token ?? user.token,
    orElse: () => null,
  );
}
```

---

## 5. Widget 更新示例

### 5.1 下载页面

```dart
// ❌ 迁移前
class BackendDownloadPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadViewModel = ref.watch(downloadViewModelProvider);
    final downloadState = downloadViewModel.downloadState;
    final downloads = downloadState.maybeWhen(
      loaded: (tasks, _, __, ___) => tasks,
      orElse: () => <DownloadTask>[],
    );

    return Scaffold(...);
  }
}

// ✅ 迁移后
class BackendDownloadPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      appBar: AppBar(...),
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
    // 使用 select 只监听特定任务
    final task = ref.watch(
      downloadViewModelProvider.select((s) =>
        s.valueOrNull?.downloads.firstWhere(
          (t) => t.id == taskId,
          orElse: () => DownloadTask(id: taskId, url: '', savePath: '', bvid: '', status: DownloadStatus.pending),
        ),
      ),
    );

    if (task == null) return const SizedBox.shrink();

    // 读取 notifier 用于调用方法
    final notifier = ref.read(downloadViewModelProvider.notifier);
    final progress = notifier.getTaskProgress(taskId);
    final queuePosition = notifier.getQueuePosition(taskId);

    return Card(
      child: ListTile(
        title: Text(task.title ?? task.bvid ?? '未知'),
        subtitle: _buildSubtitle(task, queuePosition, progress),
        trailing: _buildTrailing(context, ref, task, notifier),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, WidgetRef ref, DownloadTask task, DownloadViewModel notifier) {
    if (task.isCompleted) {
      return IconButton(
        icon: const Icon(Icons.folder_open),
        onPressed: () {/* 查看位置 */},
      );
    }

    if (task.status == DownloadStatus.downloading) {
      return IconButton(
        icon: const Icon(Icons.pause),
        onPressed: () => notifier.pauseDownload(task.id!),
      );
    }

    return IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => notifier.deleteDownload(task.id!),
    );
  }
}
```

### 5.2 播放列表页面

```dart
// ❌ 迁移前
class PlaylistPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueViewModel = ref.watch(queueViewModelProvider);
    final queue = queueViewModel.queueState.queue;
    final currentIndex = queueViewModel.queueState.currentIndex;

    return Scaffold(...);
  }
}

// ✅ 迁移后
class PlaylistPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 直接监听 state
    final queueState = ref.watch(queueViewModelProvider);
    final queue = queueState.queue;
    final currentIndex = queueState.currentIndex;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: queue.isEmpty
              ? null
              : () => ref.read(queueViewModelProvider.notifier).clear(),
          ),
        ],
      ),
      body: queue.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final playable = queue[index];
              final isCurrent = currentIndex == index;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                  child: Icon(
                    isCurrent ? Icons.play_arrow : Icons.music_note,
                    color: isCurrent ? Colors.white : Colors.grey[600],
                  ),
                ),
                title: Text(
                  playable.title,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                subtitle: Text(playable.artist ?? '未知艺术家'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => ref.read(queueViewModelProvider.notifier).removeAt(index),
                ),
                onTap: () {
                  ref.read(queueViewModelProvider.notifier).setCurrentIndex(index);
                },
              );
            },
          ),
    );
  }
}
```

### 5.3 歌单库页面

```dart
// ❌ 迁移前
class PlaylistLibraryPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistViewModel = ref.watch(playlistViewModelProvider);
    // playlistViewModel 是实例，不会触发重建

    return Scaffold(...);
  }
}

// ✅ 迁移后
class PlaylistLibraryPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    // 使用 select 只获取需要的属性
    final userPlaylists = ref.watch(
      playlistViewModelProvider.select(
        (s) => s.valueOrNull?.userPlaylists ?? [],
      ),
    );

    return Scaffold(
      body: !isLoggedIn
        ? _buildLoginPrompt(context)
        : ListView.builder(
            itemCount: userPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = userPlaylists[index];
              return PlaylistTile(playlist: playlist);
            },
          ),
    );
  }
}
```

---

## 附录: 完整的 Widget 更新对照表

| Widget | 原代码 | 新代码 |
|--------|--------|--------|
| `ref.watch(vmProvider)` | 监听实例 | 监听 `AsyncValue<State>` |
| `viewModel.state` | `viewModel.someState` | `asyncState.valueOrNull` |
| `viewModel.method()` | `ref.read(vmProvider).method()` | `ref.read(vmProvider.notifier).method()` |
| 条件渲染 | 手动检查 | 使用 `asyncState.when(...)` |
| 选择字段 | 监听整个实例 | 使用 `select((s) => s.field)` |

---

**相关文档**:
- [迁移计划](./2026-02-06-riverpod-3-migration-plan.md)
- [实施跟踪](./2026-02-06-riverpod-3-migration-tracking.md)
- [快速参考](./2026-02-06-riverpod-3-quick-reference.md)
