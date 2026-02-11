# 修复搜索页面下载状态图标显示问题

## 问题描述

搜索页面右侧的下载状态图标所有内容都显示为灰色（未下载状态），即使内容正在下载或已下载。只有点击"更多操作"菜单后才能看到真实的下载状态。

---

## 表结构本质区别分析

### `tracks` 表 vs `download_tasks` 表

| 维度 | `tracks` 表 | `download_tasks` 表 |
|------|-------------|---------------------|
| **本质职责** | 音频实体 + 文件存在性 | 下载任务生命周期 |
| **生命周期** | 永久（用户数据） | 临时（可清空） |
| **唯一标识** | `source_id` (BVID/filepath) | `id` + `bvid` |
| **状态语义** | "文件是否存在" (`is_downloaded`) | "任务处于什么阶段" (`status`) |
| **清除影响** | 丢失用户数据 | 仅清空任务记录，文件保留 |

### 当前问题

```
┌─────────────────────────────────────────────────────────────┐
│                      状态冗余问题                            │
├─────────────────────────────────────────────────────────────┤
│  tracks:                                                     │
│    - download_status ← 冗余（与 download_tasks.status 重复） │
│    - download_progress ← 冗余                                │
│    - is_downloaded ← 必需（文件存在性）                       │
│    - local_path ← 必需（文件位置）                           │
│                                                              │
│  download_tasks:                                             │
│    - status ← 真实来源                                       │
│    - track_id ← 可为 null！（搜索结果下载时无关联）            │
└─────────────────────────────────────────────────────────────┘
```

**问题根源：**

1. `download_tasks.track_id` 可为 null → 搜索结果下载时无 Track 关联
2. `DownloadStatusIndicator` 只查 `tracks` 表 → 找不到记录显示灰色
3. 状态冗余导致同步复杂，容易出现不一致

---

## 推荐方案：消除冗余 + 强制关联

### 设计原则

1. **单一数据源**：下载状态只存在 `download_tasks.status`
2. **强制关联**：`download_tasks.track_id` 始终非空
3. **文件存在性独立**：`tracks.is_downloaded` 仅表示文件物理存在

### 目标表结构

```sql
-- tracks 表：去除冗余的下载状态字段
CREATE TABLE tracks (
  id INTEGER PRIMARY KEY,
  source_id TEXT NOT NULL UNIQUE,  -- BVID 或文件路径
  source_type TEXT NOT NULL,       -- 'bilibili' | 'local'
  title TEXT NOT NULL,
  artist TEXT,
  cover_url TEXT,
  local_path TEXT,                 -- 文件位置（非空 = 已下载）
  is_downloaded INTEGER DEFAULT 0, -- 文件存在性（唯一下载相关字段）
  is_favorite INTEGER DEFAULT 0,
  local_play_count INTEGER DEFAULT 0,
  ...
  -- 移除: download_status, download_progress
);

-- download_tasks 表：track_id 改为非空
CREATE TABLE download_tasks (
  id INTEGER PRIMARY KEY,
  track_id INTEGER NOT NULL,       -- 强制非空
  bvid TEXT NOT NULL,              -- 冗余但便于查询
  status TEXT NOT NULL DEFAULT 'pending',
  downloaded_bytes INTEGER DEFAULT 0,
  total_bytes INTEGER DEFAULT 0,
  ...
  FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
);
```

### 状态查询逻辑

