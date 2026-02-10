# 下载任务管理功能分析报告

**生成日期**: 2026-02-07
**更新日期**: 2026-02-07 (v2.0 - 增补版)
**分析范围**: 前后端下载任务管理架构
**相关文件**:
- `frontend_flutter/lib/presentation/viewmodels/system/download_viewmodel.dart`
- `frontend_flutter/lib/data/repositories/download_repository.dart`
- `frontend_flutter/lib/data/api/bilibili_api_client.dart`
- `frontend_flutter/lib/services/resumable_download_service.dart`
- `frontend_flutter/lib/data/database/download_task_dao.dart`
- `listen-vision_api/controllers/bilibiliController.js`
- `listen-vision_api/services/downloadTaskStore.js`
- `listen-vision_api/services/audio/conversionService.js`

---

## 评审意见

### 总体评价

| 维度 | 评分 | 说明 |
|------|------|------|
| 问题诊断 | ⭐⭐⭐⭐⭐ | 精准定位核心问题 |
| 方案可行性 | ⭐⭐⭐⭐⭐ | 代码可直接使用 |
| 架构设计 | ⭐⭐⭐⭐☆ | 分层合理，但后端部分偏弱 |
| 完整性 | ⭐⭐⭐⭐☆ | v2.0 已补充异常边界和清理策略 |
| 文档质量 | ⭐⭐⭐⭐⭐ | 结构清晰，示例充分 |

---

## 一、问题诊断

### 1.1 重启后状态更新不正确

**问题描述**：应用重启后，下载任务状态与实际不符，部分任务无法恢复。

**根本原因**：`download_viewmodel.dart:98-111`

```dart
Future<void> _resumeIncompleteTasks() async {
  final pendingTasks = await _repository!.getPendingTasks();
  for (final task in pendingTasks) {
    if (task.id != null) {
      await _repository!.startDownload(task.id!);
    }
  }
}
```

**问题分析**：
1. `_resumeIncompleteTasks` 只恢复 `pending` 状态的任务
2. 数据库中任务状态可能与实际不符（如崩溃时任务实际在 `downloading` 状态）
3. 恢复时没有验证文件状态，可能重启后立即开始一个已部分下载的任务
4. 崩溃前 `downloading` 状态的任务在数据库中仍为 `downloading`，重启后永远不会被恢复

### 1.2 暂停后无法再次暂停/删除

**问题描述**：多次暂停后，操作功能丢失，无法再次暂停或删除。

**根本原因**：多个状态同步点不一致

**状态存储位置**：
1. **后端内存状态** (`downloadTaskStore.js`) - 存储在 Map 中，重启后丢失 ⚠️
2. **前端数据库状态** (`download_task_dao.dart`) - 持久化
3. **前端内存状态** (`_activeDownloads`, `_pendingQueue`) - 重启后丢失

**关键问题代码**：`download_repository.dart:379-413`

```dart
Future<void> pauseDownload(int taskId) async {
  // 从队列移除
  if (_pendingQueue.contains(taskId)) {
    _pendingQueue.remove(taskId);
  }

  // 取消前端的下载流
  final cancelToken = _activeDownloads[taskId];
  if (cancelToken != null && !cancelToken.isCancelled) {
    cancelToken.cancel('用户暂停');
  }

  // 通知后端停止处理
  if (task?.requestId != null) {
    await _bilibiliApi.cancelDownload(task!.requestId!);
  }

  await _downloadTaskDao.markAsPaused(taskId);
}
```

**问题流程**：
1. 第一次暂停：`cancelToken` 被取消并从 `_activeDownloads` 移除（finally 块）
2. 第二次暂停：`_activeDownloads[taskId]` 返回 null，取消操作被跳过
3. 后端 `requestId` 可能已过期（后端重启后丢失），`cancelDownload` 调用失败但被 catch 忽略
4. 数据库状态被标记为 `paused`，但实际下载可能仍在后端运行

### 1.3 后端状态持久化缺失（核心问题）

**问题描述**：后端 `downloadTaskStore.js` 使用内存存储，重启后所有任务状态丢失。

**问题代码**：`downloadTaskStore.js:32-35`

```javascript
class DownloadTaskStore {
  constructor() {
    // Map<requestId, Task>
    this.tasks = new Map();  // ⚠️ 内存存储，重启即丢失
  }
}
```

**影响**：
- 前端依赖的 `requestId` 在后端重启后失效
- `cancelDownload` 调用失败但前端无法感知
- 前端完善的恢复逻辑因后端状态丢失而失效

---

## 二、成熟下载功能流程设计

### 2.1 状态管理核心原则

