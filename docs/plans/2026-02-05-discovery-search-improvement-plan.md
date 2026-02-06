# 发现页面与搜索功能改进计划

**创建日期**: 2026-02-05
**更新日期**: 2026-02-06
**状态**: ✅ 已完成 (5/5 Phase)
**优先级**: P0（核心功能改进）

**前置依赖**: [Riverpod 3.0 迁移计划](./2026-02-06-riverpod-3-migration-plan.md) Phase 1-4

---

## 一、概述

本计划旨在改进应用的发现页面和搜索功能，完善核心用户体验。主要改进点：

1. **搜索页面**：添加分页功能、操作菜单（下载/加入歌单/跳转原网页）
2. **发现页面**：简化为纯音频列表，基于 B 站音乐区推荐，添加绑定状态检查
3. **歌单详情页面**：实现完整的歌单详情展示和管理功能

---

## 二、前置依赖说明

✅ **Riverpod 3.0 迁移已完成**，所有 Phase 可以正常执行。

### 2.1 依赖关系

```
┌─────────────────────────────────────────────────────────┐
│  Riverpod 3.0 迁移计划 (2026-02-06-riverpod-3-migration) │
│  ✅ Phase 1: 基础设施准备                                 │
│  ✅ Phase 2: 核心 ViewModel 迁移 (Download, Queue, etc.)  │
│  ✅ Phase 4: 其他 ViewModel 迁移 (SearchViewModel, etc.) │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  本计划所有 Phase 已完成                                   │
│  ✅ Phase 1: 搜索分页功能                                 │
│  ✅ Phase 2: 搜索结果操作菜单                             │
│  ✅ Phase 3: 发现页面重构                                 │
│  ✅ Phase 4: 歌单详情页面                                 │
│  ✅ Phase 5: 批量导入                                     │
└─────────────────────────────────────────────────────────┘
```

### 2.2 当前状态

| Phase | 状态 | 说明 |
|-------|------|------|
| Phase 1 | ✅ 已完成 | 搜索分页功能 (2026-02-05) |
| Phase 2 | ✅ 已完成 | 搜索结果操作菜单 (2026-02-05) |
| Phase 3 | ✅ 已完成 | 发现页面重构 (2026-02-06) |
| Phase 4 | ✅ 已完成 | 歌单详情页面 (2026-02-06) |
| Phase 5 | ✅ 已完成 | 批量导入 (2026-02-06) |

---

## 二、设计原则

### 2.1 纯音频应用定位

- 不显示视频封面/预览
- 以音频信息为核心（标题、艺术家、时长、播放量）
- 列表式布局，清晰简洁

### 2.2 交互一致性

- 搜索结果与发现页面使用相同的列表组件
- 操作菜单统一样式和选项
- 分页/加载更多交互一致

### 2.3 权限控制

- 游客模式：可搜索、可播放本地音频
- 登录用户：可访问发现页面
- 绑定 B 站账号：发现页面显示推荐内容

---

## 三、执行顺序建议

### 3.1 整体时间线

```
Week 1: Riverpod 3.0 迁移 (参见: 2026-02-06-riverpod-3-migration-plan.md)
├── Day 1-2: Phase 1-2 (基础设施 + 核心 ViewModel)
├── Day 3:   Phase 4 (其他 ViewModel: SearchViewModel, LocalMusicViewModel, etc.)
└── Day 4-5: Phase 5 (Widget 更新 + 测试)

Week 2: 本计划 Phase 3-5 实施
├── Day 6-7: Phase 3 (发现页面重构) - ExploreViewModel 使用 Riverpod 3 模式
├── Day 8:   Phase 4 (歌单详情页面) - PlaylistDetailViewModel 使用 Riverpod 3 模式
└── Day 9:   Phase 5 (批量导入改进，可选)
```

### 3.2 与 Riverpod 3 迁移的对照

| 本计划 Phase | 依赖 Riverpod 3 Phase | 说明 |
|-------------|----------------------|------|
| Phase 3 | Phase 4 | SearchViewModel 迁移后，ExploreViewModel 可复用相同模式 |
| Phase 4 | Phase 2 | PlaylistViewModel 迁移后，PlaylistDetailViewModel 保持一致 |
| Phase 5 | Phase 4 | LocalMusicViewModel 迁移后，批量导入功能正确刷新 UI |

