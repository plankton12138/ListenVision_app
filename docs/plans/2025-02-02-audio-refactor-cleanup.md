# 音频播放模块重构计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 消除前端音频播放模块中的冗余代码，提高内聚性降低耦合度，提升代码可维护性

**当前状态：**
- 音频播放相关代码分布在 8+ 个文件中
- 存在双重队列系统、重复的状态管理、过度设计的版本控制等问题
- 代码总行数约 4000+ 行，预计可精简 30%

**重构目标：**
- 统一播放队列管理（消除双重队列）
- 简化状态管理（集中状态源）
- 移除过度设计的状态版本控制
- 解耦历史记录逻辑
- 提升代码可测试性

---

## 问题分析

### 1. 双重队列系统（高优先级）

**问题描述：**
- `AudioProvider` 中维护 `_localQueue` 和 `_onlineQueue`（line 90-94）
- `PlaybackQueueManager` 中维护统一的 `_queue`（line 24）
- 两个队列系统功能重复，导致状态同步困难

**影响文件：**
- `lib/presentation/providers/audio/audio_provider.dart:90-94`
- `lib/presentation/providers/audio/audio_provider.dart:808-819`
- `lib/presentation/providers/audio/audio_provider.dart:859-920`
- `lib/presentation/providers/audio/playback_queue_manager.dart:20-25`

### 2. 重复的播放状态（高优先级）

**问题描述：**
- `AudioProvider`: `_isCurrentOnline`, `_currentOnlineAudio`, `_title`, `_artist`, `_albumArt`
- `PlaybackController`: `_isPlaying`, `_lastPlayerState`
- `AudioMetadataProvider`: `_title`, `_artist`, `_currentAlbumArt`

**影响文件：**
- `lib/presentation/providers/audio/audio_provider.dart:64-76`
- `lib/presentation/providers/audio/playback_controller.dart:28-68`
- `lib/presentation/providers/audio/audio_metadata_provider.dart:14-26`

### 3. 过度设计的状态版本控制（中优先级）

**问题描述：**
- `StateTransaction` 和 `StateVersionController` 用于防止状态更新冲突
- 实际使用场景有限，复杂度收益比低
- 可以用更简单的状态锁替代

**影响文件：**
- `lib/presentation/providers/audio/state_transaction.dart`（整个文件 95 行）
- `lib/presentation/providers/audio/audio_provider.dart:99-111`
- `lib/presentation/providers/audio/audio_provider.dart:567-640`

### 4. 播放历史记录耦合（中优先级）

**问题描述：**
- `PlaybackStateManager` 包含播放历史记录逻辑
- `AudioProvider` 通过回调直接发送 HTTP 请求记录历史
- 应该由独立的 `PlayHistoryProvider` 处理

**影响文件：**
- `lib/presentation/providers/audio/playback_state_manager.dart:240-360`
- `lib/presentation/providers/audio/audio_provider.dart:1062-1149`

### 5. 播放命令队列冗余（低优先级）

**问题描述：**
- `PlaybackQueue` 实现命令队列系统
- `AudioProvider` 中还有 `Debouncer`, `Throttler`, `OperationLock`
- 功能重复，可以统一

**影响文件：**
- `lib/presentation/providers/audio/playback_queue.dart`（整个文件 244 行）
- `lib/core/utils/debounce_utils.dart`（部分重复）
- `lib/presentation/providers/audio/audio_provider.dart:101-108`

### 6. 元数据 Provider 冗余（低优先级）

**问题描述：**
- `AudioMetadataProvider` 只是 `AudioMetadataLoader` 的包装
- `AudioProvider` 已经直接使用 `AudioMetadataLoader`
- 可以考虑合并或移除

**影响文件：**
- `lib/presentation/providers/audio/audio_metadata_provider.dart`（整个文件 106 行）
- `lib/presentation/providers/audio/audio_metadata_loader.dart`

---

## 重构方案

### Phase 1: 统一播放队列（高优先级）

