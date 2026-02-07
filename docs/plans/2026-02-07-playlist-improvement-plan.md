# 播放列表改进计划

**创建日期**: 2026-02-07
**更新日期**: 2026-02-07
**状态**: ✅ 已完成
**优先级**: P0（核心体验改进）
**整体进度**: 100% (4/4 Phase 完成)

**关联文档**: [播放列表设计方案](../reports/playlist-design-spec.md)

---

## 总体进度

| 阶段 | 任务 | 优先级 | 状态 | 完成日期 |
|------|------|--------|------|----------|
| Phase 1 | 基础修复 | 🔴 P0 | ✅ 已完成 | 2026-02-07 |
| Phase 2 | 底部弹窗 + Tab | 🔴 P0 | ✅ 已完成 | 2026-02-07 |
| Phase 3 | 歌单集成 + 来源显示 | 🟡 P1 | ✅ 已完成 | 2026-02-07 |
| Phase 4 | 高级功能 | 🟢 P2 | ✅ 已完成 | 2026-02-07 |

---

## 一、背景分析

### 1.1 当前问题

| 问题 | 根因 | 影响 |
|------|------|------|
| 播放队列入口单一 | 仅右下角按钮 | 用户难以找到 |
| 点击歌单歌曲不替换队列 | 未实现自动替换 | 每次播放都是单首 |
| 播放列表为独立页面 | 全屏页面跳转 | 打断用户操作流程 |
| 启动时无法恢复队列 | 未持久化来源信息 | 用户体验不连贯 |
| 队列来源不可见 | 未记录歌单来源 | 用户不知道当前队列来自哪里 |

### 1.2 参考设计

- **QQ音乐**: 底部弹窗 + Tab切换 + 时间分组
- **Spotify**: Next Up 队列 + 插队播放
- **网易云音乐**: 简洁的队列管理

---

## 二、架构设计

### 2.1 新增数据模型

```
models/
├── queue_source.dart        # 队列来源模型
├── play_mode.dart            # 播放模式枚举
└── history_group.dart        # 历史分组模型
```

### 2.2 新增组件

```
presentation/widgets/player/
├── queue_bottom_sheet.dart   # 底部弹窗组件
├── queue_tab_view.dart       # 正在播放 Tab
├── history_tab_view.dart     # 播放历史 Tab
└── queue_item_tile.dart      # 队列列表项组件
```

### 2.3 数据流

```
用户操作 → QueueViewModel → 状态更新 → UI刷新
                ↓
         持久化存储（SharedStorageService）
                ↓
         启动时恢复
```

---

## Phase 1: 基础修复

**目标**: 修复当前播放列表的核心问题，使其能够正常工作

**预计时间**: 1-2天

### 1.1 任务清单

| # | 任务 | 文件 | 说明 |
|---|------|------|------|
| 1.1 | 修复播放列表显示 | `views/player/play_list_page.dart` | 显示 `queue` 而非 `localAudios` |
| 1.2 | 实现 playAll() | `viewmodels/library/playlist_detail_viewmodel.dart` | 播放全部功能，返回 `Future<bool>` 便于页面显示加载状态 |
| 1.3 | 实现点击单首播放 | `viewmodels/library/playlist_detail_viewmodel.dart` | 点击歌曲替换队列，返回 `Future<bool>` |
| 1.4 | 实现启动恢复 | `viewmodels/player/queue_viewmodel.dart` | 恢复上次队列 |

### 1.2 详细设计

#### 1.2.1 修复播放列表显示

**文件**: `views/player/play_list_page.dart`

**当前代码**:
```dart
final queue = queueState.localAudios;  // ❌ 错误
```

**修改为**:
```dart
final queue = queueState.queue;  // ✅ 正确
final currentIndex = queueState.currentIndex;
```

#### 1.2.2 实现 playAll()

**文件**: `viewmodels/library/playlist_detail_viewmodel.dart`