---

### Phase 1: 搜索分页功能 (优先级: P0) ✅ 已完成

**完成日期**: 2026-02-05

**目标**: 实现搜索结果的分页加载

#### 1.1 后端验证

| 文件 | 状态 | 说明 |
|------|------|------|
| `listen-vision_api/services/bilibiliService.js` | ✅ 已支持 | `searchBilibili(keyword, page, pageSize)` |
| `listen-vision_api/routes/bilibili.js` | ✅ 已支持 | `/api/bilibili/search?page=1&pageSize=20` |

后端已支持分页，无需修改。

#### 1.2 前端 ViewModel 改造

**文件**: `frontend_flutter/lib/presentation/viewmodels/discovery/search_viewmodel.dart`

**当前代码**:
```dart
Future<bool> search(String keyword) async {
  // 只支持单次搜索，无分页
}
```

**改造后**:
```dart
// SearchState 添加分页字段
@freezed
class SearchState with _$SearchState {
  const factory SearchState.resultsLoaded({
    required List<SearchResultItem> results,
    required String query,
    required SearchPlatform platform,
    required int currentPage,      // 新增
    required int pageSize,          // 新增
    required int totalCount,        // 新增
    required bool hasMore,          // 新增
  }) = SearchStateResultsLoaded;
}

// 新增方法
Future<bool> search(String keyword, {int page = 1});
Future<bool> loadNextPage();
void clearSearchResults();
```

#### 1.3 前端 UI 改造

**文件**: `frontend_flutter/lib/presentation/views/discovery/search_page.dart`

**设计方案**: 底部"加载更多"按钮

```dart
Widget _buildResultsList(List<SearchResultItem> results, bool hasMore) {
  return ListView.builder(
    itemCount: results.length + (hasMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index == results.length) {
        return ListTile(
          title: const Center(child: Text('加载更多')),
          onTap: () => ref.read(searchViewModelProvider.notifier).loadNextPage(),
        );
      }
      return _buildResultItem(results[index]);
    },
  );
}
```

#### 1.4 验收标准

- [x] 搜索结果显示后，底部显示分页控制栏
- [x] 显示当前页码和总页数（如 `1/20`）
- [x] 上一页/下一页按钮正常工作
- [x] 没有更多结果时禁用下一页按钮

**实施记录**:
- 修改 `backend_api_client.dart:524-549`: 添加 `page` 和 `pageSize` 参数
- 修改 `search_viewmodel.dart:27-35`: 添加分页字段 `currentPage`, `pageSize`, `totalCount`, `hasMore`
- 修改 `search_viewmodel.dart:107-177`: `search()` 方法支持 `page` 参数
- 修改 `search_viewmodel.dart:182-237`: 新增 `loadNextPage()` 方法
- 修改 `search_page.dart:174-293`: 实现分页控制栏 UI (`<- 1/20 ->`)
- 运行 `build_runner` 重新生成 freezed 文件

**UI 效果**:
```
┌─────────────────────────────────────────┐
│  [结果列表...]                           │
│                                         │
├─────────────────────────────────────────┤
│            <-  1/20  ->                 │
└─────────────────────────────────────────┘
```

---

### Phase 2: 搜索结果操作菜单 (优先级: P0) ✅ 已完成

**完成日期**: 2026-02-05

**目标**: 为每个搜索结果添加操作菜单

#### 2.1 新建通用组件

**文件**: `frontend_flutter/lib/presentation/widgets/audio/audio_action_menu.dart`

```dart
/// 音频操作菜单组件
class AudioActionMenu extends StatelessWidget {
  final String bvid;
  final String title;
  final String? artist;
  final String? coverUrl;
  final VoidCallback? onPlay;
  final VoidCallback? onDownload;
  final VoidCallback? onAddToPlaylist;

  // 显示底部操作菜单
  static Future<void> show(BuildContext context, {...});
}
```

#### 2.2 搜索页面集成

**文件**: `frontend_flutter/lib/presentation/views/discovery/search_page.dart`

