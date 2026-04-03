# 播放问题修复实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复播放相关问题：队列恢复后状态同步、播放失败处理、元数据与显示一致性

**Architecture:** 遵循 MVVM 分层，ViewModel 依赖 Service 层抽象接口而非第三方库；使用 `AudioPlaybackState` 枚举解耦 audioplayers 实现；PlaybackViewModel 负责播放控制和状态，QueueViewModel 负责队列数据管理

**Tech Stack:** Flutter 3.38.5, Riverpod 3.0, freezed, audioplayers

---

## 问题诊断摘要

| 问题 | 根因 | 影响 |
|------|------|------|
| 队列恢复后状态不同步 | `_loadFromStorage` 仅恢复数据，未通知 PlaybackViewModel | UI 显示不正确 |
| WindowsAudioError | 音频源加载失败时缺少重试和错误提示 | 播放中断 |
| 元数据不匹配 | `play()` 方法与 `prepareSource()` 的状态设置不一致 | 封面/标题错误 |

---

## 文件结构

```
frontend_flutter/lib/
├── services/
│   └── audio_player_service.dart          # [修改] 增强错误处理
├── presentation/viewmodels/player/
│   ├── playback_viewmodel.dart            # [修改] 状态同步逻辑
│   └── queue_viewmodel.dart               # [修改] 恢复后通知机制
└── presentation/views/player/
    └── home_page.dart                     # [修改] 恢复播放流程

frontend_flutter/test/viewmodels/player/
└── playback_viewmodel_test.dart           # [修改] 新增测试用例
```

---

## Task 1: 队列恢复后同步 PlaybackViewModel 状态

**Files:**
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart:467-574`
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart:394-438`
- Test: `frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart`

**问题:** `QueueViewModel._loadFromStorage()` 恢复队列数据后，`PlaybackViewModel` 不知道当前应该播放哪首歌，导致 UI 状态不一致。

**解决方案:** 在 `QueueViewModel` 完成恢复后，通知 `PlaybackViewModel` 准备（但不自动播放）当前索引的歌曲。

- [ ] **Step 1: 在 PlaybackViewModel 添加恢复准备方法**

在 `playback_viewmodel.dart` 的 `PlaybackViewModel` 类中添加 `prepareCurrentFromQueue` 方法：

```dart
/// 从队列准备当前音频（不自动播放）
///
/// 用于应用启动时恢复上次播放位置
/// 依赖 QueueViewModel 已恢复完成
Future<void> prepareCurrentFromQueue() async {
  if (_disposed) return;

  final queueNotifier = ref.read(queueViewModelProvider.notifier);
  final queueState = ref.read(queueViewModelProvider);
  final currentIndex = queueState.currentIndex;

  // 验证索引有效性
  if (currentIndex < 0 || currentIndex >= queueState.queue.length) {
    AppLogger.debug('PlaybackViewModel', '队列索引无效，跳过恢复');
    return;
  }

  final playable = queueState.queue[currentIndex];
  final savedPosition = await queueNotifier.restorePosition() ?? 0;

  AppLogger.info('PlaybackViewModel', '恢复队列项: ${playable.title}, 位置: ${savedPosition}s');

  await prepareSource(playable, startPosition: savedPosition);
}
```

- [ ] **Step 2: 在 QueueViewModel 添加恢复完成回调**

在 `queue_viewmodel.dart` 的 `QueueViewModel` 类中添加回调机制：

```dart
// 在类顶部添加字段
/// 队列恢复完成回调列表
final List<void Function()> _onQueueRestoredCallbacks = [];

/// 注册队列恢复完成回调
void onQueueRestored(void Function() callback) {
  if (_didFinishInitialRestore) {
    callback();
  } else {
    _onQueueRestoredCallbacks.add(callback);
  }
}
```

在 `_loadFromStorage` 方法的 `finally` 块中，添加回调执行：

```dart
} finally {
  _isRestoringFromStorage = false;
  _didFinishInitialRestore = true;

  // 执行恢复完成回调
  for (final callback in _onQueueRestoredCallbacks) {
    callback();
  }
  _onQueueRestoredCallbacks.clear();
}
```

- [ ] **Step 3: 在 home_page.dart 集成恢复流程**

修改 `home_page.dart` 的 `_HomePageState` 类，在 `initState` 中添加队列恢复后的播放准备：

```dart
@override
void initState() {
  super.initState();

  // 注册队列恢复完成回调
  ref.read(queueViewModelProvider.notifier).onQueueRestored(() {
    // 准备当前音频（不自动播放）
    ref.read(playbackViewModelProvider.notifier).prepareCurrentFromQueue();
  });

  // 延迟处理 URL 参数
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _handleUrlParams();
  });
}
```

