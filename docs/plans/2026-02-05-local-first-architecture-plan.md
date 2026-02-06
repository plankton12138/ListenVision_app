# 本地优先架构升级方案

**创建日期**: 2026-02-05
**更新日期**: 2026-02-06
**状态**: ✅ 已完成
**优先级**: P0（架构级改进）
**整体进度**: 100% (9/9 Phase 完成)

**关联计划**: [Riverpod 3.0 迁移计划](./2026-02-06-riverpod-3-migration-plan.md)

---

## 总体进度

| 阶段 | 任务 | 优先级 | 状态 | 完成日期 |
|------|------|--------|------|----------|
| Phase 1 | 数据库层重构 | - | ✅ 已完成 | 2026-02-05 |
| Phase 2 | Repository 层重构 | - | ✅ 已完成 | 2026-02-05 |
| Phase 3 | 下载队列机制 | 🔴 P0 | ✅ 已完成 | 2026-02-05 |
| Phase 4 | 下载 UI 重构 | 🔴 P0 | ✅ 已完成 | 2026-02-05 |
| Phase 5 | 网络同步重试 | 🟡 P1 | ✅ 已完成 | 2026-02-06 |
| Phase 6 | ~~ViewModel 层重构~~ | 🟡 P1 | 🔄 **已合并** | 见 Riverpod 3 迁移计划 |
| Phase 7 | 断点续传功能 | 🟢 P2 | ✅ 已完成 | 2026-02-06 |
| Phase 8 | UI 集成与同步状态显示 | 🟢 P2 | ✅ 已完成 | 2026-02-06 |
| Phase 9 | 收藏同步与 Worker 自动启动 | 🟢 P2 | ✅ 已完成 | 2026-02-06 |

> **注**: Phase 6 (ViewModel 层重构) 已合并到 [Riverpod 3.0 迁移计划](./2026-02-06-riverpod-3-migration-plan.md)，该计划将彻底解决 UI 不刷新问题。

---

## 一、背景分析

### 1.1 当前架构问题

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  UI Layer   │────▶│ ViewModel   │────▶│  API Client │
│  (Views)    │     │ (Memory)    │     │  (Network)  │
└─────────────┘     └─────────────┘     └─────────────┘
                                                │
                                                ▼
                                         ┌─────────────┐
                                         │  B站 API    │
                                         └─────────────┘
```

**问题清单**：

| 问题 | 根因 | 影响 |
|------|------|------|
| 下载任务不持久 | `DownloadViewModel` 使用内存状态 | 重启 App 后任务丢失 |
| 暂停/删除失效 | 创建 `DownloadTask` 时无 `id` | `task.id!` 为 null |
| 进度不同步 | `onProgress` 只更新状态字段 | 任务列表状态不更新 |
| 重复下载 | 无本地记录，不知道已下载 | 浪费带宽和存储 |
| 无法离线浏览 | 所有数据来自网络 | 无网络时功能受限 |

### 1.2 成熟 App 架构参考

QQ音乐/网易云音乐：

```
┌─────────────┐     ┌─────────────────────────┐     ┌─────────────┐
│  UI Layer   │────▶│      Local Database     │────▶│  API Client │
│  (Views)    │     │      (Single Source)    │     │  (Network)  │
└─────────────┘     └─────────────────────────┘     └─────────────┘
                            │
                            ▼
                     ┌─────────────┐
                     │  File       │
                     │  Storage    │
                     └─────────────┘
```

**核心原则**：
1. **本地优先** - 所有数据先存本地，网络只是补充
2. **单一数据源** - UI 始终从数据库读取，而非直接从网络
3. **响应式更新** - 数据库变化自动同步到 UI

---

## 二、架构设计

### 2.1 新架构图

```
┌──────────────────────────────────────────────────────────────────────┐
│                            UI Layer (Riverpod)                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ SearchPage │  │ ExplorePage│  │PlayerPage │  │DownloadPage│    │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘    │
│        │                │                │                │           │
│        ▼                ▼                ▼                ▼           │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    ViewModels (StateNotifier)                   │  │
│  │  SearchViewModel │ ExploreViewModel │ PlayerViewModel │ ...     │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      Repository Layer (单一数据源)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ TrackRepo    │  │ PlaylistRepo │  │ DownloadRepo │              │
│  │ (核心)       │  │              │  │              │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                       │
└─────────┼─────────────────┼─────────────────┼───────────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         Local Database (SQLite)                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ tracks     │  │ playlists  │  │download_tasks│ │play_history│   │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      External Services                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                    │
│  │ BilibiliAPI│  │ LocalFiles │  │ DownloadMgr│                    │
│  └────────────┘  └────────────┘  └────────────┘                    │
└──────────────────────────────────────────────────────────────────────┘
```

### 2.2 核心数据模型

#### 2.2.1 tracks 表（统一音频实体）

```sql
CREATE TABLE tracks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_id TEXT NOT NULL UNIQUE,
  source_type TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT,
  duration INTEGER,
  cover_url TEXT,
  bvid TEXT,
  local_path TEXT,
  is_downloaded INTEGER DEFAULT 0,
  download_status TEXT DEFAULT '',
  download_progress INTEGER DEFAULT 0,
  is_favorite INTEGER DEFAULT 0,
  play_count INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);

