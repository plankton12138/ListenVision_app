# Phase 2A: 播放功能与播放列表改进计划

> **创建日期**: 2026-01-19
>
> **目标**: 完善播放功能，实现播放列表持久化和播放控制
>
> **依赖**: Phase 2 完成（歌单系统、收藏功能、推荐页面）

---

## 一、问题概述

| 问题 | 描述 | 用户期望 |
|------|------|----------|
| 歌单无法播放 | 点击音频只显示"功能待开发" | 能直接播放歌单中的音乐 |
| 搜索结果无法播放 | 搜索到的音频无法直接播放 | 搜索结果可点击播放或添加到歌单 |
| 播放列表不持久 | 关闭后播放列表丢失 | 重启后恢复播放列表 |
| 播放进度丢失 | 关闭后从头播放 | 自动保存并恢复播放位置 |
| 无法调整顺序 | 拖拽排序未保存 | 拖拽后保存播放顺序 |
| 播放控制简陋 | 缺少循环模式等 | 完整播放控制功能 |

---

## 二、架构设计

### 2.1 播放系统数据流

```
用户点击歌单音频
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│ 1. PlaylistDetailPage 点击事件                            │
│    └─ 获取歌单项 (List<PlaylistItem>)                    │
├─────────────────────────────────────────────────────────┤
│ 2. AudioProvider.playPlaylist()                           │
│    ├─ 设置 _currentOnlinePlaylist (播放队列)              │
│    ├─ 设置 _currentPlaylistIndex (当前索引)               │
│    └─ 设置 _loopMode (循环模式)                           │
├─────────────────────────────────────────────────────────┤
│ 3. BilibiliProvider.getAudioStream(bvid)                   │
│    └─ 获取音频流URL                                       │
├─────────────────────────────────────────────────────────┤
│ 4. 转换为代理URL (解决防盗链)                              │
│    └─ http://localhost:3000/api/bilibili/proxy/audio?url=...  │
├─────────────────────────────────────────────────────────┤
│ 5. AudioPlayer.play(UrlSource(url))                        │
│    └─ 播放在线音频                                         │
├─────────────────────────────────────────────────────────┤
│ 6. 记录播放历史 (PlayHistoryProvider)                       │
│    └─ 保存到本地 + 同步到后端                              │
├─────────────────────────────────────────────────────────┤
│ 7. 保存播放队列 (PlaylistManager)                          │
│    └─ 保存到本地 online_queue 表                           │
├─────────────────────────────────────────────────────────┤
│ 8. 定期保存进度 (每10秒)                                   │
│    └─ 更新播放历史中的 progress 字段                        │
└─────────────────────────────────────────────────────────┘
```

### 2.2 循环模式设计

```dart
enum LoopMode {
  list,    // 列表循环 - 到达末尾后回到开头
  single,  // 单曲循环 - 重复播放当前音频
  shuffle, // 随机播放 - 随机选择下一首
}
```

### 2.3 数据存储设计

**本地数据库** (SQLite):
```sql
-- 在线播放队列表
CREATE TABLE IF NOT EXISTS online_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bvid TEXT NOT NULL UNIQUE,
  title TEXT,
  artist TEXT,
  duration INTEGER,
  cover_url TEXT,
  position INTEGER NOT NULL DEFAULT 0
);

-- 播放状态表
CREATE TABLE IF NOT EXISTS playback_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  current_bvid TEXT,
  current_index INTEGER DEFAULT 0,
  loop_mode TEXT DEFAULT 'list',
  playback_type TEXT DEFAULT 'online',  -- 'local' | 'online'
  updated_at TEXT DEFAULT (datetime('now'))
);
```

---

## 三、实施步骤

### 步骤 1: 扩展 AudioProvider - 在线播放支持

**文件**: `frontend_flutter/lib/providers/audio_provider.dart`

**新增状态变量**:
```dart
// 在线播放队列
List<PlaylistItem> _currentOnlinePlaylist = [];
int _currentOnlineIndex = 0;

// 循环模式
LoopMode _loopMode = LoopMode.list;

// 播放类型
PlaybackType _playbackType = PlaybackType.local;

// 进度保存定时器
Timer? _progressSaveTimer;

// 当前在线音频信息
String? _currentBvid;
String? _currentOnlineTitle;
String? _currentOnlineArtist;
String? _currentOnlineCoverUrl;
```

**新增方法**:
1. `playPlaylist()` - 播放整张歌单
2. `playOnlineItem()` - 播放单个在线音频
3. `setLoopMode()` / `toggleLoopMode()` - 切换循环模式
4. `_startProgressSaving()` / `_stopProgressSaving()` - 进度自动保存
5. `loadPlaybackState()` - 启动时恢复播放状态
6. `_savePlaybackState()` - 保存播放状态

**修改现有方法**:
1. `playNext()` - 支持在线播放和循环模式
2. `playPrevious()` - 支持在线播放
3. `_updatePlayState()` - 触发进度保存

---

### 步骤 2: 扩展 PlaylistManager - 持久化支持

**文件**: `frontend_flutter/lib/services/playlist_manager.dart`