```
┌──────────────────────────────────────────────────────────────┐
│  原则1: 单一数据源 (Single Source of Truth)                  │
│  → 数据库为唯一真相源，所有状态变更必须先写入数据库           │
│  → 内存缓存仅用于性能优化，失效时从数据库重建                │
├──────────────────────────────────────────────────────────────┤
│  原则2: 幂等性 (Idempotency)                                │
│  → 暂停已暂停的任务 = 无操作                                 │
│  → 删除已删除的任务 = 无操作                                 │
│  → 恢复已完成任务 = 无操作                                   │
├──────────────────────────────────────────────────────────────┤
│  原则3: 优雅降级 (Graceful Degradation)                     │
│  → 后端不可用时，前端可独立完成断点续传                      │
│  → 网络失败时，保留本地状态供重试                           │
├──────────────────────────────────────────────────────────────┤
│  原则4: 状态机严格转换 (State Machine)                       │
│  → 只允许特定状态转换                                       │
│  → 非法转换请求强制阻断（生产环境）                         │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 推荐状态转换图

```
                    ┌─────────────┐
                    │   pending   │  (初始/等待中)
                    └──────┬──────┘
                           │ start()
                           ▼
                    ┌─────────────┐
           ┌────────│ downloading │◄────┐
           │        └──────┬──────┘     │
           │               │            │
    pause()/│          error()     complete()
   cancel() │               │            │
           │               ▼            ▼
           │        ┌─────────────┐  ┌───────────┐
           │        │   failed    │  │ completed │
           │        └──────┬──────┘  └─────┬─────┘
           │               │               │
           │          retry()         delete()
           │               │               │
           └───────► ┌─────┴─────┐ ◄────────┘
                     │   paused   │
                     └─────┬─────┘
                           │ resume()
                           └───────────┘
