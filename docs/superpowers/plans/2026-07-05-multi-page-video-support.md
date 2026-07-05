# 多P视频（合集）支持 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 支持B站多P视频（合集）的搜索、分P选择和逐P播放

**Architecture:** 数据层加 `videos`/`AudioPage` → API层支持按 CID 获取流 → UI层加多P标签和分P选择面板 → 播放层去重用 `bvid + cid`

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Riverpod, Freezed, Dio

## Global Constraints

- 单P视频体验不变
- 搜索时不预加载 pages（按需获取）
- 网络错误时 Toast 提示，不崩溃
- `pages` 字段仅在多P时非空，默认 null

---

## 文件结构

| 文件 | 改动类型 | 职责 |
|------|----------|------|
| `models/audio.dart` | 修改 | 新增 `videos`、`AudioPage` 类 |
| `services/bilibili_api_service.dart` | 修改 | 搜索传 `videos`；`getAudioStreams` 可选 `cid`；新增 `getVideoPages` |
| `models/online_playable.dart` | 修改 | `id` getter 含 cid（去重用） |
| `presentation/viewmodels/discovery/search_viewmodel.dart` | 修改 | `SearchResultItem` 加 `videos`；`search()` 传递 |
| `presentation/viewmodels/player/playback_viewmodel.dart` | 修改 | `_resolveOnlineStreamUrl` 传入 cid |
| `presentation/views/discovery/search_page.dart` | 修改 | 多P标签；`_onResultTap` 分支逻辑 |
| `presentation/widgets/video_pages_sheet.dart` | **新建** | 分P选择底部面板 |

---

### Task 1: Audio 模型 — 新增 `videos` 字段和 `AudioPage` 类

**Files:**
- Modify: `frontend_flutter/lib/models/audio.dart`

**Interfaces:**
- Produces: `Audio.videos` (int, default 1), `Audio.pages` (List<AudioPage>?, default null), `AudioPage` class (cid, title, duration, formattedDuration)

- [ ] **Step 1: 在 `audio.dart` 顶部（import/freezed 之间）添加 `AudioPage` 类**

```dart
/// 视频分P信息
class AudioPage {
  final int cid;
  final String title;
  final int duration; // 秒

  const AudioPage({
    required this.cid,
    required this.title,
    required this.duration,
  });

  /// 格式化时长（mm:ss）
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 静态格式化（供外部使用）
  static String formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 2: 在 `Audio` factory 构造函数中添加 `videos` 和 `pages` 字段**

将（约第 12 行）：
```dart
const factory Audio({
    required String id, // BV号或 local_{hash}
    required String title,
    ...
    int? cid, // B站视频分P ID
  }) = _Audio;
```

改为：
```dart
const factory Audio({
    required String id, // BV号或 local_{hash}
    required String title,
    String? artist,
    String? album,
    String? coverUrl,
    String? streamUrl,
    int? duration, // 秒
    String? description,
    int? playCount,
    String? uploader,
    String? uploaderMid,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? localPath,
    int? cid, // B站视频分P ID
    @Default(1) int videos, // 分P总数，默认1
    List<AudioPage>? pages, // 分P列表，单P时为null
  }) = _Audio;
```

- [ ] **Step 3: 在 `fromDto` 中解析 `videos` 字段**

在 `fromDto` 方法中（约第 74-91 行），修改 Audio 构造函数调用，添加 `videos`：

```dart
return Audio(
    id: safeString(json['bvid'] ?? json['id'] ?? json['bvId']) ?? '',
    title: safeString(json['title']) ?? '',
    artist: safeString(json['artist'] ?? json['author'] ?? json['uname']),
    album: safeString(json['album']),
    coverUrl: safeCoverUrl(),
    streamUrl: safeString(json['stream_url'] ?? json['streamUrl']),
    duration: _parseDuration(json['duration']),
    description: safeString(json['description'] ?? json['desc']),
    playCount: _parsePlayCount(json['play']),
    uploader: safeString(json['uploader'] ?? json['author']),
    uploaderMid: safeString(json['uploader_mid'] ?? json['mid']),
    publishedAt: _parseDateTime(json['pubdate'] ?? json['published_at'] ?? json['publishedAt']),
    createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    localPath: safeString(json['local_path'] ?? json['localPath']),
    cid: _parseCid(json['cid']),
    videos: _parseIntWithDefault(json['videos'], 1),
  );
