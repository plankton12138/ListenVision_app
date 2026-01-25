# 播放器优化计划

> 创建日期: 2026-01-25
> 状态: 待实施
> 优先级: 高

---

## 一、问题概述

当前播放功能存在以下用户体验问题：

1. **播放列表与实际播放内容不匹配** - UI 显示的播放项与实际播放的音频不一致
2. **播放交互不流畅** - 快速点击时出现混乱状态
3. **状态更新延迟** - 播放状态与 UI 显示存在时差
4. **MPV 缓存错误** - `lavf: Failed to create file cache.`

---

## 二、当前架构分析

### 2.1 架构设计（委托模式）

```
AudioProvider (协调器)
├── PlaybackController     → just_audio 播放控制
├── UnifiedPlaylistManager → 统一播放列表（本地+在线）
├── PlaybackStateManager  → 状态持久化
└── AudioMetadataLoader   → 元数据加载
```

### 2.2 核心文件

| 组件 | 文件路径 | 职责 |
|------|----------|------|
| AudioProvider | `lib/presentation/providers/audio/audio_provider.dart` | 协调器，向后兼容接口 |
| PlaybackController | `lib/presentation/providers/audio/playback_controller.dart` | 核心播放控制 |
| UnifiedPlaylistManager | `lib/presentation/providers/audio/unified_playlist_manager.dart` | 播放列表管理 |
| PlaybackStateManager | `lib/presentation/providers/audio/playback_state_manager.dart` | 状态持久化 |
| AudioMetadataLoader | `lib/presentation/providers/audio/audio_metadata_loader.dart` | 元数据加载 |
| PlaylistPage (UI) | `lib/presentation/pages/play_list_page.dart` | 播放列表页面 |

### 2.3 数据流

```
用户点击播放
    ↓
AudioProvider.playUnifiedAt(index)
    ↓
UnifiedPlaylistManager.setCurrentIndex(index)
    ↓
PlaybackController.setSourceAndPlay(playable)
    ↓
just_audio 播放
    ↓
Stream 回调 → notifyListeners() → UI 更新
```

---

## 三、问题详细分析

### 问题1：双重播放列表同步问题

**位置**: `audio_provider.dart:53`, `unified_playlist_manager.dart:22-28`

**问题描述**:
```dart
// AudioProvider 中
List<LocalAudio> _playlist = [];  // 向后兼容的旧列表

// UnifiedPlaylistManager 中
List<PlayableAudio> _playlist = [];  // 新的统一播放列表
```

**风险**: 两个列表需要通过 `_loadPlaylist()` 同步，存在时序窗口，可能导致 UI 显示与实际播放内容不匹配。

**影响**: 🔴 高 - 播放列表显示错误的当前播放项

---

### 问题2：索引同步复杂

**位置**: `unified_playlist_manager.dart:228-235`

**问题描述**:
```dart
void move(int oldIndex, int newIndex) {
  // ...
  // 索引调整逻辑复杂，边界情况多
  if (_currentIndex == oldIndex) { ... }
  else if (_currentIndex > oldIndex && _currentIndex <= newIndex) { ... }
  else if (_currentIndex < oldIndex && _currentIndex >= newIndex) { ... }
}
```

**风险**: 拖拽排序、删除操作时索引计算错误，导致当前播放索引与实际播放内容不符。

**影响**: 🔴 高 - 播放错误的音频

---

### 问题3：状态更新竞态条件

**位置**: `playback_controller.dart:86-119`

**问题描述**:
```dart
void _initListeners() {
  _playerStateSub = _player.playerStateStream.listen((state) {
    // 播放启动保护窗口（2秒内不覆盖手动设置的播放状态）
    if (_isStartingPlayback && !state.playing) { ... }
  });
}
```

**风险**: Stream 监听和手动状态更新可能冲突，导致 UI 显示错误的播放状态。

**影响**: 🟡 中 - UI 状态闪烁或不正确

---

### 问题4：MPV 缓存错误

**错误信息**: `MPV: [error] lavf: Failed to create file cache.`

**原因**: just_audio 底层使用 MPV，某些音频格式或文件路径可能导致缓存创建失败。

**影响**: 🟡 中 - 特定音频播放失败

---

### 问题5：notifyListeners() 过度触发

**位置**: 多个文件

**问题描述**:
```dart
// 任何状态变化都调用，可能导致整个 Widget 树重建
notifyListeners();
```

**风险**: UI 不必要的重绘，影响交互流畅度。

**影响**: 🟡 中 - 交互卡顿

---

## 四、优化方案

### 方案1：统一播放列表数据源 (P0)

**目标**: 消除双重播放列表的同步问题

**设计**:
```dart
// 移除 AudioProvider._playlist
// 仅使用 UnifiedPlaylistManager._playlist 作为单一数据源

class AudioProvider extends ChangeNotifier {
  final UnifiedPlaylistManager _playlistManager;

  // 移除
  // List<LocalAudio> _playlist = [];

  // 直接暴露统一播放列表
  List<PlayableAudio> get playlist => _playlistManager.playlist;
}
```