```

**合法转换规则**：
| 当前状态 | 可转换到 | 说明 |
|---------|---------|------|
| `pending` | `downloading`, `failed` | 等待中可开始或失败 |
| `downloading` | `paused`, `completed`, `failed` | 下载中可暂停、完成或失败 |
| `paused` | `pending`, `failed` | 暂停后可重新排队或失败 |
| `completed` | `pending` | 完成后可重新下载 |
| `failed` | `pending` | 失败后可重试 |

### 2.3 改进架构设计

```
┌──────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │DownloadPage  │  │  TaskList    │  │  ProgressDialog  │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                   │             │
│         └─────────────────┴───────────────────┘             │
│                           │                                 │
├───────────────────────────▼─────────────────────────────────┤
│                  ViewModel (Riverpod)                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ DownloadViewModel                                    │   │
│  │  • state: AsyncValue<DownloadModelState>            │   │
│  │  • 操作: pause(), resume(), delete(), retry()       │   │
│  │  • 所有操作返回 Result<T> (success/failure)        │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                           │                                 │
├───────────────────────────▼─────────────────────────────────┤
│                   Repository Layer                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ DownloadRepository                                   │   │
│  │  • _database: DatabaseDao (唯一真相源)              │   │
│  │  • _executor: DownloadExecutor (执行引擎)           │   │
│  │  • _slotManager: SlotManager (槽位管理)            │   │
│  │  • _notifier: StateNotifier (状态通知)              │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                           │                                 │
├───────────────────────────▼─────────────────────────────────┤
│                   Executor Layer                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ DownloadExecutor                                     │   │
│  │  • 管理下载 Isolate/线程                              │   │
│  │  • 处理取消令牌传递                                   │   │
│  │  • 与数据库解耦 (不直接访问数据库)                    │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                           │                                 │
├───────────────────────────▼─────────────────────────────────┤
│                   Storage Layer                             │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │  SQLite Database │  │  File System     │               │
│  │  • download_tasks│  │  • .tmp files    │               │
│  │  • sync_queue    │  │  • final files   │               │
│  └──────────────────┘  └──────────────────┘               │
└──────────────────────────────────────────────────────────────┘
```

---

## 三、具体问题定位

### 3.1 暂停后操作功能丢失

**定位**：`download_repository.dart:392-395`

```dart
final cancelToken = _activeDownloads[taskId];
if (cancelToken != null && !cancelToken.isCancelled) {
  cancelToken.cancel('用户暂停');
}
```

**问题**：
1. 第一次暂停：`cancelToken` 被取消并从 `_activeDownloads` 移除（在 `startDownload` 的 finally 块）
2. 第二次暂停：`_activeDownloads[taskId]` 返回 null，取消操作被跳过
3. 后端 `requestId` 可能已过期，`cancelDownload` 调用失败但被 catch 忽略
4. 数据库状态被标记为 `paused`，但实际下载可能仍在后端运行

### 3.2 重启后状态不正确

**定位**：`download_viewmodel.dart:98-111`

```dart
Future<void> _resumeIncompleteTasks() async {
  final pendingTasks = await _repository!.getPendingTasks();
  for (final task in pendingTasks) {
    if (task.id != null) {
      await _repository!.startDownload(task.id!);
    }
  }
}
```

**问题**：
1. 只恢复 `pending` 状态的任务
2. 崩溃前 `downloading` 状态的任务在数据库中仍为 `downloading`
3. 重启后这些任务永远不会被恢复（不在 `pending` 列表中）
4. `paused` 状态的任务也不在恢复列表中

### 3.3 并发控制槽位泄漏

**问题场景**：
```
1. 任务A开始下载（占用1个并发槽）
2. 任务A暂停（从 _activeDownloads 移除，槽位释放）
3. 任务B开始下载（占用1个槽）
4. 任务A恢复（重新占槽）
5. 任务C开始下载（此时实际并发可能超过限制）
```

**根本原因**：`_activeDownloads` 仅存储正在下载的任务，暂停后立即移除，导致槽位计数不准确。

---

## 四、推荐修复方案

### 4.1 修复点汇总

| 修复点 | 文件 | 优先级 | 问题描述 | 解决方案 |
|--------|------|--------|----------|----------|
| 1. 恢复逻辑 | `download_viewmodel.dart` | P0 | 只恢复 pending 任务 | 同时恢复 paused/downloading 状态，验证文件 |
| 2. 暂停幂等性 | `download_repository.dart` | P0 | 多次暂停失效 | 检查当前状态，已暂停则直接返回 |
| 3. 文件完整性校验 | `download_viewmodel.dart` | P1 | .tmp 文件可能损坏 | 验证文件大小与数据库记录一致 |
| 4. 内存状态重建 | `download_repository.dart` | P1 | 重启后 `_activeDownloads` 为空 | 从数据库重建内存状态 |
| 5. requestId 过期处理 | `download_repository.dart` | P1 | 过期 requestId 导致取消失败 | 失败时清除 requestId，添加超时 |
| 6. 状态机验证 | `download_task_dao.dart` | P1 | 缺少状态转换验证 | 添加合法状态转换检查，**强制阻断** |
| 7. 槽位管理 | `download_repository.dart` | P2 | 并发控制槽位泄漏 | 引入 SlotManager 分离槽位和执行状态 |
| 8. 临时文件清理 | `download_repository.dart` | P2 | 孤立 .tmp 文件积累 | 启动时扫描清理 |
| 9. 后端状态持久化 | `downloadTaskStore.js` | P2 | 后端重启状态丢失 | Redis/数据库 或无状态后端改造 |
| 10. 任务超时清理 | `download_task_dao.dart` | P2 | paused 任务永久占用 | 7天未完成自动标记为 failed |

### 4.2 改进恢复逻辑（含文件校验）

**文件**：`lib/presentation/viewmodels/system/download_viewmodel.dart`

```dart
/// 恢复未完成的任务（pending + paused + downloading）
/// 改进版：验证文件状态，处理崩溃恢复，校验文件完整性
Future<void> _resumeIncompleteTasks() async {
  try {
    // 获取所有未完成的任务
    final incompleteTasks = await _repository!.getIncompleteTasks();

    for (final task in incompleteTasks) {
      if (task.id == null) continue;

      // 验证文件状态
      final file = File(task.savePath);
      final tempFile = File('${task.savePath}.tmp');

      final fileExists = await file.exists();
      final tempExists = await tempFile.exists();

      // 已完成且文件存在，跳过
      if (task.status == DownloadStatus.completed && fileExists) {
        continue;
      }

      // 文件完整性校验（v2.0 新增）
      if (tempExists) {
        final actualSize = await tempFile.length();
        final recordedSize = task.downloadedBytes;

        // 文件大小差异超过 1MB，可能损坏
        if ((actualSize - recordedSize).abs() > 1024 * 1024) {
          AppLogger.warn('DownloadViewModel',
            '临时文件大小不一致: 记录=$recordedSize, 实际=$actualSize，重新下载');
          await tempFile.delete();
          await _repository!.updateDownloadedBytes(task.id!, 0);
          tempExists = false;
        }
      }

      // 崩溃前在下载，但临时文件不存在，重置状态
      if (task.status == DownloadStatus.downloading && !tempExists) {
        await _repository!.resetTaskStatus(task.id!, DownloadStatus.pending);
      }

      // 决定是否恢复
      bool shouldResume = switch (task.status) {
        DownloadStatus.pending => true,
        DownloadStatus.paused => tempExists || fileExists,
        DownloadStatus.downloading => tempExists,
        _ => false,
      };

      if (shouldResume) {
        AppLogger.info('DownloadViewModel',
          '恢复任务: ${task.bvid}, 状态: ${task.status}, 临时文件: $tempExists');
        await _repository!.startDownload(task.id!);
      } else {
        // 无法恢复的任务标记为失败
        await _repository!.markAsFailed(task.id!, '应用异常关闭，下载未完成');
      }
    }
  } catch (e) {
    AppLogger.error('DownloadViewModel', '恢复任务失败: $e');
  }
}
```

### 4.3 改进暂停逻辑（幂等性 + 超时）

**文件**：`lib/data/repositories/download_repository.dart`

```dart
/// 暂停下载（幂等操作 + 超时机制）
Future<void> pauseDownload(int taskId) async {
  final task = await _downloadTaskDao.getById(taskId);
  if (task == null) return;

  // 幂等性检查：已暂停或已完成则直接返回
  if (task.status == DownloadStatus.paused ||
      task.status == DownloadStatus.completed) {
    AppLogger.info('DownloadRepository',
      '任务 $taskId 已是 ${task.status} 状态，跳过暂停');
    return;
  }

  // 从队列移除（幂等）
  _pendingQueue.remove(taskId);
  _queueController.add(taskId);

  // 取消前端的下载流（幂等）
  final cancelToken = _activeDownloads[taskId];
  if (cancelToken != null && !cancelToken.isCancelled) {
    cancelToken.cancel('用户暂停');
    _activeDownloads.remove(taskId);
  }

  // 通知后端停止（添加超时机制）
  if (task.requestId != null) {
    try {
      await _bilibiliApi.cancelDownload(task.requestId!).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.warn('DownloadRepository', '后端取消超时，强制本地暂停');
          throw TimeoutException('后端取消超时');
        },
      );
    } catch (e) {
      // requestId 可能已过期（后端重启），清除本地记录
      AppLogger.warn('DownloadRepository',
        '取消后端任务失败，清除 requestId: $e');
      await _downloadTaskDao.updateRequestId(taskId, null);
    }
  }

  // 更新数据库状态
  await _downloadTaskDao.markAsPaused(taskId);

  // 更新关联 Track 状态
  if (task.trackId != null) {
    await _trackDao.updateDownloadStatus(
      task.trackId!,
      DownloadStatus.paused,
      _taskProgress[taskId] ?? 0,
    );
  }

  AppLogger.info('DownloadRepository', '暂停完成: $taskId');
}
```

### 4.4 状态机验证（强制阻断）

**文件**：`lib/data/database/download_task_dao.dart`

```dart
/// 状态转换异常
class InvalidStateTransitionError implements Exception {
  final DownloadStatus from;
  final DownloadStatus to;

