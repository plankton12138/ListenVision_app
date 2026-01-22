# Phase 3A: 播放列表页面 (PlayListPage) 功能改进计划

> **创建日期**: 2026-01-19
> **最后更新**: 2026-01-22（阶段重排）
>
> **更新日期**: 2026-01-20
>
> **状态**: ✅ **已完成**
>
> **目标**: 优化播放列表页面，添加播放进度持久化和UI交互增强
>
> **依赖**: Phase 3 完成（歌单系统、收藏功能、推荐页面）
>
> **🔄 阶段重排说明**: 原 **Phase 2A** 已重排为 **Phase 3A**，跟随 Phase 3 的阶段调整

---

## 一、功能概述

针对 `PlayListPage`（当前播放列表/播放队列）进行以下改进：

| 功能 | 描述 | 优先级 |
|------|------|--------|
| **播放进度持久化** | 保存当前播放索引和位置，应用重启后恢复 | 🔴 高 |
| **当前播放高亮** | 蓝色背景 + 左侧竖条 + 播放图标 | 🔴 高 |
| **拖拽排序** | ReorderableListView 实现 | 🔴 高 |
| **批量操作** | 清空列表 + 删除确认 | 🟡 中 |

> **注意**: 播放列表中不显示播放进度条，保持简洁的列表样式

---

## 二、当前状态分析

### PlayListPage 当前实现 (`lib/ui/pages/play_list_page.dart`)

**已有功能**:
- ✅ 显示播放列表
- ✅ 点击播放音频
- ✅ 删除单个音频

**缺失功能**:
- ❌ 当前播放项高亮显示
- ❌ 拖拽排序
- ❌ 批量操作（清空列表）
- ❌ 循环模式切换UI

### AudioProvider 当前实现 (`lib/providers/audio_provider.dart`)

**已有功能**:
- ✅ 播放控制（play/pause/next/previous）
- ✅ 播放列表管理
- ✅ 元数据处理

**缺失功能**:
- ❌ 播放进度持久化（currentIndex 和 position 保存）
- ❌ 循环模式（仅实现列表循环）

---

## 三、实施步骤

### 步骤 1: 播放进度持久化

#### 1.1 创建播放状态表

**文件**: `lib/services/playlist_manager.dart`

在数据库中新增 `playback_state` 表：

```dart
// 新增方法
Future<void> savePlaybackState({
  required int audioId,
  required int position,
  required int currentIndex,
}) async {
  final db = await database;
  await db.insert(
    'playback_state',
    {
      'audio_id': audioId,
      'position': position,
      'current_index': currentIndex,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<Map<String, dynamic>?> getPlaybackState() async {
  final db = await database;
  final results = await db.query(
    'playback_state',
    orderBy: 'updated_at DESC',
    limit: 1,
  );
  if (results.isNotEmpty) {
    return results.first;
  }
  return null;
}

Future<void> clearPlaybackState() async {
  final db = await database;
  await db.delete('playback_state');
}
```

#### 1.2 修改 AudioProvider

**文件**: `lib/providers/audio_provider.dart`

**新增字段**:
```dart
Timer? _savePositionTimer; // 定时保存播放位置
static const _saveInterval = Duration(seconds: 5); // 每5秒保存一次
```

**新增方法**:
```dart
/// 启动播放位置定时保存
void _startPositionSaveTimer() {
  _savePositionTimer?.cancel();
  _savePositionTimer = Timer.periodic(_saveInterval, (_) {
    if (_currentIndex >= 0 && _isPlaying) {
      _savePlaybackState();
    }
  });
}

/// 停止定时保存
void _stopPositionSaveTimer() {
  _savePositionTimer?.cancel();
}

/// 保存播放状态
Future<void> _savePlaybackState() async {
  if (_currentIndex < 0 || _playlist.isEmpty) return;
  final audio = _playlist[_currentIndex];
  final db = PlaylistManager();
  await db.savePlaybackState(
    audioId: audio.id!,
    position: _position.inSeconds,
    currentIndex: _currentIndex,
  );
}

/// 恢复播放状态
Future<void> restorePlaybackState() async {
  final db = PlaylistManager();
  final state = await db.getPlaybackState();
  if (state != null) {
    final savedIndex = state['current_index'] as int;
    final savedPosition = Duration(seconds: state['position'] as int);
    if (savedIndex >= 0 && savedIndex < _playlist.length) {
      _currentIndex = savedIndex;
      final audio = _playlist[savedIndex];
      await _player.setSource(DeviceFileSource(audio.filePath));
      await _player.seek(savedPosition);
      notifyListeners();
    }
  }
}
```

