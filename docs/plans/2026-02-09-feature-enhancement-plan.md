# 功能完善实施方案

> 创建日期: 2026-02-09
> 作者: Kilo AI Assistant
> 版本: v1.0

---

## 一、概述

### 1.1 背景

在完成 MVVM 重构和本地优先架构后，项目存在以下已完成但不完善的功能缺陷：

| 序号 | 问题 | 影响范围 | 严重程度 |
|------|------|----------|----------|
| 1 | 播放历史点击播放未实现 | 播放历史页面 | 高 |
| 2 | SyncWorker JSON解析使用字符串拼接 | 数据同步 | 高 |
| 3 | 批量下载功能未实现 | 歌单详情页 | 高 |
| 4 | 歌单项操作菜单缺失 | 歌单详情页 | 中 |
| 5 | 发现页第一Tab为"开发中"占位 | 发现页面 | 中 |
| 6 | B站Cookie刷新机制未实现 | 认证系统 | 低 |

### 1.2 目标

修复上述缺陷，提升应用的整体可用性和用户体验。

### 1.3 范围

| 模块 | 修改文件数 |
|------|-----------|
| 前端 Flutter | 5-6 个文件 |
| 后端 Node.js | 2-3 个文件 |
| 数据库 | 1 处ALTER |

---

## 二、功能详细设计

### 2.1 播放历史点击播放

#### 2.1.1 需求描述

用户点击播放历史列表中的某条记录时，应直接播放该音频，并导航到播放页面。

#### 2.1.2 当前状态

**文件**: `frontend_flutter/lib/presentation/views/library/play_history_page.dart`

```dart
// 第 219-221 行
onTap: () {
  // TODO: 播放该音频
},
```

#### 2.1.3 实现方案

**修改文件**: `frontend_flutter/lib/presentation/views/library/play_history_page.dart`

**新增方法**:

```dart
/// 播放历史记录项
Future<void> _playHistoryItem(PlayHistory item, WidgetRef ref) async {
  final audio = item.audio;

  // 构建 Audio 对象
  final audioToPlay = Audio(
    id: audio.id ?? item.bvid,
    title: audio.title,
    artist: audio.artist,
    duration: audio.duration,
    coverUrl: audio.coverUrl,
    bvid: item.bvid,
  );

  // 调用 PlayerViewModel 播放
  ref.read(playerViewModelProvider.notifier).playOnlineAudio(
    audio: audioToPlay,
    playlist: null,
    index: 0,
  );

  // 导航到播放页面
  if (mounted) {
    context.go('/');
  }

  AppLogger.info('PlayHistoryPage', '播放历史记录: ${audio.title}');
}
```

**修改 onTap 回调**:

```dart
ListTile(
  // ... 现有属性不变
  onTap: () {
    _playHistoryItem(item, ref);
  },
),
```

#### 2.1.4 测试要点

| 用例 | 预期结果 |
|------|----------|
| 点击在线音频历史记录 | 跳转到首页并开始播放 |
| 点击本地音乐历史记录 | 跳转到首页并播放本地音乐 |
| 无网络时点击历史 | 显示网络错误提示 |

#### 2.1.5 工作量估算

| 任务 | 时间 |
|------|------|
| 代码实现 | 0.3h |
| 测试验证 | 0.2h |
| **合计** | **0.5h** |

---

### 2.2 SyncWorker JSON解析修复

#### 2.2.1 需求描述

当前 `_parseDataJson()` 方法使用简单的字符串处理解析JSON，存在以下问题：
- 无法正确处理嵌套JSON
- 无法处理特殊字符
- 值类型丢失（全部转为String）

#### 2.2.2 当前状态

**文件**: `frontend_flutter/lib/data/sync/sync_worker.dart`

```dart
// 第 281-310 行
Map<String, dynamic> _parseDataJson(String jsonString) {
  try {
    // 简单的 JSON 解析，避免导入 dart:convert
    // 实际使用时应该使用 dart:convert
    final data = <String, dynamic>{};

    // 这里简化处理，实际应该使用 jsonDecode
    // 为了避免循环依赖，这里假设数据格式正确
    if (jsonString.contains('{')) {
      // 简单的键值对解析
      final pairs = jsonString
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll('"', '')
          .split(',');
      for (final pair in pairs) {
        final kv = pair.split(':');
        if (kv.length == 2) {
          data[kv[0].trim()] = kv[1].trim();
        }
      }
    }

    return data;
  } catch (e) {
    AppLogger.error('SyncWorker', '解析 JSON 失败: $e');
    return {};
  }
}
```

#### 2.2.3 实现方案

**修改文件**: `frontend_flutter/lib/data/sync/sync_worker.dart`

**步骤1**: 添加 import

```dart
import 'dart:convert';
```

**步骤2**: 替换 `_parseDataJson()` 方法

```dart
Map<String, dynamic> _parseDataJson(String jsonString) {
  try {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    AppLogger.error('SyncWorker', '解析 JSON 失败: $e');
    AppLogger.debug('SyncWorker', '原始数据: $jsonString');
    return {};
  }
}
```

#### 2.2.4 风险评估

| 风险 | 应对措施 |
|------|----------|
| 现有数据格式不兼容 | 添加数据迁移逻辑，清理格式错误的历史数据 |

#### 2.2.5 工作量估算

| 任务 | 时间 |
|------|------|
| 代码实现 | 0.2h |
| 测试验证 | 0.3h |
| **合计** | **0.5h** |

---

### 2.3 批量下载实现