```
┌─────────────────────────────────────────────────────────────┐
│              DownloadStatusIndicator 查询流程               │
├─────────────────────────────────────────────────────────────┤
│  1. 查询 tracks 表 (by bvid)                                 │
│     ├─ track != null && is_downloaded → 显示已下载 ✓        │
│     ├─ track != null && !is_downloaded → 进入步骤 2         │
│     └─ track == null → 显示未下载                            │
│                                                              │
│  2. 查询 download_tasks 表 (by track.id)                     │
│     ├─ task != null → 显示任务状态 (进度/暂停/失败)          │
│     └─ task == null → 显示未下载                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 实施步骤

### Phase 1: 数据库迁移 (V4 → V5)

**文件**: `frontend_flutter/lib/data/database/app_database.dart`

1. 版本号升级为 5
2. 为 `track_id IS NULL` 的任务创建对应 Track
3. 重建 `tracks` 表移除冗余字段（SQLite 不支持 DROP COLUMN）

```dart
Future<void> _upgradeToV5(Database db) async {
  AppLogger.info('AppDatabase', '升级到 V5：消除下载状态冗余');
  
  // 1. 为孤儿任务创建 Track
  final orphanTasks = await db.rawQuery(
    'SELECT * FROM download_tasks WHERE track_id IS NULL'
  );
  
  for (final task in orphanTasks) {
    final bvid = task['bvid'] as String?;
    if (bvid == null) continue;
    
    int trackId;
    final existing = await db.query(
      'tracks', where: 'source_id = ?', whereArgs: [bvid], limit: 1,
    );
    
    if (existing.isNotEmpty) {
      trackId = existing.first['id'] as int;
    } else {
      trackId = await db.insert('tracks', {
        'source_id': bvid,
        'source_type': 'bilibili',
        'title': task['title'] ?? bvid,
        'artist': task['artist'],
        'cover_url': task['cover_url'],
        'bvid': bvid,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    
    await db.update(
      'download_tasks',
      {'track_id': trackId},
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }
  
  // 2. 重建 tracks 表（移除 download_status, download_progress）
  // SQLite 不支持 DROP COLUMN，需要重建表
  await db.execute('''
    CREATE TABLE tracks_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source_id TEXT NOT NULL UNIQUE,
      source_type TEXT NOT NULL,
      title TEXT NOT NULL,
      artist TEXT,
      album TEXT,
      duration INTEGER,
      cover_url TEXT,
      cover_blob BLOB,
      bvid TEXT,
      uploader TEXT,
      uploader_mid TEXT,
      play_count INTEGER,
      local_path TEXT,
      is_downloaded INTEGER DEFAULT 0,
      is_favorite INTEGER DEFAULT 0,
      local_play_count INTEGER DEFAULT 0,
      last_played_at TEXT,
      position INTEGER,
      playlist_id TEXT,
      added_at TEXT,
      updated_at TEXT,
      created_at TEXT,
      synced_at TEXT
    )
  ''');
  
  // 复制数据（排除冗余字段）
  await db.execute('''
    INSERT INTO tracks_new 
    SELECT id, source_id, source_type, title, artist, album, duration,
           cover_url, cover_blob, bvid, uploader, uploader_mid, play_count,
           local_path, is_downloaded, is_favorite, local_play_count,
           last_played_at, position, playlist_id, added_at, updated_at,
           created_at, synced_at
    FROM tracks
  ''');
  
  // 删除旧表，重命名新表
  await db.execute('DROP TABLE tracks');
  await db.execute('ALTER TABLE tracks_new RENAME TO tracks');
  
  // 重建索引
  await db.execute('CREATE INDEX idx_tracks_source_id ON tracks(source_id)');
  await db.execute('CREATE INDEX idx_tracks_source_type ON tracks(source_type)');
  await db.execute('CREATE INDEX idx_tracks_is_downloaded ON tracks(is_downloaded)');
  await db.execute('CREATE INDEX idx_tracks_is_favorite ON tracks(is_favorite)');
  await db.execute('CREATE INDEX idx_tracks_playlist ON tracks(playlist_id, position)');
  
  AppLogger.info('AppDatabase', 'V5 迁移完成');
}
```

### Phase 2: 修改 DownloadRepository

**文件**: `frontend_flutter/lib/data/repositories/download_repository.dart`

核心变更：`addDownloadTask` 始终确保 Track 存在

```dart
Future<int> addDownloadTask({
  required String bvid,
  required String url,
  required String savePath,
  String? title,
  String? artist,
  String? coverUrl,
}) async {
  return await AppDatabase.instance.transaction<int>((txn) async {
    // 1. 确保 Track 存在（核心变更：始终创建）
    int trackId;
    final existingTrack = await txn.query(
      'tracks', where: 'source_id = ?', whereArgs: [bvid], limit: 1,
    );
    
    if (existingTrack.isNotEmpty) {
      trackId = existingTrack.first['id'] as int;
    } else {
      trackId = await txn.insert('tracks', {
        'source_id': bvid,
        'source_type': 'bilibili',
        'title': title ?? bvid,
        'artist': artist,
        'cover_url': coverUrl,
        'bvid': bvid,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      AppLogger.info('DownloadRepository', '为搜索结果创建 Track: $bvid -> $trackId');
    }
    
    // 2. 检查是否已有下载任务
    final existingTask = await txn.query(
      'download_tasks', where: 'track_id = ?', whereArgs: [trackId], limit: 1,
    );
    if (existingTask.isNotEmpty) {
      return existingTask.first['id'] as int;
    }
    
    // 3. 创建下载任务（track_id 始终非空）
    final now = DateTime.now().toIso8601String();
    final taskId = await txn.insert('download_tasks', {
      'track_id': trackId,
      'bvid': bvid,
      'url': url,
      'save_path': savePath,
      'title': title,
      'artist': artist,
      'cover_url': coverUrl,
      'status': DownloadStatus.pending.value,
      'downloaded_bytes': 0,
      'total_bytes': 0,
      'retry_count': 0,
      'user_paused': 0,
      'created_at': now,
      'updated_at': now,
    });
    
    AppLogger.info('DownloadRepository', '创建下载任务: $taskId, trackId: $trackId, bvid: $bvid');
    return taskId;
  });
}

/// 根据 Track ID 获取下载任务
Future<DownloadTask?> getTaskByTrackId(int trackId) async {
  final db = await AppDatabase.instance.database;
  final maps = await db.query(
    'download_tasks',
    where: 'track_id = ?',
    whereArgs: [trackId],
    limit: 1,
  );
  if (maps.isEmpty) return null;
  return DownloadTask.fromMap(maps.first);
}
```

### Phase 3: 添加 Provider

**文件**: `frontend_flutter/lib/data/repositories/repository_providers.dart`

```dart
/// 根据 Track ID 获取下载任务
///
/// 用于下载状态指示器查询任务状态
@riverpod
Future<DownloadTask?> downloadTaskByTrackId(Ref ref, int trackId) async {
  final repository = ref.watch(downloadRepositoryProvider);
  return await repository.getTaskByTrackId(trackId);
}
```

### Phase 4: 简化 DownloadStatusIndicator

**文件**: `frontend_flutter/lib/presentation/widgets/common/download_status_indicator.dart`

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final trackAsync = ref.watch(trackByBvidProvider(bvid));
  
  return trackAsync.when(
    data: (track) {
      // 1. 优先检查文件存在性
      if (track != null && track.isDownloaded) {
        return _buildDownloaded();
      }
      
      // 2. 通过 track_id 查询任务状态
      if (track != null) {
        return ref.watch(downloadTaskByTrackIdProvider(track.id)).when(
          data: (task) {
            if (task == null) return _buildNotDownloaded();
            return _buildFromTask(task);
          },
          loading: () => _buildLoading(),
          error: (_, __) => _buildNotDownloaded(),
        );
      }
      
      // 3. 无 Track 记录 = 未下载
      return _buildNotDownloaded();
    },
    loading: () => _buildLoading(),
    error: (_, __) => _buildNotDownloaded(),
  );
}

/// 根据 DownloadTask 构建状态图标
Widget _buildFromTask(DownloadTask task) {
  final status = task.status;
  final progress = (task.progressPercentage * 100).toInt();

  switch (status) {
    case DownloadStatus.completed:
      return _buildDownloaded();
    case DownloadStatus.downloading:
      return _buildDownloading(progress);
    case DownloadStatus.paused:
      return _buildPaused();
    case DownloadStatus.failed:
      return _buildFailed();
    case DownloadStatus.pending:
    case DownloadStatus.stalled:
      return _buildPending();
  }
}

Widget _buildDownloading(int progress) {
  return SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      value: progress / 100,
      strokeWidth: 2,
      color: Colors.green,
    ),
  );
}

Widget _buildPaused() {
  return Icon(Icons.pause_circle, size: size, color: Colors.orange);
}

Widget _buildFailed() {
  return Icon(Icons.error, size: size, color: Colors.red);
}

Widget _buildPending() {
  return Icon(Icons.schedule, size: size, color: Colors.orange);
}

Widget _buildDownloaded() {
  return Icon(Icons.download_done, size: size, color: Colors.green);
}

Widget _buildNotDownloaded() {
  return Icon(Icons.download_outlined, size: size, color: Colors.grey);
}

Widget _buildLoading() {
  return SizedBox(width: size, height: size);
}
```

### Phase 5: 修改 CachedTrack 模型

**文件**: `frontend_flutter/lib/models/cached_track.dart`

移除冗余字段：

```dart
class CachedTrack {
  final int id;
  final String sourceId;
  final TrackSource sourceType;
  final String title;
  final String? artist;
  final String? album;
  final int? duration;
  final String? coverUrl;
  final Uint8List? coverBlob;
  final String? bvid;
  final String? uploader;
  final String? uploaderMid;
  final int? playCount;
  final String? localPath;
  final bool isDownloaded;  // 保留：文件存在性
  // 移除: downloadStatus, downloadProgress
  final bool isFavorite;
  final int localPlayCount;
  final DateTime? lastPlayedAt;
  final int? position;
  final String? playlistId;
  final DateTime? addedAt;
  final DateTime? updatedAt;
  final DateTime? syncedAt;

  const CachedTrack({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.coverUrl,
    this.coverBlob,
    this.bvid,
    this.uploader,
    this.uploaderMid,
    this.playCount,
    this.localPath,
    this.isDownloaded = false,
    // 移除: downloadStatus, downloadProgress
    this.isFavorite = false,
    this.localPlayCount = 0,
    this.lastPlayedAt,
    this.position,
    this.playlistId,
    this.addedAt,
    this.updatedAt,
    this.syncedAt,
  });

  factory CachedTrack.fromMap(Map<String, dynamic> map) {
    // ... 移除 downloadStatus, downloadProgress 的解析
    return CachedTrack(
      // ...
      isDownloaded: map['is_downloaded'] == 1,
      // 移除: downloadStatus, downloadProgress
      // ...
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ...
      'is_downloaded': isDownloaded ? 1 : 0,
      // 移除: download_status, download_progress
      // ...
    };
  }
}
```

---

## 验证场景

| 场景 | 预期结果 | 验证方法 |
|------|----------|----------|
| 搜索结果 → 点击下载 | 自动创建 Track + Task | 查询数据库 |
| 下载中 | 图标显示进度 | UI 检查 |
| 下载完成 | `is_downloaded=1`, Task 保留 | 数据库查询 |
| 清空已完成任务 | `is_downloaded` 仍为 1 | 刷新页面检查 |
| 删除文件（保留记录） | `is_downloaded=0`, Task 可重下 | 手动删除文件 |
| 应用重启 | 下载任务恢复 | 杀掉应用重开 |

---

## 修改文件清单

| 文件 | 操作 |
|------|------|
| `lib/data/database/app_database.dart` | 添加 V5 迁移脚本 |
| `lib/data/repositories/download_repository.dart` | `addDownloadTask` 强制创建 Track，添加 `getTaskByTrackId` |
| `lib/data/repositories/repository_providers.dart` | 添加 `downloadTaskByTrackIdProvider` |
| `lib/presentation/widgets/common/download_status_indicator.dart` | 简化为单源查询 |
| `lib/models/cached_track.dart` | 移除 `downloadStatus`, `downloadProgress` |

---

## 风险与回滚

1. **数据迁移风险**：V5 迁移脚本需充分测试，特别是孤儿任务的 Track 创建
2. **回滚方案**：保留 `download_status` 字段但不再使用，降级到双源查询
3. **兼容性**：旧版本代码中引用 `downloadStatus` 的地方需要同步修改

---

## 实施顺序

1. **Phase 5** → 修改 `CachedTrack` 模型（其他代码会报错，便于定位修改点）
2. **Phase 1** → 数据库迁移
3. **Phase 2** → 修改 `DownloadRepository`
4. **Phase 3** → 添加 Provider
5. **Phase 4** → 修改 `DownloadStatusIndicator`
6. **测试验证** → 逐个场景验证