  InvalidStateTransitionError(this.from, this.to);

  @override
  String toString() => '非法状态转换: $from -> $to';
}

/// 下载任务 DAO
class DownloadTaskDao {
  // ... 现有代码

  /// 合法的状态转换
  static const _validTransitions = {
    DownloadStatus.pending: [
      DownloadStatus.downloading,
      DownloadStatus.failed,
    ],
    DownloadStatus.downloading: [
      DownloadStatus.paused,
      DownloadStatus.completed,
      DownloadStatus.failed,
    ],
    DownloadStatus.paused: [
      DownloadStatus.pending,
      DownloadStatus.failed,
    ],
    DownloadStatus.completed: [
      DownloadStatus.pending, // 允许重新下载
    ],
    DownloadStatus.failed: [
      DownloadStatus.pending, // 允许重试
    ],
  };

  /// 验证状态转换是否合法
  bool _isValidTransition(DownloadStatus from, DownloadStatus to) {
    final allowed = _validTransitions[from];
    return allowed?.contains(to) ?? false;
  }

  /// 更新任务状态（带强制验证）
  Future<void> updateStatus(int id, DownloadStatus status) async {
    final current = await getById(id);
    if (current != null) {
      if (!_isValidTransition(current.status, status)) {
        // v2.0: 强制阻断，抛出异常
        AppLogger.error('DownloadTaskDao',
          '非法状态转换: ${current.status} -> $status');
        throw InvalidStateTransitionError(current.status, status);
      }
    }
    // ... 原有更新逻辑
  }
}
```

### 4.5 槽位管理器（解决并发泄漏）

**文件**：`lib/data/repositories/download_slot_manager.dart` (新建)

```dart
/// 下载槽位状态
enum DownloadSlotStatus {
  /// 空闲
  idle,
  /// 占用中
  occupied,
  /// 预留（暂停后保留槽位）
  reserved,
}

/// 下载槽位管理器
///
/// 解决问题：暂停后重新开始时，实际并发数可能超过限制
class DownloadSlotManager {
  final int maxSlots;
  final Map<int, DownloadSlotStatus> _slots = {};

  DownloadSlotManager({this.maxSlots = 3});

  /// 获取当前占用数（包括 reserved）
  int get occupiedCount => _slots.values
      .where((s) => s == DownloadSlotStatus.occupied)
      .length;

  /// 获取总占用数（包括 reserved）
  int get totalReservedCount => _slots.length;

  /// 是否有空闲槽位
  bool get hasAvailableSlot => occupiedCount < maxSlots;

  /// 占用槽位
  bool occupySlot(int taskId) {
    if (!hasAvailableSlot) return false;

    _slots[taskId] = DownloadSlotStatus.occupied;
    return true;
  }

  /// 释放槽位
  void releaseSlot(int taskId) {
    _slots.remove(taskId);
  }

  /// 预留槽位（暂停时调用，保留槽位不释放）
  void reserveSlot(int taskId) {
    _slots[taskId] = DownloadSlotStatus.reserved;
  }