#### 2.3.1 需求描述

在歌单详情页点击"下载全部"时，应将歌单中所有可下载的音频添加到下载队列，并跳转到下载页面。

#### 2.3.2 当前状态

**文件**: `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart`

```dart
// 第 445-457 行
void _downloadAll(WidgetRef ref, List items) {
  if (items.isEmpty) return;

  // TODO: 批量下载
  // for (final item in items) {
  //   ref.read(downloadViewModelProvider.notifier).addDownload(item.bvid);
  // }
  // context.push('/downloads');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('已添加 ${items.length} 首歌曲到下载队列')),
  );
}
```

#### 2.3.3 实现方案

**涉及文件**:
1. `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart`
2. `frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart`

**步骤1**: 在 PlaylistDetailViewModel 添加下载方法

```dart
// playlist_detail_viewmodel.dart

/// 批量下载歌单中的音频
///
/// 返回成功添加的下载任务数量
Future<int> downloadAll(List<PlaylistItem> items) async {
  int addedCount = 0;
  int skippedLocal = 0;
  int skippedDownloaded = 0;

  for (final item in items) {
    // 跳过本地音乐
    if (item.localPath?.isNotEmpty == true) {
      skippedLocal++;
      continue;
    }

    // 跳过已下载的音频
    if (await _downloadRepository.isDownloaded(item.bvid)) {
      skippedDownloaded++;
      continue;
    }

    // 添加到下载队列
    try {
      await _downloadViewModel.addDownload(
        bvid: item.bvid!,
        title: item.title,
        artist: item.artist,
        coverUrl: item.coverUrl,
        duration: item.duration,
      );
      addedCount++;
    } catch (e) {
      AppLogger.error('PlaylistDetailViewModel', '添加下载失败: ${item.bvid} - $e');
    }
  }

  AppLogger.info('PlaylistDetailViewModel',
    '批量下载: 添加$addedCount, 跳过本地$skippedLocal, 跳过已下载$skippedDownloaded');

  return addedCount;
}
```

**步骤2**: 修改页面 `_downloadAll()` 方法

```dart
// playlist_detail_page.dart

void _downloadAll(WidgetRef ref, List items) async {
  if (items.isEmpty) return;

  // 显示加载提示
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text('正在添加到下载队列...'),
        ],
      ),
      duration: Duration(seconds: 1),
    ),
  );

  // 调用 ViewModel 批量下载
  final addedCount = await ref.read(
    playlistDetailViewModelProvider(widget.playlistId).notifier,
  ).downloadAll(items.cast<PlaylistItem>());

  if (!mounted) return;

  // 显示结果提示
  String message;
  if (addedCount > 0) {
    message = '已添加 $addedCount 首到下载队列';
  } else {
    message = '没有需要下载的歌曲';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: addedCount > 0
          ? SnackBarAction(
              label: '查看下载',
              onPressed: () => context.push('/downloads'),
            )
          : null,
    ),
  );
}
```

#### 2.3.4 时序图

```
用户点击"下载全部"
        │
        ▼
PlaylistDetailPage._downloadAll()
        │
        ▼
PlaylistDetailViewModel.downloadAll()
        │
        ├─► 遍历所有 items
        │       │
        │       ├─► 检查本地音乐 → 跳过
        │       │
        │       ├─► 检查已下载 → 跳过
        │       │
        │       └─► DownloadViewModel.addDownload()
        │
        ▼
返回添加数量
```

#### 2.3.5 测试要点

| 用例 | 预期结果 |
|------|----------|
| 歌单包含在线音频 | 全部添加到下载队列 |
| 歌单包含本地音乐 | 跳过本地音乐，显示已跳过数量 |
| 歌单包含已下载音频 | 跳过已下载项 |
| 歌单为空 | 显示"没有需要下载的歌曲" |
| 网络中断后恢复 | 重试机制生效 |

#### 2.3.6 工作量估算

| 任务 | 时间 |
|------|------|
| ViewModel 方法实现 | 0.8h |
| 页面调用修改 | 0.5h |
| 测试验证 | 0.7h |
| **合计** | **2.0h** |

---

### 2.4 歌单项操作菜单

#### 2.4.1 需求描述

在歌单详情页的音频列表项中，添加操作菜单按钮，支持以下功能：
- 收藏/取消收藏
- 下载
- 加入其他歌单
- 从当前歌单移除
- 分享

#### 2.4.2 当前状态

**文件**: `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart`

```dart
// 第 274-276 行
// 暂时移除操作菜单，避免布局问题
// TODO: 添加简单的操作菜单（收藏、下载等）
trailing: const Icon(Icons.play_circle_outline, size: 20),
```

#### 2.4.3 实现方案

**复用现有组件**: `AudioActionMenu`

**修改文件**: `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart`

**步骤1**: 添加 import

```dart
import 'package:demo/presentation/widgets/audio/audio_action_menu.dart';
```

**步骤2**: 修改 `_buildItemTile()` 方法