CREATE INDEX idx_tracks_source_id ON tracks(source_id);
CREATE INDEX idx_tracks_bvid ON tracks(bvid);
CREATE INDEX idx_tracks_is_downloaded ON tracks(is_downloaded);
```

#### 2.2.2 download_tasks 表（下载任务）

```sql
CREATE TABLE download_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  track_id INTEGER,
  bvid TEXT,
  url TEXT NOT NULL,
  save_path TEXT NOT NULL,
  title TEXT,
  status TEXT DEFAULT 'pending',
  downloaded_bytes INTEGER DEFAULT 0,
  total_bytes INTEGER DEFAULT 0,
  error_message TEXT,
  created_at TEXT,
  updated_at TEXT,
  completed_at TEXT,
  FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
);
```

#### 2.3 架构设计原则

**重要**: 所有计划必须遵循现有 MVVM + Riverpod 架构模式。

##### 2.3.1 目录组织规范

```
frontend_flutter/lib/
├── core/               # 基础设施（常量、错误、网络）
├── models/             # 轻量实体（freezed 不可变类）
├── data/               # 数据层
│   ├── database/       # SQLite DAO
│   └── repositories/   # Repository 实现
├── services/           # 有状态服务（AudioPlayer, Metadata）
└── presentation/       # UI 层
    ├── viewmodels/     # StateNotifier (@riverpod 注解)
    │   ├── auth/
    │   ├── player/
    │   ├── library/
    │   ├── discovery/
    │   └── system/
    ├── views/          # 页面 (ConsumerWidget)
    ├── widgets/        # 组件
    └── providers.dart  # 统一导出（不存放实现）
```

##### 2.3.2 计划制定规范

| 规范 | 说明 |
|------|------|
| **文件路径必须具体** | 所有修改/新建的文件必须标注完整路径 |
| **新建目录需提醒** | 涉及新建目录时必须明确提醒用户确认 |
| **优先扩展现有文件** | 功能扩展优先在现有文件中添加，而非新建 |
| **遵循现有模式** | ViewModel 用 `@riverpod` 注解，在各自文件中定义 provider |
| **providers.js 不存实现** | 该文件仅用于导出，不存放 provider 实现 |

##### 2.3.3 示例：正确的计划描述

```
#### 4.2 扩展 ViewModel 状态管理

| 修改类型 | 文件路径 | 操作 |
|----------|----------|------|
| 修改 | `frontend_flutter/lib/presentation/viewmodels/system/download_viewmodel.dart` | 添加进度缓存 |
| 修改 | `frontend_flutter/lib/presentation/views/system/backend_download_page.dart` | 重构任务卡片 |