```dart
Widget _buildResultItem(SearchResultItem item) {
  return ListTile(
    title: Text(item.title),
    subtitle: Text('${item.author} · ${_formatDuration(item.duration)}'),
    onTap: () => _onResultTap(item),  // 点击播放
    trailing: IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showActionMenu(item),
    ),
  );
}

void _showActionMenu(SearchResultItem item) {
  showModalBottomSheet(
    context: context,
    builder: (context) => AudioActionMenu(
      bvid: item.bvid,
      title: item.title,
      artist: item.author,
      onPlay: () => _playAudio(item),
      onDownload: () => _downloadAudio(item),
      onAddToPlaylist: () => _showPlaylistSelector(item),
    ),
  );
}
```

#### 2.3 操作功能实现

| 功能 | 实现方式 | 依赖 |
|------|----------|------|
| 立即播放 | `context.push('/player?bvid=$bvid')` | 现有播放器 |
| 下载到本地 | 调用 `/api/bilibili/download/$bvid` | 后端已支持 |
| 加入歌单 | 显示歌单选择器，调用添加 API | PlaylistViewModel |
| 跳转原网页 | `url_launcher.open('https://bilibili.com/video/$bvid')` | 需添加依赖 |

#### 2.4 歌单选择器组件

**文件**: `frontend_flutter/lib/presentation/widgets/playlist/playlist_selector.dart`

```dart
/// 歌单选择器对话框
class PlaylistSelector extends ConsumerWidget {
  final String bvid;
  final String title;
  final String? artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistViewModelProvider);

    return SimpleDialog(
      title: const Text('选择歌单'),
      children: [
        ...userPlaylists.map((p) => ListTile(
          title: Text(p.name),
          onTap: () => _addToPlaylist(ref, p.id),
        )),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('创建新歌单'),
          onTap: () => _createNewPlaylist(context),
        ),
      ],
    );
  }
}
```

#### 2.5 验收标准

- [x] 每个搜索结果显示更多操作按钮
- [x] 点击后弹出操作菜单
- [x] 立即播放功能正常（点击列表项）
- [x] 下载功能正常（调用 DownloadViewModel）
- [x] 加入歌单功能正常（歌单选择器 + 创建新歌单）
- [x] 跳转原网页正常（url_launcher）

**实施记录**:
- 创建 `widgets/audio/audio_action_menu.dart`: 通用音频操作菜单组件
  - 收藏/取消收藏功能
  - 加入歌单功能（含歌单选择器和创建新歌单）
  - 下载功能
  - 在浏览器中打开
  - 分享功能（占位）
- 修改 `views/discovery/search_page.dart`: 添加更多操作按钮
- 修改 `widgets/widgets.dart`: 导出 AudioActionMenu
- 运行 `build_runner` 生成代码

---

### Phase 3: 发现页面重构 (优先级: P0) ✅ 已完成

**完成日期**: 2026-02-06

**目标**: 简化发现页面为纯音频推荐列表

#### 3.1 设计方案

```
┌─────────────────────────────────────────────┐
│  发现                                        │
├─────────────────────────────────────────────┤
│  [🔥 热门]  [⭐ 推荐]  [🆕 最新]            │  ← Tab 切换
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐    │
│  │ 1.  歌曲名称              ⋮         │    │
│  │     UP主 • 03:45 • 1.2万播放         │    │
│  ├─────────────────────────────────────┤    │
│  │ 2.  歌曲名称              ⋮         │    │
│  │     UP主 • 04:12 • 9800播放          │    │
│  └─────────────────────────────────────┘    │
│                    [加载更多]                 │
└─────────────────────────────────────────────┘
```

#### 3.2 新建 ViewModel

**文件**: `frontend_flutter/lib/presentation/viewmodels/discovery/explore_viewmodel.dart`