```dart
Widget _buildItemTile(dynamic item, int index, WidgetRef ref) {
  // ... 现有属性获取代码不变

  return ListTile(
    // ... 现有属性
    leading: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (isLocalMusic)
          Icon(Icons.folder_open, size: 14, color: Colors.green),
      ],
    ),
    title: Row(
      children: [
        Expanded(
          child: Text(
            title ?? '未知标题',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    subtitle: Text(
      '${artist ?? '未知艺术家'}${duration != null ? ' • ${_formatDuration(duration)}' : ''}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: _buildItemTrailing(item, ref),
    onTap: () => _playItem(item, ref),
  );
}

Widget _buildItemTrailing(dynamic item, WidgetRef ref) {
  return PopupMenuButton<String>(
    icon: Icon(Icons.more_vert),
    iconSize: 20,
    onSelected: (action) => _onItemMenuAction(action, item, ref),
    itemBuilder: (context) => [
      PopupMenuItem(
        value: 'play',
        child: Row(
          children: [
            Icon(Icons.play_arrow, size: 18),
            SizedBox(width: 8),
            Text('播放'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'add_to_playlist',
        child: Row(
          children: [
            Icon(Icons.playlist_add, size: 18),
            SizedBox(width: 8),
            Text('添加到歌单'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'download',
        child: Row(
          children: [
            Icon(Icons.download, size: 18),
            SizedBox(width: 8),
            Text('下载'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'favorite',
        child: Row(
          children: [
            Icon(Icons.favorite_border, size: 18),
            SizedBox(width: 8),
            Text('收藏'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'share',
        child: Row(
          children: [
            Icon(Icons.share, size: 18),
            SizedBox(width: 8),
            Text('分享'),
          ],
        ),
      ),
      PopupMenuDivider(),
      PopupMenuItem(
        value: 'remove',
        child: Row(
          children: [
            Icon(Icons.delete, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('从歌单移除', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ],
  );
}

void _onItemMenuAction(String action, dynamic item, WidgetRef ref) {
  final bvid = item.bvid as String?;
  final title = item.title as String?;
  final artist = item.artist as String?;
  final coverUrl = item.coverUrl as String?;
  final duration = item.duration as int?;

  switch (action) {
    case 'play':
      _playItem(item, ref);
      break;
    case 'add_to_playlist':
      AudioActionMenu.show(
        context,
        bvid: bvid ?? '',
        title: title ?? '未知标题',
        artist: artist,
        coverUrl: coverUrl,
        duration: duration,
        showFavorite: false,
        showDownload: true,
      );
      break;
    case 'download':
      _handleDownload(item, ref);
      break;
    case 'favorite':
      _handleFavorite(item, ref);
      break;
    case 'share':
      _handleShare(bvid);
      break;
    case 'remove':
      _showRemoveConfirmDialog(item, ref);
      break;
  }
}

void _handleDownload(dynamic item, WidgetRef ref) async {
  try {
    await ref.read(downloadViewModelProvider.notifier).addDownload(
      bvid: item.bvid!,
      title: item.title,
      artist: item.artist,
      coverUrl: item.coverUrl,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加到下载队列')),
      );
    }
  } catch (e) {
    AppLogger.error('PlaylistDetailPage', '下载失败: $e');
  }
}

void _handleFavorite(dynamic item, WidgetRef ref) async {
  // 复用 AudioActionMenu 的收藏逻辑
  // 或者调用 PlaylistViewModel.toggleFavorite()
}

void _handleShare(String? bvid) {
  if (bvid == null) return;
  final url = 'https://www.bilibili.com/video/$bvid';
  // TODO: 使用系统分享API
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('分享功能开发中\n$url')),
  );
}

void _showRemoveConfirmDialog(dynamic item, WidgetRef ref) {
  showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('从歌单移除'),
      content: Text('确定要从歌单中移除 "${item.title}" 吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('移除', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  ).then((confirmed) {
    if (confirmed == true) {
      ref.read(playlistDetailViewModelProvider(widget.playlistId).notifier)
          .removeItem(item.bvid);
    }
  });
}
```

#### 2.4.4 UI布局

```
┌─────────────────────────────────────────────────────┐
│  1    标题文字........................    [⋮]      │
│       艺术家名称 · 时长                            │
├─────────────────────────────────────────────────────┤
│  2    标题文字........................    [⋮]      │
│       艺术家名称 · 时长                            │
├─────────────────────────────────────────────────────┤
│  3    标题文字........................    [⋮]      │
│       艺术家名称 · 时长                            │
└─────────────────────────────────────────────────────┘

点击 [⋮] 弹出菜单:
┌────────────────────┐
│ ▶ 播放             │
│ + 添加到歌单        │
│ ↓ 下载              │
│ ♡ 收藏              │
│ ↗ 分享              │
│ ─────────────────   │
│ 🗑 从歌单移除       │
└────────────────────┘
```

#### 2.4.5 工作量估算

| 任务 | 时间 |
|------|------|
| 代码实现 | 0.8h |
| UI调整和测试 | 0.5h |
| 测试验证 | 0.5h |
| **合计** | **1.8h** |

---

### 2.5 发现页第一Tab重构

#### 2.5.1 需求描述

| Tab | 当前内容 | 目标内容 |
|-----|----------|----------|
| Tab1 | "热门" (网格卡片) | "推荐" (列表卡片，类似搜索结果) |
| Tab2 | "开发中" | "热门" (保持原有的排行榜网格卡片) |

**Tab1 需求**:
- 内容: B站音乐区个性化推荐
- 布局: 列表形式（类似搜索结果页）
- 数据来源: 后端调用 B站推荐 API

#### 2.5.2 当前状态

**文件**: `frontend_flutter/lib/presentation/views/discovery/explore_page.dart`

```dart
// 第 26 行
static const List<String> _tabs = ['热门', '开发中'];

// 第 102-103 行
children: [
  _buildHotTab(exploreState),
  _buildComingSoonTab(),
],
```

#### 2.5.3 实现方案