**目标：** 消除双重队列系统，使用 `PlaybackQueueManager` 作为唯一数据源

**Task 1.1: 移除 AudioProvider 中的内部队列**

**Files:**
- Modify: `lib/presentation/providers/audio/audio_provider.dart:90-94` - 删除 `_localQueue` 和 `_onlineQueue`
- Modify: `lib/presentation/providers/audio/audio_provider.dart:321` - 删除 `queueLength` getter
- Modify: `lib/presentation/providers/audio/audio_provider.dart:808-819` - 重构 `addToQueue` 方法
- Modify: `lib/presentation/providers/audio/audio_provider.dart:859-920` - 删除 `_playNextInQueue` 和相关方法

**Step 1: 创建新的队列管理方法**

```dart
// 在 AudioProvider 中添加
/// 添加到播放队列（统一接口）
Future<void> addToQueue(PlayableAudio playable, {bool playImmediately = false}) async {
  await _queueManager.add(playable, playImmediately: playImmediately);
  notifyListeners();
}

/// 清空播放队列
Future<void> clearQueue() async {
  await _queueManager.clear();
  notifyListeners();
}
```

**Step 2: 运行测试验证**

```bash
cd frontend_flutter
flutter test test/providers/audio/
```

**Step 3: 提交**

```bash
git add lib/presentation/providers/audio/audio_provider.dart
git commit -m "refactor(audio): 统一播放队列管理，移除双重队列系统"
```

---

**Task 1.2: 更新调用方代码**

**Files:**
- Modify: 搜索并更新所有 `addToQueue`, `clearQueue` 调用

**Step 1: 搜索调用方**

```bash
cd frontend_flutter
grep -rn "addToQueue" lib/presentation/
```

**Step 2: 更新调用方式**

```dart
// 旧代码
await audioProvider.addToQueue(path, isLocal: true);
await audioProvider.addToQueueOnline(audio);
await audioProvider.clearQueue();

// 新代码
await audioProvider.addToQueue(LocalPlayable(audio));
await audioProvider.addToQueue(OnlinePlayable.fromAudio(audio, proxyUrl));
await audioProvider.clearQueue();
```

**Step 3: 运行测试**

```bash
flutter test
```

**Step 4: 提交**

```bash
git add lib/presentation/
git commit -m "refactor(audio): 更新队列调用方使用统一接口"
```

---

### Phase 2: 简化状态管理（高优先级）

**目标：** 集中状态管理，减少状态副本

**Task 2.1: 统一播放状态源**

**Files:**
- Modify: `lib/presentation/providers/audio/audio_provider.dart:274-322` - 重构 getters
- Modify: `lib/presentation/providers/audio/playback_controller.dart:28-68` - 简化状态

**Step 1: 定义统一的状态类**

```dart
// 创建新文件 lib/presentation/providers/audio/playback_state.dart

/// 播放状态（不可变）
class PlaybackState {
  final bool isPlaying;
  final bool isPaused;
  final bool isCompleted;
  final bool isLoading;
  final Duration position;
  final Duration? duration;
  final String? errorMessage;

  const PlaybackState({
    this.isPlaying = false,
    this.isPaused = false,
    this.isCompleted = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration,
    this.errorMessage,
  });

  PlaybackState copyWith({
    bool? isPlaying,
    bool? isPaused,
    bool? isCompleted,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
```

**Step 2: 在 PlaybackController 中使用统一状态**

```dart
// PlaybackController 添加
PlaybackState get state => PlaybackState(
  isPlaying: _isPlaying,
  isPaused: _lastPlayerState == PlayerState.paused,
  isCompleted: _lastPlayerState == PlayerState.completed,
  isLoading: _isLoadingSource,
  position: _currentPosition,
  duration: _currentDuration,
  errorMessage: null, // 错误由外部管理
);
```

**Step 3: AudioProvider 使用 PlaybackController 的状态**

```dart
// AudioProvider 简化 getters
bool get isPlaying => _playbackController.state.isPlaying;
bool get isPaused => _playbackController.state.isPaused;
bool get isLoading => _playbackController.state.isLoading;
// ...
```