**修改现有方法**:
- `playAudio()` - 启动定时保存
- `togglePlayPause()` - 启动/停止定时器
- `dispose()` - 释放前保存状态

---

### 步骤 2: UI 交互优化

**文件**: `lib/ui/pages/play_list_page.dart`

**新增状态**:
```dart
bool _isReordering = false;
```

**UI 改进**:
1. 当前播放项高亮（蓝色背景 + 左侧竖条）
2. 播放/暂停图标动态显示
3. ReorderableListView 拖拽排序
4. 清空列表按钮
5. 删除确认对话框
6. 空列表友好提示

---

## 四、数据库表结构

**文件**: `lib/services/playlist_manager.dart`

在 `onCreate` 中添加新表：

```sql
-- 播放状态表
CREATE TABLE IF NOT EXISTS playback_state (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  audio_id INTEGER NOT NULL,
  position INTEGER NOT NULL DEFAULT 0,
  current_index INTEGER NOT NULL DEFAULT -1,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (audio_id) REFERENCES playlist_audios(id) ON DELETE CASCADE
);
```

---

## 五、关键文件清单

| 文件 | 操作 | 优先级 |
|------|------|--------|
| `lib/providers/audio_provider.dart` | 添加播放状态保存/恢复方法 | 🔴 高 |
| `lib/ui/pages/play_list_page.dart` | 完全重写UI | 🔴 高 |
| `lib/services/playlist_manager.dart` | 添加 playback_state 表和方法 | 🔴 高 |

---

## 六、验收标准

### 播放进度持久化
- [x] 播放音频时自动保存位置（每5秒）
- [x] 暂停时保存当前播放位置
- [x] 应用重启后恢复到上次播放的位置
- [x] 切换音频后正确更新保存的状态

### UI 交互优化
- [x] 当前播放项有蓝色高亮显示
- [x] 当前播放项左侧有蓝色竖条标识
- [x] 正在播放时显示播放图标，暂停时显示暂停图标
- [x] 支持拖拽调整播放列表顺序
- [x] 排序模式与非排序模式UI有明显区别
- [x] 点击清空按钮弹出确认对话框
- [x] 删除单个音频弹出确认对话框
- [x] 空列表时显示友好提示

---

## 七、进度跟踪

| 步骤 | 状态 | 完成日期 |
|------|------|----------|
| 步骤 1.1: 创建播放状态表 | ✅ 已完成 | 2026-01-20 |
| 步骤 1.2: 修改 AudioProvider | ✅ 已完成 | 2026-01-20 |
| 步骤 2: UI 交互优化 | ✅ 已完成 | 2026-01-20 |

---

## 八、注意事项

1. **歌单功能暂不实施** - 歌单详情页的播放、管理功能暂时搁置
2. **在线音频暂不实施** - 本次仅处理本地音频播放列表
3. **循环模式暂不实施** - 保持现有列表循环模式

---

## 九、实施记录

### Bug 修复: 拖拽排序

**Bug #1**: ValueKey 参数为空
- **问题**: `audio.id` 可能为 null，导致 `ValueKey(audio.id)` 失败
- **修复**: 改用 `ValueKey(audio.filePath)`，filePath 始终唯一且非空

**Bug #2**: UI 未刷新
- **问题**: ReorderableListView 在拖拽期间阻止 UI 重建
- **修复**: 在 `provider.loadPlaylist()` 后添加 `setState(() {})` 强制刷新

**Bug #3**: 位置未持久化
- **问题**: `getAllAudios` 使用 `orderBy: 'id ASC'`，但删除后重新插入会生成新 ID
- **修复**: 使用 ID 交换技术（rawUpdate）直接交换数据库记录的 ID

### 核心代码位置

| 功能 | 文件 | 行号 |
|------|------|------|
| 播放状态表定义 | playlist_manager.dart | 48-58 |
| 播放状态保存 | playlist_manager.dart | 115-136 |
| 定时保存 Timer | audio_provider.dart | 34-35, 67-82 |
| 恢复播放状态 | audio_provider.dart | 101-128 |
| 当前播放高亮 | play_list_page.dart | 119-129 |
| 拖拽排序 | play_list_page.dart | 220-272 |
| ID 交换逻辑 | play_list_page.dart | 248-260 |

---

*本文档由 Claude Code 生成 | 创建: 2026-01-19 | 更新: 2026-01-20 | 状态: ✅ 已完成*
