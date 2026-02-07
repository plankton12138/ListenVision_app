# 播放列表设计方案

> 文档版本: 2.0
> 更新日期: 2026-02-07
> 参考来源: QQ音乐播放列表交互设计

---

## 一、需求背景

### 1.1 现状问题

当前项目播放列表存在以下问题：
- 播放队列入口单一（仅右下角按钮）
- 点击歌单歌曲不替换播放队列
- 播放列表页面为独立页面，打断用户操作流程
- 缺乏播放历史回溯功能
- 启动时无法恢复上次播放队列
- 队列来源不可见（用户不知道当前队列来自哪个歌单）

### 1.2 设计目标

1. **便于管理**: 支持查看、删除、排序、清空等完整操作
2. **更新及时**: 点击歌单自动替换队列，启动自动恢复
3. **方便使用**: 底部弹窗形式，不打断当前播放
4. **功能完整**: 队列管理 + 播放历史 + 播放模式

---

## 二、参考分析：QQ音乐播放列表

### 2.1 界面结构

QQ音乐采用底部弹窗 + Tab切换的设计：

```
┌─────────────────────────────────────────┐
│  正在播放 71 │ 已播歌曲 999+ │ 已播歌单 1 │  ← Tab切换 + 数量
├─────────────────────────────────────────┤
│  刚刚                                   │  ← 时间分组
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  歌曲名 - 歌手                      ❤️  │  ← 歌曲列表
│  ...                                  │
│  2025年4月21日                          │  ← 时间分组
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  歌曲名 - 歌手                      ❤️  │
└─────────────────────────────────────────┘
```

### 2.2 设计特点取舍

| 特点 | 说明 | 本项目取舍 |
|------|------|-----------|
| Tab切换 | 正在播放/已播歌曲/已播歌单 | ✅ 采用（仅保留前两个Tab） |
| Tab数量提示 | 显示每个Tab的项目数量 | ✅ 采用 |
| 时间分组 | 刚刚、具体日期 | ✅ 采用（简化版） |
| 序号列表 | 左侧显示序号 | ❌ 不采用（用户要求） |
| 波形动画 | 当前播放显示波形 | ❌ 不采用（用户要求） |
| 播放次数 | 每行显示播放次数 | ❌ 暂不实现（B站API限制） |
| VIP标识 | 绿色VIP标签 | ❌ 不需要 |
| 收藏按钮 | 每行右侧心形 | ✅ 采用（同步收藏状态） |
| 删除功能 | 长按菜单 | ❌ 改为 🗑️ 按钮（更直观） |
| 排序功能 | 不支持 | ✅ 拖拽排序（优于QQ音乐） |
| 队列来源显示 | 显示队列来自哪个歌单 | ✅ 新增（QQ音乐没有） |

---

## 三、最终设计方案

### 3.1 入口设计

保留现有入口，新增一个入口：

1. **右下角队列按钮**（已有）→ 打开播放列表弹窗
2. **点击歌曲信息区**（新增）→ 打开播放列表弹窗

```
┌─────────────────────────────────────────┐
│  首页播放器                              │
│                                         │
│  ┌─────────────────┬─────────────────┐ │
│  │   歌曲信息       │    播放控制       │ │
│  │  （点击打开队列） │   ⏮ ⏯ ⏭       │ │
│  └─────────────────┴─────────────────┘ │
│              [ ≡ 队列 ]  ← 右下角按钮    │
└─────────────────────────────────────────┘
```

### 3.2 弹窗结构（Tab切换）