**Step 4: 运行测试**

```bash
flutter test test/providers/audio/
```

**Step 5: 提交**

```bash
git add lib/presentation/providers/audio/
git commit -m "refactor(audio): 统一播放状态源，减少状态副本"
```

---

**Task 2.2: 移除 AudioProvider 中的冗余状态变量**

**Files:**
- Modify: `lib/presentation/providers/audio/audio_provider.dart:64-76`

**Step 1: 识别可移除的状态**

```dart
// 可以移除（从 PlaybackController 或 PlaybackQueueManager 获取）
bool _isCurrentOnline;      // 移到 PlaybackQueueManager
Audio? _currentOnlineAudio; // 移到 PlaybackQueueManager
bool _isSeekable;           // 简化逻辑

// 保留（UI 专用）
String _playerStatusMessage;
bool _hasPlaybackError;
```

**Step 2: 更新代码**

```dart
// 移除冗余状态，使用委托
bool get isCurrentOnline {
  final playable = _queueManager.currentPlayable;
  return playable?.isOnline ?? false;
}

String? get currentBvid {
  final playable = _queueManager.currentPlayable;
  return (playable is OnlinePlayable) ? playable.original.id : null;
}
```

**Step 3: 运行测试**

```bash
flutter test
```

**Step 4: 提交**

```bash
git add lib/presentation/providers/audio/audio_provider.dart
git commit -m "refactor(audio): 移除冗余状态变量"
```

---

### Phase 3: 移除过度设计的状态版本控制（中优先级）

**目标：** 简化状态更新机制，移除不必要的事务系统

**Task 3.1: 移除状态版本控制系统**

**Files:**
- Delete: `lib/presentation/providers/audio/state_transaction.dart`
- Modify: `lib/presentation/providers/audio/audio_provider.dart:99-111`
- Modify: `lib/presentation/providers/audio/audio_provider.dart:567-640`

**Step 1: 简化播放方法**

```dart
// 替换 _playUnifiedAtIndex 中的事务代码
Future<void> _playUnifiedAtIndex(int index) async {
  if (_disposed) return;
  if (index < 0 || index >= _queueManager.length) return;

  final playable = _queueManager[index];
  if (playable == null) return;

  _playerStatusMessage = '正在加载...';
  _hasPlaybackError = false;
  notifyListeners();

  try {
    // 直接更新索引
    _queueManager.setCurrentIndex(index, validate: false);

    // 设置状态
    _isCurrentOnline = playable.isOnline;
    if (playable is OnlinePlayable) {
      _currentOnlineAudio = playable.original;
      _isSeekable = true;
    }

    await _playPlayable(playable);
    await _queueManager.save();

    _playerStatusMessage = '';
    notifyListeners();
  } catch (e) {
    AppLogger.error('AudioProvider', '播放失败: $e');
    _hasPlaybackError = true;
    _playerStatusMessage = '播放失败: $e';
    notifyListeners();
    rethrow;
  }
}
```

**Step 2: 删除 state_transaction.dart**

```bash
rm lib/presentation/providers/audio/state_transaction.dart
```

**Step 3: 更新 AudioProvider 导入**

```dart
// 移除
import 'package:demo/presentation/providers/audio/state_transaction.dart';
```

**Step 4: 运行测试**

```bash
flutter test test/providers/audio/
```

**Step 5: 提交**

```bash
git add lib/presentation/providers/audio/
git commit -m "refactor(audio): 移除过度设计的状态版本控制系统"
```

---

### Phase 4: 解耦播放历史记录（中优先级）

**目标：** 将历史记录逻辑移至独立的 Provider

**Task 4.1: 创建独立的 PlayHistoryProvider**

**Files:**
- Create: `lib/presentation/providers/history/play_history_provider.dart`

**Step 1: 创建历史记录 Provider**

```dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:demo/core/constants/api_constants.dart';
import 'package:demo/core/constants/storage_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放历史记录 Provider
///
/// 职责：
/// 1. 记录播放开始
/// 2. 更新播放进度
/// 3. 与后端同步历史记录
class PlayHistoryProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.fullBaseUrl,
    connectTimeout: const Duration(seconds: 15),
  ));

  String? _token;
  bool _disposed = false;

  PlayHistoryProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(StorageKeys.keyToken);
  }

  /// 记录播放开始
  Future<void> recordStart({
    String? bvid,
    String? localPath,
    required String title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) async {
    if (_token == null || _token!.isEmpty) return;
    if (bvid == null && localPath == null) return;

    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      await _dio.post('/history', data: {
        if (bvid != null) 'bvid': bvid,
        if (localPath != null) 'localPath': localPath,
        'title': title,
        if (artist != null) 'artist': artist,
        if (duration != null) 'duration': duration,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'progress': 0,
      });
    } catch (e) {
      debugPrint('记录播放失败: $e');
    }
  }

  /// 更新播放进度
  Future<void> updateProgress({
    String? bvid,
    String? localPath,
    required String title,
    String? artist,
    int? duration,
    int progress = 0,
  }) async {
    if (_token == null || _token!.isEmpty) return;

    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      await _dio.put('/history/progress', data: {
        if (bvid != null) 'bvid': bvid,
        if (localPath != null) 'localPath': localPath,
        'title': title,
        if (artist != null) 'artist': artist,
        if (duration != null) 'duration': duration,
        'progress': progress,
      });
    } catch (e) {
      debugPrint('更新进度失败: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _dio.close();
    super.dispose();
  }
}
```

**Step 2: 在 AudioProvider 中使用 PlayHistoryProvider**

```dart
// 在 AudioProvider 中添加
final PlayHistoryProvider _historyProvider = PlayHistoryProvider();

// 更新 _recordPlaybackStart 方法
Future<void> _recordPlaybackStart(PlayableAudio playable) async {
  if (playable.isOnline) {
    await _historyProvider.recordStart(
      bvid: playable.id,
      title: playable.title,
      artist: playable.artist,
      duration: playable.duration,
      coverUrl: playable.coverUrl,
    );
  } else if (playable is LocalPlayable) {
    final local = playable.original;
    await _historyProvider.recordStart(
      localPath: local.filePath,
      title: local.title,
      artist: local.artist,
      duration: local.duration,
    );
  }
}
```

**Step 3: 运行测试**

```bash
flutter test test/providers/history/
```

**Step 4: 提交**

```bash
git add lib/presentation/providers/history/
git commit -m "refactor(audio): 创建独立的 PlayHistoryProvider"
```

---

**Task 4.2: 清理 PlaybackStateManager 中的历史记录代码**

**Files:**
- Modify: `lib/presentation/providers/audio/playback_state_manager.dart:240-360`

**Step 1: 移除历史记录方法**

```dart
// 从 PlaybackStateManager 中移除：
// - recordPlaybackStart()
// - updatePlaybackProgress()
// - _progressUpdateTimer
// - startProgressUpdateTimer()
// - stopProgressUpdateTimer()
```

**Step 2: 更新 AudioProvider**

```dart
// 移除对 PlaybackStateManager 历史记录方法的调用
// 直接使用 PlayHistoryProvider
```

**Step 3: 运行测试**

```bash
flutter test test/providers/audio/
```

**Step 4: 提交**

```bash
git add lib/presentation/providers/audio/playback_state_manager.dart
git add lib/presentation/providers/audio/audio_provider.dart
git commit -m "refactor(audio): 从 PlaybackStateManager 移除历史记录逻辑"
```

---

### Phase 5: 简化元数据管理（低优先级）

**目标：** 统一元数据加载和显示逻辑

**Task 5.1: 评估 AudioMetadataProvider 的必要性**

**Files:**
- Review: `lib/presentation/providers/audio/audio_metadata_provider.dart`
- Review: `lib/presentation/providers/audio/audio_metadata_loader.dart`

**Step 1: 分析调用关系**