**涉及文件**:
1. `frontend_flutter/lib/presentation/views/discovery/explore_page.dart`
2. `frontend_flutter/lib/presentation/viewmodels/discovery/explore_viewmodel.dart`
3. `listen-vision_api/services/bilibiliService.js`
4. `listen-vision_api/routes/bilibili.js`
5. `listen-vision_api/controllers/bilibiliController.js`

**步骤1**: 后端 - 添加推荐 API

**文件**: `listen-vision_api/services/bilibiliService.js`

```javascript
/**
 * 获取B站推荐视频
 *
 * API: GET https://api.bilibili.com/x/web-interface/index/top/rcmd?ps=20&rid=3
 *
 * @param {number} userId - 用户ID（用于获取Cookie）
 * @param {number} page - 页码
 * @param {number} pageSize - 每页数量
 * @returns {Object} 推荐视频列表
 */
const getRecommendedVideos = async (userId = null, page = 1, pageSize = 20) => {
  try {
    // rid=3 表示音乐区
    const url = `https://api.bilibili.com/x/web-interface/index/top/rcmd?ps=${pageSize}&rid=3`;

    const headers = {};
    if (userId) {
      const cookie = getCookie(userId);
      if (cookie) {
        headers['Cookie'] = cookie;
      }
    }

    const data = await httpGet(url, headers);

    if (data.code !== 0) {
      throw new Error(data.message || '获取推荐失败');
    }

    const list = data.data?.list || [];

    return {
      videos: list.map(item => ({
        bvid: item.bvid,
        title: item.title,
        cover: item.pic,
        duration: item.duration,
        author: item.owner?.name || item.author,
        play: item.stat?.view || item.play,
        description: item.desc,
        pubdate: item.pubdate,
      })),
      page,
      pageSize,
      total: list.length,
    };
  } catch (error) {
    throw new Error(`获取推荐失败: ${error.message}`);
  }
};
```

**步骤2**: 后端 - 添加路由

**文件**: `listen-vision_api/routes/bilibili.js`

```javascript
/**
 * @swagger
 * /api/bilibili/recommend:
 *   get:
 *     tags: [B站API]
 *     summary: 获取B站音乐区推荐
 *     description: 获取B站音乐区的个性化推荐视频
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: 页码
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *           default: 20
 *         description: 每页数量
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/recommend', optionalAuthMiddleware, bilibiliController.getRecommendedVideos);
```

**步骤3**: 后端 - 添加控制器

**文件**: `listen-vision_api/controllers/bilibiliController.js`

```javascript
/**
 * 获取B站推荐视频
 */
const getRecommendedVideos = async (req, res) => {
  try {
    const { page = 1, pageSize = 20 } = req.query;
    const userId = req.user?.id || null;

    const result = await bilibiliService.getRecommendedVideos(
      userId,
      parseInt(page) || 1,
      parseInt(pageSize) || 20
    );

    successResponse(res, result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
```

**步骤4**: 前端 - 修改 ViewModel

**文件**: `frontend_flutter/lib/presentation/viewmodels/discovery/explore_viewmodel.dart`

```dart
// 添加新方法
Future<bool> loadRecommend({int page = 1}) async {
  try {
    AppLogger.info('ExploreViewModel', '加载推荐: page=$page');

    if (!ref.mounted) return false;
    state = const AsyncLoading();

    final data = await _apiClient!.getRecommend(
      page: page,
      pageSize: _pageSize,
    );

    final videos = data['videos'] as List? ?? [];
    final total = data['total'] as int? ?? 0;

    final items = videos.map((v) {
      return ExploreItem.fromJson(v as Map<String, dynamic>);
    }).toList();

    final hasMore = (page * _pageSize) < total;

    if (!ref.mounted) return false;
    state = AsyncData(ExploreState.loaded(
      items: items,
      hasMore: hasMore,
      currentPage: page,
      type: ExploreType.recommended,
    ));

    AppLogger.info('ExploreViewModel', '推荐加载成功: ${items.length}条');
    return true;
  } catch (e) {
    AppLogger.error('ExploreViewModel', '加载推荐失败: $e');
    if (!ref.mounted) return false;
    state = AsyncError(e, StackTrace.current);
    return false;
  }
}
```

**步骤5**: 前端 - 修改页面 Tab 配置

**文件**: `frontend_flutter/lib/presentation/views/discovery/explore_page.dart`

```dart
// 第 26 行
static const List<String> _tabs = ['推荐', '热门'];

// 第 102-103 行
children: [
  _buildRecommendTab(exploreState),
  _buildHotTab(exploreState),
],
```

**步骤6**: 前端 - 添加推荐 Tab 列表布局

```dart
/// 构建推荐Tab（列表形式）
Widget _buildRecommendTab(AsyncValue<ExploreState> exploreState) {
  return exploreState.when(
    loading: () => _buildLoadingView(),
    error: (e, _) => _buildErrorView(e.toString()),
    data: (state) {
      return state.when(
        initial: () => _buildLoadingView(),
        loading: () => _buildLoadingView(),
        notBound: () => _buildNotBoundPrompt(),
        loaded: (items, _, _, _) => _buildRecommendList(items),
        error: (message) => _buildErrorView(message),
      );
    },
  );
}

/// 构建推荐列表（类似搜索结果）
Widget _buildRecommendList(List<ExploreItem> items) {
  if (items.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无推荐内容', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: () => ref.read(exploreViewModelProvider.notifier).refresh(),
    child: ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildRecommendItem(item, index);
      },
    ),
  );
}

/// 构建推荐列表项（类似搜索结果项）
Widget _buildRecommendItem(ExploreItem item, int index) {
  return Card(
    child: ListTile(
      leading: SizedBox(
        width: 80,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.coverUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.music_note),
                ),
              ),
            ),
            if (item.duration != null)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  color: Colors.black54,
                  child: Text(
                    _formatDuration(item.duration!),
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              item.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          if (item.playCount != null)
            Text(
              ' ${_formatPlayCount(item.playCount!)} ',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
        ],
      ),
      trailing: _buildItemTrailing(item),
      onTap: () => _playAudio(item),
    ),
  );
}

