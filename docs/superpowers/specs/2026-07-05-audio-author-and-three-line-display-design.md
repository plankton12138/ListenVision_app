# 音频作者属性与三行展示设计

**日期**：2026-07-05
**状态**：设计中

---

## 背景

当前音频播放页（AudioInfo）只显示两行：标题（title）和艺术家（artist）。对于B站下载的多P（分P）音频：

- 由于 `metadata_god` 写入失败触发文件名解析后备，碰巧将分集名解析为 `title`，视频标题解析为 `artist`
- 真正的UP主（作者）信息丢失
- `metadata_god` bug 修复后，元数据写入将正常生效，但分集名反而会丢失

需要正式支持：

1. **作者属性**：在主页显示上传者/UP主
2. **三行展示**：主标题 / 副标题（仅分P）/ 作者
3. **数据正确性**：分P视频的 title=分集名，albumTitle=视频标题，artist=UP主

---

## 设计目标

- 分P视频主页展示三行：分集名 / 视频标题 / UP主
- 单独视频展示两行：视频标题 / UP主（无副标题行）
- 本地导入音频读取文件元数据的 `album` 字段作为副标题
- 不破坏现有单P视频的显示体验
- 向后兼容已有数据库记录和已下载文件

---

## 数据模型

### Audio 模型新增 `albumTitle` 字段

```dart
// frontend_flutter/lib/models/audio.dart
const factory Audio({
  required String id,
  required String title,
  String? artist,
  String? album,         // 已有：专辑名（B站场景中曾用作视频URL）
  String? albumTitle,    // ← 新增：视频标题（分P音频的父标题）
  ...
})
```

> **注意**：`albumTitle` 与已有 `album` 字段不同。`album` 是通用专辑名，B站场景下目前存储视频URL。`albumTitle` 专门用于分P音频的父标题展示。读取文件元数据时，文件的 `album` 标签映射到 `albumTitle`，而非已有的 `album` 字段。

**字段语义：**

| 字段 | 分P视频 | 单独视频 | 本地导入 |
|------|---------|---------|---------|
| `title` | 分集名（如"12. 心亂飛"） | 视频标题 | 文件名或元数据 title |
| `albumTitle` | 视频标题 | null（不显示） | 元数据 album 标签（若有） |
| `artist` | UP主 | UP主 | 元数据 artist |

### PlaybackState 新增 `albumTitle` 字段

```dart
// frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart
const factory PlaybackState({
  ...
  @Default('未知标题') String title,
  String? albumTitle,  // ← 新增
  @Default('未知艺术家') String artist,
  ...
})
```

### PlayableAudio 接口新增 `albumTitle`

```dart
// frontend_flutter/lib/models/playable_audio.dart
abstract class PlayableAudio {
  String get id;
  String get title;
  String? get albumTitle;  // ← 新增
  String? get artist;
  ...
}
```

### LocalPlayable 和 OnlinePlayable 实现

- `OnlinePlayable`: 从 `Audio.albumTitle` 透传
- `LocalPlayable`: 新增 `albumTitle` 字段，从 `LocalAudio` 映射或新增字段

### PlaylistItem 新增 `albumTitle` 字段

歌单项也需要存储 albumTitle，保证歌单内分P音频显示正确。

### DownloadTask 新增 `albumTitle` 字段

下载任务需携带 albumTitle，贯穿下载全流程。

---

## 下载流程修改

### 文件元数据策略

下载时使用 `metadata_god` 写入文件元数据：

| 标签 | 单P | 分P |
|------|-----|-----|
| `title` | 视频标题 | 分集名 |
| `artist` | UP主 | UP主 |
| `album` | 视频标题 | 视频标题 |

读取时（`AudioMetadataHelper` / `Audio.fromDto`）：

| 字段来源 | 映射到模型 |
|---------|-----------|
| 元数据 `title` | `Audio.title` |
| 元数据 `artist` | `Audio.artist` |
| 元数据 `album` | `Audio.albumTitle`（新字段） |
| API `videos > 1` | `Audio.videos` |

### BilibiliDownloader

修改 `frontend_flutter/lib/services/bilibili_downloader.dart`：

```dart
// 从 videoInfo 中获取元数据
final title = videoInfo['title'] as String? ?? '未知标题';
final artist = owner?['name'] as String? ?? '未知艺术家';
final albumTitle = videoInfo['title'] as String?;
```

**单P下载**：
- `fileName` = 视频标题（不变）
- 元数据：`title=视频标题`, `album=null`（不写 album）

**多P分集下载**：
- `fileName` = 分集名（当前是 `视频标题 - 分集名`，改为仅分集名）
- 元数据：`title=分集名`, `album=视频标题`