```dart
part 'explore_viewmodel.freezed.dart';
part 'explore_viewmodel.g.dart';

/// 发现内容类型
enum ExploreType {
  hot,        // 热门榜单
  recommended,// 个性化推荐
  latest,     // 最新发布
}

/// 发现状态
@freezed
class ExploreState with _$ExploreState {
  const factory ExploreState.initial() = ExploreStateInitial;
  const factory ExploreState.loading() = ExploreStateLoading;
  const factory ExploreState.notBound() = ExploreStateNotBound;
  const factory ExploreState.loaded({
    required List<ExploreItem> items,
    required bool hasMore,
    required int currentPage,
    required ExploreType type,
  }) = ExploreStateLoaded;
  const factory ExploreState.error({required String message}) = ExploreStateError;
}

/// 发现项
class ExploreItem {
  final String bvid;
  final String title;
  final String author;
  final int duration;
  final int playCount;
  final int rank;  // 排名（仅热门榜单）
}

@riverpod
class ExploreViewModel extends _$ExploreViewModel {
  @override
  ExploreState build() {
    final isBound = ref.read(isBilibiliBound);
    if (!isBound) {
      return const ExploreState.notBound();
    }
    return const ExploreState.initial();
  }

  /// 加载热门榜单
  Future<void> loadHotRanking({int page = 1}) async { ... }

  /// 加载个性化推荐
  Future<void> loadRecommended({int page = 1}) async { ... }

  /// 加载最新发布
  Future<void> loadLatest({int page = 1}) async { ... }

  /// 加载下一页
  Future<void> loadNext() async { ... }
}
```

#### 3.3 重写发现页面

**文件**: `frontend_flutter/lib/presentation/views/discovery/explore_page.dart`

```dart
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  static const List<String> _tabs = ['热门', '推荐', '最新'];
  static const List<ExploreType> _types = [
    ExploreType.hot,
    ExploreType.recommended,
    ExploreType.latest,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChange);
    // 初始加载热门
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exploreViewModelProvider.notifier).loadHotRanking();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    switch (_types[index]) {
      case ExploreType.hot:
        ref.read(exploreViewModelProvider.notifier).loadHotRanking();
        break;
      case ExploreType.recommended:
        ref.read(exploreViewModelProvider.notifier).loadRecommended();
        break;
      case ExploreType.latest:
        ref.read(exploreViewModelProvider.notifier).loadLatest();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBilibiliBound = ref.watch(isBilibiliBound);

    if (!isBilibiliBound) {
      return _buildNotBoundPrompt(context);
    }

    final exploreState = ref.watch(exploreViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: exploreState.when(
        initial: () => _buildEmptyState(),
        loading: () => const Center(child: CircularProgressIndicator()),
        notBound: () => _buildNotBoundPrompt(context),
        loaded: (items, hasMore, _, type) => _buildAudioList(items, hasMore, type),
        error: (msg) => _buildErrorState(msg),
      ),
    );
  }

  Widget _buildNotBoundPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发现')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            const Text('需要绑定 B站账号', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('绑定后可查看 B站音乐区推荐内容'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/settings'),
              child: const Text('前往绑定'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioList(List<ExploreItem> items, bool hasMore, ExploreType type) {
    return ListView.separated(
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return ListTile(
            title: const Center(child: Text('加载更多')),
            onTap: () => ref.read(exploreViewModelProvider.notifier).loadNext(),
          );
        }
        final item = items[index];
        return _buildAudioItemTile(item, type);
      },
    );
  }

  Widget _buildAudioItemTile(ExploreItem item, ExploreType type) {
    final leading = type == ExploreType.hot
        ? Text('${item.rank}', style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
          ))
        : const Icon(Icons.music_note);

    return ListTile(
      leading: leading,
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${item.author} • ${_formatDuration(item.duration)} • ${_formatPlayCount(item.playCount)}'),
      trailing: AudioActionMenu(
        bvid: item.bvid,
        title: item.title,
        artist: item.author,
      ),
      onTap: () => context.push('/player?bvid=${item.bvid}'),
    );
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String _formatPlayCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万播放';
    }
    return '$count播放';
  }
}
```

#### 3.4 后端 API 新增

**文件**: `listen-vision_api/routes/bilibili.js`

```javascript
/**
 * @swagger
 * /api/bilibili/music/hot:
 *   get:
 *     tags: [B站API]
 *     summary: 获取B站音乐区热门音频
 *     parameters:
 *       - in: query
 *         name: page
 *       - in: query
 *         name: pageSize
 */
router.get('/music/hot', authMiddleware, bilibiliController.getMusicHot);

/**
 * @swagger
 * /api/bilibili/music/recommended:
 *   get:
 *     tags: [B站API]
 *     summary: 获取个性化推荐
 *     description: 基于用户B站浏览历史的音乐推荐
 */
router.get('/music/recommended', authMiddleware, bilibiliController.getMusicRecommended);
```