```bash
cd frontend_flutter
grep -rn "AudioMetadataProvider" lib/presentation/
```

**Step 2: 决策**

如果 `AudioMetadataProvider` 只是简单的封装：
- 考虑将其功能合并到 `AudioProvider`
- 或者明确其职责（如专门管理 UI 相关的元数据状态）

**Step 3: 运行测试**

```bash
flutter test test/providers/audio/
```

**Step 4: 提交（如有变更）**

```bash
git add lib/presentation/providers/audio/
git commit -m "refactor(audio): 简化元数据管理"
```

---

### Phase 6: 配置集中化（低优先级）

**目标：** 将分散的常量配置集中管理

**Task 6.1: 创建播放配置文件**

**Files:**
- Create: `lib/core/constants/playback_config.dart`

**Step 1: 创建配置类**

```dart
/// 音频播放配置
class PlaybackConfig {
  // 超时配置
  static const Duration localSourceTimeout = Duration(seconds: 5);
  static const Duration onlineSourceTimeout = Duration(seconds: 10);
  static const Duration durationWaitTimeout = Duration(seconds: 5);

  // 间隔配置
  static const Duration positionSaveInterval = Duration(seconds: 5);
  static const Duration progressUpdateInterval = Duration(seconds: 30);

  // 防抖/节流配置
  static const Duration playDebounceDelay = Duration(milliseconds: 300);
  static const Duration skipThrottleDelay = Duration(milliseconds: 500);

  // 缓存配置
  static const int maxCoverCacheSize = 50;
  static const int maxQueueLength = 10;

  // 网络配置
  static const int preloadBytes = 1024 * 512; // 512KB
}
```

**Step 2: 更新各处使用硬编码值的地方**

```dart
// PlaybackController
await _player.setSource(DeviceFileSource(filePath))
    .timeout(PlaybackConfig.localSourceTimeout);

// PlaybackStateManager
static const Duration _saveInterval = PlaybackConfig.positionSaveInterval;
```

**Step 3: 运行测试**

```bash
flutter test
```

**Step 4: 提交**

```bash
git add lib/core/constants/playback_config.dart
git commit -m "refactor(audio): 集中化播放配置常量"
```

---

## 测试计划

### 单元测试
- `test/providers/audio/audio_provider_test.dart` - AudioProvider 测试
- `test/providers/audio/playback_controller_test.dart` - PlaybackController 测试
- `test/providers/audio/playback_queue_manager_test.dart` - PlaybackQueueManager 测试
- `test/providers/history/play_history_provider_test.dart` - PlayHistoryProvider 测试

### 集成测试
- `test/integration/playback_flow_test.dart` - 完整播放流程测试

### 运行命令
```bash
cd frontend_flutter

# 单元测试
flutter test test/providers/

# 覆盖率
flutter test --coverage

# 集成测试
flutter test test/integration/
```

---

## 验收标准

1. **代码行数减少**：音频模块代码量减少约 30%
2. **测试覆盖率**：保持或超过当前覆盖率（70%）
3. **功能完整性**：所有现有功能正常工作
4. **耦合度降低**：
   - `AudioProvider` 不再直接依赖 Dio 发送历史记录
   - 状态管理集中在各自的组件中
5. **内聚性提升**：
   - 每个类职责单一明确
   - 队列管理由 `PlaybackQueueManager` 统一负责

---

## 回滚计划

每个 Phase 提交后都保留完整的 git 历史，如遇到问题可回滚：

```bash
# 回滚到指定 commit
git revert <commit-hash>

# 或回滚整个 phase
git revert HEAD~3..HEAD
```

---

## 预期收益

| 指标 | 当前 | 目标 | 改善 |
|------|------|------|------|
| 代码行数 | ~4000 | ~2800 | -30% |
| 文件数量 | 8 | 6-7 | -20% |
| 状态变量 | 15+ | 8 | -40% |
| 队列系统 | 2 | 1 | -50% |
| 可测试性 | 中 | 高 | ↑ |
