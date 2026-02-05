# 本地优先架构升级方案

**创建日期**: 2026-02-05
**状态**: 进行中 - Phase 3 ⏳
**优先级**: P0（架构级改进）

---

## 总体进度

| 阶段 | 任务 | 优先级 | 状态 | 完成日期 |
|------|------|--------|------|----------|
| Phase 1 | 数据库层重构 | - | ✅ 已完成 | 2026-02-05 |
| Phase 2 | Repository 层重构 | - | ✅ 已完成 | 2026-02-05 |
| Phase 3 | 下载队列机制 | 🔴 P0 | ✅ 已完成 | 2026-02-05 |
| Phase 4 | 下载 UI 重构 | 🔴 P0 | ⏳ 当前 | - |
| Phase 5 | 网络同步重试 | 🟡 P1 | ⏳ 待开始 | - |
| Phase 6 | ViewModel 层重构 | 🟡 P1 | ⏳ 待开始 | - |
| Phase 7 | 断点续传功能 | 🟢 P2 | ⏳ 待开始 | - |
| Phase 8 | 其他 UI 更新 | 🟢 P2 | ⏳ 待开始 | - |
| Phase 9 | 剩余功能 | 🟢 P2 | ⏳ 待开始 | - |

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
    _queuePositions[queuedTasks[i].id!] = i;
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
- [ ] 每个任务独立显示进度条
- [ ] 队列中任务显示位置信息
- [ ] 操作按钮根据状态智能显示
- [ ] 移除顶部整体进度 Banner

---

### Phase 5: 网络同步重试 🟡 P1

**策略**: 本地优先 + 失败重试队列

**解决方案**:

```dart
// TrackRepository 新增字段
final _syncQueue = <_SyncTask>[];
bool _isSyncing = false;

class _SyncTask {
  final _SyncType type;
  final int trackId;
  final String? bvid;
  int retryCount;
  bool get shouldRetry => retryCount < 3;
}

enum _SyncType { favorite, playHistory }

/// 修改后的 toggleFavorite
Future<void> toggleFavorite(int trackId, bool isFavorite) async {
  // 本地优先：先更新本地
  await _trackDao.toggleFavorite(trackId, isFavorite);

  // 加入同步队列
  final track = await _trackDao.getById(trackId);
  if (track?.bvid != null) {
    _syncQueue.add(_SyncTask(
      type: _SyncType.favorite,
      trackId: trackId,
      bvid: track!.bvid,
    ));
    _startSyncWorker();
  }
}
```

**修改位置**: `track_repository.dart`
- 第 21 行后：添加 `_syncQueue` 和相关字段
- 第 286-298 行：重构 `toggleFavorite`
- 第 329-341 行：重构 `recordPlayHistory`

**验收标准**:
- [ ] 本地操作立即生效
- [ ] 同步失败自动重试（最多 3 次）
- [ ] App 重启后恢复未完成的同步任务
- [ ] 同步状态在 UI 中可见

---

### Phase 6: ViewModel 层重构 🟡 P1

**目标**: ViewModels 监听数据库变化，而非持有内存状态

**修改文件**: `download_viewmodel.dart`

```dart
@riverpod
class DownloadViewModel extends _$DownloadViewModel {
  late final DownloadRepository _repository;

  @override
  DownloadModelState build() {
    _repository = ref.watch(downloadRepositoryProvider);
    _loadTasks();
    return const DownloadModelState.initial();
  }

  Future<void> _loadTasks() async {
    final tasks = await _repository.getAllTasks();
    state = DownloadModelState.loaded(tasks: tasks);
  }
}
```

**验收标准**:
- [ ] ViewModel 初始化时从数据库加载
- [ ] 数据库变化自动同步到 UI
- [ ] App 重启后状态保持

---

### Phase 7: 断点续传功能 🟢 P2

**依赖**: 后端 API 需支持 HTTP Range 请求

```dart
// 修改 resumeDownload
Future<void> resumeDownload(int taskId) async {
  final task = await _downloadTaskDao.getById(taskId);
  if (task == null) return;

  // 检查临时文件
  final tempFile = File('${task.savePath}.tmp');
  int startBytes = 0;
  if (await tempFile.exists()) {
    startBytes = await tempFile.length();
  }

  await startDownload(taskId, startBytes: startBytes);
}

// API 添加 Range 支持
Future<void> downloadAudio({
  required String bvid,
  required String savePath,
  int startBytes = 0,
  required Function(int, String, String) onProgress,
}) async {
  final options = Options();
  if (startBytes > 0) {
    options.headers = {'Range': 'bytes=$startBytes-'};
  }
  // ...
}
```

**验收标准**:
- [ ] 暂停后恢复从断点继续
- [ ] App 重启后可恢复下载
- [ ] 临时文件正确清理
- [ ] 进度计算正确（含已下载部分）

---

### Phase 8: 其他 UI 更新 🟢 P2

**目标**: 搜索、歌单页面显示下载状态

#### 8.1 搜索结果显示下载状态

```dart
Widget _buildResultItem(SearchResultItem item) {
  return Consumer(
    builder: (context, ref, _) {
      final trackAsync = ref.watch(trackByBvidProvider(item.bvid));
      return trackAsync.when(
        data: (track) {
          final isDownloaded = track?.isDownloaded ?? false;
          return ListTile(
            title: Text(item.title),
            trailing: isDownloaded
                ? const Icon(Icons.download_done, color: Colors.green)
                : const Icon(Icons.download_outline),
          );
        },
        loading: () => _buildLoadingTile(),
        error: (_, __) => _buildErrorTile(),
      );
    },
  );
}
```

**验收标准**:
- [ ] 搜索结果显示下载状态图标
- [ ] 歌单列表显示下载状态

---

### Phase 9: 剩余功能 🟢 P2

**目标**: 完成发现页面重构和歌单详情页面

**验收标准**:
- [ ] 发现页面显示推荐内容
- [ ] 歌单详情页面功能完整
- [ ] 所有页面统一使用 `CachedTrack`

---

## 四、实施顺序建议

```
Week 1-2: Phase 1-2 ✅ 已完成

Week 2 (当前):
  ├─ Day 7:   Phase 3 下载队列机制 🔴 P0
  ├─ Day 8:   Phase 4 下载 UI 重构 🔴 P0
  └─ Day 9:   Phase 5 网络同步重试 🟡 P1

Week 2-3:
  ├─ Day 10:  Phase 6 ViewModel 重构 🟡 P1
  ├─ Day 11:  Phase 8 其他 UI 更新 🟢 P2
  └─ Day 12:  Phase 7 断点续传 🟢 P2

Week 3:
  └─ Day 13+: Phase 9 剩余功能 🟢 P2
```

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