```dart
/// 播放全部
///
/// 返回 Future<bool> 便于页面显示加载状态：
/// ```dart
/// onPressed: () async {
///   final success = await viewModel.playAll();
///   if (!success) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       const SnackBar(content: Text('播放失败')),
///     );
///   }
/// }
/// ```
Future<bool> playAll() async {
  final items = state.valueOrNull?.maybeWhen(
    loaded: (_, items, __) => items,
    orElse: () => null,
  );
  if (items == null || items.isEmpty) return false;

  AppLogger.info('PlaylistDetailViewModel', '播放全部: ${items.length}首');

  // 构建队列
  final queue = items.map((item) => OnlinePlayable(
    bvid: item.bvid,
    title: item.title ?? '',
    artist: item.uploaderName,
    coverUrl: item.coverUrl,
  )).toList();

  // 获取歌单信息
  final playlist = state.valueOrNull?.maybeWhen(
    loaded: (playlist, _, __) => playlist,
    orElse: () => null,
  );

  // TODO: 记录队列来源（Phase 3）
  // 替换队列
  await ref.read(queueViewModelProvider.notifier).setQueue(
    queue,
    initialIndex: 0,
  );

  // 开始播放
  ref.read(playerViewModelProvider.notifier).loadAndPlay(queue.first);

  return true;
}
```

#### 1.2.3 实现点击单首播放

```dart
/// 点击单首歌曲播放
///
/// 返回 Future<bool> 便于页面显示加载状态：
/// ```dart
/// onTap: () async {
///   final success = await viewModel.playItem(item.bvid);
///   if (!success) {
///     // 处理失败情况
///   }
/// }
/// ```
Future<bool> playItem(String bvid) async {
  final items = state.valueOrNull?.maybeWhen(
    loaded: (_, items, __) => items,
    orElse: () => null,
  );
  if (items == null || items.isEmpty) return false;

  // 找到当前点击歌曲的索引
  final startIndex = items.indexWhere((item) => item.bvid == bvid);
  if (startIndex == -1) return false;

  AppLogger.info('PlaylistDetailViewModel', '播放歌曲: bvid=$bvid, 索引=$startIndex');

  // 构建队列（从当前歌曲开始）
  final queue = items
    .sublist(startIndex)
    .map((item) => OnlinePlayable(
      bvid: item.bvid,
      title: item.title ?? '',
      artist: item.uploaderName,
      coverUrl: item.coverUrl,
    ))
    .toList();

  // 替换队列
  await ref.read(queueViewModelProvider.notifier).setQueue(
    queue,
    initialIndex: 0,
  );

  // 开始播放
  ref.read(playerViewModelProvider.notifier).loadAndPlay(queue.first);

  return true;
}
```

#### 1.2.4 启动恢复机制

**文件**: `viewmodels/player/queue_viewmodel.dart`

已有 `_loadFromStorage()` 方法，确保在 `build()` 中调用：

```dart
@override
QueueState build() {
  _storage = ref.watch(sharedStorageServiceProvider);

  // 延迟初始化
  Future.microtask(_init);

  return const QueueState();
}

Future<void> _init() async {
  try {
    await _loadFromStorage();
    AppLogger.info('QueueViewModel', '初始化完成，队列长度: ${state.queue.length}');
  } catch (e) {
    AppLogger.error('QueueViewModel', '初始化失败: $e');
  }
}
```

### 1.3 UI 使用示例

在歌单详情页面中调用 `playAll()` 和 `playItem()`：

```dart
// 播放全部按钮
FloatingActionButton.extended(
  onPressed: () async {
    // 显示加载状态
    final viewModel = ref.read(playlistDetailViewModelProvider.notifier);

    // 调用播放方法
    final success = await viewModel.playAll();

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('播放失败，请重试')),
      );
    }
  },
  icon: const Icon(Icons.play_arrow),
  label: const Text('播放全部'),
)

