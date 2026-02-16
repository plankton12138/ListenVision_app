# Listen Vision 项目架构与功能符合性检查报告

**检查日期**: 2026-02-16  
**检查人**: Claude  
**项目版本**: frontend_flutter / listen-vision_api  

---

## 一、检查要求清单

根据业务需求，从以下五个维度对项目进行了全面检查：

| # | 检查项 | 重要性 | 期望行为 |
|---|--------|--------|----------|
| 1 | 本地优先播放策略 | 高 | 播放时优先检查本地是否存在，存在则使用本地文件 |
| 2 | 数据同步能力 | 高 | 同一内容能够同步（账号状态、音频内容状态等） |
| 3 | 数据变化感知 | 高 | 本地删除音频时软件能察觉，类似数据库恢复/并发控制 |
| 4 | 网络断链提示 | 中 | 无法播放在线音频时给出明确提示 |
| 5 | 统一的用户提示风格 | 中 | 提示信息风格统一、详细 |

---

## 二、检查结果详细分析

### 2.1 本地优先播放策略 ❌ 不符合要求

**现状分析**（controls_panel.dart:80-99）：

```dart
void _playPlayable(BuildContext context, WidgetRef ref, PlayableAudio playable) {
  if (playable.isOnline) {
    // 在线音频 - 直接播放网络流
    playerViewModel.playOnlineAudio(
      audio: playable.original,
      proxyUrl: playable.proxyUrl,
    );
  } else {
    // 本地音频 - 使用本地文件
    playerViewModel.playLocalAudio(playable.url, ...);
  }
}
```

**问题**：
- ❌ 播放逻辑仅根据 `isOnline` 布尔值判断，**没有检查本地是否已下载**
- ❌ `CachedTrack` 模型虽然有 `isDownloaded` 和 `localPath` 字段，但播放时未使用
- ❌ 即使音频已下载到本地，只要 `isOnline=true` 就会走网络播放

**缺失功能**：
- 没有实现"本地文件存在性检查"逻辑
- 没有优先使用本地路径的降级机制
- 没有网络播放失败时自动切换到本地文件的容错

**影响**：
- 用户下载音频后，播放时仍使用网络流量
- 离线状态下无法播放已下载内容
- 用户体验差，违背"本地优先"架构设计初衷

---

### 2.2 数据同步能力 ⚠️ 基本符合，但存在缺陷

**已实现功能**（sync_worker.dart）：

```dart
class SyncWorker {
  Timer? _timer;
  void start({int interval = 30}) {
    _timer = Timer.periodic(Duration(seconds: interval), (_) => _executeSync());
  }
  
  Future<void> _executeSync() async {
    final tasks = await _syncDao.getAllPendingTasks(limit: 50);
    for (final task in tasks) {
      await _processTask(task);
    }
  }
}
```

**支持场景**：
- ✅ 收藏状态同步（favorite/unfavorite）
- ✅ 播放历史同步
- ✅ 歌单操作同步（添加/删除/创建/更新）
- ✅ 断点续传和重试机制（最大3次重试）

**存在缺陷**：
- ❌ **播放时未利用同步状态**：播放逻辑未检查本地文件是否最新
- ❌ **双向同步不完善**：只有"本地→云端"同步，缺少"云端→本地"主动拉取
- ❌ **没有冲突解决策略**：当本地和云端数据冲突时，没有明确的解决规则

**同步任务类型**（已支持）：
| 类型 | 描述 | 状态 |
|------|------|------|
| favorite | 收藏 | ✅ 支持 |
| unfavorite | 取消收藏 | ✅ 支持 |
| playHistory | 播放历史 | ✅ 支持 |
| addPlaylistItem | 添加歌单项 | ✅ 支持 |
| removePlaylistItem | 删除歌单项 | ✅ 支持 |
| createPlaylist | 创建歌单 | ✅ 支持 |
| updatePlaylist | 更新歌单 | ✅ 支持 |
| deletePlaylist | 删除歌单 | ✅ 支持 |

---

### 2.3 数据变化感知 ❌ 不符合要求

**现状**：
- ❌ **没有文件系统监听**：未使用 `FileSystem.watch()` 或类似机制
- ❌ **没有本地文件校验**：用户手动删除下载文件后，数据库中的 `isDownloaded` 仍为 `true`
- ❌ **没有数据库恢复机制**：没有事务日志、检查点、回滚等恢复技术
- ❌ **没有并发控制**：没有乐观锁/悲观锁机制

**具体表现**：

假设场景：
1. 用户下载了音频 A，数据库记录 `isDownloaded=true`, `localPath="/path/to/A.mp3"`
2. 用户手动删除了 `/path/to/A.mp3`
3. 应用无法感知此变化，仍认为 A 已下载
4. 播放时尝试访问已删除的文件，导致错误