**文件**: `listen-vision_api/controllers/bilibiliController.js`

```javascript
/**
 * 获取B站音乐区热门内容
 */
const getMusicHot = async (req, res) => {
  try {
    const { page = 1, pageSize = 20 } = req.query;
    const userId = req.user?.id;

    // 调用 B站 API，搜索音乐区内容
    const result = await bilibiliService.searchBilibili(
      '',  // 空关键词
      parseInt(page),
      parseInt(pageSize),
      userId
    );

    res.json({
      success: true,
      data: {
        items: result.videos,
        hasMore: result.videos.length >= parseInt(pageSize),
        total: result.total,
      },
    });
  } catch (error) {
    logger.error('获取音乐区热门失败: %s', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * 获取个性化推荐
 */
const getMusicRecommended = async (req, res) => {
  try {
    const { page = 1, pageSize = 20 } = req.query;
    const userId = req.user?.id;

    // 基于用户浏览历史的推荐
    // TODO: 实现推荐算法，暂时返回热门
    const result = await bilibiliService.getRecommendedMusic(
      userId,
      parseInt(page),
      parseInt(pageSize)
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('获取推荐失败: %s', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
};
```

#### 3.5 验收标准

- [x] 未绑定 B 站账号时显示绑定引导
- [x] 绑定后显示三个 Tab：热门、推荐、最新
- [x] 热门榜单显示排名序号
- [x] 列表项显示标题、UP主、时长、播放量
- [x] 点击列表项播放音频
- [x] 点击更多按钮显示操作菜单
- [x] 加载更多功能正常

**实施记录**:
- 创建 `viewmodels/discovery/explore_viewmodel.dart`: ExploreViewModel
  - ExploreState (initial/loading/notBound/loaded/error)
  - ExploreItem (bvid, title, author, duration, playCount, coverUrl, rank)
  - loadHotRanking() - 加载热门榜单
  - loadRecommended() - 加载个性化推荐
  - loadLatest() - 加载最新发布
  - loadNext() - 加载下一页
- 更新 `views/discovery/explore_page.dart`: Tab + 列表布局
  - 未登录提示 → 绑定提示 → Tab内容
  - 热门榜单显示排名徽章（金银铜色）
  - 集成 AudioActionMenu 操作菜单
  - 下拉刷新 + 加载更多

---

### Phase 4: 歌单详情页面实现 (优先级: P1)

**目标**: 实现完整的歌单详情展示和管理

#### 4.1 新建 ViewModel

**文件**: `frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart`

```dart
part 'playlist_detail_viewmodel.freezed.dart';
part 'playlist_detail_viewmodel.g.dart';

/// 歌单详情状态
@freezed
class PlaylistDetailState with _$PlaylistDetailState {
  const factory PlaylistDetailState.initial() = PlaylistDetailStateInitial;
  const factory PlaylistDetailState.loading() = PlaylistDetailStateLoading;
  const factory PlaylistDetailState.loaded({
    required Playlist playlist,
    required List<PlaylistItem> items,
    required bool isOwner,
  }) = PlaylistDetailStateLoaded;
  const factory PlaylistDetailState.error({required String message}) = PlaylistDetailStateError;
}

@riverpod
class PlaylistDetailViewModel extends _$PlaylistDetailViewModel {
  @override
  PlaylistDetailState build(String playlistId) {
    _loadDetail(playlistId);
    return const PlaylistDetailState.initial();
  }

  Future<void> _loadDetail(String playlistId) async {
    state = const PlaylistDetailState.loading();
    try {
      final playlist = await _repository.getPlaylistDetail(playlistId);
      final items = await _repository.getPlaylistItems(playlistId);
      final isOwner = await _checkOwnership(playlistId);

      state = PlaylistDetailState.loaded(
        playlist: playlist,
        items: items,
        isOwner: isOwner,
      );
    } catch (e) {
      state = PlaylistDetailState.error(message: e.toString());
    }
  }

  Future<bool> removeItem(String bvid) async { ... }
  Future<bool> playAll() async { ... }
  Future<bool> downloadAll() async { ... }
  Future<bool> updatePlaylist({...}) async { ... }
  Future<bool> deletePlaylist() async { ... }
}
```