  /// 恢复槽位（从 reserved 变为 occupied）
  bool restoreSlot(int taskId) {
    if (_slots[taskId] == DownloadSlotStatus.reserved) {
      _slots[taskId] = DownloadSlotStatus.occupied;
      return true;
    }
    return occupySlot(taskId);
  }

  /// 检查任务是否有槽位
  bool hasSlot(int taskId) => _slots.containsKey(taskId);

  /// 清理所有槽位
  void clear() {
    _slots.clear();
  }
}
```

### 4.6 临时文件清理机制

**文件**：`lib/data/repositories/download_repository.dart`

```dart
/// 清理孤立的临时文件
Future<void> cleanupOrphanTempFiles() async {
  try {
    final downloadDir = await getDownloadDirectory();
    final tempFiles = downloadDir
        .listSync()
        .where((f) => f.path.endsWith('.tmp'))
        .cast<File>()
        .toList();

    for (final tempFile in tempFiles) {
      // 检查是否有对应的任务记录
      final savePath = tempFile.path.replaceAll('.tmp', '');
      final task = await _downloadTaskDao.getBySavePath(savePath);

      if (task == null || task.status == DownloadStatus.completed) {
        // 无对应任务或已完成，删除临时文件
        await tempFile.delete();
        AppLogger.info('DownloadRepository', '清理孤立临时文件: ${tempFile.path}');
      }
    }
  } catch (e) {
    AppLogger.error('DownloadRepository', '清理临时文件失败: $e');
  }
}

/// 清理超时的暂停任务
Future<void> cleanupStalePausedTasks() async {
  try {
    const staleDuration = Duration(days: 7);
    final now = DateTime.now();

    final pausedTasks = await _downloadTaskDao.getPaused();
    for (final task in pausedTasks) {
      if (task.updatedAt != null) {
        final age = now.difference(task.updatedAt!);
        if (age > staleDuration) {
          await _downloadTaskDao.markAsFailed(
            task.id!,
            '下载超时，任务已暂停超过 7 天',
          );
          AppLogger.info('DownloadRepository', '清理超时任务: ${task.id}');
        }
      }
    }
  } catch (e) {
    AppLogger.error('DownloadRepository', '清理超时任务失败: $e');
  }
}
```

### 4.7 内存状态重建

**文件**：`lib/data/repositories/download_repository.dart`

```dart
class DownloadRepository {
  final DownloadTaskDao _downloadTaskDao;
  final DownloadSlotManager _slotManager;  // v2.0 新增

  // ... 现有代码

  /// 从数据库重建内存状态（应用重启后调用）
  Future<void> rebuildState() async {
    // 获取所有下载中的任务
    final downloadingTasks = await _downloadTaskDao.getDownloading();

    // 清空当前内存状态
    _activeDownloads.clear();
    _pendingQueue.clear();
    _slotManager.clear();

    // 重建队列状态
    for (final task in downloadingTasks) {
      if (task.id != null) {
        // 下载中的任务实际上已经中断（应用重启）
        // 将它们移回等待队列
        _pendingQueue.add(task.id!);
        await _downloadTaskDao.markAsPending(task.id!);
      }
    }

    // 获取等待中的任务
    final pendingTasks = await _downloadTaskDao.getPending();
    for (final task in pendingTasks) {
      if (task.id != null && !_pendingQueue.contains(task.id!)) {
        _pendingQueue.add(task.id!);
      }
    }

    // 执行清理（v2.0 新增）
    await cleanupOrphanTempFiles();
    await cleanupStalePausedTasks();

    AppLogger.info('DownloadRepository',
      '内存状态重建完成: 活跃=${_activeDownloads.length}, 队列=${_pendingQueue.length}');
  }
}
```

---

## 五、后端架构优化方案

### 5.1 问题分析

当前 `downloadTaskStore.js` 使用内存存储任务状态：

```javascript
class DownloadTaskStore {
  constructor() {
    this.tasks = new Map();  // ⚠️ 重启即丢失
  }
}
```

**影响**：
- 前端依赖的 `requestId` 在后端重启后失效
- `cancelDownload` 调用失败但前端无法感知
- 前端完善的恢复逻辑因后端状态丢失而失效

### 5.2 方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| A. Redis/数据库持久化 | 状态持久化，支持多实例 | 引入新依赖，复杂度增加 | ⭐⭐⭐ |
| B. 无状态后端改造 | 简单，符合当前架构 | 需要前端驱动一切 | ⭐⭐⭐⭐⭐ |

### 5.3 推荐方案：无状态后端

**核心思想**：后端不保存任何任务状态，所有状态由前端数据库管理。

#### 后端改动

**文件**：`listen-vision_api/controllers/bilibiliController.js`

```javascript
/**
 * 下载音频文件（无状态版本）
 *
 * 改动：
 * 1. 移除 downloadTaskStore 依赖
 * 2. 不再创建 requestId，直接返回文件
 * 3. 移除 shouldCancel 回调（后端无法知道前端状态）
 */