// 单首歌曲点击
onTap: () async {
  final viewModel = ref.read(playlistDetailViewModelProvider.notifier);

  final success = await viewModel.playItem(item.bvid);

  if (!success && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('播放失败，请重试')),
    );
  }
},
```

### 1.4 验收标准

- [ ] 播放列表页面显示混合队列（在线+本地）
- [ ] 歌单详情页"播放全部"按钮正常工作，有加载状态反馈
- [ ] 点击歌单中单首歌曲，队列替换为该歌曲及后续歌曲
- [ ] App 重启后恢复上次播放队列
- [ ] 播放失败时显示错误提示

---

## Phase 2: 底部弹窗 + Tab

**目标**: 将独立页面改为底部弹窗，集成播放历史

**预计时间**: 2-3天

### 2.1 任务清单

| # | 任务 | 新建/修改 | 说明 |
|---|------|----------|------|
| 2.1 | 创建 QueueSource 模型 | 新建 `models/queue_source.dart` | 队列来源模型 |
| 2.2 | 创建 PlayMode 枚举 | 新建 `models/play_mode.dart` | 播放模式 |
| 2.3 | 创建 HistoryGroup 模型 | 新建 `models/history_group.dart` | 历史分组 |
| 2.4 | 创建底部弹窗组件 | 新建 `widgets/player/queue_bottom_sheet.dart` | 主弹窗 |
| 2.5 | 创建正在播放 Tab | 新建 `widgets/player/queue_tab_view.dart` | 队列列表 |
| 2.6 | 创建播放历史 Tab | 新建 `widgets/player/history_tab_view.dart` | 历史列表 |
| 2.7 | 添加双入口 | 修改 `views/player/home_page.dart` | 歌曲信息区 + 右下角 |

### 2.2 详细设计

#### 2.2.1 QueueSource 模型

**文件**: `models/queue_source.dart`

```dart
/// 队列来源类型
enum SourceType {
  userPlaylist,   // 用户歌单
  favorites,      // 收藏
  history,        // 播放历史
  search,         // 搜索结果
  manual,         // 手动添加
}

/// 队列来源
class QueueSource {
  final String id;
  final String name;
  final String? coverUrl;
  final SourceType type;

  const QueueSource({
    required this.id,
    required this.name,
    this.coverUrl,
    required this.type,
  });

  /// 用户歌单
  factory QueueSource.userPlaylist(String id, String name, {String? coverUrl}) {
    return QueueSource(
      id: id,
      name: name,
      coverUrl: coverUrl,
      type: SourceType.userPlaylist,
    );
  }

  /// 收藏
  factory QueueSource.favorites() {
    return const QueueSource(
      id: 'favorites',
      name: '我喜欢的音乐',
      type: SourceType.favorites,
    );
  }

  /// 播放历史
  factory QueueSource.history() {
    return const QueueSource(
      id: 'history',
      name: '播放历史',
      type: SourceType.history,
    );
  }

  /// 搜索结果
  factory QueueSource.search(String query) {
    return QueueSource(
      id: 'search_$query',
      name: '搜索: $query',
      type: SourceType.search,
    );
  }

  /// 手动添加
  factory QueueSource.manual() {
    return const QueueSource(
      id: 'manual',
      name: '手动添加',
      type: SourceType.manual,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverUrl': coverUrl,
      'type': type.name,
    };
  }

  factory QueueSource.fromJson(Map<String, dynamic> json) {
    return QueueSource(
      id: json['id'] as String,
      name: json['name'] as String,
      coverUrl: json['coverUrl'] as String?,
      type: SourceType.values.firstWhere(
        (e) => e.name == json['type'] as String?,
        orElse: () => SourceType.manual,
      ),
    );
  }
}
```

#### 2.2.2 PlayMode 枚举

**文件**: `models/play_mode.dart`

```dart
/// 播放模式
enum PlayMode {
  sequence,     // 顺序播放
  loopAll,      // 列表循环
  shuffle,      // 随机播放
  loopOne,      // 单曲循环
}

extension PlayModeExtension on PlayMode {
  String get displayName {
    switch (this) {
      case PlayMode.sequence:
        return '顺序';
      case PlayMode.loopAll:
        return '列表循环';
      case PlayMode.shuffle:
        return '随机';
      case PlayMode.loopOne:
        return '单曲循环';
    }
  }

  String get icon {
    switch (this) {
      case PlayMode.sequence:
        return '🔀';
      case PlayMode.loopAll:
        return '🔁';
      case PlayMode.shuffle:
        return '🔀';
      case PlayMode.loopOne:
        return '🔂';
    }
  }

