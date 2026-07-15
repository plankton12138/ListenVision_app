# 播放列表 & 播放历史架构优化设计

> 日期：2026-07-15 | 状态：已确认

---

## 一、概述

对现有播放列表、播放队列、播放历史模块进行架构重构，解决三个核心问题：

1. **概念建模错误**：播放队列被作为系统歌单存储，混淆了"持久化歌单"和"瞬时播放上下文"
2. **状态粒度太粗**：PlaylistState 单个状态类承载 8 个字段，任何子集变化触发全量 rebuild
3. **数据同步策略脆弱**：跨 ViewModel 用手动 `ref.invalidate` 同步，缺少响应式 Stream

同时引入播放来源追踪、Undo 删除、歌单封面生成等体验增强。

---

## 二、P0：队列与歌单拆分

### 2.1 删除 `SystemPlaylistType.nowPlaying`

**涉及文件：**

| 文件 | 操作 |
|------|------|
| `models/playlist.dart` | 删除 `SystemPlaylistType.nowPlaying` 枚举值，删除 `Playlist.nowPlaying` 静态常量，删除 `isNowPlaying` getter |
| `models/playlist.freezed.dart` | 重新生成 |
| `models/playlist.g.dart` | 重新生成 |

### 2.2 新建 `PlayQueue` 模型

**文件：`models/play_queue.dart`**（新建）

```dart
@freezed
class PlayQueue with _$PlayQueue {
  const factory PlayQueue({
    required List<PlayableAudio> tracks,
    required int currentIndex,
    @Default(PlayMode.sequence) PlayMode playMode,
    @Default([]) List<int> shuffleOrder,
    QueueSource? source,
  }) = _PlayQueue;
}
```

队列不再进入 `playlists` 表，使用 SharedPrefs 持久化（JSON 序列化到单个 key `play_queue`）。

### 2.3 QueueViewModel 重构

**文件：`presentation/viewmodels/player/queue_viewmodel.dart`**

- 用 `PlayQueue` 模型替换分散的 `queue`/`currentIndex`/`playMode`/`source` 字段
- 持久化改为单个 JSON key `play_queue`，替换 4 个独立 key（`unifiedPlaylist`、`currentPlaylistIndex`、`playMode`、`queueSource`）
- 删除 `_syncNowPlayingToServer()` 空方法
- 删除 `_scheduleSyncToServer()`
- 删除 `saveNowPlayingQueue()` / `saveNowPlayingQueueFromItems()` 两个对 PlaylistViewModel 的回调方法

### 2.4 PlaylistViewModel 清理

**文件：`presentation/viewmodels/library/playlist_viewmodel.dart`**

- 删除 `loadNowPlaying()` 方法
- 删除 `saveNowPlayingQueue()` / `saveNowPlayingQueueFromItems()` 方法
- 删除 `nowPlayingPlaylist`、`nowPlayingItems` 字段（与状态拆分一起处理）
- 删除 `import '../player/queue_viewmodel.dart'`

### 2.5 PlaylistRepository 清理

**文件：`data/repositories/playlist_repository.dart`**

- 删除 `saveNowPlaying()` 方法

---

## 三、P0：PlaylistState 拆分

将 `PlaylistViewModel` 拆为三个独立 Provider，各管各的查询粒度。

### 3.1 歌单列表 Provider

**文件：`presentation/viewmodels/library/playlist_viewmodel.dart`**（重构现有）

```dart
@Riverpod(keepAlive: true)
class PlaylistListNotifier extends _$PlaylistListNotifier {
  @override
  Future<List<Playlist>> build() async {
    return _repository.getUserPlaylists();
  }
  // CRUD: createPlaylist, updatePlaylist, deletePlaylist
}
```

- 删除 `PlaylistState` freezed 定义（initial/loaded/error）
- 用 Riverpod 内置的 `AsyncValue<List<Playlist>>` 替代
- 只管理歌单列表 CRUD，不再管收藏和队列

### 3.2 收藏 Provider

**文件：`presentation/viewmodels/library/favorite_tracks_notifier.dart`**（新建）

```dart
@Riverpod(keepAlive: true)
class FavoriteTracksNotifier extends _$FavoriteTracksNotifier {
  @override
  Future<Set<String>> build() async {
    return _repository.getFavoriteTrackIds(); // 查 tracks 表 is_favorite=1
  }
  Future<void> toggle(String bvid, {...}) async { ... }
  bool isFavorited(String bvid) => state.valueOrNull?.contains(bvid) ?? false;
}
```