const downloadAudioStateless = async (req, res) => {
  const { bvid } = req.params;
  const { format = 'mp3' } = req.query;

  if (!bvid) {
    return res.status(400).json({ success: false, error: '缺少 bvid 参数' });
  }

  const userId = req.user?.id;
  const audioService = require('../services/audio');
  const startTime = Date.now();

  try {
    // 步骤1: 获取视频信息
    const videoInfo = await bilibiliService.getVideoInfo(bvid);
    const metadata = {
      title: videoInfo.title || '未知标题',
      artist: videoInfo.owner?.name || '未知艺术家',
      album: `https://www.bilibili.com/video/${bvid}`,
      coverUrl: videoInfo.cover
    };

    // 步骤2: 获取音频流URL
    const audioStream = await bilibiliService.getAudioStream(bvid, null, userId);
    if (!audioStream || !audioStream.baseUrl) {
      return res.status(404).json({ success: false, error: '无法获取音频流URL' });
    }

    // 步骤3: 转换并获取文件（移除 shouldCancel）
    const result = await audioService.convertWithMetadata(
      audioStream.baseUrl,
      metadata,
      format,
      { bitrate: '192k', sampleRate: '44100', channels: 2 },
      (percent, stage) => {
        // 发送进度（可选）
      }
    );

    // 步骤4: 直接发送文件
    res.setHeader('Content-Type', result.contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${encodeURIComponent(metadata.title)}.${format}"`);
    res.send(result.buffer);

    logger.info('BiliDownload Stateless 完成', {
      bvid,
      bytes: result.buffer.length,
      durationMs: Date.now() - startTime
    });

  } catch (error) {
    logger.error('BiliDownload Stateless 失败', {
      bvid,
      error: error.message,
      durationMs: Date.now() - startTime
    });

    res.status(500).json({ success: false, error: `下载失败: ${error.message}` });
  }
};

// 导出新的无状态版本
module.exports = {
  // ... 其他导出
  downloadAudioStateless,  // 新增
};
```

#### 前端改动

**文件**：`lib/data/repositories/download_repository.dart`

```dart
class DownloadRepository {
  // ... 现有代码

  /// 开始下载（无状态后端版本）
  Future<void> startDownload(int taskId) async {
    // ... 并发检查逻辑

    final task = await _downloadTaskDao.getById(taskId);
    if (task == null) return;

    // 更新状态为下载中
    await _downloadTaskDao.markAsDownloading(taskId);

    // 创建取消令牌
    final cancelToken = CancelToken();
    _activeDownloads[taskId] = cancelToken;

    try {
      // 检查是否支持断点续传
      final canResume = task.downloadedBytes > 0 &&
          task.etag != null &&
          task.tempFilePath != null;

      if (canResume) {
        await _downloadWithResumable(taskId, task, cancelToken);
      } else {
        // 使用无状态后端下载
        await _downloadStateless(taskId, task, cancelToken);
      }

      // 下载完成
      await _downloadTaskDao.markAsCompleted(taskId);

    } catch (e) {
      if (cancelToken.isCancelled) {
        await _downloadTaskDao.markAsPaused(taskId);
      } else {
        await _downloadTaskDao.markAsFailed(taskId, errorMessage: e.toString());
      }
    } finally {
      _activeDownloads.remove(taskId);
      _processQueue();
    }
  }

  /// 无状态后端下载（直接获取文件）
  Future<void> _downloadStateless(
    int taskId,
    DownloadTask task,
    CancelToken cancelToken,
  ) async {
    final url = _bilibiliApi.getDownloadUrl(task.bvid!);

    final response = await _dioClient.dio.get(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
      ),
      cancelToken: cancelToken,
    );

    // 保存文件
    final file = File(task.savePath);
    await file.writeAsBytes(response.data);
  }

  /// 暂停下载（无状态版本）
  Future<void> pauseDownload(int taskId) async {
    final task = await _downloadTaskDao.getById(taskId);
    if (task == null) return;

    // 幂等性检查
    if (task.status == DownloadStatus.paused ||
        task.status == DownloadStatus.completed) {
      return;
    }

    // 从队列移除
    _pendingQueue.remove(taskId);

    // 取消本地下载（无需通知后端）
    final cancelToken = _activeDownloads[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('用户暂停');
      _activeDownloads.remove(taskId);
    }

    // 更新数据库状态
    await _downloadTaskDao.markAsPaused(taskId);
  }
}
```

### 5.4 迁移步骤

1. **后端**：添加新的 `downloadAudioStateless` 接口，保留旧接口兼容
2. **前端**：添加 `_downloadStateless` 方法，优先使用新接口
3. **测试**：验证下载、暂停、恢复、崩溃恢复功能
4. **清理**：确认稳定后移除旧接口和 `downloadTaskStore.js`

---

## 六、架构优化建议

### 6.1 创建 DownloadExecutor 类

将状态管理（Repository）与执行逻辑（Executor）分离：

```dart
/// 下载执行器 - 负责实际下载操作的执行
class DownloadExecutor {
  final Map<int, CancelToken> _activeDownloads = {};
  final DownloadSlotManager _slotManager;