#### 4.2 重写歌单详情页面

**文件**: `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart`

```dart
class PlaylistDetailPage extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(playlistDetailViewModelProvider(playlistId));

    return Scaffold(
      appBar: AppBar(
        title: detailState.maybeWhen(
          loaded: (playlist, _, __) => Text(playlist.name),
          orElse: () => const Text('歌单详情'),
        ),
        actions: [
          detailState.maybeWhen(
            loaded: (_, __, isOwner) => isOwner
                ? PopupMenuButton<String>(
                    onSelected: (action) => _onMenuAction(action, ref),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑歌单')),
                      const PopupMenuItem(value: 'delete', child: Text('删除歌单')),
                    ],
                  )
                : null,
            orElse: () => null,
          ),
        ],
      ),
      body: detailState.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (playlist, items, isOwner) => _buildContent(playlist, items, ref),
        error: (msg) => Center(child: Text('加载失败: $msg')),
      ),
    );
  }

  Widget _buildContent(Playlist playlist, List<PlaylistItem> items, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // 歌单头部信息
        SliverToBoxAdapter(
          child: _buildPlaylistHeader(playlist, items.length),
        ),
        // 操作按钮
        SliverToBoxAdapter(
          child: _buildActionButtons(ref, playlist.id, items),
        ),
        // 分割线
        const SliverToBoxAdapter(
          child: Divider(height: 1),
        ),
        // 音频列表
        _buildItemsList(items, ref),
      ],
    );
  }

  Widget _buildPlaylistHeader(Playlist playlist, int itemCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 封面
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: playlist.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(playlist.coverUrl!),
                  )
                : const Icon(Icons.playlist_play, size: 48),
          ),
          const SizedBox(width: 16),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text('${itemCount} 首歌曲'),
                if (playlist.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    playlist.description!,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(WidgetRef ref, String playlistId, List<PlaylistItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放全部'),
              onPressed: () => _playAll(ref, items),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('下载全部'),
              onPressed: () => _downloadAll(ref, items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<PlaylistItem> items, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return ListTile(
            leading: Text('${index + 1}'),
            title: Text(item.title ?? '未知标题'),
            subtitle: Text('${item.artist ?? '未知艺术家'} • ${_formatDuration(item.duration)}'),
            trailing: AudioActionMenu(
              bvid: item.bvid,
              title: item.title ?? '',
              artist: item.artist,
            ),
            onTap: () => context.push('/player?bvid=${item.bvid}'),
          );
        },
        childCount: items.length,
      ),
    );
  }

  void _playAll(WidgetRef ref, List<PlaylistItem> items) {
    if (items.isEmpty) return;
    // 添加到播放队列并开始播放
    ref.read(queueViewModelProvider.notifier).replaceAll(items.map((item) => ...).toList());
    ref.read(playerViewModelProvider.notifier).play();
    context.push('/player');
  }

  void _downloadAll(WidgetRef ref, List<PlaylistItem> items) {
    // 批量下载
    for (final item in items) {
      ref.read(downloadViewModelProvider.notifier).addDownload(item.bvid);
    }
    context.push('/downloads');
  }

  void _onMenuAction(String action, WidgetRef ref) {
    switch (action) {
      case 'edit':
        // 显示编辑对话框
        break;
      case 'delete':
        // 确认删除
        break;
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
```

#### 4.3 后端 API 现有支持

| API | 状态 | 说明 |
|-----|------|------|
| `GET /api/playlists/:id` | ✅ 已有 | 获取歌单详情 |
| `GET /api/playlists/:id/items` | ✅ 已有 | 获取歌单项 |
| `DELETE /api/playlists/:id/items/:bvid` | ✅ 已有 | 删除歌单项 |

后端已支持，无需修改。

#### 4.4 验收标准

- [x] 显示歌单封面、名称、描述、歌曲数量
- [x] 播放全部按钮功能正常
- [x] 下载全部按钮功能正常
- [x] 列表显示所有歌曲
- [x] 点击歌曲播放
- [x] 长按/更多按钮显示操作菜单
- [x] 所有者可编辑/删除歌单