- 从 `PlaylistViewModel` 迁移 `toggleFavorite()` 逻辑
- 收藏继续作为 `tracks.is_favorite` 标记，不依赖 playlists 表
- UI 层收藏按钮只 watch 此 Provider

### 3.3 歌单详情 Provider

**文件：`presentation/viewmodels/library/playlist_detail_notifier.dart`**（新建）

```dart
@riverpod
class PlaylistDetailNotifier extends _$PlaylistDetailNotifier {
  @override
  Future<PlaylistDetail> build(String playlistId) async {
    return _repository.getPlaylistDetail(playlistId);
  }
  // addItem, removeItem, reorderItems
}
```

- 接受 `playlistId` 参数，按需加载
- 从 `PlaylistViewModel` 迁移 `addItem()` / `removeItem()` 逻辑

### 3.4 Provider 导出

**文件：`presentation/providers.dart`**

仅导出，不包含实现。

---

## 四、P1：播放历史重构

### 4.1 新增 PlayHistoryDao

**文件：`data/database/play_history_dao.dart`**（新建）

从 `AppDatabase`（`play_history` CRUD 部分）和 `HistoryRepository` 中抽取 SQL 操作：

- `getHistory({page, pageSize})` — 分页查询，去重保留最新
- `upsert(history)` — 同 track 更新 played_at
- `deleteById(id)` / `deleteByIds(ids)` / `clearAll()`
- `getStats()` — 聚合统计

### 4.2 重构 PlayHistoryRepository

**文件：`data/repositories/history_repository.dart`**

- 注入 `PlayHistoryDao`，删除直接的 `AppDatabase` 操作
- 内部维护 `StreamController<List<PlayHistory>>`，写操作后 `add()` 通知
- 暴露 `Stream<List<PlayHistory>> watchHistory()` 供 ViewModel 订阅
- 新增 `getFavoriteTrackIds()` 方法（查 tracks 表 is_favorite=1 的 source_id）

### 4.3 重构 HistoryViewModel

**文件：`presentation/viewmodels/library/history_viewmodel.dart`**

- 删除 JSON 缓存逻辑（`_loadHistoryFromLocal` / `_saveHistoryToLocal`）
- 删除 `SharedStorageService` 依赖
- `build()` 中直接从 SQLite 加载首屏数据
- 用 `ref.watch` 监听 Repository Stream 做增量更新
- 配合 Stream 通知，其他 ViewModel 不再需要手动 invalidate

### 4.4 PlaybackViewModel 同步

播放器每切换一首歌 → Repository 自动通知 HistoryViewModel → UI 增量更新。不再需要手动调用 invalidate。

---

## 五、P2：体验增强

### 5.1 播放来源追踪

**数据库迁移：** `play_history` 表加 `source_type TEXT` 和 `source_id TEXT` 字段

**模型：`models/play_history.dart`**

```dart
@freezed
class PlaySource with _$PlaySource {
  const factory PlaySource.playlist(String playlistId) = _FromPlaylist;
  const factory PlaySource.search(String query) = _FromSearch;
  const factory PlaySource.history() = _FromHistory;
  const factory PlaySource.manual() = _FromManual;
}
```

`PlayHistory` 新增 `PlaySource? source` 字段。记录播放时写入来源，UI 层可从历史跳回原始歌单。

### 5.2 Undo 删除

**HistoryViewModel / PlaylistDetailNotifier：**

```dart
Future<void> removeItems(List<String> ids) async {
  final removed = _removeFromState(ids);
  _showUndoSnackBar(removed.length, onUndo: () => _restoreToState(removed));
  await Future.delayed(const Duration(seconds: 3));
  if (!_undone) await _repository.removeItems(ids);
}
```

- 乐观更新 UI → SnackBar "已移除 N 首歌曲" + 撤销按钮
- 3 秒后真正写 DB，用户点撤销则恢复内存状态

### 5.3 歌单封面自动生成

**PlaylistRepository 新增方法：**

取歌单前 4 首曲目的封面，用 Canvas 拼 2x2 网格，保存到本地文件。创建歌单时自动调用，封面变更时更新。

### 5.4 歌单内排序