  DownloadExecutor({int maxConcurrent = 3})
      : _slotManager = DownloadSlotManager(maxSlots: maxConcurrent);

  /// 执行下载任务
  Future<void> execute(
    DownloadTask task, {
    required void Function(int current, int total, int percent) onProgress,
    required void Function() onComplete,
    required void Function(Object error) onError,
  }) async {
    // 检查槽位
    if (!_slotManager.occupySlot(task.id!)) {
      onError(Exception('无可用下载槽位'));
      return;
    }

    // 创建取消令牌
    final cancelToken = CancelToken();
    _activeDownloads[task.id!] = cancelToken;

    try {
      // 执行实际下载
      await _downloadWithCancel(task, cancelToken, onProgress);
      onComplete();
    } catch (e) {
      onError(e);
    } finally {
      _activeDownloads.remove(task.id);
      _slotManager.releaseSlot(task.id!);
    }
  }

  /// 取消任务
  void cancel(int taskId) {
    _activeDownloads[taskId]?.cancel();
    // 暂停时保留槽位
    _slotManager.reserveSlot(taskId);
  }

  /// 恢复任务
  bool restore(int taskId) {
    return _slotManager.restoreSlot(taskId);
  }

  /// 检查任务是否在执行
  bool isActive(int taskId) => _activeDownloads.containsKey(taskId);

  /// 获取活跃任务列表
  List<int> get activeTasks => _activeDownloads.keys.toList();

  /// 获取活跃任务数量
  int get activeCount => _activeDownloads.length;

  void dispose() {
    for (final token in _activeDownloads.values) {
      token.cancel();
    }
    _activeDownloads.clear();
    _slotManager.clear();
  }
}
```

### 6.2 Repository 使用 Executor

```dart
class DownloadRepository {
  final DownloadTaskDao _downloadTaskDao;
  final DownloadExecutor _executor;

  DownloadRepository({
    DownloadTaskDao? downloadTaskDao,
    DownloadExecutor? executor,
  }) : _downloadTaskDao = downloadTaskDao ?? DownloadTaskDao(AppDatabase.instance),
       _executor = executor ?? DownloadExecutor();

  Future<void> startDownload(int taskId) async {
    final task = await _downloadTaskDao.getById(taskId);
    if (task == null) return;

    // 更新状态
    await _downloadTaskDao.markAsDownloading(taskId);

    // 执行下载
    await _executor.execute(
      task,
      onProgress: (current, total, percent) async {
        await _downloadTaskDao.updateProgress(taskId, current, total);
        _progressController.add(DownloadProgressEvent(
          taskId: taskId,
          progress: percent,
        ));
      },
      onComplete: () async {
        await _downloadTaskDao.markAsCompleted(taskId);
        _progressController.add(/* 完成事件 */);
      },
      onError: (error) async {
        await _downloadTaskDao.markAsFailed(taskId, errorMessage: error.toString());
        _progressController.add(/* 错误事件 */);
      },
    );
  }

  Future<void> pauseDownload(int taskId) async {
    // 取消执行（保留槽位）
    _executor.cancel(taskId);
    // 更新数据库
    await _downloadTaskDao.markAsPaused(taskId);
  }

