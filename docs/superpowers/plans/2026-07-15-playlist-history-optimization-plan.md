# 播放列表 & 播放历史架构优化 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 将播放队列从歌单系统剥离、拆分过大的 PlaylistState、给播放历史加 DAO 层并用 Stream 替代手动 invalidate，同时加入播放来源追踪、Undo 删除、封面生成等体验增强。

**架构：** 遵循现有 MVVM + Riverpod + DAO/Repository 分层。队列独立为 PlayQueue 模型 + SharedPrefs 持久化；PlaylistState 拆为三个独立 Provider；Repository 内部持 StreamController 通知变更。

**技术栈：** Flutter 3.41.9, Dart 3.11.5, Riverpod 3.0 (riverpod_annotation), freezed, sqflite, SharedPreferences

## 全局约束

- 所有文件路径相对于 `frontend_flutter/lib/`
- 修改 freezed 模型后必须重新运行 `dart run build_runner build --delete-conflicting-outputs`
- 每个任务完成后独立 commit
- providers.dart 仅导出，不存实现
- 日志用 AppLogger 单例

---

### Task 1: 新建 PlayQueue 模型

**文件：**
- 新建：`models/play_queue.dart`

**产出：** `PlayQueue` freezed 模型，后续 QueueViewModel 使用

- [ ] **Step 1: 编写 PlayQueue 模型**

```dart
// models/play_queue.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'playable_audio.dart';
import 'play_mode.dart';
import 'queue_source.dart';

part 'play_queue.freezed.dart';
part 'play_queue.g.dart';

@freezed
class PlayQueue with _$PlayQueue {
  const factory PlayQueue({
    required List<PlayableAudio> tracks,
    required int currentIndex,
    @Default(PlayMode.sequence) PlayMode playMode,
    @Default([]) List<int> shuffleOrder,
    QueueSource? source,
  }) = _PlayQueue;

  factory PlayQueue.fromJson(Map<String, dynamic> json) =>
      _$PlayQueueFromJson(json);
}
```

- [ ] **Step 2: 运行 build_runner 生成 .freezed.dart 和 .g.dart**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: 验证编译**

```bash
cd frontend_flutter && flutter analyze lib/models/play_queue.dart
```

预期：无错误

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/models/play_queue.dart frontend_flutter/lib/models/play_queue.freezed.dart frontend_flutter/lib/models/play_queue.g.dart
git commit -m "feat: 新建 PlayQueue 模型，独立于歌单体系"
```

---

### Task 2: PlayHistory 加 PlaySource 来源追踪

**文件：**
- 修改：`models/play_history.dart`

**产出：** `PlaySource` freezed 联合类型 + `PlayHistory` 新增 `source` 字段

- [ ] **Step 1: 在 play_history.dart 中添加 PlaySource 定义**

在 `play_history.dart` 的 import 区域之后、`PlayHistory` 定义之前插入：

```dart
/// 播放来源
@freezed
abstract class PlaySource with _$PlaySource {
  const factory PlaySource.playlist(String playlistId) = _FromPlaylist;
  const factory PlaySource.search(String query) = _FromSearch;
  const factory PlaySource.history() = _FromHistory;
  const factory PlaySource.manual() = _FromManual;

  factory PlaySource.fromJson(Map<String, dynamic> json) =>
      _$PlaySourceFromJson(json);
}
```

- [ ] **Step 2: PlayHistory 加 source 字段**

在 `PlayHistory` 的 factory constructor 中添加：

```dart
const factory PlayHistory({
  required String id,
  required String userId,
  required Audio audio,
  required DateTime playedAt,
  @Default(0) int progress,
  PlaySource? source,       // ← 新增
  DateTime? createdAt,
  DateTime? updatedAt,
}) = _PlayHistory;
```

- [ ] **Step 3: 更新 PlayHistory.fromDto 解析 source**

在 `fromDto` 方法末尾（return 之前）加 source 解析：

```dart
PlaySource? source;
final sourceType = json['source_type'] as String?;
final sourceId = json['source_id'] as String?;
if (sourceType != null) {
  switch (sourceType) {
    case 'playlist':
      source = PlaySource.playlist(sourceId ?? '');
      break;
    case 'search':
      source = PlaySource.search(sourceId ?? '');
      break;
    case 'history':
      source = const PlaySource.history();
      break;
    case 'manual':
      source = const PlaySource.manual();
      break;
  }
}
```

然后在 `PlayHistory(...)` 构造中传入 `source: source`。

- [ ] **Step 4: 运行 build_runner**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Commit**

```bash
git add frontend_flutter/lib/models/play_history.dart frontend_flutter/lib/models/play_history.freezed.dart frontend_flutter/lib/models/play_history.g.dart
git commit -m "feat: PlayHistory 添加播放来源追踪 PlaySource"
```

---

### Task 3: 清理 Playlist 模型 — 删除 nowPlaying

**文件：**
- 修改：`models/playlist.dart`

**产出：** `SystemPlaylistType` 只剩 `favorites`，删除所有 nowPlaying 相关代码

- [ ] **Step 1: 删除 SystemPlaylistType.nowPlaying**

```dart
// 改前
enum SystemPlaylistType {
  @JsonValue('favorites')
  favorites,
  @JsonValue('now_playing')
  nowPlaying,  // ← 删除这行
}

// 改后
enum SystemPlaylistType {
  @JsonValue('favorites')
  favorites,
}
```

- [ ] **Step 2: 删除 Playlist.nowPlaying 静态常量**

删除约第 134-140 行的 `static const nowPlaying`。

- [ ] **Step 3: 删除 isNowPlaying getter**

删除约第 73 行的 `bool get isNowPlaying => ...`

- [ ] **Step 4: 删除 _parseSystemType 中的 nowPlaying case**

```dart
// 删除 switch 中的这两行
case 'now_playing':
case 'nowPlaying':
  return SystemPlaylistType.nowPlaying;