```

- [ ] **Step 4: 添加 `_parseIntWithDefault` 静态方法**

在 `_parseCid` 方法之后添加：

```dart
  /// 解析整数（带默认值）
  static int _parseIntWithDefault(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
```

- [ ] **Step 5: 运行 build_runner 生成 freezed 代码**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: 验证编译通过**

```bash
cd frontend_flutter && flutter analyze lib/models/audio.dart
```

Expected: No issues found.

- [ ] **Step 7: Commit**

```bash
git add frontend_flutter/lib/models/audio.dart frontend_flutter/lib/models/audio.freezed.dart frontend_flutter/lib/models/audio.g.dart
git commit -m "feat: Audio 模型新增 videos 字段和 AudioPage 类

为多P视频（合集）支持做数据层准备：
- Audio 新增 videos（分P总数，默认1）和 pages（分P列表）字段
- AudioPage 类：cid、title、duration、formattedDuration
- fromDto 解析 videos 字段"
```

---

### Task 2: API 服务层 — `search()` 传 `videos`，`getAudioStreams` 支持 `cid`，新增 `getVideoPages`

**Files:**
- Modify: `frontend_flutter/lib/services/bilibili_api_service.dart:95-166`

**Interfaces:**
- Consumes: `AudioPage` from Task 1
- Produces: `getAudioStreams(bvid, {int? cid, ...})`, `getVideoPages(bvid) -> List<AudioPage>`, search DTO includes `videos`

- [ ] **Step 1: 修改 `getAudioStreams` 签名和方法体，支持可选 `cid` 参数**

将（约第 95-134 行）：
```dart
  Future<AudioStreamsData> getAudioStreams(
    String bvid, {
    Map<String, String>? cookies,
  }) async {
    final videoInfo = await getVideoInfo(bvid);
    final cid = videoInfo['cid'];
    if (cid == null) throw Exception('无法获取 cid');
```

改为：
```dart
  Future<AudioStreamsData> getAudioStreams(
    String bvid, {
    int? cid,
    Map<String, String>? cookies,
  }) async {
    int resolvedCid;
    if (cid != null) {
      resolvedCid = cid;
    } else {
      final videoInfo = await getVideoInfo(bvid);
      final c = videoInfo['cid'];
      if (c == null) throw Exception('无法获取 cid');
      resolvedCid = c is int ? c : int.parse('$c');
    }
```

然后将方法体内使用 `cid` 变量的地方改为 `resolvedCid`：
```dart
    final response = await _dio.get(
      '$_baseUrl/x/player/wbi/playurl',
      queryParameters: {
        'bvid': bvid,
        'cid': resolvedCid,
        'fnval': 16,
        'fnver': 0,
        'fourk': 1,
      },
      options: Options(headers: _buildHeaders(cookies: cookies)),
    );
```

并将最后的返回语句：
```dart
    return AudioStreamsData(
      bvid: bvid,
      cid: cid ?? 0,
      title: videoInfo['title'] ?? '',
      streams: streams,
    );
```

改为（当 cid 被传入时无法获取 title，用空字符串）：
```dart
    return AudioStreamsData(
      bvid: bvid,
      cid: resolvedCid,
      title: '', // title 在此场景下由调用方提供
      streams: streams,
    );
```

等一等，这样写不好——当 cid 传入时 `videoInfo` 变量不在作用域内。让我重新考虑：

实际的改法是需要保证无论是否传 cid，当 cid 未传入时仍需要调 getVideoInfo 获取 title 和 cid；当 cid 传入时只需要用给定的 cid 请求流即可。

```dart
  Future<AudioStreamsData> getAudioStreams(
    String bvid, {
    int? cid,
    Map<String, String>? cookies,
  }) async {
    int resolvedCid;
    String title = '';
    
    if (cid != null) {
      resolvedCid = cid;
    } else {
      final videoInfo = await getVideoInfo(bvid);
      final c = videoInfo['cid'];
      if (c == null) throw Exception('无法获取 cid');
      resolvedCid = c is int ? c : int.parse('$c');
      title = videoInfo['title'] ?? '';
    }

    final response = await _dio.get(
      '$_baseUrl/x/player/wbi/playurl',
      queryParameters: {
        'bvid': bvid,
        'cid': resolvedCid,
        'fnval': 16,
        'fnver': 0,
        'fourk': 1,
      },
      options: Options(headers: _buildHeaders(cookies: cookies)),
    );
    final data = _extractData(response.data);
    final dashAudio = data['dash']?['audio'] as List<dynamic>? ?? [];

    final streams = dashAudio.map((audio) {
      return AudioStreamInfo(
        url: normalizeBilibiliUrl(
          audio['baseUrl'] ?? audio['base_url'] ?? '',
        ),
        qualityId: audio['id'] ?? 0,
        size: audio['size'] ?? 0,
        codecs: audio['codecs'] ?? '',
      );
    }).toList();

    return AudioStreamsData(
      bvid: bvid,
      cid: resolvedCid,
      title: title,
      streams: streams,
    );
  }
```

- [ ] **Step 2: 在 `search` 方法的 DTO map 中添加 `'videos'` 字段**

将（约第 157-165 行）：
```dart
      return Audio.fromDto({
        'bvid': item['bvid'],
        'title': _cleanHtmlTags(item['title'] ?? ''),
        'author': item['author'] ?? '',
        'pic': normalizeBilibiliUrl(item['pic'] ?? ''),
        'duration': parseBilibiliDuration(item['duration']),
        'play': item['play'] ?? 0,
      });
```

改为：
```dart
      return Audio.fromDto({
        'bvid': item['bvid'],
        'title': _cleanHtmlTags(item['title'] ?? ''),
        'author': item['author'] ?? '',
        'pic': normalizeBilibiliUrl(item['pic'] ?? ''),
        'duration': parseBilibiliDuration(item['duration']),
        'play': item['play'] ?? 0,
        'videos': item['videos'] ?? 1,
      });
```

- [ ] **Step 3: 添加 `getVideoPages` 方法**

在 `getAudioStreams` 方法之后添加（约第 134 行之后）：

```dart
  /// 获取视频的分P列表
  ///
  /// 调用 x/web-interface/view 获取 pages 数组
  /// 返回 null 或空列表表示单P视频
  Future<List<AudioPage>> getVideoPages(String bvid) async {
    final videoInfo = await getVideoInfo(bvid);
    final pages = videoInfo['pages'] as List<dynamic>? ?? [];
    return pages.map((page) {
      final cid = page['cid'];
      final duration = page['duration'];
      return AudioPage(
        cid: cid is int ? cid : int.parse('$cid'),
        title: _cleanHtmlTags(page['part'] ?? ''),
        duration: duration is int ? duration : int.parse('$duration'),
      );
    }).toList();
  }
```

- [ ] **Step 4: 验证编译通过**

```bash
cd frontend_flutter && flutter analyze lib/services/bilibili_api_service.dart lib/models/audio.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add frontend_flutter/lib/services/bilibili_api_service.dart
git commit -m "feat: API 服务层支持多P视频 — getAudioStreams 可选 cid，新增 getVideoPages

- getAudioStreams(bvid, {int? cid, cookies}) — 传入 cid 跳过 getVideoInfo
- getVideoPages(bvid) — 返回分P列表 List<AudioPage>
- search() DTO 传递 videos 字段"
```

---

### Task 3: SearchResultItem 加 `videos`，search_viewmodel 传递

**Files:**
- Modify: `frontend_flutter/lib/presentation/viewmodels/discovery/search_viewmodel.dart:46-62, 107-115`

**Interfaces:**
- Consumes: `Audio.videos` from Task 1
- Produces: `SearchResultItem.videos` (int, default 1)

- [ ] **Step 1: `SearchResultItem` 添加 `videos` 字段**

将（第 46-62 行）：
```dart
class SearchResultItem {
  final String bvid;
  final String title;
  final String? author;
  final String? coverUrl;
  final int? duration;
  final SearchPlatform platform;

  SearchResultItem({
    required this.bvid,
    required this.title,
    this.author,
    this.coverUrl,
    this.duration,
    required this.platform,
  });
}
```

改为：
```dart
class SearchResultItem {
  final String bvid;
  final String title;
  final String? author;
  final String? coverUrl;
  final int? duration;
  final SearchPlatform platform;
  final int videos;

  SearchResultItem({
    required this.bvid,
    required this.title,
    this.author,
    this.coverUrl,
    this.duration,
    required this.platform,
    this.videos = 1,
  });
}
```

- [ ] **Step 2: `search()` 方法中传递 `videos`**

将（第 107-115 行）：
```dart
      final results = audios.map((audio) => SearchResultItem(
        bvid: audio.id,
        title: audio.title,
        author: audio.artist,
        coverUrl: audio.coverUrl,
        duration: audio.duration,
        platform: SearchPlatform.bilibili,
      )).toList();
```

改为：
```dart
      final results = audios.map((audio) => SearchResultItem(
        bvid: audio.id,
        title: audio.title,
        author: audio.artist,
        coverUrl: audio.coverUrl,
        duration: audio.duration,
        platform: SearchPlatform.bilibili,
        videos: audio.videos,
      )).toList();
```

- [ ] **Step 3: `loadNextPage()` 方法中同样传递 `videos`**

在 search_viewmodel.dart 中找到 `loadNextPage` 中构建 SearchResultItem 的位置（约第 163 行附近），同样添加 `videos: audio.videos`。

- [ ] **Step 4: 验证编译通过**

```bash
cd frontend_flutter && flutter analyze lib/presentation/viewmodels/discovery/search_viewmodel.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/discovery/search_viewmodel.dart
git commit -m "feat: SearchResultItem 新增 videos 字段，搜索时传递分P数量"
```

---

### Task 4: OnlinePlayable — `id` getter 含 cid 以支持去重

**Files:**
- Modify: `frontend_flutter/lib/models/online_playable.dart:38`

**Interfaces:**
- Consumes: `Audio.cid` from Task 1
- Produces: `OnlinePlayable.id` 返回 `bvid_cid` 或 `bvid`

- [ ] **Step 1: 修改 `id` getter**

将（第 38 行）：
```dart
  @override
  String get id => _audio.id;
```

改为：
```dart
  @override
  String get id => _audio.cid != null ? '${_audio.id}_${_audio.cid}' : _audio.id;
```

- [ ] **Step 2: 验证编译通过**

```bash
cd frontend_flutter && flutter analyze lib/models/online_playable.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/models/online_playable.dart
git commit -m "fix: OnlinePlayable.id 含 cid — 多P视频各分P独立去重

id 从 'bvid' 改为 'bvid_cid'（当 cid 存在时），确保队列中
同一视频的不同分P被视为独立的播放项，不会互相去重"
```

---

### Task 5: PlaybackViewModel — 传 cid 给 `getAudioStreams`

**Files:**
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart:286-302`

**Interfaces:**
- Consumes: `OnlinePlayable.original.cid`, `getAudioStreams(bvid, cid:)` from Task 2

- [ ] **Step 1: 在 `_resolveOnlineStreamUrl` 中传入 `cid`**

将（第 292-293 行）：
```dart
    final api = ref.read(bilibiliApiServiceProvider);
    final streamsData = await api.getAudioStreams(bvid);
```

改为：
```dart
    final api = ref.read(bilibiliApiServiceProvider);
    final streamsData = await api.getAudioStreams(bvid, cid: playable.original.cid);
```

- [ ] **Step 2: 验证编译通过**

```bash
cd frontend_flutter && flutter analyze lib/presentation/viewmodels/player/playback_viewmodel.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart
git commit -m "fix: 播放时传入 cid 以获取正确分P的音频流"
```

---

### Task 6: 分P选择面板 Widget（新建）

**Files:**
- Create: `frontend_flutter/lib/presentation/widgets/video_pages_sheet.dart`

**Interfaces:**
- Consumes: `AudioPage` from Task 1
- Produces: `VideoPagesSheet.show()` 静态方法

- [ ] **Step 1: 创建 `video_pages_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import '../../models/audio.dart';

/// 分P选择底部面板
///
/// 当用户点击搜索结果中的多P视频时弹出。
/// 显示所有分P列表和"播放全部"按钮。
class VideoPagesSheet extends StatelessWidget {
  final String title;
  final List<AudioPage> pages;
  final int? totalDuration;
  final void Function(AudioPage page) onPlayPage;
  final VoidCallback onPlayAll;

  const VideoPagesSheet({
    super.key,
    required this.title,
    required this.pages,
    this.totalDuration,
    required this.onPlayPage,
    required this.onPlayAll,
  });

  /// 弹出分P选择面板
  static void show({
    required BuildContext context,
    required String title,
    required List<AudioPage> pages,
    int? totalDuration,
    required void Function(AudioPage page) onPlayPage,
    required VoidCallback onPlayAll,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => VideoPagesSheet(
        title: title,
        pages: pages,
        totalDuration: totalDuration,
        onPlayPage: onPlayPage,
        onPlayAll: onPlayAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示条
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          // 分P列表
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pages.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final page = pages[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    page.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    page.formattedDuration,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onPlayPage(page);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 播放全部按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.playlist_play),
                label: Text(
                  totalDuration != null
                      ? '播放全部 (${AudioPage.formatDuration(totalDuration)})'
                      : '播放全部',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onPlayAll();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 验证编译通过**

```bash
cd frontend_flutter && flutter analyze lib/presentation/widgets/video_pages_sheet.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/widgets/video_pages_sheet.dart
git commit -m "feat: 新增 VideoPagesSheet 分P选择底部面板组件"
```

---

### Task 7: SearchPage — 多P标签 + `_onResultTap` 分P分支

**Files:**
- Modify: `frontend_flutter/lib/presentation/views/discovery/search_page.dart`

**Interfaces:**
- Consumes: `SearchResultItem.videos` from Task 3, `VideoPagesSheet` from Task 6, `BilibiliApiService.getVideoPages` from Task 2

- [ ] **Step 1: 添加 import**

在第 4 行之后（`models/audio.dart` 的 import 之后）添加：

```dart
import 'package:listenvision/services/bilibili_api_service.dart';
import 'package:listenvision/presentation/widgets/video_pages_sheet.dart';
```

- [ ] **Step 2: 修改搜索结果列表的 title 行，添加多P标签**

将（第 296-300 行）：
```dart
                title: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
```

改为：
```dart
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.videos > 1)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '共${item.videos}P',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
```

- [ ] **Step 3: 重构 `_onResultTap`**

将（第 49-88 行）：
```dart
  void _onResultTap(SearchResultItem item) async {
    try {
      // 创建 Audio 对象
      final audio = Audio(
        id: item.bvid,
        title: item.title,
        artist: item.author,
        coverUrl: item.coverUrl,
        duration: item.duration,
      );

      // 创建 OnlinePlayable 对象（自动生成代理 URL）并添加到队列
      final playable = OnlinePlayable.withProxyUrl(audio);
      final queueNotifier = ref.read(queueViewModelProvider.notifier);
      await queueNotifier.add(playable, playImmediately: true);

      // 播放当前实际选中的队列项。
      // 不能使用 queue.length - 1，因为去重命中时当前项可能不是末尾。
      final queueIndex = ref.read(queueViewModelProvider).currentIndex;
      if (queueIndex >= 0) {
        final queueState = ref.read(queueViewModelProvider);
        if (queueIndex < queueState.queue.length) {
          // 使用 PlaybackViewModel 播放
          ref.read(playbackViewModelProvider.notifier).play(
            queueState.queue[queueIndex],
            index: queueIndex,
          );
        }
      }

      // 显示播放提示
      if (mounted) {
        SnackbarHelper.showPlaying(context, item.title, artist: item.author);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
  }
```

改为：
```dart
  void _onResultTap(SearchResultItem item) async {
    if (item.videos > 1) {
      await _showVideoPagesSheet(item);
    } else {
      await _playSingleAudio(
        bvid: item.bvid,
        title: item.title,
        artist: item.author,
        coverUrl: item.coverUrl,
        duration: item.duration,
      );
    }
  }

  /// 弹出分P选择面板
  Future<void> _showVideoPagesSheet(SearchResultItem item) async {
    try {
      final api = ref.read(bilibiliApiServiceProvider);
      final pages = await api.getVideoPages(item.bvid);

      if (!mounted) return;

      if (pages.isEmpty) {
        // 降级：API 返回空 pages，作为单P处理
        await _playSingleAudio(
          bvid: item.bvid,
          title: item.title,
          artist: item.author,
          coverUrl: item.coverUrl,
          duration: item.duration,
        );
        return;
      }

      VideoPagesSheet.show(
        context: context,
        title: item.title,
        pages: pages,
        totalDuration: item.duration,
        onPlayPage: (page) {
          _playSingleAudio(
            bvid: item.bvid,
            title: page.title,
            artist: item.author,
            coverUrl: item.coverUrl,
            duration: page.duration,
            cid: page.cid,
            videos: item.videos,
          );
        },
        onPlayAll: () {
          _playAllPages(
            bvid: item.bvid,
            artist: item.author,
            coverUrl: item.coverUrl,
            pages: pages,
            videos: item.videos,
          );
        },
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '获取分P列表失败: $e');
      }
    }
  }

  /// 播放单首音频
  Future<void> _playSingleAudio({
    required String bvid,
    required String title,
    String? artist,
    String? coverUrl,
    int? duration,
    int? cid,
    int videos = 1,
  }) async {
    try {
      final audio = Audio(
        id: bvid,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        duration: duration,
        cid: cid,
        videos: videos,
      );

      final playable = OnlinePlayable.withProxyUrl(audio);
      final queueNotifier = ref.read(queueViewModelProvider.notifier);
      await queueNotifier.add(playable, playImmediately: true);

      final queueIndex = ref.read(queueViewModelProvider).currentIndex;
      if (queueIndex >= 0) {
        final queueState = ref.read(queueViewModelProvider);
        if (queueIndex < queueState.queue.length) {
          ref.read(playbackViewModelProvider.notifier).play(
            queueState.queue[queueIndex],
            index: queueIndex,
          );
        }
      }

      if (mounted) {
        SnackbarHelper.showPlaying(context, title, artist: artist);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
  }

  /// 播放所有分P
  Future<void> _playAllPages({
    required String bvid,
    String? artist,
    String? coverUrl,
    required List<AudioPage> pages,
    int videos = 1,
  }) async {
    try {
      final queueNotifier = ref.read(queueViewModelProvider.notifier);

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final audio = Audio(
          id: bvid,
          title: page.title,
          artist: artist,
          coverUrl: coverUrl,
          duration: page.duration,
          cid: page.cid,
          videos: videos,
        );
        final playable = OnlinePlayable.withProxyUrl(audio);
        // 第一首立即播放，其余仅加入队列
        await queueNotifier.add(playable, playImmediately: i == 0);
      }

      if (mounted) {
        SnackbarHelper.showToast('已添加 ${pages.length} 首到播放队列');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
  }
```

- [ ] **Step 4: `_formatDuration` 方法改用 `AudioPage.formatDuration`**

将（第 504-509 行）：
```dart
  /// 格式化时长
  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
```

改为（直接委托给 AudioPage）：
```dart
  /// 格式化时长
  String _formatDuration(int? seconds) => AudioPage.formatDuration(seconds);
```

- [ ] **Step 5: 验证编译通过**

```bash
cd frontend_flutter && flutter analyze lib/presentation/views/discovery/search_page.dart
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/presentation/views/discovery/search_page.dart
git commit -m "feat: 搜索页支持多P视频 — 标签、分P选择、播放全部

- 搜索结果标题旁显示 '共N P' 标签
- 点击多P视频弹出 VideoPagesSheet 选择分P
- 支持单P播放和全部播放
- _onResultTap 重构为 _playSingleAudio / _showVideoPagesSheet / _playAllPages"
```

---

## 自审记录

**1. Spec 覆盖检查：**
- ✅ 数据层：Audio.videos, AudioPage — Task 1
- ✅ API 层：search 传 videos, getAudioStreams 支持 cid, getVideoPages — Task 2
- ✅ 搜索模型：SearchResultItem.videos — Task 3
- ✅ 播放标识：OnlinePlayable.id 含 cid（去重）— Task 4
- ✅ 播放流获取：PlaybackViewModel 传 cid — Task 5
- ✅ UI 面板：VideoPagesSheet — Task 6
- ✅ UI 搜索结果：多P标签 + 点击分支 — Task 7

**2. 占位符扫描：** 无 TBD/TODO/占位符。

**3. 类型一致性：**
- `AudioPage` 在 Task 1 定义，Task 2/6/7 使用 — 一致
- `SearchResultItem.videos` 在 Task 3 定义，Task 7 使用 — 一致
- `getVideoPages` 在 Task 2 定义，Task 7 使用 — 一致
- `getAudioStreams(bvid, cid:)` 在 Task 2 定义，Task 5 使用 — 一致