```
┌─────────────────────────────────────────────────────────────┐
│  正在播放(12) │ 播放历史(48) │                    [×]       │  ← Tab+数量+关闭
├─────────────────────────────────────────────────────────────┤
│  📋 来自: 我喜欢的音乐                        [🔀 顺序 ▼]  │  ← 来源+模式
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  【Tab 1: 正在播放】                                         │
│                                                             │
│  正在播放                                                   │  ← 时间分组（可选）
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                             │
│  ▶ 光年之外 - 邓紫棋                           🗑️     ❤️   │  ← 当前播放（高亮）
│     03:25 ━━━●━━━━━━━━ 04:12                                 │  ← 进度条（已有）
│                                                             │
│     泡沫 - 邓紫棋                                   🗑️ ❤️  │
│          ☰                                                  │  ← 拖拽手柄
│     回忆中的你 - 王力宏                               🗑️ ❤️  │
│          ☰                                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  [定位] [清空]                                              │  ← 底部操作
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  【Tab 2: 播放历史】                                         │
│                                                             │
│  刚刚                                                       │  ← 时间分组
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  光年之外 - 邓紫棋                                 +   ❤️  │  ← +添加到队列
│  泡沫 - 邓紫棋                                    +   ❤️  │
│                                                             │
│  昨天                                                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  龙卷风 - 周杰伦                                   +   ❤️  │
│  晴天 - 周杰伦                                      +   ❤️  │
│                                                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                        [ 清空历史记录 ]                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 四、功能详细设计

### 4.1 Tab 1: 正在播放

#### 4.1.1 歌曲列表项

```
┌─────────────────────────────────────────────────────────────┐
│  ▶ 歌曲名 - 歌手                                 🗑️     ❤️ │  ← 当前播放
│     进度条（继承自播放器，可选显示）                          │
│                                                             │
│     歌曲名 - 歌手                                     🗑️ ❤️│  ← 其他歌曲
│          ☰                                                │  ← 拖拽手柄
└─────────────────────────────────────────────────────────────┘
```

**样式区分：**
| 状态 | 背景 | 左侧图标 | 其他元素 |
|------|------|----------|----------|
| 当前播放 | 主题色半透明背景 | ▶ 播放图标 | 歌曲名加粗/主题色 |
| 其他歌曲 | 透明 | 无序号 | 普通样式 |
| 拖拽状态 | 半透明+阴影 | - | 显示拖拽指示器 |

#### 4.1.2 操作说明

| 操作 | 触发方式 | 效果 |
|------|----------|------|
| 播放歌曲 | 点击整行 | 切换到该歌曲播放 |
| 删除歌曲 | 点击 🗑️ | 从队列移除，不确认 |
| 调整顺序 | 长按 ☰ 拖拽 | 释放后固定新位置 |
| 收藏歌曲 | 点击 ❤️ | 切换收藏状态（实时同步） |

#### 4.1.3 顶部信息区

```
┌─────────────────────────────────────────────────────────────┐
│  📋 来自: 我喜欢的音乐                        [🔀 顺序 ▼]  │
└─────────────────────────────────────────────────────────────┘
```

| 元素 | 说明 |
|------|------|
| 📋 来自 | 显示队列来源歌单名称，点击可跳转 |
| 🔀 顺序 ▼ | 播放模式按钮，点击切换 |

#### 4.1.4 底部操作栏

```
┌─────────────────────────────────────────────────────────────┐
│  [定位] [清空]                                              │
└─────────────────────────────────────────────────────────────┘
```

| 按钮 | 功能 | 说明 |
|------|------|------|
| 定位 | 滚动到当前播放歌曲 | 队列很长时快速定位 |
| 清空 | 清空整个队列 | 弹出确认对话框 |

### 4.2 Tab 2: 播放历史

#### 4.2.1 时间分组规则

| 分组名称 | 条件 | 示例 |
|----------|------|------|
| 刚刚 | 1小时内 | 刚刚 |
| 今天 | 今天但超过1小时 | 今天 |
| 昨天 | 昨天 | 昨天 |
| 具体日期 | 更早 | 2025年4月21日 |

#### 4.2.2 操作说明

| 操作 | 触发方式 | 效果 |
|------|----------|------|
| 播放歌曲 | 点击整行 | 替换队列为该歌曲，立即播放 |
| 添加到队列 | 点击 + | 添加到队列末尾 |
| 收藏歌曲 | 点击 ❤️ | 切换收藏状态（实时同步） |
| 清空历史 | 底部按钮 | 弹出确认后清空 |

### 4.3 播放模式

| 模式 | 图标 | 说明 |
|------|------|------|
| 顺序播放 | 🔀 顺序 | 按列表顺序播放，结束后停止 |
| 列表循环 | 🔁 列表循环 | 按列表顺序循环播放 |
| 随机播放 | 🔀 随机 | 随机打乱顺序播放 |
| 单曲循环 | 🔂 单曲循环 | 当前歌曲循环播放 |

### 4.4 队列自动管理规则

| 场景 | 用户操作 | 队列行为 |
|------|----------|----------|
| 1 | 点击歌单"播放全部" | 替换为歌单全部歌曲，记录来源，从第一首播放 |
| 2 | 点击歌单中某首歌曲 | 替换为"该歌曲 + 歌单后续歌曲"，记录来源 |
| 3 | 长按歌曲"下一首播放" | 插入到当前歌曲后，不替换队列 |
| 4 | 长按歌曲"添加到队列" | 追加到队列末尾 |
| 5 | 歌曲播放完成 | 移入播放历史，播放下一首 |
| 6 | App启动 | 恢复上次队列；若空则保持空 |
| 7 | 队列为空时点击历史 | 点击历史歌曲创建新队列（仅该歌） |

---

## 五、技术实现要点

### 5.1 数据结构

```dart
/// 播放模式
enum PlayMode {
  sequence,     // 顺序播放
  loopAll,      // 列表循环
  shuffle,      // 随机播放
  loopOne,      // 单曲循环
}

/// 队列来源
class QueueSource {
  final String id;           // 歌单ID
  final String name;         // 歌单名称
  final String? coverUrl;    // 歌单封面
  final SourceType type;     // 来源类型