**不新建目录或文件**，遵循现有架构模式。
```

---

## 三、实施计划

### Phase 1: 数据库层重构 ✅

**状态**: 已完成 (2026-02-05)

**创建的文件**:
- `frontend_flutter/lib/data/database/app_database.dart`
- `frontend_flutter/lib/data/database/track_dao.dart`
- `frontend_flutter/lib/data/database/download_task_dao.dart`
- `frontend_flutter/lib/models/cached_track.dart`

---

### Phase 2: Repository 层重构 ✅

**状态**: 已完成 (2026-02-05)

**创建的文件**:
- `frontend_flutter/lib/data/repositories/track_repository.dart`
- `frontend_flutter/lib/data/repositories/download_repository.dart`
- `frontend_flutter/lib/data/repositories/repository_providers.dart`

**待改进问题**:
| 问题 | 优先级 | 解决方案 |
|------|--------|----------|
| 队列机制缺失 | 🔴 P0 | Phase 3 |
| 网络同步失败 | 🟡 P1 | Phase 5 |
| 断点续传 | 🟢 P2 | Phase 7 |

---

### Phase 3: 下载队列机制 ✅

**状态**: 已完成 (2026-02-05)

**目标**: 修复并发满时任务被丢弃的问题，实现等待队列

**问题**: 当前 `startDownload()` 在并发满时直接返回，任务被丢弃。

**实现内容**:

1. **新增字段** (`download_repository.dart`):
   - `_pendingQueue`: 待处理任务 ID 队列
   - `_queueController`: 队列变更事件流

2. **修改 `startDownload`**:
   - 并发满时任务进入等待队列
   - 更新任务状态为 pending
   - 避免重复入队检查

3. **新增 `_processQueue` 方法**:
   - 下载完成后自动触发队列中的下一个任务
   - 支持并发槽位回收后的多任务启动

4. **完善队列管理**:
   - `pauseDownload`: 从队列中移除任务
   - `cancelDownload`: 从队列中移除任务
   - `deleteDownloadTask`: 从队列中移除任务
   - `dispose`: 清理队列

5. **新增队列查询方法**:
   - `getQueuePosition(int taskId)`: 获取队列位置
   - `isInQueue(int taskId)`: 检查是否在队列中
   - `getQueuedTaskIds()`: 获取队列中的任务 ID 列表
   - `getQueuedTasks()`: 获取队列中的任务详情
   - `queueStream`: 队列变更事件流

6. **DAO 更新** (`download_task_dao.dart`):
   - 新增 `markAsPending(int id)` 方法

**验收标准**:
- [x] 并发满时新任务正确进入队列
- [x] 下载完成自动触发下一个任务
- [x] 队列任务可取消/删除
- [x] 提供队列位置查询接口供 UI 使用

---

### Phase 4: 下载 UI 重构 🔴 P0

**目标**: 每个任务独立显示进度和操作，移除整体进度设计

**改进目标**:
1. 移除顶部整体进度 Banner
2. 每个任务独立显示进度和操作
3. 支持显示队列位置
4. 任务状态互不影响

#### 4.1 架构说明

**遵循现有 MVVM + Riverpod 架构**，不新建目录或文件，扩展现有组件。

| 修改类型 | 文件路径 | 操作 |
|----------|----------|------|
| 修改 | `frontend_flutter/lib/presentation/viewmodels/system/download_viewmodel.dart` | 扩展状态管理 |
| 修改 | `frontend_flutter/lib/presentation/views/system/backend_download_page.dart` | 重构任务卡片 |

#### 4.2 扩展 ViewModel 状态管理

在 `download_viewmodel.dart` 中添加：

```dart
// 新增：单任务进度缓存（ taskId -> progress ）
final Map<int, int> _taskProgress = {};
final Map<int, int> _queuePositions = {};

/// 获取任务进度
int getTaskProgress(int taskId) => _taskProgress[taskId] ?? 0;

/// 获取队列位置
int? getQueuePosition(int taskId) => _queuePositions[taskId];

/// 更新任务进度（由 Repository 回调）
void updateTaskProgress(int taskId, int progress) {
  _taskProgress[taskId] = progress;
  state = state; // 触发 UI 更新
}

/// 更新队列位置
void updateQueuePositions() {
  final repo = ref.read(downloadRepositoryProvider);
  final queuedTasks = repo.getQueuedTasks();
  _queuePositions.clear();
  for (int i = 0; i < queuedTasks.length; i++) {
    _queuePositions[queuedTasks[i].id!] = i + 1; // 1-based position（用户友好的"第1位"）
  }
  state = state; // 触发 UI 更新
}