```

- [ ] **Step 5: 运行 build_runner**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/models/playlist.dart frontend_flutter/lib/models/playlist.freezed.dart frontend_flutter/lib/models/playlist.g.dart
git commit -m "refactor: 从 Playlist 模型删除 nowPlaying 系统歌单类型"
```

---

### Task 4: 数据库迁移 v12 → v13

**文件：**
- 修改：`data/database/app_database.dart`

**产出：** play_history 表新增 source_type / source_id 列，清理 now_playing 歌单数据

- [ ] **Step 1: 添加 v12→v13 升级逻辑**

在 `_onUpgrade` 方法末尾（`_upgradeToV12` 之后）添加：

```dart
// 版本 12 -> 13: 播放历史来源追踪 + 清理 nowPlaying
if (oldVersion < 13) {
  await _upgradeToV13(db);
}
```

- [ ] **Step 2: 实现 _upgradeToV13 方法**

```dart
Future<void> _upgradeToV13(Database db) async {
  AppLogger.info('AppDatabase', '升级数据库到 V13：播放历史来源追踪 + 清理 nowPlaying');

  // 1. 添加 source_type 字段
  try {
    await db.execute('ALTER TABLE play_history ADD COLUMN source_type TEXT');
  } catch (e) {
    AppLogger.debug('AppDatabase', 'source_type 字段可能已存在: $e');
  }

  // 2. 添加 source_id 字段
  try {
    await db.execute('ALTER TABLE play_history ADD COLUMN source_id TEXT');
  } catch (e) {
    AppLogger.debug('AppDatabase', 'source_id 字段可能已存在: $e');
  }

  // 3. 清理 now_playing 系统歌单及其关联项
  final nowPlayingRows = await db.query(
    'playlists',
    where: 'system_type = ?',
    whereArgs: ['now_playing'],
  );
  for (final row in nowPlayingRows) {
    final id = row['id'] as int;
    await db.delete('playlist_items', where: 'playlist_id = ?', whereArgs: [id]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }
  AppLogger.info('AppDatabase', 'V13 迁移完成');
}
```

- [ ] **Step 3: 更新 _createDB 中的 play_history 建表语句**

在 `_createDB` 中，给 play_history 的 CREATE TABLE 加上：

```sql
source_type TEXT,
source_id TEXT,
```

加在 `position` 和 `is_completed` 之间。

- [ ] **Step 4: 更新数据库版本号**

```dart
version: 13,  // 原为 12
```

- [ ] **Step 5: Commit**

```bash
git add frontend_flutter/lib/data/database/app_database.dart
git commit -m "feat: DB v13 — play_history 加 source_type/source_id，清理 nowPlaying 数据"
```

---

### Task 5: 新建 PlayHistoryDao

**文件：**
- 新建：`data/database/play_history_dao.dart`

**产出：** 独立的播放历史 DAO，包含分页查询、去重、统计方法

- [ ] **Step 1: 编写 PlayHistoryDao**

```dart
// data/database/play_history_dao.dart
import '../../core/utils/app_logger.dart';
import 'app_database.dart';

class PlayHistoryDao {
  final AppDatabase _db;

  PlayHistoryDao(this._db);

  /// 分页获取播放历史（去重：同一 source_id 只保留最新一条）
  Future<List<Map<String, dynamic>>> getHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    final db = await _db.database;
    final offset = (page - 1) * pageSize;
    return await db.rawQuery('''
      SELECT ph.* FROM play_history ph
      INNER JOIN (
        SELECT source_id, MAX(played_at) AS max_played
        FROM play_history
        GROUP BY source_id
      ) latest ON ph.source_id = latest.source_id AND ph.played_at = latest.max_played
      ORDER BY ph.played_at DESC
      LIMIT ? OFFSET ?
    ''', [pageSize, offset]);
  }

  /// 插入或更新播放历史（同 source_id 则更新 played_at）
  Future<void> upsert(Map<String, dynamic> history) async {
    final db = await _db.database;
    final sourceId = history['source_id'] as String?;
    if (sourceId == null) return;

    final existing = await db.query(
      'play_history',
      where: 'source_id = ?',
      whereArgs: [sourceId],
      orderBy: 'played_at DESC',
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      history['played_at'] = DateTime.now().toIso8601String();
      await db.update('play_history', history, where: 'id = ?', whereArgs: [id]);
      AppLogger.debug('PlayHistoryDao', '更新播放历史: $sourceId');
    } else {
      history['played_at'] ??= DateTime.now().toIso8601String();
      await db.insert('play_history', history);
      AppLogger.debug('PlayHistoryDao', '插入播放历史: $sourceId');
    }

    // 软限制：保留最近 2000 条
    await _enforceLimit(2000);
  }

  /// 删除单条
  Future<void> deleteById(int id) async {
    final db = await _db.database;
    await db.delete('play_history', where: 'id = ?', whereArgs: [id]);
  }

  /// 批量删除
  Future<void> deleteByIds(List<int> ids) async {
    final db = await _db.database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete('play_history', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  /// 清空
  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('play_history');
  }

  /// 聚合统计
  Future<Map<String, dynamic>> getStats() async {
    final db = await _db.database;
    final total = await db.rawQuery('SELECT COUNT(*) as c FROM play_history');
    final unique = await db.rawQuery(
      'SELECT COUNT(DISTINCT source_id) as c FROM play_history',
    );
    return {
      'totalPlays': total.first['c'] ?? 0,
      'uniqueTracks': unique.first['c'] ?? 0,
    };
  }

  /// 软限制：超出 maxRows 则删除最旧的
  Future<void> _enforceLimit(int maxRows) async {
    final db = await _db.database;
    final count = await db.rawQuery('SELECT COUNT(*) as c FROM play_history');
    final total = count.first['c'] as int? ?? 0;
    if (total > maxRows) {
      await db.rawQuery('''
        DELETE FROM play_history WHERE id IN (
          SELECT id FROM play_history ORDER BY played_at ASC LIMIT ?
        )
      ''', [total - maxRows]);
      AppLogger.info('PlayHistoryDao', '清理 ${total - maxRows} 条旧历史');
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend_flutter/lib/data/database/play_history_dao.dart
git commit -m "feat: 新建 PlayHistoryDao — 分页查询、去重、统计、2000条软限制"
```