Widget _buildItemTrailing(ExploreItem item) {
  return PopupMenuButton<String>(
    icon: Icon(Icons.more_vert),
    iconSize: 20,
    onSelected: (action) => _onItemAction(action, item),
    itemBuilder: (context) => [
      PopupMenuItem(value: 'add_to_playlist', child: Text('添加到歌单')),
      PopupMenuItem(value: 'favorite', child: Text('收藏')),
      PopupMenuItem(value: 'download', child: Text('下载')),
      PopupMenuItem(value: 'share', child: Text('分享')),
    ],
  );
}

void _onItemAction(String action, ExploreItem item) {
  switch (action) {
    case 'add_to_playlist':
      AudioActionMenu.show(
        context,
        bvid: item.bvid,
        title: item.title,
        artist: item.author,
        coverUrl: item.coverUrl,
        duration: item.duration,
      );
      break;
    case 'favorite':
      // 收藏逻辑
      break;
    case 'download':
      // 下载逻辑
      break;
    case 'share':
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享功能开发中')),
      );
      break;
  }
}

String _formatPlayCount(int count) {
  if (count >= 100000000) {
    return '${(count / 100000000).toStringAsFixed(1)}亿';
  }
  if (count >= 10000) {
    return '${(count / 10000).toStringAsFixed(1)}万';
  }
  return count.toString();
}
```

#### 2.5.4 API 响应格式

```json
{
  "success": true,
  "data": {
    "videos": [
      {
        "bvid": "BV1xx411c7mD",
        "title": "【音乐】xxxx",
        "cover": "https://i0.hdslb.com/bfs/archive/xxx.jpg",
        "duration": 245,
        "author": "UP主名",
        "play": 1234567,
        "description": "视频描述",
        "pubdate": 1672502400
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 20
  }
}
```

#### 2.5.5 UI 对比

**Tab1 - 推荐（列表形式）**

```
┌─────────────────────────────────────────────────────┐
│ ▶ 【音乐】xxxxxxx........................  [⋮]      │
│    UP主名 · 123.4万播放                          │
├─────────────────────────────────────────────────────┤
│ ▶ 【音乐】yyyyyyy........................  [⋮]      │
│    UPyyname · 56.7万播放                         │
├─────────────────────────────────────────────────────┤
│ ▶ 【音乐】zzzzzzz........................  [⋮]      │
│    UPzzname · 89.1万播放                         │
└─────────────────────────────────────────────────────┘
```

**Tab2 - 热门（保持网格卡片）**

```
┌──────────┬──────────┐
│ ┌────────┐ │ ┌────────┐ │
│ │ 封面   │ │ │ 封面   │ │
│ │ #1     │ │ │ #2     │ │
│ └────────┘ │ └────────┘ │
│ 标题xxx   │  标题yyy   │
│ UP主·时长 │ UP主·时长  │
├──────────┼──────────┤
│ ┌────────┐ │ ┌────────┐ │
│ │ 封面   │ │ │ 封面   │ │
│ │ #3     │ │ │ #4     │ │
│ └────────┘ │ └────────┘ │
│ 标题zzz   │  标题aaa   │
└──────────┴──────────┘
```

#### 2.5.6 测试要点

| 用例 | 预期结果 |
|------|----------|
| Tab1 显示推荐列表 | 显示B站音乐区推荐视频 |
| Tab2 显示热门网格 | 显示原有排行榜内容 |
| 点击列表项 | 播放对应音频 |
| 列表项操作菜单 | 显示操作选项 |
| 下拉刷新 | 刷新推荐内容 |
| 登录前访问 | 显示绑定提示 |

#### 2.5.7 工作量估算

| 任务 | 时间 |
|------|------|
| 后端推荐API | 1.0h |
| 后端路由和控制器 | 0.5h |
| 前端ViewModel | 0.5h |
| 前端页面Tab调整 | 0.5h |
| 前端推荐列表UI | 1.0h |
| 测试验证 | 0.5h |
| **合计** | **4.0h** |

---

### 2.6 B站Cookie刷新机制

#### 2.6.1 需求描述

B站Cookie有效期约30天，目前：
1. 未实现Cookie自动刷新
2. Cookie过期后需用户重新扫码绑定

**目标**: 实现Cookie自动刷新，在过期前主动刷新，避免用户重新绑定。

#### 2.6.2 当前状态

**文件**: `listen-vision_api/services/bilibiliService.js`

```javascript
// 第 432-437 行
const refreshCookie = async (userId) => {
  // Cookie 刷新逻辑：调用 B站 refresh_token API 更新过期 Cookie
  // 参考文档：bilibili-API-collect/docs/login/login_action/QR.md
  // 当前暂不实现，用户重新扫码登录即可
  return true;
};
```

**数据库表结构**:

```sql
CREATE TABLE bilibili_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  bili_user_id TEXT,
  bili_username TEXT,
  cookie_encrypted TEXT NOT NULL,
  is_active INTEGER DEFAULT 1,
  expires_at TEXT,
  created_at TEXT,
  updated_at TEXT
);
```

#### 2.6.3 实现方案

**涉及文件**:
1. `listen-vision_api/services/bilibiliService.js`
2. 数据库迁移脚本

**步骤1**: 数据库迁移 - 添加 refresh_token 字段

```sql
-- 方案A: ALTER TABLE
ALTER TABLE bilibili_accounts ADD COLUMN refresh_token TEXT;

-- 方案B: 创建迁移脚本文件
-- migrations/2026-02-09-add-refresh-token.sql
```

**步骤2**: 修改 QR码登录响应处理 - 保存 refresh_token

**文件**: `listen-vision_api/services/bilibiliService.js`

**修改 `checkQRLoginStatus()` 返回值处理**:

```javascript
// 第 290-291 行附近
// 登录成功后检查是否有 refresh_token
if (data.data?.refresh_token) {
  logger.debug('[QR码检查] 获取到 refresh_token');
}
```

**修改 `saveCookie()` 方法**:

```javascript
const saveCookie = async (userId, cookie, userInfo = {}, refreshToken = null) => {
  const encrypted = encryptCookie(cookie);
  const biliUserId = userInfo.mid || userInfo.uid || '';
  const biliUsername = userInfo.uname || '';

  const encryptedRefreshToken = refreshToken
    ? encryptCookie(refreshToken)
    : null;

  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    .toISOString().replace('T', ' ').substring(0, 19);

  const existing = stmt.getActiveBiliAccount.get(userId);

  if (existing) {
    // 更新现有绑定
    stmt.updateBiliAccountWithRefresh.run(
      biliUserId,
      biliUsername,
      encrypted,
      encryptedRefreshToken,
      expiresAt,
      existing.id
    );
  } else {
    // 创建新绑定
    stmt.insertBiliAccount.run(
      userId,
      biliUserId,
      biliUsername,
      encrypted,
      encryptedRefreshToken,
      expiresAt
    );
  }

  return { success: true };
};
```

**添加预编译语句**:

```javascript
const stmt = {
  // ... 现有语句
  updateBiliAccountWithRefresh: db.prepare(`
    UPDATE bilibili_accounts
    SET bili_user_id = ?,
        bili_username = ?,
        cookie_encrypted = ?,
        refresh_token_encrypted = ?,
        is_active = 1,
        updated_at = datetime('now')
    WHERE id = ?
  `),
};
```

**步骤3**: 实现刷新逻辑

**修改 `refreshCookie()` 方法**:

```javascript
/**
 * 刷新Cookie（如果即将过期）
 *
 * 刷新策略：
 * 1. 每日定时检查所有活跃账号
 * 2. 距离过期不足7天时触发刷新
 * 3. 使用 refresh_token 调用B站API
 *
 * @param {number} userId - 用户ID
 * @returns {boolean} 是否成功
 */
const refreshCookie = async (userId) => {
  try {
    const account = stmt.getActiveBiliAccount.get(userId);
    if (!account) {
      logger.warn('[Cookie刷新] 账号不存在或已停用: userId=$userId');
      return false;
    }

    // 检查是否有 refresh_token
    if (!account.refresh_token_encrypted) {
      logger.warn('[Cookie刷新] 无 refresh_token，无法刷新');
      return false;
    }

    // 解密 refresh_token
    const refreshToken = decryptCookie(account.refresh_token_encrypted);
    if (!refreshToken) {
      logger.warn('[Cookie刷新] refresh_token 解密失败');
      return false;
    }

    // 调用B站刷新API
    const url = 'https://passport.bilibili.com/x/passport-login/web/cookie/refresh';
    const response = await httpPost(
      url,
      {
        refresh_token: refreshToken,
        csrf: extractBiliJct(account.cookie_encrypted),
      },
      {
        'Cookie': decryptCookie(account.cookie_encrypted) || '',
      }
    );

    logger.debug('[Cookie刷新] API响应: %o', response);

    if (response.code !== 0) {
      logger.error('[Cookie刷新] 失败: %s', response.message);
      return false;
    }

    // 更新Cookie和refresh_token
    const newCookie = response.data.cookie || response.data.refresh_token;
    const newRefreshToken = response.data.refresh_token || refreshToken;

    if (newCookie) {
      const encryptedCookie = encryptCookie(newCookie);
      const encryptedNewRefreshToken = encryptCookie(newRefreshToken);

      const newExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);

      stmt.updateBiliAccountWithRefresh.run(
        account.bili_user_id,
        account.bili_username,
        encryptedCookie,
        encryptedNewRefreshToken,
        newExpiresAt,
        account.id
      );

      logger.info('[Cookie刷新] 成功: userId=$userId');
      return true;
    }

    return false;
  } catch (error) {
    logger.error('[Cookie刷新] 异常: %s', error.message);
    return false;
  }
};