/// 简化后的状态定义
const factory DownloadModelState.loaded({
  required List<DownloadTask> tasks,
}) = DownloadModelStateLoaded;
```

#### 4.3 重构任务卡片

在 `backend_download_page.dart` 中修改：

```dart
class _DownloadTaskTile extends ConsumerWidget {
  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(downloadViewModelProvider);
    final progress = viewModel.getTaskProgress(task.id!);
    final queuePosition = viewModel.getQueuePosition(task.id!);

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(task.title ?? '未知'),
            subtitle: _buildSubtitle(queuePosition, progress),
            trailing: _buildActions(task.status),
          ),
          if (task.status == DownloadStatus.downloading && progress > 0)
            LinearProgressIndicator(value: progress / 100),
        ],
      ),
    );
  }

  Widget _buildSubtitle(int? queuePosition, int progress) {
    if (queuePosition != null) {
      return Text('等待中 - 队列第 ${queuePosition + 1} 位');
    }
    return Text('$progress%');
  }
}
```

**验收标准**:
- [x] 每个任务独立显示进度条
- [x] 队列中任务显示位置信息
- [x] 操作按钮根据状态智能显示
- [x] 移除顶部整体进度 Banner

---

### Phase 5: 网络同步重试 🟡 P1 ✅ 已完成

**完成日期**: 2026-02-06

**策略**: 本地优先 + 失败重试队列

**实现内容**:

#### 5.1 数据模型

- [x] `models/sync_queue.dart` - 同步队列数据模型
  - `SyncTask` - 同步任务实体
  - `SyncType` - 同步操作类型枚举
  - `SyncStatus` - 同步状态枚举
  - `SyncTaskFactory` - 同步任务工厂

#### 5.2 数据库层

- [x] `data/database/app_database.dart` - 扩展数据库
  - 新增 `sync_queue` 表
  - 添加相关索引
  - 新增 CRUD 方法

- [x] `data/database/sync_queue_dao.dart` - 同步队列 DAO
  - 插入/查询/更新/删除同步任务
  - 获取待处理任务
  - 获取可重试任务
  - 统计信息

#### 5.3 同步工作器

- [x] `data/sync/sync_worker.dart` - 同步工作器
  - 定期执行同步任务（默认 30 秒间隔）
  - 最多重试 3 次
  - 支持手动触发同步
  - 状态流通知

- [x] `data/sync/sync_worker_provider.dart` - SyncWorker Provider
  - `syncWorkerProvider` - SyncWorker 实例
  - `syncStatsProvider` - 同步统计信息
  - `hasPendingSyncTasksProvider` - 是否有待处理任务

#### 5.4 Repository 层改造

- [x] `data/repositories/track_repository.dart`
  - 新增 `localOnlyMode` 参数
  - `toggleFavorite` - 本地优先 + 加入同步队列
  - `recordPlayHistory` - 本地优先 + 加入同步队列

- [x] `data/repositories/playlist_repository.dart`
  - 新增 `localOnlyMode` 参数
  - `createPlaylist` - 失败时加入同步队列
  - `updatePlaylist` - 失败时加入同步队列
  - `deletePlaylist` - 失败时加入同步队列
  - `addPlaylistItem` - 失败时加入同步队列
  - `removePlaylistItem` - 失败时加入同步队列

**验收标准**:
- [x] 本地操作立即生效
- [x] 同步失败自动重试（最多 3 次）
- [x] App 重启后恢复未完成的同步任务
- [ ] 同步状态在 UI 中可见（待 Phase 8 实现）

---

### Phase 6: ViewModel 层重构 🟡 P1 🔄 已合并

> ⚠️ **重要变更**: 本阶段已合并到 [Riverpod 3.0 迁移计划](./2026-02-06-riverpod-3-migration-plan.md)

#### 合并原因

| 原计划 Phase 6 目标 | Riverpod 3 迁移对应内容 |
|---------------------|------------------------|
| ViewModel 监听数据库变化 | Phase 2: 使用 `AsyncNotifier.build()` 异步初始化 |
| 修复 UI 不刷新问题 | Phase 5: Widget 监听 `AsyncValue` 而非实例 |
| 状态持久化 | 已在 Phase 1-4 完成 (Repository + DAO) |

#### 迁移状态

请参考 [Riverpod 3.0 迁移跟踪文档](./2026-02-06-riverpod-3-migration-tracking.md) 查看详细进度。

| ViewModel | 原计划 | 现计划 | 状态 |
|-----------|--------|--------|------|
| DownloadViewModel | Phase 6 | Riverpod 3 Phase 2 | ⏳ 待迁移 |
| QueueViewModel | Phase 6 | Riverpod 3 Phase 2 | ⏳ 待迁移 |
| PlaylistViewModel | Phase 6 | Riverpod 3 Phase 2 | ⏳ 待迁移 |
| SearchViewModel | Phase 6 | Riverpod 3 Phase 4 | ⏳ 待迁移 |
| LocalMusicViewModel | Phase 6 | Riverpod 3 Phase 4 | ⏳ 待迁移 |

---

### Phase 7: 断点续传功能 ✅ (2026-02-06 完成)

**依赖**: 后端 API 需支持 HTTP Range 请求

#### 实现内容

**前端修改**:
- `models/download_task.dart` - 添加 `tempFilePath`, `etag`, `lastModified` 字段
- `data/database/app_database.dart` - 数据库版本升级到 v2，添加断点续传字段
- `data/database/download_task_dao.dart` - 添加 `updateResumableInfo()`, `clearTempFile()` 等方法
- `services/resumable_download_service.dart` - 新建支持 Range 请求的下载服务
- `data/repositories/download_repository.dart` - 添加 `_downloadWithResumable()` 方法

**后端修改**:
- `controllers/bilibiliController.js` - 添加 `downloadAudioWithRange()` 控制器
- `routes/bilibili.js` - 添加 `/api/bilibili/download-range/:bvid` 路由

#### 断点续传工作流程

1. **首次下载/暂停**：
   - 下载时创建临时文件（`.tmp`）
   - 记录已下载字节数、ETag、Last-Modified
   - 用户暂停时保留临时文件

2. **恢复下载**：
   - 检查是否有临时文件和 ETag
   - 发送 `Range: bytes=X-` 请求头
   - 发送 `If-Match: etag` 验证文件未更改
   - 服务器返回 206 Partial Content

3. **文件验证**：
   - 如果 ETag 不匹配，返回 412 Precondition Failed
   - 客户端自动重新下载

**验收标准**:
- [x] 暂停后恢复从断点继续
- [x] App 重启后可恢复下载
- [x] 临时文件正确清理
- [x] 进度计算正确（含已下载部分）
- [x] 支持 ETag/If-Match 验证

---

### Phase 8: 其他 UI 更新 ✅ (2026-02-06 完成)

**目标**: 搜索、歌单页面显示下载状态

#### 实现内容

**新建组件**:
- `widgets/common/download_status_indicator.dart` - 下载状态指示器组件
  - `DownloadStatusIndicator` - 自动查询并显示下载状态
  - `CompactDownloadStatusIndicator` - 紧凑型指示器（已知状态时使用）

**更新页面**:
- `views/discovery/search_page.dart` - 搜索结果副标题中添加下载状态图标
- `views/discovery/explore_page.dart` - 发现页面列表项添加下载状态图标

#### 下载状态图标说明

| 状态 | 图标 | 颜色 |
|------|------|------|
| 未下载 | `Icons.download_outlined` | 灰色 |
| 已下载 | `Icons.download_done` | 绿色 |
| 下载中 | `CircularProgressIndicator` | 进度色 |
| 已暂停 | `Icons.download_done` | 橙色 |
| 失败 | `Icons.error_outline` | 红色 |

**验收标准**:
- [x] 搜索结果显示下载状态图标
- [x] 歌单列表显示下载状态
- [x] 发现页面显示下载状态

---

### Phase 9: 收藏同步与 Worker 自动启动 ✅ (2026-02-06 完成)

**目标**: 完成本地优先架构的最后一环 - 收藏操作同步和同步状态 UI

#### 实现内容

**Repository 层改造**:
- [x] `data/repositories/playlist_repository.dart`
  - `toggleFavorite` - 支持本地优先模式，失败时加入同步队列
  - 先检查当前收藏状态，根据状态决定同步类型（favorite/unfavorite）

**ViewModel 层集成**:
- [x] `presentation/viewmodels/auth/auth_viewmodel.dart`
  - 用户登录时自动启动 SyncWorker
  - 应用启动时检测已登录用户自动启动 SyncWorker

- [x] `presentation/viewmodels/library/history_viewmodel.dart`
  - PlayHistoryRepository 启用 `localOnlyMode: true`

- [x] `presentation/viewmodels/player/player_viewmodel.dart`
  - 播放在线音频时自动记录播放历史
  - 调用 HistoryViewModel.recordPlay

**UI 组件**:
- [x] `widgets/common/sync_status_indicator.dart` - 同步状态指示器组件
  - `SyncStatusIndicator` - 自动查询并显示同步状态
  - `_SyncStatusDialog` - 同步状态详情对话框
  - `CompactSyncStatusIndicator` - 紧凑型指示器

- [x] `views/system/settings_page.dart` - 设置页面添加同步状态卡片

**Providers 导出**:
- [x] `presentation/providers.dart` - 导出同步相关 Providers
  - `syncWorkerProvider`
  - `syncStatsProvider`
  - `hasPendingSyncTasksProvider`
  - `SyncQueueStats`

**验收标准**:
- [x] toggleFavorite 操作支持本地优先模式
- [x] 用户登录后 SyncWorker 自动启动
- [x] 设置页面显示同步状态指示器
- [x] 点击同步状态可查看详情和手动触发同步
- [x] 播放在线音频自动记录播放历史

---

## 四、实施顺序建议

### 4.1 更新后的时间线

```
Week 1-2: Phase 1-4 ✅ 已完成
  ├─ Phase 1: 数据库层重构
  ├─ Phase 2: Repository 层重构
  ├─ Phase 3: 下载队列机制
  └─ Phase 4: 下载 UI 重构