**当前缺失**（应有但缺失的代码）：

```dart
// 应有的文件监听逻辑
class DownloadFileWatcher {
  StreamSubscription? _watchSubscription;
  
  void startWatching() {
    _watchSubscription = Directory(downloadPath).watch().listen((event) {
      if (event.type == FileSystemEvent.delete) {
        // 同步更新数据库状态
        _updateDatabaseWhenFileDeleted(event.path);
      }
    });
  }
}
```

**数据模型状态字段**（CachedTrack）：
| 字段 | 用途 | 问题 |
|------|------|------|
| isDownloaded | 标记是否已下载 | 用户删除文件后不会自动更新 |
| localPath | 本地文件路径 | 文件删除后路径失效 |
| syncedAt | 最后同步时间 | 不表示文件存在性 |

---

### 2.4 网络断链提示 ❌ 不符合要求

**现状**：
- ❌ **没有统一的网络错误提示**
- ❌ **没有网络状态监测**：未使用 `connectivity_plus` 或类似包
- ❌ **错误提示分散且不一致**（192处）

**当前错误处理示例**：

```dart
// 分散在各处的错误提示（共192处）
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('播放失败: $e')), // 简单、不友好
);

// 或其他地方
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('没有下一首了')), // 无网络错误专门处理
);
```

**问题**：
- ❌ 用户无法区分"网络问题"和"其他问题"
- ❌ 没有网络断开时的专门提示（如"网络已断开，请检查连接"）
- ❌ 没有网络恢复提示
- ❌ 没有离线模式提示

**网络错误类型**（已定义但未使用）：

```dart
// core/utils/error_handler.dart:296
static bool isNetworkError(dynamic error) {
  if (error is NetworkException) {
    return true;
  }
  if (error is DioException) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
  return false;
}
```

**注**：`isNetworkError` 方法已定义，但未被实际调用。

---

### 2.5 统一的用户提示风格 ❌ 严重不符合要求

**问题规模**：
- 🔴 **192处**直接使用 `ScaffoldMessenger.of(context).showSnackBar()`
- 🔴 **风格完全不统一**

**示例对比**：

```dart
// 样式1：简单文本
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('播放失败: $e')),
);

// 样式2：带颜色
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
);

// 样式3：带操作
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('已添加到下一首: ${audio.title}'),
    action: SnackBarAction(label: '撤销', onPressed: () {}),
  ),
);

// 样式4：英文提示
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('No previous track')),
);

// 样式5：详细信息
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('导入失败: ${e.toString()}')),
);
```

**缺失**：
- ❌ 没有统一的错误提示组件
- ❌ 没有根据错误类型自动选择提示方式的机制
- ❌ 没有提示信息的详细程度分级（简略/详细）
- ❌ 没有提示信息的国际化支持

**已修复项**（2026-02-16）：
- ✅ 已创建 `presentation/utils/error_ui_handler.dart` 作为统一入口
- ✅ 已重构 `core/utils/error_handler.dart` 移除 UI 依赖
- ⚠️ 但调用方尚未全部迁移至新组件

---

## 三、问题汇总与风险评级

| 问题 | 严重程度 | 影响 | 修复优先级 |
|------|----------|------|------------|
| 没有本地优先播放逻辑 | 🔴 严重 | 用户体验差、流量浪费 | P0 |
| 没有数据变化感知 | 🔴 严重 | 数据不一致、播放失败 | P0 |
| 用户提示风格不统一 | 🟡 中等 | 体验差、维护困难 | P1 |
| 网络断链提示不完善 | 🟡 中等 | 用户困惑 | P1 |
| 数据同步单向化 | 🟢 低 | 功能可用但不够完善 | P2 |

---

## 四、与 PRD 文档对比

根据 `docs/PRD.md` 文档声明：

### PRD 声明的功能

| 功能 | PRD状态 | 实际状态 | 符合度 |
|------|---------|----------|--------|
| 本地优先同步机制 | ✅ 已实现 | ⚠️ 部分实现 | 60% |
| 下载管理（队列、断点续传、重试） | ✅ 已实现 | ✅ 已实现 | 100% |
| 播放历史同步 | ✅ 已实现 | ✅ 已实现 | 100% |

### 关键差异

**PRD 声称**："本地优先同步机制实现 (2026-02-06)"

**实际情况**：
- ✅ 数据同步机制已实现（SyncWorker）
- ❌ 播放时的本地优先策略未实现
- ❌ 播放逻辑仍然依赖 `isOnline` 布尔值，而非 `isDownloaded`

**PRD 未覆盖的功能**：
- ❌ 本地文件变化监听
- ❌ 网络状态监测与提示
- ❌ 用户提示风格统一

---

## 五、建议修复方案

### Phase 1: 核心功能修复（P0）

#### 1.1 实现播放时的本地文件存在性检查