/**
 * 从Cookie中提取 bili_jct
 */
const extractBiliJct = (cookieEncrypted) => {
  try {
    const cookie = decryptCookie(cookieEncrypted);
    if (!cookie) return '';
    const match = cookie.match(/bili_jct=([^;]+)/);
    return match ? match[1] : '';
  } catch (e) {
    return '';
  }
};
```

**步骤4**: 定时任务 - 每日检查刷新

**新建文件**: `listen-vision_api/services/cookieRefreshScheduler.js`

```javascript
const { logger } = require('../utils/logger');
const bilibiliService = require('./bilibiliService');

/**
 * Cookie刷新调度器
 *
 * 功能：
 * 1. 每日定时检查所有活跃的B站绑定
 * 2. 距离过期不足7天时触发刷新
 * 3. 记录刷新结果和失败原因
 */
class CookieRefreshScheduler {
  constructor() {
    this.isRunning = false;
    this.checkIntervalMs = 24 * 60 * 60 * 1000; // 24小时
    this.refreshThresholdDays = 7; // 提前7天刷新
    this.timer = null;
  }

  /**
   * 启动调度器
   */
  start() {
    if (this.isRunning) {
      logger.warn('[CookieRefreshScheduler] 调度器已在运行');
      return;
    }

    this.isRunning = true;
    logger.info('[CookieRefreshScheduler] 启动Cookie刷新调度器');

    // 立即执行一次检查
    this.checkAndRefreshAll();

    // 设置定时任务
    this.timer = setInterval(() => {
      this.checkAndRefreshAll();
    }, this.checkIntervalMs);
  }