Week 2-3: Riverpod 3.0 迁移 ✅ 已完成
  └─ 参见: 2026-02-06-riverpod-3-migration-plan.md
    ├─ Phase 1-2: 基础设施 + 核心 ViewModel
    ├─ Phase 4: 其他 ViewModel (含原 Phase 6 内容)
    └─ Phase 5: Widget 全面更新

Week 3-4: 本计划剩余 Phase ✅ 已完成
  ├─ Day 10:  Phase 5 网络同步重试 ✅
  ├─ Day 11:  Phase 7 断点续传 ✅
  ├─ Day 12:  Phase 8 UI 更新 ✅
  └─ Day 13:  Phase 9 收藏同步与 Worker 启动 ✅
```

**本地优先架构完成日期**: 2026-02-06

---

## 四、实施顺序建议

### 4.1 更新后的时间线

```
Week 1-2: Phase 1-4 ✅ 已完成
  ├─ Phase 1: 数据库层重构
  ├─ Phase 2: Repository 层重构
  ├─ Phase 3: 下载队列机制
  └─ Phase 4: 下载 UI 重构

Week 2-3: Riverpod 3.0 迁移 (优先执行)
  └─ 参见: 2026-02-06-riverpod-3-migration-plan.md
    ├─ Phase 1-2: 基础设施 + 核心 ViewModel
    ├─ Phase 4: 其他 ViewModel (含原 Phase 6 内容)
    └─ Phase 5: Widget 全面更新