**实施步骤**:
1. 移除 `AudioProvider._playlist`
2. 更新所有引用 `_playlist` 的代码
3. 更新 UI 层使用 `unifiedPlaylist`
4. 验证向后兼容性

**影响范围**:
- `audio_provider.dart` - 主要修改
- `play_list_page.dart` - UI 层已使用 `unifiedPlaylist`
- 其他依赖 `playlist` getter 的代码

**预期收益**:
- ✅ 消除同步问题根源
- ✅ 简化状态管理
- ✅ 数据流更清晰

---

### 方案2：播放操作队列 (P0)

**目标**: 解决用户快速点击导致的播放混乱

**设计**:
```dart
enum PlaybackCommandType {
  play,
  pause,
  stop,
  seek,
  changeTrack,
}

class PlaybackCommand {
  final PlaybackCommandType type;
  final Map<String, dynamic> params;
  final Completer<void> completer;

  Future<void> execute(PlaybackController controller);
}

class PlaybackQueue {
  final List<PlaybackCommand> _queue = [];
  bool _isProcessing = false;
  final PlaybackController _controller;

  Future<void> enqueue(PlaybackCommand cmd) async {
    _queue.add(cmd);
    if (!_isProcessing) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessing = true;
    while (_queue.isNotEmpty) {
      final cmd = _queue.removeAt(0);
      try {
        await cmd.execute(_controller);
        cmd.completer.complete();
      } catch (e) {
        cmd.completer.completeError(e);
      }
    }
    _isProcessing = false;
  }
}
```

**实施步骤**:
1. 创建 `PlaybackCommand` 和 `PlaybackQueue`
2. 在 `PlaybackController` 中集成队列
3. 将所有播放操作通过队列执行
4. 添加取消/清空队列功能

**影响范围**:
- `playback_controller.dart` - 添加队列
- `audio_provider.dart` - 通过队列调用播放操作

**预期收益**:
- ✅ 播放操作串行化，消除竞态条件
- ✅ 用户快速点击不会导致混乱
- ✅ 更好的错误处理

---

### 方案3：细粒度状态通知 (P1)

**目标**: 减少不必要的 UI 重建

**设计**:
```dart
// 方案 A: 使用不同的通知方法
class AudioProvider extends ChangeNotifier {
  void _notifyPlaybackChanged() { notifyListeners(); }
  void _notifyPlaylistChanged() { notifyListeners(); }
  void _notifyMetadataChanged() { notifyListeners(); }
}

// 方案 B: 使用多个 ChangeNotifier（推荐）
class AudioProvider {
  final PlaybackNotifier _playback = PlaybackNotifier();
  final PlaylistNotifier _playlist = PlaylistNotifier();
  final MetadataNotifier _metadata = MetadataNotifier();

  PlaybackNotifier get playback => _playback;
  PlaylistNotifier get playlist => _playlist;
  MetadataNotifier get metadata => _metadata;
}

// UI 层分别订阅
class PlaylistPage extends StatelessWidget {
  Widget build(BuildContext context) {
    final playlist = context.watch<AudioProvider>().playlist;
    final playback = context.watch<AudioProvider>().playback;
    // ...
  }
}
```

**实施步骤**:
1. 创建独立的状态通知类
2. 分离 AudioProvider 中的状态
3. 更新 UI 层订阅对应的状态

**影响范围**:
- `audio_provider.dart` - 重构状态管理
- 所有使用 AudioProvider 的 UI 组件

**预期收益**:
- ✅ UI 只订阅需要的状态变化
- ✅ 减少不必要的重建
- ✅ 提升交互流畅度

---

### 方案4：索引状态机 (P1)

**目标**: 提升索引管理的可靠性

**设计**:
```dart
enum PlaylistState {
  idle,       // 空闲
  loading,    // 加载中
  playing,    // 播放中
  pausing,    // 暂停中
  seeking,    // 跳转中
  error       // 错误
}

class IndexedPlayer {
  PlaylistState _state = PlaylistState.idle;
  int _currentIndex = -1;

  // 状态转换时验证索引
  bool transitionTo(PlaylistState newState, int index) {
    if (!_isValidIndex(index)) {
      debugPrint('【IndexedPlayer】无效索引: $index');
      return false;
    }

    final oldState = _state;
    _state = newState;
    _currentIndex = index;

    debugPrint('【IndexedPlayer】状态转换: $oldState -> $newState, 索引: $index');
    return true;
  }

  bool _isValidIndex(int index) {
    return index >= 0 && index < _playlist.length;
  }

  // 安全的索引操作
  void moveCurrentTo(int newIndex) {
    if (_state != PlaylistState.idle && _state != PlaylistState.playing) {
      debugPrint('【IndexedPlayer】当前状态不允许移动: $_state');
      return;
    }
    // 移动逻辑...
  }

  void removeCurrent() {
    if (_currentIndex == -1) return;

    // 删除后重置状态
    _playlist.removeAt(_currentIndex);
    _currentIndex = -1;
    _state = PlaylistState.idle;
  }
}
```

**实施步骤**:
1. 创建 `IndexedPlayer` 状态机
2. 在 `UnifiedPlaylistManager` 中集成
3. 添加状态转换验证
4. 添加调试日志