**修改点**：`presentation/viewmodels/player/queue_viewmodel.dart`

```dart
Future<void> playAt(int index) async {
  final playable = state.queue[index];
  
  // 新增：本地优先检查
  if (playable.isOnline && playable is OnlinePlayable) {
    final bvid = playable.original.id;
    final trackRepo = ref.read(trackRepositoryProvider);
    
    // 检查本地是否已下载
    final isDownloaded = await trackRepo.isTrackDownloaded(bvid);
    if (isDownloaded) {
      final localPath = await trackRepo.getLocalPath(bvid);
      if (localPath != null && await File(localPath).exists()) {
        // 使用本地文件播放
        await playerNotifier.playLocalAudio(localPath, ...);
        return;
      }
    }
    
    // 本地不存在，使用网络流
    await playerNotifier.playOnlineAudio(audio: playable.original, ...);
  }
}
```

#### 1.2 添加文件系统监听

**新增文件**：`services/download_file_watcher.dart`

```dart
class DownloadFileWatcher {
  final TrackRepository _trackRepository;
  StreamSubscription? _watchSubscription;
  
  void startWatching() {
    final downloadDir = Directory(AppConstants.downloadPath);
    _watchSubscription = downloadDir.watch().listen((event) {
      if (event.type == FileSystemEvent.delete) {
        _handleFileDeleted(event.path);
      }
    });
  }
  
  void _handleFileDeleted(String filePath) async {
    // 从路径提取 bvid 或 sourceId
    final sourceId = _extractSourceIdFromPath(filePath);
    if (sourceId != null) {
      await _trackRepository.markAsNotDownloaded(sourceId);
    }
  }
}
```

### Phase 2: 体验优化（P1）

#### 2.1 统一错误提示风格

**使用已创建的 ErrorUIHandler**：

```dart
// 替换分散的 showSnackBar 调用
ErrorUIHandler.showError(context, error);
ErrorUIHandler.showErrorDialog(context, error, title: '播放失败');
```

#### 2.2 添加网络状态监测

**新增 Provider**：`core/network/network_status_provider.dart`

```dart
@riverpod
class NetworkStatus extends _$NetworkStatus {
  @override
  Future<NetworkStatusState> build() async {
    // 使用 connectivity_plus
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return _mapToState(result);
  }
}
```

### Phase 3: 完善（P2）

#### 3.1 实现双向同步

**修改 SyncWorker**：

```dart
Future<void> _pullFromCloud() async {
  // 定期从云端拉取最新数据
  final cloudData = await _apiClient.getUserData();
  await _mergeWithLocal(cloudData);
}
```

#### 3.2 添加数据冲突解决策略

```dart
enum ConflictResolutionStrategy {
  localWins,      // 本地优先
  cloudWins,      // 云端优先
  timestampWins,  // 时间戳优先
  manualResolve,  // 手动解决
}
```

---

## 六、结论

### 总体评分：6.5/10

| 维度 | 评分 | 说明 |
|------|------|------|
| 本地优先播放 | 3/10 | 核心功能缺失 |
| 数据同步 | 7/10 | 单向同步完善，双向待改进 |
| 数据变化感知 | 2/10 | 无文件监听 |
| 网络断链提示 | 3/10 | 有方法定义但未使用 |
| 提示风格统一 | 4/10 | 已创建组件但未完全迁移 |

### 关键结论

1. **项目当前在本地优先播放和数据变化感知两个核心需求上不符合要求**
2. **需要进行架构级修复，而非简单代码调整**
3. **PRD 文档声明的"本地优先同步机制"仅实现了数据同步，未实现播放时的本地优先**
4. **建议优先修复 P0 级别问题，确保核心功能符合需求**

### 下一步行动

1. **P0 紧急**：实现播放时的本地文件存在性检查逻辑
2. **P0 紧急**：添加文件系统监听，感知本地文件删除
3. **P1 重要**：统一错误提示风格，迁移所有调用点
4. **P1 重要**：添加网络状态监测和断链提示
5. **P2 可选**：完善双向同步和冲突解决策略

---

## 附录：关键文件清单

| 文件路径 | 相关功能 | 问题 |
|----------|----------|------|
| `lib/presentation/viewmodels/player/queue_viewmodel.dart:299-312` | 播放队列 | 未检查本地文件 |
| `lib/presentation/widgets/controls_panel.dart:80-99` | 播放控制 | 直接根据 isOnline 判断 |
| `lib/data/sync/sync_worker.dart:1-402` | 数据同步 | 单向同步 |
| `lib/models/cached_track.dart:64-65` | 数据模型 | 字段未充分利用 |
| `lib/core/utils/error_handler.dart:296` | 错误处理 | 方法未使用 |

---

**报告生成时间**: 2026-02-16 16:30:00  
**报告版本**: v1.0