  factory QueueSource.userPlaylist(String id, String name, {String? coverUrl}) { ... }
  factory QueueSource.favorites() { ... }
  factory QueueSource.history() { ... }
  factory QueueSource.search() { ... }
  factory QueueSource.manual() { ... }

  enum SourceType {
    userPlaylist,   // 用户歌单
    favorites,      // 收藏
    history,        // 播放历史
    search,         // 搜索结果
    manual,         // 手动添加
  }
}

/// 播放队列状态（扩展）
@freezed
class QueueState with _$QueueState {
  const factory QueueState({
    /// 播放队列
    @Default([]) List<PlayableAudio> queue,

    /// 当前播放索引
    @Default(-1) int currentIndex,

    /// 播放模式
    @Default(PlayMode.sequence) PlayMode playMode,

    /// 队列来源（用于显示）
    QueueSource? source,

    /// 是否正在拖拽
    @Default(false) bool isDragging,
  }) = _QueueState;
}

/// 播放历史分组
class HistoryGroup {
  final String label;        // "刚刚"、"今天"、"昨天"、日期
  final List<PlayHistory> items;

  static List<HistoryGroup> groupByTime(List<PlayHistory> history) { ... }
}
```

### 5.2 持久化策略

**保存时机：**
- 队列变化时（添加、删除、排序、设置）
- 当前歌曲切换时
- 播放模式切换时
- App 进入后台时

**保存内容：**
```json
{
  "queue": [...],
  "currentIndex": 3,
  "playMode": "shuffle",
  "source": {
    "id": "playlist_123",
    "name": "我的歌单A",
    "type": "userPlaylist",
    "coverUrl": "..."
  },
  "lastUpdated": "2026-02-07T10:30:00.000Z"
}
```

### 5.3 关键方法

```dart
class QueueViewModel extends _$QueueViewModel {
  // 队列管理
  Future<void> setQueue(List<PlayableAudio> queue, {int initialIndex = 0});
  Future<void> setQueueFromPlaylist(
    List<PlayableAudio> queue,
    QueueSource source, {
    int initialIndex = 0,
  });
  Future<void> removeAt(int index);
  Future<void> reorder(int oldIndex, int newIndex);
  Future<void> clear();

  // 插队播放
  Future<void> playNext(PlayableAudio playable);

  // 追加播放
  Future<void> append(PlayableAudio playable);

  // 播放模式
  void togglePlayMode();
  void setPlayMode(PlayMode mode);

  // 历史管理
  List<HistoryGroup> getGroupedHistory();
  Future<void> clearHistory();

  // 收藏状态同步
  Future<bool> isFavorite(String audioId);
  Future<void> toggleFavorite(String audioId);

  // 持久化
  Future<void> _saveToStorage();
  Future<void> _loadFromStorage();
}
```

---

## 六、与现有代码整合

### 6.1 新建文件

| 文件 | 说明 |
|------|------|
| `models/queue_source.dart` | 队列来源模型 |
| `models/play_mode.dart` | 播放模式枚举 |
| `models/history_group.dart` | 历史分组模型 |
| `presentation/widgets/player/queue_bottom_sheet.dart` | 底部弹窗组件 |
| `presentation/widgets/player/queue_tab_view.dart` | 正在播放Tab |
| `presentation/widgets/player/history_tab_view.dart` | 播放历史Tab |
| `presentation/widgets/player/queue_item_tile.dart` | 队列列表项组件 |

### 6.2 修改文件

| 文件 | 修改内容 |
|------|----------|
| `viewmodels/player/queue_viewmodel.dart` | 添加source、playMode、历史分组、插队播放 |
| `views/player/play_list_page.dart` | 改为底部弹窗，添加Tab切换，修复显示queue而非localAudios |
| `viewmodels/library/playlist_detail_viewmodel.dart` | 实现playAll()，点击歌曲替换队列 |
| `views/player/home_page.dart` | 添加点击歌曲信息打开弹窗 |
| `widgets/controls_panel.dart` | 实现上一首/下一首功能 |

### 6.3 歌单页面集成示例

```dart
// playlist_detail_viewmodel.dart - playAll() 实现

Future<bool> playAll() async {
  final items = state.valueOrNull?.maybeWhen(
    loaded: (_, items, __) => items,
    orElse: () => null,
  );
  if (items == null || items.isEmpty) return false;

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

  // 替换队列并记录来源
  final source = QueueSource.userPlaylist(
    playlist!.id,
    playlist.name,
    coverUrl: playlist.coverUrl,
  );

  ref.read(queueViewModelProvider.notifier).setQueueFromPlaylist(
    queue,
    source,
    initialIndex: 0,
  );

  // 开始播放
  ref.read(playerViewModelProvider.notifier).loadAndPlay(queue.first);

  return true;
}
```

```dart
// playlist_detail_viewmodel.dart - 点击单首歌曲