- [ ] **Step 4: 编写测试用例**

在 `playback_viewmodel_test.dart` 添加：

```dart
group('PlaybackState 队列恢复测试', () {
  test('prepareCurrentFromQueue 应能从队列恢复当前项', () {
    // 这个测试需要 mock QueueViewModel 和 StorageService
    // 验证：恢复的索引和位置正确传递给 prepareSource
  });

  test('prepareCurrentFromQueue 在索引无效时应安全跳过', () {
    // 验证：currentIndex = -1 时不抛出异常
  });
});
```

- [ ] **Step 5: 运行测试验证**

Run: `cd frontend_flutter && flutter test test/viewmodels/player/playback_viewmodel_test.dart`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/*.dart
git add frontend_flutter/lib/presentation/views/player/home_page.dart
git add frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart
git commit -m "fix(player): 添加队列恢复后状态同步机制"
```

---

## Task 2: 增强音频播放错误处理

**Files:**
- Modify: `frontend_flutter/lib/services/audio_player_service.dart:129-138`
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart:234-250`
- Test: `frontend_flutter/test/services/audio_player_service_test.dart`

**问题:** `WindowsAudioError` 等平台错误发生时，缺少详细日志和重试机制。

**解决方案:** 在 Service 层添加错误分类，在 ViewModel 层提供用户友好的错误提示。

- [ ] **Step 1: 在 AudioPlayerService 添加错误分类**

在 `audio_player_service.dart` 中添加错误类型枚举和分类方法：

```dart
/// 音频播放错误类型
enum AudioPlayerErrorType {
  /// 源加载失败
  sourceLoadFailed,
  /// 网络错误
  networkError,
  /// 文件不存在
  fileNotFound,
  /// 格式不支持
  formatNotSupported,
  /// 平台错误
  platformError,
  /// 未知错误
  unknown,
}

/// 根据异常分类错误类型
AudioPlayerErrorType classifyError(dynamic error) {
  final errorString = error.toString().toLowerCase();

  if (errorString.contains('windowsaudioerror') ||
      errorString.contains('platformexception')) {
    return AudioPlayerErrorType.platformError;
  }
  if (errorString.contains('network') ||
      errorString.contains('socket') ||
      errorString.contains('timeout')) {
    return AudioPlayerErrorType.networkError;
  }
  if (errorString.contains('file not found') ||
      errorString.contains('enoent')) {
    return AudioPlayerErrorType.fileNotFound;
  }
  if (errorString.contains('format') ||
      errorString.contains('unsupported')) {
    return AudioPlayerErrorType.formatNotSupported;
  }
  if (errorString.contains('source')) {
    return AudioPlayerErrorType.sourceLoadFailed;
  }
  return AudioPlayerErrorType.unknown;
}

/// 获取用户友好的错误消息
String getUserFriendlyMessage(AudioPlayerErrorType type) {
  return switch (type) {
    AudioPlayerErrorType.sourceLoadFailed => '音频源加载失败，请重试',
    AudioPlayerErrorType.networkError => '网络连接失败，请检查网络',
    AudioPlayerErrorType.fileNotFound => '音频文件不存在或已被删除',
    AudioPlayerErrorType.formatNotSupported => '音频格式不支持',
    AudioPlayerErrorType.platformError => '播放器初始化失败，请重启应用',
    AudioPlayerErrorType.unknown => '播放失败，请重试',
  };
}
```

- [ ] **Step 2: 修改 PlaybackViewModel.play() 的错误处理**

在 `playback_viewmodel.dart` 的 `play()` 方法中，使用新的错误分类：

```dart
try {
  if (playable.isOnline && playable is OnlinePlayable) {
    await _playOnline(playable);
  } else if (playable is LocalPlayable) {
    await _playLocal(playable);
  }

  state = state.copyWith(isLoading: false, isPlaying: true);
  _startPositionSaveTimer();
  _recordHistory(playable);
} catch (e) {
  AppLogger.error('PlaybackViewModel', '播放失败: $e');

  // 分类错误并获取用户友好消息
  final errorType = classifyError(e);
  final userMessage = getUserFriendlyMessage(errorType);

  state = state.copyWith(
    isLoading: false,
    errorMessage: userMessage,
  );
}
```

- [ ] **Step 3: 在 AudioPlayerService 添加源加载重试**

在 `audio_player_service.dart` 的 `playUrl` 和 `setUrlSource` 方法中添加重试逻辑：

```dart
/// 播放在线URL（带重试）
///
/// [url] 在线音频流的 URL 地址
/// [maxRetries] 最大重试次数（默认 2）
Future<void> playUrl(String url, {int maxRetries = 2}) async {
  if (_disposed) return;

  int attempt = 0;
  while (attempt <= maxRetries) {
    try {
      AppLogger.info('AudioPlayerService', '播放在线URL (尝试 ${attempt + 1}): $url');
      await _player.play(UrlSource(url));
      _currentSourceUrl = url;
      return; // 成功，退出重试循环
    } catch (e) {
      attempt++;
      if (attempt > maxRetries) {
        AppLogger.error('AudioPlayerService', '播放失败，已重试 $maxRetries 次: $e');
        rethrow;
      }
      // 等待后重试
      await Future.delayed(Duration(milliseconds: 500 * attempt));
      AppLogger.warn('AudioPlayerService', '播放失败，准备重试 ($attempt/$maxRetries): $e');
    }
  }
}
```

- [ ] **Step 4: 编写测试用例**

在 `audio_player_service_test.dart` 添加错误分类测试：

```dart
group('AudioPlayerService 错误分类测试', () {
  test('classifyError 应正确识别平台错误', () {
    expect(
      classifyError('PlatformException(WindowsAudioError, Failed to set source)'),
      AudioPlayerErrorType.platformError,
    );
  });

  test('classifyError 应正确识别网络错误', () {
    expect(
      classifyError('SocketException: Connection failed'),
      AudioPlayerErrorType.networkError,
    );
  });

  test('getUserFriendlyMessage 应返回可读消息', () {
    expect(
      getUserFriendlyMessage(AudioPlayerErrorType.networkError),
      contains('网络'),
    );
  });
});
```

- [ ] **Step 5: 运行测试验证**

Run: `cd frontend_flutter && flutter test test/services/audio_player_service_test.dart`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/services/audio_player_service.dart
git add frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart
git add frontend_flutter/test/services/audio_player_service_test.dart
git commit -m "fix(player): 增强音频播放错误处理和重试机制"
```

---

## Task 3: 统一元数据状态管理

**Files:**
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart:394-438`
- Test: `frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart`

**问题:** `play()` 和 `prepareSource()` 设置的状态字段不一致，可能导致封面/标题显示错误。

**解决方案:** 提取公共方法 `_updatePlayableState()` 确保状态一致性。

- [ ] **Step 1: 提取公共状态更新方法**

在 `playback_viewmodel.dart` 的 `PlaybackViewModel` 类中添加私有方法：

```dart
/// 更新当前播放项的状态
///
/// 统一设置元数据字段，确保一致性
void _updatePlayableState(PlayableAudio playable, {int index = -1}) {
  state = state.copyWith(
    currentPlayable: playable,
    title: playable.title,
    artist: playable.artist ?? '未知艺术家',
    coverUrl: playable.coverUrl,
    coverData: playable.coverData,
    currentIndex: index,
    errorMessage: null,
  );
}
```

- [ ] **Step 2: 重构 play() 方法使用公共方法**

修改 `play()` 方法：

```dart
Future<void> play(PlayableAudio playable, {int index = -1}) async {
  if (_disposed) return;

  AppLogger.info('PlaybackViewModel', '播放: ${playable.title}');

  // 使用公共方法设置状态
  _updatePlayableState(playable, index: index);
  state = state.copyWith(isLoading: true);

  try {
    if (playable.isOnline && playable is OnlinePlayable) {
      await _playOnline(playable);
    } else if (playable is LocalPlayable) {
      await _playLocal(playable);
    }

    state = state.copyWith(isLoading: false, isPlaying: true);
    _startPositionSaveTimer();
    _recordHistory(playable);
  } catch (e) {
    // ... 错误处理
  }
}
```

- [ ] **Step 3: 重构 prepareSource() 方法使用公共方法**

修改 `prepareSource()` 方法：

```dart
Future<void> prepareSource(PlayableAudio playable, {int startPosition = 0}) async {
  if (_disposed) return;

  AppLogger.info('PlaybackViewModel', '准备音频源: ${playable.title}');

  // 使用公共方法设置状态
  _updatePlayableState(playable);
  state = state.copyWith(isLoading: true);

  try {
    // ... 加载逻辑
  }
}
```

- [ ] **Step 4: 编写测试用例**

```dart
group('PlaybackState 元数据一致性测试', () {
  test('play 和 prepareSource 应设置相同的元数据', () {
    // 创建测试用的 PlayableAudio
    // 验证：调用 play() 和 prepareSource() 后状态一致
  });

  test('_updatePlayableState 应正确处理 null 字段', () {
    // 验证：artist 为 null 时使用默认值
  });
});
```

- [ ] **Step 5: 运行测试验证**

Run: `cd frontend_flutter && flutter test test/viewmodels/player/playback_viewmodel_test.dart`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart
git add frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart
git commit -m "refactor(player): 统一元数据状态管理，确保一致性"
```

---

## Task 4: 添加播放状态完整性验证

**Files:**
- Create: `frontend_flutter/lib/core/utils/playback_state_validator.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart`
- Test: `frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart`

**问题:** 状态可能处于不一致状态（如 `isPlaying: true` 但 `currentPlayable: null`），导致 UI 异常。

**解决方案:** 添加状态验证器，在关键操作前后检查状态完整性。

- [ ] **Step 1: 创建状态验证器**

创建 `frontend_flutter/lib/core/utils/playback_state_validator.dart`：

```dart
import '../../../presentation/viewmodels/player/playback_viewmodel.dart';

/// 播放状态验证结果
class PlaybackStateValidationResult {
  final bool isValid;
  final List<String> issues;

  const PlaybackStateValidationResult({
    required this.isValid,
    this.issues = const [],
  });
}

/// 播放状态验证器
class PlaybackStateValidator {
  /// 验证状态完整性
  static PlaybackStateValidationResult validate(PlaybackState state) {
    final issues = <String>[];

    // 规则 1: 播放中必须有当前音频
    if (state.isPlaying && state.currentPlayable == null) {
      issues.add('isPlaying=true 但 currentPlayable=null');
    }

    // 规则 2: 有效索引必须有对应音频
    if (state.currentIndex >= 0 && state.currentPlayable == null) {
      issues.add('currentIndex>=0 但 currentPlayable=null');
    }

    // 规则 3: 加载中不应同时播放
    if (state.isLoading && state.isPlaying) {
      issues.add('isLoading 和 isPlaying 同时为 true');
    }

    // 规则 4: 播放和暂停互斥
    if (state.isPlaying && state.isPaused) {
      issues.add('isPlaying 和 isPaused 同时为 true');
    }

    return PlaybackStateValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }

  /// 修复不一致状态
  static PlaybackState repair(PlaybackState state) {
    if (state.isPlaying && state.currentPlayable == null) {
      return state.copyWith(isPlaying: false);
    }
    if (state.isLoading && state.isPlaying) {
      return state.copyWith(isPlaying: false);
    }
    if (state.isPlaying && state.isPaused) {
      return state.copyWith(isPaused: false);
    }
    return state;
  }
}
```

- [ ] **Step 2: 在 PlaybackViewModel 中集成验证**

在 `playback_viewmodel.dart` 中添加验证调用（仅 DEBUG 模式）：

```dart
import '../../../core/utils/playback_state_validator.dart';

// 在状态更新后添加验证
void _validateState() {
  assert(() {
    final result = PlaybackStateValidator.validate(state);
    if (!result.isValid) {
      AppLogger.warn('PlaybackViewModel', '状态不一致: ${result.issues}');
    }
    return true;
  }());
}
```

在关键方法末尾调用 `_validateState()`。

- [ ] **Step 3: 编写验证器测试**

```dart
group('PlaybackStateValidator 测试', () {
  test('应检测到 isPlaying=true 且 currentPlayable=null 的不一致', () {
    final state = PlaybackState(isPlaying: true, currentPlayable: null);
    final result = PlaybackStateValidator.validate(state);
    expect(result.isValid, false);
    expect(result.issues, contains(contains('currentPlayable')));
  });

  test('应检测到 isLoading 和 isPlaying 同时为 true', () {
    final state = PlaybackState(isLoading: true, isPlaying: true);
    final result = PlaybackStateValidator.validate(state);
    expect(result.isValid, false);
  });

  test('repair 应修复不一致状态', () {
    final state = PlaybackState(isPlaying: true, currentPlayable: null);
    final repaired = PlaybackStateValidator.repair(state);
    expect(repaired.isPlaying, false);
  });
});
```

- [ ] **Step 4: 运行测试验证**

Run: `cd frontend_flutter && flutter test test/viewmodels/player/playback_viewmodel_test.dart`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add frontend_flutter/lib/core/utils/playback_state_validator.dart
git add frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart
git add frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart
git commit -m "feat(player): 添加播放状态完整性验证"
```

---

## 验收标准

1. **队列恢复**：应用启动后，队列恢复且 UI 正确显示当前项信息（不自动播放）
2. **错误处理**：播放失败时显示用户友好的错误提示，而非技术错误信息
3. **元数据一致**：播放任何音频后，封面、标题、艺术家信息与实际播放内容一致
4. **状态完整**：状态转换不会产生不一致的组合（如同时播放和暂停）

## 测试命令

```bash
# 运行所有相关测试
cd frontend_flutter && flutter test test/viewmodels/player/ test/services/audio_player_service_test.dart

# 运行应用验证
cd frontend_flutter && flutter run
```