**新增方法**:
1. `saveOnlineQueue()` - 保存在线播放队列
2. `getOnlineQueue()` - 获取在线播放队列
3. `savePlaybackState()` - 保存播放状态
4. `getPlaybackState()` - 获取播放状态
5. `clearOnlineQueue()` - 清空在线队列

---

### 步骤 3: 实现歌单详情页播放功能

**文件**: `frontend_flutter/lib/ui/pages/playlist_detail_page.dart`

**修改内容**:
1. 替换 `onTap` 中的"功能开发中"提示
2. 调用 `AudioProvider.playPlaylist()` 播放歌单
3. 记录播放历史
4. 添加"播放全部"按钮

---

### 步骤 4: 实现播放顺序持久化

**文件**: `frontend_flutter/lib/ui/pages/playlist_detail_page.dart`

**修改内容**:
1. 在 `_reorderItems()` 中调用后端 API
2. 调用 `PUT /api/playlists/:id/items/reorder` 保存新顺序
3. 失败时回滚 UI 状态

---

### 步骤 5: 创建播放器页面 UI

**文件**: `frontend_flutter/lib/ui/pages/player_page.dart` (新建/修改)

**功能**:
1. 显示当前播放的音频信息（封面、标题、艺术家）
2. 播放进度条（可拖动）
3. 播放控制按钮（上一曲、播放/暂停、下一曲）
4. 循环模式切换按钮
5. 播放列表展开/收起
6. 收藏按钮

---

### 步骤 6: 处理发现页面

**文件**: `frontend_flutter/lib/ui/pages/explore_page.dart`

**修改内容**:
1. B站推荐视频：点击后显示提示"推荐视频播放即将上线"
2. 歌单推荐：显示"歌单详情功能开发中，留待QQ音乐集成"

---

### 步骤 7: 实现搜索结果播放功能

**文件**: `frontend_flutter/lib/ui/pages/search_page.dart`

**修改内容**:
1. 搜索结果项添加播放按钮
2. 点击播放按钮直接播放该音频
3. 长按或点击"更多"按钮弹出菜单：
   - 添加到歌单
   - 添加到"我喜欢"
   - 下载音频
4. 播放时自动创建临时播放队列（当前搜索结果）

**新增功能**:
- `playSearchResult()` - 播放搜索结果中的单个音频
- `showAddToPlaylistDialog()` - 显示添加到歌单对话框

---

## 四、关键文件清单

| 文件 | 操作 | 优先级 |
|------|------|--------|
| `lib/providers/audio_provider.dart` | 修改 | 🔴 高 |
| `lib/ui/pages/playlist_detail_page.dart` | 修改 | 🔴 高 |
| `lib/services/playlist_manager.dart` | 修改 | 🔴 高 |
| `lib/ui/pages/search_page.dart` | 修改 | 🔴 高 |
| `lib/ui/pages/player_page.dart` | 新建/修改 | 🟡 中 |
| `lib/ui/pages/explore_page.dart` | 修改 | 🟢 低 |

---

## 五、知识点说明

1. **Provider 状态同步**: 多个 Provider 协同工作，通过 `context.read()` 获取引用
2. **在线音频播放**: 使用 `audioplayers` 的 `UrlSource` 播放网络音频
3. **防盗链处理**: 通过后端代理服务添加 Referer 头
4. **持久化策略**: 本地 SQLite 存储（在线队列 + 播放状态）
5. **进度保存频率**: 每 10 秒保存一次，平衡性能和数据安全

---

## 六、验收标准

**功能验收**:
- [ ] 点击歌单中的音频能直接播放
- [ ] 搜索结果可以点击播放
- [ ] 搜索结果可以添加到歌单
- [ ] 上一曲/下一曲按钮正常工作
- [ ] 循环模式切换正常（列表/单曲/随机）
- [ ] 应用重启后恢复播放列表和播放位置
- [ ] 拖拽调整播放顺序后能保存
- [ ] 播放进度每10秒自动保存
- [ ] 发现页面显示相应提示信息

**文档验收**:
- [ ] CLAUDE.md 更新完成
- [ ] README.md 更新完成
- [ ] PHASE_2_PLAYLIST_PLAN.md 更新完成
- [ ] INCREMENTAL_MIGRATION_PLAN.md 更新完成

---

## 七、进度跟踪

| 步骤 | 状态 | 完成日期 |
|------|------|----------|
| 步骤 1: 扩展 AudioProvider | ⏳ 进行中 | |
| 步骤 2: 扩展 PlaylistManager | ⏸️ 待开始 | |
| 步骤 3: 歌单详情页播放功能 | ⏸️ 待开始 | |
| 步骤 4: 播放顺序持久化 | ⏸️ 待开始 | |
| 步骤 5: 播放器页面 UI | ⏸️ 待开始 | |
| 步骤 6: 发现页面处理 | ⏸️ 待开始 | |
| 步骤 7: 搜索结果播放功能 | ⏸️ 待开始 | |

---

*本文档由 Claude Code 生成 | 创建: 2026-01-19 | 最后更新: 2026-01-19*