**影响范围**:
- `unified_playlist_manager.dart` - 集成状态机

**预期收益**:
- ✅ 索引变更有明确的状态转换
- ✅ 便于调试和追踪问题
- ✅ 提升可靠性

---

### 方案5：MPV 缓存配置 (P2)

**目标**: 修复特定音频的缓存错误

**设计**:
```dart
// 配置 just_audio 使用缓存
await _player.setAudioSource(
  AudioSource.file(
    filePath,
    tag: MediaItem(
      id: audioId,
      title: title,
      artHeaders: {'Cache-Control': 'no-store'},
    ),
  ),
);

// 或禁用缓存（针对在线音频）
final userAgent = Dio();
final options = Options(
  headers: {
    'Cache-Control': 'no-cache',
    'User-Agent': 'ListenVision/1.0',
  },
);
```

**实施步骤**:
1. 尝试不同的缓存配置
2. 针对在线/本地音频分别处理
3. 添加错误处理和重试机制

**影响范围**:
- `playback_controller.dart` - 音频源设置

**预期收益**:
- ✅ 修复特定音频的播放问题
- ✅ 改善在线音频的加载

---

## 五、实施优先级

| 优先级 | 优化项 | 影响 | 工作量 | 预计时间 |
|--------|--------|------|--------|----------|
| 🔴 P0 | 统一播放列表数据源 | 消除同步问题根源 | 中 | 2-3小时 |
| 🔴 P0 | 播放操作队列 | 解决交互混乱 | 中 | 2-3小时 |
| 🟡 P1 | 细粒度状态通知 | 提升流畅度 | 中 | 3-4小时 |
| 🟡 P1 | 索引状态机 | 提升可靠性 | 中 | 2小时 |
| 🟢 P2 | MPV 缓存配置 | 修复特定错误 | 低 | 1小时 |

**建议实施顺序**:
1. P0: 统一播放列表数据源 → 解决根本问题
2. P0: 播放操作队列 → 解决用户痛点
3. P1: 索引状态机 → 提升可靠性
4. P1: 细粒度状态通知 → 优化性能
5. P2: MPV 缓存配置 → 修复边界问题

---

## 六、验证方案

### 测试场景

1. **基础播放测试**
   - [ ] 点击播放列表项，正常播放
   - [ ] 点击当前播放项，切换暂停/播放
   - [ ] 播放完成后自动播放下一首

2. **列表操作测试**
   - [ ] 删除播放项后，索引正确更新
   - [ ] 清空列表后，播放器状态正确重置
   - [ ] 拖拽排序后，当前播放项索引正确

3. **快速交互测试**
   - [ ] 快速连续点击多个播放项，最终播放正确的音频
   - [ ] 快速切换播放/暂停，状态正确显示
   - [ ] 快速拖动进度条，跳转正常

4. **状态恢复测试**
   - [ ] 应用重启后，播放列表正确恢复
   - [ ] 应用重启后，播放位置正确恢复
   - [ ] 应用重启后，当前播放项高亮正确

### 性能指标

| 指标 | 当前值 | 目标值 |
|------|--------|--------|
| 播放响应时间 | < 500ms | < 200ms |
| 列表滚动帧率 | 55fps | 60fps |
| 状态更新延迟 | < 100ms | < 50ms |

---

## 七、风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 向后兼容性破坏 | 高 | 保留旧接口，逐步迁移 |
| 新功能引入新 Bug | 中 | 充分测试，分阶段发布 |
| 性能回归 | 低 | 性能基准测试 |

---

## 八、参考文档

- [Phase 2 在线播放功能](./PHASE_2_ONLINE_PLAYBACK.md)
- [音频播放器修复方案](./AUDIO_PLAYER_FIX_PLAN.md)
- [渐进式架构迁移计划](./INCREMENTAL_MIGRATION_PLAN.md)

---

## 九、更新日志

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-01-25 | 1.0 | 初始版本 |
| 2026-01-25 | 1.1 | 实施完成：方案1（统一数据源）+ 方案2（播放队列）+ Bug修复 |

## 十、实施记录

### 已完成 (2026-01-25)

#### P0-1: 统一播放列表数据源 ✅
- 移除 `AudioProvider._playlist` 冗余字段
- 改用 `_playlistManager.localPlaylist` 单一数据源
- 修改文件：`audio_provider.dart`

#### P0-2: 播放操作队列 ✅
- 创建 `playback_queue.dart` (PlaybackCommand, PlaybackQueue, PlaybackQueueState)
- 集成到 `PlaybackController`
- 所有播放操作通过命令执行

#### Bug 修复 ✅
| 问题 | 修复 |
|------|------|
| 上下首不循环 | `_playUnifiedAtIndex` 添加 `setCurrentIndex` |
| 在线音频不能拖动 | 设置 `_isSeekable = true` (HTTP Range 支持) |
| 播放列表插入不更新 | `playOnlineAudio` 添加 `save()` 调用 |

### 待实施

- [ ] P1: 细粒度状态通知
- [ ] P1: 索引状态机
- [ ] P2: MPV 缓存配置优化