Future<bool> playItem(String bvid) async {
  final items = state.valueOrNull?.maybeWhen(
    loaded: (_, items, __) => items,
    orElse: () => null,
  );
  if (items == null || items.isEmpty) return false;

  // 找到当前点击歌曲的索引
  final startIndex = items.indexWhere((item) => item.bvid == bvid);
  if (startIndex == -1) return false;

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

  // 记录来源
  final playlist = state.valueOrNull?.maybeWhen(
    loaded: (playlist, _, __) => playlist,
    orElse: () => null,
  );

  final source = QueueSource.userPlaylist(
    playlist!.id,
    playlist.name,
    coverUrl: playlist.coverUrl,
  );

  // 替换队列
  ref.read(queueViewModelProvider.notifier).setQueueFromPlaylist(
    queue,
    source,
    initialIndex: 0,
  );

  // 开始播放
  ref.read(playerViewModelProvider.notifier).loadAndPlay(queue.first);

  return true;
}
```

### 6.4 底部弹窗实现

```dart
// widgets/player/queue_bottom_sheet.dart

class QueueBottomSheet extends ConsumerStatefulWidget {
  const QueueBottomSheet({super.key});

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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

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

---

## 七、启动恢复流程

```
App 启动
   │
   ▼
QueueViewModel._init()
   │
   ├── 1. 从本地存储加载队列
   │   ├── 有队列 → 恢复 queue + currentIndex + playMode + source
   │   └── 无队列 → 保持空队列
   │
   ├── 2. 从本地存储加载历史
   │   └── 恢复历史记录列表（HistoryViewModel已有）
   │
   ├── 3. 恢复播放模式
   │   └── 默认顺序播放
   │
   └── 4. 如果队列不为空
       └── 恢复上次播放位置（可选）
```

---

## 八、功能验收清单

### 8.1 队列管理

- [ ] 打开播放列表弹窗（双入口：右下角按钮 + 歌曲信息区）
- [ ] 显示当前队列歌曲列表（修复显示queue而非localAudios）
- [ ] 当前播放歌曲高亮显示
- [ ] 点击歌曲切换到该歌曲
- [ ] 点击删除按钮移除歌曲
- [ ] 长按拖拽手柄调整顺序
- [ ] 点击定位滚动到当前歌曲
- [ ] 点击清空弹出确认并清空
- [ ] 切换播放模式（四种模式）

### 8.2 播放历史

- [ ] Tab切换到播放历史
- [ ] 历史按时间分组显示
- [ ] 点击历史歌曲替换队列并播放
- [ ] 点击 + 按钮添加到队列末尾
- [ ] 点击清空历史弹出确认

### 8.3 自动管理

- [ ] 点击歌单"播放全部"替换队列
- [ ] 点击歌单歌曲替换队列（从该歌曲开始）
- [ ] 切换歌曲时自动记录到历史
- [ ] App重启后恢复上次队列
- [ ] App重启后恢复历史记录

### 8.4 收藏同步

- [ ] 播放列表中显示收藏状态
- [ ] 点击收藏按钮实时同步
- [ ] 收藏状态与"我的收藏"页面一致

---

## 九、实施优先级

### Phase 1: 基础修复 (P0) - 1-2天
1. ✅ 修复 `play_list_page.dart` 显示混合队列（queue而非localAudios）
2. ✅ 实现 `playAll()` 功能
3. ✅ 实现点击单首歌曲替换队列
4. ✅ 实现启动恢复机制

### Phase 2: 底部弹窗 + Tab (P0) - 2-3天
5. ✅ 创建 `QueueBottomSheet` 组件
6. ✅ 实现 Tab 切换（正在播放 / 播放历史）
7. ✅ 实现时间分组历史显示
8. ✅ 添加双入口（歌曲信息区 + 右下角）

### Phase 3: 歌单集成 + 来源显示 (P1) - 2天
9. ✅ 记录队列来源并显示
10. ✅ 来源点击跳转到歌单详情
11. ✅ 实现上一首/下一首功能

### Phase 4: 高级功能 (P2) - 2-3天
12. ✅ 拖拽排序
13. ✅ 插队播放（下一首）
14. ✅ 四种播放模式切换
15. ✅ 收藏状态同步

---

## 十、参考资源

- QQ音乐 App 播放列表界面截图
- [QQ音乐交互设计分析](https://www.woshipm.com/ucd/3443955.html)
- [Spotify Play Queue](https://support.spotify.com/us/article/play-queue/)
- 项目现有代码：
  - `frontend_flutter/lib/presentation/views/player/play_list_page.dart`
  - `frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart`
  - `frontend_flutter/lib/presentation/viewmodels/library/history_viewmodel.dart`