---

### Task 6: 重构 PlayHistoryRepository — 注入 DAO，加 Stream

**文件：**
- 修改：`data/repositories/history_repository.dart`

**产出：** Repository 通过 DAO 操作，内部持 StreamController 通知变更

- [ ] **Step 1: 重写 history_repository.dart**

```dart
// data/repositories/history_repository.dart
import 'dart:async';
import '../../core/utils/app_logger.dart';
import '../../models/play_history.dart';
import '../../models/audio.dart';
import '../database/app_database.dart';
import '../database/play_history_dao.dart';

class PlayHistoryRepository {
  final PlayHistoryDao _dao;
  final StreamController<List<PlayHistory>> _controller =
      StreamController<List<PlayHistory>>.broadcast();

  PlayHistoryRepository({AppDatabase? db, PlayHistoryDao? dao})
      : _dao = dao ?? PlayHistoryDao(db ?? AppDatabase.instance);

  /// 监听历史变更的 Stream
  Stream<List<PlayHistory>> watchHistory() => _controller.stream;

  /// 分页获取历史
  Future<List<PlayHistory>> getPlayHistory({int page = 1, int pageSize = 50}) async {
    try {
      final maps = await _dao.getHistory(page: page, pageSize: pageSize);
      final history = maps.map(_parseRow).toList();
      AppLogger.debug('PlayHistoryRepository', '加载历史: page=$page, ${history.length}条');
      return history;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '获取历史失败: $e');
      return [];
    }
  }

  /// 记录播放
  Future<void> recordPlay({
    required String bvid,
    int? cid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? progress,
    String? sourceType,
    String? sourceId,
  }) async {
    try {
      await _dao.upsert({
        'source_id': bvid,
        'title': title ?? bvid,
        'artist': artist ?? '',
        'cover_url': coverUrl ?? '',
        'duration': duration ?? 0,
        'position': progress ?? 0,
        if (sourceType != null) 'source_type': sourceType,
        if (sourceId != null) 'source_id': sourceId,
      });
      _notifyChange();
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '记录播放失败: $e');
    }
  }

  /// 删除单条
  Future<void> deleteById(int id) async {
    await _dao.deleteById(id);
    _notifyChange();
  }

  /// 批量删除
  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    await _dao.deleteByIds(ids);
    _notifyChange();
  }

  /// 清空
  Future<void> clearAll() async {
    await _dao.clearAll();
    _notifyChange();
  }

  /// 获取收藏曲目 ID 集合
  Future<Set<String>> getFavoriteTrackIds() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tracks',
      where: 'is_favorite = ?', whereArgs: [1],
      columns: ['source_id'],
    );
    return rows.map((r) => r['source_id'] as String).toSet();
  }

  // --- private ---

  PlayHistory _parseRow(Map<String, dynamic> map) {
    final sourceId = map['source_id'] as String? ?? '';
    return PlayHistory(
      id: map['id']?.toString() ?? '',
      userId: '',
      audio: Audio(
        id: sourceId,
        title: map['title'] as String? ?? '',
        artist: map['artist'] as String?,
        duration: map['duration'] as int?,
        coverUrl: map['cover_url'] as String?,
      ),
      playedAt: DateTime.tryParse(map['played_at'] as String? ?? '') ?? DateTime.now(),
      progress: map['position'] as int? ?? 0,
      source: _parseSource(map['source_type'] as String?, map['source_id'] as String?),
    );
  }

  PlaySource? _parseSource(String? type, String? id) {
    if (type == null) return null;
    switch (type) {
      case 'playlist': return PlaySource.playlist(id ?? '');
      case 'search':  return PlaySource.search(id ?? '');
      case 'history': return const PlaySource.history();
      case 'manual':  return const PlaySource.manual();
      default:        return null;
    }
  }

  Future<void> _notifyChange() async {
    final history = await getPlayHistory(pageSize: 50);
    if (!_controller.isClosed) _controller.add(history);
  }

  void dispose() {
    _controller.close();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend_flutter/lib/data/repositories/history_repository.dart
git commit -m "refactor: PlayHistoryRepository 注入 DAO，加 Stream 通知，加 recordPlay 支持 sourceType"
```

---

### Task 7: 重构 PlaylistRepository — 删 saveNowPlaying，加 getFavoriteTrackIds

**文件：**
- 修改：`data/repositories/playlist_repository.dart`

**产出：** 清理死代码，加收藏 ID 查询方法

- [ ] **Step 1: 删除 saveNowPlaying 方法**

删除 `playlist_repository.dart` 第 253-257 行的 `saveNowPlaying` 方法。

- [ ] **Step 2: 添加 getFavoriteTrackIds 方法**

```dart
/// 获取收藏曲目 ID 集合（用于快速查找）
Future<Set<String>> getFavoriteTrackIds() async {
  try {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'tracks',
      where: 'is_favorite = ?',
      whereArgs: [1],
      columns: ['source_id'],
    );
    return rows.map((r) => r['source_id'] as String).toSet();
  } catch (e) {
    AppLogger.error('PlaylistRepository', '获取收藏ID失败: $e');
    return {};
  }
}
```

- [ ] **Step 3: 添加 generatePlaylistCover 桩方法（P2 实现）**

```dart
/// 生成歌单封面（2x2 拼图）
Future<String?> generatePlaylistCover(String playlistId) async {
  // P2 阶段实现
  return null;
}
```

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/data/repositories/playlist_repository.dart
git commit -m "refactor: PlaylistRepository 删 saveNowPlaying，加 getFavoriteTrackIds + 封面生成桩"
```

---

### Task 8: 更新 repository_providers.dart

**文件：**
- 修改：`data/repositories/repository_providers.dart`

**产出：** 新增 PlayHistoryDao、PlayHistoryRepository 的 Provider

- [ ] **Step 1: 添加 import 和 Provider**

```dart
import '../database/play_history_dao.dart';
import 'history_repository.dart';