  PlayMode next() {
    final values = PlayMode.values;
    final currentIndex = values.indexOf(this);
    return values[(currentIndex + 1) % values.length];
  }
}
```

#### 2.2.3 HistoryGroup 模型

**文件**: `models/history_group.dart`

```dart
import 'package:listen_vision/models/play_history.dart';

/// 播放历史分组
class HistoryGroup {
  final String label;
  final List<PlayHistory> items;

  const HistoryGroup({
    required this.label,
    required this.items,
  });

  /// 按时间分组
  static List<HistoryGroup> groupByTime(List<PlayHistory> history) {
    final now = DateTime.now();
    final groups = <String, List<PlayHistory>>{};

    for (final item in history) {
      final diff = now.difference(item.playedAt);
      String key;

      if (diff.inMinutes < 60) {
        key = '刚刚';
      } else if (item.playedAt.day == now.day &&
                 item.playedAt.month == now.month &&
                 item.playedAt.year == now.year) {
        key = '今天';
      } else if (item.playedAt.day == now.day - 1 &&
                 item.playedAt.month == now.month &&
                 item.playedAt.year == now.year) {
        key = '昨天';
      } else {
        key = '${item.playedAt.year}年${item.playedAt.month}月${item.playedAt.day}日';
      }

      groups.putIfAbsent(key, () => []).add(item);
    }

    // 定义排序顺序
    final order = ['刚刚', '今天', '昨天'];

    return groups.entries.toList()
      ..sort((a, b) {
        final aIndex = order.indexOf(a.key);
        final bIndex = order.indexOf(b.key);
        if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
        if (aIndex >= 0) return -1;
        if (bIndex >= 0) return 1;
        return b.key.compareTo(a.key);
      });
  }
}
```

#### 2.2.4 底部弹窗组件

**文件**: `widgets/player/queue_bottom_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/presentation/providers.dart';
import 'queue_tab_view.dart';
import 'history_tab_view.dart';

/// 播放列表底部弹窗
class QueueBottomSheet extends ConsumerStatefulWidget {
  const QueueBottomSheet({super.key});