  Future<void> resumeDownload(int taskId) async {
    // 恢复槽位
    if (!_executor.restore(taskId)) {
      throw Exception('无法恢复任务：槽位不足');
    }
    // 重新开始
    await startDownload(taskId);
  }
}
```

---

## 七、检查清单

### 7.1 开发修复检查清单

**P0 - 必须立即修复**
- [ ] 实现改进的 `_resumeIncompleteTasks` 方法（含文件校验）
- [ ] 实现幂等的 `pauseDownload` 方法（含超时机制）
- [ ] 实现 `rebuildState` 方法用于内存重建

**P1 - 本周完成**
- [ ] 添加状态机验证到 `DownloadTaskDao`（强制阻断）
- [ ] 添加文件完整性校验
- [ ] 实现临时文件清理机制
- [ ] 实现超时任务清理机制
- [ ] 添加 `getIncompleteTasks` 方法到 DAO
- [ ] 添加 `updateDownloadedBytes` 方法到 Repository
- [ ] 添加 `resetTaskStatus` 方法到 Repository
- [ ] 添加 `markAsFailed` 方法到 Repository

**P2 - 下阶段优化**
- [ ] 实现 `DownloadSlotManager` 槽位管理器
- [ ] 实现无状态后端改造
- [ ] 实现 `DownloadExecutor` 分离
- [ ] 更新 ViewModel 调用 `rebuildState` 在 build 方法中

### 7.2 用户体验检查清单

| 场景 | 检查项 | 验证方法 |
|------|--------|----------|
| 冷启动 | 列表状态与文件实际一致 | 手动删除 .tmp 文件，看应用是否识别为错误 |
| 快速操作 | 连续点击暂停/开始无异常 | 快速点击 10 次，检查是否死锁 |
| 网络切换 | WiFi 切 4G 时状态正确 | 飞行模式切换，观察状态流转 |
| 大文件 | 进度条不卡顿 | 下载 1GB 文件，观察帧率 |
| 后台保活 | 10 分钟后进度准确 | 切后台 10 分钟，对比前后进度 |
| 并发下载 | 多任务状态独立 | 同时下载 5 个，暂停第 3 个，其他不受影响 |
| 异常恢复 | 杀进程后重启可续传 | 下载到 50% 杀进程，重启看能否从 50% 继续 |
| 后端重启 | 后端重启后下载可继续 | 下载中途重启后端，验证前端行为 |
| 槽位管理 | 暂停/恢复不超并发 | 暂停任务A，开始任务B，恢复A，验证并发数 |

### 7.3 测试覆盖建议

| 测试类型 | 测试场景 |
|----------|----------|
| 单元测试 | 状态机所有转换路径 |
| 单元测试 | SlotManager 槽位占用/释放/预留/恢复 |
| 集成测试 | 前后端重启后的状态同步 |
| 集成测试 | 文件完整性校验逻辑 |
| 压力测试 | 100+ 任务并发创建/暂停/恢复 |
| 异常测试 | 网络中断、磁盘满、权限被拒绝 |

---

## 八、实施优先级

```
┌─────────────────────────────────────────────────────────────┐
│  P0（立即修复）- 崩溃恢复基础                               │
│  ✓ _resumeIncompleteTasks 改进（含文件校验）                │
│  ✓ pauseDownload 幂等性（含超时机制）                       │
│  ✓ rebuildState 内存重建                                    │
├─────────────────────────────────────────────────────────────┤
│  P1（本周完成）- 数据一致性                                │
│  ✓ 状态机验证（强制阻断）                                   │
│  ✓ 文件完整性校验                                           │
│  ✓ .tmp 文件清理机制                                        │
│  ✓ 超时任务自动标记失败                                     │
│  ✓ 操作超时机制                                             │
├─────────────────────────────────────────────────────────────┤
│  P1.5（本迭代完成）- 架构改进                              │
│  ○ 后端无状态改造（推荐优先）                               │
│  ○ DownloadSlotManager 槽位管理                            │
├─────────────────────────────────────────────────────────────┤
│  P2（下阶段优化）- 长期优化                                │
│  ○ DownloadExecutor 分离                                   │
│  ○ 完整的 Result<T> 返回模式                               │
│  ○ 单元测试覆盖                                             │
└─────────────────────────────────────────────────────────────┘
```

**关键变更**：将"后端无状态改造"从 P2 提升至 P1.5，因为这是治本之策。

---

## 九、总结

### 9.1 当前问题

1. **状态不一致**：前端内存状态、数据库状态、后端内存状态三者不同步
2. **缺少幂等性**：暂停/恢复操作没有检查当前状态，导致重复操作失效
3. **恢复逻辑缺陷**：只恢复 `pending` 任务，忽略了 `paused` 和 `downloading` 状态
4. **缺少状态机验证**：允许非法的状态转换
5. **并发控制泄漏**：槽位管理不准确，暂停/恢复可能导致超并发
6. **后端状态丢失**：后端内存存储，重启后所有状态失效

### 9.2 核心改进

| 问题 | 解决方案 | 文件 |
|------|----------|------|
| 崩溃恢复 | 文件校验 + 多状态恢复 | download_viewmodel.dart |
| 幂等性 | 状态预检 + 超时机制 | download_repository.dart |
| 非法转换 | 强制阻断 + 异常抛出 | download_task_dao.dart |
| 槽位泄漏 | SlotManager 分离管理 | download_slot_manager.dart |
| 孤立文件 | 启动清理机制 | download_repository.dart |
| 后端状态 | 无状态后端改造 | bilibiliController.js |

### 9.3 长期价值

通过实施 v2.0 方案，下载系统将具备：
- **健壮性**：崩溃、重启、网络中断均可正确恢复
- **可维护性**：状态机、槽位管理、执行器分离，职责清晰
- **可测试性**：无状态后端，前端状态可预测，易于测试
- **用户体验**：操作响应一致，进度准确，无数据丢失

---

## 附录：评审意见响应

| 评审意见 | 响应 |
|----------|------|
| 后端状态持久化缺失 | 新增第五章"后端架构优化方案"，推荐无状态后端 |
| 并发控制细节不足 | 新增 4.5 节"槽位管理器"，解决槽位泄漏 |
| 文件验证逻辑有漏洞 | 4.2 节增强文件校验，添加大小一致性检查 |
| 缺少清理机制 | 新增 4.6 节"临时文件清理机制" |
| 状态机验证应强制阻断 | 4.4 节改为抛出异常，强制阻断非法转换 |
| 添加操作超时机制 | 4.3 节添加 .timeout() 处理后端超时 |
| 测试覆盖建议 | 新增 7.3 节"测试覆盖建议" |