`playlist_items` 表已有 `position` 字段，`PlaylistDao` 已有 `reorderPlaylistItems()` 方法。

- `PlaylistDetailNotifier` 加 `reorderItems()` 方法
- UI 层接 `ReorderableListView` 支持拖拽排序
- 支持按添加时间/标题/歌手/时长自动排序

### 5.5 历史条数放宽

- 删除 100 条硬限制（`history_viewmodel.dart:192`）
- 改为默认 2000 条软限制
- ViewModel 加分页加载（`LIMIT 50 OFFSET N`）
- UI 做 `ScrollController` 触底加载更多

---

## 六、数据库迁移

**版本 12 → 13：**

| 表 | 变更 |
|----|------|
| `play_history` | 新增 `source_type TEXT`、`source_id TEXT` 字段 |
| `playlists` | 无结构变更（nowPlaying 不再使用，历史数据清理） |

- 删除所有 `system_type = 'now_playing'` 的歌单行（`playlists` + 级联 `playlist_items`）
- 保留其他 system_type（`favorites`）不变

---

## 七、涉及文件汇总

| 文件 | 操作 |
|------|------|
| `models/playlist.dart` | 修改：删除 SystemPlaylistType.nowPlaying |
| `models/playlist.freezed.dart` | 重新生成 |
| `models/playlist.g.dart` | 重新生成 |
| `models/play_queue.dart` | 新建 |
| `models/play_history.dart` | 修改：加 PlaySource |
| `models/play_history.freezed.dart` | 重新生成 |
| `models/play_history.g.dart` | 重新生成 |
| `data/database/app_database.dart` | 修改：DB 迁移 v12→v13，移除 play_history CRUD |
| `data/database/play_history_dao.dart` | 新建 |
| `data/database/playlist_dao.dart` | 不变（已有所需方法） |
| `data/repositories/playlist_repository.dart` | 修改：删 saveNowPlaying |
| `data/repositories/history_repository.dart` | 修改：注入 DAO，加 Stream |
| `data/repositories/repository_providers.dart` | 修改：新增 Provider |
| `presentation/viewmodels/library/playlist_viewmodel.dart` | 重构：拆为 PlaylistListNotifier |
| `presentation/viewmodels/library/playlist_viewmodel.freezed.dart` | 重新生成 |
| `presentation/viewmodels/library/playlist_viewmodel.g.dart` | 重新生成 |
| `presentation/viewmodels/library/favorite_tracks_notifier.dart` | 新建 |
| `presentation/viewmodels/library/playlist_detail_notifier.dart` | 新建 |
| `presentation/viewmodels/library/history_viewmodel.dart` | 重构 |
| `presentation/viewmodels/library/history_viewmodel.freezed.dart` | 重新生成 |
| `presentation/viewmodels/library/history_viewmodel.g.dart` | 重新生成 |
| `presentation/viewmodels/player/queue_viewmodel.dart` | 重构 |
| `presentation/viewmodels/player/queue_viewmodel.freezed.dart` | 重新生成 |
| `presentation/viewmodels/player/queue_viewmodel.g.dart` | 重新生成 |
| `presentation/providers.dart` | 修改：导出新 Provider |
| `presentation/widgets/audio_info.dart` | 修改：收藏按钮改用 FavoriteTracksNotifier |
| `presentation/views/library/local_music_playlist_page.dart` | 修改：改用新 Provider |
| `presentation/views/player/home_page.dart` | 修改：改用 QueueViewModel |
| `presentation/widgets/controls_panel.dart` | 修改：如有收藏按钮需更新 |
| `presentation/widgets/player_action_bar.dart` | 修改：如有收藏按钮需更新 |

---

## 八、验收标准

1. `SystemPlaylistType.nowPlaying` 从代码中完全移除
2. 播放队列独立于歌单系统，通过 `PlayQueue` 模型 + SharedPrefs 持久化
3. 歌单列表、收藏、歌单详情各自独立 Provider，互不触发 rebuild
4. 播放历史有完整 DAO 层，不再使用 JSON 缓存
5. Repository 层通过 Stream 通知 ViewModel，消除跨 ViewModel 手动 invalidate
6. 播放历史记录包含播放来源信息
7. 删除操作有 SnackBar + 撤销按钮
8. 新建歌单自动生成 2x2 拼图封面
9. 歌单内支持拖拽排序
10. 播放历史无硬限制，支持分页加载