/// PlayHistoryDao Provider
final playHistoryDaoProvider = Provider<PlayHistoryDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlayHistoryDao(db);
});

/// PlayHistoryRepository Provider
final playHistoryRepositoryProvider = Provider<PlayHistoryRepository>((ref) {
  final repository = PlayHistoryRepository(
    dao: ref.watch(playHistoryDaoProvider),
  );
  ref.onDispose(() => repository.dispose());
  return repository;
});
```

- [ ] **Step 2: Commit**

```bash
git add frontend_flutter/lib/data/repositories/repository_providers.dart
git commit -m "feat: 注册 PlayHistoryDao + PlayHistoryRepository Provider"
```

---

### Task 9: 重构 QueueViewModel — 使用 PlayQueue 模型

**文件：**
- 修改：`presentation/viewmodels/player/queue_viewmodel.dart`

**产出：** QueueState 简化为单字段 + PlayQueue，持久化简化为单 key

- [ ] **Step 1: 重写 QueueState freezed**

```dart
@freezed
abstract class QueueState with _$QueueState {
  const factory QueueState({
    PlayQueue? queue,
    @Default([]) List<LocalAudio> localAudios,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _QueueState;
}
```

删除 `queue`/`currentIndex`/`playMode`/`source` 四个独立字段，统一到 `PlayQueue? queue`。

- [ ] **Step 2: 简化持久化方法**

`_saveToStorage()` 改为：

```dart
Future<void> _saveToStorage() async {
  if (state.queue == null) return;
  final json = jsonEncode(state.queue!.toJson());
  await _storage!.setString(StorageKeys.unifiedPlaylist, json);
}
```

`_loadFromStorage()` 改为：

```dart
Future<void> _loadFromStorage() async {
  final json = _storage!.getString(StorageKeys.unifiedPlaylist);
  if (json == null) return;
  try {
    final queue = PlayQueue.fromJson(jsonDecode(json));
    state = state.copyWith(queue: queue);
  } catch (e) {
    AppLogger.error('QueueViewModel', '恢复队列失败: $e');
  }
}
```

- [ ] **Step 3: 更新所有队列操作方法**

- `setQueue()` → 创建 `PlayQueue(tracks: queue, currentIndex: initialIndex)` 赋值
- `setCurrentIndex()` → `state.queue?.copyWith(currentIndex: index)` 
- `togglePlayMode()` → `state.queue?.copyWith(playMode: newMode)`
- `add()` / `removeAt()` / `clear()` / `reorder()` → 操作 `state.queue!.tracks` 并重新赋值

- [ ] **Step 4: 删除 _syncNowPlayingToServer 和 _scheduleSyncToServer**

删除两个空/无用方法及其 Timer 字段。

- [ ] **Step 5: 运行 build_runner**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.freezed.dart frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.g.dart
git commit -m "refactor: QueueViewModel 改用 PlayQueue 模型，简化持久化"
```

---

### Task 10: 重构 PlaylistViewModel → PlaylistListNotifier

**文件：**
- 修改：`presentation/viewmodels/library/playlist_viewmodel.dart`

**产出：** 从管理 8 字段的 PlaylistState 变为只管理 `List<Playlist>` 的列表 Provider

- [ ] **Step 1: 更换类名和状态类型**

```dart
// 改前
@Riverpod(keepAlive: true)
class PlaylistViewModel extends _$PlaylistViewModel {
  @override
  Future<PlaylistState> build() async { ... }

// 改后
@Riverpod(keepAlive: true)
class PlaylistListNotifier extends _$PlaylistListNotifier {
  @override
  Future<List<Playlist>> build() async {
    return _repository.getUserPlaylists();
  }
```

用 Riverpod 内置的 `AsyncValue<List<Playlist>>` 替代 `AsyncValue<PlaylistState>`。

- [ ] **Step 2: 删除收藏相关代码**

删除：
- `_favoritedBvids` 字段和 `isFavorited()` 方法
- `toggleFavorite()` 方法（整个 ~150 行）
- `loadFavorites()` / `_loadFavoritesFromLocal()` / `_saveFavoritesToLocal()` / `_updateFavoritedCache()`
- `favoritesItems` / `favoritesPlaylist` 相关字段操作

- [ ] **Step 3: 删除 nowPlaying 相关代码**

删除：
- `loadNowPlaying()` 方法
- `saveNowPlayingQueue()` / `saveNowPlayingQueueFromItems()` 方法
- `nowPlayingPlaylist` / `nowPlayingItems` 字段

- [ ] **Step 4: 保留并简化歌单列表操作**

保留：`createPlaylist()`、`updatePlaylist()`、`deletePlaylist()`、`clear()`
简化：每个方法只操作 `List<Playlist>`，不需要 copyWith 8 个字段。

示例 — `createPlaylist` 改写后：

```dart
Future<Playlist?> createPlaylist({required String name, ...}) async {
  final newPlaylist = await _repository.createPlaylist(name: name, ...);
  if (newPlaylist != null && state.valueOrNull != null) {
    state = AsyncData([...state.valueOrNull!, newPlaylist]);
  }
  return newPlaylist;
}
```

- [ ] **Step 5: 删除 PlaylistState / PlaylistStateX 定义**

删除整个 `PlaylistState` freezed 定义和 `PlaylistStateX` extension（约 100 行）。

- [ ] **Step 6: 运行 build_runner**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/library/playlist_viewmodel.dart frontend_flutter/lib/presentation/viewmodels/library/playlist_viewmodel.freezed.dart frontend_flutter/lib/presentation/viewmodels/library/playlist_viewmodel.g.dart
git commit -m "refactor: PlaylistViewModel -> PlaylistListNotifier，管理纯列表"
```

---

### Task 11: 新建 FavoriteTracksNotifier

**文件：**
- 新建：`presentation/viewmodels/library/favorite_tracks_notifier.dart`

**产出：** 独立的收藏状态 Provider，返回 `Set<String>`

- [ ] **Step 1: 编写 FavoriteTracksNotifier**

```dart
// presentation/viewmodels/library/favorite_tracks_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../data/repositories/repository_providers.dart';

part 'favorite_tracks_notifier.g.dart';

@Riverpod(keepAlive: true)
class FavoriteTracksNotifier extends _$FavoriteTracksNotifier {
  @override
  Future<Set<String>> build() async {
    final repo = ref.watch(playlistRepositoryProvider);
    return repo.getFavoriteTrackIds();
  }

  /// 切换收藏状态，返回操作后的状态
  Future<bool> toggle(
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    String? localPath,
  }) async {
    final repo = ref.watch(playlistRepositoryProvider);
    final trackRepo = ref.watch(trackRepositoryProvider);

    final isFav = state.valueOrNull?.contains(bvid) ?? false;
    final target = !isFav;

    // 切换 tracks.is_favorite
    final track = await ref.read(trackDaoProvider).getBySourceId(bvid);
    if (track != null) {
      await trackRepo.toggleFavorite(track.id, target,
        title: title ?? track.title, artist: artist ?? track.artist,
        duration: duration ?? track.duration, coverUrl: coverUrl ?? track.coverUrl,
      );
    }

    // 乐观更新内存状态
    final current = Set<String>.from(state.valueOrNull ?? {});
    if (target) {
      current.add(bvid);
    } else {
      current.remove(bvid);
    }
    state = AsyncData(current);

    AppLogger.info('FavoriteTracksNotifier', '收藏切换: $bvid -> $target');
    return target;
  }

  bool isFavorited(String bvid) =>
      state.valueOrNull?.contains(bvid) ?? false;
}
```

- [ ] **Step 2: 运行 build_runner**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/library/favorite_tracks_notifier.dart frontend_flutter/lib/presentation/viewmodels/library/favorite_tracks_notifier.g.dart
git commit -m "feat: 新建 FavoriteTracksNotifier — 独立收藏状态管理"
```

---

### Task 12: 重构 PlaylistDetailViewModel — 改名 + 删手动 invalidate

**文件：**
- 修改：`presentation/viewmodels/library/playlist_detail_viewmodel.dart`

**产出：** 代码不变，删除 `ref.invalidate(playlistViewModelProvider)` 调用（共 4 处）

- [ ] **Step 1: 删除所有 ref.invalidate(playlistViewModelProvider)**

在文件中搜索并删除这 4 行：
```dart
ref.invalidate(playlistViewModelProvider);
```

分别在 `removeItem`（约第 244 行）、`updatePlaylist`（约第 578 行）、`deletePlaylist`（约第 604 行）、`batchRemoveItems`（约第 733 行）。

- [ ] **Step 2: 将 import playlist_viewmodel.dart 改为 import 新的 Provider**

将 `import 'playlist_viewmodel.dart';` 改为 `import 'playlist_viewmodel.dart' show PlaylistListNotifier;`，或者直接删除（因为已经不再需要类型引用）。

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart
git commit -m "refactor: PlaylistDetailViewModel 删除手动 invalidate"
```

---

### Task 13: 重构 HistoryViewModel — 删 JSON 缓存，用 Stream

**文件：**
- 修改：`presentation/viewmodels/library/history_viewmodel.dart`

**产出：** 不再使用 SharedStorageService，直接在 build() 中从 SQLite 加载，监听 Stream

- [ ] **Step 1: 删除 SharedStorageService 相关代码**

- 删除 `_storage` 字段
- 删除 `_loadHistoryFromLocal()` 方法
- 删除 `_saveHistoryToLocal()` 方法
- 删除 SharedStorageService import
- 删除所有 `await _storage!.setString/remove` 调用

- [ ] **Step 2: 重写 build() 从 DAO 加载首屏**

```dart
@override
Future<HistoryState> build() async {
  _repository = ref.watch(historyRepositoryProvider);

  // 从 SQLite 加载首屏数据
  final history = await _repository!.getPlayHistory(pageSize: 50);

  // 订阅 Stream 做增量更新
  _repository!.watchHistory().listen((updated) {
    if (ref.mounted) {
      state = AsyncData(HistoryState.loaded(history: updated));
    }
  });

  return HistoryState.loaded(history: history);
}
```

- [ ] **Step 3: 更新 recordPlay — 支持 sourceType/sourceId**

```dart
Future<void> recordPlay({
  ...
  String? sourceType,  // 新增
  String? sourceId,    // 新增
}) async {
  await _repository!.recordPlay(
    bvid: identifier,
    title: title,
    artist: artist,
    duration: duration,
    coverUrl: coverUrl,
    progress: progress,
    sourceType: sourceType,
    sourceId: sourceId,
  );
}
```

- [ ] **Step 4: 删除乐观更新的 100 条硬限制**

在 `recordPlay` 中删除 `if (updatedHistory.length > 100) { ... }`。

- [ ] **Step 5: 运行 build_runner**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/library/history_viewmodel.dart frontend_flutter/lib/presentation/viewmodels/library/history_viewmodel.freezed.dart frontend_flutter/lib/presentation/viewmodels/library/history_viewmodel.g.dart
git commit -m "refactor: HistoryViewModel 删 JSON 缓存，用 SQLite + Stream"
```

---

### Task 14: 更新 PlaybackViewModel — 传 sourceType 给历史

**文件：**
- 修改：`presentation/viewmodels/player/playback_viewmodel.dart`

**产出：** recordPlay 调用时传入 `sourceType: 'manual'`

- [ ] **Step 1: 更新 recordPlay 调用**

找到约第 566 行的 `ref.read(historyViewModelProvider.notifier).recordPlay(...)`：

```dart
ref.read(historyViewModelProvider.notifier).recordPlay(
  bvid: playable.original.id,
  title: playable.title,
  artist: playable.artist,
  duration: playable.duration,
  coverUrl: playable.coverUrl,
  sourceType: 'manual',   // ← 新增
);
```

- [ ] **Step 2: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart
git commit -m "feat: PlaybackViewModel 记录播放时传入 sourceType"
```

---

### Task 15: 更新 providers.dart — 导出新 Provider

**文件：**
- 修改：`presentation/providers.dart`

**产出：** 导出新 Provider，删除旧 PlaylistState/HistoryState 导出（替换为新的）

- [ ] **Step 1: 更新导出**

```dart
// 替换旧导出
export 'viewmodels/library/playlist_viewmodel.dart'
    show playlistListNotifierProvider;  // 改名
export 'viewmodels/library/favorite_tracks_notifier.dart'
    show favoriteTracksNotifierProvider;
export 'viewmodels/library/playlist_detail_viewmodel.dart'
    show playlistDetailViewModelProvider, PlaylistDetailState;
export 'viewmodels/library/history_viewmodel.dart'
    show historyViewModelProvider;
```

- [ ] **Step 2: 删除旧 PlaylistState 导出**

删除 `show PlaylistState` 和 `show sharedStorageServiceProvider`（如果不再需要）。

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/providers.dart
git commit -m "refactor: 更新 providers.dart 导出为新 Provider"
```

---

### Task 16: 适配 UI 文件 — player_action_bar.dart

**文件：**
- 修改：`presentation/widgets/player_action_bar.dart`

**产出：** 收藏按钮改用 `favoriteTracksNotifierProvider`

- [ ] **Step 1: 替换收藏状态查询**

```dart
// 改前
final playlistAsync = ref.watch(playlistViewModelProvider);
final isFavorited = playlistAsync.when(
  data: (playlistState) {
    if (playlistState is PlaylistStateLoaded) { ... }
  },
  ...
);

// 改后
final favoriteTracksAsync = ref.watch(favoriteTracksNotifierProvider);
final isFavorited = favoriteTracksAsync.whenOrNull(
  data: (ids) => ids.contains(currentId),
) ?? false;
```

- [ ] **Step 2: 替换收藏切换调用**

```dart
// 改前
ref.read(playlistViewModelProvider.notifier).toggleFavorite(...)

// 改后
ref.read(favoriteTracksNotifierProvider.notifier).toggle(...)
```

- [ ] **Step 3: 验证编译**

```bash
cd frontend_flutter && flutter analyze lib/presentation/widgets/player_action_bar.dart
```

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/presentation/widgets/player_action_bar.dart
git commit -m "refactor: player_action_bar 改用 FavoriteTracksNotifier"
```

---

### Task 17: 适配 UI 文件 — audio_action_menu.dart 和 queue_item_tile.dart

**文件：**
- 修改：`presentation/widgets/audio/audio_action_menu.dart`
- 修改：`presentation/widgets/player/queue_item_tile.dart`

**产出：** 所有 `playlistViewModelProvider` 引用替换为对应新 Provider

- [ ] **Step 1: audio_action_menu.dart — 收藏切换**

```dart
// 改前: ref.read(playlistViewModelProvider.notifier).toggleFavorite(...)
// 改后: ref.read(favoriteTracksNotifierProvider.notifier).toggle(...)

// 改前: ref.read(playlistViewModelProvider.notifier).isFavorited(bvid)
// 改后: ref.read(favoriteTracksNotifierProvider.notifier).isFavorited(bvid)
```

替换文件中约 5 处对 `playlistViewModelProvider` 的引用。收藏相关改用 `favoriteTracksNotifierProvider`，添加到歌单改用 `playlistListNotifierProvider`。

- [ ] **Step 2: queue_item_tile.dart — 收藏切换**

```dart
// 改前: final playlistNotifier = ref.read(playlistViewModelProvider.notifier);
// 改后: final favNotifier = ref.read(favoriteTracksNotifierProvider.notifier);
```

替换约 2 处。

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/widgets/audio/audio_action_menu.dart frontend_flutter/lib/presentation/widgets/player/queue_item_tile.dart
git commit -m "refactor: audio_action_menu + queue_item_tile 改用新 Provider"
```

---

### Task 18: 适配 UI 文件 — 播放历史相关页面

**文件：**
- 修改：`presentation/widgets/player/history_tab_view.dart`
- 修改：`presentation/views/library/play_history_page.dart`

**产出：** 调整为新的 HistoryViewModel 接口

- [ ] **Step 1: history_tab_view.dart**

```dart
// 替换 ref.watch(historyViewModelProvider) → 不变（Provider 名不变）
// 替换 ref.read(historyViewModelProvider.notifier).removeHistoryItem(id)
//    → ref.read(historyViewModelProvider.notifier).removeHistoryById(id)
// replace ref.read(historyViewModelProvider.notifier).clearHistory()
//    → ref.read(historyViewModelProvider.notifier).clearHistory()
```

适配新方法名：`removeHistoryItem` → `removeHistoryById`（ID-based）。

- [ ] **Step 2: play_history_page.dart**

删除 `initState` 中的 `ref.read(historyViewModelProvider.notifier).loadHistory()` 调用（因为 build() 中已自动加载）。

适配删除和清空方法：保持一致。

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/widgets/player/history_tab_view.dart frontend_flutter/lib/presentation/views/library/play_history_page.dart
git commit -m "refactor: 播放历史 UI 适配新 HistoryViewModel"
```

---

### Task 19: 适配 UI 文件 — playlist_library_page.dart 和 playlist_detail_page.dart

**文件：**
- 修改：`presentation/views/library/playlist_library_page.dart`
- 修改：`presentation/views/library/playlist_detail_page.dart`
- 修改：`presentation/views/library/local_music_playlist_page.dart`

**产出：** 适配新的 PlaylistListNotifier Provider

- [ ] **Step 1: playlist_library_page.dart**

```dart
// 改前: final playlistAsync = ref.watch(playlistViewModelProvider);
// 改后: final playlistAsync = ref.watch(playlistListNotifierProvider);

// 改前: .when(data: (state) => _buildContent(context, ref, state), ...)
// 改后: .when(data: (playlists) => _buildContent(context, ref, playlists), ...)
```

删除 `_buildContent` 中对 `PlaylistState` 的 pattern match（`.playlists` / `.userPlaylists` 等扩展方法的调用）。直接用 `List<Playlist>`。

- [ ] **Step 2: playlist_detail_page.dart**

```dart
// 改前: ref.read(playlistViewModelProvider.notifier)
// 改后: 如果是收藏切换 → ref.read(favoriteTracksNotifierProvider.notifier)
```

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/views/library/playlist_library_page.dart frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart frontend_flutter/lib/presentation/views/library/local_music_playlist_page.dart
git commit -m "refactor: 歌单页面适配 PlaylistListNotifier"
```

---

### Task 20: 适配 UI 文件 — home_page.dart 和 my_drawer.dart

**文件：**
- 修改：`presentation/views/player/home_page.dart`
- 修改：`presentation/widgets/my_drawer.dart`

**产出：** 如有 playlistViewModelProvider 引用则更新

- [ ] **Step 1: 搜索并替换**

搜索 `home_page.dart` 和 `my_drawer.dart` 中对 `playlistViewModelProvider` 的引用。

如果是收藏相关 → 改为 `favoriteTracksNotifierProvider`。
如果是歌单列表 → 改为 `playlistListNotifierProvider`。

- [ ] **Step 2: Commit**

```bash
git add frontend_flutter/lib/presentation/views/player/home_page.dart frontend_flutter/lib/presentation/widgets/my_drawer.dart
git commit -m "refactor: home_page + my_drawer 适配新 Provider"
```

---

### Task 21: Undo 删除 — 历史记录

**文件：**
- 修改：`presentation/viewmodels/library/history_viewmodel.dart`

**产出：** 删除操作延迟 3 秒持久化 + SnackBar 撤销

- [ ] **Step 1: 添加 undo 相关字段**

```dart
bool _undone = false;
List<PlayHistory>? _removedItems;
```

- [ ] **Step 2: 重写 removeHistoryById**

```dart
Future<void> removeHistoryById(String id) async {
  final current = state.valueOrNull?.maybeWhen(
    loaded: (h, _) => h, orElse: () => <PlayHistory>[],
  ) ?? [];

  final removed = current.where((item) => item.id == id).toList();
  if (removed.isEmpty) return;

  final updated = current.where((item) => item.id != id).toList();
  state = AsyncData(HistoryState.loaded(history: updated));

  _undone = false;
  _removedItems = removed;

  await Future.delayed(const Duration(seconds: 3));
  if (!_undone) {
    await _repository!.deleteById(int.tryParse(id) ?? 0);
  }
}

void undoRemove() {
  if (_removedItems == null) return;
  _undone = true;
  final current = state.valueOrNull?.maybeWhen(
    loaded: (h, _) => h, orElse: () => <PlayHistory>[],
  ) ?? [];
  final restored = [..._removedItems!, ...current]
    ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  state = AsyncData(HistoryState.loaded(history: restored));
  _removedItems = null;
}
```

- [ ] **Step 3: UI 层加 SnackBar（history_tab_view.dart 或 play_history_page.dart）**

```dart
// 删除时
ref.read(historyViewModelProvider.notifier).removeHistoryById(item.id);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('已移除 1 首歌曲'),
    action: SnackBarAction(
      label: '撤销',
      onPressed: () {
        ref.read(historyViewModelProvider.notifier).undoRemove();
      },
    ),
  ),
);
```

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/library/history_viewmodel.dart frontend_flutter/lib/presentation/views/library/play_history_page.dart
git commit -m "feat: 播放历史删除支持 Undo（3s延迟 + SnackBar撤销）"
```

---

### Task 22: Undo 删除 — 歌单项

**文件：**
- 修改：`presentation/viewmodels/library/playlist_detail_viewmodel.dart`

**产出：** `removeItem` 方法同样支持延迟持久化

- [ ] **Step 1: 在 PlaylistDetailViewModel 中实现相同的 undo 模式**

参照 Task 21 的实现，给 `removeItem` 方法加 `_undone` / undo 逻辑。

- [ ] **Step 2: 在 playlist_detail_page.dart 中加 SnackBar**

参照 Task 21 Step 3。

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart
git commit -m "feat: 歌单项删除支持 Undo"
```

---

### Task 23: 歌单封面自动生成

**文件：**
- 修改：`data/repositories/playlist_repository.dart`
- 修改：`presentation/viewmodels/library/playlist_viewmodel.dart`

**产出：** 创建歌单时自动生成 2x2 拼图封面

- [ ] **Step 1: 实现 PlaylistRepository.generatePlaylistCover**

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> generatePlaylistCover(String playlistId) async {
  try {
    final items = await getPlaylistItems(playlistId);
    if (items.length < 2) return null; // 至少 2 首才拼图

    final coverUrls = items.take(4).map((i) => i.coverUrl).where((u) =>
        u != null && u.isNotEmpty).toList();
    if (coverUrls.isEmpty) return null;

    // 下载封面图片 → Canvas 拼 2x2 → 保存为 PNG
    final images = <ui.Image>[];
    for (final url in coverUrls) {
      try {
        final bytes = await _downloadImage(url);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        images.add(frame.image);
      } catch (_) {}
    }
    if (images.length < 2) return null;

    const tileSize = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final gridSize = images.length <= 2 ? 2 : 2;
    for (var i = 0; i < images.length; i++) {
      final x = (i % gridSize) * tileSize;
      final y = (i ~/ gridSize) * tileSize;
      canvas.drawImageRect(
        images[i],
        Rect.fromLTWH(0, 0, images[i].width.toDouble(), images[i].height.toDouble()),
        Rect.fromLTWH(x, y, tileSize, tileSize),
        Paint(),
      );
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (tileSize * gridSize).toInt(), (tileSize * gridSize).toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final coverPath = '${dir.path}/playlist_covers/$playlistId.png';
    await Directory('${dir.path}/playlist_covers').create(recursive: true);
    await File(coverPath).writeAsBytes(pngBytes);

    return coverPath;
  } catch (e) {
    AppLogger.error('PlaylistRepository', '生成封面失败: $e');
    return null;
  }
}

Future<Uint8List> _downloadImage(String url) async {
  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes = await consolidateHttpClientResponseBytes(response);
    return bytes;
  } finally {
    httpClient.close();
  }
}
```

- [ ] **Step 2: createPlaylist 中调用封面生成**

```dart
Future<Playlist?> createPlaylist({required String name, ...}) async {
  final newPlaylist = await _repository.createPlaylist(name: name, ...);
  if (newPlaylist != null) {
    _repository.generatePlaylistCover(newPlaylist.id).then((coverPath) {
      if (coverPath != null) {
        _repository.updatePlaylist(id: newPlaylist.id, coverUrl: coverPath);
      }
    });
  }
  return newPlaylist;
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/data/repositories/playlist_repository.dart frontend_flutter/lib/presentation/viewmodels/library/playlist_viewmodel.dart
git commit -m "feat: 歌单封面自动生成 — 前4首封面拼2x2网格"
```

---

### Task 24: 歌单内排序和历史分页 UI

**文件：**
- 修改：`presentation/viewmodels/library/playlist_detail_viewmodel.dart`
- 修改：`presentation/views/library/play_history_page.dart`

**产出：** 歌单拖拽排序 + 历史分页加载

- [ ] **Step 1: PlaylistDetailViewModel 加 reorderItems 和 sortItems**

```dart
/// 拖拽重排
Future<void> reorderItems(int oldIndex, int newIndex) async {
  final current = state.valueOrNull?.maybeWhen(
    loaded: (_, items, __) => items, orElse: () => null,
  );
  if (current == null) return;

  final reordered = List<PlaylistItem>.from(current);
  final item = reordered.removeAt(oldIndex);
  reordered.insert(newIndex, item);

  // 乐观更新
  _updateItems(reordered);

  // 持久化
  final playlistId = ...;
  final dao = PlaylistDao(AppDatabase.instance);
  final db = await AppDatabase.instance.database;
  await db.transaction((txn) async {
    for (var i = 0; i < reordered.length; i++) {
      if (reordered[i].id != null) {
        await txn.update('playlist_items', {'position': i},
          where: 'id = ?', whereArgs: [int.tryParse(reordered[i].id!)]);
      }
    }
  });
}

/// 自动排序
Future<void> sortItems(SortField field) async {
  final current = ...;
  List<PlaylistItem> sorted;
  switch (field) {
    case SortField.title:
      sorted = List.from(current)..sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
    case SortField.artist:
      sorted = List.from(current)..sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
    case SortField.duration:
      sorted = List.from(current)..sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
    case SortField.addedAt:
      sorted = List.from(current)..sort((a, b) => (b.addedAt ?? DateTime(0)).compareTo(a.addedAt ?? DateTime(0)));
  }
  _updateItems(sorted);
  await _persistReorder(sorted);
}

enum SortField { title, artist, duration, addedAt }
```

- [ ] **Step 2: 播放历史分页 UI**

```dart
// play_history_page.dart — ScrollController
final _scrollController = ScrollController();
bool _isLoadingMore = false;

_scrollController.addListener(() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
    _loadMore();
  }
});