  /**
   * 停止调度器
   */
  stop() {
    if (!this.isRunning) return;

    this.isRunning = false;
    this.timer?.clear();
    this.timer = null;

    logger.info('[CookieRefreshScheduler] 已停止Cookie刷新调度器');
  }

  /**
   * 检查并刷新所有账号
   */
  async checkAndRefreshAll() {
    try {
      logger.info('[CookieRefreshScheduler] 开始检查所有B站绑定账号');

      const stmt = require('../config/database').prepare(
        'SELECT * FROM bilibili_accounts WHERE is_active = 1'
      );
      const accounts = stmt.all();

      let refreshed = 0;
      let skipped = 0;
      let failed = 0;

      for (const account of accounts) {
        const result = await this.checkAndRefreshAccount(account);
        if (result === 'refreshed') refreshed++;
        else if (result === 'skipped') skipped++;
        else if (result === 'failed') failed++;
      }

      logger.info(
        '[CookieRefreshScheduler] 检查完成: 刷新$refreshed, 跳过$skipped, 失败$failed'
      );
    } catch (error) {
      logger.error('[CookieRefreshScheduler] 检查异常: %s', error.message);
    }
  }

  /**
   * 检查单个账号是否需要刷新
   *
   * @param {Object} account - 账号信息
   * @returns {string} 'refreshed' | 'skipped' | 'failed'
   */
  async checkAndRefreshAccount(account) {
    try {
      const expiresAt = new Date(account.expires_at);
      const now = new Date();
      const daysLeft = (expiresAt - now) / (1000 * 60 * 60 * 24);

      // 如果距离过期超过阈值，跳过
      if (daysLeft > this.refreshThresholdDays) {
        return 'skipped';
      }

      // 尝试刷新
      const success = await bilibiliService.refreshCookie(account.user_id);

      if (success) {
        return 'refreshed';
      } else {
        // 刷新失败，检查是否已过期
        if (daysLeft <= 0) {
          // 已过期，停用账号
          const db = require('../config/database');
          db.prepare(
            'UPDATE bilibili_accounts SET is_active = 0 WHERE id = ?'
          ).run(account.id);
          logger.warn(
            '[CookieRefreshScheduler] 账号已过期，已停用: userId=$account.user_id'
          );
        }
        return 'failed';
      }
    } catch (error) {
      logger.error(
        '[CookieRefreshScheduler] 检查账号异常: %s',
        error.message
      );
      return 'failed';
    }
  }
}

module.exports = new CookieRefreshScheduler();
```

**步骤5**: 在应用启动时启用调度器

**文件**: `listen-vision_api/index.js`

```javascript
// 添加调度器
const cookieRefreshScheduler = require('./services/cookieRefreshScheduler');

// 启动后启动Cookie刷新调度器
cookieRefreshScheduler.start();
```

**步骤6**: 添加手动刷新接口（可选）

```javascript
// routes/bilibili.js

/**
 * @swagger
 * /api/bilibili/refresh-cookie:
 *   post:
 *     tags: [B站API]
 *     summary: 手动刷新Cookie
 *     description: 手动触发当前用户的B站Cookie刷新
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 刷新成功
 *       400:
 *         description: 刷新失败或无需刷新
 */