### search_page.dart 下载调用

```dart
// 单P下载 - 不变
await downloadNotifier.addDownload(
  title: title,
  albumTitle: null,  // ← 新增
  ...
);

// 分P下载 - 修改
final page = pages[i];
await downloadNotifier.addDownload(
  title: page.title,      // 分集名（不再拼成 "视频标题 - 分集名"）
  albumTitle: title,       // 视频标题
  ...
);
```

### DownloadRepository

`_downloadWithBilibiliDownloader` 中将 `task.albumTitle` 传给 `BilibiliDownloader.download()`。

---

## 文件名格式

分P下载的文件名从 `{视频标题} - {分集名}.m4a` 改为 `{分集名}.m4a`。

原因：
- 既然元数据中有了 `album` 字段存储视频标题，文件名不再需要承载视频标题信息
- 文件名简洁，避免 Windows 路径长度问题
- 但仍需确保文件名唯一（分P标题通常已序号开头，如"12. 心亂飛"）

**兼容已下载文件**：已有的 `{视频标题} - {分集名}.m4a` 格式文件在导入时，通过 `AudioMetadataHelper.extractFromPath()` 仍能正确解析——拆分 ` - ` 后，左侧变为 `albumTitle`，右侧变为 `title`。但需要确保元数据读取优先于文件名解析。

---

## UI 修改

### AudioInfo 三行展示

```dart
// frontend_flutter/lib/presentation/widgets/audio_info.dart
Widget _buildAudioInfo(BuildContext context, PlaybackState state) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // 第1行：主标题（分集名/视频标题）
      Text(
        state.title,
        style: const TextStyle(
          fontSize: UIConstants.fontSizeMedium,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),

      // 第2行：副标题（仅分P音频）
      if (state.albumTitle != null && state.albumTitle!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            state.albumTitle!,
            style: const TextStyle(
              fontSize: UIConstants.fontSizeSmall,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),

      const SizedBox(height: 4),

      // 第3行：作者（artist/UP主）
      Text(
        state.artist.isNotEmpty ? state.artist : '未知艺术家',
        style: const TextStyle(
          fontSize: UIConstants.fontSizeSmall,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ],
  );
}
```

### 其他列表项

- `QueueItemTile`：保持两行（主标题 + 作者），增加 `albumTitle` 信息透传（可选显示）
- `LocalMusicPlaylistPage` 列表项：保持两行（主标题 + 作者），副标题不显示
- `HistoryTabView`：保持两行，不显示副标题

---

## 兼容性

### 已有下载文件

对于已下载的 `{视频标题} - {分集名}.m4a` 文件：

1. 如果文件元数据中已有 title/artist（旧的错误写入），应该忽略
2. 优先从文件名解析，因为文件名格式稳定
3. 但仍然需要区分"当前文件是分P还是单P"

**策略**：`AudioMetadataHelper` 读取元数据后，如果发现 `title` 不包含 ` - ` 分隔符且文件名包含 ` - `，则认为文件名格式为 `{视频标题} - {分集名}`，做反向解析。

### 数据库旧记录

已有 `Track` 和 `PlaylistItem` 记录的 `albumTitle` 字段为 null，不影响显示。

---

## 受影响文件清单

| 文件 | 改动类型 |
|------|---------|
| `lib/models/audio.dart` | 新增 `albumTitle` 字段 + fromDto/toDto |
| `lib/models/playable_audio.dart` | 接口新增 `albumTitle` getter |
| `lib/models/online_playable.dart` | 实现 `albumTitle` |
| `lib/models/local_playable.dart` | 新增 `albumTitle` 字段 |
| `lib/models/local_audio.dart` | 新增 `albumTitle` 字段 + copyWith/toMap/fromMap |
| `lib/models/playlist.dart` (PlaylistItem) | 新增 `albumTitle` 字段 |
| `lib/models/download_task.dart` | 新增 `albumTitle` 字段 |
| `lib/services/bilibili_downloader.dart` | 接收/传递 albumTitle，修改文件名逻辑 |
| `lib/services/metadata_writer.dart` | 写入 albumTitle → album 标签 |
| `lib/presentation/widgets/audio_info.dart` | 三行展示 |
| `lib/presentation/viewmodels/player/playback_viewmodel.dart` | PlaybackState 新增 albumTitle |
| `lib/presentation/views/discovery/search_page.dart` | 分P下载传 albumTitle |
| `lib/data/repositories/download_repository.dart` | 透传 albumTitle |
| 代码生成文件 | 重新运行 build_runner |