Future<void> _loadMore() async {
  _isLoadingMore = true;
  await ref.read(historyViewModelProvider.notifier).loadMoreHistory();
  _isLoadingMore = false;
}
```

- [ ] **Step 3: HistoryViewModel 加 loadMoreHistory 方法**

```dart
int _currentPage = 1;

Future<void> loadMoreHistory() async {
  _currentPage++;
  final more = await _repository!.getPlayHistory(page: _currentPage, pageSize: 50);
  final current = state.valueOrNull?.maybeWhen(
    loaded: (h, _) => h, orElse: () => <PlayHistory>[],
  ) ?? [];
  state = AsyncData(HistoryState.loaded(history: [...current, ...more]));
}
```

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart frontend_flutter/lib/presentation/viewmodels/library/history_viewmodel.dart frontend_flutter/lib/presentation/views/library/play_history_page.dart
git commit -m "feat: 歌单拖拽排序 + 历史分页加载"
```

---

### Task 25: 运行代码生成 + 静态分析

**文件：** 无

**产出：** 所有 .freezed.dart / .g.dart 文件重新生成，无编译错误

- [ ] **Step 1: 清理并重新生成**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: 静态分析**

```bash
cd frontend_flutter && flutter analyze
```

预期：0 issues。

- [ ] **Step 3: 如果有问题，修复后重新 commit**