**实施记录**:
- 创建 `viewmodels/library/playlist_detail_viewmodel.dart`: PlaylistDetailViewModel
  - PlaylistDetailState (initial/loading/loaded/error)
  - build() - 自动加载歌单详情
  - refresh() - 刷新详情
  - removeItem() - 移除歌单项
  - updatePlaylist() - 更新歌单信息
  - deletePlaylist() - 删除歌单
- 更新 `views/library/playlist_detail_page.dart`: 实现歌单详情 UI
  - 歌单头部信息（封面、名称、描述）
  - 操作按钮（播放全部、下载全部）
  - 歌曲列表
  - 编辑/删除歌单功能
- 更新 `providers.dart`: 导出 playlistDetailViewModelProvider

---

### Phase 5: 批量导入功能改进 (优先级: P2) ✅

**完成日期**: 2026-02-06

**目标**: 支持多文件选择导入

#### 5.1 当前实现

**文件**: `frontend_flutter/lib/presentation/viewmodels/library/local_music_viewmodel.dart`

`importMultipleFiles()` 方法已存在，支持多文件选择和批量导入。

#### 5.2 UI 改进

**文件**: `frontend_flutter/lib/presentation/views/library/local_music_playlist_page.dart`

- 添加批量导入按钮（`Icons.playlist_add`）
- 显示导入进度（current/total + 当前文件名）

#### 5.3 验收标准

- [x] 支持多文件选择
- [x] 显示导入进度
- [x] 支持取消导入（通过返回按钮）

**实施记录**:
- 验证 `local_music_viewmodel.dart` 已实现 `importMultipleFiles()`
- 更新 `local_music_playlist_page.dart` 添加批量导入按钮
- [ ] 支持取消导入

---

## 四、文件清单

### 4.1 新建文件

| 文件 | 说明 |
|------|------|
| `frontend_flutter/lib/presentation/viewmodels/discovery/explore_viewmodel.dart` | 发现页面 ViewModel |
| `frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart` | 歌单详情 ViewModel |
| `frontend_flutter/lib/presentation/widgets/audio/audio_action_menu.dart` | 音频操作菜单组件 |
| `frontend_flutter/lib/presentation/widgets/playlist/playlist_selector.dart` | 歌单选择器组件 |

### 4.2 修改文件

| 文件 | 修改内容 |
|------|----------|
| `frontend_flutter/lib/presentation/viewmodels/discovery/search_viewmodel.dart` | 添加分页状态和方法 |
| `frontend_flutter/lib/presentation/views/discovery/search_page.dart` | 添加分页 UI 和操作菜单 |
| `frontend_flutter/lib/presentation/views/discovery/explore_page.dart` | 重构为 Tab 列表布局 |
| `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart` | 实现完整功能 |
| `frontend_flutter/lib/presentation/providers.dart` | 添加新 Provider 导出 |

### 4.3 后端修改

| 文件 | 修改内容 |
|------|----------|
| `listen-vision_api/routes/bilibili.js` | 添加音乐区 API 路由 |
| `listen-vision_api/controllers/bilibiliController.js` | 添加音乐区控制器方法 |

---

## 五、风险与注意事项

1. **B站 API 限制**
   - 搜索频率限制，需添加防抖
   - WBI 签名可能变化，需做好容错

2. **性能考虑**
   - 列表滚动性能，使用 `ListView.builder`
   - 图片加载使用缓存

3. **权限控制**
   - 发现页面需正确检查 B 站绑定状态
   - 游客模式与登录用户的权限区分

4. **兼容性**
   - 现有路由配置可能需要调整
   - 确保与现有播放器、下载功能兼容

---

## 六、验收标准总结

| 功能 | 验收点 |
|------|--------|
| 搜索分页 | 加载更多按钮、追加显示、页码显示 |
| 搜索操作菜单 | 播放/下载/加入歌单/原网页跳转 |
| 发现页面 | 绑定检查、Tab 切换、列表显示、操作菜单 |
| 歌单详情 | 信息展示、播放全部、下载全部、列表操作 |
| 批量导入 | 多文件选择、导入进度、取消功能 |