  /// 显示弹窗
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QueueBottomSheet(),
    );
  }

  @override
  ConsumerState<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends ConsumerState<QueueBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // 顶部拖拽指示器
            _buildDragIndicator(theme),

            // TabBar
            _buildTabBar(context, ref),

            // TabView
            Expanded(
              child: TabBarView(
                children: [
                  QueueTabView(scrollController: scrollController),
                  HistoryTabView(scrollController: scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragIndicator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueViewModelProvider);
    final historyState = ref.watch(historyViewModelProvider);

    final historyCount = historyState.valueOrNull?.maybeWhen(
      loaded: (history, _) => history.length,
      orElse: () => 0,
    ) ?? 0;

    return TabBar(
      tabs: [
        Tab(text: '正在播放(${queueState.queue.length})'),
        Tab(text: '播放历史($historyCount)'),
      ],
      indicatorSize: TabBarIndicatorSize.label,
    );
  }
}
```

#### 2.2.5 正在播放 Tab

**文件**: `widgets/player/queue_tab_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 正在播放 Tab
class QueueTabView extends ConsumerWidget {
  final ScrollController? scrollController;

  const QueueTabView({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueViewModelProvider);
    final queue = queueState.queue;
    final currentIndex = queueState.currentIndex;

    if (queue.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // 来源信息（Phase 3 实现）
        // _buildSourceInfo(context, queueState.source),

        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final playable = queue[index];
              final isCurrent = currentIndex == index;

              return _buildQueueItem(
                context,
                ref,
                playable,
                index,
                isCurrent,
              );
            },
          ),
        ),

        // 底部操作栏
        _buildBottomActions(context, ref),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('播放列表为空', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    BuildContext context,
    WidgetRef ref,
    dynamic playable,
    int index,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: isCurrent
            ? Icon(Icons.play_arrow, color: theme.colorScheme.primary)
            : const Icon(Icons.music_note, color: Colors.grey),
        title: Text(
          playable.title,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(playable.artist ?? '未知艺术家'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 删除按钮
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                AppLogger.logButtonClick('删除队列项', 'QueueTabView',
                  parameters: {'index': index});
                ref.read(queueViewModelProvider.notifier).removeAt(index);
              },
            ),
          ],
        ),
        onTap: () {
          AppLogger.logButtonClick('播放队列项', 'QueueTabView',
            parameters: {'index': index});
          ref.read(queueViewModelProvider.notifier).setCurrentIndex(index);
          // TODO: 触发播放
        },
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueViewModelProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 定位按钮
          TextButton.icon(
            onPressed: () {
              // TODO: 滚动到当前播放
            },
            icon: const Icon(Icons.location_on),
            label: const Text('定位'),
          ),
          const SizedBox(width: 16),
          // 清空按钮
          TextButton.icon(
            onPressed: queueState.queue.isEmpty
                ? null
                : () {
                    _showClearConfirmDialog(context, ref);
                  },
            icon: const Icon(Icons.clear_all),
            label: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放列表'),
        content: const Text('确定要清空播放列表吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(queueViewModelProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
```

#### 2.2.6 播放历史 Tab

**文件**: `widgets/player/history_tab_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/models/history_group.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 播放历史 Tab
class HistoryTabView extends ConsumerWidget {
  final ScrollController? scrollController;

  const HistoryTabView({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyViewModelProvider);

    return historyState.when(
      initial: () => _buildEmptyState(context),
      loading: () => _buildLoadingState(),
      loaded: (history, stats) {
        if (history.isEmpty) {
          return _buildEmptyState(context);
        }

        final groups = HistoryGroup.groupByTime(history);

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: groups.length,
                itemBuilder: (context, groupIndex) {
                  final group = groups[groupIndex];
                  return _buildHistoryGroup(context, ref, group);
                },
              ),
            ),
            _buildClearHistoryButton(context, ref),
          ],
        );
      },
      error: (message) => _buildErrorState(context, message),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('暂无播放历史', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $message'),
        ],
      ),
    );
  }

  Widget _buildHistoryGroup(
    BuildContext context,
    WidgetRef ref,
    HistoryGroup group,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            group.label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),

        // 分组项
        ...group.items.map((item) => _buildHistoryItem(context, ref, item)),
      ],
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
  ) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.music_note),
      ),
      title: Text(item.audio.title),
      subtitle: Text(item.audio.artist ?? '未知艺术家'),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () {
          AppLogger.logButtonClick('添加到队列', 'HistoryTabView');
          // TODO: 添加到队列
        },
      ),
      onTap: () {
        AppLogger.logButtonClick('播放历史项', 'HistoryTabView');
        // TODO: 替换队列并播放
      },
    );
  }

  Widget _buildClearHistoryButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: FilledButton(
        onPressed: () => _showClearHistoryDialog(context, ref),
        child: const Text('清空历史记录'),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空所有播放历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(historyViewModelProvider.notifier).clearHistory();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
```

#### 2.2.7 添加双入口

**文件**: `views/player/home_page.dart`

在现有的右下角按钮基础上，添加点击歌曲信息区打开弹窗：

```dart
// 在 AudioInfo 组件外包裹 GestureDetector
GestureDetector(
  onTap: () {
    AppLogger.logButtonClick('歌曲信息区', 'HomePage',
      action: '打开播放列表');
    QueueBottomSheet.show(context);
  },
  child: const AudioInfo(),
),
```

### 2.3 验收标准

- [ ] 底部弹窗可以正常打开和关闭
- [ ] Tab 可以正常切换（正在播放 / 播放历史）
- [ ] 正在播放 Tab 显示当前队列
- [ ] 播放历史 Tab 按时间分组显示
- [ ] 点击歌曲信息区可以打开弹窗
- [ ] 右下角按钮可以打开弹窗

---

## Phase 3: 歌单集成 + 来源显示

**目标**: 记录并显示队列来源，实现上一首/下一首

**预计时间**: 2天

### 3.1 任务清单

| # | 任务 | 文件 | 说明 |
|---|------|------|------|
| 3.1 | 扩展 QueueState | `viewmodels/player/queue_viewmodel.dart` | 添加 source、playMode |
| 3.2 | 实现 setQueueFromPlaylist | `viewmodels/player/queue_viewmodel.dart` | 记录来源 |
| 3.3 | 显示来源信息 | `widgets/player/queue_tab_view.dart` | 顶部来源栏 |
| 3.4 | 来源点击跳转 | `widgets/player/queue_tab_view.dart` | 跳转歌单详情 |
| 3.5 | 实现上一首/下一首 | `widgets/controls_panel.dart` | 集成 QueueViewModel |

### 3.2 详细设计

#### 3.2.1 扩展 QueueState

**文件**: `viewmodels/player/queue_viewmodel.dart`

```dart
/// 播放队列状态
@freezed
abstract class QueueState with _$QueueState {
  /// 初始状态
  const factory QueueState({
    /// 播放队列（本地和在线混合）
    @Default([]) List<PlayableAudio> queue,

    /// 本地音频列表
    @Default([]) List<LocalAudio> localAudios,

    /// 当前播放索引
    @Default(-1) int currentIndex,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 错误消息
    String? errorMessage,

    /// 播放模式
    @Default(PlayMode.sequence) PlayMode playMode,

    /// 队列来源
    QueueSource? source,
  }) = _QueueState;
}
```

#### 3.2.2 实现 setQueueFromPlaylist

```dart
/// 设置播放队列（带来源）
Future<void> setQueueFromPlaylist(
  List<PlayableAudio> queue,
  QueueSource source, {
  int initialIndex = -1,
}) async {
  state = state.copyWith(
    queue: queue,
    currentIndex: initialIndex,
    source: source,
  );

  await _saveToStorage();
  AppLogger.info('QueueViewModel',
    '设置播放队列: ${queue.length}首, 来源: ${source.name}');
}
```

#### 3.2.3 显示来源信息

```dart
Widget _buildSourceInfo(BuildContext context, QueueState queueState) {
  final source = queueState.source;
  if (source == null) return const SizedBox.shrink();

  final theme = Theme.of(context);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.playlist_play, size: 16),
        const SizedBox(width: 8),
        Text('来自: '),
        Expanded(
          child: GestureDetector(
            onTap: () {
              // TODO: 跳转到歌单详情
            },
            child: Text(
              source.name,
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        // 播放模式切换按钮
        _buildPlayModeButton(context, queueState.playMode),
      ],
    ),
  );
}
```

#### 3.2.4 实现上一首/下一首

**文件**: `widgets/controls_panel.dart`

```dart
IconButton(
  icon: const Icon(Icons.skip_previous),
  iconSize: 45,
  onPressed: () {
    AppLogger.logButtonClick('上一首', 'ControlsPanel');
    final queueNotifier = ref.read(queueViewModelProvider.notifier);
    final previous = queueNotifier.playPrevious();
    if (previous != null) {
      ref.read(playerViewModelProvider.notifier).loadAndPlay(previous);
    }
  },
),
// ... 播放按钮
IconButton(
  icon: const Icon(Icons.skip_next),
  iconSize: 45,
  onPressed: () {
    AppLogger.logButtonClick('下一首', 'ControlsPanel');
    final queueNotifier = ref.read(queueViewModelProvider.notifier);
    final next = queueNotifier.playNext();
    if (next != null) {
      ref.read(playerViewModelProvider.notifier).loadAndPlay(next);
    }
  },
),
```

### 3.3 验收标准

- [ ] 队列来源正确显示在弹窗顶部
- [ ] 点击来源可以跳转到对应歌单
- [ ] 播放模式可以切换
- [ ] 上一首/下一首按钮正常工作
- [ ] App 重启后恢复来源信息

---

## Phase 4: 高级功能

**目标**: 实现拖拽排序、插队播放、收藏同步

**预计时间**: 2-3天

### 4.1 任务清单

| # | 任务 | 文件 | 说明 |
|---|------|------|------|
| 4.1 | 实现拖拽排序 | `widgets/player/queue_tab_view.dart` | ReorderableListView |
| 4.2 | 实现插队播放 | `viewmodels/player/queue_viewmodel.dart` | playNext() 方法 |
| 4.3 | 收藏状态同步 | `widgets/player/queue_item_tile.dart` | 集成 FavoriteViewModel |
| 4.4 | 长按菜单 | `widgets/player/queue_item_tile.dart` | 更多操作 |

### 4.2 详细设计

#### 4.2.1 拖拽排序

使用 `ReorderableListView` 或 `flutter_reorderable_list_view` 包：

```dart
ReorderableListView.builder(
  itemCount: queue.length,
  onReorder: (oldIndex, newIndex) {
    AppLogger.logButtonClick('拖拽排序', 'QueueTabView',
      parameters: {'from': oldIndex, 'to': newIndex});
    ref.read(queueViewModelProvider.notifier).reorder(oldIndex, newIndex);
  },
  itemBuilder: (context, index) {
    // 返回列表项
  },
)
```

#### 4.2.2 插队播放

**文件**: `viewmodels/player/queue_viewmodel.dart`

```dart
/// 插队播放（下一首）
Future<void> playNext(PlayableAudio playable) async {
  final newQueue = List<PlayableAudio>.from(state.queue);
  final insertIndex = state.currentIndex + 1;

  // 检查是否已存在
  final existingIndex = newQueue.indexWhere((p) => p.id == playable.id);

  if (existingIndex != -1) {
    // 已存在，先移除
    newQueue.removeAt(existingIndex);
    if (existingIndex < insertIndex) {
      insertIndex--;
    }
  }

  newQueue.insert(insertIndex, playable);

  state = state.copyWith(queue: newQueue);
  await _saveToStorage();

  AppLogger.info('QueueViewModel', '插队播放: ${playable.title}');
}
```

#### 4.2.3 收藏状态同步

```dart
Widget _buildFavoriteButton(BuildContext context, WidgetRef ref, String audioId) {
  final favoriteState = ref.watch(favoriteViewModelProvider);
  final isFav = favoriteState.favorites.any((f) => f.id == audioId);

  return IconButton(
    icon: Icon(
      isFav ? Icons.favorite : Icons.favorite_border,
      color: isFav ? Colors.red : null,
    ),
    onPressed: () {
      ref.read(favoriteViewModelProvider.notifier).toggleFavorite(audioId);
    },
  );
}
```

### 4.3 验收标准

- [ ] 长按拖拽可以调整歌曲顺序
- [ ] "下一首播放"功能正常
- [ ] 收藏按钮状态与"我的收藏"同步
- [ ] 长按歌曲显示更多操作菜单

---

## 总体验收清单

### Phase 1 ✅ 已完成
- [x] 播放列表显示混合队列
- [x] 歌单"播放全部"正常工作
- [x] 点击歌曲替换队列
- [x] App 启动恢复队列

### Phase 2 ✅ 已完成
- [x] 底部弹窗正常显示
- [x] Tab 切换正常
- [x] 播放历史时间分组
- [x] 双入口都可以打开弹窗

### Phase 3 ✅ 已完成
- [x] 显示队列来源
- [x] 来源点击跳转（占位实现）
- [x] 上一首/下一首功能
- [x] 播放模式切换

### Phase 4 ✅ 已完成
- [x] 拖拽排序（ReorderableListView）
- [x] 插队播放（insertNext 方法）
- [x] 收藏状态同步（收藏按钮）
- [x] 长按菜单（底部菜单）

---

## 风险与注意事项

### 技术风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 拖拽排序性能 | 队列很长时卡顿 | 限制最大显示数量或使用虚拟列表 |
| 状态同步 | 多处状态不一致 | 使用 Riverpod 的 Provider 统一管理 |
| 持久化数据量 | 数据过大导致加载慢 | 只保存必要字段，按需加载 |

### 设计决策

| 决策 | 理由 |
|------|------|
| 不显示序号 | 用户要求，简化界面 |
| 不显示波形动画 | 用户要求，减少视觉干扰 |
| 使用底部弹窗而非全屏 | 不打断用户操作流程 |
| 双入口设计 | 提高可发现性 |

---

## 参考资料

- [播放列表设计方案 v2.0](../reports/playlist-design-spec.md)
- QQ音乐 App 播放列表界面
- [QQ音乐交互设计分析](https://www.woshipm.com/ucd/3443955.html)
- [Spotify Play Queue](https://support.spotify.com/us/article/play-queue/)