router.post('/refresh-cookie', authMiddleware, async (req, res) => {
  try {
    const success = await bilibiliService.refreshCookie(req.user.id);

    if (success) {
      successResponse(res, { refreshed: true }, 'Cookie刷新成功');
    } else {
      res.status(400).json({
        success: false,
        error: 'Cookie刷新失败或无需刷新',
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
```

#### 2.6.4 数据流

```
┌─────────────────────────────────────────────────────────────┐
│                    每日定时任务                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              CookieRefreshScheduler.checkAndRefreshAll()    │
│                    检查所有活跃账号                          │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
        距离过期>7天              距离过期≤7天
        ──────────────            ──────────────
        跳过检查                   调用 refreshCookie()
                                                    │
                                                    ▼
                                    ┌─────────────────────────────┐
                                    │  POST /cookie/refresh       │
                                    │  - refresh_token           │
                                    │  - csrf                     │
                                    └─────────────────────────────┘
                                                    │
                                    ┌───────────────┴───────────────┐
                                    ▼                               ▼
                            刷新成功                          刷新失败
                            ─────────                       ─────────
                            更新数据库                       检查是否过期
                            返回success                     过期则停用账号
```

#### 2.6.5 错误处理

| 错误码 | 处理方式 |
|--------|----------|
| -6 (refresh_token无效) | 停用账号，提示用户重新绑定 |
| -7 (refresh_token过期) | 停用账号，提示用户重新绑定 |
| -652 (请求过于频繁) | 延迟重试，最多重试3次 |
| 网络错误 | 记录日志，下次定时任务重试 |

#### 2.6.6 工作量估算

| 任务 | 时间 |
|------|------|
| 数据库迁移脚本 | 0.3h |
| 修改 saveCookie() | 0.3h |
| 实现 refreshCookie() | 1.0h |
| 创建调度器 | 0.8h |
| 添加手动刷新接口 | 0.3h |
| 集成到应用启动 | 0.2h |
| 测试验证 | 0.5h |
| **合计** | **3.4h** |

---

## 三、项目总工作量

| 功能 | 前端 | 后端 | 数据库 | 测试 | 合计 |
|------|------|------|--------|------|------|
| 播放历史点击播放 | 0.5h | - | - | 0.2h | 0.7h |
| SyncWorker JSON修复 | 0.5h | - | - | 0.2h | 0.7h |
| 批量下载实现 | 2.0h | - | - | 0.5h | 2.5h |
| 歌单项操作菜单 | 1.5h | - | - | 0.3h | 1.8h |
| 发现页推荐Tab | 3.0h | 1.5h | - | 0.5h | 5.0h |
| Cookie刷新机制 | - | 2.5h | 0.3h | 0.5h | 3.3h |
| **总计** | **7.5h** | **4.0h** | **0.3h** | **2.2h** | **14.0h** |

---

## 四、实施计划

### 4.1 第一阶段（P0 - 高优先级）

| 序号 | 任务 | 时间 | 依赖 |
|------|------|------|------|
| 1 | SyncWorker JSON解析修复 | 0.7h | - |
| 2 | 播放历史点击播放 | 0.7h | - |
| 3 | 歌单项操作菜单 | 1.8h | AudioActionMenu组件 |

### 4.2 第二阶段（P1 - 中优先级）

| 序号 | 任务 | 时间 | 依赖 |
|------|------|------|------|
| 4 | 批量下载实现 | 2.5h | DownloadViewModel |
| 5 | 发现页推荐Tab | 5.0h | 后端API |
| 6 | 后端推荐API | 1.5h | - |

### 4.3 第三阶段（P2 - 低优先级）

| 序号 | 任务 | 时间 | 依赖 |
|------|------|------|------|
| 7 | Cookie刷新机制 | 3.3h | 数据库迁移 |

---

## 五、风险与缓解

### 5.1 技术风险

| 风险 | 影响 | 可能性 | 缓解措施 |
|------|------|--------|----------|
| B站推荐API变更 | Tab1无法获取数据 | 中 | 预留fallback方案，使用搜索API代替 |
| B站刷新API频率限制 | 刷新失败 | 低 | 添加重试和错误处理 |
| 数据库迁移失败 | 应用启动异常 | 低 | 预先备份，执行迁移前验证 |

### 5.2 用户体验风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 批量下载触发B站限流 | 下载失败 | 控制并发数，单次最多3个 |
| Cookie刷新失败需重新绑定 | 用户体验下降 | 提前7天刷新，减少触发 |

---

## 六、验收标准

### 6.1 功能验收

| 功能 | 验收标准 |
|------|----------|
| 播放历史点击 | 点击任意历史记录可播放并跳转 |
| SyncWorker | JSON数据解析正确，无数据丢失 |
| 批量下载 | 歌单下载正确，跳过本地和已下载项 |
| 歌单操作菜单 | 每个音频项可进行收藏/下载/分享等操作 |
| 发现页Tab1 | 显示B站音乐区推荐，类似搜索结果列表 |
| 发现页Tab2 | 显示热门排行榜，保持网格卡片布局 |
| Cookie刷新 | 过期前自动刷新，用户无感知 |

### 6.2 性能验收

| 指标 | 标准 |
|------|------|
| 批量下载并发 | 同时最多3个下载任务 |
| 推荐加载时间 | < 2秒 |
| Cookie刷新调度 | 24小时周期检查 |

---

## 七、附录

### 7.1 相关文件清单

```
frontend_flutter/
├── lib/
│   ├── presentation/
│   │   ├── views/
│   │   │   ├── library/
│   │   │   │   ├── play_history_page.dart    # 修改
│   │   │   │   └── playlist_detail_page.dart # 修改
│   │   │   └── discovery/
│   │   │       └── explore_page.dart         # 修改
│   │   └── viewmodels/
│   │       ├── library/
│   │       │   └── playlist_detail_viewmodel.dart # 修改
│   │       └── discovery/
│   │           └── explore_viewmodel.dart    # 修改
│   └── data/
│       └── sync/
│           └── sync_worker.dart             # 修改
│
listen-vision_api/
├── services/
│   ├── bilibiliService.js      # 修改
│   └── cookieRefreshScheduler.js # 新建
├── routes/
│   └── bilibili.js             # 修改
├── controllers/
│   └── bilibiliController.js   # 修改
└── migrations/
    └── 2026-02-09-add-refresh-token.sql  # 新建
```

### 7.2 参考文档

- B站API文档: `references/bilibili-API-collect/`
- Riverpod指南: `docs/RIVERPOD_GUIDE.md`
- 代码注释规范: `docs/CODE_COMMENT_STANDARDS.md`

---

> 文档版本: v1.0
> 最后更新: 2026-02-09