```bash
git add -A
git commit -m "chore: 重新生成 freezed/g 文件，修复静态分析错误"
```

---

### Task 26: 最终验证

**文件：** 无

**产出：** 确认所有改动正常工作

- [ ] **Step 1: 验证数据库迁移**

启动 App，确认 v12→v13 迁移成功（检查 logcat / 日志文件）。

- [ ] **Step 2: 验证队列持久化**

添加歌曲到队列 → 关闭 App → 重新打开 → 确认队列恢复（以新 PlayQueue JSON 格式）。

- [ ] **Step 3: 验证收藏功能**

收藏/取消收藏 → 切换到详情页 → 确认一致性。

- [ ] **Step 4: 验证播放历史**

播放歌曲 → 查看历史页面 → 删除 → 撤销 → 确认 Undo 生效。

- [ ] **Step 5: 验证歌单操作**

创建歌单 → 添加歌曲 → 拖拽排序 → 确认持久化。

- [ ] **Step 6: Commit**

```bash
git commit -m "verify: 端到端验证通过" --allow-empty
```

---

## 完成标准

1. `flutter analyze` 0 issues
2. `SystemPlaylistType.nowPlaying` 不存在于代码中
3. QueueViewModel 使用 PlayQueue 模型，不依赖 PlaylistViewModel
4. PlaylistListNotifier 只返回 `List<Playlist>`
5. FavoriteTracksNotifier 独立管理 `Set<String>`
6. HistoryViewModel 无 SharedStorageService / JSON 缓存
7. HistoryRepository 暴露 Stream
8. PlayHistory 记录包含 source 信息
9. 删除操作有 SnackBar + 撤销按钮
10. 新建歌单自动生成封面
11. 歌单内可拖拽排序
12. 播放历史分页加载，无 100 条限制