Week 3-4: 本计划剩余 Phase (按需执行)
  ├─ Day 10:  Phase 5 网络同步重试 🟡 P1
  ├─ Day 11:  Phase 8 其他 UI 更新 🟢 P2
  ├─ Day 12:  Phase 7 断点续传 🟢 P2 (可选)
  └─ Day 13+:  Phase 9 剩余功能 🟢 P2
```

### 4.2 与 Riverpod 3 迁移的协调

| 本计划 Phase | 执行时机 | 说明 |
|-------------|----------|------|
| Phase 1-4 | ✅ 已完成 | 不受影响 |
| Phase 5 | Riverpod 3 迁移后 | 网络同步重试，使用迁移后的 ViewModel |
| Phase 6 | 🔄 合并 | 由 Riverpod 3 迁移计划 Phase 2/4 覆盖 |
| Phase 7-9 | Riverpod 3 迁移后 | 断点续传、UI 更新等功能 |

**关键原则**:
1. **先完成 Riverpod 3 迁移**，确保所有 ViewModels 使用正确架构
2. **Phase 5 网络同步重试** 依赖迁移后的 ViewModel，需要在迁移后实施
3. **Phase 7-9 可按需调整优先级**，根据实际需求决定执行顺序

---

## 五、风险与注意事项

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 数据库迁移失败 | 用户数据丢失 | 充分测试迁移脚本，提供回滚方案 |
| 性能问题 | UI 卡顿 | 使用索引，异步操作，分页加载 |
| 并发下载冲突 | 下载失败 | 限制并发数（3 个），使用队列 |
| 存储空间不足 | 下载中断 | 提前检查可用空间，友好的错误提示 |

---

## 六、验收标准总结

| 功能 | 验收点 |
|------|--------|
| 数据库 | 表结构正确，CRUD 操作正常 |
| Repository | 优先本地数据，网络回源正常 |
| 下载 | 进度同步，状态持久，暂停/恢复/删除正常，队列机制工作 |
| UI | 下载状态图标显示正确，进度实时更新，每个任务独立显示 |
| 兼容性 | 现有功能正常工作，数据迁移成功 |
